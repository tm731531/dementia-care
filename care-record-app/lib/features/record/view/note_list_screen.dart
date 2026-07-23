import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/time.dart';
import '../model/note_author.dart';
import '../providers.dart';
import '../service/backup.dart';
import 'doctor_review_screen.dart';
import 'record_note_screen.dart';

/// Reads persisted notes newest-first — this screen is how persistence
/// survives an app restart is visually verified (device smoke test).
class NoteListScreen extends ConsumerWidget {
  const NoteListScreen({super.key});

  /// Builds `care-record-backup.zip` (notes + photos) into a temp dir and
  /// hands it to the OS share sheet, so the caregiver can send it to a
  /// second phone by whatever channel they already use (LINE / USB / …).
  Future<void> _exportZip(BuildContext context, WidgetRef ref) async {
    final dao = await ref.read(noteDaoProvider.future);
    final photosDir = Directory(
      p.join((await getApplicationDocumentsDirectory()).path, 'photos'),
    );
    final outDir = await getTemporaryDirectory();
    final zipFile = await exportZip(dao: dao, photosDir: photosDir, outDir: outDir);

    if (!context.mounted) return;
    await SharePlus.instance.share(ShareParams(files: [XFile(zipFile.path)]));
  }

  /// Lets the caregiver pick a zip received from another phone and merges
  /// it into the local db — new-only, id-idempotent, so re-picking the same
  /// file is always safe.
  Future<void> _importZip(BuildContext context, WidgetRef ref) async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['zip'],
    );
    final path = result?.files.single.path;
    if (path == null) return;

    final dao = await ref.read(noteDaoProvider.future);
    final photosDir = Directory(
      p.join((await getApplicationDocumentsDirectory()).path, 'photos'),
    );

    if (!context.mounted) return;
    try {
      final summary = await importZip(zip: File(path), dao: dao, photosDir: photosDir);
      if (!context.mounted) return;
      ref.invalidate(notesProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('匯入 ${summary.total} 筆，其中 ${summary.imported} 筆是新的')),
      );
    } on FormatException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notesAsync = ref.watch(notesProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('照護紀錄列表'),
        actions: [
          IconButton(
            icon: const Icon(Icons.summarize),
            tooltip: '給醫生看的整理',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const DoctorReviewScreen()),
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'export') _exportZip(context, ref);
              if (value == 'import') _importZip(context, ref);
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'export', child: Text('匯出備份（ZIP）')),
              PopupMenuItem(value: 'import', child: Text('匯入他人紀錄')),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: notesAsync.when(
          data: (notes) {
            if (notes.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('目前沒有紀錄', style: TextStyle(fontSize: 22)),
                ),
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: notes.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final note = notes[index];
                final t = note.timestamp;
                final date = '${t.year}-${t.month.toString().padLeft(2, '0')}-'
                    '${t.day.toString().padLeft(2, '0')}';
                final shift = shiftOfDay(t);
                final time = TimeOfDay.fromDateTime(t).format(context);
                final authorLabel = note.author == NoteAuthor.family ? '家屬' : '照顧者';
                final photoMarker = note.photoPath != null ? '　📷' : '';
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  title: Text(
                    '$date（$shift $time）　$authorLabel$photoMarker',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF222222),
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      note.text,
                      style: const TextStyle(fontSize: 24, height: 1.6, color: Color(0xFF222222)),
                    ),
                  ),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
            child: Text('讀取失敗：$e', style: const TextStyle(fontSize: 20)),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const RecordNoteScreen()),
        ),
        icon: const Icon(Icons.mic),
        label: const Text('新增紀錄'),
      ),
    );
  }
}

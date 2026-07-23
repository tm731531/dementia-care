import 'dart:io';
import 'dart:typed_data';

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
import '../../about/about_screen.dart';
import '../../patient/patient_manage_screen.dart';
import '../../patient/patient_switcher.dart';
import 'doctor_review_screen.dart';
import 'record_note_screen.dart';

/// Reads persisted notes newest-first — this screen is how persistence
/// survives an app restart is visually verified (device smoke test).
class NoteListScreen extends ConsumerWidget {
  const NoteListScreen({super.key});

  /// Builds `care-record-backup.zip` (the current patient + their notes +
  /// photos) into a temp dir, then lets the caregiver choose to hand it to
  /// the OS share sheet (send to a second phone via LINE / USB / …) or save
  /// it straight onto this device (e.g. Downloads).
  Future<void> _exportZip(BuildContext context, WidgetRef ref) async {
    final patient = ref.read(currentPatientProvider).valueOrNull;
    if (patient == null) return; // no patients yet (shouldn't happen post-seed)
    final dao = await ref.read(noteDaoProvider.future);
    final photosDir = Directory(
      p.join((await getApplicationDocumentsDirectory()).path, 'photos'),
    );
    final outDir = await getTemporaryDirectory();
    final zipFile = await exportZip(patient: patient, dao: dao, photosDir: photosDir, outDir: outDir);

    if (!context.mounted) return;
    final choice = await _showExportChoiceSheet(context);
    if (choice == null) return; // dismissed without choosing

    if (choice == _ExportChoice.share) {
      if (!context.mounted) return;
      await SharePlus.instance.share(ShareParams(files: [XFile(zipFile.path)]));
    } else {
      final bytes = await zipFile.readAsBytes();
      if (!context.mounted) return;
      await _saveBytesToDevice(context, bytes: bytes, fileName: 'care-record-backup.zip');
    }
  }

  /// Lets the caregiver pick a zip received from another phone and merges
  /// it into the local db — new-only, id-idempotent, so re-picking the same
  /// file is always safe. Notes without patient info (old Plan-2 backups)
  /// fall back onto the currently-selected patient.
  Future<void> _importZip(BuildContext context, WidgetRef ref) async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['zip'],
    );
    final path = result?.files.single.path;
    if (path == null) return;

    final dao = await ref.read(noteDaoProvider.future);
    final patientDao = await ref.read(patientDaoProvider.future);
    final currentPatientId = ref.read(currentPatientProvider).valueOrNull?.id;
    final String fallbackPatientId;
    if (currentPatientId != null) {
      fallbackPatientId = currentPatientId;
    } else {
      fallbackPatientId = await ref.read(defaultPatientIdProvider.future);
    }
    final photosDir = Directory(
      p.join((await getApplicationDocumentsDirectory()).path, 'photos'),
    );

    if (!context.mounted) return;
    try {
      final summary = await importZip(
        zip: File(path),
        dao: dao,
        patientDao: patientDao,
        photosDir: photosDir,
        fallbackPatientId: fallbackPatientId,
      );
      if (!context.mounted) return;
      ref.invalidate(patientsProvider);
      ref.invalidate(notesProvider);
      await ref.read(currentPatientIdProvider.notifier).select(summary.patientId);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('已匯入『${summary.patientName}』的 ${summary.total} 筆，其中 ${summary.imported} 筆是新的'),
        ),
      );
    } on FormatException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    }
  }

  /// System info dialog — app name + version (from the ⋮ menu).
  /// Await the version BEFORE opening the dialog so it never shows "讀取中".
  Future<void> _showSystemInfo(BuildContext context, WidgetRef ref) async {
    final version = await ref.read(appVersionProvider.future);
    if (!context.mounted) return;
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('系統資訊'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('App 名稱：照護紀錄', style: TextStyle(fontSize: 18)),
            const SizedBox(height: 10),
            Text('版本：$version', style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 10),
            const Text('資料儲存：本機（離線，不上雲端）',
                style: TextStyle(fontSize: 16, color: Color(0xFF555555))),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('確定'),
          ),
        ],
      ),
    );
  }

  /// Full-screen viewer so the recorder can actually inspect a photo from the
  /// main list (not only from the doctor-review screen).
  void _showPhoto(BuildContext context, String path) {
    showDialog<void>(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(12),
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            InteractiveViewer(
              child: Image.file(
                File(path),
                errorBuilder: (_, __, ___) => const Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('照片已遺失', style: TextStyle(color: Colors.white)),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 32),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
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
              if (value == 'about') {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AboutScreen()),
                );
              }
              if (value == 'patients') {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const PatientManageScreen()),
                );
              }
              if (value == 'sysinfo') _showSystemInfo(context, ref);
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'export', child: Text('匯出備份（ZIP）')),
              PopupMenuItem(value: 'import', child: Text('匯入他人紀錄')),
              PopupMenuItem(value: 'patients', child: Text('病人管理')),
              PopupMenuItem(value: 'about', child: Text('關於與隱私')),
              PopupMenuItem(value: 'sysinfo', child: Text('系統資訊')),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const PatientSwitcher(),
            Expanded(
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
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    itemCount: notes.length,
                    itemBuilder: (context, index) {
                      final note = notes[index];
                      final t = note.timestamp;
                      final date = '${t.year}-${t.month.toString().padLeft(2, '0')}-'
                          '${t.day.toString().padLeft(2, '0')}';
                      final shift = shiftOfDay(t);
                      final time = TimeOfDay.fromDateTime(t).format(context);
                      final authorLabel = note.author == NoteAuthor.family ? '家屬' : '照顧者';
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        elevation: 2,
                        color: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '$date（$shift $time）　$authorLabel',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF2C5D80),
                                ),
                              ),
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 10),
                                child: Divider(height: 1),
                              ),
                              Text(
                                note.text,
                                style: const TextStyle(
                                    fontSize: 24, height: 1.6, color: Color(0xFF222222)),
                              ),
                              if (note.photoPath != null) ...[
                                const SizedBox(height: 12),
                                GestureDetector(
                                  onTap: () => _showPhoto(context, note.photoPath!),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.file(
                                      File(note.photoPath!),
                                      width: 160,
                                      height: 160,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                                    ),
                                  ),
                                ),
                              ],
                            ],
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
          ],
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

enum _ExportChoice { share, save }

/// Bottom sheet offering the two ways to deliver an export: hand it to the
/// OS share sheet, or save it straight onto this device (e.g. Downloads)
/// via the system "save as" dialog. Returns null if dismissed.
Future<_ExportChoice?> _showExportChoiceSheet(BuildContext context) {
  return showModalBottomSheet<_ExportChoice>(
    context: context,
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.ios_share),
            title: const Text('分享', style: TextStyle(fontSize: 20)),
            onTap: () => Navigator.of(context).pop(_ExportChoice.share),
          ),
          ListTile(
            leading: const Icon(Icons.save_alt),
            title: const Text('儲存到手機', style: TextStyle(fontSize: 20)),
            onTap: () => Navigator.of(context).pop(_ExportChoice.save),
          ),
        ],
      ),
    ),
  );
}

/// Opens the system "save as" dialog (SAF on Android) so the caregiver can
/// pick where to save — e.g. Downloads — then confirms with a SnackBar.
/// Does nothing if the user cancels the dialog (file_picker returns null).
Future<void> _saveBytesToDevice(
  BuildContext context, {
  required Uint8List bytes,
  required String fileName,
}) async {
  final savedPath = await FilePicker.saveFile(fileName: fileName, bytes: bytes);
  if (!context.mounted) return;
  if (savedPath == null) return; // user cancelled the save dialog
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('已儲存到手機：$savedPath')),
  );
}

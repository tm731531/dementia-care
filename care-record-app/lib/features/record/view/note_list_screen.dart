import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/time.dart';
import '../model/note_author.dart';
import '../providers.dart';
import 'record_note_screen.dart';

/// Reads persisted notes newest-first — this screen is how persistence
/// survives an app restart is visually verified (device smoke test).
class NoteListScreen extends ConsumerWidget {
  const NoteListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notesAsync = ref.watch(notesProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('照護紀錄列表')),
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
                final shift = shiftOfDay(note.timestamp);
                final time = TimeOfDay.fromDateTime(note.timestamp).format(context);
                final authorLabel = note.author == NoteAuthor.family ? '家屬' : '照顧者';
                final photoMarker = note.photoPath != null ? '　📷' : '';
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  title: Text(
                    '$shift $time　$authorLabel$photoMarker',
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
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const RecordNoteScreen()),
        ),
        icon: const Icon(Icons.mic),
        label: const Text('新增紀錄'),
      ),
    );
  }
}

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/time.dart';
import '../model/care_note.dart';
import '../model/note_author.dart';
import '../providers.dart';

/// Edit or delete a single, already-saved [CareNote]. Text and optional
/// photo removal only — id/timestamp/author/patientId are preserved so
/// editing never changes when a note was recorded or who by.
class NoteEditScreen extends ConsumerStatefulWidget {
  final CareNote note;

  const NoteEditScreen({super.key, required this.note});

  @override
  ConsumerState<NoteEditScreen> createState() => _NoteEditScreenState();
}

class _NoteEditScreenState extends ConsumerState<NoteEditScreen> {
  late final TextEditingController _textController;
  String? _photoPath;
  bool _isSaving = false;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.note.text);
    _photoPath = widget.note.photoPath;
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _removePhoto() {
    setState(() => _photoPath = null);
  }

  Future<void> _save() async {
    final text = _textController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('內容不能是空的')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final removedPhotoPath =
          widget.note.photoPath != null && _photoPath == null ? widget.note.photoPath : null;
      final updated = CareNote(
        id: widget.note.id,
        timestamp: widget.note.timestamp,
        author: widget.note.author,
        text: text,
        patientId: widget.note.patientId,
        photoPath: _photoPath,
      );
      final dao = await ref.read(noteDaoProvider.future);
      await dao.insert(updated); // same id → replace-by-id = update
      if (removedPhotoPath != null) {
        final file = File(removedPhotoPath);
        if (await file.exists()) await file.delete();
      }
      ref.invalidate(notesProvider);
      if (!mounted) return;
      Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('刪除這筆紀錄？'),
        content: const Text('刪除後無法復原。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('刪除', style: TextStyle(color: Color(0xFFB3261E))),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    if (!mounted) return;

    setState(() => _isDeleting = true);
    try {
      final dao = await ref.read(noteDaoProvider.future);
      if (widget.note.photoPath != null) {
        final file = File(widget.note.photoPath!);
        if (await file.exists()) await file.delete();
      }
      await dao.delete(widget.note.id);
      ref.invalidate(notesProvider);
      if (!mounted) return;
      Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.note.timestamp;
    final date = '${t.year}-${t.month.toString().padLeft(2, '0')}-'
        '${t.day.toString().padLeft(2, '0')}';
    final shift = shiftOfDay(t);
    final time = TimeOfDay.fromDateTime(t).format(context);
    final authorLabel = widget.note.author == NoteAuthor.family ? '家屬' : '照顧者';
    final busy = _isSaving || _isDeleting;

    return Scaffold(
      appBar: AppBar(title: const Text('編輯紀錄')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '$date（$shift $time）　$authorLabel',
                style: const TextStyle(fontSize: 16, color: Color(0xFF555555)),
              ),
              const SizedBox(height: 20),
              const Text('文字內容：', style: TextStyle(fontSize: 20, color: Color(0xFF222222))),
              const SizedBox(height: 8),
              TextField(
                controller: _textController,
                maxLines: 8,
                minLines: 3,
                style: const TextStyle(fontSize: 24, height: 1.6, color: Color(0xFF222222)),
                decoration: const InputDecoration(border: OutlineInputBorder()),
              ),
              const SizedBox(height: 24),
              if (_photoPath != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    File(_photoPath!),
                    height: 200,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: busy ? null : _removePhoto,
                  child: const Text('移除照片'),
                ),
                const SizedBox(height: 24),
              ],
              FilledButton(
                onPressed: busy ? null : _save,
                child: Text(_isSaving ? '儲存中…' : '儲存'),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: busy ? null : _confirmDelete,
                style: TextButton.styleFrom(foregroundColor: const Color(0xFFB3261E)),
                child: Text(_isDeleting ? '刪除中…' : '刪除這筆'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

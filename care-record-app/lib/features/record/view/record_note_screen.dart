import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../model/care_note.dart';
import '../model/note_author.dart';
import '../providers.dart';
import 'note_list_screen.dart';

enum _ModelStatus { downloading, ready, error }

/// Production record-a-note screen: record → on-device transcribe → user
/// edits the text (寧缺勿錯, the human is the verifier) → save.
class RecordNoteScreen extends ConsumerStatefulWidget {
  const RecordNoteScreen({super.key});

  @override
  ConsumerState<RecordNoteScreen> createState() => _RecordNoteScreenState();
}

class _RecordNoteScreenState extends ConsumerState<RecordNoteScreen> {
  final TextEditingController _textController = TextEditingController();

  _ModelStatus _modelStatus = _ModelStatus.downloading;
  String? _modelError;

  bool _isRecording = false;
  bool _isTranscribing = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _ensureModelReady();
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  /// Triggers (or awaits, if already in flight) the one-time model
  /// download/init. Safe to call again from the retry button on failure —
  /// [SherpaTranscriber.ensureReady] resets its memoized future on error.
  Future<void> _ensureModelReady() async {
    setState(() {
      _modelStatus = _ModelStatus.downloading;
      _modelError = null;
    });
    try {
      await ref.read(transcriberProvider).ensureReady();
      if (!mounted) return;
      setState(() => _modelStatus = _ModelStatus.ready);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _modelStatus = _ModelStatus.error;
        _modelError = e.toString();
      });
    }
  }

  Future<void> _toggleRecording() async {
    final recorder = ref.read(audioRecorderProvider);
    if (_isRecording) {
      setState(() => _isRecording = false);
      final path = await recorder.stopAndGetPath();
      await _transcribe(path);
      return;
    }

    if (!await recorder.hasPermission()) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('沒有麥克風權限，無法錄音')),
      );
      return;
    }

    await recorder.start();
    if (!mounted) return;
    setState(() => _isRecording = true);
  }

  Future<void> _transcribe(String audioPath) async {
    setState(() => _isTranscribing = true);
    try {
      final text = await ref.read(transcriberProvider).transcribe(audioPath);
      if (!mounted) return;
      setState(() {
        _textController.text = text;
        _isTranscribing = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isTranscribing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('轉錄失敗：$e')),
      );
    }
  }

  Future<void> _save() async {
    final text = _textController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('請先錄音或輸入文字內容')),
      );
      return;
    }

    setState(() => _isSaving = true);
    final note = CareNote(
      id: const Uuid().v4(),
      timestamp: DateTime.now(),
      author: NoteAuthor.family,
      text: text,
    );
    try {
      final dao = await ref.read(noteDaoProvider.future);
      await dao.insert(note);
      ref.invalidate(notesProvider);
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const NoteListScreen()),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('照護紀錄'),
        actions: [
          IconButton(
            icon: const Icon(Icons.list_alt),
            tooltip: '查看紀錄列表',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const NoteListScreen()),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildModelStatus(),
              const SizedBox(height: 24),
              if (_modelStatus == _ModelStatus.ready) _buildRecordButton(),
              const SizedBox(height: 24),
              if (_isTranscribing)
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 3),
                    ),
                    SizedBox(width: 12),
                    Text('辨識中…', style: TextStyle(fontSize: 22)),
                  ],
                ),
              const SizedBox(height: 16),
              const Text('文字內容（可修改）：', style: TextStyle(fontSize: 20, color: Color(0xFF222222))),
              const SizedBox(height: 8),
              TextField(
                controller: _textController,
                maxLines: 6,
                minLines: 3,
                style: const TextStyle(fontSize: 24, height: 1.6, color: Color(0xFF222222)),
                decoration: const InputDecoration(border: OutlineInputBorder()),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _isSaving ? null : _save,
                child: Text(_isSaving ? '儲存中…' : '儲存'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModelStatus() {
    switch (_modelStatus) {
      case _ModelStatus.downloading:
        return const Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 3),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                '正在下載語音模型（僅需一次，建議使用 Wi-Fi）…',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ],
        );
      case _ModelStatus.ready:
        return const Row(
          children: [
            Icon(Icons.check_circle, color: Color(0xFF2C5D80)),
            SizedBox(width: 8),
            Text('語音模型已就緒', style: TextStyle(fontSize: 18)),
          ],
        );
      case _ModelStatus.error:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('模型下載失敗：$_modelError', style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: _ensureModelReady,
              child: const Text('重試下載'),
            ),
          ],
        );
    }
  }

  Widget _buildRecordButton() {
    return FilledButton(
      onPressed: _isTranscribing ? null : _toggleRecording,
      style: FilledButton.styleFrom(
        minimumSize: const Size(double.infinity, 72),
        backgroundColor: _isRecording ? const Color(0xFFB3261E) : null,
      ),
      child: Text(
        _isRecording ? '⏹ 停止' : '🎤 開始說話',
        style: const TextStyle(fontSize: 24),
      ),
    );
  }
}

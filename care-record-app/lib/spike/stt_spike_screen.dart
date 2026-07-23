import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa_onnx;

/// SPIKE screen — not production UI.
///
/// Purpose: let Tom read the synthetic script aloud on a real phone and see
/// whether on-device Whisper (via `sherpa_onnx`, whisper.cpp's ONNX port)
/// produces a usable Traditional-Chinese transcription. See
/// `spike/stt_spike.md` for the chosen binding, model size, and the GO/NO-GO
/// evidence to fill in after a real-device run.
///
/// Synthetic only — this script contains NO real patient/caregiving data.
const String kSyntheticScript = '今天精神穩定，午餐吃一半，下午走一走，晚上睡得好，情緒平穩。';

/// Whisper-small (int8) model files, unpacked (not tar'd) on Hugging Face.
/// See spike/stt_spike.md for why this mirror over the official k2-fsa release
/// (which only ships a combined .tar.bz2, and this project has no bzip2/tar
/// extraction dependency). Swapped base -> small after the base device run
/// dropped characters (穩定/午餐/情緒平穩); small is more accurate (~375MB int8).
const String _kModelBaseUrl =
    'https://huggingface.co/csukuangfj/sherpa-onnx-whisper-small/resolve/main';
const String _kEncoderFile = 'small-encoder.int8.onnx';
const String _kDecoderFile = 'small-decoder.int8.onnx';
const String _kTokensFile = 'small-tokens.txt';

enum _ModelStatus { downloading, ready, error }

class SttSpikeScreen extends StatefulWidget {
  const SttSpikeScreen({super.key});

  @override
  State<SttSpikeScreen> createState() => _SttSpikeScreenState();
}

class _SttSpikeScreenState extends State<SttSpikeScreen> {
  final AudioRecorder _recorder = AudioRecorder();
  sherpa_onnx.OfflineRecognizer? _recognizer;

  _ModelStatus _modelStatus = _ModelStatus.downloading;
  String? _modelError;

  bool _isRecording = false;
  bool _isTranscribing = false;
  String? _transcript;
  Duration? _transcribeWallClock;

  @override
  void initState() {
    super.initState();
    _ensureModelDownloaded();
  }

  @override
  void dispose() {
    _recorder.dispose();
    _recognizer?.free();
    super.dispose();
  }

  /// Model is NEVER bundled in the repo (>100MB, public GitHub rejects it).
  /// First launch downloads it once from Hugging Face over the network and
  /// caches it in app-support storage; later launches reuse the cached files.
  Future<void> _ensureModelDownloaded() async {
    setState(() {
      _modelStatus = _ModelStatus.downloading;
      _modelError = null;
    });
    try {
      final dir = await getApplicationSupportDirectory();
      final modelDir = Directory('${dir.path}/whisper_small');
      if (!modelDir.existsSync()) {
        modelDir.createSync(recursive: true);
      }
      final encoderPath = '${modelDir.path}/$_kEncoderFile';
      final decoderPath = '${modelDir.path}/$_kDecoderFile';
      final tokensPath = '${modelDir.path}/$_kTokensFile';

      await _downloadIfMissing('$_kModelBaseUrl/$_kEncoderFile', encoderPath);
      await _downloadIfMissing('$_kModelBaseUrl/$_kDecoderFile', decoderPath);
      await _downloadIfMissing('$_kModelBaseUrl/$_kTokensFile', tokensPath);

      sherpa_onnx.initBindings();
      final config = sherpa_onnx.OfflineRecognizerConfig(
        model: sherpa_onnx.OfflineModelConfig(
          whisper: sherpa_onnx.OfflineWhisperModelConfig(
            encoder: encoderPath,
            decoder: decoderPath,
            language: 'zh',
            task: 'transcribe',
          ),
          tokens: tokensPath,
          modelType: 'whisper',
          numThreads: 1,
          debug: false,
        ),
      );
      _recognizer = sherpa_onnx.OfflineRecognizer(config);

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

  /// Downloads [url] to [path] unless a file already exists there (cache
  /// reuse across launches). Downloads to a `.part` temp file first so a
  /// crash mid-download can't leave a truncated file that looks "cached".
  Future<void> _downloadIfMissing(String url, String path) async {
    final file = File(path);
    if (file.existsSync() && file.lengthSync() > 0) return;

    final partFile = File('$path.part');
    final client = HttpClient();
    try {
      final request = await client.getUrl(Uri.parse(url));
      final response = await request.close();
      if (response.statusCode != 200) {
        throw Exception('HTTP ${response.statusCode} downloading $url');
      }
      final sink = partFile.openWrite();
      await response.pipe(sink);
      await sink.close();
      await partFile.rename(path);
    } finally {
      client.close();
    }
  }

  Future<void> _toggleRecording() async {
    if (_isRecording) {
      final path = await _recorder.stop();
      setState(() => _isRecording = false);
      if (path != null) {
        await _transcribe(path);
      }
      return;
    }

    if (!await _recorder.hasPermission()) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('沒有麥克風權限，無法錄音')),
      );
      return;
    }

    final dir = await getTemporaryDirectory();
    final path =
        '${dir.path}/stt_spike_${DateTime.now().millisecondsSinceEpoch}.wav';
    // 16kHz mono WAV — the format sherpa_onnx's Whisper model expects
    // without needing an ffmpeg re-encode step.
    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.wav,
        sampleRate: 16000,
        numChannels: 1,
      ),
      path: path,
    );
    setState(() {
      _isRecording = true;
      _transcript = null;
      _transcribeWallClock = null;
    });
  }

  Future<void> _transcribe(String audioPath) async {
    final recognizer = _recognizer;
    if (recognizer == null) return;
    setState(() => _isTranscribing = true);
    final start = DateTime.now();
    try {
      final wave = sherpa_onnx.readWave(audioPath);
      final stream = recognizer.createStream();
      stream.acceptWaveform(samples: wave.samples, sampleRate: wave.sampleRate);
      recognizer.decode(stream);
      final result = recognizer.getResult(stream);
      stream.free();
      if (!mounted) return;
      setState(() {
        _transcript = result.text.isEmpty ? '（無法辨識，回傳空結果）' : result.text;
        _transcribeWallClock = DateTime.now().difference(start);
        _isTranscribing = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _transcript = '轉錄失敗：$e';
        _transcribeWallClock = DateTime.now().difference(start);
        _isTranscribing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('語音轉字 Spike（測試用）')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('請對著手機唸出以下句子：', style: TextStyle(fontSize: 20)),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFFFF),
                  border: Border.all(color: const Color(0xFF2C5D80), width: 2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  kSyntheticScript,
                  style: TextStyle(
                    fontSize: 26,
                    height: 1.6,
                    color: Color(0xFF222222),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 24),
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
              if (_transcript != null) _buildTranscriptResult(),
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
                '正在下載語音模型（whisper-small，約 375MB，僅需一次，'
                '建議使用 Wi-Fi）…',
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
            Text('模型已就緒', style: TextStyle(fontSize: 18)),
          ],
        );
      case _ModelStatus.error:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('模型下載失敗：$_modelError', style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: _ensureModelDownloaded,
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
        _isRecording ? '⏹ 停止錄音' : '🎤 開始錄音',
        style: const TextStyle(fontSize: 24),
      ),
    );
  }

  Widget _buildTranscriptResult() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('辨識結果：', style: TextStyle(fontSize: 18, color: Color(0xFF222222))),
          const SizedBox(height: 8),
          SelectableText(
            _transcript ?? '',
            style: const TextStyle(fontSize: 24, color: Color(0xFF222222)),
          ),
          if (_transcribeWallClock != null) ...[
            const SizedBox(height: 8),
            Text(
              '耗時：${_transcribeWallClock!.inMilliseconds} ms',
              style: const TextStyle(fontSize: 14, color: Color(0xFF666666)),
            ),
          ],
        ],
      ),
    );
  }
}

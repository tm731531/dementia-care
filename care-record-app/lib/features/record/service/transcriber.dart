import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa_onnx;

/// The model-agnostic seam. UI (Task 6) and tests depend on [Transcriber],
/// never on the sherpa_onnx package directly.
abstract class Transcriber {
  /// Transcribe an on-device audio file to text. Fully offline. Never throws
  /// for low-confidence audio — returns best-effort text (possibly empty)
  /// for the user to edit (寧缺勿錯: the human is the verifier).
  Future<String> transcribe(String audioFilePath);
}

/// On-device transcription via `sherpa_onnx` (whisper.cpp's ONNX port),
/// using whisper-base (int8). Lifts the model download/init/decode logic
/// verified working on a real phone in `lib/spike/stt_spike_screen.dart`.
///
/// The model (~160MB) is never bundled in the repo — it is downloaded once
/// from Hugging Face on first use and cached under app-support storage.
/// After that, transcription is fully offline.
class SherpaTranscriber implements Transcriber {
  static const String _kModelBaseUrl =
      'https://huggingface.co/csukuangfj/sherpa-onnx-whisper-base/resolve/main';
  static const String _kEncoderFile = 'base-encoder.int8.onnx';
  static const String _kDecoderFile = 'base-decoder.int8.onnx';
  static const String _kTokensFile = 'base-tokens.txt';

  sherpa_onnx.OfflineRecognizer? _recognizer;
  Future<void>? _readyFuture;

  /// Ensures the model is downloaded (one-time, cached) and the recognizer
  /// is initialized. Safe to call multiple times or from multiple callers —
  /// concurrent calls share the same in-flight download/init.
  Future<void> ensureReady() => _readyFuture ??= _init();

  Future<void> _init() async {
    final dir = await getApplicationSupportDirectory();
    final modelDir = Directory('${dir.path}/whisper_base');
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

  @override
  Future<String> transcribe(String audioFilePath) async {
    await ensureReady();
    final recognizer = _recognizer;
    if (recognizer == null) {
      throw StateError('SherpaTranscriber failed to initialize');
    }
    final wave = sherpa_onnx.readWave(audioFilePath);
    final stream = recognizer.createStream();
    stream.acceptWaveform(samples: wave.samples, sampleRate: wave.sampleRate);
    recognizer.decode(stream);
    final result = recognizer.getResult(stream);
    stream.free();
    return result.text.trim();
  }

  /// Releases native resources. Call when the transcriber is no longer needed.
  void dispose() {
    _recognizer?.free();
    _recognizer = null;
  }
}

import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart' as rec;

/// Wraps the `record` package to capture 16kHz mono WAV audio to a temp
/// file — the format [SherpaTranscriber] (whisper.cpp's ONNX port) expects
/// without needing an ffmpeg re-encode step. Lifted from the spike at
/// `lib/spike/stt_spike_screen.dart`.
///
/// Aliased import: the `record` package's own recorder class is also named
/// `AudioRecorder`, so it is imported as `rec` to avoid a name clash with
/// this class.
class AudioRecorder {
  final rec.AudioRecorder _recorder = rec.AudioRecorder();
  String? _currentPath;

  Future<bool> hasPermission() => _recorder.hasPermission();

  Future<void> start() async {
    final dir = await getTemporaryDirectory();
    final path =
        '${dir.path}/care_record_${DateTime.now().millisecondsSinceEpoch}.wav';
    await _recorder.start(
      const rec.RecordConfig(
        encoder: rec.AudioEncoder.wav,
        sampleRate: 16000,
        numChannels: 1,
      ),
      path: path,
    );
    _currentPath = path;
  }

  Future<String> stopAndGetPath() async {
    final stoppedPath = await _recorder.stop();
    final path = stoppedPath ?? _currentPath;
    if (path == null) {
      throw StateError('stopAndGetPath() called without a prior start()');
    }
    _currentPath = null;
    return path;
  }

  /// Releases native resources. Call when the recorder is no longer needed.
  void dispose() => _recorder.dispose();
}

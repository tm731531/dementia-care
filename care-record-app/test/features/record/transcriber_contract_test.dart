import 'package:flutter_test/flutter_test.dart';
import 'package:care_record_app/features/record/service/transcriber.dart';

class _FakeTranscriber implements Transcriber {
  @override
  Future<void> ensureReady() async {}

  @override
  Future<String> transcribe(String audioFilePath) async => '午餐吃一半，左手會痛';
}

void main() {
  test('Transcriber returns the spoken text for an audio path', () async {
    final Transcriber t = _FakeTranscriber();
    final text = await t.transcribe('/tmp/whatever.wav');
    expect(text, '午餐吃一半，左手會痛');
  });
}

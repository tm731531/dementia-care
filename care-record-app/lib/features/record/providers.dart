import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import 'data/local_db.dart';
import 'data/note_dao.dart';
import 'data/photo_store.dart';
import 'model/care_note.dart';
import 'service/audio_recorder.dart';
import 'service/transcriber.dart';

/// Opens the app's local SQLite DB once at startup; cached for the app's
/// lifetime by Riverpod (default `FutureProvider`, not `autoDispose`).
final dbProvider = FutureProvider<Database>((ref) async {
  final dir = await getApplicationDocumentsDirectory();
  final path = p.join(dir.path, 'care_record.db');
  return LocalDb.open(path);
});

final noteDaoProvider = FutureProvider<NoteDao>((ref) async {
  final db = await ref.watch(dbProvider.future);
  return NoteDao(db);
});

/// Newest-first note list. Invalidate after a save so the list screen
/// re-fetches instead of showing stale cached data.
final notesProvider = FutureProvider<List<CareNote>>((ref) async {
  final dao = await ref.watch(noteDaoProvider.future);
  return dao.allNewestFirst();
});

/// App-lifetime singleton — released only when the ProviderScope itself is
/// torn down (app exit), not per-screen, so the mic isn't re-acquired on
/// every navigation.
final audioRecorderProvider = Provider<AudioRecorder>((ref) {
  final recorder = AudioRecorder();
  ref.onDispose(recorder.dispose);
  return recorder;
});

/// App-lifetime singleton so the one-time model download/init survives
/// navigating away from and back to the record screen.
final transcriberProvider = Provider<Transcriber>((ref) {
  final transcriber = SherpaTranscriber();
  ref.onDispose(transcriber.dispose);
  return transcriber;
});

/// Copies picked photos into the app's local documents dir. Stateless
/// (no dispose needed), so a plain `Provider` is enough.
final photoStoreProvider = Provider<PhotoStore>((ref) => PhotoStore());

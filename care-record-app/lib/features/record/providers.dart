import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import 'data/current_patient.dart';
import 'data/local_db.dart';
import 'data/note_dao.dart';
import 'data/patient_dao.dart';
import 'data/photo_store.dart';
import 'model/care_note.dart';
import 'model/patient.dart';
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

final patientDaoProvider = FutureProvider<PatientDao>((ref) async {
  final db = await ref.watch(dbProvider.future);
  return PatientDao(db);
});

/// The device's default patient id (single-patient devices always have
/// exactly one, seeded by the DB migration/onCreate). The record screen
/// still saves against this for now — Task 4 switches it to
/// [currentPatientProvider].
final defaultPatientIdProvider = FutureProvider<String>((ref) async {
  final patientDao = await ref.watch(patientDaoProvider.future);
  final patients = await patientDao.all();
  return patients.first.id;
});

/// All patients on this device, in DB order.
final patientsProvider = FutureProvider<List<Patient>>((ref) async {
  final patientDao = await ref.watch(patientDaoProvider.future);
  return patientDao.all();
});

/// The persisted "current patient id" store. Overridden with a fake in
/// widget tests that don't want the real SharedPreferences plugin channel.
final currentPatientStoreProvider = Provider<CurrentPatientStore>((ref) => CurrentPatientStore());

/// The user's selected patient id, persisted across restarts.
///
/// State is `null` until [CurrentPatientStore.load] resolves (kicked off
/// from [build]) — [currentPatientProvider] below is what code should
/// actually watch, since it already falls back to the first patient while
/// this is still loading.
class CurrentPatientIdNotifier extends Notifier<String?> {
  @override
  String? build() {
    _loadStored();
    return null;
  }

  Future<void> _loadStored() async {
    final store = ref.read(currentPatientStoreProvider);
    final stored = await store.load();
    // Guard against the notifier having been disposed while awaiting.
    if (ref.exists(currentPatientIdProvider) && stored != null) {
      state = stored;
    }
  }

  /// Selects [id] as the current patient and persists the choice.
  Future<void> select(String id) async {
    state = id;
    await ref.read(currentPatientStoreProvider).save(id);
  }
}

final currentPatientIdProvider = NotifierProvider<CurrentPatientIdNotifier, String?>(
  CurrentPatientIdNotifier.new,
);

/// The resolved current [Patient] — combines the persisted selection with
/// the live patient list via [resolveCurrentPatient], so a deleted or
/// not-yet-loaded selection always falls back to the first patient rather
/// than surfacing an error or another patient's data.
///
/// `AsyncLoading`/`AsyncError` only while [patientsProvider] itself hasn't
/// resolved (e.g. DB still opening); once patients are loaded this is
/// always `AsyncData`, even before [CurrentPatientIdNotifier] finishes
/// loading the persisted id (falls back to the first patient meanwhile).
final currentPatientProvider = Provider<AsyncValue<Patient>>((ref) {
  final patientsAsync = ref.watch(patientsProvider);
  final storedId = ref.watch(currentPatientIdProvider);
  return patientsAsync.whenData((patients) {
    final resolvedId = resolveCurrentPatient(storedId, patients);
    return patients.firstWhere(
      (p) => p.id == resolvedId,
      orElse: () => patients.first,
    );
  });
});

/// Newest-first note list, scoped to the current patient. Watches
/// [currentPatientProvider] so switching patients (via
/// `currentPatientIdProvider.select`) refreshes this automatically.
/// Invalidate after a save so the list screen re-fetches instead of
/// showing stale cached data.
final notesProvider = FutureProvider<List<CareNote>>((ref) async {
  final dao = await ref.watch(noteDaoProvider.future);
  final currentPatient = ref.watch(currentPatientProvider).valueOrNull;
  final String patientId;
  if (currentPatient != null) {
    patientId = currentPatient.id;
  } else {
    patientId = await ref.watch(defaultPatientIdProvider.future);
  }
  return dao.allNewestFirstForPatient(patientId);
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

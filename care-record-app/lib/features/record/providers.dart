import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:package_info_plus/package_info_plus.dart';

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

/// The user's selected patient id, persisted across restarts, plus whether
/// the initial [CurrentPatientStore.load] has completed.
///
/// [loaded] starts `false` and flips to `true` exactly once, when [build]'s
/// kicked-off load resolves — even if there was nothing stored (`id` stays
/// `null` in that case). [currentPatientProvider] watches [loaded] to stay
/// `AsyncLoading` until then, instead of racing ahead and resolving against
/// the wrong (first) patient on a multi-patient cold start.
typedef CurrentPatientIdState = ({String? id, bool loaded});

class CurrentPatientIdNotifier extends Notifier<CurrentPatientIdState> {
  @override
  CurrentPatientIdState build() {
    _loadStored();
    return (id: null, loaded: false);
  }

  Future<void> _loadStored() async {
    final store = ref.read(currentPatientStoreProvider);
    final stored = await store.load();
    // Guard against the notifier having been disposed while awaiting.
    if (ref.exists(currentPatientIdProvider)) {
      state = (id: stored, loaded: true);
    }
  }

  /// Selects [id] as the current patient and persists the choice.
  Future<void> select(String id) async {
    state = (id: id, loaded: true);
    await ref.read(currentPatientStoreProvider).save(id);
  }
}

final currentPatientIdProvider =
    NotifierProvider<CurrentPatientIdNotifier, CurrentPatientIdState>(
  CurrentPatientIdNotifier.new,
);

/// The resolved current [Patient] — combines the persisted selection with
/// the live patient list via [resolveCurrentPatient], so a deleted
/// selection falls back to the first patient rather than surfacing an
/// error or another patient's data.
///
/// Stays `AsyncLoading` until both [patientsProvider] has resolved AND the
/// initial persisted-id load ([CurrentPatientIdNotifier]'s `loaded` flag)
/// has completed — so nothing ever reads a "current patient" that was
/// resolved before we actually knew which one was selected. Never throws:
/// an empty patient list (should not normally happen — the DB migration
/// always seeds one, and [PatientDao.delete] refuses to remove the last
/// one) resolves to `AsyncError` instead of crashing.
final currentPatientProvider = Provider<AsyncValue<Patient>>((ref) {
  final patientsAsync = ref.watch(patientsProvider);
  final currentIdState = ref.watch(currentPatientIdProvider);

  if (!currentIdState.loaded) {
    return const AsyncValue<Patient>.loading();
  }

  return patientsAsync.when(
    data: (patients) {
      if (patients.isEmpty) {
        return AsyncValue<Patient>.error(
          StateError('no patients'),
          StackTrace.current,
        );
      }
      final resolvedId = resolveCurrentPatient(currentIdState.id, patients);
      final patient = patients.firstWhere(
        (p) => p.id == resolvedId,
        orElse: () => patients.first,
      );
      return AsyncValue.data(patient);
    },
    error: (e, st) => AsyncValue.error(e, st),
    loading: () => const AsyncValue.loading(),
  );
});

/// Newest-first note list, scoped to the current patient. Watches
/// [currentPatientProvider] so switching patients (via
/// `currentPatientIdProvider.select`) refreshes this automatically.
///
/// Stays in a loading state while [currentPatientProvider] is still
/// resolving (e.g. the initial current-patient-id load from
/// SharedPreferences hasn't finished yet), instead of falling back to
/// [defaultPatientIdProvider] and briefly showing the wrong patient's notes
/// on a multi-patient cold start.
///
/// Invalidate after a save so the list screen re-fetches instead of
/// showing stale cached data.
final notesProvider = FutureProvider<List<CareNote>>((ref) async {
  final dao = await ref.watch(noteDaoProvider.future);
  final currentPatientAsync = ref.watch(currentPatientProvider);

  if (currentPatientAsync.isLoading) {
    // Never resolves; this build is superseded once currentPatientProvider
    // settles (watched above, so it triggers a rebuild) — well before any
    // real UI would time out.
    return Completer<List<CareNote>>().future;
  }

  final String? currentPatientId = currentPatientAsync.valueOrNull?.id;
  final String patientId =
      currentPatientId ?? await ref.watch(defaultPatientIdProvider.future);
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

/// App version string ("vX.Y.Z+build") for display in AppBars.
final appVersionProvider = FutureProvider<String>((ref) async {
  final info = await PackageInfo.fromPlatform();
  return 'v${info.version}+${info.buildNumber}';
});

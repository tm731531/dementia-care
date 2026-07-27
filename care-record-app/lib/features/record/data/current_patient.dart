import 'package:shared_preferences/shared_preferences.dart';

import '../model/patient.dart';

/// Resolves which patient should be "current" given the last-persisted
/// choice and the live patient list.
///
/// - [stored] matches an existing patient's id -> that id (normal case).
/// - [stored] is null (first launch, nothing chosen yet) -> the first
///   patient.
/// - [stored] no longer matches any patient (e.g. that patient was
///   deleted on another device and the deletion synced in) -> falls back
///   to the first patient rather than pointing at a dangling id.
///
/// [patients] is assumed non-empty — the DB migration always seeds at
/// least one default patient. If it is somehow empty, returns `''`
/// (documented edge case; callers should not persist this value).
String resolveCurrentPatient(String? stored, List<Patient> patients) {
  if (patients.isEmpty) return '';
  if (stored != null && patients.any((p) => p.id == stored)) {
    return stored;
  }
  return patients.first.id;
}

/// Persists the user's selected patient id across app restarts.
///
/// Thin wrapper around [SharedPreferences] so it's easy to inject in tests
/// (pass a pre-configured [SharedPreferences] via [prefs]) without pulling
/// in the platform channel every time.
class CurrentPatientStore {
  static const _key = 'current_patient_id';

  final Future<SharedPreferences> Function() _getPrefs;

  CurrentPatientStore({SharedPreferences? prefs})
      : _getPrefs = (prefs != null ? (() async => prefs) : SharedPreferences.getInstance);

  Future<String?> load() async {
    final prefs = await _getPrefs();
    return prefs.getString(_key);
  }

  Future<void> save(String id) async {
    final prefs = await _getPrefs();
    await prefs.setString(_key, id);
  }
}

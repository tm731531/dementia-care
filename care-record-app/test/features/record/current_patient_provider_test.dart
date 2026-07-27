import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:care_record_app/features/record/data/current_patient.dart';
import 'package:care_record_app/features/record/model/patient.dart';
import 'package:care_record_app/features/record/providers.dart';

/// [currentPatientProvider] must never let an empty patient list crash the
/// app via an unguarded `.first`/`firstWhere` call — this should not
/// normally happen (the DB migration always seeds one default patient, and
/// [PatientDao.delete] now refuses to remove the last one), but if that
/// invariant ever regresses, the provider must degrade to `AsyncError`
/// rather than throwing a raw `StateError` out of a `Provider` read.
void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
  });

  test('resolves to AsyncError (not a thrown StateError) when the patient list is empty', () async {
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(overrides: [
      patientsProvider.overrideWith((ref) async => const <Patient>[]),
      currentPatientStoreProvider.overrideWithValue(CurrentPatientStore(prefs: prefs)),
    ]);
    addTearDown(container.dispose);

    // Let the empty patient list resolve.
    await container.read(patientsProvider.future);

    // Wait for the initial persisted-id load to finish — currentPatientProvider
    // itself waits on this same flag before resolving.
    if (!container.read(currentPatientIdProvider).loaded) {
      final completer = Completer<void>();
      final sub = container.listen(currentPatientIdProvider, (prev, next) {
        if (next.loaded && !completer.isCompleted) completer.complete();
      });
      await completer.future;
      sub.close();
    }

    // The call itself must not throw.
    final result = container.read(currentPatientProvider);
    expect(result.hasError, isTrue);
    expect(result.valueOrNull, isNull);
  });
}

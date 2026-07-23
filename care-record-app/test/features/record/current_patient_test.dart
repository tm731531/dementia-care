import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:care_record_app/features/record/data/current_patient.dart';
import 'package:care_record_app/features/record/model/patient.dart';

void main() {
  group('resolveCurrentPatient', () {
    const p1 = Patient(id: 'p1', name: '甲');
    const p2 = Patient(id: 'p2', name: '乙');

    test('stored id present in list -> returns it', () {
      expect(resolveCurrentPatient('p2', [p1, p2]), 'p2');
    });

    test('stored null -> returns first', () {
      expect(resolveCurrentPatient(null, [p1, p2]), 'p1');
    });

    test('stored id not in list (e.g. deleted patient) -> returns first', () {
      expect(resolveCurrentPatient('deleted', [p1, p2]), 'p1');
    });

    test('single-patient list -> returns that one', () {
      expect(resolveCurrentPatient(null, [p1]), 'p1');
      expect(resolveCurrentPatient('anything-else', [p1]), 'p1');
    });
  });

  group('CurrentPatientStore', () {
    setUp(() {
      TestWidgetsFlutterBinding.ensureInitialized();
      SharedPreferences.setMockInitialValues({});
    });

    test('save then load round-trips the id', () async {
      final store = CurrentPatientStore();
      await store.save('p2');
      expect(await store.load(), 'p2');
    });

    test('load with nothing stored returns null', () async {
      final store = CurrentPatientStore();
      expect(await store.load(), isNull);
    });
  });
}

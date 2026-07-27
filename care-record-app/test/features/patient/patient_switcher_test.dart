import 'package:flutter_test/flutter_test.dart';

import 'package:care_record_app/features/patient/patient_switcher.dart';

/// [showSwitcher] is the sole visibility rule for [PatientSwitcher]: it must
/// stay invisible on single-patient devices (the common case) and only
/// appear once there's an actual choice to make.
void main() {
  group('showSwitcher', () {
    test('hidden with 0 patients', () {
      expect(showSwitcher(0), isFalse);
    });

    test('hidden with exactly 1 patient (the common single-patient device)', () {
      expect(showSwitcher(1), isFalse);
    });

    test('visible with 2 patients', () {
      expect(showSwitcher(2), isTrue);
    });

    test('visible with more than 2 patients', () {
      expect(showSwitcher(3), isTrue);
    });
  });
}

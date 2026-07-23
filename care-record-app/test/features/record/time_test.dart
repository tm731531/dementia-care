import 'package:flutter_test/flutter_test.dart';
import 'package:care_record_app/core/time.dart';

void main() {
  test('shiftOfDay buckets by caregiving shift', () {
    expect(shiftOfDay(DateTime(2026, 7, 21, 9)), '早');   // 06-14
    expect(shiftOfDay(DateTime(2026, 7, 21, 15)), '晚');  // 14-22
    expect(shiftOfDay(DateTime(2026, 7, 21, 23)), '大夜'); // 22-06
    expect(shiftOfDay(DateTime(2026, 7, 21, 3)), '大夜');
  });
}

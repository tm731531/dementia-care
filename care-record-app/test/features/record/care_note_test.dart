import 'package:flutter_test/flutter_test.dart';
import 'package:care_record_app/features/record/model/note_author.dart';
import 'package:care_record_app/features/record/model/care_note.dart';

void main() {
  test('NoteAuthor round-trips through its code', () {
    expect(NoteAuthor.family.code, 'F');
    expect(NoteAuthor.caregiver.code, 'C');
    expect(NoteAuthor.fromCode('F'), NoteAuthor.family);
    expect(NoteAuthor.fromCode('C'), NoteAuthor.caregiver);
  });

  test('CareNote serialises and deserialises losslessly', () {
    final note = CareNote(
      id: 'uuid-123',
      timestamp: DateTime.utc(2026, 7, 21, 22, 57),
      author: NoteAuthor.family,
      text: '測試筆記內容一',
      patientId: 'p1',
      photoPath: '/data/photos/uuid-123.jpg',
    );
    final restored = CareNote.fromJson(note.toJson());
    expect(restored.id, note.id);
    // fromJson now converts to local time for correct display (timezone
    // fix), so the restored DateTime's isUtc flag differs from the UTC
    // DateTime constructed above even though it's the same instant —
    // compare by moment, not by Dart's flag-sensitive `==`.
    expect(restored.timestamp.isAtSameMomentAs(note.timestamp), isTrue);
    expect(restored.author, NoteAuthor.family);
    expect(restored.text, note.text);
    expect(restored.photoPath, note.photoPath);
  });

  test('CareNote tolerates a null photoPath', () {
    final note = CareNote(
      id: 'x', timestamp: DateTime.utc(2026, 7, 21), author: NoteAuthor.caregiver, text: 'ok', patientId: 'p1');
    final restored = CareNote.fromJson(note.toJson());
    expect(restored.photoPath, isNull);
  });

  test('CareNote round-trip preserves local display hour on non-UTC devices', () {
    // A note saved at local 09:00 must still show local hour 9 after
    // round-tripping through toJson (stores UTC) / fromJson (must convert
    // back to local) — regression for the "displays as 大夜/01:00" bug.
    final localTimestamp = DateTime(2026, 7, 21, 9, 0);
    final note = CareNote(
      id: 'tz-1',
      timestamp: localTimestamp,
      author: NoteAuthor.family,
      text: '早上量血壓',
      patientId: 'p1',
    );
    final restored = CareNote.fromJson(note.toJson());

    expect(restored.timestamp, note.timestamp); // same instant
    expect(restored.timestamp.toLocal().hour, 9); // correct local hour for display
  });
}

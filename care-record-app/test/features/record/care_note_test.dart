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
      photoPath: '/data/photos/uuid-123.jpg',
    );
    final restored = CareNote.fromJson(note.toJson());
    expect(restored.id, note.id);
    expect(restored.timestamp, note.timestamp);
    expect(restored.author, NoteAuthor.family);
    expect(restored.text, note.text);
    expect(restored.photoPath, note.photoPath);
  });

  test('CareNote tolerates a null photoPath', () {
    final note = CareNote(
      id: 'x', timestamp: DateTime.utc(2026, 7, 21), author: NoteAuthor.caregiver, text: 'ok');
    final restored = CareNote.fromJson(note.toJson());
    expect(restored.photoPath, isNull);
  });
}

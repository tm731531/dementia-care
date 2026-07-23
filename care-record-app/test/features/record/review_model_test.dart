import 'package:flutter_test/flutter_test.dart';
import 'package:care_record_app/features/record/model/note_author.dart';
import 'package:care_record_app/features/record/model/care_note.dart';
import 'package:care_record_app/features/record/view/review_model.dart';

CareNote _note(String id, DateTime timestamp) => CareNote(
      id: id,
      timestamp: timestamp,
      author: NoteAuthor.family,
      text: 'note $id',
    );

void main() {
  group('groupNotesByLocalDate', () {
    // 3 local dates, with day1 having two notes (out of chronological order
    // on input) to verify within-day ASC sorting.
    final day1Late = _note('day1-late', DateTime(2026, 7, 21, 20, 0));
    final day1Early = _note('day1-early', DateTime(2026, 7, 21, 8, 0));
    final day2 = _note('day2', DateTime(2026, 7, 22, 9, 0));
    final day3 = _note('day3', DateTime(2026, 7, 20, 23, 30));

    final notes = [day1Late, day1Early, day2, day3];

    test('groups by local calendar date, dates DESC', () {
      final groups = groupNotesByLocalDate(notes);

      expect(groups.length, 3);
      expect(groups[0].date, DateTime(2026, 7, 22));
      expect(groups[1].date, DateTime(2026, 7, 21));
      expect(groups[2].date, DateTime(2026, 7, 20));
    });

    test('within a date group, notes are sorted ASC by timestamp', () {
      final groups = groupNotesByLocalDate(notes);
      final day21Group = groups.firstWhere((g) => g.date == DateTime(2026, 7, 21));

      expect(day21Group.notes.length, 2);
      expect(day21Group.notes[0].id, 'day1-early');
      expect(day21Group.notes[1].id, 'day1-late');
    });

    test('from/to filters by local calendar date, inclusive', () {
      final groups = groupNotesByLocalDate(
        notes,
        from: DateTime(2026, 7, 21),
        to: DateTime(2026, 7, 21),
      );

      expect(groups.length, 1);
      expect(groups.single.date, DateTime(2026, 7, 21));
      expect(groups.single.notes.length, 2);
    });

    test('from/to boundaries are inclusive of the whole day regardless of time-of-day', () {
      final groups = groupNotesByLocalDate(
        notes,
        from: DateTime(2026, 7, 20),
        to: DateTime(2026, 7, 22),
      );
      expect(groups.length, 3);
    });

    test('notes outside the range are excluded', () {
      final groups = groupNotesByLocalDate(
        notes,
        from: DateTime(2026, 7, 22),
        to: DateTime(2026, 7, 22),
      );

      expect(groups.length, 1);
      expect(groups.single.notes.single.id, 'day2');
    });

    test('null from/to is unbounded', () {
      final groups = groupNotesByLocalDate(notes, from: null, to: null);
      expect(groups.length, 3);
    });

    test('empty input yields empty output', () {
      expect(groupNotesByLocalDate([]), isEmpty);
    });
  });
}

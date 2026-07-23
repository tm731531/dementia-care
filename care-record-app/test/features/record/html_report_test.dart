import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:care_record_app/features/record/model/care_note.dart';
import 'package:care_record_app/features/record/model/note_author.dart';
import 'package:care_record_app/features/record/service/html_report.dart';
import 'package:care_record_app/features/record/view/review_model.dart';

void main() {
  group('buildHtmlReport', () {
    final from = DateTime(2026, 7, 20);
    final to = DateTime(2026, 7, 22);

    final photoNote = CareNote(
      id: 'photo-note',
      timestamp: DateTime(2026, 7, 21, 8, 30),
      author: NoteAuthor.caregiver,
      text: '早餐吃了半碗稀飯',
      patientId: 'p1',
      photoPath: 'fake/whiteboard.jpg',
    );

    final xssNote = CareNote(
      id: 'xss-note',
      timestamp: DateTime(2026, 7, 22, 20, 0),
      author: NoteAuthor.family,
      text: '<script>alert(1)</script> & "quotes" <b>bold</b>',
      patientId: 'p1',
    );

    final groups = groupNotesByLocalDate([photoNote, xssNote], from: from, to: to);

    test('produces a self-contained offline HTML document', () {
      final html = buildHtmlReport(
        groups,
        from: from,
        to: to,
        readPhotoBytes: (path) =>
            path == 'fake/whiteboard.jpg' ? Uint8List.fromList([1, 2, 3]) : null,
      );

      expect(html.startsWith('<!doctype html'), isTrue);
      expect(html.contains('照護紀錄整理'), isTrue);
      expect(html.contains('2026-07-20'), isTrue);
      expect(html.contains('2026-07-22'), isTrue);
      expect(html.contains('共 2 筆'), isTrue);

      // date headings
      expect(html.contains('2026-07-21'), isTrue);

      // note text present (escaped) and embedded photo present
      expect(html.contains('早餐吃了半碗稀飯'), isTrue);
      expect(html.contains('data:image/jpeg;base64,'), isTrue);

      // offline guarantee: no external URLs anywhere in the document
      expect(html.contains('http://'), isFalse);
      expect(html.contains('https://'), isFalse);
    });

    test('escapes HTML-significant characters in note text', () {
      final html = buildHtmlReport(groups, from: from, to: to);

      expect(html.contains('<script>alert(1)</script>'), isFalse);
      expect(html.contains('&lt;script&gt;'), isTrue);
      expect(html.contains('&amp;'), isTrue);
      expect(html.contains('&quot;'), isTrue);
    });

    test('omits image gracefully when readPhotoBytes is null', () {
      final html = buildHtmlReport(groups, from: from, to: to);

      expect(html.contains('data:image'), isFalse);
      // rest of the note still renders
      expect(html.contains('早餐吃了半碗稀飯'), isTrue);
    });

    test('omits image gracefully when readPhotoBytes returns null for the path', () {
      final html = buildHtmlReport(
        groups,
        from: from,
        to: to,
        readPhotoBytes: (path) => null,
      );

      expect(html.contains('data:image'), isFalse);
    });

    test('empty groups still produce a valid document with 0 count', () {
      final html = buildHtmlReport(const [], from: from, to: to);

      expect(html.startsWith('<!doctype html'), isTrue);
      expect(html.contains('共 0 筆'), isTrue);
    });
  });
}

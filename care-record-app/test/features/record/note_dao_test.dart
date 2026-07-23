import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:care_record_app/features/record/data/local_db.dart';
import 'package:care_record_app/features/record/data/note_dao.dart';
import 'package:care_record_app/features/record/model/care_note.dart';
import 'package:care_record_app/features/record/model/note_author.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test('insert then read back, newest first', () async {
    final db = await LocalDb.open(inMemoryDatabasePath);
    final dao = NoteDao(db);
    await dao.insert(CareNote(
        id: 'a', timestamp: DateTime.utc(2026, 7, 20, 8), author: NoteAuthor.family, text: '測試內容甲'));
    await dao.insert(CareNote(
        id: 'b', timestamp: DateTime.utc(2026, 7, 21, 22), author: NoteAuthor.caregiver, text: '測試內容乙'));
    final all = await dao.allNewestFirst();
    expect(all.map((n) => n.id).toList(), ['b', 'a']); // newest first
    expect(all.first.author, NoteAuthor.caregiver);
    await db.close();
  });

  test('inserting the same id twice replaces, does not duplicate (import-safe)', () async {
    final db = await LocalDb.open(inMemoryDatabasePath);
    final dao = NoteDao(db);
    await dao.insert(CareNote(
        id: 'dup', timestamp: DateTime.utc(2026, 7, 21), author: NoteAuthor.family, text: 'v1'));
    await dao.insert(CareNote(
        id: 'dup', timestamp: DateTime.utc(2026, 7, 21), author: NoteAuthor.family, text: 'v2'));
    final all = await dao.allNewestFirst();
    expect(all.length, 1);
    expect(all.single.text, 'v2');
    await db.close();
  });
}

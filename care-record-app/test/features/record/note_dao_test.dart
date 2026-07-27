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
        id: 'a', timestamp: DateTime.utc(2026, 7, 20, 8), author: NoteAuthor.family, text: '測試內容甲', patientId: 'p1'));
    await dao.insert(CareNote(
        id: 'b', timestamp: DateTime.utc(2026, 7, 21, 22), author: NoteAuthor.caregiver, text: '測試內容乙', patientId: 'p1'));
    final all = await dao.allNewestFirst();
    expect(all.map((n) => n.id).toList(), ['b', 'a']); // newest first
    expect(all.first.author, NoteAuthor.caregiver);
    await db.close();
  });

  test('inserting the same id twice replaces, does not duplicate (import-safe)', () async {
    final db = await LocalDb.open(inMemoryDatabasePath);
    final dao = NoteDao(db);
    await dao.insert(CareNote(
        id: 'dup', timestamp: DateTime.utc(2026, 7, 21), author: NoteAuthor.family, text: 'v1', patientId: 'p1'));
    await dao.insert(CareNote(
        id: 'dup', timestamp: DateTime.utc(2026, 7, 21), author: NoteAuthor.family, text: 'v2', patientId: 'p1'));
    final all = await dao.allNewestFirst();
    expect(all.length, 1);
    expect(all.single.text, 'v2');
    await db.close();
  });

  test('inserting an existing id with new text updates the row in place (edit path)', () async {
    final db = await LocalDb.open(inMemoryDatabasePath);
    final dao = NoteDao(db);
    final original = CareNote(
        id: 'edit-1', timestamp: DateTime.utc(2026, 7, 21, 9), author: NoteAuthor.caregiver, text: '原始內容', patientId: 'p1');
    await dao.insert(original);
    final edited = CareNote(
        id: original.id,
        timestamp: original.timestamp,
        author: original.author,
        text: '修改後內容',
        patientId: original.patientId);
    await dao.insert(edited);
    final all = await dao.allNewestFirst();
    expect(all.length, 1); // updated, not duplicated
    expect(all.single.id, 'edit-1');
    expect(all.single.text, '修改後內容');
    // fromJson round-trips through toLocal(), so compare the instant rather
    // than DateTime== (which also checks the UTC/local flag).
    expect(all.single.timestamp.isAtSameMomentAs(original.timestamp), isTrue); // preserved
    expect(all.single.author, NoteAuthor.caregiver); // preserved
    await db.close();
  });

  test('delete removes only the targeted note', () async {
    final db = await LocalDb.open(inMemoryDatabasePath);
    final dao = NoteDao(db);
    await dao.insert(CareNote(
        id: 'keep', timestamp: DateTime.utc(2026, 7, 20, 8), author: NoteAuthor.family, text: '留著', patientId: 'p1'));
    await dao.insert(CareNote(
        id: 'gone', timestamp: DateTime.utc(2026, 7, 21, 8), author: NoteAuthor.family, text: '刪掉', patientId: 'p1'));
    await dao.delete('gone');
    final all = await dao.allNewestFirst();
    expect(all.length, 1);
    expect(all.single.id, 'keep');
    await db.close();
  });

  test('deleting a non-existent id is a no-op, does not throw', () async {
    final db = await LocalDb.open(inMemoryDatabasePath);
    final dao = NoteDao(db);
    await dao.insert(CareNote(
        id: 'only', timestamp: DateTime.utc(2026, 7, 20, 8), author: NoteAuthor.family, text: '唯一一筆', patientId: 'p1'));
    await dao.delete('does-not-exist');
    final all = await dao.allNewestFirst();
    expect(all.length, 1);
    expect(all.single.id, 'only');
    await db.close();
  });
}

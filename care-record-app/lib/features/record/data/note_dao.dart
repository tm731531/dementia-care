import 'package:sqflite/sqflite.dart';
import '../model/care_note.dart';

class NoteDao {
  final Database _db;
  NoteDao(this._db);

  Future<void> insert(CareNote n) => _db.insert(
        'care_note',
        n.toJson(),
        conflictAlgorithm: ConflictAlgorithm.replace, // idempotent by id → import-safe
      );

  Future<List<CareNote>> allNewestFirst() async {
    final rows = await _db.query('care_note', orderBy: 'timestamp DESC');
    return rows.map(CareNote.fromJson).toList();
  }

  /// Same as [allNewestFirst] but scoped to one patient (Plan 3 multi-patient).
  Future<List<CareNote>> allNewestFirstForPatient(String patientId) async {
    final rows = await _db.query(
      'care_note',
      where: 'patientId = ?',
      whereArgs: [patientId],
      orderBy: 'timestamp DESC',
    );
    return rows.map(CareNote.fromJson).toList();
  }

  /// All note ids currently stored — one query, used by import to tell
  /// "already had this note" apart from "newly inserted".
  Future<Set<String>> existsIds() async {
    final rows = await _db.query('care_note', columns: ['id']);
    return rows.map((r) => r['id'] as String).toSet();
  }

  /// Deletes a single note by id. A no-op (does not throw) if the id
  /// doesn't exist — used by the edit screen's "刪除這筆" action.
  Future<void> delete(String id) =>
      _db.delete('care_note', where: 'id = ?', whereArgs: [id]);
}

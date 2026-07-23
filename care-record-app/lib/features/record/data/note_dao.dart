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
}

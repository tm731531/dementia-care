import 'package:sqflite/sqflite.dart';
import '../model/patient.dart';

class PatientDao {
  final Database _db;
  PatientDao(this._db);

  Future<void> insert(Patient p) => _db.insert(
        'patient',
        p.toJson(),
        conflictAlgorithm: ConflictAlgorithm.replace, // idempotent by id → import-safe
      );

  Future<List<Patient>> all() async {
    final rows = await _db.query('patient');
    return rows.map(Patient.fromJson).toList();
  }

  /// Deletes [id]'s notes, then the patient row itself, in one transaction —
  /// so a crash mid-delete can never leave orphaned notes pointing at a
  /// patient that no longer exists. (Photo-file cleanup is a higher layer,
  /// Plan 3 Task 4 — this DAO only touches DB rows.)
  Future<void> delete(String id) => _db.transaction((txn) async {
        await txn.delete('care_note', where: 'patientId = ?', whereArgs: [id]);
        await txn.delete('patient', where: 'id = ?', whereArgs: [id]);
      });
}

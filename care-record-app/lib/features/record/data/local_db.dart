import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

/// Display name for the auto-created patient that every device (fresh or
/// migrated from v1) always has at least one of, so callers never have to
/// special-case "no patient yet".
const _defaultPatientName = '本人';

class LocalDb {
  static Future<Database> open(String path) => openDatabase(
        path,
        version: 2,
        onCreate: (db, _) async {
          await db.execute('''
            CREATE TABLE patient (
              id TEXT PRIMARY KEY,
              name TEXT NOT NULL
            )
          ''');
          await db.execute('''
            CREATE TABLE care_note (
              id TEXT PRIMARY KEY,
              timestamp TEXT NOT NULL,
              author TEXT NOT NULL,
              text TEXT NOT NULL,
              photoPath TEXT,
              patientId TEXT
            )
          ''');
          await _seedDefaultPatient(db);
        },
        onUpgrade: (db, oldVersion, newVersion) async {
          if (oldVersion < 2) {
            await db.execute('''
              CREATE TABLE patient (
                id TEXT PRIMARY KEY,
                name TEXT NOT NULL
              )
            ''');
            // Existing care_note table (and its rows) is untouched — just
            // widened with a nullable column so no data loss is possible.
            await db.execute('ALTER TABLE care_note ADD COLUMN patientId TEXT');
            final defaultPatientId = await _seedDefaultPatient(db);
            // Backfill EVERY pre-v2 note (all of them, since the column was
            // just added) onto the one default patient.
            await db.update(
              'care_note',
              {'patientId': defaultPatientId},
              where: 'patientId IS NULL',
            );
          }
        },
      );

  static Future<String> _seedDefaultPatient(DatabaseExecutor db) async {
    final id = const Uuid().v4();
    await db.insert('patient', {'id': id, 'name': _defaultPatientName});
    return id;
  }
}

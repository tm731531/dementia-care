import 'package:sqflite/sqflite.dart';

class LocalDb {
  static Future<Database> open(String path) => openDatabase(
        path,
        version: 1,
        onCreate: (db, _) async {
          await db.execute('''
            CREATE TABLE care_note (
              id TEXT PRIMARY KEY,
              timestamp TEXT NOT NULL,
              author TEXT NOT NULL,
              text TEXT NOT NULL,
              photoPath TEXT
            )
          ''');
        },
      );
}

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:care_record_app/features/record/data/local_db.dart';
import 'package:care_record_app/features/record/data/note_dao.dart';
import 'package:care_record_app/features/record/data/patient_dao.dart';
import 'package:care_record_app/features/record/model/care_note.dart';
import 'package:care_record_app/features/record/model/note_author.dart';
import 'package:care_record_app/features/record/model/patient.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('patient_migration_test_');
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('v1 -> v2 migration (data safety)', () {
    test('preserves every existing note and backfills it onto one default patient', () async {
      final dbPath = p.join(tempDir.path, 'migrate.db');

      // Simulate a real v1 install on disk: the OLD care_note schema, no
      // patientId column at all, with 2 real notes already in it.
      final v1Db = await openDatabase(
        dbPath,
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
      await v1Db.insert('care_note', {
        'id': 'note-1',
        'timestamp': '2026-07-20T08:00:00.000Z',
        'author': 'F',
        'text': '舊筆記一',
        'photoPath': null,
      });
      await v1Db.insert('care_note', {
        'id': 'note-2',
        'timestamp': '2026-07-21T09:00:00.000Z',
        'author': 'C',
        'text': '舊筆記二',
        'photoPath': null,
      });
      await v1Db.close();

      // Reopen through the real app entry point (now v2) — this is the
      // exact code path the app takes on a real upgrade, so it must
      // trigger onUpgrade and run the migration.
      final db = await LocalDb.open(dbPath);
      final patientDao = PatientDao(db);
      final noteDao = NoteDao(db);

      final patients = await patientDao.all();
      expect(patients.length, 1);
      expect(patients.single.name, '本人');
      final defaultId = patients.single.id;

      final notes = await noteDao.allNewestFirst();
      expect(notes.length, 2); // 0 notes lost
      expect(notes.map((n) => n.id).toSet(), {'note-1', 'note-2'});
      // 0 notes with null/mismatched patientId — every old note backfilled
      // onto the same default patient.
      expect(notes.every((n) => n.patientId == defaultId), isTrue);

      await db.close();
    });

    test('migration is safe to run against an empty v1 db (no notes to backfill)', () async {
      final dbPath = p.join(tempDir.path, 'migrate_empty.db');

      final v1Db = await openDatabase(
        dbPath,
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
      await v1Db.close();

      final db = await LocalDb.open(dbPath);
      final patients = await PatientDao(db).all();
      expect(patients.length, 1);
      expect(patients.single.name, '本人');

      final notes = await NoteDao(db).allNewestFirst();
      expect(notes, isEmpty);

      await db.close();
    });
  });

  group('fresh v2 install', () {
    test('a default patient exists immediately after LocalDb.open on a brand-new db', () async {
      final db = await LocalDb.open(inMemoryDatabasePath);
      final patients = await PatientDao(db).all();
      expect(patients.length, 1);
      expect(patients.single.name, '本人');
      await db.close();
    });
  });

  group('PatientDao', () {
    test('insert + all returns every inserted patient', () async {
      final db = await LocalDb.open(inMemoryDatabasePath);
      final dao = PatientDao(db);
      await dao.insert(const Patient(id: 'p1', name: '爸爸'));
      await dao.insert(const Patient(id: 'p2', name: '媽媽'));

      final all = await dao.all();
      // A default patient is also always present (seeded by LocalDb.open),
      // so assert containment rather than exact count.
      expect(all.map((p) => p.id).toSet().containsAll({'p1', 'p2'}), isTrue);
      expect(all.firstWhere((p) => p.id == 'p1').name, '爸爸');
      expect(all.firstWhere((p) => p.id == 'p2').name, '媽媽');

      await db.close();
    });

    test('inserting the same id twice replaces, does not duplicate (idempotent)', () async {
      final db = await LocalDb.open(inMemoryDatabasePath);
      final dao = PatientDao(db);
      await dao.insert(const Patient(id: 'dup', name: 'v1-name'));
      await dao.insert(const Patient(id: 'dup', name: 'v2-name'));

      final all = await dao.all();
      final dups = all.where((p) => p.id == 'dup').toList();
      expect(dups.length, 1);
      expect(dups.single.name, 'v2-name');

      await db.close();
    });

    test('delete removes the patient and its notes, leaving other patients + their notes intact', () async {
      final db = await LocalDb.open(inMemoryDatabasePath);
      final patientDao = PatientDao(db);
      final noteDao = NoteDao(db);

      await patientDao.insert(const Patient(id: 'keep', name: '保留'));
      await patientDao.insert(const Patient(id: 'gone', name: '刪除'));

      await noteDao.insert(CareNote(
        id: 'n-keep',
        timestamp: DateTime.utc(2026, 7, 20),
        author: NoteAuthor.family,
        text: '保留的筆記',
        patientId: 'keep',
      ));
      await noteDao.insert(CareNote(
        id: 'n-gone',
        timestamp: DateTime.utc(2026, 7, 20),
        author: NoteAuthor.family,
        text: '要刪除的筆記',
        patientId: 'gone',
      ));

      await patientDao.delete('gone');

      final patients = await patientDao.all();
      expect(patients.any((p) => p.id == 'gone'), isFalse);
      expect(patients.any((p) => p.id == 'keep'), isTrue);

      final notes = await noteDao.allNewestFirst();
      expect(notes.any((n) => n.id == 'n-gone'), isFalse);
      final keptNote = notes.firstWhere((n) => n.id == 'n-keep');
      expect(keptNote.patientId, 'keep');

      await db.close();
    });

    test('deleting the only remaining patient throws StateError and does not delete it', () async {
      final db = await LocalDb.open(inMemoryDatabasePath);
      final patientDao = PatientDao(db);

      // LocalDb.open already seeds one default patient, so this device has
      // exactly 1 — deleting it would leave 0, which must be refused.
      final before = await patientDao.all();
      expect(before.length, 1);
      final onlyPatientId = before.single.id;

      await expectLater(
        () => patientDao.delete(onlyPatientId),
        throwsA(isA<StateError>()),
      );

      final after = await patientDao.all();
      expect(after.length, 1);
      expect(after.single.id, onlyPatientId);

      await db.close();
    });
  });

  group('NoteDao.allNewestFirstForPatient', () {
    test('returns only the queried patient\'s notes, newest first', () async {
      final db = await LocalDb.open(inMemoryDatabasePath);
      final patientDao = PatientDao(db);
      final noteDao = NoteDao(db);

      await patientDao.insert(const Patient(id: 'p1', name: '甲'));
      await patientDao.insert(const Patient(id: 'p2', name: '乙'));

      await noteDao.insert(CareNote(
        id: 'p1-old',
        timestamp: DateTime.utc(2026, 7, 20, 8),
        author: NoteAuthor.family,
        text: 'p1 早上的紀錄',
        patientId: 'p1',
      ));
      await noteDao.insert(CareNote(
        id: 'p1-new',
        timestamp: DateTime.utc(2026, 7, 21, 8),
        author: NoteAuthor.family,
        text: 'p1 晚上的紀錄',
        patientId: 'p1',
      ));
      await noteDao.insert(CareNote(
        id: 'p2-note',
        timestamp: DateTime.utc(2026, 7, 22, 8),
        author: NoteAuthor.caregiver,
        text: 'p2 的紀錄',
        patientId: 'p2',
      ));

      final p1Notes = await noteDao.allNewestFirstForPatient('p1');
      expect(p1Notes.map((n) => n.id).toList(), ['p1-new', 'p1-old']);

      final p2Notes = await noteDao.allNewestFirstForPatient('p2');
      expect(p2Notes.map((n) => n.id).toList(), ['p2-note']);

      await db.close();
    });
  });
}

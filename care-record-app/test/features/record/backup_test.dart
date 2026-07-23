import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:care_record_app/features/record/data/local_db.dart';
import 'package:care_record_app/features/record/data/note_dao.dart';
import 'package:care_record_app/features/record/data/patient_dao.dart';
import 'package:care_record_app/features/record/model/care_note.dart';
import 'package:care_record_app/features/record/model/note_author.dart';
import 'package:care_record_app/features/record/model/patient.dart';
import 'package:care_record_app/features/record/service/backup.dart';

/// Builds a zip the same shape as [exportZip] produces, but from raw
/// `notes.json` bytes + an explicit photo file map — lets tests construct
/// malformed / inconsistent archives that a real export would never emit.
File _buildZip(
  Directory dir,
  String name, {
  required List<int> notesJsonBytes,
  Map<String, List<int>> photos = const {},
}) {
  final archive = Archive();
  archive.addFile(ArchiveFile('notes.json', notesJsonBytes.length, notesJsonBytes));
  for (final entry in photos.entries) {
    archive.addFile(ArchiveFile('photos/${entry.key}', entry.value.length, entry.value));
  }
  final file = File(p.join(dir.path, name));
  file.writeAsBytesSync(ZipEncoder().encode(archive));
  return file;
}

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('backup_test_');
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  const patient1 = Patient(id: 'p1', name: '甲');
  const patient2 = Patient(id: 'p2', name: '乙');

  test('exportZip writes patient.json + notes.json (only that patient\'s notes) + the referenced photo', () async {
    final sourcePhotosDir = Directory(p.join(tempDir.path, 'source_photos'))
      ..createSync(recursive: true);
    final photoFile = File(p.join(sourcePhotosDir.path, 'abc.jpg'));
    await photoFile.writeAsBytes([1, 2, 3, 4]);

    final db = await LocalDb.open(inMemoryDatabasePath);
    final dao = NoteDao(db);
    await dao.insert(CareNote(
      id: 'note-with-photo',
      timestamp: DateTime.utc(2026, 7, 20, 8),
      author: NoteAuthor.family,
      text: '有照片的紀錄',
      patientId: patient1.id,
      photoPath: photoFile.path,
    ));
    await dao.insert(CareNote(
      id: 'note-no-photo',
      timestamp: DateTime.utc(2026, 7, 21, 9),
      author: NoteAuthor.caregiver,
      text: '沒照片的紀錄',
      patientId: patient1.id,
    ));
    // Belongs to a different patient — must NOT end up in patient1's export.
    await dao.insert(CareNote(
      id: 'other-patient-note',
      timestamp: DateTime.utc(2026, 7, 21, 10),
      author: NoteAuthor.family,
      text: '不是甲的紀錄',
      patientId: patient2.id,
    ));

    final outDir = Directory(p.join(tempDir.path, 'export'))..createSync(recursive: true);
    final zipFile = await exportZip(patient: patient1, dao: dao, photosDir: sourcePhotosDir, outDir: outDir);

    expect(await zipFile.exists(), isTrue);

    final archive = ZipDecoder().decodeBytes(await zipFile.readAsBytes());
    final patientFile = archive.findFile('patient.json');
    expect(patientFile, isNotNull);
    expect(
      Patient.fromJson(jsonDecode(utf8.decode(patientFile!.content)) as Map<String, dynamic>).id,
      patient1.id,
    );

    final notesFile = archive.findFile('notes.json');
    expect(notesFile, isNotNull);
    final notesJson = jsonDecode(utf8.decode(notesFile!.content)) as List;
    expect(notesJson.length, 2); // only patient1's two notes, not patient2's
    expect(notesJson.every((n) => (n as Map)['patientId'] == patient1.id), isTrue);

    expect(archive.findFile('photos/abc.jpg'), isNotNull);

    await db.close();
  });

  test('importZip round-trips a patient + their notes + photo into a fresh dao, and re-import is idempotent', () async {
    final sourcePhotosDir = Directory(p.join(tempDir.path, 'source_photos'))
      ..createSync(recursive: true);
    final photoFile = File(p.join(sourcePhotosDir.path, 'abc.jpg'));
    await photoFile.writeAsBytes([1, 2, 3, 4]);

    final sourceDb = await LocalDb.open(inMemoryDatabasePath);
    final sourceDao = NoteDao(sourceDb);
    await sourceDao.insert(CareNote(
      id: 'note-with-photo',
      timestamp: DateTime.utc(2026, 7, 20, 8),
      author: NoteAuthor.family,
      text: '有照片的紀錄',
      patientId: patient1.id,
      photoPath: photoFile.path,
    ));
    await sourceDao.insert(CareNote(
      id: 'note-no-photo',
      timestamp: DateTime.utc(2026, 7, 21, 9),
      author: NoteAuthor.caregiver,
      text: '沒照片的紀錄',
      patientId: patient1.id,
    ));

    final outDir = Directory(p.join(tempDir.path, 'export'))..createSync(recursive: true);
    final zipFile = await exportZip(patient: patient1, dao: sourceDao, photosDir: sourcePhotosDir, outDir: outDir);
    await sourceDb.close();

    // Simulate a second phone: fresh DAOs, fresh (not-yet-existing) photosDir,
    // and no patients on it yet.
    final targetDb = await LocalDb.open(inMemoryDatabasePath);
    final targetDao = NoteDao(targetDb);
    final targetPatientDao = PatientDao(targetDb);
    final targetPhotosDir = Directory(p.join(tempDir.path, 'target_photos'));

    final summary1 = await importZip(
      zip: zipFile,
      dao: targetDao,
      patientDao: targetPatientDao,
      photosDir: targetPhotosDir,
      fallbackPatientId: 'should-not-be-used',
    );
    expect(summary1.total, 2);
    expect(summary1.imported, 2);
    expect(summary1.patientId, patient1.id);
    expect(summary1.patientName, patient1.name);

    // The patient itself was created on the target device.
    final targetPatients = await targetPatientDao.all();
    expect(targetPatients.map((p) => p.id), contains(patient1.id));

    final imported = await targetDao.allNewestFirst();
    expect(imported.length, 2);
    expect(imported.every((n) => n.patientId == patient1.id), isTrue);

    final withPhoto = imported.firstWhere((n) => n.id == 'note-with-photo');
    expect(withPhoto.photoPath, isNotNull);
    expect(p.dirname(withPhoto.photoPath!), targetPhotosDir.path);
    expect(await File(withPhoto.photoPath!).exists(), isTrue);
    expect(await File(withPhoto.photoPath!).readAsBytes(), [1, 2, 3, 4]);

    final withoutPhoto = imported.firstWhere((n) => n.id == 'note-no-photo');
    expect(withoutPhoto.photoPath, isNull);

    // Re-importing the same zip must not duplicate rows.
    final summary2 = await importZip(
      zip: zipFile,
      dao: targetDao,
      patientDao: targetPatientDao,
      photosDir: targetPhotosDir,
      fallbackPatientId: 'should-not-be-used',
    );
    expect(summary2.total, 2);
    expect(summary2.imported, 0);

    final afterReimport = await targetDao.allNewestFirst();
    expect(afterReimport.length, 2);

    await targetDb.close();
  });

  test('importZip throws FormatException on a malformed zip and does not touch the db', () async {
    final badZip = File(p.join(tempDir.path, 'bad.zip'));
    await badZip.writeAsBytes([0, 1, 2, 3]);

    final db = await LocalDb.open(inMemoryDatabasePath);
    final dao = NoteDao(db);
    final patientDao = PatientDao(db);
    final photosDir = Directory(p.join(tempDir.path, 'photos'));

    expect(
      () => importZip(
        zip: badZip,
        dao: dao,
        patientDao: patientDao,
        photosDir: photosDir,
        fallbackPatientId: patient1.id,
      ),
      throwsA(isA<FormatException>()),
    );

    final all = await dao.allNewestFirst();
    expect(all, isEmpty);

    await db.close();
  });

  test('importZip throws FormatException when one notes.json entry is malformed, '
      'and inserts nothing (no partial import)', () async {
    final goodNote = CareNote(
      id: 'ok',
      timestamp: DateTime.utc(2026, 7, 20, 8),
      author: NoteAuthor.family,
      text: '正常紀錄',
      patientId: patient1.id,
    );
    final notesJson = jsonEncode([goodNote.toJson(), {'nope': 1}]);
    final zipFile = _buildZip(
      tempDir,
      'partial-bad.zip',
      notesJsonBytes: utf8.encode(notesJson),
    );

    final db = await LocalDb.open(inMemoryDatabasePath);
    final dao = NoteDao(db);
    final patientDao = PatientDao(db);
    final photosDir = Directory(p.join(tempDir.path, 'photos'));

    expect(
      () => importZip(
        zip: zipFile,
        dao: dao,
        patientDao: patientDao,
        photosDir: photosDir,
        fallbackPatientId: patient1.id,
      ),
      throwsA(isA<FormatException>()),
    );

    final all = await dao.allNewestFirst();
    expect(all, isEmpty);

    await db.close();
  });

  test('importZip sets photoPath to null (not a dangling path) when the referenced '
      'photo is missing from the archive', () async {
    final noteJson = CareNote(
      id: 'missing-photo',
      timestamp: DateTime.utc(2026, 7, 20, 8),
      author: NoteAuthor.caregiver,
      text: '照片遺失的紀錄',
      patientId: patient1.id,
      photoPath: '/some/other/phone/path/ghost.jpg',
    ).toJson();
    final notesJson = jsonEncode([noteJson]);
    // No 'photos/ghost.jpg' entry in the archive — simulates a backup whose
    // photo never made it in (or was stripped in transit).
    final zipFile = _buildZip(
      tempDir,
      'missing-photo.zip',
      notesJsonBytes: utf8.encode(notesJson),
    );

    final db = await LocalDb.open(inMemoryDatabasePath);
    final dao = NoteDao(db);
    final patientDao = PatientDao(db);
    final photosDir = Directory(p.join(tempDir.path, 'photos'));

    final summary = await importZip(
      zip: zipFile,
      dao: dao,
      patientDao: patientDao,
      photosDir: photosDir,
      fallbackPatientId: patient1.id,
    );
    expect(summary.total, 1);
    expect(summary.imported, 1);

    final imported = await dao.allNewestFirst();
    expect(imported.single.photoPath, isNull);

    await db.close();
  });

  test('importZip backward-compat: a zip with no patient.json and notes with no patientId '
      'all get assigned to fallbackPatientId, without throwing', () async {
    // Simulates a Plan-2 (pre-multi-patient) backup: raw note maps that never
    // had a `patientId` key at all.
    final oldStyleNotes = [
      {
        'id': 'old-1',
        'timestamp': DateTime.utc(2026, 7, 18, 8).toIso8601String(),
        'author': NoteAuthor.family.code,
        'text': '舊格式紀錄一',
        'photoPath': null,
      },
      {
        'id': 'old-2',
        'timestamp': DateTime.utc(2026, 7, 19, 9).toIso8601String(),
        'author': NoteAuthor.caregiver.code,
        'text': '舊格式紀錄二',
        'photoPath': null,
      },
    ];
    final zipFile = _buildZip(
      tempDir,
      'old-plan2-backup.zip',
      notesJsonBytes: utf8.encode(jsonEncode(oldStyleNotes)),
    );

    final db = await LocalDb.open(inMemoryDatabasePath);
    final dao = NoteDao(db);
    final patientDao = PatientDao(db);
    await patientDao.insert(patient1); // the device's existing current patient
    final photosDir = Directory(p.join(tempDir.path, 'photos'));

    final summary = await importZip(
      zip: zipFile,
      dao: dao,
      patientDao: patientDao,
      photosDir: photosDir,
      fallbackPatientId: patient1.id,
    );

    expect(summary.total, 2);
    expect(summary.imported, 2);
    expect(summary.patientId, patient1.id);
    expect(summary.patientName, patient1.name);

    final imported = await dao.allNewestFirst();
    expect(imported.every((n) => n.patientId == patient1.id), isTrue);

    await db.close();
  });
}

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:care_record_app/features/patient/patient_service.dart';
import 'package:care_record_app/features/record/data/local_db.dart';
import 'package:care_record_app/features/record/data/note_dao.dart';
import 'package:care_record_app/features/record/data/patient_dao.dart';
import 'package:care_record_app/features/record/model/care_note.dart';
import 'package:care_record_app/features/record/model/note_author.dart';
import 'package:care_record_app/features/record/model/patient.dart';

/// [PatientService.deletePatient] is the only place that cascades a patient
/// delete onto their photo files — [PatientDao.delete] alone only removes DB
/// rows (documented deliberately there), so this is where "delete a patient"
/// actually needs to be exercised end-to-end.
void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late Directory tempDir;
  late Directory photosDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('patient_service_test_');
    photosDir = Directory(p.join(tempDir.path, 'photos'))..createSync(recursive: true);
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('deletePatient removes the photo file, the patient row, and their notes; '
      'leaves another patient\'s notes and photos untouched', () async {
    final db = await LocalDb.open(inMemoryDatabasePath);
    final noteDao = NoteDao(db);
    final patientDao = PatientDao(db);

    const target = Patient(id: 'p-target', name: '待刪除');
    const other = Patient(id: 'p-other', name: '保留');
    await patientDao.insert(target);
    await patientDao.insert(other);

    final targetPhoto = File(p.join(photosDir.path, 'target.jpg'));
    await targetPhoto.writeAsBytes([1, 2, 3]);
    final otherPhoto = File(p.join(photosDir.path, 'other.jpg'));
    await otherPhoto.writeAsBytes([4, 5, 6]);

    await noteDao.insert(CareNote(
      id: 'target-note-with-photo',
      timestamp: DateTime.utc(2026, 7, 20, 8),
      author: NoteAuthor.family,
      text: '待刪除病人的紀錄一',
      patientId: target.id,
      photoPath: targetPhoto.path,
    ));
    await noteDao.insert(CareNote(
      id: 'target-note-no-photo',
      timestamp: DateTime.utc(2026, 7, 21, 9),
      author: NoteAuthor.caregiver,
      text: '待刪除病人的紀錄二',
      patientId: target.id,
    ));
    await noteDao.insert(CareNote(
      id: 'other-note-with-photo',
      timestamp: DateTime.utc(2026, 7, 22, 10),
      author: NoteAuthor.family,
      text: '保留病人的紀錄',
      patientId: other.id,
      photoPath: otherPhoto.path,
    ));

    await PatientService().deletePatient(
      id: target.id,
      noteDao: noteDao,
      patientDao: patientDao,
      photosDir: photosDir,
    );

    // Target patient's photo file is gone.
    expect(await targetPhoto.exists(), isFalse);
    // The other patient's photo file is untouched.
    expect(await otherPhoto.exists(), isTrue);

    // Target patient's row and notes are gone.
    final remainingPatients = await patientDao.all();
    expect(remainingPatients.map((p) => p.id), isNot(contains(target.id)));
    expect(remainingPatients.map((p) => p.id), contains(other.id));

    final remainingNotes = await noteDao.allNewestFirst();
    expect(remainingNotes.map((n) => n.id), isNot(contains('target-note-with-photo')));
    expect(remainingNotes.map((n) => n.id), isNot(contains('target-note-no-photo')));
    expect(remainingNotes.map((n) => n.id), contains('other-note-with-photo'));

    await db.close();
  });

  test('deletePatient does not throw when a note references a photo file that no longer exists', () async {
    final db = await LocalDb.open(inMemoryDatabasePath);
    final noteDao = NoteDao(db);
    final patientDao = PatientDao(db);

    const target = Patient(id: 'p-target', name: '待刪除');
    await patientDao.insert(target);
    await noteDao.insert(CareNote(
      id: 'target-note-ghost-photo',
      timestamp: DateTime.utc(2026, 7, 20, 8),
      author: NoteAuthor.family,
      text: '照片已遺失的紀錄',
      patientId: target.id,
      photoPath: p.join(photosDir.path, 'never-existed.jpg'),
    ));

    await PatientService().deletePatient(
      id: target.id,
      noteDao: noteDao,
      patientDao: patientDao,
      photosDir: photosDir,
    );

    final remainingPatients = await patientDao.all();
    expect(remainingPatients.map((p) => p.id), isNot(contains(target.id)));

    await db.close();
  });
}

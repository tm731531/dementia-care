import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:care_record_app/features/record/data/local_db.dart';
import 'package:care_record_app/features/record/data/note_dao.dart';
import 'package:care_record_app/features/record/model/care_note.dart';
import 'package:care_record_app/features/record/model/note_author.dart';
import 'package:care_record_app/features/record/service/backup.dart';

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

  test('exportZip writes a zip containing notes.json and the referenced photo', () async {
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
      photoPath: photoFile.path,
    ));
    await dao.insert(CareNote(
      id: 'note-no-photo',
      timestamp: DateTime.utc(2026, 7, 21, 9),
      author: NoteAuthor.caregiver,
      text: '沒照片的紀錄',
    ));

    final outDir = Directory(p.join(tempDir.path, 'export'))..createSync(recursive: true);
    final zipFile = await exportZip(dao: dao, photosDir: sourcePhotosDir, outDir: outDir);

    expect(await zipFile.exists(), isTrue);

    final archive = ZipDecoder().decodeBytes(await zipFile.readAsBytes());
    expect(archive.findFile('notes.json'), isNotNull);
    expect(archive.findFile('photos/abc.jpg'), isNotNull);

    await db.close();
  });

  test('importZip round-trips notes + photo into a fresh dao/photosDir, and re-import is idempotent', () async {
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
      photoPath: photoFile.path,
    ));
    await sourceDao.insert(CareNote(
      id: 'note-no-photo',
      timestamp: DateTime.utc(2026, 7, 21, 9),
      author: NoteAuthor.caregiver,
      text: '沒照片的紀錄',
    ));

    final outDir = Directory(p.join(tempDir.path, 'export'))..createSync(recursive: true);
    final zipFile = await exportZip(dao: sourceDao, photosDir: sourcePhotosDir, outDir: outDir);
    await sourceDb.close();

    // Simulate a second phone: fresh DAO, fresh (not-yet-existing) photosDir.
    final targetDb = await LocalDb.open(inMemoryDatabasePath);
    final targetDao = NoteDao(targetDb);
    final targetPhotosDir = Directory(p.join(tempDir.path, 'target_photos'));

    final summary1 = await importZip(zip: zipFile, dao: targetDao, photosDir: targetPhotosDir);
    expect(summary1.total, 2);
    expect(summary1.imported, 2);

    final imported = await targetDao.allNewestFirst();
    expect(imported.length, 2);

    final withPhoto = imported.firstWhere((n) => n.id == 'note-with-photo');
    expect(withPhoto.photoPath, isNotNull);
    expect(p.dirname(withPhoto.photoPath!), targetPhotosDir.path);
    expect(await File(withPhoto.photoPath!).exists(), isTrue);
    expect(await File(withPhoto.photoPath!).readAsBytes(), [1, 2, 3, 4]);

    final withoutPhoto = imported.firstWhere((n) => n.id == 'note-no-photo');
    expect(withoutPhoto.photoPath, isNull);

    // Re-importing the same zip must not duplicate rows.
    final summary2 = await importZip(zip: zipFile, dao: targetDao, photosDir: targetPhotosDir);
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
    final photosDir = Directory(p.join(tempDir.path, 'photos'));

    expect(
      () => importZip(zip: badZip, dao: dao, photosDir: photosDir),
      throwsA(isA<FormatException>()),
    );

    final all = await dao.allNewestFirst();
    expect(all, isEmpty);

    await db.close();
  });
}

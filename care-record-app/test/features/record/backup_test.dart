import 'dart:convert';
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

  test('importZip throws FormatException when one notes.json entry is malformed, '
      'and inserts nothing (no partial import)', () async {
    final goodNote = CareNote(
      id: 'ok',
      timestamp: DateTime.utc(2026, 7, 20, 8),
      author: NoteAuthor.family,
      text: '正常紀錄',
    );
    final notesJson = jsonEncode([goodNote.toJson(), {'nope': 1}]);
    final zipFile = _buildZip(
      tempDir,
      'partial-bad.zip',
      notesJsonBytes: utf8.encode(notesJson),
    );

    final db = await LocalDb.open(inMemoryDatabasePath);
    final dao = NoteDao(db);
    final photosDir = Directory(p.join(tempDir.path, 'photos'));

    expect(
      () => importZip(zip: zipFile, dao: dao, photosDir: photosDir),
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
    final photosDir = Directory(p.join(tempDir.path, 'photos'));

    final summary = await importZip(zip: zipFile, dao: dao, photosDir: photosDir);
    expect(summary.total, 1);
    expect(summary.imported, 1);

    final imported = await dao.allNewestFirst();
    expect(imported.single.photoPath, isNull);

    await db.close();
  });
}

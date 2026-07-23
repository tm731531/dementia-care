import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:path/path.dart' as p;

import '../data/note_dao.dart';
import '../model/care_note.dart';

/// Result of [importZip]: how many notes were in the backup vs. how many
/// were actually new to this device (the rest were already here — import
/// is safe to repeat because [NoteDao.insert] is idempotent by id).
class ImportSummary {
  final int total;
  final int imported;
  ImportSummary(this.total, this.imported);
}

/// Bundles every note (as `notes.json`) plus every photo it references
/// (under `photos/<basename>`) into a single zip a caregiver can hand to a
/// second phone via any channel (LINE / USB / AirDrop).
Future<File> exportZip({
  required NoteDao dao,
  required Directory photosDir,
  required Directory outDir,
}) async {
  final notes = await dao.allNewestFirst();
  final notesJson = jsonEncode(notes.map((n) => n.toJson()).toList());

  final archive = Archive();
  final notesBytes = utf8.encode(notesJson);
  archive.addFile(ArchiveFile('notes.json', notesBytes.length, notesBytes));

  for (final note in notes) {
    final photoPath = note.photoPath;
    if (photoPath == null) continue;
    final photoFile = File(photoPath);
    if (!await photoFile.exists()) continue; // skip notes whose photo is gone locally
    final bytes = await photoFile.readAsBytes();
    archive.addFile(ArchiveFile('photos/${p.basename(photoPath)}', bytes.length, bytes));
  }

  if (!await outDir.exists()) {
    await outDir.create(recursive: true);
  }
  final outFile = File(p.join(outDir.path, 'care-record-backup.zip'));
  await outFile.writeAsBytes(ZipEncoder().encode(archive));
  return outFile;
}

/// Imports a zip produced by [exportZip] into the local db + photos dir.
/// Photos are copied in under their original basename (stable across
/// re-imports) and each note's [CareNote.photoPath] is rewritten to point
/// at the local copy. Insert-by-id is idempotent, so importing the same
/// zip twice never duplicates notes.
Future<ImportSummary> importZip({
  required File zip,
  required NoteDao dao,
  required Directory photosDir,
}) async {
  final Archive archive;
  final List<CareNote> notes;
  try {
    archive = ZipDecoder().decodeBytes(await zip.readAsBytes());
    final notesFile = archive.findFile('notes.json');
    if (notesFile == null) throw const FormatException('缺少 notes.json');
    final notesFileContent = jsonDecode(utf8.decode(notesFile.content));
    if (notesFileContent is! List) throw const FormatException('無效的備份檔');
    notes = notesFileContent
        .map((entry) => CareNote.fromJson(entry as Map<String, dynamic>))
        .toList();
  } catch (_) {
    throw const FormatException('無效的備份檔');
  }

  final existingIds = await dao.existsIds();
  if (!await photosDir.exists()) {
    await photosDir.create(recursive: true);
  }

  // Resolve each note's local photo (extracting from the archive as
  // needed) into a fully-formed list *before* touching the db, so a
  // problem partway through can't leave the db partially imported.
  final notesToInsert = <CareNote>[];
  for (final note in notes) {
    var noteToInsert = note;
    final photoPath = note.photoPath;
    if (photoPath != null) {
      final basename = p.basename(photoPath);
      final localFile = File(p.join(photosDir.path, basename));
      if (!await localFile.exists()) {
        final archivedPhoto = archive.findFile('photos/$basename');
        if (archivedPhoto != null) {
          await localFile.writeAsBytes(archivedPhoto.content);
        }
      }
      // Only point the imported note at the local file if it actually
      // exists — never plant a path to a photo that was never written.
      noteToInsert = CareNote(
        id: note.id,
        timestamp: note.timestamp,
        author: note.author,
        text: note.text,
        photoPath: await localFile.exists() ? localFile.path : null,
      );
    }
    notesToInsert.add(noteToInsert);
  }

  var imported = 0;
  for (final note in notesToInsert) {
    final isNew = !existingIds.contains(note.id);
    await dao.insert(note);
    if (isNew) imported++;
  }

  return ImportSummary(notes.length, imported);
}

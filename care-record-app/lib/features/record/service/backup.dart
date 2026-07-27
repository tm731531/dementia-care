import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:path/path.dart' as p;

import '../data/note_dao.dart';
import '../data/patient_dao.dart';
import '../model/care_note.dart';
import '../model/patient.dart';

/// Result of [importZip]: how many notes were in the backup vs. how many
/// were actually new to this device (the rest were already here — import
/// is safe to repeat because [NoteDao.insert] is idempotent by id), plus
/// which patient the notes ended up attached to (from `patient.json`, or the
/// caller's `fallbackPatientId` for an old Plan-2 zip).
class ImportSummary {
  final int total;
  final int imported;
  final String patientId;
  final String patientName;
  ImportSummary(this.total, this.imported, this.patientId, this.patientName);
}

/// Bundles [patient] (as `patient.json`) plus that patient's notes only (as
/// `notes.json`) plus every photo those notes reference (under
/// `photos/<basename>`) into a single zip a caregiver can hand to a second
/// phone via any channel (LINE / USB / AirDrop).
Future<File> exportZip({
  required Patient patient,
  required NoteDao dao,
  required Directory photosDir,
  required Directory outDir,
}) async {
  final notes = await dao.allNewestFirstForPatient(patient.id);
  final notesJson = jsonEncode(notes.map((n) => n.toJson()).toList());

  final archive = Archive();
  final patientBytes = utf8.encode(jsonEncode(patient.toJson()));
  archive.addFile(ArchiveFile('patient.json', patientBytes.length, patientBytes));
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
///
/// If the zip has a `patient.json` (a Plan-3 export), that patient is
/// created/merged via [patientDao] and every imported note is forced onto
/// it — an export only ever contains one patient's notes, so this is a
/// safety normalization, not a behavior change. If there's no
/// `patient.json` (an old Plan-2 backup, before multi-patient existed), or
/// an individual note's json has no `patientId`, that note is instead
/// attached to [fallbackPatientId] (the caller's current patient).
Future<ImportSummary> importZip({
  required File zip,
  required NoteDao dao,
  required PatientDao patientDao,
  required Directory photosDir,
  required String fallbackPatientId,
}) async {
  final Archive archive;
  final Patient? patient;
  final List<CareNote> notes;
  try {
    archive = ZipDecoder().decodeBytes(await zip.readAsBytes());
    final notesFile = archive.findFile('notes.json');
    if (notesFile == null) throw const FormatException('缺少 notes.json');
    final notesFileContent = jsonDecode(utf8.decode(notesFile.content));
    if (notesFileContent is! List) throw const FormatException('無效的備份檔');

    final patientFile = archive.findFile('patient.json');
    patient = patientFile == null
        ? null
        : Patient.fromJson(jsonDecode(utf8.decode(patientFile.content)) as Map<String, dynamic>);

    notes = notesFileContent.map((entry) {
      final noteMap = Map<String, dynamic>.from(entry as Map<String, dynamic>);
      if (patient != null) {
        noteMap['patientId'] = patient.id; // export is single-patient — force it
      } else if (noteMap['patientId'] == null) {
        noteMap['patientId'] = fallbackPatientId; // Plan-2 backup, no patient info at all
      }
      return CareNote.fromJson(noteMap);
    }).toList();
  } catch (_) {
    throw const FormatException('無效的備份檔');
  }

  if (patient != null) {
    await patientDao.insert(patient);
  }
  final resolvedPatientId = patient?.id ?? fallbackPatientId;
  final resolvedPatientName = patient?.name ??
      (await patientDao.all())
          .firstWhere((p) => p.id == fallbackPatientId, orElse: () => Patient(id: fallbackPatientId, name: fallbackPatientId))
          .name;

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
        patientId: note.patientId,
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

  return ImportSummary(notes.length, imported, resolvedPatientId, resolvedPatientName);
}

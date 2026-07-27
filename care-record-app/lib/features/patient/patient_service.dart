import 'dart:io';

import 'package:path/path.dart' as p;

import '../record/data/note_dao.dart';
import '../record/data/patient_dao.dart';

/// Cross-cutting patient operations that touch both the DB (via the DAOs)
/// and the filesystem (photo files) — [PatientDao.delete] alone only removes
/// DB rows, so deleting a patient through the DAO directly would leave
/// orphaned photo files on disk forever.
class PatientService {
  /// Deletes [id]'s photo files first (best-effort — missing files are
  /// skipped, not an error), then the patient + its note rows via
  /// [PatientDao.delete]. Order matters: if this were interrupted after the
  /// DB delete, the notes (and their photo paths) would already be gone and
  /// the files would leak; deleting files first means a worst case leaves
  /// harmless orphaned rows, never orphaned files.
  Future<void> deletePatient({
    required String id,
    required NoteDao noteDao,
    required PatientDao patientDao,
    required Directory photosDir,
  }) async {
    final notes = await noteDao.allNewestFirstForPatient(id);
    for (final note in notes) {
      final photoPath = note.photoPath;
      if (photoPath == null) continue;
      final file = File(p.join(photosDir.path, p.basename(photoPath)));
      if (await file.exists()) {
        await file.delete();
      }
    }
    await patientDao.delete(id);
  }
}

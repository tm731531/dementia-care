import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

/// Copies a picked photo into the app's local documents dir under `photos/`
/// with a UUID filename, so the original (often a transient cache/temp file
/// from the image picker) isn't relied on after this call returns.
class PhotoStore {
  /// Injectable base directory so tests can point this at a temp dir instead
  /// of the real app documents directory. Defaults to
  /// [getApplicationDocumentsDirectory] in production.
  final String? _baseDir;

  PhotoStore({String? baseDir}) : _baseDir = baseDir;

  Future<String> save(File src) async {
    final baseDir = _baseDir ?? (await getApplicationDocumentsDirectory()).path;
    final photosDir = Directory(p.join(baseDir, 'photos'));
    if (!await photosDir.exists()) {
      await photosDir.create(recursive: true);
    }
    final destPath = p.join(photosDir.path, '${const Uuid().v4()}.jpg');
    await src.copy(destPath);
    return destPath;
  }
}

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:care_record_app/features/record/data/photo_store.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('photo_store_test_');
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('save copies the source file into <baseDir>/photos/<uuid>.jpg and returns its path', () async {
    final srcFile = File(p.join(tempDir.path, 'source.jpg'));
    final srcBytes = List<int>.generate(256, (i) => i % 256);
    await srcFile.writeAsBytes(srcBytes);

    final store = PhotoStore(baseDir: tempDir.path);
    final savedPath = await store.save(srcFile);

    final savedFile = File(savedPath);
    expect(await savedFile.exists(), isTrue);
    expect(p.dirname(savedPath), p.join(tempDir.path, 'photos'));
    expect(p.extension(savedPath), '.jpg');
    expect(await savedFile.readAsBytes(), srcBytes);
  });

  test('save called twice produces two distinct files', () async {
    final srcFile = File(p.join(tempDir.path, 'source.jpg'));
    await srcFile.writeAsBytes([1, 2, 3]);

    final store = PhotoStore(baseDir: tempDir.path);
    final path1 = await store.save(srcFile);
    final path2 = await store.save(srcFile);

    expect(path1, isNot(equals(path2)));
    expect(await File(path1).exists(), isTrue);
    expect(await File(path2).exists(), isTrue);
  });
}

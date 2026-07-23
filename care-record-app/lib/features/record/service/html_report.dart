import 'dart:convert';
import 'dart:typed_data';

import '../../../core/time.dart';
import '../model/note_author.dart';
import '../view/review_model.dart';

const _weekdayLabels = ['一', '二', '三', '四', '五', '六', '日'];

String _formatDate(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

String _formatTime(DateTime d) =>
    '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

String _formatDateWithWeekday(DateTime d) =>
    '${_formatDate(d)}（週${_weekdayLabels[d.weekday - 1]}）';

/// HTML-escapes [text] so untrusted note content can never break out of the
/// document markup (also guards the offline-only guarantee: escaped content
/// can't smuggle in a `<script src="http...">` tag).
String _escapeHtml(String text) => text
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;');

/// Builds a single, self-contained HTML document summarizing [groups] for a
/// doctor to read on any device, offline — no external CSS/JS/font/image
/// URLs, ever. [readPhotoBytes] (if provided) supplies the raw bytes for a
/// note's `photoPath`, which get inlined as a base64 `data:` URI; if it's
/// null, or returns null for a given path, that note's photo is omitted.
/// [patientName], if given, is shown as「病人：〈name〉」under the date range;
/// if null, that line is omitted entirely. Callers on a single-patient
/// device must pass null (mirroring the `patients.length >= 2` gate used
/// elsewhere, e.g. record_note_screen.dart) so the report looks identical
/// to before multi-patient support existed.
String buildHtmlReport(
  List<DateGroup> groups, {
  required DateTime from,
  required DateTime to,
  Uint8List? Function(String path)? readPhotoBytes,
  String? patientName,
}) {
  final totalCount = groups.fold<int>(0, (sum, g) => sum + g.notes.length);

  final buffer = StringBuffer();
  buffer.writeln('<!doctype html>');
  buffer.writeln('<html lang="zh-Hant">');
  buffer.writeln('<head>');
  buffer.writeln('<meta charset="utf-8">');
  buffer.writeln('<meta name="viewport" content="width=device-width, initial-scale=1">');
  buffer.writeln('<title>照護紀錄整理</title>');
  buffer.writeln('<style>$_css</style>');
  buffer.writeln('</head>');
  buffer.writeln('<body>');
  buffer.writeln('<header>');
  buffer.writeln('<h1>照護紀錄整理</h1>');
  if (patientName != null) {
    buffer.writeln('<p class="patient">病人：${_escapeHtml(patientName)}</p>');
  }
  buffer.writeln('<p class="range">${_formatDate(from)} ～ ${_formatDate(to)}</p>');
  buffer.writeln('<p class="count">共 $totalCount 筆</p>');
  buffer.writeln('</header>');
  buffer.writeln('<main>');

  if (groups.isEmpty) {
    buffer.writeln('<p class="empty">這段時間沒有紀錄</p>');
  }

  for (final group in groups) {
    buffer.writeln('<section class="date-group">');
    buffer.writeln('<h2>${_formatDateWithWeekday(group.date)}</h2>');
    for (final note in group.notes) {
      final shift = shiftOfDay(note.timestamp);
      final time = _formatTime(note.timestamp);
      final authorLabel = note.author == NoteAuthor.family ? '家屬' : '照顧者';

      buffer.writeln('<article class="note">');
      buffer.writeln('<p class="meta">$shift $time <span class="author">$authorLabel</span></p>');
      buffer.writeln('<p class="text">${_escapeHtml(note.text)}</p>');

      final photoPath = note.photoPath;
      if (photoPath != null) {
        final bytes = readPhotoBytes?.call(photoPath);
        if (bytes != null) {
          final base64Data = base64Encode(bytes);
          buffer.writeln(
              '<img class="photo" src="data:image/jpeg;base64,$base64Data" alt="白板照片">');
        }
      }
      buffer.writeln('</article>');
    }
    buffer.writeln('</section>');
  }

  buffer.writeln('</main>');
  buffer.writeln('</body>');
  buffer.writeln('</html>');

  return buffer.toString();
}

const _css = '''
body { background:#f5f5f5; color:#222; font-family: -apple-system, "PingFang TC", "Microsoft JhengHei", sans-serif; line-height:1.6; margin:0; padding:24px; font-size:20px; }
header { margin-bottom:24px; }
h1 { font-size:28px; margin:0 0 8px; }
.patient { font-size:22px; font-weight:600; margin:0 0 4px; color:#2C5D80; }
.range { font-size:22px; font-weight:600; margin:0; }
.count { font-size:18px; color:#555; margin:4px 0 0; }
.date-group { margin-bottom:32px; }
h2 { font-size:22px; color:#2C5D80; border-bottom:1px solid #ddd; padding-bottom:8px; }
.note { background:#fff; border:1px solid #e5e5e5; border-radius:12px; padding:16px; margin-bottom:12px; }
.meta { font-size:16px; color:#555; font-weight:600; margin:0 0 8px; }
.author { display:inline-block; background:#e8f0f6; color:#2C5D80; border-radius:999px; padding:2px 10px; font-size:14px; font-weight:600; }
.text { font-size:22px; margin:0; white-space:pre-wrap; }
.photo { max-width:100%; height:auto; border-radius:8px; margin-top:12px; }
.empty { font-size:22px; text-align:center; padding:24px; }
''';

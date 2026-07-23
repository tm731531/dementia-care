import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/time.dart';
import '../model/care_note.dart';
import '../model/note_author.dart';
import '../providers.dart';
import '../service/html_report.dart';
import 'review_model.dart';

const _weekdayLabels = ['一', '二', '三', '四', '五', '六', '日'];

String _formatDate(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

String _formatDateWithWeekday(DateTime d) =>
    '${_formatDate(d)}（週${_weekdayLabels[d.weekday - 1]}）';

/// Read-only, date-grouped summary of all notes in a chosen date range —
/// the screen a caregiver hands to the doctor at a clinic visit.
class DoctorReviewScreen extends ConsumerStatefulWidget {
  const DoctorReviewScreen({super.key});

  @override
  ConsumerState<DoctorReviewScreen> createState() => _DoctorReviewScreenState();
}

class _DoctorReviewScreenState extends ConsumerState<DoctorReviewScreen> {
  late DateTime _from;
  late DateTime _to;

  @override
  void initState() {
    super.initState();
    final today = DateTime.now();
    _to = DateTime(today.year, today.month, today.day);
    _from = _to.subtract(const Duration(days: 29)); // last 30 days inclusive
  }

  Future<void> _pickFrom() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _from,
      firstDate: DateTime(2020),
      lastDate: _to,
    );
    if (!mounted) return;
    if (picked != null) setState(() => _from = picked);
  }

  Future<void> _pickTo() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _to,
      firstDate: _from,
      lastDate: DateTime.now(),
    );
    if (!mounted) return;
    if (picked != null) setState(() => _to = picked);
  }

  /// Builds the self-contained HTML report for the current date range and
  /// hands it off via the OS share sheet, so the caregiver can pick any
  /// channel (LINE / email / AirDrop / USB) to get it to the doctor — no
  /// app required on the receiving end.
  Future<void> _exportHtml() async {
    final notes = await ref.read(notesProvider.future);
    final groups = groupNotesByLocalDate(notes, from: _from, to: _to);
    final html = buildHtmlReport(
      groups,
      from: _from,
      to: _to,
      readPhotoBytes: (path) {
        final file = File(path);
        return file.existsSync() ? file.readAsBytesSync() : null;
      },
    );

    final tempDir = await getTemporaryDirectory();
    final fileName = 'care-report-${_formatDate(_from)}_${_formatDate(_to)}.html';
    final filePath = p.join(tempDir.path, fileName);
    await File(filePath).writeAsString(html);

    if (!mounted) return;
    await SharePlus.instance.share(ShareParams(files: [XFile(filePath)]));
  }

  @override
  Widget build(BuildContext context) {
    final notesAsync = ref.watch(notesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('給醫生看的整理')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _exportHtml,
        icon: const Icon(Icons.ios_share),
        label: const Text('產出給醫生（HTML）', style: TextStyle(fontSize: 18)),
      ),
      body: SafeArea(
        child: notesAsync.when(
          data: (notes) {
            final groups = groupNotesByLocalDate(notes, from: _from, to: _to);
            final totalCount = groups.fold<int>(0, (sum, g) => sum + g.notes.length);
            return Column(
              children: [
                _RangeHeader(
                  from: _from,
                  to: _to,
                  totalCount: totalCount,
                  onPickFrom: _pickFrom,
                  onPickTo: _pickTo,
                ),
                Expanded(
                  child: groups.isEmpty
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(24),
                            child: Text('這段時間沒有紀錄', style: TextStyle(fontSize: 22)),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                          itemCount: groups.length,
                          itemBuilder: (context, index) => _DateGroupSection(group: groups[index]),
                        ),
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
            child: Text('讀取失敗：$e', style: const TextStyle(fontSize: 20)),
          ),
        ),
      ),
    );
  }
}

class _RangeHeader extends StatelessWidget {
  final DateTime from;
  final DateTime to;
  final int totalCount;
  final VoidCallback onPickFrom;
  final VoidCallback onPickTo;

  const _RangeHeader({
    required this.from,
    required this.to,
    required this.totalCount,
    required this.onPickFrom,
    required this.onPickTo,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFDDDDDD)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${_formatDate(from)} ～ ${_formatDate(to)}',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: Color(0xFF222222),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '共 $totalCount 筆紀錄',
              style: const TextStyle(fontSize: 18, color: Color(0xFF555555)),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onPickFrom,
                    child: Text('起：${_formatDate(from)}'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: onPickTo,
                    child: Text('迄：${_formatDate(to)}'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DateGroupSection extends StatelessWidget {
  final DateGroup group;

  const _DateGroupSection({required this.group});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
          child: Text(
            _formatDateWithWeekday(group.date),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C5D80),
            ),
          ),
        ),
        const Divider(height: 1, color: Color(0xFFDDDDDD)),
        const SizedBox(height: 8),
        ...group.notes.map((note) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _NoteCard(note: note),
            )),
      ],
    );
  }
}

class _NoteCard extends StatelessWidget {
  final CareNote note;

  const _NoteCard({required this.note});

  @override
  Widget build(BuildContext context) {
    final shift = shiftOfDay(note.timestamp);
    final time = TimeOfDay.fromDateTime(note.timestamp).format(context);
    final authorLabel = note.author == NoteAuthor.family ? '家屬' : '照顧者';

    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFE5E5E5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '$shift $time',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF555555),
                  ),
                ),
                const SizedBox(width: 8),
                _AuthorChip(label: authorLabel),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              note.text,
              style: const TextStyle(fontSize: 22, height: 1.6, color: Color(0xFF222222)),
            ),
            if (note.photoPath != null) ...[
              const SizedBox(height: 12),
              _PhotoThumbnail(path: note.photoPath!),
            ],
          ],
        ),
      ),
    );
  }
}

class _AuthorChip extends StatelessWidget {
  final String label;

  const _AuthorChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F0F6),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Color(0xFF2C5D80),
        ),
      ),
    );
  }
}

class _PhotoThumbnail extends StatelessWidget {
  final String path;

  const _PhotoThumbnail({required this.path});

  void _openFullScreen(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(8),
        child: InteractiveViewer(
          child: Image.file(File(path)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _openFullScreen(context),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.file(
          File(path),
          height: 80,
          width: 80,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            height: 80,
            width: 80,
            color: const Color(0xFFEEEEEE),
            child: const Icon(Icons.broken_image, color: Color(0xFF999999)),
          ),
        ),
      ),
    );
  }
}

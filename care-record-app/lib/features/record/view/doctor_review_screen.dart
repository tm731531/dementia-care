import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
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

  /// Builds the self-contained HTML report for the current date range, then
  /// lets the caregiver choose to hand it off via the OS share sheet (LINE /
  /// email / AirDrop / USB — no app required on the receiving end) or save
  /// it straight onto this device (e.g. Downloads).
  Future<void> _exportHtml() async {
    final notes = await ref.read(notesProvider.future);
    final groups = groupNotesByLocalDate(notes, from: _from, to: _to);
    final patients = await ref.read(patientsProvider.future);
    // Single-patient devices must look identical to before Plan 3 — no
    // 病人 line — so only pass a name once there's an actual choice.
    final patientName = patients.length >= 2
        ? ref.read(currentPatientProvider).valueOrNull?.name
        : null;
    final html = buildHtmlReport(
      groups,
      from: _from,
      to: _to,
      patientName: patientName,
      readPhotoBytes: (path) {
        final file = File(path);
        return file.existsSync() ? file.readAsBytesSync() : null;
      },
    );
    final fileName = 'care-report-${_formatDate(_from)}_${_formatDate(_to)}.html';

    if (!mounted) return;
    final choice = await _showExportChoiceSheet(context);
    if (choice == null) return; // dismissed without choosing

    if (choice == _ExportChoice.share) {
      final tempDir = await getTemporaryDirectory();
      final filePath = p.join(tempDir.path, fileName);
      await File(filePath).writeAsString(html);
      if (!mounted) return;
      await SharePlus.instance.share(ShareParams(files: [XFile(filePath)]));
    } else {
      final bytes = Uint8List.fromList(utf8.encode(html));
      if (!mounted) return;
      await _saveBytesToDevice(context, bytes: bytes, fileName: fileName);
    }
  }

  @override
  Widget build(BuildContext context) {
    final notesAsync = ref.watch(notesProvider);
    final patients = ref.watch(patientsProvider).valueOrNull ?? const [];
    final currentPatientName = ref.watch(currentPatientProvider).valueOrNull?.name;
    // Same single-patient-invisibility gate as record_note_screen.dart:
    // only show the 病人 line once there's an actual choice to make.
    final patientName = patients.length >= 2 ? currentPatientName : null;

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
                  patientName: patientName,
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
  final String? patientName;
  final VoidCallback onPickFrom;
  final VoidCallback onPickTo;

  const _RangeHeader({
    required this.from,
    required this.to,
    required this.totalCount,
    required this.patientName,
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
            if (patientName != null) ...[
              Text(
                '病人：$patientName',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2C5D80),
                ),
              ),
              const SizedBox(height: 4),
            ],
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

enum _ExportChoice { share, save }

/// Bottom sheet offering the two ways to deliver an export: hand it to the
/// OS share sheet, or save it straight onto this device (e.g. Downloads)
/// via the system "save as" dialog. Returns null if dismissed.
Future<_ExportChoice?> _showExportChoiceSheet(BuildContext context) {
  return showModalBottomSheet<_ExportChoice>(
    context: context,
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.ios_share),
            title: const Text('分享', style: TextStyle(fontSize: 20)),
            onTap: () => Navigator.of(context).pop(_ExportChoice.share),
          ),
          ListTile(
            leading: const Icon(Icons.save_alt),
            title: const Text('儲存到手機', style: TextStyle(fontSize: 20)),
            onTap: () => Navigator.of(context).pop(_ExportChoice.save),
          ),
        ],
      ),
    ),
  );
}

/// Opens the system "save as" dialog (SAF on Android) so the caregiver can
/// pick where to save — e.g. Downloads — then confirms with a SnackBar.
/// Does nothing if the user cancels the dialog (file_picker returns null).
Future<void> _saveBytesToDevice(
  BuildContext context, {
  required Uint8List bytes,
  required String fileName,
}) async {
  final savedPath = await FilePicker.saveFile(fileName: fileName, bytes: bytes);
  if (!context.mounted) return;
  if (savedPath == null) return; // user cancelled the save dialog
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('已儲存到手機：$savedPath')),
  );
}

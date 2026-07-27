import '../model/care_note.dart';

/// All notes that fall on the same LOCAL calendar date, ASC by timestamp.
class DateGroup {
  final DateTime date; // local, time-of-day stripped (y, m, d)
  final List<CareNote> notes;

  DateGroup(this.date, this.notes);
}

DateTime _localDateOnly(DateTime t) => DateTime(t.year, t.month, t.day);

/// Groups [notes] by their LOCAL calendar date (time-of-day ignored), keeping
/// only notes whose local date falls within [from, to] inclusive (either
/// bound may be null for unbounded). Groups are sorted date DESC (newest
/// first, for the doctor-facing review screen); notes within a group are
/// sorted ASC by timestamp (chronological).
List<DateGroup> groupNotesByLocalDate(
  List<CareNote> notes, {
  DateTime? from,
  DateTime? to,
}) {
  final fromDate = from != null ? _localDateOnly(from) : null;
  final toDate = to != null ? _localDateOnly(to) : null;

  final byDate = <DateTime, List<CareNote>>{};
  for (final note in notes) {
    final date = _localDateOnly(note.timestamp);
    if (fromDate != null && date.isBefore(fromDate)) continue;
    if (toDate != null && date.isAfter(toDate)) continue;
    byDate.putIfAbsent(date, () => []).add(note);
  }

  final groups = byDate.entries
      .map((e) => DateGroup(e.key, e.value..sort((a, b) => a.timestamp.compareTo(b.timestamp))))
      .toList()
    ..sort((a, b) => b.date.compareTo(a.date));

  return groups;
}

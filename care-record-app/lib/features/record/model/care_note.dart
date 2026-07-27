import 'note_author.dart';

/// One caregiving event note. Append-only, timestamped, author-tagged so that
/// merging two devices' notes (Plan 3) is a union deduped by [id].
class CareNote {
  final String id; // caller-supplied UUID → stable across devices
  final DateTime timestamp;
  final NoteAuthor author;
  final String text;
  final String? photoPath;
  final String patientId; // which Patient (Plan 3) this note belongs to

  const CareNote({
    required this.id,
    required this.timestamp,
    required this.author,
    required this.text,
    required this.patientId,
    this.photoPath,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'timestamp': timestamp.toUtc().toIso8601String(),
        'author': author.code,
        'text': text,
        'photoPath': photoPath,
        'patientId': patientId,
      };

  factory CareNote.fromJson(Map<String, dynamic> json) => CareNote(
        id: json['id'] as String,
        timestamp: DateTime.parse(json['timestamp'] as String).toLocal(),
        author: NoteAuthor.fromCode(json['author'] as String),
        text: json['text'] as String,
        photoPath: json['photoPath'] as String?,
        patientId: json['patientId'] as String,
      );
}

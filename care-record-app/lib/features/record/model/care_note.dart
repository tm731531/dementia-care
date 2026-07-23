import 'note_author.dart';

/// One caregiving event note. Append-only, timestamped, author-tagged so that
/// merging two devices' notes (Plan 3) is a union deduped by [id].
class CareNote {
  final String id; // caller-supplied UUID → stable across devices
  final DateTime timestamp;
  final NoteAuthor author;
  final String text;
  final String? photoPath;

  const CareNote({
    required this.id,
    required this.timestamp,
    required this.author,
    required this.text,
    this.photoPath,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'timestamp': timestamp.toUtc().toIso8601String(),
        'author': author.code,
        'text': text,
        'photoPath': photoPath,
      };

  factory CareNote.fromJson(Map<String, dynamic> json) => CareNote(
        id: json['id'] as String,
        timestamp: DateTime.parse(json['timestamp'] as String),
        author: NoteAuthor.fromCode(json['author'] as String),
        text: json['text'] as String,
        photoPath: json['photoPath'] as String?,
      );
}

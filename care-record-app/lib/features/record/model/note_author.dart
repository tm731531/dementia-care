enum NoteAuthor {
  family,
  caregiver;

  String get code => this == NoteAuthor.family ? 'F' : 'C';

  static NoteAuthor fromCode(String code) =>
      code == 'F' ? NoteAuthor.family : NoteAuthor.caregiver;
}

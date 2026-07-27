/// A person being cared for. A device may track 1..N patients; notes are
/// scoped to a patient via [CareNote.patientId]. `id` is caller-supplied
/// (uuid) so the same patient dedupes by id across devices, same as notes.
class Patient {
  final String id;
  final String name;

  const Patient({required this.id, required this.name});

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
      };

  factory Patient.fromJson(Map<String, dynamic> json) => Patient(
        id: json['id'] as String,
        name: json['name'] as String,
      );
}

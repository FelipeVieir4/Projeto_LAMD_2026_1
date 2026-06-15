class Specialty {
  final String id;
  final String name;
  final String? description;

  const Specialty({
    required this.id,
    required this.name,
    this.description,
  });

  factory Specialty.fromJson(Map<String, dynamic> json) {
    return Specialty(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
    );
  }

  Map<String, dynamic> toLocalMap() => {
        'id': id,
        'name': name,
        'description': description,
      };

  factory Specialty.fromLocalMap(Map<String, dynamic> map) {
    return Specialty(
      id: map['id'] as String,
      name: map['name'] as String,
      description: map['description'] as String?,
    );
  }
}

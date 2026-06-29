class PartnerUser {
  final String id;
  final String email;
  final String companyName;
  final String program;
  final String? phone;
  final String? bio;
  final String? document;
  final List<String> specialties;

  const PartnerUser({
    required this.id,
    required this.email,
    required this.companyName,
    required this.program,
    this.phone,
    this.bio,
    this.document,
    this.specialties = const [],
  });

  factory PartnerUser.fromJson(Map<String, dynamic> json) {
    return PartnerUser(
      id: json['id'] as String,
      email: json['email'] as String,
      companyName: (json['companyName'] ?? 'Parceiro') as String,
      program: json['program'] as String,
      phone: json['phone'] as String?,
      bio: json['bio'] as String?,
      document: json['document'] as String?,
      specialties: (json['specialties'] as List?)?.map((e) => e.toString()).toList() ?? const [],
    );
  }
}

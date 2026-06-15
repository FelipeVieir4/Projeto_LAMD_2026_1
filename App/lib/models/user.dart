class User {
  final String id;
  final String email;
  final String name;
  final String program;
  final String? phone;

  const User({
    required this.id,
    required this.email,
    required this.name,
    required this.program,
    this.phone,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      email: json['email'] as String,
      name: (json['name'] ?? json['companyName'] ?? 'Usuário') as String,
      program: json['program'] as String,
      phone: json['phone'] as String?,
    );
  }
}

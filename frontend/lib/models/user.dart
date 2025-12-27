class User {
  final int id;
  final String username;
  final String email;
  final String firstName;
  final String lastName;
  final String? phone;
  final String? address;
  final String role;
  final DateTime createdAt;
  final DateTime updatedAt;

  User({
    required this.id,
    required this.username,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.phone,
    this.address,
    required this.role,
    required this.createdAt,
    required this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? 0,
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      phone: json['phone'],
      address: json['address'],
      role: json['role'] ?? '',
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updated_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'first_name': firstName,
      'last_name': lastName,
      'phone': phone,
      'address': address,
      'role': role,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  String get fullName => '$firstName $lastName';
  
  bool get isDonor => role == 'donor';
  bool get isVolunteer => role == 'volunteer';
  bool get isOrganization => role == 'organization';
  
  String get roleDisplay {
    switch (role) {
      case 'donor':
        return 'Donor';
      case 'volunteer':
        return 'Volunteer';
      case 'organization':
        return 'Organization';
      default:
        return role;
    }
  }
}

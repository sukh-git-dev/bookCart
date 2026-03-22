class UserModel {
  const UserModel({
    required this.name,
    required this.phone,
    required this.email,
    required this.password,
    this.location = 'Kolkata, West Bengal',
    this.profileImageBase64,
  });

  final String name;
  final String phone;
  final String email;
  final String password;
  final String location;
  final String? profileImageBase64;

  UserModel copyWith({
    String? name,
    String? phone,
    String? email,
    String? password,
    String? location,
    String? profileImageBase64,
  }) {
    return UserModel(
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      password: password ?? this.password,
      location: location ?? this.location,
      profileImageBase64: profileImageBase64 ?? this.profileImageBase64,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'phone': phone,
      'email': email,
      'password': password,
      'location': location,
      'profileImageBase64': profileImageBase64,
    };
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      name: json['name'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      email: json['email'] as String? ?? '',
      password: json['password'] as String? ?? '',
      location: json['location'] as String? ?? 'Kolkata, West Bengal',
      profileImageBase64: json['profileImageBase64'] as String?,
    );
  }
}

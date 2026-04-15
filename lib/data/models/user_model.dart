class UserModel {
  const UserModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    this.location = 'Kolkata, West Bengal',
    this.profileImageBase64,
  });

  final String id;
  final String name;
  final String phone;
  final String email;
  final String location;
  final String? profileImageBase64;

  UserModel copyWith({
    String? id,
    String? name,
    String? phone,
    String? email,
    String? location,
    String? profileImageBase64,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      location: location ?? this.location,
      profileImageBase64: profileImageBase64 ?? this.profileImageBase64,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'email': email,
      'location': location,
      'profileImageBase64': profileImageBase64,
    };
  }

  factory UserModel.fromJson(
    Map<String, dynamic> json, {
    String? fallbackId,
    String? fallbackEmail,
  }) {
    return UserModel(
      id: json['id'] as String? ?? fallbackId ?? '',
      name: json['name'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      email: json['email'] as String? ?? fallbackEmail ?? '',
      location: json['location'] as String? ?? 'Kolkata, West Bengal',
      profileImageBase64: json['profileImageBase64'] as String?,
    );
  }
}

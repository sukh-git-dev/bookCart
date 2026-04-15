import 'package:bookcart/data/models/user_model.dart';

abstract class AuthRepository {
  Future<UserModel?> getCurrentUser();

  Future<UserModel> login({required String email, required String password});

  Future<UserModel> signUp({
    required String name,
    required String phone,
    required String email,
    required String password,
    String location = 'Kolkata, West Bengal',
    String? profileImageBase64,
  });

  Future<UserModel> updateUser(UserModel user);

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  });

  Future<void> logout();

  Future<void> deleteAccount();
}

class AuthRepositoryException implements Exception {
  const AuthRepositoryException(this.message);

  final String message;

  @override
  String toString() => message;
}

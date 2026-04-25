import 'dart:async';
import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bookcart/data/models/user_model.dart';
import 'package:bookcart/data/repository/auth_repository.dart';

class SupabaseAuthRepository implements AuthRepository {
  final SupabaseClient _client = Supabase.instance.client;

  // ================= CURRENT USER =================
  @override
  Future<UserModel?> getCurrentUser() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;

    try {
      final data = await _client
          .from('users')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (data == null) return _fallback(user);

      return UserModel.fromJson(data);
    } catch (e) {
      print("getCurrentUser error: $e");
      return _fallback(user);
    }
  }

  // ================= STREAM =================
  @override
  Stream<UserModel?> watchCurrentUser() {
    return _client.auth.onAuthStateChange.asyncMap((event) async {
      final user = event.session?.user;
      if (user == null) return null;

      try {
        final data = await _client
            .from('users')
            .select()
            .eq('id', user.id)
            .maybeSingle();

        if (data == null) return _fallback(user);

        return UserModel.fromJson(data);
      } catch (e) {
        print("stream error: $e");
        return _fallback(user);
      }
    });
  }

  // ================= LOGIN =================
  @override
  Future<UserModel> login({
    required String email,
    required String password,
    String? location,
    double? latitude,
    double? longitude,
    DateTime? locationUpdatedAt,
  }) async {
    try {
      await _client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );

      final user = _client.auth.currentUser!;
      return await getCurrentUser() ?? _fallback(user);
    } on AuthException catch (e) {
      throw AuthRepositoryException(e.message);
    }
  }

  // ================= SIGNUP =================
  @override
  Future<UserModel> signUp({
    required String name,
    required String phone,
    required String email,
    required String password,
    String location = 'India',
    double? latitude,
    double? longitude,
    DateTime? locationUpdatedAt,
    String? profileImageBase64,
  }) async {
    try {
      final res = await _client.auth.signUp(
        email: email.trim(),
        password: password,
      );

      final user = res.user;
      if (user == null) {
        throw const AuthRepositoryException("Signup failed");
      }

      // 🔥 wait session ready
      await Future.delayed(const Duration(milliseconds: 800));

      final imageUrl = await _uploadProfileImage(
        userId: user.id,
        profileImageBase64: profileImageBase64,
      );

      // ================= INSERT USER =================
      await _client.from('users').upsert({
        'id': user.id,
        'name': name.trim(),
        'phone': phone.trim(),
        'email': email.trim(),
        'location': location,
        'latitude': latitude,
        'longitude': longitude,
        'location_updated_at': locationUpdatedAt?.toIso8601String(),
        'profile_image_base64': imageUrl,
      }, onConflict: 'id');

      return UserModel(
        id: user.id,
        name: name,
        phone: phone,
        email: email,
        location: location,
        latitude: latitude,
        longitude: longitude,
        locationUpdatedAt: locationUpdatedAt,
        profileImageUrl: imageUrl,
      );
    } on PostgrestException catch (e) {
      print("DB ERROR: ${e.message}");
      throw AuthRepositoryException("Database error: ${e.message}");
    } on AuthException catch (e) {
      throw AuthRepositoryException(e.message);
    } catch (e) {
      throw AuthRepositoryException("Signup failed: $e");
    }
  }

  // ================= UPDATE USER =================
  @override
  Future<UserModel> updateUser(UserModel user) async {
    try {
      final normalizedUser = user.copyWith(
        name: user.name.trim(),
        phone: user.phone.trim(),
        email: user.email.trim(),
        location: user.location.trim().isEmpty
            ? UserModel.defaultLocation
            : user.location.trim(),
      );
      final imageUrl = await _resolveProfileImageUrl(normalizedUser);

      await _client
          .from('users')
          .update({
            'name': normalizedUser.name,
            'phone': normalizedUser.phone,
            'email': normalizedUser.email,
            'location': normalizedUser.location,
            'latitude': normalizedUser.latitude,
            'longitude': normalizedUser.longitude,
            'location_updated_at': normalizedUser.locationUpdatedAt
                ?.toIso8601String(),
            'profile_image_base64': imageUrl,
          })
          .eq('id', normalizedUser.id);

      return normalizedUser.copyWith(
        profileImageUrl: imageUrl,
        clearProfileImageBase64: imageUrl != null,
      );
    } catch (e) {
      throw AuthRepositoryException("Update failed: $e");
    }
  }

  // ================= CHANGE PASSWORD =================
  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      await _client.auth.updateUser(UserAttributes(password: newPassword));
    } on AuthException catch (e) {
      throw AuthRepositoryException(e.message);
    }
  }

  // ================= LOGOUT =================
  @override
  Future<void> logout() async {
    try {
      await _client.auth.signOut();
    } catch (e) {
      throw AuthRepositoryException("Logout failed");
    }
  }

  // ================= DELETE ACCOUNT =================
  @override
  Future<void> deleteAccount() async {
    try {
      await _client.rpc('delete_my_account');
      await _client.auth.signOut();
    } catch (e) {
      throw AuthRepositoryException("Delete failed");
    }
  }

  // ================= FALLBACK =================
  UserModel _fallback(User user) {
    return UserModel(
      id: user.id,
      name: "User",
      phone: "",
      email: user.email ?? "",
      location: "India",
    );
  }

  Future<String?> _resolveProfileImageUrl(UserModel user) async {
    if (user.profileImageBase64 != null &&
        user.profileImageBase64!.isNotEmpty) {
      return _uploadProfileImage(
        userId: user.id,
        profileImageBase64: user.profileImageBase64,
      );
    }

    return user.profileImageUrl;
  }

  Future<String?> _uploadProfileImage({
    required String userId,
    String? profileImageBase64,
  }) async {
    final normalizedBase64 = _normalizeBase64(profileImageBase64);
    if (normalizedBase64 == null) {
      return null;
    }

    try {
      final bytes = base64Decode(normalizedBase64);
      final file = '$userId.png';

      await _client.storage
          .from('profile_images')
          .uploadBinary(
            file,
            bytes,
            fileOptions: const FileOptions(upsert: true),
          );

      return _client.storage.from('profile_images').getPublicUrl(file);
    } catch (e) {
      print("Image upload error: $e");
      return null;
    }
  }

  String? _normalizeBase64(String? value) {
    final normalized = value?.trim();
    if (normalized == null || normalized.isEmpty) {
      return null;
    }

    final dataUriIndex = normalized.indexOf(',');
    if (normalized.startsWith('data:') && dataUriIndex >= 0) {
      return normalized.substring(dataUriIndex + 1).trim();
    }

    return normalized;
  }
}

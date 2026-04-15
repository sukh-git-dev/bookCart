import 'package:bookcart/data/models/user_model.dart';

enum ProfileStatus { initial, loading, loaded, saving, failure }

class ProfileState {
  const ProfileState({
    this.status = ProfileStatus.initial,
    this.user,
    this.errorMessage,
    this.successMessage,
  });

  final ProfileStatus status;
  final UserModel? user;
  final String? errorMessage;
  final String? successMessage;

  bool get isSaving => status == ProfileStatus.saving;

  ProfileState copyWith({
    ProfileStatus? status,
    UserModel? user,
    bool clearUser = false,
    String? errorMessage,
    String? successMessage,
  }) {
    return ProfileState(
      status: status ?? this.status,
      user: clearUser ? null : user ?? this.user,
      errorMessage: errorMessage,
      successMessage: successMessage,
    );
  }
}

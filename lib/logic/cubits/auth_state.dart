import 'package:bookcart/data/models/user_model.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated }

enum AuthAction {
  none,
  refresh,
  login,
  biometricLogin,
  signUp,
  changePassword,
  logout,
  deleteAccount,
}

class AuthState {
  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.isSubmitting = false,
    this.action = AuthAction.none,
    this.errorMessage,
    this.successMessage,
  });

  final AuthStatus status;
  final UserModel? user;
  final bool isSubmitting;
  final AuthAction action;
  final String? errorMessage;
  final String? successMessage;

  bool get isAuthenticated =>
      status == AuthStatus.authenticated && user != null;

  AuthState copyWith({
    AuthStatus? status,
    UserModel? user,
    bool clearUser = false,
    bool? isSubmitting,
    AuthAction? action,
    String? errorMessage,
    String? successMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: clearUser ? null : user ?? this.user,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      action: action ?? this.action,
      errorMessage: errorMessage,
      successMessage: successMessage,
    );
  }
}

import 'package:bookcart/data/models/user_model.dart';
import 'package:bookcart/data/repository/auth_repository.dart';
import 'package:bookcart/logic/cubits/auth_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AuthCubit extends Cubit<AuthState> {
  AuthCubit(this._repository) : super(const AuthState());

  final AuthRepository _repository;

  Future<void> loadSession() async {
    emit(
      state.copyWith(
        status: AuthStatus.loading,
        isSubmitting: false,
        action: AuthAction.refresh,
      ),
    );

    try {
      final user = await _repository.getCurrentUser();
      emit(
        state.copyWith(
          status: user == null
              ? AuthStatus.unauthenticated
              : AuthStatus.authenticated,
          user: user,
          clearUser: user == null,
          isSubmitting: false,
          action: AuthAction.none,
        ),
      );
    } on AuthRepositoryException catch (error) {
      _emitFailure(
        error.message,
        status: AuthStatus.unauthenticated,
        clearUser: true,
      );
    } catch (_) {
      _emitFailure(
        'Could not load the current session.',
        status: AuthStatus.unauthenticated,
        clearUser: true,
      );
    }
  }

  Future<void> refreshUser() async {
    try {
      final user = await _repository.getCurrentUser();
      emit(
        state.copyWith(
          status: user == null
              ? AuthStatus.unauthenticated
              : AuthStatus.authenticated,
          user: user,
          clearUser: user == null,
          isSubmitting: false,
          action: AuthAction.none,
        ),
      );
    } on AuthRepositoryException catch (error) {
      _emitFailure(error.message);
    } catch (_) {
      _emitFailure('Could not refresh your account details.');
    }
  }

  Future<void> login({required String email, required String password}) async {
    emit(
      state.copyWith(
        isSubmitting: true,
        action: AuthAction.login,
        status: AuthStatus.unauthenticated,
      ),
    );

    try {
      final user = await _repository.login(email: email, password: password);
      _emitSuccess(user: user, successMessage: 'Welcome back, ${user.name}.');
    } on AuthRepositoryException catch (error) {
      _emitFailure(
        error.message,
        status: AuthStatus.unauthenticated,
        clearUser: true,
      );
    } catch (_) {
      _emitFailure(
        'Login failed. Please try again.',
        status: AuthStatus.unauthenticated,
        clearUser: true,
      );
    }
  }

  Future<void> signUp({
    required String name,
    required String phone,
    required String email,
    required String password,
    String location = 'Kolkata, West Bengal',
    String? profileImageBase64,
  }) async {
    emit(
      state.copyWith(
        isSubmitting: true,
        action: AuthAction.signUp,
        status: AuthStatus.unauthenticated,
      ),
    );

    try {
      final user = await _repository.signUp(
        name: name,
        phone: phone,
        email: email,
        password: password,
        location: location,
        profileImageBase64: profileImageBase64,
      );
      _emitSuccess(user: user, successMessage: 'Account created successfully.');
    } on AuthRepositoryException catch (error) {
      _emitFailure(
        error.message,
        status: AuthStatus.unauthenticated,
        clearUser: true,
      );
    } catch (_) {
      _emitFailure(
        'Could not create your account right now.',
        status: AuthStatus.unauthenticated,
        clearUser: true,
      );
    }
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    emit(
      state.copyWith(
        isSubmitting: true,
        action: AuthAction.changePassword,
        status: AuthStatus.authenticated,
        user: state.user,
      ),
    );

    try {
      await _repository.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      emit(
        state.copyWith(
          status: AuthStatus.authenticated,
          user: state.user,
          isSubmitting: false,
          action: AuthAction.none,
          successMessage: 'Password updated successfully.',
        ),
      );
    } on AuthRepositoryException catch (error) {
      _emitFailure(
        error.message,
        status: AuthStatus.authenticated,
        user: state.user,
      );
    } catch (_) {
      _emitFailure(
        'Could not change your password right now.',
        status: AuthStatus.authenticated,
        user: state.user,
      );
    }
  }

  Future<void> logout() async {
    emit(
      state.copyWith(
        isSubmitting: true,
        action: AuthAction.logout,
        status: AuthStatus.authenticated,
        user: state.user,
      ),
    );

    try {
      await _repository.logout();
      emit(
        state.copyWith(
          status: AuthStatus.unauthenticated,
          clearUser: true,
          isSubmitting: false,
          action: AuthAction.none,
          successMessage: 'Logged out successfully.',
        ),
      );
    } on AuthRepositoryException catch (error) {
      _emitFailure(
        error.message,
        status: AuthStatus.authenticated,
        user: state.user,
      );
    } catch (_) {
      _emitFailure(
        'Could not log out right now.',
        status: AuthStatus.authenticated,
        user: state.user,
      );
    }
  }

  Future<void> deleteAccount() async {
    emit(
      state.copyWith(
        isSubmitting: true,
        action: AuthAction.deleteAccount,
        status: AuthStatus.authenticated,
        user: state.user,
      ),
    );

    try {
      await _repository.deleteAccount();
      emit(
        state.copyWith(
          status: AuthStatus.unauthenticated,
          clearUser: true,
          isSubmitting: false,
          action: AuthAction.none,
          successMessage: 'Account deleted successfully.',
        ),
      );
    } on AuthRepositoryException catch (error) {
      _emitFailure(
        error.message,
        status: AuthStatus.authenticated,
        user: state.user,
      );
    } catch (_) {
      _emitFailure(
        'Could not delete the account right now.',
        status: AuthStatus.authenticated,
        user: state.user,
      );
    }
  }

  void clearFeedback() {
    emit(
      state.copyWith(
        status: state.status,
        user: state.user,
        isSubmitting: state.isSubmitting,
        action: state.action,
      ),
    );
  }

  void _emitSuccess({required UserModel user, required String successMessage}) {
    emit(
      state.copyWith(
        status: AuthStatus.authenticated,
        user: user,
        isSubmitting: false,
        action: AuthAction.none,
        successMessage: successMessage,
      ),
    );
  }

  void _emitFailure(
    String message, {
    AuthStatus? status,
    UserModel? user,
    bool clearUser = false,
  }) {
    emit(
      state.copyWith(
        status: status ?? state.status,
        user: user,
        clearUser: clearUser,
        isSubmitting: false,
        action: AuthAction.none,
        errorMessage: message,
      ),
    );
  }
}

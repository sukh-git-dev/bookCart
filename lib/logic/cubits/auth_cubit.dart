import 'dart:async';

import 'package:bookcart/core/utils/app_logger.dart';
import 'package:bookcart/data/models/user_model.dart';
import 'package:bookcart/data/repository/auth_repository.dart';
import 'package:bookcart/data/repository/biometric_auth_repository.dart';
import 'package:bookcart/logic/cubits/auth_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AuthCubit extends Cubit<AuthState> {
  AuthCubit(
    this._repository, {
    BiometricAuthRepository? biometricAuthRepository,
  }) : _biometricAuthRepository =
           biometricAuthRepository ?? BiometricAuthRepository(),
       super(const AuthState());

  final AuthRepository _repository;
  final BiometricAuthRepository _biometricAuthRepository;
  StreamSubscription<UserModel?>? _sessionSubscription;

  Future<void> loadSession() async {
    AppLogger.info('AuthCubit', 'loadSession: subscribing');
    emit(
      state.copyWith(
        status: AuthStatus.loading,
        isSubmitting: false,
        action: AuthAction.refresh,
      ),
    );

    await _sessionSubscription?.cancel();
    _sessionSubscription = _repository.watchCurrentUser().listen(
      (user) {
        AppLogger.info(
          'AuthCubit',
          user == null
              ? 'Session changed: signed out'
              : 'Session changed: signed in',
          details: {'userId': user?.id},
        );
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
      },
      onError: (error, stackTrace) {
        AppLogger.error(
          'AuthCubit',
          'loadSession stream error',
          error: error,
          stackTrace: stackTrace,
        );
        _emitFailure(
          'Could not load the current session.',
          status: AuthStatus.unauthenticated,
          clearUser: true,
        );
      },
    );
  }

  Future<void> refreshUser() async {
    final timer = AppLogger.startTimer('AuthCubit', 'refreshUser');
    try {
      final user = await _repository.getCurrentUser();
      timer.success(
        user == null ? 'No active user' : 'User refreshed',
        details: {'userId': user?.id},
      );
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
      timer.fail('Refresh failed', error: error);
      _emitFailure(error.message);
    } catch (error, stackTrace) {
      timer.fail('Refresh failed', error: error, stackTrace: stackTrace);
      _emitFailure('Could not refresh your account details.');
    }
  }

  Future<void> login({
    required String email,
    required String password,
    String? location,
    double? latitude,
    double? longitude,
    DateTime? locationUpdatedAt,
    bool enableBiometricLogin = false,
    bool disableBiometricLogin = false,
  }) async {
    final timer = AppLogger.startTimer(
      'AuthCubit',
      'login',
      details: {'email': email.trim()},
    );
    emit(
      state.copyWith(
        isSubmitting: true,
        action: AuthAction.login,
        status: AuthStatus.unauthenticated,
      ),
    );

    try {
      final user = await _repository.login(
        email: email,
        password: password,
        location: location,
        latitude: latitude,
        longitude: longitude,
        locationUpdatedAt: locationUpdatedAt,
      );
      final biometricSaved = await _syncBiometricCredentials(
        email: email,
        password: password,
        shouldEnable: enableBiometricLogin,
        shouldDisable: disableBiometricLogin,
      );
      _emitSuccess(
        user: user,
        successMessage: biometricSaved
            ? 'Welcome back, ${user.name}. Face login is ready for next time.'
            : 'Welcome back, ${user.name}.',
      );
      timer.success('Login completed', details: {'userId': user.id});
    } on AuthRepositoryException catch (error) {
      timer.fail('Login failed', error: error);
      _emitFailure(
        error.message,
        status: AuthStatus.unauthenticated,
        clearUser: true,
      );
    } catch (error, stackTrace) {
      timer.fail('Login failed', error: error, stackTrace: stackTrace);
      _emitFailure(
        'Login failed. Please try again.',
        status: AuthStatus.unauthenticated,
        clearUser: true,
      );
    }
  }

  Future<void> loginWithBiometrics() async {
    final timer = AppLogger.startTimer('AuthCubit', 'loginWithBiometrics');
    emit(
      state.copyWith(
        isSubmitting: true,
        action: AuthAction.biometricLogin,
        status: AuthStatus.unauthenticated,
      ),
    );

    try {
      final credentials = await _biometricAuthRepository
          .readCredentialsWithAuthentication();
      final user = await _repository.login(
        email: credentials.email,
        password: credentials.password,
      );
      _emitSuccess(user: user, successMessage: 'Welcome back, ${user.name}.');
      timer.success('Biometric login completed', details: {'userId': user.id});
    } on BiometricAuthException catch (error) {
      timer.fail('Biometric login failed', error: error);
      _emitFailure(
        error.message,
        status: AuthStatus.unauthenticated,
        clearUser: true,
      );
    } on AuthRepositoryException catch (error) {
      timer.fail('Biometric login failed', error: error);
      _emitFailure(
        error.message,
        status: AuthStatus.unauthenticated,
        clearUser: true,
      );
    } catch (error, stackTrace) {
      timer.fail(
        'Biometric login failed',
        error: error,
        stackTrace: stackTrace,
      );
      _emitFailure(
        'Face login failed. Please try again.',
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
    String location = UserModel.defaultLocation,
    double? latitude,
    double? longitude,
    DateTime? locationUpdatedAt,
    String? profileImageBase64,
    bool enableBiometricLogin = false,
    bool disableBiometricLogin = false,
  }) async {
    final timer = AppLogger.startTimer(
      'AuthCubit',
      'signUp',
      details: {'email': email.trim()},
    );
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
        latitude: latitude,
        longitude: longitude,
        locationUpdatedAt: locationUpdatedAt,
        profileImageBase64: profileImageBase64,
      );
      final biometricSaved = await _syncBiometricCredentials(
        email: email,
        password: password,
        shouldEnable: enableBiometricLogin,
        shouldDisable: disableBiometricLogin,
      );
      _emitSuccess(
        user: user,
        successMessage: biometricSaved
            ? 'Account created successfully. Face login is ready.'
            : 'Account created successfully.',
      );
      timer.success('Signup completed', details: {'userId': user.id});
    } on AuthRepositoryException catch (error) {
      timer.fail('Signup failed', error: error);
      _emitFailure(
        error.message,
        status: AuthStatus.unauthenticated,
        clearUser: true,
      );
    } catch (error, stackTrace) {
      timer.fail('Signup failed', error: error, stackTrace: stackTrace);
      _emitFailure(
        'Could not create your account right now.',
        status: AuthStatus.unauthenticated,
        clearUser: true,
      );
    }
  }

  Future<bool> _syncBiometricCredentials({
    required String email,
    required String password,
    required bool shouldEnable,
    required bool shouldDisable,
  }) async {
    try {
      if (shouldEnable) {
        await _biometricAuthRepository.saveCredentials(
          email: email,
          password: password,
        );
        return true;
      }

      if (shouldDisable) {
        await _biometricAuthRepository.clearCredentials();
      }
    } catch (_) {
      return false;
    }

    return false;
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final timer = AppLogger.startTimer('AuthCubit', 'changePassword');
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
      timer.success('Password changed');
    } on AuthRepositoryException catch (error) {
      timer.fail('Change password failed', error: error);
      _emitFailure(
        error.message,
        status: AuthStatus.authenticated,
        user: state.user,
      );
    } catch (error, stackTrace) {
      timer.fail(
        'Change password failed',
        error: error,
        stackTrace: stackTrace,
      );
      _emitFailure(
        'Could not change your password right now.',
        status: AuthStatus.authenticated,
        user: state.user,
      );
    }
  }

  Future<void> logout() async {
    final timer = AppLogger.startTimer('AuthCubit', 'logout');
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
      timer.success('Logout completed');
    } on AuthRepositoryException catch (error) {
      timer.fail('Logout failed', error: error);
      _emitFailure(
        error.message,
        status: AuthStatus.authenticated,
        user: state.user,
      );
    } catch (error, stackTrace) {
      timer.fail('Logout failed', error: error, stackTrace: stackTrace);
      _emitFailure(
        'Could not log out right now.',
        status: AuthStatus.authenticated,
        user: state.user,
      );
    }
  }

  Future<void> deleteAccount() async {
    final timer = AppLogger.startTimer('AuthCubit', 'deleteAccount');
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
      timer.success('Delete account completed');
    } on AuthRepositoryException catch (error) {
      timer.fail('Delete account failed', error: error);
      _emitFailure(
        error.message,
        status: AuthStatus.authenticated,
        user: state.user,
      );
    } catch (error, stackTrace) {
      timer.fail('Delete account failed', error: error, stackTrace: stackTrace);
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

  @override
  Future<void> close() async {
    await _sessionSubscription?.cancel();
    return super.close();
  }
}

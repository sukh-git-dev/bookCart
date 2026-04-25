import 'dart:async';

import 'package:bookcart/core/utils/app_logger.dart';
import 'package:bookcart/data/models/user_model.dart';
import 'package:bookcart/data/repository/auth_repository.dart';
import 'package:bookcart/logic/cubits/profile_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ProfileCubit extends Cubit<ProfileState> {
  ProfileCubit(this._repository) : super(const ProfileState());

  final AuthRepository _repository;
  StreamSubscription<UserModel?>? _profileSubscription;

  Future<void> loadProfile() async {
    AppLogger.info('ProfileCubit', 'loadProfile: subscribing');
    emit(state.copyWith(status: ProfileStatus.loading, user: state.user));

    await _profileSubscription?.cancel();
    _profileSubscription = _repository.watchCurrentUser().listen(
      (user) {
        if (user == null) {
          AppLogger.warning('ProfileCubit', 'No signed-in profile found');
          emit(
            state.copyWith(
              status: ProfileStatus.failure,
              clearUser: true,
              errorMessage: 'No signed-in account found.',
            ),
          );
          return;
        }

        AppLogger.success(
          'ProfileCubit',
          'Profile loaded',
          details: {'userId': user.id},
        );
        emit(state.copyWith(status: ProfileStatus.loaded, user: user));
      },
      onError: (error, stackTrace) {
        AppLogger.error(
          'ProfileCubit',
          'loadProfile stream error',
          error: error,
          stackTrace: stackTrace,
        );
        emit(
          state.copyWith(
            status: ProfileStatus.failure,
            user: state.user,
            errorMessage: 'Could not load your profile right now.',
          ),
        );
      },
    );
  }

  Future<void> updateProfile(UserModel user) async {
    final timer = AppLogger.startTimer(
      'ProfileCubit',
      'updateProfile',
      details: {'userId': user.id},
    );
    emit(state.copyWith(status: ProfileStatus.saving, user: user));

    try {
      final updatedUser = await _repository.updateUser(user);
      timer.success('Profile updated');
      emit(
        state.copyWith(
          status: ProfileStatus.loaded,
          user: updatedUser,
          successMessage:
              'Profile saved. Check your inbox if you changed your email.',
        ),
      );
    } on AuthRepositoryException catch (error) {
      timer.fail('Profile update failed', error: error);
      emit(
        state.copyWith(
          status: ProfileStatus.loaded,
          user: state.user,
          errorMessage: error.message,
        ),
      );
    } catch (error, stackTrace) {
      timer.fail('Profile update failed', error: error, stackTrace: stackTrace);
      emit(
        state.copyWith(
          status: ProfileStatus.loaded,
          user: state.user,
          errorMessage: 'Could not save your profile right now.',
        ),
      );
    }
  }

  void clearFeedback() {
    emit(state.copyWith(status: state.status, user: state.user));
  }

  @override
  Future<void> close() async {
    await _profileSubscription?.cancel();
    return super.close();
  }
}

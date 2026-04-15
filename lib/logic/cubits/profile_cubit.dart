import 'package:bookcart/data/models/user_model.dart';
import 'package:bookcart/data/repository/auth_repository.dart';
import 'package:bookcart/logic/cubits/profile_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ProfileCubit extends Cubit<ProfileState> {
  ProfileCubit(this._repository) : super(const ProfileState());

  final AuthRepository _repository;

  Future<void> loadProfile() async {
    emit(state.copyWith(status: ProfileStatus.loading, user: state.user));

    try {
      final user = await _repository.getCurrentUser();
      if (user == null) {
        emit(
          state.copyWith(
            status: ProfileStatus.failure,
            clearUser: true,
            errorMessage: 'No signed-in account found.',
          ),
        );
        return;
      }

      emit(state.copyWith(status: ProfileStatus.loaded, user: user));
    } on AuthRepositoryException catch (error) {
      emit(
        state.copyWith(
          status: ProfileStatus.failure,
          user: state.user,
          errorMessage: error.message,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: ProfileStatus.failure,
          user: state.user,
          errorMessage: 'Could not load your profile right now.',
        ),
      );
    }
  }

  Future<void> updateProfile(UserModel user) async {
    emit(state.copyWith(status: ProfileStatus.saving, user: user));

    try {
      final updatedUser = await _repository.updateUser(user);
      emit(
        state.copyWith(
          status: ProfileStatus.loaded,
          user: updatedUser,
          successMessage:
              'Profile saved. Check your inbox if you changed your email.',
        ),
      );
    } on AuthRepositoryException catch (error) {
      emit(
        state.copyWith(
          status: ProfileStatus.loaded,
          user: state.user,
          errorMessage: error.message,
        ),
      );
    } catch (_) {
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
}

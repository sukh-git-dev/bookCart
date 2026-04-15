import 'package:bookcart/data/repository/app_preferences_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

enum LaunchStatus { loading, onboarding, ready }

class LaunchState {
  const LaunchState({required this.status});

  const LaunchState.loading() : this(status: LaunchStatus.loading);

  const LaunchState.onboarding() : this(status: LaunchStatus.onboarding);

  const LaunchState.ready() : this(status: LaunchStatus.ready);

  final LaunchStatus status;
}

class LaunchCubit extends Cubit<LaunchState> {
  LaunchCubit(this._preferencesRepository)
    : super(const LaunchState.loading()) {
    load();
  }

  final AppPreferencesRepository _preferencesRepository;

  Future<void> load() async {
    emit(const LaunchState.loading());
    final onboardingCompleted = await _preferencesRepository
        .readOnboardingCompleted();
    emit(
      onboardingCompleted
          ? const LaunchState.ready()
          : const LaunchState.onboarding(),
    );
  }

  Future<void> completeOnboarding() async {
    await _preferencesRepository.writeOnboardingCompleted(true);
    emit(const LaunchState.ready());
  }
}

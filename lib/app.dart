import 'package:bookcart/core/notifications/app_notification_service.dart';
import 'package:bookcart/core/notifications/notification_coordinator.dart';
import 'package:bookcart/core/config/supabase_bootstrap.dart';
import 'package:bookcart/core/utils/app_animation_utils.dart';
import 'package:bookcart/core/constants/app_colors.dart';
import 'package:bookcart/core/theme/app_theme.dart';
import 'package:bookcart/core/theme/app_color_palette.dart';
import 'package:bookcart/data/repository/app_preferences_repository.dart';
import 'package:bookcart/data/repository/auth_repository.dart';
import 'package:bookcart/data/repository/biometric_auth_repository.dart';
import 'package:bookcart/data/repository/book_repository.dart';
import 'package:bookcart/data/repository/chat_repository.dart';
import 'package:bookcart/data/repository/device_location_repository.dart';
import 'package:bookcart/data/repository/supabase_auth_repository.dart';
import 'package:bookcart/logic/cubits/auth_cubit.dart';
import 'package:bookcart/logic/cubits/auth_state.dart';
import 'package:bookcart/logic/cubits/book_cubit.dart';
import 'package:bookcart/logic/cubits/chat_cubit.dart';
import 'package:bookcart/logic/cubits/launch_cubit.dart';
import 'package:bookcart/logic/cubits/theme_cubit.dart';
import 'package:bookcart/presentation/screens/auth/login_screen.dart';
import 'package:bookcart/presentation/screens/auth/signup_screen.dart';
import 'package:bookcart/presentation/screens/home/home_shell_screen.dart';
import 'package:bookcart/presentation/screens/onboarding/onboarding_screen.dart';
import 'package:bookcart/presentation/screens/supabase/supabase_setup_screen.dart';
import 'package:bookcart/presentation/widgets/app_loading_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class BookCartApp extends StatelessWidget {
  const BookCartApp({
    super.key,
    required this.supabaseBootstrapResult,
    this.authRepository,
    this.biometricAuthRepository,
    this.bookRepository,
    this.chatRepository,
    this.deviceLocationRepository,
    this.preferencesRepository,
  });

  final SupabaseBootstrapResult supabaseBootstrapResult;
  final AuthRepository? authRepository;
  final BiometricAuthRepository? biometricAuthRepository;
  final BookRepository? bookRepository;
  final ChatRepository? chatRepository;
  final DeviceLocationRepository? deviceLocationRepository;
  final AppPreferencesRepository? preferencesRepository;

  @override
  Widget build(BuildContext context) {
    if (!supabaseBootstrapResult.isReady) {
      return ScreenUtilInit(
        designSize: const Size(393, 852),
        minTextAdapt: true,
        splitScreenMode: true,
        builder: (_, __) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Book Cart',
            theme: AppTheme.light(),
            home: SupabaseSetupScreen(
              errorMessage:
                  supabaseBootstrapResult.errorMessage ??
                  'Supabase is not configured.',
            ).animatePage(),
          );
        },
      );
    }

    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<AppPreferencesRepository>(
          create: (_) => preferencesRepository ?? AppPreferencesRepository(),
        ),
        RepositoryProvider<AuthRepository>(
          create: (_) => authRepository ?? SupabaseAuthRepository(),
        ),
        RepositoryProvider<BiometricAuthRepository>(
          create: (_) => biometricAuthRepository ?? BiometricAuthRepository(),
        ),
        RepositoryProvider<DeviceLocationRepository>(
          create: (_) => deviceLocationRepository ?? DeviceLocationRepository(),
        ),
        RepositoryProvider<BookRepository>(
          create: (_) => bookRepository ?? BookRepository(),
        ),
        RepositoryProvider<ChatRepository>(
          create: (_) => chatRepository ?? ChatRepository(),
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) => AuthCubit(
              context.read<AuthRepository>(),
              biometricAuthRepository: context.read<BiometricAuthRepository>(),
            )..loadSession(),
          ),
          BlocProvider(
            create: (context) => BookCubit(context.read<BookRepository>()),
          ),
          BlocProvider(
            create: (context) => ChatCubit(context.read<ChatRepository>()),
          ),
          BlocProvider(
            create: (context) =>
                LaunchCubit(context.read<AppPreferencesRepository>()),
          ),
          BlocProvider(
            create: (context) =>
                ThemeCubit(context.read<AppPreferencesRepository>()),
          ),
        ],
        child: NotificationCoordinator(
          child: ScreenUtilInit(
            designSize: const Size(393, 852),
            minTextAdapt: true,
            splitScreenMode: true,
            builder: (_, __) {
              return BlocBuilder<ThemeCubit, AppColorPalette>(
                builder: (context, palette) {
                  AppColors.applyPalette(palette);

                  return MaterialApp(
                    debugShowCheckedModeBanner: false,
                    title: 'Book Cart',
                    navigatorKey: AppNotificationService.navigatorKey,
                    scaffoldMessengerKey:
                        AppNotificationService.scaffoldMessengerKey,
                    theme: AppTheme.light(palette),
                    routes: {
                      LoginScreen.routeName: (_) => const LoginScreen(),
                      SignUpScreen.routeName: (_) => const SignUpScreen(),
                      HomeShellScreen.routeName: (_) => const HomeShellScreen(),
                    },
                    home: BlocBuilder<LaunchCubit, LaunchState>(
                      builder: (context, launchState) {
                        if (launchState.status == LaunchStatus.loading) {
                          return const Scaffold(
                            body: Center(
                              child: AppLoadingIndicator(
                                label: 'Preparing your BookCart experience...',
                              ),
                            ),
                          ).animatePage();
                        }

                        if (launchState.status == LaunchStatus.onboarding) {
                          return OnboardingScreen(
                            onComplete: context
                                .read<LaunchCubit>()
                                .completeOnboarding,
                          ).animatePage();
                        }

                        return BlocBuilder<AuthCubit, AuthState>(
                          builder: (context, state) {
                            if (state.status == AuthStatus.initial ||
                                state.status == AuthStatus.loading) {
                              return const Scaffold(
                                body: Center(
                                  child: AppLoadingIndicator(
                                    label: 'Loading your account...',
                                  ),
                                ),
                              ).animatePage();
                            }

                            return state.isAuthenticated
                                ? const HomeShellScreen().animatePage()
                                : const LoginScreen().animatePage();
                          },
                        );
                      },
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

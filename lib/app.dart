import 'package:bookcart/core/config/firebase_bootstrap.dart';
import 'package:bookcart/core/constants/app_colors.dart';
import 'package:bookcart/core/theme/app_theme.dart';
import 'package:bookcart/core/theme/app_color_palette.dart';
import 'package:bookcart/data/repository/app_preferences_repository.dart';
import 'package:bookcart/data/repository/auth_repository.dart';
import 'package:bookcart/data/repository/book_repository.dart';
import 'package:bookcart/data/repository/firebase_auth_repository.dart';
import 'package:bookcart/logic/cubits/auth_cubit.dart';
import 'package:bookcart/logic/cubits/auth_state.dart';
import 'package:bookcart/logic/cubits/book_cubit.dart';
import 'package:bookcart/logic/cubits/launch_cubit.dart';
import 'package:bookcart/logic/cubits/theme_cubit.dart';
import 'package:bookcart/presentation/screens/auth/login_screen.dart';
import 'package:bookcart/presentation/screens/auth/signup_screen.dart';
import 'package:bookcart/presentation/screens/firebase/firebase_setup_screen.dart';
import 'package:bookcart/presentation/screens/home/home_shell_screen.dart';
import 'package:bookcart/presentation/screens/onboarding/onboarding_screen.dart';
import 'package:bookcart/presentation/widgets/app_loading_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class BookCartApp extends StatelessWidget {
  const BookCartApp({
    super.key,
    required this.firebaseBootstrapResult,
    this.authRepository,
    this.bookRepository,
    this.preferencesRepository,
  });

  final FirebaseBootstrapResult firebaseBootstrapResult;
  final AuthRepository? authRepository;
  final BookRepository? bookRepository;
  final AppPreferencesRepository? preferencesRepository;

  @override
  Widget build(BuildContext context) {
    if (!firebaseBootstrapResult.isReady) {
      return ScreenUtilInit(
        designSize: const Size(393, 852),
        minTextAdapt: true,
        splitScreenMode: true,
        builder: (_, __) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Book Cart',
            theme: AppTheme.light(),
            home: FirebaseSetupScreen(
              errorMessage:
                  firebaseBootstrapResult.errorMessage ??
                  'Firebase is not configured.',
            ),
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
          create: (_) => authRepository ?? FirebaseAuthRepository(),
        ),
        RepositoryProvider<BookRepository>(
          create: (_) => bookRepository ?? BookRepository(),
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) =>
                AuthCubit(context.read<AuthRepository>())..loadSession(),
          ),
          BlocProvider(
            create: (context) => BookCubit(context.read<BookRepository>()),
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
                        );
                      }

                      if (launchState.status == LaunchStatus.onboarding) {
                        return OnboardingScreen(
                          onComplete: context
                              .read<LaunchCubit>()
                              .completeOnboarding,
                        );
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
                            );
                          }

                          return state.isAuthenticated
                              ? const HomeShellScreen()
                              : const LoginScreen();
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
    );
  }
}

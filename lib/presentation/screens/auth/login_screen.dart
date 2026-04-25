import 'package:bookcart/core/constants/app_colors.dart';
import 'package:bookcart/core/utils/app_animation_utils.dart';
import 'package:bookcart/data/repository/biometric_auth_repository.dart';
import 'package:bookcart/logic/cubits/auth_cubit.dart';
import 'package:bookcart/logic/cubits/auth_state.dart';
import 'package:bookcart/presentation/screens/auth/signup_screen.dart';
import 'package:bookcart/presentation/screens/home/home_shell_screen.dart';
import 'package:bookcart/presentation/widgets/app_toast.dart';
import 'package:bookcart/presentation/widgets/auth_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  static const routeName = '/login';

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _hidePassword = true;
  bool _loadedBiometricStatus = false;
  bool _biometricAvailable = false;
  bool _hasBiometricCredentials = false;
  bool _saveForBiometrics = false;
  String _biometricLabel = 'Face ID';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loadedBiometricStatus) {
      _loadedBiometricStatus = true;
      _loadBiometricStatus();
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (email.isEmpty || password.isEmpty) {
      AppToast.show(
        context,
        message: 'Enter your email and password to continue.',
        type: AppToastType.error,
      );
      return;
    }

    FocusScope.of(context).unfocus();
    await context.read<AuthCubit>().login(
      email: email,
      password: password,
      enableBiometricLogin: _biometricAvailable && _saveForBiometrics,
      disableBiometricLogin: _biometricAvailable && !_saveForBiometrics,
    );
  }

  Future<void> _loginWithBiometrics() async {
    FocusScope.of(context).unfocus();
    await context.read<AuthCubit>().loginWithBiometrics();
    if (mounted) {
      await _loadBiometricStatus();
    }
  }

  Future<void> _loadBiometricStatus() async {
    final biometricRepository = context.read<BiometricAuthRepository>();
    final canUseBiometrics = await biometricRepository.canUseBiometrics();
    final hasCredentials = await biometricRepository.hasSavedCredentials();
    final label = await biometricRepository.preferredBiometricLabel();

    if (!mounted) {
      return;
    }

    setState(() {
      _biometricAvailable = canUseBiometrics;
      _hasBiometricCredentials = hasCredentials;
      _saveForBiometrics = canUseBiometrics && hasCredentials;
      _biometricLabel = label;
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listenWhen: (previous, current) =>
          previous.status != current.status ||
          previous.errorMessage != current.errorMessage ||
          previous.successMessage != current.successMessage,
      listener: (context, state) {
        if (state.errorMessage != null) {
          AppToast.show(
            context,
            message: state.errorMessage!,
            type: AppToastType.error,
          );
          context.read<AuthCubit>().clearFeedback();
          _loadBiometricStatus();
          return;
        }

        if (state.successMessage != null &&
            state.status != AuthStatus.authenticated) {
          AppToast.show(
            context,
            message: state.successMessage!,
            type: AppToastType.success,
          );
          context.read<AuthCubit>().clearFeedback();
        }

        if (state.status == AuthStatus.authenticated) {
          Navigator.of(context).pushNamedAndRemoveUntil(
            HomeShellScreen.routeName,
            (route) => false,
          );
        }
      },
      child: Builder(
        builder: (context) {
          final authState = context.watch<AuthCubit>().state;
          final isPasswordSubmitting =
              authState.isSubmitting && authState.action == AuthAction.login;
          final isBiometricSubmitting =
              authState.isSubmitting &&
              authState.action == AuthAction.biometricLogin;
          final isSubmitting = authState.isSubmitting;

          return Scaffold(
            backgroundColor: AppColors.background,
            body: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 1000;
                  final form = _AuthCard(
                    title: 'Login',
                    subtitle: 'Sign in with your email address and password.',
                    child: AppStaggeredColumn(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AuthTextField(
                          controller: _emailController,
                          label: 'Email',
                          hint: 'Enter email address',
                          icon: Icons.mail_rounded,
                          keyboardType: TextInputType.emailAddress,
                        ),
                        SizedBox(height: 14.h),
                        AuthTextField(
                          controller: _passwordController,
                          label: 'Password',
                          hint: 'Enter password',
                          icon: Icons.lock_rounded,
                          obscureText: _hidePassword,
                          suffixIcon: IconButton(
                            onPressed: () {
                              setState(() {
                                _hidePassword = !_hidePassword;
                              });
                            },
                            icon: Icon(
                              _hidePassword
                                  ? Icons.visibility_rounded
                                  : Icons.visibility_off_rounded,
                            ),
                          ),
                        ),
                        SizedBox(height: 22.h),
                        if (_hasBiometricCredentials) ...[
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: isSubmitting
                                  ? null
                                  : _loginWithBiometrics,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.primary,
                                minimumSize: Size(double.infinity, 50.h),
                                side: BorderSide(color: AppColors.primary),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20.r),
                                ),
                              ),
                              icon: Icon(Icons.face_rounded, size: 20.sp),
                              label: Text(
                                isBiometricSubmitting
                                    ? 'Checking $_biometricLabel...'
                                    : 'Login with $_biometricLabel',
                                style: TextStyle(
                                  fontSize: 15.sp,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: 14.h),
                        ],
                        if (_biometricAvailable) ...[
                          _BiometricPreferenceTile(
                            title: 'Enable $_biometricLabel login',
                            subtitle:
                                'Use this device biometric check next time.',
                            value: _saveForBiometrics,
                            onChanged: isSubmitting
                                ? null
                                : (value) {
                                    setState(() {
                                      _saveForBiometrics = value;
                                    });
                                  },
                          ),
                          SizedBox(height: 18.h),
                        ],
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: isSubmitting ? null : _login,
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              minimumSize: Size(double.infinity, 50.h),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20.r),
                              ),
                            ),
                            child: Text(
                              isPasswordSubmitting ? 'Logging in...' : 'Login',
                              style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 14.h),
                        Center(
                          child: TextButton(
                            onPressed: () {
                              Navigator.of(
                                context,
                              ).pushNamed(SignUpScreen.routeName);
                            },
                            child: const Text('Create new account'),
                          ),
                        ),
                      ],
                    ),
                  );

                  return isWide
                      ? Row(
                          children: [
                            Expanded(
                              child: const _AuthHeroPanel().animatePage(),
                            ),
                            Expanded(
                              child: Center(
                                child: SingleChildScrollView(
                                  padding: const EdgeInsets.all(32),
                                  keyboardDismissBehavior:
                                      ScrollViewKeyboardDismissBehavior.onDrag,
                                  child: ConstrainedBox(
                                    constraints: const BoxConstraints(
                                      maxWidth: 460,
                                    ),
                                    child: form.animatePage(
                                      delay: const Duration(milliseconds: 120),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        )
                      : SingleChildScrollView(
                          padding: EdgeInsets.all(20.w),
                          keyboardDismissBehavior:
                              ScrollViewKeyboardDismissBehavior.onDrag,
                          child: Column(
                            children: [
                              const _AuthHeroPanel(
                                isCompact: true,
                              ).animatePage(),
                              SizedBox(height: 20.h),
                              form.animatePage(
                                delay: const Duration(milliseconds: 120),
                              ),
                            ],
                          ),
                        );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}

class _AuthHeroPanel extends StatelessWidget {
  const _AuthHeroPanel({this.isCompact = false});

  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: isCompact ? EdgeInsets.zero : const EdgeInsets.all(24),
      padding: EdgeInsets.all(isCompact ? 22.w : 36.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.dark, AppColors.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Text(
              'BookCart Auth',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          SizedBox(height: 18.h),
          Text(
            'Buy, sell, and chat about books from one marketplace.',
            style: TextStyle(
              color: Colors.white,
              fontSize: isCompact ? 24.sp : 32.sp,
              height: 1.15,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 12.h),
          Text(
            'Use your email address and password to access your BookCart account securely.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.82),
              fontSize: 14.sp,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthCard extends StatelessWidget {
  const _AuthCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 28.sp,
              fontWeight: FontWeight.w800,
              color: AppColors.dark,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 14.sp,
              height: 1.45,
              color: AppColors.muted,
            ),
          ),
          SizedBox(height: 22.h),
          child,
        ],
      ),
    );
  }
}

class _BiometricPreferenceTile extends StatelessWidget {
  const _BiometricPreferenceTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 42.w,
            height: 42.w,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: Icon(
              Icons.face_retouching_natural_rounded,
              color: AppColors.primary,
              size: 22.sp,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w800,
                    color: AppColors.dark,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12.sp,
                    height: 1.35,
                    color: AppColors.muted,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            activeThumbColor: AppColors.primary,
            activeTrackColor: AppColors.primary.withValues(alpha: 0.25),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

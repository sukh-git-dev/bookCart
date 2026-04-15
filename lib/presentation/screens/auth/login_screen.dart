import 'package:bookcart/core/constants/app_colors.dart';
import 'package:bookcart/logic/cubits/auth_cubit.dart';
import 'package:bookcart/logic/cubits/auth_state.dart';
import 'package:bookcart/presentation/screens/auth/signup_screen.dart';
import 'package:bookcart/presentation/screens/home/home_shell_screen.dart';
import 'package:bookcart/presentation/widgets/app_toast.dart';
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
    await context.read<AuthCubit>().login(email: email, password: password);
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listenWhen: (previous, current) =>
          previous.status != current.status ||
          previous.errorMessage != current.errorMessage,
      listener: (context, state) {
        if (state.errorMessage != null) {
          AppToast.show(
            context,
            message: state.errorMessage!,
            type: AppToastType.error,
          );
          context.read<AuthCubit>().clearFeedback();
          return;
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
          final isSubmitting =
              authState.isSubmitting && authState.action == AuthAction.login;

          return Scaffold(
            backgroundColor: AppColors.background,
            body: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 1000;
                  final form = _AuthCard(
                    title: 'Login',
                    subtitle:
                        'Continue with your email address and password in the same BookCart style.',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _AuthTextField(
                          controller: _emailController,
                          label: 'Email',
                          hint: 'Enter email address',
                          icon: Icons.mail_rounded,
                          keyboardType: TextInputType.emailAddress,
                        ),
                        SizedBox(height: 14.h),
                        _AuthTextField(
                          controller: _passwordController,
                          label: 'Password',
                          hint: 'Enter password',
                          icon: Icons.lock_rounded,
                          obscureText: true,
                        ),
                        SizedBox(height: 22.h),
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
                              isSubmitting ? 'Logging in...' : 'Login',
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
                            const Expanded(child: _AuthHeroPanel()),
                            Expanded(
                              child: Center(
                                child: SingleChildScrollView(
                                  padding: const EdgeInsets.all(32),
                                  child: ConstrainedBox(
                                    constraints: const BoxConstraints(
                                      maxWidth: 460,
                                    ),
                                    child: form,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        )
                      : SingleChildScrollView(
                          padding: EdgeInsets.all(20.w),
                          child: Column(
                            children: [
                              const _AuthHeroPanel(isCompact: true),
                              SizedBox(height: 20.h),
                              form,
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

class _AuthTextField extends StatelessWidget {
  const _AuthTextField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.obscureText = false,
    this.keyboardType,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final bool obscureText;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13.sp,
            fontWeight: FontWeight.w700,
            color: AppColors.dark,
          ),
        ),
        SizedBox(height: 8.h),
        TextField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          style: TextStyle(color: AppColors.dark, fontSize: 14.sp),
          decoration: InputDecoration(hintText: hint, prefixIcon: Icon(icon))
              .applyDefaults(Theme.of(context).inputDecorationTheme)
              .copyWith(
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20.r),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20.r),
                  borderSide: BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20.r),
                  borderSide: BorderSide(color: AppColors.primary, width: 1.4),
                ),
              ),
        ),
      ],
    );
  }
}

import 'dart:convert';
import 'dart:typed_data';

import 'package:bookcart/core/constants/app_colors.dart';
import 'package:bookcart/data/models/user_model.dart';
import 'package:bookcart/data/repository/auth_repository.dart';
import 'package:bookcart/presentation/screens/auth/login_screen.dart';
import 'package:bookcart/presentation/screens/home/home_shell_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  static const routeName = '/signup';

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  bool _isSubmitting = false;
  Uint8List? _profileImageBytes;
  String? _profileImageBase64;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _otpController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _createAccount() async {
    if (_isSubmitting) {
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _isSubmitting = true;
    });

    await context.read<AuthRepository>().signUp(
      UserModel(
        name: _nameController.text.trim().isEmpty
            ? 'Book Cart User'
            : _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        email: _emailController.text.trim().isEmpty
            ? 'user@bookcart.app'
            : _emailController.text.trim(),
        password: _passwordController.text,
        profileImageBase64: _profileImageBase64,
      ),
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _isSubmitting = false;
    });

    Navigator.of(context).pushReplacementNamed(HomeShellScreen.routeName);
  }

  Future<void> _pickProfileImage() async {
    final image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null) {
      return;
    }

    final bytes = await image.readAsBytes();
    if (!mounted) {
      return;
    }

    setState(() {
      _profileImageBytes = bytes;
      _profileImageBase64 = base64Encode(bytes);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(20.w),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 620),
              child: Column(
                children: [
                  const _SignUpHeroCard(),
                  SizedBox(height: 20.h),
                  Container(
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
                          'Sign Up',
                          style: TextStyle(
                            fontSize: 28.sp,
                            fontWeight: FontWeight.w800,
                            color: AppColors.dark,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          'Create your account with OTP and password.',
                          style: TextStyle(
                            fontSize: 14.sp,
                            height: 1.45,
                            color: AppColors.muted,
                          ),
                        ),
                        SizedBox(height: 22.h),
                        Center(
                          child: GestureDetector(
                            onTap: _pickProfileImage,
                            child: Column(
                              children: [
                                Container(
                                  width: 92.w,
                                  height: 92.w,
                                  decoration: BoxDecoration(
                                    color: AppColors.surface,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: AppColors.border,
                                      width: 2,
                                    ),
                                  ),
                                  child: ClipOval(
                                    child: _profileImageBytes != null
                                        ? Image.memory(
                                            _profileImageBytes!,
                                            fit: BoxFit.cover,
                                          )
                                        : Icon(
                                            Icons.person_rounded,
                                            size: 42.sp,
                                            color: AppColors.primary,
                                          ),
                                  ),
                                ),
                                SizedBox(height: 10.h),
                                Text(
                                  'Add Profile Image',
                                  style: TextStyle(
                                    fontSize: 13.sp,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: 18.h),
                        _SignUpTextField(
                          controller: _nameController,
                          label: 'Full Name',
                          hint: 'Enter full name',
                          icon: Icons.person_rounded,
                        ),
                        SizedBox(height: 14.h),
                        _SignUpTextField(
                          controller: _phoneController,
                          label: 'Phone Number',
                          hint: 'Enter phone number',
                          icon: Icons.call_rounded,
                          keyboardType: TextInputType.phone,
                        ),
                        SizedBox(height: 14.h),
                        _SignUpTextField(
                          controller: _emailController,
                          label: 'Email',
                          hint: 'Enter email',
                          icon: Icons.mail_rounded,
                          keyboardType: TextInputType.emailAddress,
                        ),
                        SizedBox(height: 14.h),
                        Row(
                          children: [
                            Expanded(
                              child: _SignUpTextField(
                                controller: _otpController,
                                label: 'OTP',
                                hint: 'Enter OTP',
                                icon: Icons.password_rounded,
                                keyboardType: TextInputType.number,
                              ),
                            ),
                            SizedBox(width: 12.w),
                            Padding(
                              padding: EdgeInsets.only(top: 26.h),
                              child: OutlinedButton(
                                onPressed: () {},
                                child: const Text('Send OTP'),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 14.h),
                        _SignUpTextField(
                          controller: _passwordController,
                          label: 'Password',
                          hint: 'Create password',
                          icon: Icons.lock_rounded,
                          obscureText: true,
                        ),
                        SizedBox(height: 22.h),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: _isSubmitting ? null : _createAccount,
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              minimumSize: Size(double.infinity, 50.h),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20.r),
                              ),
                            ),
                            child: Text(
                              _isSubmitting
                                  ? 'Creating Account...'
                                  : 'Create Account',
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
                              ).pushReplacementNamed(LoginScreen.routeName);
                            },
                            child: const Text('Already have an account? Login'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SignUpHeroCard extends StatelessWidget {
  const _SignUpHeroCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(22.w),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.dark, AppColors.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Text(
              'Join BookCart',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          SizedBox(height: 16.h),
          Text(
            'Create an account to sell books, chat with buyers, and manage listings.',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24.sp,
              height: 1.2,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _SignUpTextField extends StatelessWidget {
  const _SignUpTextField({
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
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon),
          ).applyDefaults(Theme.of(context).inputDecorationTheme).copyWith(
            fillColor: AppColors.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20.r),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20.r),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20.r),
              borderSide: const BorderSide(
                color: AppColors.primary,
                width: 1.4,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

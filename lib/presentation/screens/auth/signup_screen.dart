import 'dart:convert';
import 'dart:typed_data';

import 'package:bookcart/core/constants/app_colors.dart';
import 'package:bookcart/core/utils/app_animation_utils.dart';
import 'package:bookcart/core/utils/location_label_utils.dart';
import 'package:bookcart/core/utils/location_time_utils.dart';
import 'package:bookcart/data/models/user_model.dart';
import 'package:bookcart/data/repository/biometric_auth_repository.dart';
import 'package:bookcart/data/repository/device_location_repository.dart';
import 'package:bookcart/logic/cubits/auth_cubit.dart';
import 'package:bookcart/logic/cubits/auth_state.dart';
import 'package:bookcart/presentation/screens/auth/login_screen.dart';
import 'package:bookcart/presentation/screens/home/home_shell_screen.dart';
import 'package:bookcart/presentation/widgets/app_toast.dart';
import 'package:bookcart/presentation/widgets/auth_text_field.dart';
import 'package:bookcart/presentation/widgets/current_location_card.dart';
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
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final TextEditingController _locationController = TextEditingController(
    text: UserModel.defaultLocation,
  );
  bool _hidePassword = true;
  bool _hideConfirmPassword = true;
  final ImagePicker _picker = ImagePicker();
  Uint8List? _profileImageBytes;
  String? _profileImageBase64;
  bool _loadedBiometricStatus = false;
  bool _biometricAvailable = false;
  bool _enableBiometricLogin = false;
  String _biometricLabel = 'Face ID';
  DateTime? _locationUpdatedAt;
  double? _latitude;
  double? _longitude;
  bool _isFetchingLocation = false;
  @override
  void initState() {
    super.initState();

    _nameController.text = "Sukhveer Singh";
    _phoneController.text = "9465056434";
    _emailController.text = "sukhveersin71@gmail.com";
    _passwordController.text = "Hi@12345";
    _confirmPasswordController.text = "Hi@12345";
  }
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
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _createAccount() async {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final email = _emailController.text.trim();
    final location = _locationController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;
    if (name.isEmpty ||
        phone.isEmpty ||
        email.isEmpty ||
        location.isEmpty ||
        password.isEmpty) {
      AppToast.show(
        context,
        message:
            'Username, phone number, email, location, and password are required.',
        type: AppToastType.error,
      );
      return;
    }
    if (password != confirmPassword) {
      AppToast.show(
        context,
        message: 'Password and confirm password must match.',
        type: AppToastType.error,
      );
      return;
    }

    FocusScope.of(context).unfocus();
    await context.read<AuthCubit>().signUp(
      name: name,
      phone: phone,
      email: email,
      password: password,
      location: location,
      latitude: _latitude,
      longitude: _longitude,
      locationUpdatedAt: _locationUpdatedAt,
      profileImageBase64: _profileImageBase64,
      enableBiometricLogin: _biometricAvailable && _enableBiometricLogin,
      disableBiometricLogin: _biometricAvailable && !_enableBiometricLogin,
    );
  }

  Future<void> _loadBiometricStatus() async {
    final biometricRepository = context.read<BiometricAuthRepository>();
    final canUseBiometrics = await biometricRepository.canUseBiometrics();
    final label = await biometricRepository.preferredBiometricLabel();

    if (!mounted) {
      return;
    }

    setState(() {
      _biometricAvailable = canUseBiometrics;
      _biometricLabel = label;
    });
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

  Future<void> _syncCurrentLocation() async {
    if (_isFetchingLocation) {
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _isFetchingLocation = true;
    });

    try {
      final snapshot = await context
          .read<DeviceLocationRepository>()
          .getCurrentLocation();
      if (!mounted) {
        return;
      }

      setState(() {
        _locationController.text = visibleLocationLabel(
          snapshot.label,
          fallback: UserModel.defaultLocation,
        );
        _latitude = snapshot.latitude;
        _longitude = snapshot.longitude;
        _locationUpdatedAt = snapshot.capturedAt;
      });

      AppToast.show(
        context,
        message:
            'Current location captured. ${formatLocationRefreshTime(snapshot.capturedAt)}.',
        type: AppToastType.success,
      );
    } on DeviceLocationException catch (error) {
      if (!mounted) {
        return;
      }

      AppToast.show(context, message: error.message, type: AppToastType.error);
    } finally {
      if (mounted) {
        setState(() {
          _isFetchingLocation = false;
        });
      }
    }
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
          final isSubmitting =
              authState.isSubmitting && authState.action == AuthAction.signUp;

          return Scaffold(
            backgroundColor: AppColors.background,
            body: SafeArea(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(20.w),
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 620),
                    child: Column(
                      children: [
                        const _SignUpHeroCard().animatePage(),
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
                          child: AppStaggeredColumn(
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
                                'Create your account with username, phone, email, location, and password.',
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
                              AuthTextField(
                                controller: _nameController,
                                label: 'User Name',
                                hint: 'Enter user name',
                                icon: Icons.person_rounded,
                              ),
                              SizedBox(height: 14.h),
                              AuthTextField(
                                controller: _phoneController,
                                label: 'Phone Number',
                                hint: 'Enter phone number',
                                maxLength: 10,
                                icon: Icons.call_rounded,
                                keyboardType: TextInputType.phone,
                              ),
                              SizedBox(height: 14.h),
                              AuthTextField(
                                controller: _emailController,
                                label: 'Email',
                                hint: 'Enter email',
                                icon: Icons.mail_rounded,
                                keyboardType: TextInputType.emailAddress,
                              ),
                              SizedBox(height: 14.h),
                              AuthTextField(
                                controller: _locationController,
                                label: 'Location',
                                hint: 'Enter city or area',
                                icon: Icons.place_rounded,
                                keyboardType: TextInputType.streetAddress,
                              ),
                              SizedBox(height: 14.h),
                              AuthTextField(
                                controller: _passwordController,
                                label: 'Password',
                                hint: 'Create password',
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
                              SizedBox(height: 14.h),
                              AuthTextField(
                                controller: _confirmPasswordController,
                                label: 'Confirm Password',
                                hint: 'Confirm password',
                                icon: Icons.lock_rounded,
                                obscureText: _hideConfirmPassword,
                                suffixIcon: IconButton(
                                  onPressed: () {
                                    setState(() {
                                      _hideConfirmPassword =
                                          !_hideConfirmPassword;
                                    });
                                  },
                                  icon: Icon(
                                    _hideConfirmPassword
                                        ? Icons.visibility_rounded
                                        : Icons.visibility_off_rounded,
                                  ),
                                ),
                              ),
                              SizedBox(height: 14.h),
                              CurrentLocationCard(
                                title: 'Use current location',
                                locationLabel: visibleLocationLabel(
                                  _locationController.text.trim(),
                                  fallback: UserModel.defaultLocation,
                                ),
                                statusLabel: _locationUpdatedAt == null
                                    ? 'You can type your location manually or fill it from your device.'
                                    : formatLocationRefreshTime(
                                        _locationUpdatedAt,
                                      ),
                                isLoading: _isFetchingLocation,
                                onPressed: isSubmitting
                                    ? null
                                    : _syncCurrentLocation,
                                buttonLabel: 'Use Current Location',
                              ),
                              if (_biometricAvailable) ...[
                                SizedBox(height: 14.h),
                                _BiometricPreferenceTile(
                                  title: 'Enable $_biometricLabel login',
                                  subtitle:
                                      'Use this device biometric check after signup.',
                                  value: _enableBiometricLogin,
                                  onChanged: isSubmitting
                                      ? null
                                      : (value) {
                                          setState(() {
                                            _enableBiometricLogin = value;
                                          });
                                        },
                                ),
                              ],
                              SizedBox(height: 22.h),
                              SizedBox(
                                width: double.infinity,
                                child: FilledButton(
                                  onPressed: isSubmitting
                                      ? null
                                      : _createAccount,
                                  style: FilledButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: Colors.white,
                                    minimumSize: Size(double.infinity, 50.h),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20.r),
                                    ),
                                  ),
                                  child: Text(
                                    isSubmitting
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
                                    Navigator.of(context).pushReplacementNamed(
                                      LoginScreen.routeName,
                                    );
                                  },
                                  child: const Text(
                                    'Already have an account? Login',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ).animatePage(delay: const Duration(milliseconds: 120)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
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
        gradient: LinearGradient(
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

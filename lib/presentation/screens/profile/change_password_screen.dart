import 'package:bookcart/core/constants/app_colors.dart';
import 'package:bookcart/core/utils/app_animation_utils.dart';
import 'package:bookcart/logic/cubits/auth_cubit.dart';
import 'package:bookcart/logic/cubits/auth_state.dart';
import 'package:bookcart/presentation/widgets/auth_text_field.dart';
import 'package:bookcart/presentation/widgets/app_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  late final TextEditingController _currentPasswordController;
  late final TextEditingController _newPasswordController;
  late final TextEditingController _confirmPasswordController;
  bool _hideCurrentPassword = true;
  bool _hideNewPassword = true;
  bool _hideConfirmPassword = true;

  @override
  void initState() {
    super.initState();
    _currentPasswordController = TextEditingController();
    _newPasswordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final currentPassword = _currentPasswordController.text.trim();
    final newPassword = _newPasswordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (currentPassword.isEmpty ||
        newPassword.isEmpty ||
        confirmPassword.isEmpty) {
      AppToast.show(
        context,
        message: 'Fill in all password fields to continue.',
        type: AppToastType.error,
      );
      return;
    }

    if (newPassword.length < 6) {
      AppToast.show(
        context,
        message: 'New password should be at least 6 characters.',
        type: AppToastType.error,
      );
      return;
    }

    if (newPassword != confirmPassword) {
      AppToast.show(
        context,
        message: 'New password and confirm password do not match.',
        type: AppToastType.error,
      );
      return;
    }

    if (currentPassword == newPassword) {
      AppToast.show(
        context,
        message: 'Choose a new password different from the current one.',
        type: AppToastType.error,
      );
      return;
    }

    await context.read<AuthCubit>().changePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthCubit, AuthState>(
      listenWhen: (previous, current) =>
          previous.errorMessage != current.errorMessage ||
          previous.successMessage != current.successMessage,
      listener: (context, state) {
        if (!(ModalRoute.of(context)?.isCurrent ?? true)) {
          return;
        }

        if (state.errorMessage != null) {
          AppToast.show(
            context,
            message: state.errorMessage!,
            type: AppToastType.error,
          );
          context.read<AuthCubit>().clearFeedback();
          return;
        }

        if (state.successMessage != null) {
          AppToast.show(
            context,
            message: state.successMessage!,
            type: AppToastType.success,
          );
          context.read<AuthCubit>().clearFeedback();
          Navigator.of(context).pop(true);
        }
      },
      builder: (context, state) {
        final isSaving =
            state.isSubmitting && state.action == AuthAction.changePassword;

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: const Text('Change Password'),
            centerTitle: true,
          ),
          body: SingleChildScrollView(
            padding: EdgeInsets.all(20.w),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(20.w),
                  decoration: BoxDecoration(
                    color: AppColors.white,
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
                        'Update your login password securely.',
                        style: TextStyle(
                          color: AppColors.dark,
                          fontSize: 22.sp,
                          fontWeight: FontWeight.w800,
                          height: 1.25,
                        ),
                      ),
                      SizedBox(height: 10.h),
                      Text(
                        'For security, enter your current password before choosing a new one.',
                        style: TextStyle(
                          color: AppColors.muted,
                          fontSize: 14.sp,
                          height: 1.5,
                        ),
                      ),
                      SizedBox(height: 22.h),
                      AuthTextField(
                        controller: _currentPasswordController,
                        label: 'Current Password',
                        hint: 'Enter current password',
                        icon: Icons.lock_rounded,
                        obscureText: _hideCurrentPassword,
                        suffixIcon: IconButton(
                          onPressed: () {
                            setState(() {
                              _hideCurrentPassword = !_hideCurrentPassword;
                            });
                          },
                          icon: Icon(
                            _hideCurrentPassword
                                ? Icons.visibility_rounded
                                : Icons.visibility_off_rounded,
                          ),
                        ),
                      ),
                      SizedBox(height: 14.h),
                      AuthTextField(
                        controller: _newPasswordController,
                        label: 'New Password',
                        hint: 'Create new password',
                        icon: Icons.lock_rounded,
                        obscureText: _hideNewPassword,
                        suffixIcon: IconButton(
                          onPressed: () {
                            setState(() {
                              _hideNewPassword = !_hideNewPassword;
                            });
                          },
                          icon: Icon(
                            _hideNewPassword
                                ? Icons.visibility_rounded
                                : Icons.visibility_off_rounded,
                          ),
                        ),
                      ),
                      SizedBox(height: 14.h),
                      AuthTextField(
                        controller: _confirmPasswordController,
                        label: 'Confirm Password',
                        hint: 'Re-enter new password',
                        icon: Icons.lock_rounded,
                        obscureText: _hideConfirmPassword,
                        suffixIcon: IconButton(
                          onPressed: () {
                            setState(() {
                              _hideConfirmPassword = !_hideConfirmPassword;
                            });
                          },
                          icon: Icon(
                            _hideConfirmPassword
                                ? Icons.visibility_rounded
                                : Icons.visibility_off_rounded,
                          ),
                        ),
                      ),
                      SizedBox(height: 22.h),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: isSaving ? null : _submit,
                          child: Text(
                            isSaving ? 'Updating...' : 'Update Password',
                          ),
                        ),
                      ),
                    ],
                  ),
                ).animatePage(),
              ),
            ),
          ),
        );
      },
    );
  }
}

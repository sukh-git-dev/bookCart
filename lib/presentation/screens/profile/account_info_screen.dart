import 'dart:convert';
import 'dart:typed_data';

import 'package:bookcart/core/constants/app_colors.dart';
import 'package:bookcart/data/models/user_model.dart';
import 'package:bookcart/logic/cubits/auth_cubit.dart';
import 'package:bookcart/logic/cubits/profile_cubit.dart';
import 'package:bookcart/logic/cubits/profile_state.dart';
import 'package:bookcart/presentation/screens/profile/widgets/info_field.dart';
import 'package:bookcart/presentation/widgets/app_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';

class AccountInfoScreen extends StatefulWidget {
  const AccountInfoScreen({super.key, required this.user});

  final UserModel user;

  @override
  State<AccountInfoScreen> createState() => _AccountInfoScreenState();
}

class _AccountInfoScreenState extends State<AccountInfoScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  late final TextEditingController _locationController;
  final ImagePicker _picker = ImagePicker();
  bool _isEditing = false;
  Uint8List? _profileImageBytes;
  String? _profileImageBase64;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.name);
    _phoneController = TextEditingController(text: widget.user.phone);
    _emailController = TextEditingController(text: widget.user.email);
    _locationController = TextEditingController(text: widget.user.location);
    if (widget.user.profileImageBase64 != null &&
        widget.user.profileImageBase64!.isNotEmpty) {
      _profileImageBase64 = widget.user.profileImageBase64;
      _profileImageBytes = base64Decode(widget.user.profileImageBase64!);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _locationController.dispose();
    super.dispose();
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

  Future<void> _save() async {
    final updatedUser = widget.user.copyWith(
      name: _nameController.text.trim().isEmpty
          ? widget.user.name
          : _nameController.text.trim(),
      phone: _phoneController.text.trim().isEmpty
          ? widget.user.phone
          : _phoneController.text.trim(),
      email: _emailController.text.trim().isEmpty
          ? widget.user.email
          : _emailController.text.trim(),
      location: _locationController.text.trim().isEmpty
          ? widget.user.location
          : _locationController.text.trim(),
      profileImageBase64: _profileImageBase64,
    );

    await context.read<ProfileCubit>().updateProfile(updatedUser);
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ProfileCubit, ProfileState>(
      listenWhen: (previous, current) =>
          previous.errorMessage != current.errorMessage ||
          previous.successMessage != current.successMessage,
      listener: (context, state) async {
        if (state.errorMessage != null) {
          AppToast.show(
            context,
            message: state.errorMessage!,
            type: AppToastType.error,
          );
          context.read<ProfileCubit>().clearFeedback();
          return;
        }

        if (state.successMessage != null) {
          if (mounted) {
            setState(() {
              _isEditing = false;
            });
          }
          AppToast.show(
            context,
            message: state.successMessage!,
            type: AppToastType.success,
          );
          context.read<ProfileCubit>().clearFeedback();
          await context.read<AuthCubit>().refreshUser();
          if (context.mounted) {
            Navigator.of(context).pop(true);
          }
        }
      },
      builder: (context, state) {
        final isSaving = state.isSaving;

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: const Text('Card Info'),
            centerTitle: true,
            actions: [
              TextButton(
                onPressed: isSaving
                    ? null
                    : () {
                        setState(() {
                          _isEditing = !_isEditing;
                        });
                      },
                child: Text(_isEditing ? 'View' : 'Edit'),
              ),
            ],
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
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: _isEditing && !isSaving
                            ? _pickProfileImage
                            : null,
                        child: Column(
                          children: [
                            Container(
                              width: 104.w,
                              height: 104.w,
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
                                        size: 52.sp,
                                        color: AppColors.primary,
                                      ),
                              ),
                            ),
                            SizedBox(height: 10.h),
                            Text(
                              _isEditing
                                  ? 'Change Profile Image'
                                  : 'Profile Image',
                              style: TextStyle(
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w700,
                                color: _isEditing
                                    ? AppColors.primary
                                    : AppColors.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 20.h),
                      InfoField(
                        label: 'Full Name',
                        controller: _nameController,
                        enabled: _isEditing && !isSaving,
                        icon: Icons.person_rounded,
                      ),
                      SizedBox(height: 14.h),
                      InfoField(
                        label: 'Phone Number',
                        controller: _phoneController,
                        enabled: _isEditing && !isSaving,
                        icon: Icons.call_rounded,
                        keyboardType: TextInputType.phone,
                      ),
                      SizedBox(height: 14.h),
                      InfoField(
                        label: 'Email',
                        controller: _emailController,
                        enabled: _isEditing && !isSaving,
                        icon: Icons.mail_rounded,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      SizedBox(height: 14.h),
                      InfoField(
                        label: 'Location',
                        controller: _locationController,
                        enabled: _isEditing && !isSaving,
                        icon: Icons.location_on_rounded,
                      ),
                      if (_isEditing) ...[
                        SizedBox(height: 22.h),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: isSaving ? null : _save,
                            child: Text(
                              isSaving ? 'Saving...' : 'Save Changes',
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

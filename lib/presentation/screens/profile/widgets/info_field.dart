import 'package:bookcart/core/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class InfoField extends StatelessWidget {
  const InfoField({
    super.key,
    required this.label,
    required this.controller,
    required this.enabled,
    required this.icon,
    this.keyboardType,
  });

  final String label;
  final TextEditingController controller;
  final bool enabled;
  final IconData icon;
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
          enabled: enabled,
          keyboardType: keyboardType,
          style: TextStyle(color: AppColors.dark, fontSize: 14.sp),
          decoration: InputDecoration(
            prefixIcon: Icon(icon),
            filled: true,
            fillColor: enabled ? AppColors.surface : const Color(0xFFF7FBFA),
          ),
        ),
      ],
    );
  }
}

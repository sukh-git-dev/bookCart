import 'package:bookcart/core/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

enum AppToastType { success, error }

class AppToast {
  static void show(
    BuildContext context, {
    required String message,
    required AppToastType type,
  }) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          elevation: 0,
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.transparent,
          margin: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
          content: _ToastCard(message: message, type: type),
        ),
      );
  }
}

class _ToastCard extends StatelessWidget {
  const _ToastCard({required this.message, required this.type});

  final String message;
  final AppToastType type;

  @override
  Widget build(BuildContext context) {
    final isSuccess = type == AppToastType.success;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(22.r),
        border: Border.all(
          color: isSuccess ? AppColors.primary : const Color(0xFFD9534F),
          width: 1.3,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42.w,
            height: 42.w,
            padding: EdgeInsets.all(10.w),
            decoration: BoxDecoration(
              color: isSuccess
                  ? AppColors.primary.withValues(alpha: 0.12)
                  : const Color(0xFFD9534F).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14.r),
            ),
            child: SvgPicture.asset(
              isSuccess ? 'assets/toast/success.svg' : 'assets/toast/error.svg',
              colorFilter: ColorFilter.mode(
                isSuccess ? AppColors.primary : const Color(0xFFD9534F),
                BlendMode.srcIn,
              ),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: AppColors.dark,
                fontSize: 13.sp,
                height: 1.35,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

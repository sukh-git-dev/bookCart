import 'package:bookcart/core/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class PlaceholderTabCard extends StatelessWidget {
  const PlaceholderTabCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(20.w),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(26.w),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(28.r),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72.w,
              height: 72.w,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(22.r),
              ),
              child: Icon(icon, size: 34.sp, color: AppColors.primary),
            ),
            SizedBox(height: 22.h),
            Text(
              title,
              style: TextStyle(
                fontSize: 28.sp,
                fontWeight: FontWeight.w800,
                color: AppColors.dark,
              ),
            ),
            SizedBox(height: 10.h),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 15.sp,
                height: 1.5,
                color: AppColors.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

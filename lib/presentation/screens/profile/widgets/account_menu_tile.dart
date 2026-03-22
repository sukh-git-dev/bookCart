import 'package:bookcart/core/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AccountMenuTile extends StatelessWidget {
  const AccountMenuTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.isDanger = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool isDanger;

  @override
  Widget build(BuildContext context) {
    final accent = isDanger ? const Color(0xFFB8403F) : AppColors.primary;
    return InkWell(
      borderRadius: BorderRadius.circular(22.r),
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: isDanger ? const Color(0xFFFFF1F0) : AppColors.surface,
          borderRadius: BorderRadius.circular(22.r),
          border: Border.all(
            color: isDanger ? const Color(0xFFF0C4C1) : AppColors.border,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 46.w,
              height: 46.w,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(15.r),
              ),
              child: Icon(icon, color: accent, size: 22.sp),
            ),
            SizedBox(width: 14.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w800,
                      color: isDanger ? accent : AppColors.dark,
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
            Icon(
              Icons.chevron_right_rounded,
              color: isDanger ? accent : AppColors.muted,
              size: 22.sp,
            ),
          ],
        ),
      ),
    );
  }
}

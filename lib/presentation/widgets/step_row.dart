import 'package:bookcart/core/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class StepRow extends StatelessWidget {
  const StepRow({super.key, required this.step, required this.text});

  final String step;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 10.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28.w,
            height: 28.w,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Text(
              step,
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
              ),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(top: 4.h),
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 13.sp,
                  height: 1.45,
                  color: const Color(0xFF5D5247),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

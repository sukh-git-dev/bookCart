import 'package:bookcart/core/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CurrentLocationCard extends StatelessWidget {
  const CurrentLocationCard({
    super.key,
    required this.title,
    required this.locationLabel,
    required this.statusLabel,
    required this.isLoading,
    required this.onPressed,
    this.buttonLabel = 'Use Current Location',
  });

  final String title;
  final String locationLabel;
  final String statusLabel;
  final bool isLoading;
  final VoidCallback? onPressed;
  final String buttonLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42.w,
                height: 42.w,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16.r),
                ),
                child: Icon(
                  Icons.my_location_rounded,
                  color: AppColors.primary,
                  size: 22.sp,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w800,
                    color: AppColors.dark,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Text(
            locationLabel,
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.w700,
              color: AppColors.dark,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            statusLabel,
            style: TextStyle(
              fontSize: 12.sp,
              height: 1.35,
              color: AppColors.muted,
            ),
          ),
          SizedBox(height: 14.h),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: isLoading ? null : onPressed,
              icon: Icon(
                isLoading ? Icons.sync_rounded : Icons.gps_fixed_rounded,
                size: 18.sp,
              ),
              label: Text(
                isLoading ? 'Updating location...' : buttonLabel,
                style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w700),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: BorderSide(color: AppColors.primary),
                minimumSize: Size(double.infinity, 46.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18.r),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

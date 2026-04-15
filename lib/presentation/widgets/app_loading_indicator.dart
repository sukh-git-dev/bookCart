import 'package:bookcart/core/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

class AppLoadingIndicator extends StatelessWidget {
  const AppLoadingIndicator({
    super.key,
    this.label,
    this.size = 48,
    this.color,
  });

  final String? label;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final loaderColor = color ?? AppColors.primary;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        LoadingAnimationWidget.halfTriangleDot(color: loaderColor, size: size),
        if (label != null) ...[
          SizedBox(height: 14.h),
          Text(
            label!,
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.w700,
              color: AppColors.muted,
            ),
          ),
        ],
      ],
    );
  }
}

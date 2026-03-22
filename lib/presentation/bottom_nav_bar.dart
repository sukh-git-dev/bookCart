import 'package:bookcart/core/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

class BookBottomNavBar extends StatelessWidget {
  const BookBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  static const List<BottomNavItem> items = [
    BottomNavItem(label: 'Home', assetPath: 'assets/icons/home.svg'),
    BottomNavItem(label: 'My Books', assetPath: 'assets/icons/books.svg'),
    BottomNavItem(label: 'Sell', assetPath: 'assets/icons/sell.svg'),
    BottomNavItem(label: 'Chat', assetPath: 'assets/icons/chat.svg'),
    BottomNavItem(label: 'Account', assetPath: 'assets/icons/account.svg'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.fromLTRB(16.w, 0, 16.w, 20.h),
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(28.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: List.generate(items.length, (index) {
          final item = items[index];
          final isSelected = index == currentIndex;
          return Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(20.r),
              onTap: () => onTap(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                padding: EdgeInsets.symmetric(vertical: 8.h),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary.withValues(alpha: 0.12)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SvgPicture.asset(
                      item.assetPath,
                      width: 24.sp,
                      height: 24.sp,
                      colorFilter: ColorFilter.mode(
                        isSelected
                            ? AppColors.primary
                            : const Color(0xFF7D746A),
                        BlendMode.srcIn,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      item.label,
                      style: TextStyle(
                        fontSize: 11.sp,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: isSelected
                            ? AppColors.primary
                            : const Color(0xFF7D746A),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class BottomNavItem {
  const BottomNavItem({required this.label, required this.assetPath});

  final String label;
  final String assetPath;
}

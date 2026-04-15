import 'package:bookcart/core/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:stylish_bottom_bar/stylish_bottom_bar.dart';

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
    final inactiveColor = const Color(0xFF7D746A);

    return Container(
      margin: EdgeInsets.fromLTRB(16.w, 0, 16.w, 20.h),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: StylishBottomBar(
        currentIndex: currentIndex,
        backgroundColor: AppColors.white,
        elevation: 0,
        hasNotch: false,
        borderRadius: BorderRadius.circular(28.r),
        option: AnimatedBarOptions(
          barAnimation: BarAnimation.liquid,
          iconStyle: IconStyle.animated,
          opacity: 0.18,
          iconSize: 24.sp,
        ),
        items: [
          for (final item in items)
            BottomBarItem(
              icon: _NavAssetIcon(
                assetPath: item.assetPath,
                color: inactiveColor,
              ),
              selectedIcon: _NavAssetIcon(
                assetPath: item.assetPath,
                color: AppColors.primary,
              ),
              title: Text(item.label),
              backgroundColor: AppColors.primary,
              selectedColor: AppColors.primary,
              unSelectedColor: inactiveColor,
            ),
        ],
        onTap: onTap,
      ),
    );
  }
}

class _NavAssetIcon extends StatelessWidget {
  const _NavAssetIcon({required this.assetPath, required this.color});

  final String assetPath;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      assetPath,
      width: 24.sp,
      height: 24.sp,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
    );
  }
}

class BottomNavItem {
  const BottomNavItem({required this.label, required this.assetPath});

  final String label;
  final String assetPath;
}

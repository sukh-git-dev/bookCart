import 'package:bookcart/core/constants/app_colors.dart';
import 'package:bookcart/core/theme/app_color_palette.dart';
import 'package:bookcart/logic/cubits/theme_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ThemeChangeScreen extends StatelessWidget {
  const ThemeChangeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text('Change Theme'),
      ),
      body: BlocBuilder<ThemeCubit, AppColorPalette>(
        builder: (context, activePalette) {
          return SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 32.h),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ThemeHeroCard(activePalette: activePalette),
                    SizedBox(height: 20.h),
                    Text(
                      'Choose App Color',
                      style: TextStyle(
                        fontSize: 22.sp,
                        fontWeight: FontWeight.w800,
                        color: AppColors.dark,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      'Tap any theme card. The full app color changes instantly and stays saved after restart.',
                      style: TextStyle(
                        fontSize: 13.sp,
                        height: 1.45,
                        color: AppColors.muted,
                      ),
                    ),
                    SizedBox(height: 18.h),
                    for (final palette in AppThemePalettes.all) ...[
                      _ThemeOptionCard(
                        palette: palette,
                        isSelected: palette.id == activePalette.id,
                        onTap: () {
                          context.read<ThemeCubit>().selectPalette(palette);
                        },
                      ),
                      SizedBox(height: 14.h),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ThemeHeroCard extends StatelessWidget {
  const _ThemeHeroCard({required this.activePalette});

  final AppColorPalette activePalette;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(22.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [activePalette.dark, activePalette.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30.r),
        boxShadow: [
          BoxShadow(
            color: activePalette.primary.withValues(alpha: 0.22),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 7.h),
            decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(18.r),
            ),
            child: Text(
              'Active Theme',
              style: TextStyle(
                color: AppColors.white,
                fontSize: 12.sp,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          SizedBox(height: 18.h),
          Text(
            activePalette.name,
            style: TextStyle(
              color: AppColors.white,
              fontSize: 30.sp,
              height: 1.1,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 10.h),
          Text(
            'This color style is now used across buttons, cards, filters, and navigation.',
            style: TextStyle(
              color: AppColors.white.withValues(alpha: 0.84),
              fontSize: 13.sp,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _ThemeOptionCard extends StatelessWidget {
  const _ThemeOptionCard({
    required this.palette,
    required this.isSelected,
    required this.onTap,
  });

  final AppColorPalette palette;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(26.r),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: isSelected ? palette.surface : AppColors.white,
          borderRadius: BorderRadius.circular(26.r),
          border: Border.all(
            color: isSelected ? palette.primary : AppColors.border,
            width: isSelected ? 1.7 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isSelected ? 0.07 : 0.04),
              blurRadius: isSelected ? 18 : 12,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 70.w,
              height: 70.w,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [palette.primary, palette.secondary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(22.r),
              ),
              child: Center(
                child: Icon(
                  isSelected
                      ? Icons.check_circle_rounded
                      : Icons.palette_rounded,
                  color: AppColors.white,
                  size: 28.sp,
                ),
              ),
            ),
            SizedBox(width: 14.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    palette.name,
                    style: TextStyle(
                      fontSize: 17.sp,
                      fontWeight: FontWeight.w900,
                      color: AppColors.dark,
                    ),
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    isSelected ? 'Active now' : 'Tap to apply this theme',
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColors.muted,
                    ),
                  ),
                  SizedBox(height: 10.h),
                  Row(
                    children: [
                      _PaletteDot(color: palette.primary),
                      SizedBox(width: 7.w),
                      _PaletteDot(color: palette.secondary),
                      SizedBox(width: 7.w),
                      _PaletteDot(color: palette.dark),
                    ],
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: isSelected ? palette.primary : AppColors.muted,
              size: 24.sp,
            ),
          ],
        ),
      ),
    );
  }
}

class _PaletteDot extends StatelessWidget {
  const _PaletteDot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 18.w,
      height: 18.w,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.white, width: 1.2),
      ),
    );
  }
}

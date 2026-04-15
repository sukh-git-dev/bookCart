import 'package:bookcart/data/models/user_model.dart';
import 'package:bookcart/data/repository/auth_repository.dart';
import 'package:bookcart/core/constants/app_colors.dart';
import 'package:bookcart/core/theme/app_color_palette.dart';
import 'package:bookcart/logic/cubits/auth_cubit.dart';
import 'package:bookcart/logic/cubits/auth_state.dart';
import 'package:bookcart/logic/cubits/profile_cubit.dart';
import 'package:bookcart/logic/cubits/profile_state.dart';
import 'package:bookcart/logic/cubits/theme_cubit.dart';
import 'package:bookcart/presentation/screens/auth/login_screen.dart';
import 'package:bookcart/presentation/screens/profile/about_screen.dart';
import 'package:bookcart/presentation/screens/profile/account_info_screen.dart';
import 'package:bookcart/presentation/screens/profile/change_password_screen.dart';
import 'package:bookcart/presentation/screens/profile/privacy_screen.dart';
import 'package:bookcart/presentation/screens/profile/widgets/account_action_dialog.dart';
import 'package:bookcart/presentation/screens/profile/widgets/account_hero_card.dart';
import 'package:bookcart/presentation/screens/profile/widgets/account_menu_tile.dart';
import 'package:bookcart/presentation/screens/profile/widgets/profile_summary_card.dart';
import 'package:bookcart/presentation/widgets/app_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          ProfileCubit(context.read<AuthRepository>())..loadProfile(),
      child: const _ProfileView(),
    );
  }
}

class _ProfileView extends StatelessWidget {
  const _ProfileView();

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listenWhen: (previous, current) =>
          previous.status != current.status ||
          previous.errorMessage != current.errorMessage,
      listener: (context, state) {
        if (!(ModalRoute.of(context)?.isCurrent ?? true)) {
          return;
        }

        if (state.errorMessage != null) {
          AppToast.show(
            context,
            message: state.errorMessage!,
            type: AppToastType.error,
          );
          context.read<AuthCubit>().clearFeedback();
          return;
        }

        if (state.status == AuthStatus.unauthenticated) {
          Navigator.of(
            context,
          ).pushNamedAndRemoveUntil(LoginScreen.routeName, (route) => false);
        }
      },
      child: BlocConsumer<ProfileCubit, ProfileState>(
        listenWhen: (previous, current) =>
            previous.errorMessage != current.errorMessage,
        listener: (context, state) {
          if (state.errorMessage != null) {
            AppToast.show(
              context,
              message: state.errorMessage!,
              type: AppToastType.error,
            );
            context.read<ProfileCubit>().clearFeedback();
          }
        },
        builder: (context, state) {
          final user = state.user ?? context.read<AuthCubit>().state.user;
          if (user == null && state.status == ProfileStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (user == null) {
            return Center(
              child: FilledButton(
                onPressed: context.read<ProfileCubit>().loadProfile,
                child: const Text('Reload Profile'),
              ),
            );
          }

          return LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 1000;
              return SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 130.h),
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: isWide ? 920 : 760),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const AccountHeroCard(),
                        SizedBox(height: 24.h),
                        ProfileSummaryCard(user: user),
                        SizedBox(height: 18.h),
                        const _ThemeColorCard(),
                        SizedBox(height: 18.h),
                        _AccountMenuCard(user: user),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _ThemeColorCard extends StatelessWidget {
  const _ThemeColorCard();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeCubit, AppColorPalette>(
      builder: (context, palette) {
        return Container(
          width: double.infinity,
          padding: EdgeInsets.all(20.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Theme Colors',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w800,
                  color: AppColors.dark,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                'Choose a color style for the app. Your selection updates the full interface instantly.',
                style: TextStyle(
                  fontSize: 13.sp,
                  height: 1.45,
                  color: AppColors.muted,
                ),
              ),
              SizedBox(height: 16.h),
              Wrap(
                spacing: 12.w,
                runSpacing: 12.h,
                children: [
                  for (final option in AppThemePalettes.all)
                    _ThemePaletteChip(
                      palette: option,
                      isSelected: option.id == palette.id,
                      onTap: () {
                        context.read<ThemeCubit>().selectPalette(option);
                      },
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ThemePaletteChip extends StatelessWidget {
  const _ThemePaletteChip({
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
      borderRadius: BorderRadius.circular(22.r),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 140.w,
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: isSelected ? palette.surface : Colors.white,
          borderRadius: BorderRadius.circular(22.r),
          border: Border.all(
            color: isSelected ? palette.primary : AppColors.border,
            width: isSelected ? 1.6 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _PaletteDot(color: palette.primary),
                SizedBox(width: 6.w),
                _PaletteDot(color: palette.secondary),
                SizedBox(width: 6.w),
                _PaletteDot(color: palette.dark),
                const Spacer(),
                if (isSelected)
                  Icon(
                    Icons.check_circle_rounded,
                    size: 18.sp,
                    color: palette.primary,
                  ),
              ],
            ),
            SizedBox(height: 12.h),
            Text(
              palette.name,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w800,
                color: AppColors.dark,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              isSelected ? 'Active theme' : 'Tap to apply',
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.muted,
              ),
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
        border: Border.all(color: Colors.white, width: 1.2),
      ),
    );
  }
}

class _AccountMenuCard extends StatelessWidget {
  const _AccountMenuCard({required this.user});

  final UserModel user;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          AccountMenuTile(
            icon: Icons.badge_rounded,
            title: 'Card Info',
            subtitle: '${user.name} • ${user.phone} • ${user.email}',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => BlocProvider.value(
                    value: context.read<ProfileCubit>(),
                    child: AccountInfoScreen(user: user),
                  ),
                ),
              );
            },
          ),
          SizedBox(height: 12.h),
          AccountMenuTile(
            icon: Icons.lock_reset_rounded,
            title: 'Change Password',
            subtitle: 'Update the password you use to sign in.',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ChangePasswordScreen()),
              );
            },
          ),
          SizedBox(height: 12.h),
          AccountMenuTile(
            icon: Icons.privacy_tip_rounded,
            title: 'Privacy',
            subtitle: 'Read privacy and data protection info.',
            onTap: () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const PrivacyScreen()));
            },
          ),
          SizedBox(height: 12.h),
          AccountMenuTile(
            icon: Icons.info_rounded,
            title: 'About',
            subtitle: 'Learn more about Book Cart.',
            onTap: () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const AboutScreen()));
            },
          ),
          SizedBox(height: 12.h),
          AccountMenuTile(
            icon: Icons.block_rounded,
            title: 'Stop Ad',
            subtitle: 'Disable ads for this account.',
            onTap: () {
              showAccountActionDialog(
                context,
                title: 'Stop Ads',
                message: 'Do you want to disable ads for this account?',
              );
            },
          ),
          SizedBox(height: 12.h),
          AccountMenuTile(
            icon: Icons.logout_rounded,
            title: 'Logout',
            subtitle: 'Sign out from this account.',
            onTap: () {
              showAccountActionDialog(
                context,
                title: 'Logout',
                message: 'Do you want to logout from this account?',
                onConfirm: () async {
                  await context.read<AuthCubit>().logout();
                },
              );
            },
          ),
          SizedBox(height: 12.h),
          AccountMenuTile(
            icon: Icons.delete_forever_rounded,
            title: 'Delete',
            subtitle: 'Delete this account permanently.',
            isDanger: true,
            onTap: () {
              showAccountActionDialog(
                context,
                title: 'Delete Account',
                message: 'Do you want to permanently delete this account?',
                onConfirm: () async {
                  await context.read<AuthCubit>().deleteAccount();
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

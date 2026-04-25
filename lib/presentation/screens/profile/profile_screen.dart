import 'package:bookcart/data/models/user_model.dart';
import 'package:bookcart/data/repository/auth_repository.dart';
import 'package:bookcart/core/constants/app_colors.dart';
import 'package:bookcart/core/utils/app_animation_utils.dart';
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
import 'package:bookcart/presentation/screens/profile/theme_change_screen.dart';
import 'package:bookcart/presentation/screens/profile/widgets/account_action_dialog.dart';
import 'package:bookcart/presentation/screens/profile/widgets/account_hero_card.dart';
import 'package:bookcart/presentation/screens/profile/widgets/account_menu_tile.dart';
import 'package:bookcart/presentation/screens/profile/widgets/profile_summary_card.dart';
import 'package:bookcart/presentation/widgets/app_loading_indicator.dart';
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
            return const Center(
              child: AppLoadingIndicator(label: 'Loading your profile...'),
            );
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
                    child: AppStaggeredColumn(
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
        void openThemeScreen() {
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const ThemeChangeScreen()));
        }

        return Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28.r),
          child: InkWell(
            borderRadius: BorderRadius.circular(28.r),
            onTap: openThemeScreen,
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
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
                  Row(
                    children: [
                      Container(
                        width: 52.w,
                        height: 52.w,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [palette.primary, palette.secondary],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(18.r),
                        ),
                        child: Icon(
                          Icons.palette_rounded,
                          color: AppColors.white,
                          size: 24.sp,
                        ),
                      ),
                      SizedBox(width: 14.w),
                      Expanded(
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
                            SizedBox(height: 4.h),
                            Text(
                              '${palette.name} theme active',
                              style: TextStyle(
                                fontSize: 13.sp,
                                height: 1.35,
                                color: AppColors.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 24.sp,
                        color: AppColors.muted,
                      ),
                    ],
                  ),
                  SizedBox(height: 16.h),
                  Row(
                    children: [
                      _PaletteDot(color: palette.primary),
                      SizedBox(width: 8.w),
                      _PaletteDot(color: palette.secondary),
                      SizedBox(width: 8.w),
                      _PaletteDot(color: palette.dark),
                      const Spacer(),
                      FilledButton(
                        onPressed: openThemeScreen,
                        child: const Text('Change Theme'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
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
          ).animateListItem(order: 0),
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
          ).animateListItem(order: 1),
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
          ).animateListItem(order: 2),
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
          ).animateListItem(order: 3),
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
          ).animateListItem(order: 4),
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
          ).animateListItem(order: 5),
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
          ).animateListItem(order: 6),
        ],
      ),
    );
  }
}

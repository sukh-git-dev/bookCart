import 'package:bookcart/data/models/user_model.dart';
import 'package:bookcart/data/repository/auth_repository.dart';
import 'package:bookcart/presentation/screens/profile/about_screen.dart';
import 'package:bookcart/presentation/screens/profile/account_info_screen.dart';
import 'package:bookcart/presentation/screens/profile/privacy_screen.dart';
import 'package:bookcart/presentation/screens/profile/widgets/account_action_dialog.dart';
import 'package:bookcart/presentation/screens/profile/widgets/account_hero_card.dart';
import 'package:bookcart/presentation/screens/profile/widgets/account_menu_tile.dart';
import 'package:bookcart/presentation/screens/profile/widgets/profile_summary_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Future<UserModel?> _userFuture;

  @override
  void initState() {
    super.initState();
    _userFuture = context.read<AuthRepository>().getCurrentUser();
  }

  void _refreshUser() {
    setState(() {
      _userFuture = context.read<AuthRepository>().getCurrentUser();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UserModel?>(
      future: _userFuture,
      builder: (context, snapshot) {
        final user =
            snapshot.data ??
            const UserModel(
              name: 'Book Cart User',
              phone: '94650 56434',
              email: 'user@bookcart.app',
              password: '',
            );

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
                      _AccountMenuCard(
                        user: user,
                        onChanged: _refreshUser,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _AccountMenuCard extends StatelessWidget {
  const _AccountMenuCard({
    required this.user,
    required this.onChanged,
  });

  final UserModel user;
  final VoidCallback onChanged;

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
            onTap: () async {
              final changed = await Navigator.of(context).push<bool>(
                MaterialPageRoute(
                  builder: (_) => AccountInfoScreen(user: user),
                ),
              );
              if (changed == true) {
                onChanged();
              }
            },
          ),
          SizedBox(height: 12.h),
          AccountMenuTile(
            icon: Icons.privacy_tip_rounded,
            title: 'Privacy',
            subtitle: 'Read privacy and data protection info.',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const PrivacyScreen()),
              );
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
                  await context.read<AuthRepository>().logout();
                  if (context.mounted) {
                    Navigator.of(
                      context,
                    ).pushNamedAndRemoveUntil('/login', (route) => false);
                  }
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
                  await context.read<AuthRepository>().deleteAccount();
                  if (context.mounted) {
                    Navigator.of(
                      context,
                    ).pushNamedAndRemoveUntil('/login', (route) => false);
                  }
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

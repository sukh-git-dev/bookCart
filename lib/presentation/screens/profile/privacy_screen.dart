import 'package:bookcart/core/constants/app_colors.dart';
import 'package:bookcart/presentation/screens/profile/widgets/policy_card.dart';
import 'package:bookcart/presentation/screens/profile/widgets/policy_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Privacy'), centerTitle: true),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20.w),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.all(22.w),
              decoration: BoxDecoration(
                color: AppColors.white,
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
                  const PolicyHeader(
                    icon: Icons.privacy_tip_rounded,
                    title: 'Privacy Policy',
                    subtitle:
                        'Read how Book Cart handles account and marketplace data.',
                  ),
                  SizedBox(height: 20.h),
                  const PolicyCard(
                    title: 'Account Data',
                    body:
                        'Your name, phone number, email, and location are stored in Firebase Authentication and Cloud Firestore for account access and profile display.',
                  ),
                  SizedBox(height: 12.h),
                  const PolicyCard(
                    title: 'Images',
                    body:
                        'Profile images selected during signup or account updates are saved with your account profile data for use inside the app experience.',
                  ),
                  SizedBox(height: 12.h),
                  const PolicyCard(
                    title: 'Chats And Listings',
                    body:
                        'Chats and listings are shown in the app UI, while authenticated account actions use Firebase-backed storage and identity services.',
                  ),
                  SizedBox(height: 12.h),
                  const PolicyCard(
                    title: 'User Control',
                    body:
                        'You can update your account details, logout from the current session, or delete your Firebase-backed account from the account screen.',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

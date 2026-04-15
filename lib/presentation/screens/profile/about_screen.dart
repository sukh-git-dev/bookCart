import 'package:bookcart/core/constants/app_colors.dart';
import 'package:bookcart/presentation/screens/profile/widgets/policy_card.dart';
import 'package:bookcart/presentation/screens/profile/widgets/policy_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('About'), centerTitle: true),
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
                  Center(
                    child: Container(
                      width: 108.w,
                      height: 108.w,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(28.r),
                      ),
                      padding: EdgeInsets.all(14.w),
                      child: Image.asset('assets/app/app_icon.png'),
                    ),
                  ),
                  SizedBox(height: 18.h),
                  const PolicyHeader(
                    icon: Icons.info_rounded,
                    title: 'About Book Cart',
                    subtitle:
                        'A simple book marketplace app for buying, selling, and chatting.',
                  ),
                  SizedBox(height: 20.h),
                  const PolicyCard(
                    title: 'What The App Does',
                    body:
                        'Book Cart helps users list books for sale, browse available books, manage their own listings, and chat with buyers or sellers.',
                  ),
                  SizedBox(height: 12.h),
                  const PolicyCard(
                    title: 'Core Features',
                    body:
                        'The app includes Firebase login and sign up, home search and category filter, sell form, my books management, chat UI, and account editing.',
                  ),
                  SizedBox(height: 12.h),
                  const PolicyCard(
                    title: 'Design Direction',
                    body:
                        'The interface uses a responsive card-based layout with a consistent teal theme across mobile and wide screens.',
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

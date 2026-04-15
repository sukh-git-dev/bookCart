import 'package:bookcart/core/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, required this.onComplete});

  final Future<void> Function() onComplete;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  late final PageController _pageController;
  int _currentPage = 0;
  bool _isFinishing = false;

  static const _pages = [
    _OnboardingPageData(
      eyebrow: 'Welcome',
      title: 'Discover second-hand books in one clean place.',
      description:
          'Browse curated listings, compare prices, and explore categories built for students and readers.',
      assetPath: 'assets/onboarding/discover_books.svg',
    ),
    _OnboardingPageData(
      eyebrow: 'Search Faster',
      title: 'Filter by category, author, and price in seconds.',
      description:
          'Use search and category filters to narrow the catalog and quickly find the right copy.',
      assetPath: 'assets/onboarding/filter_books.svg',
    ),
    _OnboardingPageData(
      eyebrow: 'Sell Smarter',
      title: 'Create polished listings with image support and pricing help.',
      description:
          'Upload a cover photo, add details, choose multiple categories, and publish your book for sale.',
      assetPath: 'assets/onboarding/sell_books.svg',
    ),
    _OnboardingPageData(
      eyebrow: 'Stay Connected',
      title: 'Chat with buyers and keep every deal in one flow.',
      description:
          'Review offers, respond faster, and keep the conversation organized inside the app.',
      assetPath: 'assets/onboarding/chat_books.svg',
    ),
    _OnboardingPageData(
      eyebrow: 'Manage',
      title: 'Track listings, edit prices, and control your account.',
      description:
          'Manage your book inventory, update details, and personalize the app theme from your profile.',
      assetPath: 'assets/onboarding/profile_books.svg',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    if (_isFinishing) {
      return;
    }

    setState(() {
      _isFinishing = true;
    });

    await widget.onComplete();
  }

  Future<void> _next() async {
    if (_currentPage == _pages.length - 1) {
      await _finish();
      return;
    }

    await _pageController.nextPage(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final page = _pages[_currentPage];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(20.w, 18.h, 20.w, 24.h),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 960),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 14.w,
                          vertical: 9.h,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(18.r),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Text(
                          'BookCart Tour',
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: _isFinishing ? null : _finish,
                        child: const Text('Skip'),
                      ),
                    ],
                  ),
                  SizedBox(height: 18.h),
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(34.r),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 22,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: PageView.builder(
                        controller: _pageController,
                        itemCount: _pages.length,
                        onPageChanged: (value) {
                          setState(() {
                            _currentPage = value;
                          });
                        },
                        itemBuilder: (context, index) {
                          final item = _pages[index];
                          return Padding(
                            padding: EdgeInsets.all(24.w),
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                final isWide = constraints.maxWidth >= 760;
                                return isWide
                                    ? Row(
                                        children: [
                                          Expanded(
                                            child: _OnboardingCopy(page: item),
                                          ),
                                          SizedBox(width: 24.w),
                                          Expanded(
                                            child: _OnboardingArt(
                                              assetPath: item.assetPath,
                                            ),
                                          ),
                                        ],
                                      )
                                    : Column(
                                        children: [
                                          Expanded(
                                            flex: 5,
                                            child: _OnboardingArt(
                                              assetPath: item.assetPath,
                                            ),
                                          ),
                                          SizedBox(height: 20.h),
                                          Expanded(
                                            flex: 4,
                                            child: _OnboardingCopy(page: item),
                                          ),
                                        ],
                                      );
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  SizedBox(height: 18.h),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(18.w),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(26.r),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: List.generate(_pages.length, (index) {
                            final isActive = index == _currentPage;
                            return Expanded(
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 220),
                                margin: EdgeInsets.only(
                                  right: index == _pages.length - 1 ? 0 : 8.w,
                                ),
                                height: 8.h,
                                decoration: BoxDecoration(
                                  color: isActive
                                      ? AppColors.primary
                                      : AppColors.surface,
                                  borderRadius: BorderRadius.circular(10.r),
                                ),
                              ),
                            );
                          }),
                        ),
                        SizedBox(height: 16.h),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                page.eyebrow,
                                style: TextStyle(
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.muted,
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 180.w,
                              child: FilledButton(
                                onPressed: _isFinishing ? null : _next,
                                child: Text(
                                  _currentPage == _pages.length - 1
                                      ? 'Get Started'
                                      : 'Next',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
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

class _OnboardingCopy extends StatelessWidget {
  const _OnboardingCopy({required this.page});

  final _OnboardingPageData page;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(28.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(18.r),
              border: Border.all(color: AppColors.border),
            ),
            child: Text(
              page.eyebrow,
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
              ),
            ),
          ),
          SizedBox(height: 18.h),
          Text(
            page.title,
            style: TextStyle(
              fontSize: 17.sp,
              height: 1.15,
              fontWeight: FontWeight.w800,
              color: AppColors.dark,
            ),
          ),
          SizedBox(height: 14.h),
          Text(
            page.description,
            style: TextStyle(
              fontSize: 14.sp,
              height: 1.55,
              color: AppColors.muted,
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingArt extends StatelessWidget {
  const _OnboardingArt({required this.assetPath});

  final String assetPath;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(22.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.surface, AppColors.background],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30.r),
      ),
      child: SvgPicture.asset(assetPath, fit: BoxFit.contain),
    );
  }
}

class _OnboardingPageData {
  const _OnboardingPageData({
    required this.eyebrow,
    required this.title,
    required this.description,
    required this.assetPath,
  });

  final String eyebrow;
  final String title;
  final String description;
  final String assetPath;
}

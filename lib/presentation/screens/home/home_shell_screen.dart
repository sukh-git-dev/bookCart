import 'package:bookcart/core/constants/app_colors.dart';
import 'package:bookcart/logic/cubits/book_cubit.dart';
import 'package:bookcart/logic/cubits/book_state.dart';
import 'package:bookcart/presentation/bottom_nav_bar.dart';
import 'package:bookcart/presentation/screens/add_book/add_book_screen.dart';
import 'package:bookcart/presentation/screens/cart/cart_screen.dart';
import 'package:bookcart/presentation/screens/chat/chat_screen.dart';
import 'package:bookcart/presentation/screens/home/home_screen.dart';
import 'package:bookcart/presentation/screens/profile/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';

class HomeShellScreen extends StatelessWidget {
  const HomeShellScreen({super.key});

  static const routeName = '/home';

  @override
  Widget build(BuildContext context) {
    const screens = [
      HomeScreen(),
      CartScreen(),
      AddBookScreen(),
      ChatScreen(),
      ProfileScreen(),
    ];

    return BlocBuilder<BookCubit, BookState>(
      builder: (context, state) {
        final width = MediaQuery.sizeOf(context).width;
        final isDesktop = width >= 1100;
        final activeScreen = screens[state.currentTabIndex];

        return Scaffold(
          extendBody: true,
          body: SafeArea(
            child: isDesktop
                ? Row(
                    children: [
                      _DesktopSideRail(
                        currentIndex: state.currentTabIndex,
                        onTap: context.read<BookCubit>().changeTab,
                      ),
                      Expanded(
                        child: Container(
                          color: AppColors.background,
                          child: Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 1440),
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 250),
                                child: KeyedSubtree(
                                  key: ValueKey(state.currentTabIndex),
                                  child: activeScreen,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                : AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: KeyedSubtree(
                      key: ValueKey(state.currentTabIndex),
                      child: activeScreen,
                    ),
                  ),
          ),
          bottomNavigationBar: isDesktop
              ? null
              : BookBottomNavBar(
                  currentIndex: state.currentTabIndex,
                  onTap: context.read<BookCubit>().changeTab,
                ),
        );
      },
    );
  }
}

class _DesktopSideRail extends StatelessWidget {
  const _DesktopSideRail({required this.currentIndex, required this.onTap});

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF221B14), Color(0xFF3A2A20)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.auto_stories_rounded, color: Colors.white),
                SizedBox(width: 10),
                Text(
                  'BookCart',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Responsive seller workspace for mobile and web.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.72),
              fontSize: 14,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 28),
          ...List.generate(BookBottomNavBar.items.length, (index) {
            final item = BookBottomNavBar.items[index];
            final isSelected = index == currentIndex;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () => onTap(index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFFB85C38)
                        : Colors.white.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isSelected
                          ? Colors.transparent
                          : Colors.white.withValues(alpha: 0.06),
                    ),
                  ),
                  child: Row(
                    children: [
                      SvgPicture.asset(
                        item.assetPath,
                        width: 22,
                        height: 22,
                        colorFilter: const ColorFilter.mode(
                          Colors.white,
                          BlendMode.srcIn,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Text(
                        item.label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
          const Spacer(),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Web view ready: wide navigation rail, centered content, and responsive sell-book layout.',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.78),
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

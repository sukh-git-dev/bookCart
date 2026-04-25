import 'package:bookcart/core/constants/app_colors.dart';
import 'package:bookcart/core/constants/book_categories.dart';
import 'package:bookcart/core/utils/app_animation_utils.dart';
import 'package:bookcart/core/utils/location_distance_utils.dart';
import 'package:bookcart/core/utils/location_label_utils.dart';
import 'package:bookcart/data/models/book_model.dart';
import 'package:bookcart/data/models/category_model.dart';
import 'package:bookcart/data/models/user_model.dart';
import 'package:bookcart/logic/cubits/auth_cubit.dart';
import 'package:bookcart/logic/cubits/book_cubit.dart';
import 'package:bookcart/logic/cubits/book_state.dart';
import 'package:bookcart/logic/cubits/chat_cubit.dart';
import 'package:bookcart/presentation/screens/home/book_detail_screen.dart';
import 'package:bookcart/presentation/widgets/app_shimmer.dart';
import 'package:bookcart/presentation/widgets/banner_ad_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../widgets/app_toast.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String searchQuery = '';
  String selectedCategory = 'All';
  late final TextEditingController _searchController;

  final List<CategoryModel> categories = List.generate(
    kBookCategories.length,
    (index) => CategoryModel(id: '${index + 1}', name: kBookCategories[index]),
  );

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = context.select((AuthCubit cubit) => cubit.state.user);

    return BlocBuilder<BookCubit, BookState>(
      builder: (context, state) {
        final filteredBooks = _sortBooksByDistance(
          state.books.where((book) {
            final query = searchQuery.trim().toLowerCase();
            final matchesSearch =
                query.isEmpty ||
                book.title.toLowerCase().contains(query) ||
                book.author.toLowerCase().contains(query) ||
                book.categoryLabel.toLowerCase().contains(query) ||
                book.description.toLowerCase().contains(query);
            final matchesCategory =
                selectedCategory == 'All' ||
                book.belongsToCategory(selectedCategory);
            return matchesSearch && matchesCategory;
          }).toList(),
          currentUser,
        );

        return LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 1000;
            return Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 24.h),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: isWide ? 1260 : 760,
                        ),
                        child: AppStaggeredColumn(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _HomeHeroCard(bookCount: state.books.length),
                            SizedBox(height: 14.h),
                            // _NearbyRadiusCard(
                            //   hasCurrentLocation: hasCurrentLocation,
                            //   nearbyBookCount: nearbyBookCount,
                            // ),
                            SizedBox(height: 22.h),
                            Text(
                              'Book Store',
                              style: TextStyle(
                                fontSize: 28.sp,
                                fontWeight: FontWeight.w800,
                                color: AppColors.dark,
                              ),
                            ),
                            SizedBox(height: 8.h),
                            Text(
                              'Search books quickly and filter by category using the same marketplace style as the sell screen.',
                              style: TextStyle(
                                fontSize: 14.sp,
                                height: 1.45,
                                color: AppColors.muted,
                              ),
                            ),
                            SizedBox(height: 18.h),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _searchController,
                                    onChanged: (value) {
                                      setState(() {
                                        searchQuery = value;
                                      });
                                    },
                                    decoration: InputDecoration(
                                      hintText:
                                          'Search books, author, or category',
                                      prefixIcon: const Icon(
                                        Icons.search_rounded,
                                      ),
                                      suffixIcon: searchQuery.isEmpty
                                          ? null
                                          : IconButton(
                                              onPressed: () {
                                                _searchController.clear();
                                                setState(() {
                                                  searchQuery = '';
                                                });
                                              },
                                              icon: const Icon(
                                                Icons.close_rounded,
                                              ),
                                            ),
                                      filled: true,
                                      fillColor: AppColors.white,
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: 18.w,
                                        vertical: 16.h,
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(
                                          22.r,
                                        ),
                                        borderSide: BorderSide.none,
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(
                                          22.r,
                                        ),
                                        borderSide: BorderSide(
                                          color: AppColors.border,
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(
                                          22.r,
                                        ),
                                        borderSide: BorderSide(
                                          color: AppColors.primary,
                                          width: 1.4,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(width: 12.w),
                                InkWell(
                                  borderRadius: BorderRadius.circular(20.r),
                                  onTap: () => _showFilterBottomSheet(context),
                                  child: Container(
                                    width: 56.w,
                                    height: 56.w,
                                    decoration: BoxDecoration(
                                      color: AppColors.white,
                                      borderRadius: BorderRadius.circular(20.r),
                                      border: Border.all(
                                        color: AppColors.border,
                                      ),
                                    ),
                                    child: Center(
                                      child: SvgPicture.asset(
                                        'assets/actions/filter.svg',
                                        width: 22.sp,
                                        height: 22.sp,
                                        colorFilter: ColorFilter.mode(
                                          AppColors.primary,
                                          BlendMode.srcIn,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 16.h),
                            Container(
                              width: double.infinity,
                              padding: EdgeInsets.symmetric(
                                horizontal: 16.w,
                                vertical: 12.h,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.white,
                                borderRadius: BorderRadius.circular(20.r),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.tune_rounded,
                                    size: 18.sp,
                                    color: AppColors.primary,
                                  ),
                                  SizedBox(width: 10.w),
                                  Expanded(
                                    child: Text(
                                      'Selected filter: $selectedCategory',
                                      style: TextStyle(
                                        fontSize: 13.sp,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.dark,
                                      ),
                                    ),
                                  ),
                                  if (selectedCategory != 'All')
                                    TextButton(
                                      onPressed: () {
                                        setState(() {
                                          selectedCategory = 'All';
                                        });
                                      },
                                      child: const Text('Clear'),
                                    ),
                                ],
                              ),
                            ),
                            SizedBox(height: 22.h),
                            if (state.isLoadingBooks)
                              const _HomeLoadingSection()
                            else if (filteredBooks.isEmpty)
                              Container(
                                width: double.infinity,
                                padding: EdgeInsets.all(28.w),
                                decoration: BoxDecoration(
                                  color: AppColors.white,
                                  borderRadius: BorderRadius.circular(28.r),
                                ),
                                child: Text(
                                  'No books found for the selected search and filter.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.muted,
                                  ),
                                ),
                              )
                            else
                              _HomeBookSection(
                                books: filteredBooks,
                                isWide: isWide,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showFilterBottomSheet(BuildContext context) async {
    String tempSelectedCategory = selectedCategory;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final filterItems = [
              const CategoryModel(id: '0', name: 'All'),
              ...categories,
            ];

            return FractionallySizedBox(
              heightFactor: 0.82,
              child: Container(
                padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 20.h),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(30.r),
                  ),
                ),
                child: SafeArea(
                  top: false,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 44.w,
                          height: 4.h,
                          decoration: BoxDecoration(
                            color: AppColors.border,
                            borderRadius: BorderRadius.circular(4.r),
                          ),
                        ),
                      ),
                      SizedBox(height: 18.h),
                      Text(
                        'All Filters',
                        style: TextStyle(
                          fontSize: 22.sp,
                          fontWeight: FontWeight.w800,
                          color: AppColors.dark,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        'Choose a category to filter the home screen book list.',
                        style: TextStyle(
                          fontSize: 13.sp,
                          height: 1.45,
                          color: AppColors.muted,
                        ),
                      ),
                      SizedBox(height: 18.h),
                      Expanded(
                        child: ListView.builder(
                          itemCount: filterItems.length,
                          itemBuilder: (context, index) {
                            final category = filterItems[index];
                            return InkWell(
                              borderRadius: BorderRadius.circular(18.r),
                              onTap: () {
                                setModalState(() {
                                  tempSelectedCategory = category.name;
                                });
                              },
                              child: Container(
                                margin: EdgeInsets.only(bottom: 15.h),
                                padding: EdgeInsets.symmetric(
                                  horizontal: 14.w,
                                  vertical: 14.h,
                                ),
                                decoration: BoxDecoration(
                                  color: tempSelectedCategory == category.name
                                      ? AppColors.surface
                                      : AppColors.white,
                                  borderRadius: BorderRadius.circular(18.r),
                                  border: Border.all(
                                    color: tempSelectedCategory == category.name
                                        ? AppColors.primary
                                        : AppColors.border,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        category.name,
                                        style: TextStyle(
                                          fontSize: 14.sp,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.dark,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      width: 22.w,
                                      height: 22.w,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color:
                                              tempSelectedCategory ==
                                                  category.name
                                              ? AppColors.primary
                                              : AppColors.border,
                                          width: 2,
                                        ),
                                        color:
                                            tempSelectedCategory ==
                                                category.name
                                            ? AppColors.primary
                                            : Colors.transparent,
                                      ),
                                      child:
                                          tempSelectedCategory == category.name
                                          ? Icon(
                                              Icons.check_rounded,
                                              size: 14.sp,
                                              color: Colors.white,
                                            )
                                          : null,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      SizedBox(height: 12.h),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: () {
                            setState(() {
                              selectedCategory = tempSelectedCategory;
                            });
                            Navigator.of(context).pop();
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            minimumSize: Size(double.infinity, 50.h),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20.r),
                            ),
                          ),
                          child: Text(
                            'Apply',
                            style: TextStyle(
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
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

  List<BookModel> _sortBooksByDistance(
    List<BookModel> books,
    UserModel? currentUser,
  ) {
    final sortedBooks = List<BookModel>.from(books);
    if (currentUser?.latitude == null || currentUser?.longitude == null) {
      return sortedBooks;
    }

    sortedBooks.sort((firstBook, secondBook) {
      final firstDistance = _distanceFromCurrentUser(firstBook, currentUser);
      final secondDistance = _distanceFromCurrentUser(secondBook, currentUser);
      final firstIsNearby = isWithinNearbyRadius(firstDistance);
      final secondIsNearby = isWithinNearbyRadius(secondDistance);

      if (firstIsNearby != secondIsNearby) {
        return firstIsNearby ? -1 : 1;
      }

      if (firstDistance != null && secondDistance != null) {
        return firstDistance.compareTo(secondDistance);
      }

      if (firstDistance != null) {
        return -1;
      }

      if (secondDistance != null) {
        return 1;
      }

      return 0;
    });

    return sortedBooks;
  }

  double? _distanceFromCurrentUser(BookModel book, UserModel? currentUser) {
    return calculateDistanceKm(
      fromLatitude: currentUser?.latitude,
      fromLongitude: currentUser?.longitude,
      toLatitude: book.sellerLatitude,
      toLongitude: book.sellerLongitude,
    );
  }
}

class _HomeBookSection extends StatelessWidget {
  const _HomeBookSection({required this.books, required this.isWide});

  final List<BookModel> books;
  final bool isWide;

  @override
  Widget build(BuildContext context) {
    if (!isWide) {
      final adIndex = books.length >= 2 ? 2 : books.length;
      return Column(
        children: [
          for (int index = 0; index < books.length; index++) ...[
            if (index == adIndex) const _InlineBannerAdCard(),
            Padding(
              padding: EdgeInsets.only(bottom: 14.h),
              child: _BookCard(book: books[index]),
            ).animateListItem(order: index),
          ],
          if (adIndex == books.length) const _InlineBannerAdCard(),
        ],
      );
    }

    final splitIndex = books.length >= 2 ? 2 : books.length;
    final firstBooks = books.take(splitIndex).toList();
    final remainingBooks = books.skip(splitIndex).toList();

    return Column(
      children: [
        if (firstBooks.isNotEmpty) _WideBookGrid(books: firstBooks),
        const _InlineBannerAdCard(),
        if (remainingBooks.isNotEmpty) ...[
          SizedBox(height: 20.h),
          _WideBookGrid(books: remainingBooks),
        ],
      ],
    );
  }
}

class _WideBookGrid extends StatelessWidget {
  const _WideBookGrid({required this.books});

  final List<BookModel> books;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: books.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 20,
        mainAxisSpacing: 20,
        childAspectRatio: 1.65,
      ),
      itemBuilder: (_, index) =>
          _BookCard(book: books[index]).animateListItem(order: index),
    );
  }
}

class _HomeLoadingSection extends StatelessWidget {
  const _HomeLoadingSection();

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: Column(
        children: List.generate(
          3,
          (index) => Padding(
            padding: EdgeInsets.only(bottom: 18.h),
            child: AppShimmerBox(height: 210.h, radius: 24.r),
          ),
        ),
      ),
    );
  }
}

class _InlineBannerAdCard extends StatelessWidget {
  const _InlineBannerAdCard();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 18.h),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(24.r),
          border: Border.all(color: AppColors.border.withValues(alpha: 0.8)),
        ),
        child: const Center(child: BannerAdWidget()),
      ),
    );
  }
}

class _HomeHeroCard extends StatelessWidget {
  const _HomeHeroCard({required this.bookCount});

  final int bookCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.dark, AppColors.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30.r),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 6.h,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Text(
                    'Marketplace',
                    style: TextStyle(
                      color: AppColors.white,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                SizedBox(height: 14.h),
                Text(
                  'Find books by category and discover ready-to-buy listings.',
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: 24.sp,
                    height: 1.2,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 10.h),
                Text(
                  '$bookCount books available across school, college, and other categories.',
                  style: TextStyle(
                    color: AppColors.white.withValues(alpha: 0.82),
                    fontSize: 13.sp,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 12.w),
          Container(
            width: 86.w,
            height: 110.h,
            decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(24.r),
              border: Border.all(color: AppColors.white.withValues(alpha: 0.2)),
            ),
            child: Icon(
              Icons.menu_book_rounded,
              color: AppColors.white,
              size: 40.sp,
            ),
          ),
        ],
      ),
    );
  }
}

class _BookCard extends StatelessWidget {
  const _BookCard({required this.book});

  final BookModel book;

  void _openDetail(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => BookDetailScreen(book: book)));
  }

  Future<void> _openChat(BuildContext context) async {
    final user = context.read<AuthCubit>().state.user;
    if (user == null) {
      AppToast.show(
        context,
        message: 'Please log in again before opening chat.',
        type: AppToastType.error,
      );
      return;
    }

    await context.read<ChatCubit>().startChatForBook(book: book, buyer: user);
    if (!context.mounted) {
      return;
    }

    final chatState = context.read<ChatCubit>().state;
    if (chatState.errorMessage != null) {
      AppToast.show(
        context,
        message: chatState.errorMessage!,
        type: AppToastType.error,
      );
      context.read<ChatCubit>().clearFeedback();
      return;
    }

    context.read<BookCubit>().changeTab(3);
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = context.select((AuthCubit cubit) => cubit.state.user);
    final coverImageBytes = book.resolvedImageBytes;
    final primaryImageUrl = book.primaryImageUrl;
    final sellerLocationLabel = visibleLocationLabel(
      book.sellerLocation,
      fallback: kLocationUnavailableLabel,
    );
    final distanceLabel = formatDistanceKm(
      calculateDistanceKm(
        fromLatitude: currentUser?.latitude,
        fromLongitude: currentUser?.longitude,
        toLatitude: book.sellerLatitude,
        toLongitude: book.sellerLongitude,
      ),
    );
    final locationBadgeLabel = distanceLabel == 'Location'
        ? compactLocationLabel(sellerLocationLabel)
        : distanceLabel;

    return InkWell(
      borderRadius: BorderRadius.circular(24.r),
      onTap: () => _openDetail(context),
      child: Container(
        padding: EdgeInsets.all(18.w),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(24.r),
          border: Border.all(color: AppColors.border.withValues(alpha: 0.8)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.dark, AppColors.primary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(30.r),
              ),
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    height: 200.h,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(22.r),
                    ),
                    child: coverImageBytes != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(22.r),
                            child: Image.memory(
                              coverImageBytes,
                              fit: BoxFit.cover,
                            ),
                          )
                        : primaryImageUrl != null && primaryImageUrl.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(22.r),
                            child: Image.network(
                              primaryImageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Icon(
                                    Icons.auto_stories_rounded,
                                    size: 42.sp,
                                    color: Colors.white,
                                  ),
                            ),
                          )
                        : Icon(
                            Icons.auto_stories_rounded,
                            size: 42.sp,
                            color: Colors.white,
                          ),
                  ),
                  if (book.imageCount > 1)
                    Positioned(
                      right: 14.w,
                      top: 14.h,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12.w,
                          vertical: 8.h,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.dark.withValues(alpha: 0.78),
                          borderRadius: BorderRadius.circular(18.r),
                        ),
                        child: Text(
                          '${book.imageCount} photos',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            SizedBox(height: 14.w),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        book.title,
                        style: TextStyle(
                          fontSize: 17.sp,
                          fontWeight: FontWeight.w800,
                          color: AppColors.dark,
                        ),
                      ),
                    ),
                    SizedBox(width: 10.w),
                    _MetaBadge(
                      icon: Icons.location_on_rounded,
                      label: locationBadgeLabel,
                    ),
                  ],
                ),
                SizedBox(height: 8.h),
                Wrap(
                  spacing: 8.w,
                  runSpacing: 8.h,
                  children: [
                    _MetaBadge(
                      icon: Icons.category_rounded,
                      label: book.primaryCategory,
                    ),
                    if (book.additionalCategoryCount > 0)
                      _MetaBadge(
                        icon: Icons.layers_rounded,
                        label: '+${book.additionalCategoryCount} more',
                      ),
                    _MetaBadge(icon: Icons.person_rounded, label: book.author),
                  ],
                ),
                SizedBox(height: 10.h),
                Text(
                  book.description.isEmpty ? 'Good Book' : book.description,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13.sp,
                    height: 1.45,
                    color: AppColors.dark,
                  ),
                ),
                SizedBox(height: 10.h),
                // Row(
                //   crossAxisAlignment: CrossAxisAlignment.start,
                //   children: [
                //     Padding(
                //       padding: EdgeInsets.only(top: 2.h),
                //       child: Icon(
                //         Icons.location_on_outlined,
                //         size: 16.sp,
                //         color: AppColors.primary,
                //       ),
                //     ),
                //     SizedBox(width: 6.w),
                //     Expanded(
                //       child: Text(
                //         sellerLocationLabel,
                //         maxLines: 2,
                //         overflow: TextOverflow.ellipsis,
                //         style: TextStyle(
                //           fontSize: 12.sp,
                //           height: 1.4,
                //           color: AppColors.muted,
                //           fontWeight: FontWeight.w600,
                //         ),
                //       ),
                //     ),
                //   ],
                // ),
                // SizedBox(height: 14.h),
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12.w,
                        vertical: 10.h,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16.r),
                      ),
                      child: Text(
                        '₹${book.price}',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(16.r),
                      ),
                      child: IconButton(
                        onPressed: () => _openChat(context),
                        tooltip: 'Chat',
                        icon: Icon(
                          Icons.chat_bubble_outline_rounded,
                          color: AppColors.primary,
                          size: 20.sp,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MetaBadge extends StatelessWidget {
  const _MetaBadge({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 7.h),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14.sp, color: AppColors.primary),
          SizedBox(width: 6.w),
          Text(
            label,
            style: TextStyle(
              fontSize: 11.sp,
              fontWeight: FontWeight.w700,
              color: AppColors.dark,
            ),
          ),
        ],
      ),
    );
  }
}

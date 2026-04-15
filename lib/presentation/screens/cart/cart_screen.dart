import 'package:bookcart/core/constants/app_colors.dart';
import 'package:bookcart/data/models/book_model.dart';
import 'package:bookcart/logic/cubits/book_cubit.dart';
import 'package:bookcart/logic/cubits/book_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  String searchQuery = '';
  late final TextEditingController _searchController;

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
    return BlocBuilder<BookCubit, BookState>(
      builder: (context, state) {
        final filteredBooks = state.books.where((book) {
          final query = searchQuery.trim().toLowerCase();
          return query.isEmpty ||
              book.title.toLowerCase().contains(query) ||
              book.author.toLowerCase().contains(query) ||
              book.categoryLabel.toLowerCase().contains(query) ||
              book.description.toLowerCase().contains(query);
        }).toList();

        return LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 1000;
            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 130.h),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: isWide ? 1260 : 760),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _MyBooksHero(bookCount: state.books.length),
                      SizedBox(height: 22.h),
                      TextField(
                        controller: _searchController,
                        onChanged: (value) {
                          setState(() {
                            searchQuery = value;
                          });
                        },
                        decoration: InputDecoration(
                          hintText: 'Search my books, author, or category',
                          prefixIcon: const Icon(Icons.search_rounded),
                          suffixIcon: searchQuery.isEmpty
                              ? null
                              : IconButton(
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() {
                                      searchQuery = '';
                                    });
                                  },
                                  icon: const Icon(Icons.close_rounded),
                                ),
                          filled: true,
                          fillColor: AppColors.white,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 18.w,
                            vertical: 16.h,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(22.r),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(22.r),
                            borderSide: BorderSide(color: AppColors.border),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(22.r),
                            borderSide: BorderSide(
                              color: AppColors.primary,
                              width: 1.4,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 22.h),
                      if (filteredBooks.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(28.w),
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            borderRadius: BorderRadius.circular(28.r),
                          ),
                          child: Text(
                            searchQuery.trim().isEmpty
                                ? 'No books added yet.'
                                : 'No books found for this search.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w700,
                              color: AppColors.muted,
                            ),
                          ),
                        )
                      else if (isWide)
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: filteredBooks.length,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 20,
                                mainAxisSpacing: 20,
                                childAspectRatio: 1.65,
                              ),
                          itemBuilder: (_, index) =>
                              _MyBookCard(book: filteredBooks[index]),
                        )
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: filteredBooks.length,
                          itemBuilder: (_, index) => Padding(
                            padding: EdgeInsets.only(bottom: 14.h),
                            child: _MyBookCard(book: filteredBooks[index]),
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
}

class _MyBooksHero extends StatelessWidget {
  const _MyBooksHero({required this.bookCount});

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
                    'My Inventory',
                    style: TextStyle(
                      color: AppColors.white,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                SizedBox(height: 14.h),
                Text(
                  'Manage your listed books, drafts, and active sale items.',
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: 24.sp,
                    height: 1.2,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 10.h),
                Text(
                  '$bookCount books available in your collection.',
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
              Icons.library_books_rounded,
              color: AppColors.white,
              size: 40.sp,
            ),
          ),
        ],
      ),
    );
  }
}

class _MyBookCard extends StatelessWidget {
  const _MyBookCard({required this.book});

  final BookModel book;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(18.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 68.w,
            height: 90.h,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(18.r),
            ),
            child: Icon(
              Icons.menu_book_rounded,
              size: 32.sp,
              color: AppColors.primary,
            ),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  book.title,
                  style: TextStyle(
                    fontSize: 17.sp,
                    fontWeight: FontWeight.w800,
                    color: AppColors.dark,
                  ),
                ),
                SizedBox(height: 6.h),
                Text(
                  'Author: ${book.author}',
                  style: TextStyle(fontSize: 13.sp, color: AppColors.muted),
                ),
                SizedBox(height: 4.h),
                Text(
                  'Categories: ${book.categoryLabel}',
                  style: TextStyle(fontSize: 13.sp, color: AppColors.muted),
                ),
                SizedBox(height: 8.h),
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
                Text(
                  '₹${book.price}',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
                SizedBox(height: 12.h),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          _showBookActionDialog(
                            context,
                            title: 'Edit Book',
                            message:
                                'Edit option for "${book.title}" can be connected here.',
                          );
                        },
                        icon: const Icon(Icons.edit_rounded),
                        label: const Text('Edit'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.dark,
                          minimumSize: Size(double.infinity, 50.h),
                          side: BorderSide(color: AppColors.border),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16.r),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () {
                          _showBookActionDialog(
                            context,
                            title: 'Delete Book',
                            message:
                                'Delete option for "${book.title}" can be connected here.',
                          );
                        },
                        icon: SvgPicture.asset(
                          'assets/actions/delete.svg',
                          width: 18.sp,
                          height: 18.sp,
                          colorFilter: const ColorFilter.mode(
                            Colors.white,
                            BlendMode.srcIn,
                          ),
                        ),
                        label: const Text('Delete'),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFFB8403F),
                          foregroundColor: Colors.white,
                          minimumSize: Size(double.infinity, 50.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16.r),
                          ),
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
    );
  }
}

void _showBookActionDialog(
  BuildContext context, {
  required String title,
  required String message,
}) {
  showDialog<void>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      );
    },
  );
}

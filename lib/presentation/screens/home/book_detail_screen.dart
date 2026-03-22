import 'package:bookcart/core/constants/app_colors.dart';
import 'package:bookcart/data/models/book_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class BookDetailScreen extends StatelessWidget {
  const BookDetailScreen({super.key, required this.book});

  final BookModel book;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Book Details'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20.w),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(22.w),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.dark, AppColors.primary],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(30.r),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 94.w,
                        height: 124.h,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(22.r),
                        ),
                        child: book.imageBytes != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(22.r),
                                child: Image.memory(
                                  book.imageBytes!,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : Icon(
                                Icons.auto_stories_rounded,
                                size: 42.sp,
                                color: Colors.white,
                              ),
                      ),
                      SizedBox(width: 16.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              book.title,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 23.sp,
                                fontWeight: FontWeight.w800,
                                height: 1.2,
                              ),
                            ),
                            SizedBox(height: 10.h),
                            Text(
                              'by ${book.author}',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.84),
                                fontSize: 14.sp,
                              ),
                            ),
                            SizedBox(height: 12.h),
                            Wrap(
                              spacing: 8.w,
                              runSpacing: 8.h,
                              children: [
                                _DetailChip(
                                  icon: Icons.category_rounded,
                                  label: book.category,
                                ),
                                const _DetailChip(
                                  icon: Icons.location_on_rounded,
                                  label: '12 km away',
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 18.h),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(20.w),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(26.r),
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
                      Text(
                        'Price',
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w700,
                          color: AppColors.muted,
                        ),
                      ),
                      SizedBox(height: 6.h),
                      Text(
                        '₹${book.price}',
                        style: TextStyle(
                          fontSize: 24.sp,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                      SizedBox(height: 18.h),
                      Text(
                        'Description',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w800,
                          color: AppColors.dark,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        book.description.isEmpty
                            ? 'This book is available in good condition.'
                            : book.description,
                        style: TextStyle(
                          fontSize: 14.sp,
                          height: 1.55,
                          color: AppColors.muted,
                        ),
                      ),
                      SizedBox(height: 20.h),
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(16.w),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(22.r),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Seller Info',
                              style: TextStyle(
                                fontSize: 15.sp,
                                fontWeight: FontWeight.w800,
                                color: AppColors.dark,
                              ),
                            ),
                            SizedBox(height: 10.h),
                            _DetailInfoRow(
                              icon: Icons.person_rounded,
                              label: 'Author',
                              value: book.author,
                            ),
                            SizedBox(height: 10.h),
                            _DetailInfoRow(
                              icon: Icons.menu_book_rounded,
                              label: 'Category',
                              value: book.category,
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 22.h),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.chat_bubble_rounded),
                          label: const Text('Chat Now'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DetailChip extends StatelessWidget {
  const _DetailChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15.sp, color: Colors.white),
          SizedBox(width: 6.w),
          Text(
            label,
            style: TextStyle(
              color: Colors.white,
              fontSize: 12.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailInfoRow extends StatelessWidget {
  const _DetailInfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 38.w,
          height: 38.w,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Icon(icon, size: 18.sp, color: AppColors.primary),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColors.muted,
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColors.dark,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

import 'package:bookcart/core/constants/app_colors.dart';
import 'package:bookcart/core/utils/app_animation_utils.dart';
import 'package:bookcart/core/utils/location_distance_utils.dart';
import 'package:bookcart/core/utils/location_label_utils.dart';
import 'package:bookcart/data/models/book_model.dart';
import 'package:bookcart/logic/cubits/auth_cubit.dart';
import 'package:bookcart/logic/cubits/book_cubit.dart';
import 'package:bookcart/logic/cubits/chat_cubit.dart';
import 'package:bookcart/presentation/widgets/app_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher.dart';

class BookDetailScreen extends StatelessWidget {
  const BookDetailScreen({super.key, required this.book});

  final BookModel book;

  @override
  Widget build(BuildContext context) {
    final currentUser = context.select((AuthCubit cubit) => cubit.state.user);
    final galleryImages = book.galleryImages;
    final sellerDistanceKm = calculateDistanceKm(
      fromLatitude: currentUser?.latitude,
      fromLongitude: currentUser?.longitude,
      toLatitude: book.sellerLatitude,
      toLongitude: book.sellerLongitude,
    );
    final sellerLocationLabel = visibleLocationLabel(
      book.sellerLocation,
      fallback: kLocationUnavailableLabel,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Book Details'), centerTitle: true),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20.w),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: AppStaggeredColumn(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(22.w),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.dark, AppColors.primary],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(30.r),
                  ),
                  child: Container(
                    width: double.infinity,
                    height: 200.h,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(22.r),
                    ),
                    child: _BookGalleryCarousel(images: galleryImages),
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
                              label: 'Seller',
                              value: book.sellerName.trim().isEmpty
                                  ? 'BookCart Seller'
                                  : book.sellerName,
                            ),
                            if (book.sellerPhone.trim().isNotEmpty) ...[
                              SizedBox(height: 10.h),
                              _DetailInfoRow(
                                icon: Icons.call_rounded,
                                label: 'Mobile number',
                                value: book.sellerPhone,
                                onTap: () => _callSeller(context),
                              ),
                            ],
                            SizedBox(height: 10.h),
                            _DetailInfoRow(
                              icon: Icons.menu_book_rounded,
                              label: book.categories.length > 1
                                  ? 'Categories'
                                  : 'Category',
                              value: book.categoryLabel,
                            ),
                            SizedBox(height: 10.h),
                            _DetailInfoRow(
                              icon: Icons.location_on_rounded,
                              label: 'Seller location',
                              value: sellerLocationLabel,
                            ),
                            if (sellerDistanceKm != null) ...[
                              SizedBox(height: 10.h),
                              _DetailInfoRow(
                                icon: Icons.social_distance_rounded,
                                label: 'Distance from you',
                                value: isWithinNearbyRadius(sellerDistanceKm)
                                    ? '${formatDistanceKm(sellerDistanceKm)} from you (within 15 KM)'
                                    : '${formatDistanceKm(sellerDistanceKm)} from you',
                              ),
                            ],
                          ],
                        ),
                      ),
                      SizedBox(height: 22.h),
                      Row(
                        children: [
                          if (book.sellerPhone.trim().isNotEmpty) ...[
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _callSeller(context),
                                icon: const Icon(Icons.call_rounded),
                                label: const Text('Call Seller'),
                              ),
                            ),
                            SizedBox(width: 12.w),
                          ],
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: () => _openChat(context),
                              icon: const Icon(Icons.chat_bubble_rounded),
                              label: const Text('Chat Now'),
                            ),
                          ),
                        ],
                      ),
                      if (book.sellerPhone.trim().isNotEmpty) ...[
                        SizedBox(height: 10.h),
                        Text(
                          'Tap the phone number or Call Seller to open your dialer.',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: AppColors.muted,
                            height: 1.45,
                          ),
                        ),
                      ],
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

  Future<void> _callSeller(BuildContext context) async {
    final rawPhone = book.sellerPhone.trim();
    if (rawPhone.isEmpty) {
      AppToast.show(
        context,
        message: 'Seller phone number is not available.',
        type: AppToastType.error,
      );
      return;
    }

    final launchUri = Uri(
      scheme: 'tel',
      path: rawPhone.replaceAll(RegExp(r'[^\d+]'), ''),
    );

    bool opened;
    try {
      opened = await launchUrl(launchUri);
    } on PlatformException {
      opened = false;
    } on MissingPluginException {
      opened = false;
    }

    if (!opened && context.mounted) {
      AppToast.show(
        context,
        message:
            'Could not open the dialer. Fully restart the app and try again.',
        type: AppToastType.error,
      );
    }
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

    final bookCubit = context.read<BookCubit>();
    final navigator = Navigator.of(context);

    bookCubit.changeTab(3);
    if (navigator.canPop()) {
      navigator.pop();
    }
  }
}

class _BookGalleryCarousel extends StatefulWidget {
  const _BookGalleryCarousel({required this.images});

  final List<BookImageModel> images;

  @override
  State<_BookGalleryCarousel> createState() => _BookGalleryCarouselState();
}

class _BookGalleryCarouselState extends State<_BookGalleryCarousel> {
  late final PageController _pageController;
  int _currentIndex = 0;

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

  @override
  Widget build(BuildContext context) {
    if (widget.images.isEmpty) {
      return Icon(Icons.auto_stories_rounded, size: 42.sp, color: Colors.white);
    }

    return Stack(
      children: [
        Positioned.fill(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22.r),
            child: PageView.builder(
              controller: _pageController,
              itemCount: widget.images.length,
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              itemBuilder: (context, index) {
                final image = widget.images[index];
                final imageBytes = image.resolvedBytes;
                final imageUrl = image.resolvedUrl;

                if (imageBytes != null) {
                  return Image.memory(imageBytes, fit: BoxFit.cover);
                }

                if (imageUrl != null && imageUrl.isNotEmpty) {
                  return Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Icon(
                      Icons.auto_stories_rounded,
                      size: 42.sp,
                      color: Colors.white,
                    ),
                  );
                }

                return Icon(
                  Icons.auto_stories_rounded,
                  size: 42.sp,
                  color: Colors.white,
                );
              },
            ),
          ),
        ),
        if (widget.images.length > 1)
          Positioned(
            right: 14.w,
            top: 14.h,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: AppColors.dark.withValues(alpha: 0.78),
                borderRadius: BorderRadius.circular(18.r),
              ),
              child: Text(
                '${_currentIndex + 1}/${widget.images.length}',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        if (widget.images.length > 1)
          Positioned(
            left: 0,
            right: 0,
            bottom: 14.h,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var index = 0; index < widget.images.length; index++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: index == _currentIndex ? 16.w : 8.w,
                    height: 8.w,
                    margin: EdgeInsets.symmetric(horizontal: 3.w),
                    decoration: BoxDecoration(
                      color: index == _currentIndex
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(999.r),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class _DetailInfoRow extends StatelessWidget {
  const _DetailInfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16.r),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: onTap == null ? 0 : 6.w,
          vertical: onTap == null ? 0 : 6.h,
        ),
        child: Row(
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
            if (onTap != null)
              Icon(
                Icons.arrow_outward_rounded,
                size: 18.sp,
                color: AppColors.primary,
              ),
          ],
        ),
      ),
    );
  }
}

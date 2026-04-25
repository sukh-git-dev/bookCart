import 'dart:typed_data';

import 'package:bookcart/core/constants/app_colors.dart';
import 'package:bookcart/core/constants/app_strings.dart';
import 'package:bookcart/core/constants/book_categories.dart';
import 'package:bookcart/core/utils/app_animation_utils.dart';
import 'package:bookcart/data/models/book_model.dart';
import 'package:bookcart/logic/cubits/book_cubit.dart';
import 'package:bookcart/logic/cubits/book_state.dart';
import 'package:bookcart/presentation/widgets/app_loading_indicator.dart';
import 'package:bookcart/presentation/widgets/app_shimmer.dart';
import 'package:bookcart/presentation/widgets/app_toast.dart';
import 'package:bookcart/presentation/widgets/app_text_field.dart';
import 'package:bookcart/presentation/widgets/section_title.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AddBookScreen extends StatefulWidget {
  const AddBookScreen({super.key});

  @override
  State<AddBookScreen> createState() => _AddBookScreenState();
}

class _AddBookScreenState extends State<AddBookScreen> {
  late final TextEditingController _titleController;
  late final TextEditingController _authorController;
  late final TextEditingController _priceController;
  late final TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();
    final draft = context.read<BookCubit>().state.draft;
    _titleController = TextEditingController(text: draft.title);
    _authorController = TextEditingController(text: draft.author);
    _priceController = TextEditingController(text: draft.price);
    _descriptionController = TextEditingController(text: draft.description);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _authorController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _syncControllers(BookState state) {
    _setControllerValue(_titleController, state.draft.title);
    _setControllerValue(_authorController, state.draft.author);
    _setControllerValue(_priceController, state.draft.price);
    _setControllerValue(_descriptionController, state.draft.description);
  }

  void _setControllerValue(TextEditingController controller, String value) {
    if (controller.text == value) {
      return;
    }
    controller.value = controller.value.copyWith(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
  }

  void _showFeedback(BuildContext context, String message) {
    final lowerMessage = message.toLowerCase();
    final isSuccess =
        lowerMessage.contains('published') ||
        lowerMessage.contains('success') ||
        lowerMessage.contains('ready');

    AppToast.show(
      context,
      message: message,
      type: isSuccess ? AppToastType.success : AppToastType.error,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<BookCubit, BookState>(
      listener: (context, state) {
        _syncControllers(state);
        if (state.message != null && state.message!.isNotEmpty) {
          _showFeedback(context, state.message!);
          context.read<BookCubit>().clearMessage();
        }
      },
      builder: (context, state) {
        final cubit = context.read<BookCubit>();
        if (state.isLoadingBooks) {
          return const _AddBookLoadingView();
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 1000;
            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 130.h),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: isWide ? 1260 : 760),
                  child: isWide
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 5,
                              child: _AddBookLeadColumn(
                                state: state,
                                onImageTap: cubit.pickImage,
                                onRemoveImage: cubit.removeImageAt,
                                onStartCreate: cubit.startCreateListing,
                                onViewAll: cubit.viewAllListings,
                              ).animatePage(),
                            ),
                            SizedBox(width: 24.w),
                            Expanded(
                              flex: 6,
                              child:
                                  _AddBookFormCard(
                                    state: state,
                                    cubit: cubit,
                                    titleController: _titleController,
                                    authorController: _authorController,
                                    priceController: _priceController,
                                    descriptionController:
                                        _descriptionController,
                                  ).animatePage(
                                    delay: const Duration(milliseconds: 120),
                                  ),
                            ),
                          ],
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _AddBookLeadColumn(
                              state: state,
                              onImageTap: cubit.pickImage,
                              onRemoveImage: cubit.removeImageAt,
                              onStartCreate: cubit.startCreateListing,
                              onViewAll: cubit.viewAllListings,
                            ).animatePage(),
                            SizedBox(height: 22.h),
                            _AddBookFormCard(
                              state: state,
                              cubit: cubit,
                              titleController: _titleController,
                              authorController: _authorController,
                              priceController: _priceController,
                              descriptionController: _descriptionController,
                            ).animatePage(
                              delay: const Duration(milliseconds: 120),
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

class _AddBookLeadColumn extends StatelessWidget {
  const _AddBookLeadColumn({
    required this.state,
    required this.onImageTap,
    required this.onRemoveImage,
    required this.onStartCreate,
    required this.onViewAll,
  });

  final BookState state;
  final VoidCallback onImageTap;
  final ValueChanged<int> onRemoveImage;
  final VoidCallback onStartCreate;
  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context) {
    return AppStaggeredColumn(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _HeroSellCard(state: state),
        SizedBox(height: 22.h),
        // Container(
        //   width: double.infinity,
        //   padding: EdgeInsets.all(18.w),
        //   decoration: BoxDecoration(
        //     color: AppColors.white,
        //     borderRadius: BorderRadius.circular(24.r),
        //     border: Border.all(color: AppColors.border),
        //   ),
        //   child: Row(
        //     children: [
        //       Expanded(
        //         child: _LeadStat(
        //           label: 'Status',
        //           value: state.isEditing
        //               ? 'Editing'
        //               : state.draft.imagePath == null
        //               ? 'Draft'
        //               : 'Ready',
        //         ),
        //       ),
        //       Container(width: 1, height: 38.h, color: AppColors.border),
        //       Expanded(
        //         child: _LeadStat(
        //           label: 'Image',
        //           value: state.isProcessingImage
        //               ? 'Compressing'
        //               : state.draft.imagePath == null
        //               ? 'Pending'
        //               : 'Added',
        //         ),
        //       ),
        //       Container(width: 1, height: 38.h, color: AppColors.border),
        //       Expanded(
        //         child: _LeadStat(
        //           label: 'Listings',
        //           value: '${state.books.length}',
        //         ),
        //       ),
        //     ],
        //   ),
        // ),
        // SizedBox(height: 20.h),
        Text(
          AppStrings.sellTitle,
          style: TextStyle(
            fontSize: 28.sp,
            fontWeight: FontWeight.w800,
            color: AppColors.dark,
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          AppStrings.sellSubtitle,
          style: TextStyle(
            fontSize: 14.sp,
            height: 1.45,
            color: AppColors.muted,
          ),
        ),
        SizedBox(height: 22.h),
        _ImagePickerCard(state: state, onAddImages: onImageTap),
        if (state.draft.hasImages) ...[
          SizedBox(height: 12.h),
          _SelectedImageStrip(
            images: state.draft.galleryImages,
            onRemoveImage: onRemoveImage,
          ),
        ],
        SizedBox(height: 18.h),
        // Row(
        //   children: [
        //     Expanded(
        //       child: InfoChip(
        //         icon: Icons.add_photo_alternate_rounded,
        //         label: state.draft.imagePath == null
        //             ? 'Select image to start listing'
        //             : 'Book image selected',
        //       ),
        //     ),
        //     SizedBox(width: 12.w),
        //     const Expanded(
        //       child: InfoChip(
        //         icon: Icons.verified_rounded,
        //         label: 'Onboarding + sell flow ready',
        //       ),
        //     ),
        //   ],
        // ),
        // SizedBox(height: 18.h),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onViewAll,
                icon: const Icon(Icons.library_books_rounded),
                label: const Text('View All'),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onStartCreate,
                icon: Icon(
                  state.isEditing
                      ? Icons.add_box_rounded
                      : Icons.refresh_rounded,
                ),
                label: Text(state.isEditing ? 'New Listing' : 'Reset Form'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _AddBookFormCard extends StatelessWidget {
  const _AddBookFormCard({
    required this.state,
    required this.cubit,
    required this.titleController,
    required this.authorController,
    required this.priceController,
    required this.descriptionController,
  });

  final BookState state;
  final BookCubit cubit;
  final TextEditingController titleController;
  final TextEditingController authorController;
  final TextEditingController priceController;
  final TextEditingController descriptionController;

  @override
  Widget build(BuildContext context) {
    final primaryActionLabel = state.isSavingListing
        ? (state.isEditing ? 'Updating...' : 'Publishing...')
        : (state.isEditing ? 'Update Listing' : 'Publish Listing');
    final primaryActionIcon = state.isSavingListing
        ? AppLoadingIndicator(size: 18, color: Colors.white)
        : Icon(
            state.isEditing ? Icons.save_rounded : Icons.cloud_upload_rounded,
          );

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(22.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(28.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 26,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: AppStaggeredColumn(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(child: SectionTitle(title: 'Book Details')),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16.r),
                ),
                child: Text(
                  state.isEditing ? 'Edit Listing' : 'Seller Form',
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            state.isEditing
                ? 'Update the selected listing, adjust the price, and save your changes.'
                : 'Complete the fields below and publish the listing when everything looks correct.',
            style: TextStyle(
              fontSize: 13.sp,
              height: 1.45,
              color: AppColors.muted,
            ),
          ),
          SizedBox(height: 14.h),
          AppTextField(
            controller: titleController,
            label: 'Book Title',
            hint: 'Clean Code',
            prefixIcon: Icons.menu_book_rounded,
            onChanged: cubit.updateTitle,
          ),
          SizedBox(height: 14.h),
          AppTextField(
            controller: authorController,
            label: 'Author',
            hint: 'Robert C. Martin',
            prefixIcon: Icons.edit_note_rounded,
            onChanged: cubit.updateAuthor,
          ),
          SizedBox(height: 14.h),
          _CategorySelectorSection(
            selectedCategories: state.draft.categories,
            onToggleCategory: cubit.toggleCategory,
          ),
          SizedBox(height: 14.h),
          AppTextField(
            controller: priceController,
            label: 'Selling Price',
            hint: 'Enter book price',
            keyboardType: TextInputType.number,
            prefixIcon: Icons.currency_rupee_rounded,
            onChanged: cubit.updatePrice,
          ),
          SizedBox(height: 14.h),
          AppTextField(
            controller: descriptionController,
            label: 'Description',
            hint: 'Brief condition, highlights, notes, and delivery details.',
            minLines: 3,
            maxLines: null,
            keyboardType: TextInputType.multiline,
            prefixIcon: Icons.notes_rounded,
            onChanged: cubit.updateDescription,
          ),
          // SizedBox(height: 20.h),
          // Container(
          //   width: double.infinity,
          //   padding: EdgeInsets.all(16.w),
          //   decoration: BoxDecoration(
          //     color: AppColors.surface,
          //     borderRadius: BorderRadius.circular(24.r),
          //   ),
          //   child: Column(
          //     crossAxisAlignment: CrossAxisAlignment.start,
          //     children: [
          //       const SectionTitle(title: 'Quick Steps'),
          //       SizedBox(height: 12.h),
          //       const StepRow(
          //         step: '1',
          //         text: 'Tap image and select a cover photo.',
          //       ),
          //       const StepRow(
          //         step: '2',
          //         text:
          //             'Add title, author, price, description, and categories.',
          //       ),
          //       const StepRow(step: '3', text: 'Review the listing preview.'),
          //       const StepRow(step: '4', text: 'Edit or reset when needed.'),
          //       const StepRow(
          //         step: '5',
          //         text: 'Save the listing and view all inventory.',
          //       ),
          //     ],
          //   ),
          // ),
          SizedBox(height: 18.h),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: AppColors.dark,
              borderRadius: BorderRadius.circular(22.r),
            ),
            child: Row(
              children: [
                Container(
                  width: 44.w,
                  height: 44.w,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                  child: Icon(
                    Icons.inventory_2_rounded,
                    color: Colors.white,
                    size: 22.sp,
                  ),
                ),
                SizedBox(width: 14.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        state.draft.title.trim().isEmpty
                            ? 'Listing preview will appear here'
                            : state.draft.title,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        state.draft.price.trim().isEmpty
                            ? 'Add a price to preview the final listing'
                            : 'Price: ₹${state.draft.price}',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.78),
                          fontSize: 12.sp,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        state.draft.categories.isEmpty
                            ? 'Categories are optional for this listing'
                            : 'Categories: ${state.draft.categoryLabel}',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.78),
                          fontSize: 12.sp,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 24.h),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: state.canPublish ? cubit.saveListing : null,
                  icon: primaryActionIcon,
                  label: Text(
                    primaryActionLabel,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.white,
                    minimumSize: Size(double.infinity, 50.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                  ),
                ),
              ),
              // SizedBox(width: 12.w),
              // Expanded(
              //   child: OutlinedButton.icon(
              //     onPressed: cubit.viewAllListings,
              //     icon: const Icon(Icons.visibility_rounded),
              //     label: const Text('View All Listings'),
              //     style: OutlinedButton.styleFrom(
              //       foregroundColor: AppColors.dark,
              //       minimumSize: Size(double.infinity, 50.h),
              //       side: BorderSide(color: AppColors.border),
              //       shape: RoundedRectangleBorder(
              //         borderRadius: BorderRadius.circular(20.r),
              //       ),
              //     ),
              //   ),
              // ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CategorySelectorSection extends StatelessWidget {
  const _CategorySelectorSection({
    required this.selectedCategories,
    required this.onToggleCategory,
  });

  final List<String> selectedCategories;
  final ValueChanged<String> onToggleCategory;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Categories',
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w800,
                    color: AppColors.dark,
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 7.h),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(16.r),
                ),
                child: Text(
                  selectedCategories.isEmpty
                      ? 'Optional'
                      : '${selectedCategories.length} selected',
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            'Choose one or more categories for this book. Leave them blank if you want.',
            style: TextStyle(
              fontSize: 13.sp,
              height: 1.45,
              color: AppColors.muted,
            ),
          ),
          SizedBox(height: 14.h),
          Wrap(
            spacing: 10.w,
            runSpacing: 10.h,
            children: [
              for (final category in kBookCategories)
                _CategoryChip(
                  label: category,
                  isSelected: selectedCategories.contains(category),
                  onTap: () => onToggleCategory(category),
                ),
            ],
          ),
          // if (selectedCategories.isNotEmpty) ...[
          //   SizedBox(height: 14.h),
          //   Text(
          //     'Selected: ${selectedCategories.join(', ')}',
          //     style: TextStyle(
          //       fontSize: 12.sp,
          //       fontWeight: FontWeight.w700,
          //       color: AppColors.dark,
          //     ),
          //   ),
          // ],
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18.r),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 11.h),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.white,
          borderRadius: BorderRadius.circular(18.r),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Wrap(
          spacing: 8.w,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Icon(
              isSelected
                  ? Icons.check_circle_rounded
                  : Icons.add_circle_outline_rounded,
              size: 16.sp,
              color: isSelected ? Colors.white : AppColors.primary,
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w700,
                color: isSelected ? Colors.white : AppColors.dark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroSellCard extends StatelessWidget {
  const _HeroSellCard({required this.state});

  final BookState state;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(22.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.dark, AppColors.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.18),
            blurRadius: 26,
            offset: const Offset(0, 10),
          ),
        ],
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
                    'Seller Studio',
                    style: TextStyle(
                      color: AppColors.white,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                SizedBox(height: 14.h),
                Text(
                  state.isEditing
                      ? 'Tune the details and refresh your listing fast.'
                      : state.draft.imageCount == 0
                      ? 'Create a polished book listing in minutes.'
                      : 'Your listing is almost ready to go live.',
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: 25.sp,
                    height: 1.2,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 10.h),
                Text(
                  'Add up to ${BookModel.maxImages} clear images and keep your inventory updated from one place.',
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
            width: 92.w,
            height: 122.h,
            decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(24.r),
              border: Border.all(color: AppColors.white.withValues(alpha: 0.2)),
            ),
            child: Icon(
              Icons.auto_stories_rounded,
              color: AppColors.white,
              size: 42.sp,
            ),
          ),
        ],
      ),
    );
  }
}

class _ImagePickerCard extends StatelessWidget {
  const _ImagePickerCard({required this.state, required this.onAddImages});

  final BookState state;
  final VoidCallback onAddImages;

  @override
  Widget build(BuildContext context) {
    final hasImage = state.draft.hasImages;
    final previewBytes = state.draft.resolvedImageBytes;
    final previewUrl = state.draft.primaryImageUrl;

    return InkWell(
      borderRadius: BorderRadius.circular(28.r),
      onTap: state.isProcessingImage ? null : onAddImages,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        height: 280.h,
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(28.r),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.18),
            width: 1.4,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28.r),
                child: hasImage
                    ? _SelectedImageView(
                        imageBytes: previewBytes,
                        imageUrl: previewUrl,
                      )
                    : const _ImagePickerPlaceholder(),
              ),
            ),
            if (state.isProcessingImage)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.82),
                    borderRadius: BorderRadius.circular(28.r),
                  ),
                  child: const Center(
                    child: AppLoadingIndicator(label: 'Compressing image...'),
                  ),
                ),
              ),
            Positioned(
              right: 16.w,
              top: 16.h,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: AppColors.dark.withValues(alpha: 0.78),
                  borderRadius: BorderRadius.circular(18.r),
                ),
                child: Text(
                  '${state.draft.imageCount}/${BookModel.maxImages}',
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            Positioned(
              left: 16.w,
              bottom: 16.h,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
                decoration: BoxDecoration(
                  color: AppColors.white.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(18.r),
                ),
                child: Text(
                  state.isProcessingImage
                      ? 'Please wait while the images are compressed'
                      : hasImage
                      ? state.draft.imageCount < BookModel.maxImages
                            ? 'Tap to add more images'
                            : 'Maximum ${BookModel.maxImages} images selected'
                      : 'Tap to add up to ${BookModel.maxImages} book images',
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.dark,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SelectedImageStrip extends StatelessWidget {
  const _SelectedImageStrip({
    required this.images,
    required this.onRemoveImage,
  });

  final List<BookImageModel> images;
  final ValueChanged<int> onRemoveImage;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 92.h,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: images.length,
        separatorBuilder: (_, __) => SizedBox(width: 10.w),
        itemBuilder: (context, index) {
          final image = images[index];
          return Stack(
            children: [
              Container(
                width: 96.w,
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(22.r),
                  border: Border.all(color: AppColors.border),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(22.r),
                  child: _SelectedImageView(
                    imageBytes: image.resolvedBytes,
                    imageUrl: image.resolvedUrl,
                  ),
                ),
              ),
              Positioned(
                right: 6.w,
                top: 6.h,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.58),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    onPressed: () => onRemoveImage(index),
                    icon: Icon(
                      Icons.close_rounded,
                      color: Colors.white,
                      size: 16.sp,
                    ),
                    constraints: BoxConstraints.tight(Size(30.w, 30.w)),
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _AddBookLoadingView extends StatelessWidget {
  const _AddBookLoadingView();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 130.h),
      child: AppShimmer(
        child: Column(
          children: [
            AppShimmerBox(height: 180.h, radius: 30.r),
            SizedBox(height: 20.h),
            AppShimmerBox(height: 240.h, radius: 28.r),
            SizedBox(height: 20.h),
            AppShimmerBox(height: 460.h, radius: 28.r),
          ],
        ),
      ),
    );
  }
}

class _SelectedImageView extends StatelessWidget {
  const _SelectedImageView({this.imageBytes, this.imageUrl});

  final Uint8List? imageBytes;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    const fallback = _ImagePickerPlaceholder();
    if (imageBytes != null) {
      return Image.memory(
        imageBytes!,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => fallback,
      );
    }

    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return Image.network(
        imageUrl!,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => fallback,
      );
    }

    return fallback;
  }
}

class _ImagePickerPlaceholder extends StatelessWidget {
  const _ImagePickerPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFFFF7EC), Color(0xFFF4DDC0)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Center(
        child: SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72.r,
                height: 72.r,
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(22.r),
                ),
                child: Icon(
                  Icons.add_a_photo_rounded,
                  size: 34.r,
                  color: AppColors.primary,
                ),
              ),
              SizedBox(height: 14.h),
              Text(
                'Select book images',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w800,
                  color: AppColors.dark,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                'Choose up to ${BookModel.maxImages} images first, then enter the listing details manually.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13.sp,
                  height: 1.45,
                  color: AppColors.muted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

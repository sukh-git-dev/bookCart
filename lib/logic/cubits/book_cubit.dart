import 'dart:async';

import 'package:bookcart/core/utils/app_logger.dart';
import 'package:bookcart/data/models/book_model.dart';
import 'package:bookcart/data/repository/book_repository.dart';
import 'package:bookcart/logic/cubits/book_state.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

class BookCubit extends Cubit<BookState> {
  BookCubit(this._repository) : super(const BookState()) {
    loadBooks();
  }

  final BookRepository _repository;
  final ImagePicker _picker = ImagePicker();
  StreamSubscription<List<BookModel>>? _booksSubscription;

  Future<void> loadBooks() async {
    AppLogger.info('BookCubit', 'loadBooks: subscribing');
    emit(state.copyWith(isLoadingBooks: true, message: null));
    await _booksSubscription?.cancel();
    _booksSubscription = _repository.watchBooks().listen(
      (books) {
        AppLogger.success(
          'BookCubit',
          'Books synced',
          details: {'count': books.length},
        );
        emit(
          state.copyWith(books: books, isLoadingBooks: false, message: null),
        );
      },
      onError: (error, stackTrace) async {
        AppLogger.error(
          'BookCubit',
          'watchBooks stream error',
          error: error,
          stackTrace: stackTrace,
        );
        try {
          final books = await _repository.fetchBooks();
          AppLogger.success(
            'BookCubit',
            'Books fallback fetch succeeded',
            details: {'count': books.length},
          );
          emit(
            state.copyWith(books: books, isLoadingBooks: false, message: null),
          );
        } catch (fetchError, fetchStackTrace) {
          AppLogger.error(
            'BookCubit',
            'Books fallback fetch failed',
            error: fetchError,
            stackTrace: fetchStackTrace,
          );
          emit(
            state.copyWith(
              isLoadingBooks: false,
              message: 'Could not load books right now.',
            ),
          );
        }
      },
    );
  }

  void changeTab(int index) {
    emit(state.copyWith(currentTabIndex: index, message: null));
  }

  Future<void> pickImage() async {
    final timer = AppLogger.startTimer('BookCubit', 'pickImage');
    final remainingSlots = BookModel.maxImages - state.draft.imageCount;
    if (remainingSlots <= 0) {
      emit(
        state.copyWith(
          message: 'You can upload up to ${BookModel.maxImages} images.',
        ),
      );
      return;
    }

    emit(state.copyWith(isProcessingImage: true, message: null));

    try {
      final selectedImages = await _picker.pickMultiImage(
        limit: remainingSlots,
      );
      if (selectedImages.isEmpty) {
        timer.warning('Image selection cancelled');
        emit(
          state.copyWith(
            isProcessingImage: false,
            message: 'Image selection cancelled.',
          ),
        );
        return;
      }

      final nextImages = [...state.draft.galleryImages];
      for (final image in selectedImages.take(remainingSlots)) {
        final imageBytes = await image.readAsBytes();
        final compressedBytes = await FlutterImageCompress.compressWithList(
          imageBytes,
          minWidth: 900,
          minHeight: 900,
          quality: 68,
        );
        nextImages.add(
          BookImageModel(path: image.path, bytes: compressedBytes),
        );
      }
      final normalizedDraft = _draftWithImages(state.draft, nextImages);

      emit(
        state.copyWith(
          draft: normalizedDraft,
          isProcessingImage: false,
          message:
              '${selectedImages.length} image${selectedImages.length == 1 ? '' : 's'} added successfully.',
        ),
      );
      timer.success(
        'Book images selected',
        details: {'count': normalizedDraft.imageCount},
      );
    } catch (error, stackTrace) {
      timer.fail(
        'Image processing failed',
        error: error,
        stackTrace: stackTrace,
      );
      emit(
        state.copyWith(
          isProcessingImage: false,
          message: 'Could not process the image. Please try again.',
        ),
      );
    }
  }

  void removeImageAt(int index) {
    final currentImages = [...state.draft.galleryImages];
    if (index < 0 || index >= currentImages.length) {
      return;
    }

    currentImages.removeAt(index);
    emit(
      state.copyWith(
        draft: _draftWithImages(state.draft, currentImages),
        message: currentImages.isEmpty
            ? 'All listing images removed.'
            : 'Listing image removed.',
      ),
    );
  }

  void updateTitle(String value) {
    emit(
      state.copyWith(draft: state.draft.copyWith(title: value), message: null),
    );
  }

  void updateAuthor(String value) {
    emit(
      state.copyWith(draft: state.draft.copyWith(author: value), message: null),
    );
  }

  void toggleCategory(String value) {
    final selectedCategories = [...state.draft.categories];
    final selectedIndex = selectedCategories.indexWhere(
      (category) => category.toLowerCase() == value.toLowerCase(),
    );

    if (selectedIndex >= 0) {
      selectedCategories.removeAt(selectedIndex);
    } else {
      selectedCategories.add(value);
    }

    emit(
      state.copyWith(
        draft: state.draft.copyWith(
          category: BookModel.serializeCategories(selectedCategories),
        ),
        message: null,
      ),
    );
  }

  void updatePrice(String value) {
    emit(
      state.copyWith(draft: state.draft.copyWith(price: value), message: null),
    );
  }

  void updateDescription(String value) {
    emit(
      state.copyWith(
        draft: state.draft.copyWith(description: value),
        message: null,
      ),
    );
  }

  void startEditBook(String bookId) {
    final book = _repository.findById(bookId);
    if (book == null) {
      emit(state.copyWith(message: 'Could not find that listing.'));
      return;
    }

    emit(
      state.copyWith(
        currentTabIndex: 2,
        draft: book,
        editingBookId: bookId,
        message: 'Editing "${book.title}". Update details and save again.',
      ),
    );
  }

  void startCreateListing() {
    emit(
      state.copyWith(
        currentTabIndex: 2,
        draft: const BookModel(),
        clearEditing: true,
        message: null,
      ),
    );
  }

  void viewAllListings() {
    emit(state.copyWith(currentTabIndex: 1, message: null));
  }

  Future<void> saveListing() async {
    final timer = AppLogger.startTimer(
      'BookCubit',
      state.isEditing ? 'updateListing' : 'publishListing',
      details: {'bookId': state.editingBookId},
    );
    final currentTabIndex = state.currentTabIndex;
    emit(state.copyWith(isSavingListing: true, message: null));

    try {
      if (state.isEditing) {
        await _repository.update(state.draft.copyWith(id: state.editingBookId));
        timer.success('Listing updated');
        emit(
          state.copyWith(
            currentTabIndex: currentTabIndex,
            draft: const BookModel(),
            isLoadingBooks: false,
            isSavingListing: false,
            isProcessingImage: false,
            clearEditing: true,
            message: 'Listing updated successfully.',
          ),
        );
        return;
      }

      await _repository.publish(state.draft);
      timer.success('Listing published');
      emit(
        state.copyWith(
          currentTabIndex: currentTabIndex,
          draft: const BookModel(),
          isLoadingBooks: false,
          isSavingListing: false,
          isProcessingImage: false,
          clearEditing: true,
          message: 'Listing published successfully.',
        ),
      );
    } catch (error, stackTrace) {
      timer.fail('Listing save failed', error: error, stackTrace: stackTrace);
      emit(
        state.copyWith(
          isSavingListing: false,
          message: 'Could not save the listing right now.',
        ),
      );
    }
  }

  Future<void> deleteBook(String bookId) async {
    final timer = AppLogger.startTimer(
      'BookCubit',
      'deleteBook',
      details: {'bookId': bookId},
    );
    try {
      await _repository.delete(bookId);
      timer.success('Listing deleted');
      emit(
        state.copyWith(
          books: _repository.snapshot(),
          draft: state.editingBookId == bookId
              ? const BookModel()
              : state.draft,
          clearEditing: state.editingBookId == bookId,
          message: 'Listing deleted successfully.',
        ),
      );
    } catch (error, stackTrace) {
      timer.fail('Delete listing failed', error: error, stackTrace: stackTrace);
      emit(state.copyWith(message: 'Could not delete the listing right now.'));
    }
  }

  void clearMessage() {
    emit(state.copyWith(message: null));
  }

  @override
  Future<void> close() async {
    await _booksSubscription?.cancel();
    return super.close();
  }

  BookModel _draftWithImages(BookModel draft, List<BookImageModel> images) {
    final limitedImages = images
        .take(BookModel.maxImages)
        .toList(growable: false);
    final primaryImage = limitedImages.isEmpty ? null : limitedImages.first;

    return draft.copyWith(
      imagePath: primaryImage?.path,
      imageBytes: primaryImage?.bytes,
      imageBase64: primaryImage?.base64,
      imageUrl: primaryImage?.resolvedUrl,
      images: limitedImages,
      clearImagePath: limitedImages.isEmpty,
      clearImageBytes: limitedImages.isEmpty,
      clearImageBase64: limitedImages.isEmpty,
      clearImageUrl: limitedImages.isEmpty,
      clearImages: limitedImages.isEmpty,
    );
  }
}

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

  Future<void> loadBooks() async {
    emit(state.copyWith(isLoadingBooks: true, message: null));
    final books = await _repository.fetchBooks();
    emit(state.copyWith(books: books, isLoadingBooks: false, message: null));
  }

  void changeTab(int index) {
    emit(state.copyWith(currentTabIndex: index, message: null));
  }

  Future<void> pickImage() async {
    emit(state.copyWith(isProcessingImage: true, message: null));

    try {
      final image = await _picker.pickImage(source: ImageSource.gallery);
      if (image == null) {
        emit(
          state.copyWith(
            isProcessingImage: false,
            message: 'Image selection cancelled.',
          ),
        );
        return;
      }

      final imageBytes = await image.readAsBytes();
      final compressedBytes = await FlutterImageCompress.compressWithList(
        imageBytes,
        minWidth: 1280,
        minHeight: 1280,
        quality: 82,
      );

      emit(
        state.copyWith(
          draft: state.draft.copyWith(
            imagePath: image.path,
            imageBytes: compressedBytes,
          ),
          isProcessingImage: false,
          message: 'Book image optimized and added successfully.',
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          isProcessingImage: false,
          message: 'Could not process the image. Please try again.',
        ),
      );
    }
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
    final currentTabIndex = state.currentTabIndex;
    emit(state.copyWith(isSavingListing: true, message: null));

    try {
      if (state.isEditing) {
        await _repository.update(state.draft.copyWith(id: state.editingBookId));
        final books = _repository.snapshot();
        emit(
          state.copyWith(
            currentTabIndex: currentTabIndex,
            books: books,
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
      final books = _repository.snapshot();
      emit(
        state.copyWith(
          currentTabIndex: currentTabIndex,
          books: books,
          draft: const BookModel(),
          isLoadingBooks: false,
          isSavingListing: false,
          isProcessingImage: false,
          clearEditing: true,
          message: 'Listing published successfully.',
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          isSavingListing: false,
          message: 'Could not save the listing right now.',
        ),
      );
    }
  }

  Future<void> deleteBook(String bookId) async {
    await _repository.delete(bookId);
    emit(
      state.copyWith(
        books: _repository.snapshot(),
        draft: state.editingBookId == bookId ? const BookModel() : state.draft,
        clearEditing: state.editingBookId == bookId,
        message: 'Listing deleted successfully.',
      ),
    );
  }

  void clearMessage() {
    emit(state.copyWith(message: null));
  }
}

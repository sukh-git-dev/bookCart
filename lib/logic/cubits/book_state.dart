import 'package:bookcart/data/models/book_model.dart';

class BookState {
  const BookState({
    this.currentTabIndex = 0,
    this.books = const [],
    this.draft = const BookModel(),
    this.isLoadingBooks = true,
    this.isSavingListing = false,
    this.isProcessingImage = false,
    this.editingBookId,
    this.message,
  });

  final int currentTabIndex;
  final List<BookModel> books;
  final BookModel draft;
  final bool isLoadingBooks;
  final bool isSavingListing;
  final bool isProcessingImage;
  final String? editingBookId;
  final String? message;

  bool get isEditing => editingBookId != null;

  bool get canPublish =>
      !isLoadingBooks &&
      !isSavingListing &&
      !isProcessingImage &&
      draft.canPublish;

  BookState copyWith({
    int? currentTabIndex,
    List<BookModel>? books,
    BookModel? draft,
    bool? isLoadingBooks,
    bool? isSavingListing,
    bool? isProcessingImage,
    String? editingBookId,
    bool clearEditing = false,
    String? message,
  }) {
    return BookState(
      currentTabIndex: currentTabIndex ?? this.currentTabIndex,
      books: books ?? this.books,
      draft: draft ?? this.draft,
      isLoadingBooks: isLoadingBooks ?? this.isLoadingBooks,
      isSavingListing: isSavingListing ?? this.isSavingListing,
      isProcessingImage: isProcessingImage ?? this.isProcessingImage,
      editingBookId: clearEditing ? null : editingBookId ?? this.editingBookId,
      message: message,
    );
  }
}

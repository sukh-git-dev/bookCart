import 'package:bookcart/data/models/book_model.dart';

class BookState {
  const BookState({
    this.currentTabIndex = 2,
    this.books = const [],
    this.draft = const BookModel(),
    this.isPublishing = false,
    this.message,
  });

  final int currentTabIndex;
  final List<BookModel> books;
  final BookModel draft;
  final bool isPublishing;
  final String? message;

  bool get canPublish => !isPublishing && draft.canPublish;

  BookState copyWith({
    int? currentTabIndex,
    List<BookModel>? books,
    BookModel? draft,
    bool? isPublishing,
    String? message,
  }) {
    return BookState(
      currentTabIndex: currentTabIndex ?? this.currentTabIndex,
      books: books ?? this.books,
      draft: draft ?? this.draft,
      isPublishing: isPublishing ?? this.isPublishing,
      message: message,
    );
  }
}

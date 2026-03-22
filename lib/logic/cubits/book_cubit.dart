import 'package:bookcart/data/repository/book_repository.dart';
import 'package:bookcart/logic/cubits/book_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

class BookCubit extends Cubit<BookState> {
  BookCubit(this._repository)
    : super(BookState(books: _repository.getInitialBooks()));

  final BookRepository _repository;
  final ImagePicker _picker = ImagePicker();

  void changeTab(int index) {
    emit(state.copyWith(currentTabIndex: index, message: null));
  }

  Future<void> pickImage() async {
    try {
      final image = await _picker.pickImage(source: ImageSource.gallery);
      if (image == null) {
        emit(state.copyWith(message: 'Image selection cancelled.'));
        return;
      }

      final imageBytes = await image.readAsBytes();
      emit(
        state.copyWith(
          draft: state.draft.copyWith(
            imagePath: image.path,
            imageBytes: imageBytes,
          ),
          message: 'Book image added successfully.',
        ),
      );
    } catch (_) {
      emit(state.copyWith(message: 'Could not read the image. Please try again.'));
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

  Future<void> publish() async {
    emit(state.copyWith(isPublishing: true, message: null));
    final published = await _repository.publish(state.draft);
    emit(
      BookState(
        currentTabIndex: state.currentTabIndex,
        books: [published, ...state.books],
        message: 'Listing published successfully.',
      ),
    );
  }

  void clearMessage() {
    emit(state.copyWith(message: null));
  }
}

import 'dart:typed_data';

import 'package:bookcart/core/utils/book_autofill_utils.dart';
import 'package:bookcart/data/models/book_model.dart';

class BookRepository {
  BookRepository() : _books = List<BookModel>.from(_seedBooks);

  final List<BookModel> _books;

  static const List<BookModel> _seedBooks = [
    BookModel(
      id: 'book-1',
      title: 'Mathematics Basics',
      author: 'R. Sharma',
      category: 'School',
      price: '180',
      description: 'Good for school students with solved exercises.',
    ),
    BookModel(
      id: 'book-2',
      title: 'Engineering Mechanics',
      author: 'S. Kumar',
      category: 'College',
      price: '340',
      description: 'Semester reference with notes and examples.',
    ),
    BookModel(
      id: 'book-3',
      title: 'English Grammar Guide',
      author: 'P. Roy',
      category: 'School',
      price: '150',
      description: 'Clear explanations and practice chapters.',
    ),
    BookModel(
      id: 'book-4',
      title: 'Competitive Exam Toolkit',
      author: 'A. Das',
      category: 'Competitive Exams',
      price: '220',
      description: 'Preparation material for aptitude and reasoning.',
    ),
    BookModel(
      id: 'book-5',
      title: 'Flutter Development Guide',
      author: 'M. Arora',
      category: 'Technology',
      price: '410',
      description: 'Practical guide for mobile app development projects.',
    ),
    BookModel(
      id: 'book-6',
      title: 'Panchatantra Stories',
      author: 'V. Mehta',
      category: 'Kids Books',
      price: '130',
      description: 'Illustrated moral stories for young readers.',
    ),
    BookModel(
      id: 'book-7',
      title: 'Atomic Habits',
      author: 'James Clear',
      category: 'Self Help',
      price: '299',
      description: 'Popular self-improvement book with simple habit systems.',
    ),
    BookModel(
      id: 'book-8',
      title: 'Wings of Fire',
      author: 'A. P. J. Abdul Kalam',
      category: 'Biography',
      price: '250',
      description: 'Inspiring autobiography of Dr. A. P. J. Abdul Kalam.',
    ),
  ];

  Future<List<BookModel>> fetchBooks() async {
    await Future<void>.delayed(const Duration(milliseconds: 650));
    return List<BookModel>.from(_books);
  }

  Future<BookModel> autofillFromImage({
    required String imagePath,
    required String imageName,
    required Uint8List imageBytes,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    final title = BookAutofillUtils.normalizeTitleFromImageName(imageName);

    return BookModel(
      id: _buildId(),
      imagePath: imagePath,
      imageBytes: imageBytes,
      title: title,
      author: 'Unknown Author',
      category: 'Technology',
      price: '299',
      description:
          'Pre-owned copy of $title in good condition. Minimal markings, clean pages, and suitable for students or casual readers.',
    );
  }

  Future<BookModel> publish(BookModel book) async {
    await Future<void>.delayed(const Duration(milliseconds: 800));
    final savedBook = book.copyWith(id: book.id.isEmpty ? _buildId() : book.id);
    _books.insert(0, savedBook);
    return savedBook;
  }

  Future<BookModel> update(BookModel book) async {
    await Future<void>.delayed(const Duration(milliseconds: 650));
    final index = _books.indexWhere((item) => item.id == book.id);
    if (index < 0) {
      throw StateError('Book listing not found.');
    }

    _books[index] = book;
    return book;
  }

  Future<void> delete(String bookId) async {
    await Future<void>.delayed(const Duration(milliseconds: 350));
    _books.removeWhere((book) => book.id == bookId);
  }

  BookModel? findById(String bookId) {
    for (final book in _books) {
      if (book.id == bookId) {
        return book;
      }
    }

    return null;
  }

  List<BookModel> snapshot() => List<BookModel>.from(_books);

  String _buildId() => 'book-${DateTime.now().microsecondsSinceEpoch}';
}

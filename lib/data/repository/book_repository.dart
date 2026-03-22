import 'dart:typed_data';

import 'package:bookcart/core/utils/book_autofill_utils.dart';
import 'package:bookcart/data/models/book_model.dart';

class BookRepository {
  List<BookModel> getInitialBooks() {
    return const [
      BookModel(
        title: 'Mathematics Basics',
        author: 'R. Sharma',
        category: 'School',
        price: '180',
        description: 'Good for school students with solved exercises.',
      ),
      BookModel(
        title: 'Engineering Mechanics',
        author: 'S. Kumar',
        category: 'College',
        price: '340',
        description: 'Semester reference with notes and examples.',
      ),
      BookModel(
        title: 'English Grammar Guide',
        author: 'P. Roy',
        category: 'School',
        price: '150',
        description: 'Clear explanations and practice chapters.',
      ),
      BookModel(
        title: 'Competitive Exam Toolkit',
        author: 'A. Das',
        category: 'Competitive Exams',
        price: '220',
        description: 'Preparation material for aptitude and reasoning.',
      ),
      BookModel(
        title: 'Flutter Development Guide',
        author: 'M. Arora',
        category: 'Technology',
        price: '410',
        description: 'Practical guide for mobile app development projects.',
      ),
      BookModel(
        title: 'Panchatantra Stories',
        author: 'V. Mehta',
        category: 'Kids Books',
        price: '130',
        description: 'Illustrated moral stories for young readers.',
      ),
      BookModel(
        title: 'Atomic Habits',
        author: 'James Clear',
        category: 'Self Help',
        price: '299',
        description: 'Popular self-improvement book with simple habit systems.',
      ),
      BookModel(
        title: 'Wings of Fire',
        author: 'A. P. J. Abdul Kalam',
        category: 'Biography',
        price: '250',
        description: 'Inspiring autobiography of Dr. A. P. J. Abdul Kalam.',
      ),
    ];
  }

  Future<BookModel> autofillFromImage({
    required String imagePath,
    required String imageName,
    required Uint8List imageBytes,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    final title = BookAutofillUtils.normalizeTitleFromImageName(imageName);

    return BookModel(
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
    return book;
  }
}

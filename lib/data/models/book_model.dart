import 'dart:typed_data';

class BookModel {
  const BookModel({
    this.imagePath,
    this.imageBytes,
    this.title = '',
    this.author = '',
    this.category = 'Other',
    this.price = '',
    this.description = '',
  });

  final String? imagePath;
  final Uint8List? imageBytes;
  final String title;
  final String author;
  final String category;
  final String price;
  final String description;

  bool get canPublish =>
      title.trim().isNotEmpty &&
      author.trim().isNotEmpty &&
      price.trim().isNotEmpty &&
      description.trim().isNotEmpty;

  BookModel copyWith({
    String? imagePath,
    Uint8List? imageBytes,
    String? title,
    String? author,
    String? category,
    String? price,
    String? description,
    bool clearImagePath = false,
  }) {
    return BookModel(
      imagePath: clearImagePath ? null : imagePath ?? this.imagePath,
      imageBytes: imageBytes ?? this.imageBytes,
      title: title ?? this.title,
      author: author ?? this.author,
      category: category ?? this.category,
      price: price ?? this.price,
      description: description ?? this.description,
    );
  }
}

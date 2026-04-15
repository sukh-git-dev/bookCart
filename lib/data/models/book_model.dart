import 'dart:typed_data';

class BookModel {
  const BookModel({
    this.imagePath,
    this.imageBytes,
    this.title = '',
    this.author = '',
    this.category = '',
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

  List<String> get categories => parseCategories(category);

  String get categoryLabel =>
      categories.isEmpty ? 'Other' : categories.join(', ');

  String get primaryCategory => categories.isEmpty ? 'Other' : categories.first;

  int get additionalCategoryCount =>
      categories.length > 1 ? categories.length - 1 : 0;

  bool belongsToCategory(String value) {
    final normalizedValue = value.trim().toLowerCase();
    return categories.any(
      (category) => category.toLowerCase() == normalizedValue,
    );
  }

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

  static List<String> parseCategories(String value) {
    final seen = <String>{};
    final parsed = <String>[];

    for (final rawCategory in value.split(',')) {
      final trimmedCategory = rawCategory.trim();
      if (trimmedCategory.isEmpty) {
        continue;
      }

      final normalizedKey = trimmedCategory.toLowerCase();
      if (seen.add(normalizedKey)) {
        parsed.add(trimmedCategory);
      }
    }

    return parsed;
  }

  static String serializeCategories(Iterable<String> values) {
    final seen = <String>{};
    final parsed = <String>[];

    for (final rawCategory in values) {
      final trimmedCategory = rawCategory.trim();
      if (trimmedCategory.isEmpty) {
        continue;
      }

      final normalizedKey = trimmedCategory.toLowerCase();
      if (seen.add(normalizedKey)) {
        parsed.add(trimmedCategory);
      }
    }

    return parsed.join(', ');
  }
}

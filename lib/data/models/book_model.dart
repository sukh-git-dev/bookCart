import 'dart:convert';
import 'dart:typed_data';

class BookImageModel {
  const BookImageModel({this.path, this.bytes, this.base64, this.url});

  final String? path;
  final Uint8List? bytes;
  final String? base64;
  final String? url;

  Uint8List? get resolvedBytes => bytes ?? _decodeImage(base64);

  String? get resolvedUrl {
    final normalizedUrl = _normalizedString(url);
    if (normalizedUrl != null) {
      return normalizedUrl;
    }

    return _looksLikeHttpUrl(base64) ? _normalizedString(base64) : null;
  }

  bool get hasVisual => resolvedBytes != null || resolvedUrl != null;

  BookImageModel copyWith({
    String? path,
    Uint8List? bytes,
    String? base64,
    String? url,
    bool clearPath = false,
    bool clearBytes = false,
    bool clearBase64 = false,
    bool clearUrl = false,
  }) {
    return BookImageModel(
      path: clearPath ? null : path ?? this.path,
      bytes: clearBytes ? null : bytes ?? this.bytes,
      base64: clearBase64 ? null : base64 ?? this.base64,
      url: clearUrl ? null : url ?? this.url,
    );
  }
}

class BookModel {
  const BookModel({
    this.id = '',
    this.imagePath,
    this.imageBytes,
    this.imageBase64,
    this.imageUrl,
    this.images = const [],
    this.title = '',
    this.author = '',
    this.category = '',
    this.price = '',
    this.description = '',
    this.sellerId = '',
    this.sellerName = '',
    this.sellerEmail = '',
    this.sellerPhone = '',
    this.sellerLocation = '',
    this.sellerLatitude,
    this.sellerLongitude,
    this.createdAt,
    this.updatedAt,
  });

  static const int maxImages = 4;

  final String id;
  final String? imagePath;
  final Uint8List? imageBytes;
  final String? imageBase64;
  final String? imageUrl;
  final List<BookImageModel> images;
  final String title;
  final String author;
  final String category;
  final String price;
  final String description;
  final String sellerId;
  final String sellerName;
  final String sellerEmail;
  final String sellerPhone;
  final String sellerLocation;
  final double? sellerLatitude;
  final double? sellerLongitude;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  List<BookImageModel> get galleryImages {
    if (images.isNotEmpty) {
      return _limitImages(
        images.where((image) => image.hasVisual).toList(growable: false),
      );
    }

    final legacyImage = BookImageModel(
      path: imagePath,
      bytes: imageBytes,
      base64: imageBase64,
      url: imageUrl,
    );
    if (!legacyImage.hasVisual) {
      return const [];
    }

    return [legacyImage];
  }

  BookImageModel? get primaryImage =>
      galleryImages.isEmpty ? null : galleryImages.first;

  List<Uint8List> get resolvedImageBytesList => [
    for (final image in galleryImages)
      if (image.resolvedBytes != null) image.resolvedBytes!,
  ];

  List<String> get resolvedImageUrls => [
    for (final image in galleryImages)
      if (image.resolvedUrl != null) image.resolvedUrl!,
  ];

  List<String> get selectedImagePaths => [
    for (final image in galleryImages)
      if (_normalizedString(image.path) != null) _normalizedString(image.path)!,
  ];

  Uint8List? get resolvedImageBytes =>
      resolvedImageBytesList.isEmpty ? null : resolvedImageBytesList.first;

  String? get primaryImageUrl =>
      resolvedImageUrls.isEmpty ? null : resolvedImageUrls.first;

  int get imageCount => galleryImages.length;

  bool get hasImages => galleryImages.isNotEmpty;

  List<String> get categories => parseCategories(category);

  String get categoryLabel =>
      categories.isEmpty ? 'Other' : categories.join(', ');

  String get primaryCategory => categories.isEmpty ? 'Other' : categories.first;

  int get additionalCategoryCount =>
      categories.length > 1 ? categories.length - 1 : 0;

  double get priceValue => double.tryParse(price.trim()) ?? 0;

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
    String? id,
    String? imagePath,
    Uint8List? imageBytes,
    String? imageBase64,
    String? imageUrl,
    List<BookImageModel>? images,
    String? title,
    String? author,
    String? category,
    String? price,
    String? description,
    String? sellerId,
    String? sellerName,
    String? sellerEmail,
    String? sellerPhone,
    String? sellerLocation,
    double? sellerLatitude,
    double? sellerLongitude,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool clearImagePath = false,
    bool clearImageBytes = false,
    bool clearImageBase64 = false,
    bool clearImageUrl = false,
    bool clearImages = false,
  }) {
    return BookModel(
      id: id ?? this.id,
      imagePath: clearImagePath ? null : imagePath ?? this.imagePath,
      imageBytes: clearImageBytes ? null : imageBytes ?? this.imageBytes,
      imageBase64: clearImageBase64 ? null : imageBase64 ?? this.imageBase64,
      imageUrl: clearImageUrl ? null : imageUrl ?? this.imageUrl,
      images: clearImages ? const [] : images ?? this.images,
      title: title ?? this.title,
      author: author ?? this.author,
      category: category ?? this.category,
      price: price ?? this.price,
      description: description ?? this.description,
      sellerId: sellerId ?? this.sellerId,
      sellerName: sellerName ?? this.sellerName,
      sellerEmail: sellerEmail ?? this.sellerEmail,
      sellerPhone: sellerPhone ?? this.sellerPhone,
      sellerLocation: sellerLocation ?? this.sellerLocation,
      sellerLatitude: sellerLatitude ?? this.sellerLatitude,
      sellerLongitude: sellerLongitude ?? this.sellerLongitude,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    final primary = primaryImage;
    final encodedImage = primary?.resolvedBytes != null
        ? base64Encode(primary!.resolvedBytes!)
        : _normalizedBase64(primary?.base64);

    return {
      'id': id,
      'imageBase64': encodedImage,
      'imageUrl': primaryImageUrl,
      'imageUrls': resolvedImageUrls,
      'title': title.trim(),
      'author': author.trim(),
      'category': category.trim(),
      'price': price.trim(),
      'description': description.trim(),
      'sellerId': sellerId,
      'sellerName': sellerName,
      'sellerEmail': sellerEmail,
      'sellerPhone': sellerPhone,
      'sellerLocation': sellerLocation,
      'sellerLatitude': sellerLatitude,
      'sellerLongitude': sellerLongitude,
    };
  }

  factory BookModel.fromJson(
    Map<String, dynamic> json, {
    String fallbackId = '',
  }) {
    final galleryImages = _galleryImagesFromJson(json);
    final primaryImage = galleryImages.isEmpty
        ? _legacyImageFromJson(json)
        : galleryImages.first;

    return BookModel(
      id: json['id'] as String? ?? fallbackId,
      imagePath: primaryImage?.path,
      imageBytes: primaryImage?.resolvedBytes,
      imageBase64: primaryImage?.resolvedUrl == null
          ? _normalizedBase64(primaryImage?.base64)
          : null,
      imageUrl: primaryImage?.resolvedUrl,
      images: galleryImages,
      title: json['title'] as String? ?? '',
      author: json['author'] as String? ?? '',
      category: json['category'] as String? ?? '',
      price: json['price'] as String? ?? '',
      description: json['description'] as String? ?? '',
      sellerId:
          json['sellerId'] as String? ?? json['seller_id'] as String? ?? '',
      sellerName:
          json['sellerName'] as String? ?? json['seller_name'] as String? ?? '',
      sellerEmail:
          json['sellerEmail'] as String? ??
          json['seller_email'] as String? ??
          '',
      sellerPhone:
          json['sellerPhone'] as String? ??
          json['seller_phone'] as String? ??
          '',
      sellerLocation:
          json['sellerLocation'] as String? ??
          json['seller_location'] as String? ??
          '',
      sellerLatitude: _doubleFromJson(
        json['sellerLatitude'] ?? json['seller_latitude'],
      ),
      sellerLongitude: _doubleFromJson(
        json['sellerLongitude'] ?? json['seller_longitude'],
      ),
      createdAt: _dateTimeFromJson(json['createdAt'] ?? json['created_at']),
      updatedAt: _dateTimeFromJson(json['updatedAt'] ?? json['updated_at']),
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

List<BookImageModel> _limitImages(List<BookImageModel> images) {
  if (images.length <= BookModel.maxImages) {
    return images;
  }

  return images.take(BookModel.maxImages).toList(growable: false);
}

BookImageModel? _legacyImageFromJson(Map<String, dynamic> json) {
  final rawImageBase64 = _normalizedString(
    json['imageBase64'] as String? ?? json['image_base64'] as String?,
  );
  final explicitImageUrl = _normalizedString(
    json['imageUrl'] as String? ?? json['image_url'] as String?,
  );
  final legacyImage = BookImageModel(
    base64: _looksLikeHttpUrl(rawImageBase64)
        ? null
        : _normalizedBase64(rawImageBase64),
    url:
        explicitImageUrl ??
        (_looksLikeHttpUrl(rawImageBase64) ? rawImageBase64 : null),
  );

  return legacyImage.hasVisual ? legacyImage : null;
}

List<BookImageModel> _galleryImagesFromJson(Map<String, dynamic> json) {
  final rawImageUrls = json['imageUrls'] ?? json['image_urls'];
  final parsedImageUrls = _stringListFromJson(rawImageUrls);
  if (parsedImageUrls.isNotEmpty) {
    return _limitImages([
      for (final imageUrl in parsedImageUrls) BookImageModel(url: imageUrl),
    ]);
  }

  return const [];
}

List<String> _stringListFromJson(Object? value) {
  if (value == null) {
    return const [];
  }

  if (value is List) {
    return value
        .map((item) => _normalizedString(item?.toString()))
        .whereType<String>()
        .take(BookModel.maxImages)
        .toList(growable: false);
  }

  if (value is String) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return const [];
    }

    try {
      final decoded = jsonDecode(trimmed);
      if (decoded is List) {
        return decoded
            .map((item) => _normalizedString(item?.toString()))
            .whereType<String>()
            .take(BookModel.maxImages)
            .toList(growable: false);
      }
    } catch (_) {
      final normalized = _normalizedString(trimmed);
      if (normalized != null) {
        return [normalized];
      }
    }
  }

  return const [];
}

Uint8List? _decodeImage(String? value) {
  final normalized = _normalizedBase64(value);
  if (normalized == null) {
    return null;
  }

  try {
    return base64Decode(normalized);
  } catch (_) {
    return null;
  }
}

String? _normalizedString(String? value) {
  final trimmed = value?.trim();
  if (trimmed == null || trimmed.isEmpty) {
    return null;
  }

  return trimmed;
}

String? _normalizedBase64(String? value) {
  final normalized = _normalizedString(value);
  if (normalized == null) {
    return null;
  }

  final dataUriIndex = normalized.indexOf(',');
  if (normalized.startsWith('data:') && dataUriIndex >= 0) {
    return normalized.substring(dataUriIndex + 1).trim();
  }

  return normalized;
}

bool _looksLikeHttpUrl(String? value) {
  final normalized = _normalizedString(value);
  if (normalized == null) {
    return false;
  }

  final uri = Uri.tryParse(normalized);
  return uri != null &&
      (uri.scheme == 'http' || uri.scheme == 'https') &&
      uri.host.isNotEmpty;
}

double? _doubleFromJson(Object? value) {
  if (value == null) {
    return null;
  }
  if (value is num) {
    return value.toDouble();
  }
  if (value is String) {
    return double.tryParse(value);
  }

  return null;
}

DateTime? _dateTimeFromJson(Object? value) {
  if (value == null) {
    return null;
  }
  if (value is DateTime) {
    return value;
  }
  if (value is String) {
    return DateTime.tryParse(value);
  }

  try {
    final dynamic timestamp = value;
    final Object? dateTime = timestamp.toDate();
    return dateTime is DateTime ? dateTime : null;
  } catch (_) {
    return null;
  }
}

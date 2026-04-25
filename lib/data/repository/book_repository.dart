import 'dart:typed_data';

import 'package:bookcart/core/utils/book_autofill_utils.dart';
import 'package:bookcart/core/utils/supabase_schema_error_utils.dart';
import 'package:bookcart/data/models/book_model.dart';
import 'package:bookcart/data/models/user_model.dart';
import 'package:bookcart/data/repository/location_label_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BookRepository {
  BookRepository({SupabaseClient? client})
    : _client = client,
      _books = <BookModel>[];

  static const String _bookImagesBucket = 'book_images';

  final SupabaseClient? _client;
  final List<BookModel> _books;

  SupabaseClient get _resolvedClient => _client ?? Supabase.instance.client;

  Stream<List<BookModel>> watchBooks() {
    return _resolvedClient
        .from('books')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .asyncMap((rows) async {
          final books = await Future.wait(
            rows.map((row) {
              final book = BookModel.fromJson(
                row,
                fallbackId: row['id'] as String? ?? '',
              );
              return LocationLabelRepository.enrichBook(book);
            }),
          );
          _replaceBooks(books);
          return snapshot();
        });
  }

  Future<List<BookModel>> fetchBooks() async {
    final dynamic response;
    try {
      response = await _resolvedClient
          .from('books')
          .select()
          .order('created_at', ascending: false);
    } on PostgrestException catch (error) {
      if (isSupabaseMissingTableError(error, table: 'public.books')) {
        throw StateError(supabaseSchemaSetupMessage(table: 'public.books'));
      }
      rethrow;
    }

    final books = await Future.wait(
      (response as List<dynamic>).map((row) {
        final data = Map<String, dynamic>.from(row as Map);
        final book = BookModel.fromJson(
          data,
          fallbackId: data['id'] as String? ?? '',
        );
        return LocationLabelRepository.enrichBook(book);
      }),
    );
    _replaceBooks(books);
    return snapshot();
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
      images: [BookImageModel(path: imagePath, bytes: imageBytes)],
      title: title,
      author: 'Unknown Author',
      category: 'Technology',
      price: '299',
      description:
          'Pre-owned copy of $title in good condition. Minimal markings, clean pages, and suitable for students or casual readers.',
    );
  }

  Future<BookModel> publish(BookModel book) async {
    final seller = await _readCurrentUser();
    final preparedBook = await _prepareBookForPersistence(
      book.copyWith(
        sellerId: seller.id,
        sellerName: seller.name,
        sellerEmail: seller.email,
        sellerPhone: seller.phone,
        sellerLocation: seller.location,
        sellerLatitude: seller.latitude,
        sellerLongitude: seller.longitude,
      ),
      ownerId: seller.id,
    );
    final now = DateTime.now().toUtc().toIso8601String();
    final payload = {
      ..._bookToRow(preparedBook),
      if (preparedBook.id.trim().isNotEmpty) 'id': preparedBook.id.trim(),
      'created_at': now,
      'updated_at': now,
    };

    final dynamic row;
    try {
      row = await _resolvedClient
          .from('books')
          .insert(payload)
          .select()
          .single();
    } on PostgrestException catch (error) {
      if (isSupabaseMissingTableError(error, table: 'public.books')) {
        throw StateError(supabaseSchemaSetupMessage(table: 'public.books'));
      }
      rethrow;
    }
    final savedBook = await LocationLabelRepository.enrichBook(
      BookModel.fromJson(
        Map<String, dynamic>.from(row),
        fallbackId: Map<String, dynamic>.from(row)['id'] as String? ?? '',
      ),
    );

    _books.insert(0, savedBook);
    return savedBook;
  }

  Future<BookModel> update(BookModel book) async {
    if (book.id.isEmpty) {
      throw StateError('Book listing not found.');
    }

    final seller = await _readCurrentUser();
    final existingBook = findById(book.id) ?? book;
    final updatedBook = await _prepareBookForPersistence(
      book.copyWith(
        sellerId: seller.id,
        sellerName: seller.name,
        sellerEmail: seller.email,
        sellerPhone: seller.phone,
        sellerLocation: seller.location,
        sellerLatitude: seller.latitude,
        sellerLongitude: seller.longitude,
        createdAt: existingBook.createdAt,
      ),
      ownerId: seller.id,
    );

    final dynamic row;
    try {
      row = await _resolvedClient
          .from('books')
          .update({
            ..._bookToRow(updatedBook),
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', book.id)
          .select()
          .single();
    } on PostgrestException catch (error) {
      if (isSupabaseMissingTableError(error, table: 'public.books')) {
        throw StateError(supabaseSchemaSetupMessage(table: 'public.books'));
      }
      rethrow;
    }

    final savedBook = await LocationLabelRepository.enrichBook(
      BookModel.fromJson(Map<String, dynamic>.from(row), fallbackId: book.id),
    );
    final index = _books.indexWhere((item) => item.id == savedBook.id);
    if (index >= 0) {
      _books[index] = savedBook;
    } else {
      _books.insert(0, savedBook);
    }
    return savedBook;
  }

  Future<void> delete(String bookId) async {
    try {
      await _resolvedClient.from('books').delete().eq('id', bookId);
    } on PostgrestException catch (error) {
      if (isSupabaseMissingTableError(error, table: 'public.books')) {
        throw StateError(supabaseSchemaSetupMessage(table: 'public.books'));
      }
      rethrow;
    }
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

  Future<UserModel> _readCurrentUser() async {
    final currentUser = _resolvedClient.auth.currentUser;
    if (currentUser == null) {
      throw StateError('Please log in again before saving a listing.');
    }

    final dynamic row;
    try {
      row = await _resolvedClient
          .from('users')
          .select()
          .eq('id', currentUser.id)
          .maybeSingle();
    } on PostgrestException catch (error) {
      if (isSupabaseMissingTableError(error, table: 'public.users')) {
        final user = UserModel.fromJson(
          {
            ...Map<String, dynamic>.from(currentUser.userMetadata ?? {}),
            'id': currentUser.id,
            'email': currentUser.email,
          },
          fallbackId: currentUser.id,
          fallbackEmail: currentUser.email,
        );
        return LocationLabelRepository.enrichUser(user);
      }
      rethrow;
    }
    if (row != null) {
      final user = UserModel.fromJson(
        Map<String, dynamic>.from(row),
        fallbackId: currentUser.id,
        fallbackEmail: currentUser.email,
      );
      return LocationLabelRepository.enrichUser(user);
    }

    final user = UserModel.fromJson(
      {
        ...Map<String, dynamic>.from(currentUser.userMetadata ?? {}),
        'id': currentUser.id,
        'email': currentUser.email,
      },
      fallbackId: currentUser.id,
      fallbackEmail: currentUser.email,
    );
    return LocationLabelRepository.enrichUser(user);
  }

  Map<String, dynamic> _bookToRow(BookModel book) {
    final serializedBook = book.toJson();
    return {
      'image_base64': book.primaryImageUrl ?? serializedBook['imageBase64'],
      'image_urls': book.resolvedImageUrls,
      'title': book.title.trim(),
      'author': book.author.trim(),
      'category': book.category.trim(),
      'price': book.price.trim(),
      'description': book.description.trim(),
      'seller_id': book.sellerId,
      'seller_name': book.sellerName,
      'seller_email': book.sellerEmail,
      'seller_phone': book.sellerPhone,
      'seller_location': book.sellerLocation,
      'seller_latitude': book.sellerLatitude,
      'seller_longitude': book.sellerLongitude,
    };
  }

  Future<BookModel> _prepareBookForPersistence(
    BookModel book, {
    required String ownerId,
  }) async {
    final imageUrls = await _resolveBookImageUrls(book, ownerId: ownerId);
    if (imageUrls.isEmpty) {
      return book;
    }

    final imageModels = [
      for (final imageUrl in imageUrls) BookImageModel(url: imageUrl),
    ];
    return book.copyWith(
      imageUrl: imageUrls.first,
      images: imageModels,
      clearImageBase64: true,
    );
  }

  Future<List<String>> _resolveBookImageUrls(
    BookModel book, {
    required String ownerId,
  }) async {
    final galleryImages = book.galleryImages;
    if (galleryImages.isEmpty) {
      return const [];
    }

    final galleryKey = book.id.trim().isEmpty
        ? DateTime.now().microsecondsSinceEpoch.toString()
        : book.id.trim();
    final imageUrls = <String>[];

    for (var index = 0; index < galleryImages.length; index++) {
      final image = galleryImages[index];
      final imageBytes = image.resolvedBytes;
      if (imageBytes != null && imageBytes.isNotEmpty) {
        final objectName = _buildBookImageObjectName(
          ownerId: ownerId,
          galleryKey: galleryKey,
          index: index,
        );

        await _resolvedClient.storage
            .from(_bookImagesBucket)
            .uploadBinary(
              objectName,
              imageBytes,
              fileOptions: const FileOptions(upsert: true),
            );

        imageUrls.add(
          _resolvedClient.storage
              .from(_bookImagesBucket)
              .getPublicUrl(objectName),
        );
        continue;
      }

      final imageUrl = image.resolvedUrl;
      if (imageUrl != null) {
        imageUrls.add(imageUrl);
      }
    }

    return imageUrls.take(BookModel.maxImages).toList(growable: false);
  }

  String _buildBookImageObjectName({
    required String ownerId,
    required String galleryKey,
    required int index,
  }) {
    return '$ownerId.book.$galleryKey.$index.jpg';
  }

  void _replaceBooks(List<BookModel> books) {
    _books
      ..clear()
      ..addAll(books);
  }
}

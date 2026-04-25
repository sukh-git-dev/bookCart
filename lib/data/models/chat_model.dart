class ChatThreadModel {
  const ChatThreadModel({
    required this.id,
    required this.bookId,
    required this.bookTitle,
    required this.bookPrice,
    required this.buyerId,
    required this.sellerId,
    required this.buyerName,
    required this.sellerName,
    this.lastMessage = '',
    this.lastSenderId = '',
    this.updatedAt,
  });

  final String id;
  final String bookId;
  final String bookTitle;
  final String bookPrice;
  final String buyerId;
  final String sellerId;
  final String buyerName;
  final String sellerName;
  final String lastMessage;
  final String lastSenderId;
  final DateTime? updatedAt;

  bool isSeller(String userId) => sellerId == userId;

  String displayNameFor(String userId) =>
      isSeller(userId) ? buyerName : sellerName;

  String statusFor(String userId) =>
      isSeller(userId) ? 'Buyer inquiry' : 'Seller chat';

  String get priceTag =>
      bookPrice.trim().isEmpty ? 'Book chat' : 'Rs $bookPrice';

  String get displayLastMessage =>
      lastMessage.trim().isEmpty ? 'Start the conversation.' : lastMessage;

  String get displayTime {
    final updated = updatedAt;
    if (updated == null) {
      return 'Now';
    }

    final now = DateTime.now();
    final difference = now.difference(updated);
    if (difference.inMinutes < 1) {
      return 'Now';
    }
    if (difference.inHours < 1) {
      return '${difference.inMinutes}m';
    }
    if (difference.inDays < 1) {
      return '${difference.inHours}h';
    }
    if (difference.inDays == 1) {
      return 'Yesterday';
    }
    if (difference.inDays < 7) {
      return '${difference.inDays}d';
    }

    return '${updated.day}/${updated.month}/${updated.year}';
  }

  factory ChatThreadModel.fromJson(
    Map<String, dynamic> json, {
    required String fallbackId,
  }) {
    return ChatThreadModel(
      id: json['id'] as String? ?? fallbackId,
      bookId: json['bookId'] as String? ?? json['book_id'] as String? ?? '',
      bookTitle:
          json['bookTitle'] as String? ??
          json['book_title'] as String? ??
          'Book listing',
      bookPrice:
          json['bookPrice'] as String? ?? json['book_price'] as String? ?? '',
      buyerId: json['buyerId'] as String? ?? json['buyer_id'] as String? ?? '',
      sellerId:
          json['sellerId'] as String? ?? json['seller_id'] as String? ?? '',
      buyerName:
          json['buyerName'] as String? ??
          json['buyer_name'] as String? ??
          'Buyer',
      sellerName:
          json['sellerName'] as String? ??
          json['seller_name'] as String? ??
          'Seller',
      lastMessage:
          json['lastMessage'] as String? ??
          json['last_message'] as String? ??
          '',
      lastSenderId:
          json['lastSenderId'] as String? ??
          json['last_sender_id'] as String? ??
          '',
      updatedAt: _dateTimeFromJson(json['updatedAt'] ?? json['updated_at']),
    );
  }
}

class ChatMessageModel {
  const ChatMessageModel({
    required this.id,
    required this.text,
    required this.senderId,
    this.createdAt,
  });

  final String id;
  final String text;
  final String senderId;
  final DateTime? createdAt;

  String get displayTime {
    final created = createdAt;
    if (created == null) {
      return 'Now';
    }

    final hour = created.hour % 12 == 0 ? 12 : created.hour % 12;
    final minute = created.minute.toString().padLeft(2, '0');
    final period = created.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  factory ChatMessageModel.fromJson(
    Map<String, dynamic> json, {
    required String fallbackId,
  }) {
    return ChatMessageModel(
      id: json['id'] as String? ?? fallbackId,
      text: json['text'] as String? ?? '',
      senderId:
          json['senderId'] as String? ?? json['sender_id'] as String? ?? '',
      createdAt: _dateTimeFromJson(json['createdAt'] ?? json['created_at']),
    );
  }
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

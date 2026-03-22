class BookAutofillUtils {
  static String normalizeTitleFromImageName(String imageName) {
    final normalized = imageName
        .replaceAll(RegExp(r'\.[^.]+$'), '')
        .replaceAll(RegExp(r'[_-]+'), ' ')
        .trim();
    final cleaned = normalized.isEmpty ? 'Book Cover' : normalized;
    return cleaned
        .split(' ')
        .where((part) => part.isNotEmpty)
        .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
  }

  const BookAutofillUtils._();
}

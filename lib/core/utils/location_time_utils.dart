String formatLocationRefreshTime(DateTime? value) {
  if (value == null) {
    return 'Location not synced yet';
  }

  final localValue = value.toLocal();
  final timeLabel = _formatClock(localValue);
  final monthLabel = _monthLabel(localValue.month);
  return 'Updated on ${localValue.day} $monthLabel ${localValue.year} at $timeLabel';
}

String _formatClock(DateTime value) {
  final normalizedHour = value.hour % 12 == 0 ? 12 : value.hour % 12;
  final minute = value.minute.toString().padLeft(2, '0');
  final period = value.hour >= 12 ? 'PM' : 'AM';
  return '$normalizedHour:$minute $period';
}

String _monthLabel(int month) {
  const monthLabels = <String>[
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  return monthLabels[month - 1];
}

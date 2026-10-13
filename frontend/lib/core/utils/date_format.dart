/// Shared formatting helpers for dates and times, keeping receipts, order
/// history and order detail views consistent.
abstract final class DateTimeFormat {
  /// Formats a [DateTime] as `DD/MM/YYYY`.
  static String date(DateTime dateTime) {
    return '${dateTime.day.toString().padLeft(2, '0')}/'
        '${dateTime.month.toString().padLeft(2, '0')}/'
        '${dateTime.year}';
  }

  /// Formats a [DateTime] as a 12-hour time `h:mm AM|PM`.
  static String time(DateTime dateTime) {
    final hour = dateTime.hour % 12 == 0 ? 12 : dateTime.hour % 12;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = dateTime.hour < 12 ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }
}

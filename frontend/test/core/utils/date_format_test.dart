// Unit tests for the shared date/time formatting helpers.
import 'package:flutter_test/flutter_test.dart';

import 'package:smartkart/core/utils/date_format.dart';

void main() {
  group('DateTimeFormat.date', () {
    test('pads day and month with leading zeros', () {
      expect(DateTimeFormat.date(DateTime(2026, 3, 5)), '05/03/2026');
    });

    test('does not pad two-digit values', () {
      expect(DateTimeFormat.date(DateTime(2025, 12, 25)), '25/12/2025');
    });
  });

  group('DateTimeFormat.time', () {
    test('formats morning as AM', () {
      expect(DateTimeFormat.time(DateTime(2026, 3, 5, 9, 5)), '9:05 AM');
    });

    test('formats afternoon as PM', () {
      expect(DateTimeFormat.time(DateTime(2026, 3, 5, 14, 30)), '2:30 PM');
    });

    test('midnight maps to 12 AM', () {
      expect(DateTimeFormat.time(DateTime(2026, 3, 5, 0, 0)), '12:00 AM');
    });

    test('noon maps to 12 PM', () {
      expect(DateTimeFormat.time(DateTime(2026, 3, 5, 12, 0)), '12:00 PM');
    });
  });
}

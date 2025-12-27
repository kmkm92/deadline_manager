import 'package:flutter_test/flutter_test.dart';
import 'package:deadline_manager/utils/date_logic.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('ja');
  });

  group('DateLogic Tests', () {
    test('Calculates next daily date correctly', () {
      final current = DateTime(2023, 1, 1, 10, 0);
      final next = DateLogic.calculateNextDate(current, 'daily');
      expect(next, DateTime(2023, 1, 2, 10, 0));
    });

    test('Calculates next weekly date correctly', () {
      final current = DateTime(2023, 1, 1, 10, 0);
      final next = DateLogic.calculateNextDate(current, 'weekly');
      expect(next, DateTime(2023, 1, 8, 10, 0));
    });

    test('Calculates next monthly date correctly (standard)', () {
      final current = DateTime(2023, 1, 15, 10, 0);
      final next = DateLogic.calculateNextDate(current, 'monthly');
      expect(next, DateTime(2023, 2, 15, 10, 0));
    });

    test('Calculates next monthly date correctly (year rollover)', () {
      final current = DateTime(2023, 12, 15, 10, 0);
      final next = DateLogic.calculateNextDate(current, 'monthly');
      expect(next, DateTime(2024, 1, 15, 10, 0));
    });

    test('Calculates next monthly date correctly (month overflow)', () {
      // 修正後: Jan 31 -> Feb 28 (オーバーフローせずに月末に調整)
      // 2023年は閏年ではないので、2月は28日まで
      final current = DateTime(2023, 1, 31, 10, 0);
      final next = DateLogic.calculateNextDate(current, 'monthly');
      expect(next, DateTime(2023, 2, 28, 10, 0));
    });

    test('Calculates next yearly date correctly', () {
      final current = DateTime(2023, 1, 1, 10, 0);
      final next = DateLogic.calculateNextDate(current, 'yearly');
      expect(next, DateTime(2024, 1, 1, 10, 0));
    });

    test('Calculates next yearly date correctly (leap year)', () {
      final current = DateTime(2020, 2, 29, 10, 0); // Leap day
      final next = DateLogic.calculateNextDate(current, 'yearly');
      // 2021 is not a leap year, so Feb 29 doesn't exist.
      // Dart DateTime: 2021-02-29 -> 2021-03-01
      expect(next, DateTime(2021, 3, 1, 10, 0));
    });

    test('Default to daily for unknown interval', () {
      final current = DateTime(2023, 1, 1, 10, 0);
      final next = DateLogic.calculateNextDate(current, 'unknown');
      expect(next, DateTime(2023, 1, 2, 10, 0));
    });
  });

  group('DateLogic Formatting Tests', () {
    test('formatToJapanese formats correctly', () {
      final date = DateTime(2023, 10, 27, 14, 30);
      // DateFormat.yMMMEd('ja').add_jm() format: "2023年10月27日(金) 14:30"
      // Note: The exact string depends on the locale data and implementation.
      // We'll verify it contains key components.
      final formatted = DateLogic.formatToJapanese(date);
      expect(formatted, contains('2023年10月27日'));
      expect(formatted, contains('14:30'));
    });
  });
}

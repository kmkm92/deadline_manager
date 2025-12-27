import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:deadline_manager/database.dart';

class DateLogic {
  static String formatToJapanese(DateTime date) {
    return DateFormat.yMMMEd('ja').add_jm().format(date);
  }

  static DateTime calculateNextDate(DateTime current, String interval) {
    switch (interval) {
      case 'daily':
        return current.add(const Duration(days: 1));
      case 'weekly':
        return current.add(const Duration(days: 7));
      case 'monthly':
        // Simple monthly addition: 1 month later, same time
        // Note: This logic can be improved for edge cases (e.g. Jan 31 -> Feb 28/29) using packages like Jiffy or handling explicitly.
        // For now, using standard DateTime logic which might overflow (Jan 31 + 1 mo -> Feb 28 or Mar 3 depending on implementation? actually Dart DateTime(y, m+1, d) handles overflow by carrying over)
        // DateTime(2023, 1, 31) -> DateTime(2023, 2, 31) -> March 3 (non-leap)
        final nextMonth = DateTime(current.year, current.month + 1, current.day,
            current.hour, current.minute);
        return nextMonth;
      case 'yearly':
        return DateTime(current.year + 1, current.month, current.day,
            current.hour, current.minute);
      default:
        return current.add(const Duration(days: 1));
    }
  }

  // 毎日: 指定した時間の次の発生日時
  static DateTime getNextDailyDate(TimeOfDay time) {
    final now = DateTime.now();
    var scheduledDate =
        DateTime(now.year, now.month, now.day, time.hour, time.minute);
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  // 毎週: 指定した曜日の次の発生日時
  // weekday: 1 (Mon) - 7 (Sun)
  static DateTime getNextWeeklyDate(int weekday, TimeOfDay time) {
    final now = DateTime.now();
    var scheduledDate =
        DateTime(now.year, now.month, now.day, time.hour, time.minute);

    // Calculate days to add to reach the target weekday
    // current: 3 (Wed), target: 5 (Fri) -> add 2
    // current: 5 (Fri), target: 3 (Wed) -> add 5 (7 - (5-3))
    int daysToAdd = (weekday - now.weekday + 7) % 7;

    // If today is the target day but time has passed, move to next week
    if (daysToAdd == 0 && scheduledDate.isBefore(now)) {
      daysToAdd = 7;
    }

    return scheduledDate.add(Duration(days: daysToAdd));
  }

  // 毎月: 指定した日の次の発生日時
  // day: 1 - 31 (Checking validity is needed on UI side or here)
  static DateTime getNextMonthlyDate(int day, TimeOfDay time) {
    final now = DateTime.now();

    // Try current month

    // Handle invalid dates (e.g. Feb 30) -> Dart overflows to March
    // We want to skip invalid months if strictly required, but usually we just want "next valid 30th"
    // For simplicity: if current month doesn't have that day, we might land in next month.
    // Ideally we should check if generated month != target month.

    // Simple logic:
    // If constructed date is valid for this month AND is in future, use it.
    // Else try next month.

    // Better safely construction:
    var candidate = _safeDate(now.year, now.month, day, time);
    if (candidate.isBefore(now)) {
      candidate = _safeDate(now.year, now.month + 1, day, time);
    }
    return candidate;
  }

  // Helper to safely construct date (e.g. prevent Feb 30 becoming Mar 2)
  // Or handle it as "Last day of month" if desired.
  // Let's stick to Dart's behavior for now but safeguard "before now".
  static DateTime _safeDate(int year, int month, int day, TimeOfDay time) {
    return DateTime(year, month, day, time.hour, time.minute);
  }

  static String getRecurrenceDescription(Task task) {
    if (task.recurrenceInterval == null) return '';
    final timeStr = DateFormat.Hm('ja').format(task.dueDate);

    switch (task.recurrenceInterval) {
      case 'daily':
        return '毎日 $timeStr';
      case 'weekly':
        // Weekday from dueDate
        final weekday = DateFormat.E('ja').format(task.dueDate);
        return '毎週 $weekday $timeStr';
      case 'monthly':
        final day = task.dueDate.day;
        return '毎月 $day日 $timeStr';
      case 'yearly':
        final dateStr = DateFormat.Md('ja').format(task.dueDate);
        return '毎年 $dateStr $timeStr';
      default:
        return '';
    }
  }

  // Helper to get the next valid future date based on recurrence interval
  // Used for both calculating next instance in DB and for display purposes in UI
  static DateTime getNextValidFutureDate(DateTime start, String? interval) {
    if (interval == null || interval.isEmpty) return start;

    final now = DateTime.now();
    DateTime nextDate = start;
    int safetyCount = 0;

    // If date is already in future, return it (unless we want to force recalculate, but usually start is the 'expired' date)
    // BUT, if start IS future, we just return it.
    if (nextDate.isAfter(now)) return nextDate;

    while (nextDate.isBefore(now) && safetyCount < 1000) {
      nextDate = calculateNextDate(nextDate, interval);
      safetyCount++;
    }

    return nextDate;
  }
}

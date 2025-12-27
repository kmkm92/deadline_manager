import 'package:intl/intl.dart';

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
        // Handling month overflow is automatic in DateTime (e.g., Month 13 -> Year+1 Month 1)
        // Note: Jan 31 -> Feb 31 -> March 3 (approx). Simple logic for now.
        return DateTime(current.year, current.month + 1, current.day,
            current.hour, current.minute);
      case 'yearly':
        return DateTime(current.year + 1, current.month, current.day,
            current.hour, current.minute);
      default:
        return current.add(const Duration(days: 1));
    }
  }
}

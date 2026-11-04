import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

class DailyShareHelper {
  static const _monthNames = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  /// Formats date as e.g. "31 Oct 2026".
  static String formatDate(DateTime date) {
    final day = date.day.toString();
    final month = _monthNames[date.month - 1];
    final year = date.year.toString();
    return '$day $month $year';
  }

  /// Formats time in seconds as "MM:SS".
  static String formatTime(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// Generates the standard shareable message.
  static String generateShareText({
    required DateTime date,
    required int timeSeconds,
    required int hintsUsed,
    required int streakDays,
  }) {
    final dateStr = formatDate(date);
    final timeStr = formatTime(timeSeconds);
    final streakLabel = streakDays == 1 ? '1 day' : '$streakDays days';

    return '''🐶 SnapDog Daily Challenge
📅 $dateStr
⏱️ Time: $timeStr
💡 Hints: $hintsUsed
🔥 Streak: $streakLabel

Can you solve today's puzzle?''';
  }

  /// Shares the completion result using native share dialog,
  /// with automatic fallback to clipboard copy.
  static Future<bool> shareResult({
    required DateTime date,
    required int timeSeconds,
    required int hintsUsed,
    required int streakDays,
  }) async {
    final text = generateShareText(
      date: date,
      timeSeconds: timeSeconds,
      hintsUsed: hintsUsed,
      streakDays: streakDays,
    );

    // Also copy to clipboard so player has it ready immediately
    try {
      await Clipboard.setData(ClipboardData(text: text));
    } catch (_) {}

    try {
      final result = await SharePlus.instance.share(
        ShareParams(text: text, subject: 'SnapDog Daily Challenge - ${formatDate(date)}'),
      );
      return result.status == ShareResultStatus.success;
    } catch (_) {
      // Fallback: clipboard was already updated
      return true;
    }
  }
}

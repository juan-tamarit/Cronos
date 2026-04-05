import 'package:cronos/db/activity_dao.dart';
import 'package:cronos/db/database_helper.dart';
import '../models/period_type.dart';

class StatService {
  final ActivityDao _activityDao = ActivityDao();

  // ─── Daily metrics ─────────────────────────────────────────────
  Future<int> getTodayTotalSeconds(int activityId) async {
    final db = await DatabaseHelper.instance.database;
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final result = await db.rawQuery('''
      SELECT SUM(durationSecs) as total
      FROM sessions
      WHERE activityId = ? AND start >= ? AND start < ?
    ''', [
      activityId,
      startOfDay.millisecondsSinceEpoch,
      endOfDay.millisecondsSinceEpoch,
    ]);

    return result.first['total'] as int? ?? 0;
  }

  Future<bool> hasCompletedToday(int activityId, int objetiveMinutes) async {
    final todaySeconds = await getTodayTotalSeconds(activityId);
    return todaySeconds >= objetiveMinutes * 60;
  }

  Future<int> getCurrentStreak(int activityId, int objetiveMinutes) async {
    final db = await DatabaseHelper.instance.database;
    final today = DateTime.now();
    final todayKey = today.millisecondsSinceEpoch ~/ 86400000;

    final result = await db.rawQuery('''
      SELECT (start / 86400000) as dayKey, SUM(durationSecs) as total
      FROM sessions
      WHERE activityId = ? AND start <= ?
      GROUP BY dayKey
      ORDER BY dayKey DESC
    ''', [
      activityId,
      today.millisecondsSinceEpoch,
    ]);

    int streak = 0;
    int expectedDayKey = todayKey;

    for (final row in result) {
      final dayKey = (row['dayKey'] as num).toInt();
      final total = row['total'] as int? ?? 0;

      if (dayKey != expectedDayKey) break;
      if (total >= objetiveMinutes * 60) {
        streak++;
        expectedDayKey--;
      } else {
        break;
      }
    }

    return streak;
  }

  Future<Map<String, dynamic>> getTodayStats(int activityId, int objetiveMinutes) async {
    final todaySeconds = await getTodayTotalSeconds(activityId);
    final completed = todaySeconds >= objetiveMinutes * 60;
    final streak = await getCurrentStreak(activityId, objetiveMinutes);
    final progress = todaySeconds / (objetiveMinutes * 60);

    return {
      'todaySeconds': todaySeconds,
      'completed': completed,
      'streak': streak,
      'progress': progress.clamp(0.0, 1.0),
    };
  }

  // ─── Weekly metrics ───────────────────────────────────────────
  DateTime _startOfCurrentWeek() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return today.subtract(Duration(days: today.weekday - 1));
  }

  Future<int> getCurrentWeekTotal(int activityId) async {
    final db = await DatabaseHelper.instance.database;
    final start = _startOfCurrentWeek();
    final end = start.add(const Duration(days: 7));

    final result = await db.rawQuery('''
      SELECT SUM(durationSecs) as total
      FROM sessions
      WHERE activityId = ? AND start >= ? AND start < ?
    ''', [
      activityId,
      start.millisecondsSinceEpoch,
      end.millisecondsSinceEpoch,
    ]);

    return result.first['total'] as int? ?? 0;
  }

  Future<int> getPreviousWeekTotal(int activityId) async {
    final db = await DatabaseHelper.instance.database;
    final start = _startOfCurrentWeek().subtract(const Duration(days: 7));
    final end = _startOfCurrentWeek();

    final result = await db.rawQuery('''
      SELECT SUM(durationSecs) as total
      FROM sessions
      WHERE activityId = ? AND start >= ? AND start < ?
    ''', [
      activityId,
      start.millisecondsSinceEpoch,
      end.millisecondsSinceEpoch,
    ]);

    return result.first['total'] as int? ?? 0;
  }

  Future<double> getWeeklyAverage(int activityId, int numberOfWeeks) async {
    final db = await DatabaseHelper.instance.database;
    final startOfThisWeek = _startOfCurrentWeek();
    final startOfRange =
        startOfThisWeek.subtract(Duration(days: 7 * (numberOfWeeks - 1)));
    final endOfRange = startOfThisWeek.add(const Duration(days: 7));

    final result = await db.rawQuery('''
      SELECT SUM(durationSecs) as total
      FROM sessions
      WHERE activityId = ? AND start >= ? AND start < ?
    ''', [
      activityId,
      startOfRange.millisecondsSinceEpoch,
      endOfRange.millisecondsSinceEpoch,
    ]);

    final totalSeconds = result.first['total'] as int? ?? 0;
    return totalSeconds / numberOfWeeks;
  }

  Future<List<int>> getLastNWeeksTotals(int activityId, int n) async {
    final db = await DatabaseHelper.instance.database;
    final startOfThisWeek = _startOfCurrentWeek();
    final startOfRange = startOfThisWeek.subtract(Duration(days: 7 * (n - 1)));
    final endOfRange = startOfThisWeek.add(const Duration(days: 7));
    const weekMillis = 7 * 86400000;

    final result = await db.rawQuery('''
      SELECT ((start - ?) / ?) as weekIndex, SUM(durationSecs) as total
      FROM sessions
      WHERE activityId = ? AND start >= ? AND start < ?
      GROUP BY weekIndex
    ''', [
      startOfThisWeek.millisecondsSinceEpoch,
      weekMillis,
      activityId,
      startOfRange.millisecondsSinceEpoch,
      endOfRange.millisecondsSinceEpoch,
    ]);

    List<int> weeklyTotals = List.filled(n, 0);

    for (final row in result) {
      final weekIndex = (row['weekIndex'] as num).toInt();
      final total = row['total'] as int? ?? 0;
      final position = n - 1 + weekIndex;
      if (position >= 0 && position < n) weeklyTotals[position] = total;
    }

    return weeklyTotals;
  }
  Future<List<int>> getCurrentWeekDailyTotals(int activityId) async {
    final db = await DatabaseHelper.instance.database;

    final startOfWeek = _startOfCurrentWeek();
    final endOfWeek = startOfWeek.add(const Duration(days: 7));

    final result = await db.rawQuery('''
      SELECT ((start - ?) / 86400000) as dayIndex,
            SUM(durationSecs) as total
      FROM sessions
      WHERE activityId = ? AND start >= ? AND start < ?
      GROUP BY dayIndex
    ''', [
      startOfWeek.millisecondsSinceEpoch,
      activityId,
      startOfWeek.millisecondsSinceEpoch,
      endOfWeek.millisecondsSinceEpoch,
    ]);

    // Lunes = 0 ... Domingo = 6
    List<int> dailyTotals = List.filled(7, 0);

    for (final row in result) {
      final dayIndex = (row['dayIndex'] as num).toInt();
      final total = row['total'] as int? ?? 0;

      if (dayIndex >= 0 && dayIndex < 7) {
        dailyTotals[dayIndex] = total;
      }
    }

    return dailyTotals;
  }

  Future<List<int>> getGlobalCurrentWeekDailyTotals() async {
    final db = await DatabaseHelper.instance.database;

    final startOfWeek = _startOfCurrentWeek();
    final endOfWeek = startOfWeek.add(const Duration(days: 7));

    final result = await db.rawQuery('''
      SELECT ((start - ?) / 86400000) as dayIndex,
             SUM(durationSecs) as total
      FROM sessions
      WHERE start >= ? AND start < ?
      GROUP BY dayIndex
    ''', [
      startOfWeek.millisecondsSinceEpoch,
      startOfWeek.millisecondsSinceEpoch,
      endOfWeek.millisecondsSinceEpoch,
    ]);

    List<int> dailyTotals = List.filled(7, 0);

    for (final row in result) {
      final dayIndex = (row['dayIndex'] as num).toInt();
      final total = row['total'] as int? ?? 0;

      if (dayIndex >= 0 && dayIndex < 7) {
        dailyTotals[dayIndex] = total;
      }
    }

    return dailyTotals;
  }
  // ─── Monthly metrics ─────────────────────────────────────────
  DateTime _startOfCurrentMonth() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, 1);
  }

  DateTime _startOfNextMonth() {
    final now = DateTime.now();
    return DateTime(now.year, now.month + 1, 1);
  }

  Future<int> getCurrentMonthTotal(int activityId) async {
    final db = await DatabaseHelper.instance.database;
    final start = _startOfCurrentMonth();
    final end = _startOfNextMonth();

    final result = await db.rawQuery('''
      SELECT SUM(durationSecs) as total
      FROM sessions
      WHERE activityId = ? AND start >= ? AND start < ?
    ''', [
      activityId,
      start.millisecondsSinceEpoch,
      end.millisecondsSinceEpoch,
    ]);

    return result.first['total'] as int? ?? 0;
  }

  Future<int> getPreviousMonthTotal(int activityId) async {
    final db = await DatabaseHelper.instance.database;
    final now = DateTime.now();
    final start = DateTime(now.year, now.month - 1, 1);
    final end = DateTime(now.year, now.month, 1);

    final result = await db.rawQuery('''
      SELECT SUM(durationSecs) as total
      FROM sessions
      WHERE activityId = ? AND start >= ? AND start < ?
    ''', [
      activityId,
      start.millisecondsSinceEpoch,
      end.millisecondsSinceEpoch,
    ]);

    return result.first['total'] as int? ?? 0;
  }

  Future<List<int>> getLastNMonthsTotals(int activityId, int n) async {
    final db = await DatabaseHelper.instance.database;
    final now = DateTime.now();
    final startOfRange = DateTime(now.year, now.month - n + 1, 1);
    final endOfRange = DateTime(now.year, now.month + 1, 1);

    final result = await db.rawQuery('''
      SELECT strftime('%Y-%m', start / 1000, 'unixepoch') as month, 
             SUM(durationSecs) as total
      FROM sessions
      WHERE activityId = ? AND start >= ? AND start < ?
      GROUP BY month
      ORDER BY month
    ''', [
      activityId,
      startOfRange.millisecondsSinceEpoch,
      endOfRange.millisecondsSinceEpoch,
    ]);

    List<int> monthlyTotals = List.filled(n, 0);

    for (final row in result) {
      final parts = (row['month'] as String).split('-');
      final year = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final total = row['total'] as int? ?? 0;
      final position = (year - startOfRange.year) * 12 + (month - startOfRange.month);
      if (position >= 0 && position < n) monthlyTotals[position] = total;
    }

    return monthlyTotals;
  }

  Future<List<int>> getCurrentMonthWeeklyTotals(int activityId) async {
    final db = await DatabaseHelper.instance.database;
    final startOfMonth = _startOfCurrentMonth();
    final endOfMonth = _startOfNextMonth();

    final result = await db.rawQuery('''
      SELECT ((CAST(strftime('%d', start / 1000, 'unixepoch', 'localtime') AS INTEGER) - 1) / 7)
          as weekIndex,
             SUM(durationSecs) as total
      FROM sessions
      WHERE activityId = ? AND start >= ? AND start < ?
      GROUP BY weekIndex
      ORDER BY weekIndex
    ''', [
      activityId,
      startOfMonth.millisecondsSinceEpoch,
      endOfMonth.millisecondsSinceEpoch,
    ]);

    List<int> weeklyTotals = List.filled(4, 0);

    for (final row in result) {
      final weekIndex = (row['weekIndex'] as num).toInt();
      final total = row['total'] as int? ?? 0;

      if (weekIndex >= 0 && weekIndex < 4) {
        weeklyTotals[weekIndex] = total;
      } else if (weekIndex >= 4) {
        weeklyTotals[3] += total;
      }
    }

    return weeklyTotals;
  }

  Future<List<int>> getGlobalCurrentMonthWeeklyTotals() async {
    final db = await DatabaseHelper.instance.database;
    final startOfMonth = _startOfCurrentMonth();
    final endOfMonth = _startOfNextMonth();

    final result = await db.rawQuery('''
      SELECT ((CAST(strftime('%d', start / 1000, 'unixepoch', 'localtime') AS INTEGER) - 1) / 7)
          as weekIndex,
             SUM(durationSecs) as total
      FROM sessions
      WHERE start >= ? AND start < ?
      GROUP BY weekIndex
      ORDER BY weekIndex
    ''', [
      startOfMonth.millisecondsSinceEpoch,
      endOfMonth.millisecondsSinceEpoch,
    ]);

    List<int> weeklyTotals = List.filled(4, 0);

    for (final row in result) {
      final weekIndex = (row['weekIndex'] as num).toInt();
      final total = row['total'] as int? ?? 0;

      if (weekIndex >= 0 && weekIndex < 4) {
        weeklyTotals[weekIndex] = total;
      } else if (weekIndex >= 4) {
        weeklyTotals[3] += total;
      }
    }

    return weeklyTotals;
  }

  Future<int> getCurrentYearTotal(int activityId) async {
    final db = await DatabaseHelper.instance.database;
    final start = DateTime(DateTime.now().year, 1, 1);
    final end = DateTime(DateTime.now().year + 1, 1, 1);

    final result = await db.rawQuery('''
      SELECT SUM(durationSecs) as total
      FROM sessions
      WHERE activityId = ? AND start >= ? AND start < ?
    ''', [
      activityId,
      start.millisecondsSinceEpoch,
      end.millisecondsSinceEpoch,
    ]);

    return result.first['total'] as int? ?? 0;
  }

  // ─── Habits metrics ──────────────────────────────────────────
  Future<Map<int, int>> getTimeByWeekDay(int activityId) async {
    final db = await DatabaseHelper.instance.database;

    final result = await db.rawQuery('''
      SELECT strftime('%w', start / 1000, 'unixepoch') as weekday,
             SUM(durationSecs) as total
      FROM sessions
      WHERE activityId = ?
      GROUP BY weekday
    ''', [activityId]);

    Map<int, int> totals = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0, 6: 0, 7: 0};

    for (final row in result) {
      int sqliteWeekday = int.parse(row['weekday'] as String);
      int dartWeekday = sqliteWeekday == 0 ? 7 : sqliteWeekday;
      totals[dartWeekday] = row['total'] as int? ?? 0;
    }

    return totals;
  }

  Future<double> getAverageSessionDuration(int activityId) async {
    final db = await DatabaseHelper.instance.database;

    final result = await db.rawQuery('''
      SELECT SUM(durationSecs) as total, COUNT(*) as count
      FROM sessions
      WHERE activityId = ?
      AND durationSecs > 0
    ''', [activityId]);

    final total = result.first['total'] as int? ?? 0;
    final count = result.first['count'] as int? ?? 0;

    if (count == 0) return 0;

    final avgSeconds = total / count;
    return avgSeconds / 60;
  }

  Future<int> getSessionsCount(int activityId) async {
    final db = await DatabaseHelper.instance.database;

    final result = await db.rawQuery('''
      SELECT COUNT(*) as count
      FROM sessions
      WHERE activityId = ?
      AND durationSecs > 0
    ''', [activityId]);

    return result.first['count'] as int? ?? 0;
  }

  Future<double> getAverageSessionPerDay(int activityId) async {
    final db = await DatabaseHelper.instance.database;

    final result = await db.rawQuery('''
      SELECT COUNT(*) as count, MIN(start) as first
      FROM sessions
      WHERE activityId = ?
      AND durationSecs > 0
    ''', [activityId]);

    final count = result.first['count'] as int? ?? 0;
    final firstMillis = result.first['first'] as int?;

    if (count == 0 || firstMillis == null) return 0;

    final firstDay = DateTime.fromMillisecondsSinceEpoch(firstMillis);
    final today = DateTime.now();

    final daysDifference = today.difference(
      DateTime(firstDay.year, firstDay.month, firstDay.day)
    ).inDays + 1;

    return count / daysDifference;
  }

  // ─── Global metrics ─────────────────────────────────────────
  Future<int> getGlobalTodayTotal() async {
    final db = await DatabaseHelper.instance.database;
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final result = await db.rawQuery('''
      SELECT SUM(durationSecs) as total
      FROM sessions
      WHERE start >= ? AND start < ?
    ''', [
      startOfDay.millisecondsSinceEpoch,
      endOfDay.millisecondsSinceEpoch,
    ]);

    return result.first['total'] as int? ?? 0;
  }

  Future<double> getGlobalTodayCompeltionPercentage() async {
    final todayTotal = await getGlobalTodayTotal();
    final objectivesTotal = await _activityDao.getTotalDailyObjectivesSeconds();
    return objectivesTotal == 0 ? 0 : (todayTotal / objectivesTotal) * 100;
  }
  Future<List<int>> getGlobalLastNWeeksTotals(int n) async {
    final db = await DatabaseHelper.instance.database;

    final startOfThisWeek = _startOfCurrentWeek();
    final startOfRange = startOfThisWeek.subtract(Duration(days: 7 * (n - 1)));
    final endOfRange = startOfThisWeek.add(const Duration(days: 7));

    const weekMillis = 7 * 86400000;

    final result = await db.rawQuery('''
      SELECT ((start - ?) / ?) as weekIndex,
            SUM(durationSecs) as total
      FROM sessions
      WHERE start >= ? AND start < ?
      GROUP BY weekIndex
    ''', [
      startOfThisWeek.millisecondsSinceEpoch,
      weekMillis,
      startOfRange.millisecondsSinceEpoch,
      endOfRange.millisecondsSinceEpoch,
    ]);

    List<int> weeklyTotals = List.filled(n, 0);

    for (final row in result) {
      final weekIndex = (row['weekIndex'] as num).toInt();
      final total = row['total'] as int? ?? 0;
      final position = n - 1 + weekIndex;

      if (position >= 0 && position < n) {
        weeklyTotals[position] = total;
      }
    }

    return weeklyTotals;
  }
  Future<List<int>> getGlobalLastNMonthsTotals(int n) async {
    final db = await DatabaseHelper.instance.database;

    final now = DateTime.now();
    final startOfRange = DateTime(now.year, now.month - n + 1, 1);
    final endOfRange = DateTime(now.year, now.month + 1, 1);

    final result = await db.rawQuery('''
      SELECT strftime('%Y-%m', start / 1000, 'unixepoch') as month,
            SUM(durationSecs) as total
      FROM sessions
      WHERE start >= ? AND start < ?
      GROUP BY month
      ORDER BY month
    ''', [
      startOfRange.millisecondsSinceEpoch,
      endOfRange.millisecondsSinceEpoch,
    ]);

    List<int> monthlyTotals = List.filled(n, 0);

    for (final row in result) {
      final parts = (row['month'] as String).split('-');
      final year = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final total = row['total'] as int? ?? 0;

      final position =
          (year - startOfRange.year) * 12 + (month - startOfRange.month);

      if (position >= 0 && position < n) {
        monthlyTotals[position] = total;
      }
    }

    return monthlyTotals;
  }
  Future<List<int>> getGlobalTotalsForPeriod(PeriodType period) async {
    switch (period) {
      case PeriodType.week:
        return await getGlobalCurrentWeekDailyTotals();

      case PeriodType.month:
        return await getGlobalCurrentMonthWeeklyTotals();

      case PeriodType.threeMonths:
        return await getGlobalLastNMonthsTotals(3);

      case PeriodType.sixMonths:
        return await getGlobalLastNMonthsTotals(6);

      case PeriodType.year:
        return await getGlobalLastNMonthsTotals(12);
    }
  }
  Future<int> getGlobalTotalForPeriod(PeriodType period) async {
    final totals = await getGlobalTotalsForPeriod(period);
    if (totals.isEmpty) return 0;
    return totals.last;
  }
}

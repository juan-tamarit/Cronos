import 'package:cronos/db/session_dao.dart';
import 'package:cronos/db/activity_dao.dart';

class StatService{
  final SessionDao _sessionDao=SessionDao();
  final ActivityDao _activityDao = ActivityDao();
  //Daily metrics
  Future<int> getTodayTotalSeconds(int activityId)async{
    final now=DateTime.now();
    final startOfDay=DateTime(now.year,now.month,now.day);
    final endOfDay=startOfDay.add(const Duration(days:1));

    final sessions=await _sessionDao.getByActivityBetween(activityId, startOfDay, endOfDay);

    return sessions.fold<int>(0,(sum,s)=>sum + s.durationSecs);
  }
  Future<bool> hasCompletedToday(int activityId, int objetiveMinutes)async{
    final todaySeconds= await getTodayTotalSeconds(activityId);
    return todaySeconds>=objetiveMinutes;
  }
  Future<int> getCurrentStreak(int activityId,int objetiveMinutes)async{
    int streak=0;
    DateTime currentDay=DateTime.now();
    while(true){
      final startOfDay=DateTime(currentDay.year,currentDay.month,currentDay.day);
      final endOfDay=startOfDay.add(const Duration(days:1));

      final sessions= await _sessionDao.getByActivityBetween(activityId, startOfDay, endOfDay);
      final totalSeconds= sessions.fold<int>(0,(sum,s)=>sum+s.durationSecs);

      if (totalSeconds>=objetiveMinutes*60){
        streak++;
        currentDay=currentDay.subtract(const Duration(days:1));
      }else{
        break;
      }
    }
    return streak;
  }
  //Weekly metrics
  DateTime _startOfCurrentWeek() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return today.subtract(Duration(days: today.weekday - 1));
  }
  DateTime _endOfCurrentWeek() {
    final start = _startOfCurrentWeek();
    return start.add(const Duration(days: 7));
  }
  Future<int> getCurrentWeekTotal(int activityId) async {
    final startOfWeek = _startOfCurrentWeek();
    final endOfWeek = _endOfCurrentWeek();

    final sessions = await _sessionDao.getByActivityBetween(
      activityId,
      startOfWeek,
      endOfWeek,
    );

    return sessions.fold<int>(0, (sum, s) => sum + s.durationSecs);
  }
  Future<int> getPreviousWeekTotal(int activityId) async {
    final startOfThisWeek = _startOfCurrentWeek();
    final startOfPreviousWeek =
      startOfThisWeek.subtract(const Duration(days: 7));
    final endOfPreviousWeek = startOfThisWeek;

    final sessions = await _sessionDao.getByActivityBetween(
      activityId,
      startOfPreviousWeek,
      endOfPreviousWeek,
    );

    return sessions.fold<int>(0, (sum, s) => sum + s.durationSecs);
  }
  Future<double> getWeeklyAverage(int activityId, int numberOfWeeks) async {
    final startOfThisWeek = _startOfCurrentWeek();
    DateTime startPeriod =
      startOfThisWeek.subtract(Duration(days: 7 * (numberOfWeeks - 1)));
    final endPeriod = startOfThisWeek.add(const Duration(days: 7));

    final sessions = await _sessionDao.getByActivityBetween(
      activityId,
      startPeriod,
      endPeriod,
    );

    final totalSeconds =
      sessions.fold<int>(0, (sum, s) => sum + s.durationSecs);

    return totalSeconds / numberOfWeeks;
  }
  Future<List<int>> getLastNWeeksTotals(int activityId, int n) async {
    final startOfThisWeek = _startOfCurrentWeek();
    List<int> weeklyTotals = [];

    for (int i = n - 1; i >= 0; i--) {
      final startOfWeek =
        startOfThisWeek.subtract(Duration(days: 7 * i));
      final endOfWeek = startOfWeek.add(const Duration(days: 7));

      final sessions = await _sessionDao.getByActivityBetween(
        activityId,
        startOfWeek,
        endOfWeek,
      );

      final total = sessions.fold<int>(0, (sum, s) => sum + s.durationSecs);
      weeklyTotals.add(total);
    }

    return weeklyTotals;
  }
  //Monthly metrics
  DateTime _startOfCurrentMonth() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, 1);
  }

  DateTime _startOfNextMonth() {
    final now = DateTime.now();
    return DateTime(now.year, now.month + 1, 1);
  }

  DateTime _startOfCurrentYear() {
    final now = DateTime.now();
    return DateTime(now.year, 1, 1);
  }

  DateTime _startOfNextYear() {
    final now = DateTime.now();
    return DateTime(now.year + 1, 1, 1);
  }
  Future<int> getCurrentMonthTotal(int activityId) async {
    final startOfMonth = _startOfCurrentMonth();
    final startOfNextMonth = _startOfNextMonth();

    final sessions = await _sessionDao.getByActivityBetween(
      activityId,
      startOfMonth,
      startOfNextMonth,
    );

    return sessions.fold<int>(0, (sum, s) => sum + s.durationSecs);
  }
  Future<int> getPreviousMonthTotal(int activityId) async {
    final now = DateTime.now();

    final startOfCurrentMonth = DateTime(now.year, now.month, 1);
    final startOfPreviousMonth =
        DateTime(now.year, now.month - 1, 1);

    final sessions = await _sessionDao.getByActivityBetween(
      activityId,
      startOfPreviousMonth,
      startOfCurrentMonth,
    );

    return sessions.fold<int>(0, (sum, s) => sum + s.durationSecs);
  }
  Future<List<int>> getLastNMonthsTotals(int activityId, int n) async {
    final now = DateTime.now();
    List<int> monthlyTotals = [];

    for (int i = n - 1; i >= 0; i--) {
      final startOfMonth =
          DateTime(now.year, now.month - i, 1);
      final startOfNextMonth =
          DateTime(now.year, now.month - i + 1, 1);

      final sessions = await _sessionDao.getByActivityBetween(
        activityId,
        startOfMonth,
        startOfNextMonth,
      );

      final total =
          sessions.fold<int>(0, (sum, s) => sum + s.durationSecs);

      monthlyTotals.add(total);
    }

    return monthlyTotals;
  }
  Future<int> getCurrentYearTotal(int activityId) async {
    final startOfYear = _startOfCurrentYear();
    final startOfNextYear = _startOfNextYear();

    final sessions = await _sessionDao.getByActivityBetween(
      activityId,
      startOfYear,
      startOfNextYear,
    );

    return sessions.fold<int>(0, (sum, s) => sum + s.durationSecs);
  }
  //Habits metrics
  Future<Map<int, int>> getTimeByWeekDay(int activityId) async {
    final sessions = await _sessionDao.getByActivity(activityId);

    Map<int, int> result = {
      1: 0,
      2: 0,
      3: 0,
      4: 0,
      5: 0,
      6: 0,
      7: 0,
    };

    for (var s in sessions) {
      final weekday = s.start.weekday;
      result[weekday] = result[weekday]! + s.durationSecs;
    }

    return result;
  }
  Future<double> getAverageSessionDuration(int activityId) async {
    final sessions = await _sessionDao.getByActivity(activityId);

    if (sessions.isEmpty) return 0;

    final totalSeconds =
        sessions.fold<int>(0, (sum, s) => sum + s.durationSecs);

    return totalSeconds / sessions.length;
  }
  Future<int> getSessionsCount(int activityId) async {
    final sessions = await _sessionDao.getByActivity(activityId);
    return sessions.length;
  }
  Future<double> getAverageSessionPerDay(int activityId) async {
    final sessions = await _sessionDao.getByActivity(activityId);

    if (sessions.isEmpty) return 0;

    final firstSession = sessions.last; // están ordenadas DESC
    final firstDay = DateTime(
      firstSession.start.year,
      firstSession.start.month,
      firstSession.start.day,
    );

    final today = DateTime.now();
    final daysDifference =
        today.difference(firstDay).inDays + 1;

    return sessions.length / daysDifference;
  }
  //Global
  Future<int> getGlobalTodayTotal() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final sessions = await _sessionDao.getAll();

    return sessions
        .where((s) =>
            s.start.isAfter(startOfDay) &&
            s.start.isBefore(endOfDay))
        .fold<int>(0, (sum, s) => sum + s.durationSecs);
  }
  Future<double> getGlobalTodayCompeltionPercentage() async {
    final todayTotal = await getGlobalTodayTotal();
    final objectivesTotal =
        await _activityDao.getTotalDailyObjectivesSeconds();

    if (objectivesTotal == 0) return 0;

    return (todayTotal / objectivesTotal) * 100;
  }
}
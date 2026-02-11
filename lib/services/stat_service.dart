import 'package:cronos/db/session_dao.dart';

class StatService{
  final SessionDao _sessionDao=SessionDao();
  //Daily metrics
  Future<int> getTodayTotalSeconds(int activityId)async{
    final now=DateTime.now();
    final startOfDay=DateTime(now.year,now.month,now.day);
    final endOfDay=startOfDay.add(const Duration(days:1));

    final sessions=await _sessionDao.getByActivityBetween(activityId, startOfDay, endOfDay);

    return sessions.fold<int>(0,(sum,s)=>sum + s.durationSecs);
  }
  Future<bool> hasCompletedToday(int activityId, int objetiveMinutes){}
  Future<int> getCurrentStreak(int activity,int objetiveMinutes){}
  //Weekly metrics
  Future<int> getCurrentWeekTotal(int activityId){}
  Future<int> getPreviousWeekTotal(int activityId){}
  Future<double> getWeeklyAverage(int activityId, int numberOfWeeks){}
  Future<List> getLastNweeksTotals(int activityId, int n){}
  //Monthly metrics
  Future<int> getCurrentMonthTotal(int activityId){}
  Future<int> getCurrentYearTotal(int activityId){}
  //Habits metrics
  Future<Map<int,int>> getTimeByWeekDay(int activityId){}
  Future<double>  getAverageSessionDuration(int activityId){}
  Future<int> getSessionsCount (int activityId){}
  Future<double> getAverageSessionPerDay(int activity){}
  //Global
  Future<int> getGlobalTodayTotal(){}
  Future<int> getGlobalTodayCompeltionPercentage(){}
}
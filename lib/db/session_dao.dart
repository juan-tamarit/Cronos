import 'package:sqflite/sqflite.dart';
import '../models/session.dart';
import 'database_helper.dart';

class SessionDao {
  Future<int> insert(Session session) async{
    final db= await DatabaseHelper.instance.database;
    return await db.insert('sessions', session.toMap());
  }
  Future<List<Session>> getByActivity(int activityId) async{
    final db= await DatabaseHelper.instance.database;
    final List<Map<String,dynamic>> maps= await db.query(
      'sessions',
      where: 'activityId=?',
      whereArgs: [activityId],
      orderBy: 'start DESC'
    );
    return maps.map((m)=>Session.fromMap(m)).toList();
  }
  Future<int> delete (int id) async{
    final db= await DatabaseHelper.instance.database;
    return await db.delete(
      'sessions',
      where: 'id=?',
      whereArgs: [id],
    );
  }
  Future<int> getTotalSecondsForActivity(int activityId) async {
    final db = await DatabaseHelper.instance.database;

    final result = await db.rawQuery(
      'SELECT SUM(duration_secs) as total FROM sessions WHERE activity_id = ?',
      [activityId],
    );

    final total = result.first['total'];
    return total == null ? 0 : total as int;
  }
}
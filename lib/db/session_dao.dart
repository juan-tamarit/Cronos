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
  Future<int> getAccumulatedSecondsForActivity(int activityId) async {
    final db = await DatabaseHelper.instance.database;

    final result = await db.query(
      'sessions',
      columns: ['accumulatedSecs'],
      where: 'activityId = ?',
      whereArgs: [activityId],
      orderBy: 'end DESC',
      limit: 1,
    );

    if (result.isEmpty) return 0;

    return result.first['accumulatedSecs'] as int;
  }
    Future<Session?> getLastSession(int activityId) async {
    final db = await DatabaseHelper.instance.database;

    final maps = await db.query(
      'sessions',
      where: 'activityId = ?',
      whereArgs: [activityId],
      orderBy: 'end DESC',
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return Session.fromMap(maps.first);
  }
}
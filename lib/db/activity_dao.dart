import 'package:sqflite/sqflite.dart';
import '../models/activity.dart';
import 'database_helper.dart';

class ActivityDao {

  /// Insertar una nueva actividad
  Future<int> insert(Activity activity) async {
    final db = await DatabaseHelper.instance.database;
    return await db.insert('activities', activity.toMap());
  }

  /// Obtener todas las actividades
  Future<List<Activity>> getAll() async {
    final db = await DatabaseHelper.instance.database;

    final List<Map<String, dynamic>> maps = await db.query(
      'activities',
      orderBy: 'name ASC'
    );

    return maps.map((m) => Activity.fromMap(m)).toList();
  }
  /// Obtener todas las actividades por su id
  Future <Activity?> getById(int id) async{
    final db = await DatabaseHelper.instance.database;

    final maps= await db.query(
      'activities',
      where:'id=?',
      whereArgs:[id]);
    if(maps.isNotEmpty){
      return Activity.fromMap(maps.first);
    }
    return null;
  }
  /// Obtener solo actividades activas
  Future<List<Activity>> getActive() async {
    final db = await DatabaseHelper.instance.database;

    final List<Map<String, dynamic>> maps = await db.query(
      'activities',
      where: 'active = ?',
      whereArgs: [1],
      orderBy: 'name ASC'
    );

    return maps.map((m) => Activity.fromMap(m)).toList();
  }

  /// Actualizar una actividad
  Future<int> update(Activity activity) async {
    final db = await DatabaseHelper.instance.database;

    return await db.update(
      'activities',
      activity.toMap(),
      where: 'id = ?',
      whereArgs: [activity.id]
    );
  }

  /// Borrado lógico (desactivar)
  Future<int> deactivate(int id) async {
    final db = await DatabaseHelper.instance.database;

    return await db.update(
      'activities',
      {'active': 0},
      where: 'id = ?',
      whereArgs: [id]
    );
  }

  /// Borrado físico
  Future<int> delete(int id) async {
    final db = await DatabaseHelper.instance.database;

    return await db.delete(
      'activities',
      where: 'id = ?',
      whereArgs: [id]
    );
  }
}
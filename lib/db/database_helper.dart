import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance=DatabaseHelper._internal();
  static Database? _database;
  DatabaseHelper._internal();

  Future <Database> get database async{
    if (_database!=null) return _database!;
    _database=await _initDatabase();
    return _database!;
  }
  Future <Database> _initDatabase() async {
    final dbPath= await getDatabasesPath();
    final path= join (dbPath,'cronometros.db');

    return await openDatabase(
      path,
      version:1,
      onCreate: _onCreate
    );
  }
  Future <void> _onCreate(Database db, int version) async{
    await db.execute('''
      CREATE TABLE activities (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        description TEXT,
        objetiveMinutes INTEGER NOT NULL,
        daysWeek TEXT NOT NULL,
        active INTEGER NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE sessions(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      activityId INTEGER NOT NULL,
      start INTEGER NOT NULL,
      end INTEGER NOT NULL,
      durationSecs INTEGER NOT NULL,
      accumulatedSecs INTEGER NOT NULL,
      FOREIGN KEY(activityId) REFERENCES activities (id)
      )
    ''');
    await db.execute('CREATE INDEX idx_sessions_start ON sessions(start)');
    await db.execute('CREATE INDEX idx_sessions_activity_start ON sessions(activityId, start)');
  }
  Future <int> insertActivity(Map<String,dynamic> activityMap) async {
    final db= await database;
    return await(db.insert('activities',activityMap));
  }
  Future <List<Map<String,dynamic>>> getActivities() async{
    final db= await database;
    return await(db.query('activities'));
  }
  Future <int> insertSession(Map<String,dynamic> sessionMap) async {
    final db= await database;
    return await (db.insert('sessions',sessionMap));
  }
  Future <List<Map<String,dynamic>>> getSessionsByActivity(int activityId) async{
    final db= await database;
    return await db.query(
      'sessions',
      where:'activityId=?',
      whereArgs: [activityId]
    );
  }
}
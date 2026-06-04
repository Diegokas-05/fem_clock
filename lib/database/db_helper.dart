import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/daily_log.dart';

class DBHelper {
  static final DBHelper instance = DBHelper._init();
  static Database? _database;

  DBHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    // CAMBIO: Cambiamos el nombre a v3 para que SQLite aplique la nueva columna 'hasHeart' 
    // sin que te genere conflictos ni crasheos con datos viejos en tu teléfono.
    _database = await _initDB('femclock_v3.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE daily_logs (
        userId TEXT,
        date TEXT,
        flow TEXT,
        mood TEXT,
        symptoms TEXT,
        hasHeart INTEGER DEFAULT 0, -- NUEVO: Columna para el corazón (0 = Falso, 1 = Verdadero)
        PRIMARY KEY (userId, date)
      )
    ''');
  }

  Future<int> insertOrUpdateLog(DailyLog log) async {
    final db = await instance.database;
    return await db.insert(
      'daily_logs',
      log.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Filtrado por cuenta de usuaria
  Future<DailyLog?> getLogByDate(String date, String userId) async {
    final db = await instance.database;
    final maps = await db.query(
      'daily_logs',
      where: 'date = ? AND userId = ?',
      whereArgs: [date, userId],
    );
    if (maps.isNotEmpty) return DailyLog.fromMap(maps.first);
    return null;
  }

  // Historial solo de la usuaria logueada
  Future<List<DailyLog>> getAllLogs(String userId) async {
    final db = await instance.database;
    final result = await db.query('daily_logs', where: 'userId = ?', whereArgs: [userId], orderBy: 'date DESC');
    return result.map((json) => DailyLog.fromMap(json)).toList();
  }

  // Eliminar registro
  Future<int> deleteLog(String date, String userId) async {
    final db = await instance.database;
    return await db.delete(
      'daily_logs',
      where: 'date = ? AND userId = ?',
      whereArgs: [date, userId],
    );
  }
}
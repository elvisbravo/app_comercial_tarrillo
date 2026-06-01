import 'dart:async';
import 'dart:convert';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  static const _dbName = 'comercial_tarrillo.db';
  static const _dbVersion = 1;

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _open();
    return _db!;
  }

  Future<Database> _open() async {
    final dir = await getApplicationDocumentsDirectory();
    final path = p.join(dir.path, _dbName);
    return openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE cache_venta_data (
        key TEXT PRIMARY KEY,
        data TEXT NOT NULL,
        cached_at INTEGER NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE cache_cobros_data (
        key TEXT PRIMARY KEY,
        data TEXT NOT NULL,
        cached_at INTEGER NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE pending_operations (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        id_local TEXT UNIQUE NOT NULL,
        tipo TEXT NOT NULL,
        endpoint TEXT NOT NULL,
        payload TEXT NOT NULL,
        estado TEXT NOT NULL,
        server_id INTEGER,
        intentos INTEGER DEFAULT 0,
        last_error TEXT,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');
    await db.execute(
        'CREATE INDEX idx_pending_estado ON pending_operations(estado)');
    await db.execute(
        'CREATE INDEX idx_pending_created ON pending_operations(created_at)');
  }

  // =================== Cache de catálogos ===================

  Future<void> saveCache(String table, String key, Map<String, dynamic> data) async {
    final db = await database;
    await db.insert(
      table,
      {
        'key': key,
        'data': jsonEncode(data),
        'cached_at': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Map<String, dynamic>?> getCache(String table, String key) async {
    final db = await database;
    final rows = await db.query(
      table,
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return jsonDecode(rows.first['data'] as String) as Map<String, dynamic>;
  }

  // =================== Cola de operaciones ===================

  Future<int> encolar({
    required String idLocal,
    required String tipo,
    required String endpoint,
    required Map<String, dynamic> payload,
  }) async {
    final db = await database;
    final now = DateTime.now().millisecondsSinceEpoch;
    return db.insert(
      'pending_operations',
      {
        'id_local': idLocal,
        'tipo': tipo,
        'endpoint': endpoint,
        'payload': jsonEncode(payload),
        'estado': 'PENDIENTE',
        'intentos': 0,
        'created_at': now,
        'updated_at': now,
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<List<Map<String, dynamic>>> obtenerPendientes() async {
    final db = await database;
    return db.query(
      'pending_operations',
      where: 'estado IN (?, ?)',
      whereArgs: ['PENDIENTE', 'ERROR'],
      orderBy: 'created_at ASC',
    );
  }

  Future<int> contarPendientes() async {
    final db = await database;
    final result = await db.rawQuery(
        'SELECT COUNT(*) AS c FROM pending_operations WHERE estado IN (?, ?, ?)',
        ['PENDIENTE', 'ENVIANDO', 'ERROR']);
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<void> marcarEnviando(String idLocal) async {
    final db = await database;
    await db.update(
      'pending_operations',
      {
        'estado': 'ENVIANDO',
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id_local = ?',
      whereArgs: [idLocal],
    );
  }

  Future<void> marcarOk(String idLocal, int serverId) async {
    final db = await database;
    await db.update(
      'pending_operations',
      {
        'estado': 'OK',
        'server_id': serverId,
        'last_error': null,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id_local = ?',
      whereArgs: [idLocal],
    );
  }

  Future<void> marcarError(String idLocal, String error) async {
    final db = await database;
    await db.update(
      'pending_operations',
      {
        'estado': 'ERROR',
        'last_error': error,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id_local = ?',
      whereArgs: [idLocal],
    );
  }

  Future<void> devolverAPendiente(String idLocal) async {
    final db = await database;
    await db.rawUpdate(
      'UPDATE pending_operations SET intentos = intentos + 1, estado = ?, updated_at = ? WHERE id_local = ?',
      ['PENDIENTE', DateTime.now().millisecondsSinceEpoch, idLocal],
    );
  }

  Future<int> obtenerIntentos(String idLocal) async {
    final db = await database;
    final rows = await db.query(
      'pending_operations',
      columns: ['intentos'],
      where: 'id_local = ?',
      whereArgs: [idLocal],
      limit: 1,
    );
    if (rows.isEmpty) return 0;
    return (rows.first['intentos'] as int?) ?? 0;
  }
}

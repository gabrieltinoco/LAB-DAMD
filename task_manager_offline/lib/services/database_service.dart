import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  static Database? _db;

  DatabaseService._internal();

  Future<Database> get db async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    String path = join(await getDatabasesPath(), 'offline_app.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        // Tabela de Itens (User Data)
        // is_synced: 0 = não, 1 = sim
        // updated_at: Essencial para o Last-Write-Wins
        await db.execute('''
          CREATE TABLE items(
            id TEXT PRIMARY KEY, 
            title TEXT, 
            is_synced INTEGER DEFAULT 0,
            updated_at TEXT
          )
        ''');

        // Tabela da Fila de Sincronização
        // operation: 'CREATE', 'UPDATE', 'DELETE'
        await db.execute('''
          CREATE TABLE sync_queue(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            operation TEXT,
            item_id TEXT,
            payload TEXT,
            created_at TEXT
          )
        ''');
      },
    );
  }

  // Métodos CRUD simplificados
  Future<void> insertItem(String id, String title) async {
    final dbClient = await db;
    String now = DateTime.now().toIso8601String();
    
    // 1. Salva na tabela de itens
    await dbClient.insert('items', {
      'id': id,
      'title': title,
      'is_synced': 0, // Começa não sincronizado
      'updated_at': now
    }, conflictAlgorithm: ConflictAlgorithm.replace);

    // 2. Adiciona na fila de sincronização (Operação CREATE)
    await dbClient.insert('sync_queue', {
      'operation': 'CREATE',
      'item_id': id,
      'payload': title,
      'created_at': now
    });
  }

  Future<List<Map<String, dynamic>>> getItems() async {
    final dbClient = await db;
    return await dbClient.query('items', orderBy: "updated_at DESC");
  }
  
  // Atualiza status para sincronizado
  Future<void> markAsSynced(String itemId) async {
    final dbClient = await db;
    await dbClient.update('items', {'is_synced': 1}, where: 'id = ?', whereArgs: [itemId]);
  }

  // Remove da fila após sucesso
  Future<void> removeFromQueue(int queueId) async {
    final dbClient = await db;
    await dbClient.delete('sync_queue', where: 'id = ?', whereArgs: [queueId]);
  }

  // Pega a fila pendente
  Future<List<Map<String, dynamic>>> getPendingSyncs() async {
    final dbClient = await db;
    return await dbClient.query('sync_queue', orderBy: "created_at ASC");
  }
}
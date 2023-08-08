import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:deadline_manager/models/task.dart';

class DatabaseHelper {
  static final _databaseName = "TaskDatabase.db";
  static final _databaseVersion = 1;

  static final table = 'tasks';

  static final columnId = 'id';
  static final columnTitle = 'title';
  static final columnDueDate = 'dueDate';
  static final columnStatus = 'status';

  // Singleton class
  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  // Database reference
  static Database? _database;
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  // Open the database
  _initDatabase() async {
    String path = join(await getDatabasesPath(), _databaseName);
    return await openDatabase(path,
        version: _databaseVersion, onCreate: _onCreate);
  }

  // SQL code to create the database table
  Future _onCreate(Database db, int version) async {
    await db.execute('''
          CREATE TABLE $table (
            $columnId INTEGER PRIMARY KEY,
            $columnTitle TEXT NOT NULL,
            $columnDueDate TEXT NOT NULL,
            $columnStatus TEXT NOT NULL
          )
          ''');
  }

  // Insert a task into the database
  Future<int> insert(Task task) async {
    Database db = await instance.database;
    return await db.insert(table, task.toJson());
  }

  // Update a task in the database
  Future<int> update(Task task) async {
    // print(task);
    Database db = await instance.database;
    return await db.update(table, task.toJson(),
        where: '$columnId = ?', whereArgs: [task.id]);
  }

  // Delete a task from the database
  Future<int> delete(int id) async {
    Database db = await instance.database;
    return await db.delete(table, where: '$columnId = ?', whereArgs: [id]);
  }

  // Retrieve all tasks from the database
  Future<List<Task>> queryAllTasks() async {
    Database db = await instance.database;
    var res = await db.query(table);
    List<Task> list =
        res.isNotEmpty ? res.map((c) => Task.fromJson(c)).toList() : [];
    // print(list);
    return list;
  }
}

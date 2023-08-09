import 'dart:io';
import 'package:drift/drift.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'models/task.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

part 'database.g.dart';

@DriftDatabase(tables: [Tasks])
class AppDatabase extends _$AppDatabase {
  AppDatabase(QueryExecutor e) : super(e);

  @override
  int get schemaVersion => 2; // 1から2に更新

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onUpgrade: (migrator, from, to) async {
          if (from == 1) {
            // バージョン1から2へのマイグレーション
            await migrator.addColumn(tasks, tasks.isCompleted);
            await migrator.addColumn(tasks, tasks.isDeleted);
            await migrator.addColumn(tasks, tasks.shouldNotify);
          }
        },
      );

  Future<List<Task>> getAllTasks() => select(tasks).get();

  Future<int> insertTask(Task task) => into(tasks).insert(task);

  Future<void> updateTask(Task task) => update(tasks).replace(task);

  Future<void> deleteTask(Task task) => delete(tasks).delete(task);
}

final provideDatabase = FutureProvider<AppDatabase>((ref) async {
  final dbFolder = await getApplicationDocumentsDirectory();
  final file = File(p.join(dbFolder.path, 'db.sqlite'));
  return AppDatabase(NativeDatabase(file));
});

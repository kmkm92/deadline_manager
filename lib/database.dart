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
  int get schemaVersion => 5; // 4 to 5

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onUpgrade: (migrator, from, to) async {
          if (from < 2) {
            // バージョン1から2へのマイグレーション
            await migrator.addColumn(tasks, tasks.isCompleted);
            await migrator.addColumn(tasks, tasks.isDeleted);
            await migrator.addColumn(tasks, tasks.shouldNotify);
          }
          if (from < 3) {
            // バージョン3へのマイグレーション
            await migrator.addColumn(tasks, tasks.recurrenceInterval);
          }
          if (from < 4) {
            // バージョン4へのマイグレーション
            await migrator.addColumn(tasks, tasks.sortOrder);
          }
          if (from < 5) {
            // バージョン5へのマイグレーション
            await migrator.addColumn(tasks, tasks.deletedAt);
          }
        },
      );
  // 全件取得（並び替え順）
  Future<List<Task>> getAllTasks() => (select(tasks)
        ..where((table) => table.isDeleted.equals(false))
        ..orderBy([
          (table) =>
              OrderingTerm(expression: table.sortOrder, mode: OrderingMode.asc)
        ]))
      .get();

  // 全件取得（削除されたタスク）
  Future<List<Task>> getAllDeleteTasks() =>
      (select(tasks)..where((table) => table.isDeleted.equals(true))).get();

  // 古いタスクを完全に削除
  Future<int> deleteOldTasks(DateTime threshold) {
    return (delete(tasks)
          ..where((t) =>
              t.isDeleted.equals(true) &
              t.deletedAt.isSmallerThanValue(threshold)))
        .go();
  }

  // 期限遅い順
  Future<List<Task>> getAllTasksSortedDesc() => (select(tasks)
        ..where((table) => table.isDeleted.equals(false))
        ..orderBy([
          (table) =>
              OrderingTerm(expression: table.dueDate, mode: OrderingMode.desc)
        ]))
      .get();
  // 期限早い順
  Future<List<Task>> getAllTasksSortedAsc() => (select(tasks)
        ..where((table) => table.isDeleted.equals(false))
        ..orderBy([
          (table) =>
              OrderingTerm(expression: table.dueDate, mode: OrderingMode.asc)
        ]))
      .get();
  // チェックなし
  Future<List<Task>> getAllTasksNotCompleted() => (select(tasks)
        ..where((table) =>
            table.isCompleted.equals(false) & table.isDeleted.equals(false)))
      .get();

  Future<int> insertTask(Task task) => into(tasks).insert(task);

  Future<void> updateTask(Task task) => update(tasks).replace(task);

  Future<void> deleteTask(Task task) => delete(tasks).delete(task);
}

final provideDatabase = FutureProvider<AppDatabase>((ref) async {
  final dbFolder = await getApplicationDocumentsDirectory();
  final file = File(p.join(dbFolder.path, 'db.sqlite'));
  return AppDatabase(NativeDatabase(file));
});

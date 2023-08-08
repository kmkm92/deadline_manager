import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:deadline_manager/models/task.dart';
import 'package:deadline_manager/database.dart';

final taskListProvider =
    StateNotifierProvider<TaskListNotifier, List<Task>>((ref) {
  return TaskListNotifier(ref);
});

class TaskListNotifier extends StateNotifier<List<Task>> {
  final Ref _ref;

  TaskListNotifier(this._ref) : super([]) {
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    final db = await _ref.read(provideDatabase.future);
    final tasks = await db.getAllTasks();
    state = tasks;
  }

  Future<void> addOrUpdateTask(Task task) async {
    final db = await _ref.read(provideDatabase.future);
    final tasks = await db.getAllTasks();
    print(task.id);
    // print(tasks[0].id);
    if (task.id == 0) {
      await db.insertTask(task);
    } else {
      await db.updateTask(task);
    }
    _loadTasks();
  }

  Future<void> deleteTask(Task task) async {
    final db = await _ref.read(provideDatabase.future);
    await db.deleteTask(task);
    _loadTasks();
  }
}

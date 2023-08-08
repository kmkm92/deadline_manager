import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:deadline_manager/models/task.dart';
import 'package:deadline_manager/database_helper.dart';

final taskProvider =
    StateNotifierProvider<TaskNotifier, List<Task>>((ref) => TaskNotifier());

class TaskNotifier extends StateNotifier<List<Task>> {
  TaskNotifier() : super([]) {
    _loadTasks();
  }

  final dbHelper = DatabaseHelper.instance;

  void _loadTasks() async {
    List<Task> tasks = await dbHelper.queryAllTasks();
    state = tasks;
  }

  void addTask(Task task) async {
    int id = await dbHelper.insert(task);
    task = task.copyWith(id: id);
    state = [...state, task];
  }

  void updateTask(int index, Task newTask) async {
    await dbHelper.update(newTask);
    state[index] = newTask;
    state = [...state];
  }

  void deleteTask(int index) async {
    // print('task_pro');
    // Task task = state[index];
    await dbHelper.delete(index!);
    // index = index - 1;
    state = List.from(state)..removeAt(index);
  }

  void editTask(int index, Task task) {}
}

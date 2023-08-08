import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:deadline_manager/models/task.dart';
import 'package:deadline_manager/view_models/home_view_model.dart';
import 'package:deadline_manager/database.dart';

class TaskFormView extends ConsumerWidget {
  final Task? task;

  TaskFormView({this.task});

  final _titleController = TextEditingController();
  final _dueDateController = TextEditingController();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (task != null) {
      _titleController.text = task!.title;
      _dueDateController.text = task!.dueDate.toIso8601String();
    }

    return Scaffold(
      appBar: AppBar(title: Text(task == null ? 'Add Task' : 'Edit Task')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              decoration: InputDecoration(labelText: 'Title'),
            ),
            TextField(
              controller: _dueDateController,
              decoration: InputDecoration(labelText: 'Due Date (YYYY-MM-DD)'),
            ),
            ElevatedButton(
              onPressed: () {
                final newTask = Task(
                  id: task?.id,
                  title: _titleController.text,
                  dueDate: DateTime.parse(_dueDateController.text),
                );
                ref.read(taskListProvider.notifier).addOrUpdateTask(newTask);
                Navigator.pop(context);
              },
              child: Text(task == null ? 'Add' : 'Update'),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:deadline_manager/database.dart';
import 'package:deadline_manager/views/task_from_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:deadline_manager/view_models/home_view_model.dart';
import 'package:intl/intl.dart';
import 'package:settings_ui/settings_ui.dart';
import 'package:deadline_manager/view_models/delete_task_view_model.dart';

import 'home_view.dart'; // 日付のフォーマットに使用

class DeleteTaskView extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deleteTasks = ref.watch(deleteTaskListProvider);
    // final deleteTasks = ref.watch(sortedTaskListProvider);
    ref.read(deleteTaskListProvider.notifier).loadDeleteTasks();

    return Scaffold(
      appBar: AppBar(
        title: Text('削除タスク'),
      ),
      body: ListView.builder(
        itemCount: deleteTasks.length + 1,
        itemBuilder: (context, index) {
          if (index == deleteTasks.length) {
            return SizedBox(height: 50);
          }
          final task = deleteTasks[index];
          return Card(
            margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: ListTile(
              leading: IconButton(
                icon: Icon(Icons.undo, color: Colors.green),
                onPressed: () {
                  ref.read(deleteTaskListProvider.notifier).restoreTask(task);
                },
              ),
              title: Text(
                task.title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  decoration: task.isCompleted
                      ? TextDecoration.lineThrough
                      : null, // タスクが完了している場合、打ち消し線を追加
                  decorationThickness: 2.5,
                ),
              ),
              subtitle: Row(
                children: [
                  Text(
                    DateFormat.yMMMEd('ja').add_jm().format(task.dueDate),
                  ),
                  if (task.shouldNotify)
                    Icon(
                      Icons.notifications,
                      size: 17,
                    ),
                ],
              ),
              trailing: IconButton(
                icon: Icon(Icons.delete, color: Colors.red),
                onPressed: () {
                  ref.read(deleteTaskListProvider.notifier).deleteTask(task);
                },
              ),
            ),
          );
        },
      ),
    );
  }
}

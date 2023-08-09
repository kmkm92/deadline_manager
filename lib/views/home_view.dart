import 'package:deadline_manager/database.dart';
import 'package:deadline_manager/views/task_from_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:deadline_manager/view_models/home_view_model.dart';
import 'package:intl/intl.dart'; // 日付のフォーマットに使用

class HomeView extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = ref.watch(taskListProvider);

    // 1. _showTaskForm関数の定義
    void _showTaskForm([Task? task]) {
      showModalBottomSheet(
        elevation: 0.1,
        context: context,
        builder: (BuildContext context) {
          return Container(
            height: 600,
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20.0),
                topRight: Radius.circular(20.0),
              ),
            ),
            child: TaskFormView(task: task),
          );
        },
        isScrollControlled: true,
        barrierColor: Colors.black.withOpacity(0.7),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('リスト'),
        backgroundColor: Colors.deepPurple,
      ),
      body: ListView.builder(
        itemCount: tasks.length,
        itemBuilder: (context, index) {
          final task = tasks[index];
          return Card(
            margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: ListTile(
              leading: Checkbox(
                value: task.isCompleted,
                onChanged: (bool? value) {
                  // toggleTaskCompletionを使用してタスクの完了状態を更新
                  ref
                      .read(taskListProvider.notifier)
                      .toggleTaskCompletion(task);
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

              subtitle: Text(
                DateFormat.yMMMEd('ja').add_jm().format(task.dueDate),
              ),
              trailing: IconButton(
                icon: Icon(Icons.delete, color: Colors.red),
                onPressed: () {
                  ref.read(taskListProvider.notifier).deleteTask(task);
                },
              ),
              onTap: () => _showTaskForm(task), // 2. _showTaskForm関数の呼び出し
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showTaskForm(), // 3. _showTaskForm関数の呼び出し
        child: Icon(Icons.add),
        backgroundColor: Colors.deepPurple,
      ),
    );
  }
}

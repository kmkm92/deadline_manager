import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:deadline_manager/models/task.dart';
import 'package:deadline_manager/view_models/task_provider.dart';
import 'package:deadline_manager/views/task_creation_screen.dart';
import 'package:deadline_manager/views/task_edit_screen.dart';

class HomeScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = ref.watch(taskProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text('Task Manager'),
        backgroundColor: Colors.blueGrey,
      ),
      body: ListView.separated(
        itemCount: tasks.length,
        separatorBuilder: (BuildContext context, int index) => Divider(),
        itemBuilder: (context, index) {
          final task = tasks[index];
          return Dismissible(
            key: ValueKey(task.id),
            onDismissed: (direction) {
              // print(task.id);
              // スワイプでタスクを削除
              ref.read(taskProvider.notifier).deleteTask(index!);
              ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${task.title} dismissed')));
            },
            background: Container(color: Colors.red), // スワイプ時の背景色
            child: Card(
              child: ListTile(
                title: Text(task.title,
                    style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('Due Date: ${task.dueDate.toIso8601String()}'),
                trailing: Text(task.status.toString().split('.').last),
                onTap: () {
                  print(task);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TaskEditScreen(
                        index: task.id!,
                        task: task,
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TaskCreationScreen(),
            ),
          );
        },
        child: Icon(Icons.add),
        backgroundColor: Colors.blueGrey,
      ),
    );
  }
}

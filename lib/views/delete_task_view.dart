import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:deadline_manager/view_models/delete_task_view_model.dart';

class DeleteTaskView extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deleteTasks = ref.watch(deleteTaskListProvider);
    ref.read(deleteTaskListProvider.notifier).loadDeleteTasks();

    return ScreenUtilInit(
      designSize: const Size(926, 428),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('ゴミ箱'),
          ),
          body: ListView.builder(
            itemCount: deleteTasks.length + 1,
            itemBuilder: (context, index) {
              if (index == deleteTasks.length) {
                return SizedBox(height: 50.h);
              }
              final task = deleteTasks[index];
              return Card(
                margin: EdgeInsets.symmetric(vertical: 10.w, horizontal: 15.w),
                child: ListTile(
                  leading: IconButton(
                    icon: const Icon(Icons.undo, color: Colors.green),
                    onPressed: () {
                      ref
                          .read(deleteTaskListProvider.notifier)
                          .restoreTask(task);
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
                          size: 35.sp,
                        ),
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      ref
                          .read(deleteTaskListProvider.notifier)
                          .deleteTask(task);
                    },
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

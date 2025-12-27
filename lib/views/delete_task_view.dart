import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:deadline_manager/utils/date_logic.dart';
import 'package:deadline_manager/view_models/delete_task_view_model.dart';

class DeleteTaskView extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deleteTasks = ref.watch(deleteTaskListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('ゴミ箱'),
      ),
      body: ListView.builder(
        itemCount: deleteTasks.length + 1,
        itemBuilder: (context, index) {
          if (index == deleteTasks.length) {
            return Padding(
              padding: EdgeInsets.symmetric(vertical: 20.h),
              child: Center(
                child: Text(
                  "ゴミ箱のタスクは30日経過後に自動的に削除されます",
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          final task = deleteTasks[index];
          return Card(
            margin: EdgeInsets.symmetric(vertical: 10.w, horizontal: 15.w),
            child: ListTile(
              leading: IconButton(
                icon: Icon(Icons.undo,
                    color: Theme.of(context).colorScheme.primary),
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
                  decorationThickness: task.isCompleted ? 2.5 : null,
                ),
              ),
              subtitle: Row(
                children: [
                  Text(
                    DateLogic.formatToJapanese(task.dueDate),
                  ),
                  if (task.shouldNotify)
                    Icon(
                      Icons.notifications,
                      size: 35.sp,
                    ),
                ],
              ),
              trailing: IconButton(
                icon: Icon(Icons.delete,
                    color: Theme.of(context).colorScheme.error),
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

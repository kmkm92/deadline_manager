import 'package:deadline_manager/database.dart';
import 'package:deadline_manager/views/settings_view.dart';
import 'package:deadline_manager/views/task_from_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:deadline_manager/view_models/home_view_model.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:deadline_manager/utils/date_logic.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeView extends ConsumerStatefulWidget {
  @override
  _HomeViewState createState() => _HomeViewState();
}

class _HomeViewState extends ConsumerState<HomeView> {
  @override
  void initState() {
    super.initState();

    Future.delayed(Duration(seconds: 1), _updateTimer);
  }

  void _updateTimer() {
    if (mounted) {
      setState(() {});
      Future.delayed(Duration(seconds: 1), _updateTimer);
    }
  }

  String _getTimeRemaining(DateTime dueDate) {
    final now = DateTime.now();
    final difference = dueDate.difference(now);

    if (difference.isNegative) {
      return '期限切れ';
    }

    final hours = difference.inHours;
    final minutes = difference.inMinutes.remainder(60);
    final seconds = difference.inSeconds.remainder(60);

    if (hours > 24) {
      return '残り ${difference.inDays}日';
    }
    if (hours == 0 && minutes == 0) {
      return '残り ${seconds}秒';
    }
    return '残り ${hours}時間 ${minutes}分';
  }

  void _showTaskForm([Task? task, String? initialTitle]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (BuildContext context) {
        return TaskFormView(task: task, initialTitle: initialTitle);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final tasks = ref.watch(taskListProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('リスト'),
        centerTitle: false,
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: '設定',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsView()),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: tasks.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.task_alt,
                    size: 64,
                    color:
                        Theme.of(context).colorScheme.surfaceContainerHighest,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'タスクがありません',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '右下のボタンから新しいタスクを追加しましょう',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            )
          : CustomScrollView(
              slivers: [
                SliverPadding(
                  padding:
                      EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                  sliver: SliverReorderableList(
                    itemBuilder: (context, index) {
                      return _buildTaskCard(context, tasks[index], index);
                    },
                    itemCount: tasks.length,
                    onReorder: (oldIndex, newIndex) {
                      ref
                          .read(taskListProvider.notifier)
                          .reorderTasks(oldIndex, newIndex);
                    },
                    proxyDecorator: (child, index, animation) {
                      return Material(
                        elevation: 4,
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                        child: child,
                      );
                    },
                  ),
                ),
                SliverToBoxAdapter(
                  child: SizedBox(height: 80.h),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showTaskForm(),
        icon: const Icon(Icons.add),
        label: const Text('新規タスク'),
        elevation: 4,
      ),
    );
  }

  Widget _buildTaskCard(BuildContext context, Task task, int index) {
    // Recurrence logic visual
    final isRecurring =
        task.recurrenceInterval != null && task.recurrenceInterval!.isNotEmpty;
    final isExpired = DateTime.now().isAfter(task.dueDate);

    return ReorderableDelayedDragStartListener(
      key: ValueKey(task.id),
      index: index,
      child: Dismissible(
        key: ValueKey(task.id),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: EdgeInsets.only(right: 20.w),
          margin: EdgeInsets.symmetric(vertical: 4.h),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.errorContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.delete,
              color: Theme.of(context).colorScheme.onErrorContainer),
        ),
        confirmDismiss: (direction) async {
          // Confirm deletion
          final prefs = await SharedPreferences.getInstance();
          final showConfirmation =
              prefs.getBool('show_delete_confirmation') ?? true;

          if (!showConfirmation) {
            return true;
          }

          bool doNotShowAgain = false;

          return await showDialog(
            context: context,
            builder: (BuildContext context) {
              return StatefulBuilder(
                builder: (context, setState) {
                  return AlertDialog(
                    title: const Text("削除確認"),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text("このタスクをゴミ箱に移動しますか？"),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Checkbox(
                                value: doNotShowAgain,
                                onChanged: (val) {
                                  setState(() {
                                    doNotShowAgain = val!;
                                  });
                                }),
                            Flexible(
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    doNotShowAgain = !doNotShowAgain;
                                  });
                                },
                                child: const Text("次回から表示しない"),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    actions: <Widget>[
                      TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: const Text("キャンセル")),
                      TextButton(
                          onPressed: () async {
                            if (doNotShowAgain) {
                              await prefs.setBool(
                                  'show_delete_confirmation', false);
                            }
                            Navigator.of(context).pop(true);
                          },
                          child: const Text("削除")),
                    ],
                  );
                },
              );
            },
          );
        },
        onDismissed: (direction) {
          ref.read(taskListProvider.notifier).deleteTask(task);
        },
        child: Card(
          margin: EdgeInsets.symmetric(vertical: 6.h),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => _showTaskForm(task),
            child: Padding(
              padding: EdgeInsets.all(12.w),
              child: Row(
                children: [
                  // Checkbox or Completed Icon
                  Transform.scale(
                    scale: 1.2,
                    child: Checkbox(
                      value: task.isCompleted,
                      shape: const CircleBorder(),
                      activeColor: Theme.of(context).colorScheme.primary,
                      onChanged: (bool? value) {
                        ref
                            .read(taskListProvider.notifier)
                            .toggleTaskCompletion(task);
                      },
                    ),
                  ),
                  SizedBox(width: 8.w),
                  // Main Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          task.title,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                decoration: task.isCompleted
                                    ? TextDecoration.lineThrough
                                    : null,
                                color: task.isCompleted ? Colors.grey : null,
                                fontWeight: FontWeight.bold,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 4.h),
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 4.w,
                          runSpacing: 2.h,
                          children: [
                            Icon(Icons.calendar_today,
                                size: 14.sp,
                                color: isExpired && !task.isCompleted
                                    ? Theme.of(context).colorScheme.error
                                    : Colors.grey),
                            Text(
                              DateLogic.formatToJapanese(task.dueDate),
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                      color: isExpired && !task.isCompleted
                                          ? Theme.of(context).colorScheme.error
                                          : null,
                                      fontWeight: isExpired
                                          ? FontWeight.bold
                                          : FontWeight.normal),
                            ),
                            if (isRecurring) ...[
                              SizedBox(width: 4.w),
                              Icon(Icons.repeat,
                                  size: 14.sp,
                                  color:
                                      Theme.of(context).colorScheme.tertiary),
                              Text(
                                _getRecurrenceLabel(task.recurrenceInterval),
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .tertiary,
                                    ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Time Remaining (Right side)
                  if (!task.isCompleted && task.shouldNotify)
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: isExpired
                            ? Theme.of(context)
                                .colorScheme
                                .errorContainer
                                .withOpacity(0.5)
                            : Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _getTimeRemaining(task.dueDate),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: isExpired
                                  ? Theme.of(context).colorScheme.error
                                  : Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                ],
              ),
            ),
          ), // InkWell
        ), // Card
      ), // Dismissible
    ); // ReorderableDelayedDragStartListener
  }

  String _getRecurrenceLabel(String? interval) {
    switch (interval) {
      case 'daily':
        return '毎日';
      case 'weekly':
        return '毎週';
      case 'monthly':
        return '毎月';
      case 'yearly':
        return '毎年';
      default:
        return '';
    }
  }
}

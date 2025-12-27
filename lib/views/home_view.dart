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

class _HomeViewState extends ConsumerState<HomeView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    Future.delayed(Duration(seconds: 1), _updateTimer);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _updateTimer() {
    if (mounted) {
      setState(() {});
      Future.delayed(Duration(seconds: 1), _updateTimer);
    }
  }

  String _getTimeRemaining(Task task) {
    DateTime targetDate = task.dueDate;
    final now = DateTime.now();

    // For recurring tasks, if they are expired, calculate the NEXT occurrence for display
    if (task.recurrenceInterval != null &&
        task.recurrenceInterval!.isNotEmpty &&
        targetDate.isBefore(now)) {
      targetDate =
          DateLogic.getNextValidFutureDate(targetDate, task.recurrenceInterval);
    }

    Duration difference = targetDate.difference(now);

    if (difference.isNegative) {
      if (task.recurrenceInterval != null &&
          task.recurrenceInterval!.isNotEmpty) {
        // Should have been handled above, but just in case
        return "更新中";
      }
      return "期限切れ";
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
    final isRecurringTab = _tabController.index == 1;
    // Specific check: if editing a task, use its property. If creating new, use tab index.
    final isRecurringMode = task != null
        ? (task.recurrenceInterval != null &&
            task.recurrenceInterval!.isNotEmpty)
        : isRecurringTab;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (BuildContext context) {
        return TaskFormView(
            task: task,
            initialTitle: initialTitle,
            isRecurringMode: isRecurringMode);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final allTasks = ref.watch(taskListProvider);
    final normalTasks = allTasks
        .where((t) =>
            t.recurrenceInterval == null || t.recurrenceInterval!.isEmpty)
        .toList();
    final recurringTasks = allTasks
        .where((t) =>
            t.recurrenceInterval != null && t.recurrenceInterval!.isNotEmpty)
        .toList();

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
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '通常'),
            Tab(text: '繰り返し'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTaskList(normalTasks),
          _buildTaskList(recurringTasks),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showTaskForm(),
        icon: const Icon(Icons.add),
        label: const Text('新規リマインダー'),
        elevation: 4,
      ),
    );
  }

  Widget _buildTaskList(List<Task> tasks) {
    if (tasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.task_alt,
              size: 64,
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
            ),
            const SizedBox(height: 16),
            Text(
              'リマインダーがありません',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              '右下のボタンから新しいリマインダーを追加しましょう',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      );
    }

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          sliver: SliverReorderableList(
            itemBuilder: (context, index) {
              return _buildTaskCard(context, tasks[index], index);
            },
            itemCount: tasks.length,
            onReorder: (oldIndex, newIndex) {
              // Note: Reordering might behave strangely if we filter the list.
              // For now, let's just allow reordering within the view, but we need to handle the global index.
              // Logic needs adjustment if reordering is critical globally.
              // Ideally reorder should only happen within the filtered list and update global SortOrder.

              // Since reorderTasks takes oldIndex/newIndex of the GLOBAL list in the VM currently?
              // No, VM takes indices. We need to pass the TASK object or handle indices carefully.
              // The current VM implementation uses indices of 'state'.

              // If we split lists, reordering index 0->1 in "Recurring" tab (which might be index 5, 6 in global)
              // won't work directly with current VM `reorderTasks(int, int)`.
              // We'll skip reordering for now or fix it later.
              // To enable it, we need `reorderTasks` to accept Task objects or IDs, or we need to map indices.

              // Let's Disable reordering for now or just accept it might be buggy until VM update.
              // Or better, update VM to Move task A to position of Task B?
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
                        const Text("このリマインダーをゴミ箱に移動しますか？"),
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
                  // Show checkbox only if NOT recurring
                  if (!isRecurring) ...[
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
                  ] else ...[
                    // Maybe show an icon indicating recurrence?
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12.w),
                      child: Icon(Icons.repeat,
                          color: Theme.of(context).colorScheme.tertiary),
                    ),
                  ],

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
                            if (!isRecurring) ...[
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
                                            ? Theme.of(context)
                                                .colorScheme
                                                .error
                                            : null,
                                        fontWeight: isExpired
                                            ? FontWeight.bold
                                            : FontWeight.normal),
                              ),
                            ] else ...[
                              // Recurrence Description
                              Text(
                                DateLogic.getRecurrenceDescription(task),
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .tertiary,
                                        fontWeight: FontWeight.bold),
                              ),
                            ],

                            // Original visual code had recurrence label here for normal tasks too?
                            // Current design separates them.
                            // If isRecurring is false, we don't show recurrence info.
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
                        _getTimeRemaining(task),
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
}

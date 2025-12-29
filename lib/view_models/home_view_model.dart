import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:drift/drift.dart';
import 'package:deadline_manager/database.dart';
import 'package:timezone/timezone.dart';
import 'package:intl/intl.dart';
import 'package:deadline_manager/utils/date_logic.dart';

final taskListProvider =
    StateNotifierProvider<TaskListNotifier, List<Task>>((ref) {
  return TaskListNotifier(ref);
});

class TaskListNotifier extends StateNotifier<List<Task>> {
  final Ref _ref;

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  TaskListNotifier(this._ref) : super([]) {
    _cleanupOldTasks();
    loadTasks();
  }

  Future<void> _cleanupOldTasks() async {
    final db = await _ref.read(provideDatabase.future);
    // 30日以上前の削除済みタスクを完全削除
    final threshold = DateTime.now().subtract(const Duration(days: 30));

    await db.deleteOldTasks(threshold);
  }

  Future<void> loadTasks() async {
    final db = await _ref.read(provideDatabase.future);

    // Check for expired recurring tasks and update them
    await _checkExpiredRecurringTasks(db);

    final tasks = await db.getAllTasks();
    state = tasks;
  }

  Future<void> _checkExpiredRecurringTasks(AppDatabase db) async {
    final now = DateTime.now();
    // Fetch all active recurring tasks
    final tasks = await db.getAllTasks();
    final recurringTasks = tasks.where((t) =>
        t.recurrenceInterval != null &&
        t.recurrenceInterval!.isNotEmpty &&
        !t.isDeleted);

    for (var task in recurringTasks) {
      // If task is expired, calculate next occurrence(s) until it's in future
      if (task.dueDate.isBefore(now)) {
        final nextDate = DateLogic.getNextValidFutureDate(
            task.dueDate, task.recurrenceInterval);

        // Only update if it actually changed to future (safety check)
        if (nextDate.isAfter(now)) {
          final updatedTask = task.copyWith(dueDate: nextDate);
          await db.updateTask(updatedTask);
          // Re-schedule notification
          if (updatedTask.shouldNotify) {
            cancelNotification(updatedTask.id);
            scheduleNotification(
                updatedTask.id, updatedTask.title, updatedTask.dueDate);
          }
        }
      }
    }
  }

  Future<void> loadTasksSortAsc() async {
    final db = await _ref.read(provideDatabase.future);
    final tasks = await db.getAllTasksSortedAsc();
    state = tasks;
  }

  Future<void> loadTasksSortDesc() async {
    final db = await _ref.read(provideDatabase.future);
    final tasks = await db.getAllTasksSortedDesc();
    state = tasks;
  }

  Future<void> addOrUpdateTask(Task task) async {
    final db = await _ref.read(provideDatabase.future);
    if (task.id == null) {
      // 新しいタスクを追加
      // 並び順はすべてのタスクの最後にする
      final currentTasks = state;
      int nextSortOrder = 0;
      if (currentTasks.isNotEmpty) {
        // Find max sort order (assuming list is sorted or just check all)
        nextSortOrder = currentTasks.last.sortOrder + 1;
      }

      final taskWithSort = task.copyWith(sortOrder: nextSortOrder);
      final insertId = await db.insertTask(taskWithSort);
      if (task.shouldNotify) {
        scheduleNotification(insertId, task.title, task.dueDate);
      }
    } else {
      // 既存のタスクを更新
      await db.updateTask(task);
      cancelNotification(task.id);
      if (task.shouldNotify) {
        scheduleNotification(task.id, task.title, task.dueDate);
      }
    }

    await loadTasks();
  }

// 論理削除
  Future<void> deleteTask(Task task) async {
    final db = await _ref.read(provideDatabase.future);
    final deletedTask = task.copyWith(
      isDeleted: true,
      shouldNotify: false,
      deletedAt: Value(DateTime.now()), // Set deletion timestamp
    );
    await db.updateTask(deletedTask);
    cancelNotification(task.id);
    await loadTasks();
  }

  Future<void> scheduleNotification(
      int? id, String title, DateTime dueDate) async {
    // IDがnullの場合は通知をスケジュールしない
    if (id == null) return;

    // 過去の日時の場合は通知をスケジュールしない
    if (!dueDate.isAfter(DateTime.now())) return;

    var iOSPlatformChannelSpecifics = DarwinNotificationDetails();
    var platformChannelSpecifics =
        NotificationDetails(iOS: iOSPlatformChannelSpecifics);
    final tzDueDate = TZDateTime.from(dueDate, local);

    try {
      await flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        DateFormat.yMMMEd('ja').add_jm().format(tzDueDate),
        title,
        tzDueDate,
        platformChannelSpecifics,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        androidAllowWhileIdle: true,
      );
    } catch (e) {
      // Ignore notification errors
    }
  }

  Future<void> cancelNotification(int? id) async {
    // IDがnullの場合はキャンセル処理をスキップ
    if (id == null) return;
    await flutterLocalNotificationsPlugin.cancel(id);
  }

  Future<void> toggleTaskCompletion(Task task) async {
    final db = await _ref.read(provideDatabase.future);
    final isCompleting = !task.isCompleted;

    // 1. Handle Recurring Task Creation (only when marking as completed)
    if (isCompleting &&
        task.recurrenceInterval != null &&
        task.recurrenceInterval!.isNotEmpty) {
      final nextDate =
          DateLogic.calculateNextDate(task.dueDate, task.recurrenceInterval!);
      final newTask = task.copyWith(
        id: const Value(null), // Create new entry
        dueDate: nextDate,
        isCompleted: false,
        sortOrder: state.isNotEmpty ? state.last.sortOrder + 1 : 0,
      );
      await addOrUpdateTask(newTask);
    }

    // 2. Logic for current task
    // If completing -> cancel notification
    // If uncompleting (checking off -> active) -> schedule notification if applicable
    if (isCompleting) {
      if (task.shouldNotify) {
        cancelNotification(task.id);
      }
    } else {
      // Reactivating task
      if (task.shouldNotify && task.dueDate.isAfter(DateTime.now())) {
        scheduleNotification(task.id, task.title, task.dueDate);
      }
    }

    final updatedTask = task.copyWith(isCompleted: isCompleting);
    await db.updateTask(updatedTask);

    await loadTasks();
  }

  // 並び替え処理（タブ別対応）
  void reorderTasks(int oldIndex, int newIndex,
      {required bool isRecurring}) async {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }

    // 全タスクリストから対象のタスクをフィルタリング
    final allTasks = List<Task>.from(state);
    final filteredTasks = allTasks
        .where((t) => isRecurring
            ? (t.recurrenceInterval != null && t.recurrenceInterval!.isNotEmpty)
            : (t.recurrenceInterval == null || t.recurrenceInterval!.isEmpty))
        .toList();

    // フィルタリングされたリスト内で並び替え
    final item = filteredTasks.removeAt(oldIndex);
    filteredTasks.insert(newIndex, item);

    // sortOrderを更新（フィルタリングされたリスト内での順序を維持）
    final db = await _ref.read(provideDatabase.future);

    for (int i = 0; i < filteredTasks.length; i++) {
      final task = filteredTasks[i];
      if (task.sortOrder != i) {
        final updated = task.copyWith(sortOrder: i);
        await db.updateTask(updated);
        filteredTasks[i] = updated;
      }
    }

    // 全タスクリストを再構築
    final otherTasks = allTasks
        .where((t) => isRecurring
            ? (t.recurrenceInterval == null || t.recurrenceInterval!.isEmpty)
            : (t.recurrenceInterval != null &&
                t.recurrenceInterval!.isNotEmpty))
        .toList();

    // 両方のリストをsortOrderでソートして結合
    filteredTasks.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    otherTasks.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    state = [...filteredTasks, ...otherTasks]
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  }
}

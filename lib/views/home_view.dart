import 'package:deadline_manager/database.dart';
import 'package:deadline_manager/views/settings_view.dart';
import 'package:deadline_manager/views/task_from_view.dart';
import 'package:deadline_manager/widgets/banner_ad_widget.dart';
import 'package:deadline_manager/services/ad_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:deadline_manager/view_models/home_view_model.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:deadline_manager/utils/date_logic.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:deadline_manager/theme/app_theme.dart';

class HomeView extends ConsumerStatefulWidget {
  @override
  _HomeViewState createState() => _HomeViewState();
}

class _HomeViewState extends ConsumerState<HomeView>
    with SingleTickerProviderStateMixin {
  int _selectedSegment = 0;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 1), _updateTimer);
  }

  void _updateTimer() {
    if (mounted) {
      setState(() {});
      Future.delayed(const Duration(seconds: 1), _updateTimer);
    }
  }

  String _getTimeRemaining(Task task) {
    DateTime targetDate = task.dueDate;
    final now = DateTime.now();

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
    // 1分未満（60秒未満）は秒表示
    if (hours == 0 && minutes == 0) {
      return '残り $seconds秒';
    }
    // 1時間未満は分表示のみ
    if (hours == 0) {
      return '残り $minutes分';
    }
    return '残り $hours時間 $minutes分';
  }

  void _showTaskForm([Task? task, String? initialTitle]) {
    final isRecurringTab = _selectedSegment == 1;
    final isRecurringMode = task != null
        ? (task.recurrenceInterval != null &&
            task.recurrenceInterval!.isNotEmpty)
        : isRecurringTab;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // モダンなヘッダー
            _buildHeader(context, isDarkMode),
            // モダンなセグメントコントロール
            _buildSegmentControl(context, isDarkMode),
            // タスクリスト
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _selectedSegment == 0
                    ? _buildTaskList(normalTasks, isDarkMode)
                    : _buildTaskList(recurringTasks, isDarkMode),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BannerAdWidget(placement: AdPlacement.homeList),
      floatingActionButton: _buildFloatingActionButton(context),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'リマインダー',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      fontSize: 28,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                _getGreeting(),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: isDarkMode ? Colors.white70 : Colors.black54,
                    ),
              ),
            ],
          ),
          // 設定ボタン
          Container(
            decoration: BoxDecoration(
              color: isDarkMode
                  ? AppTheme.secondaryColor.withOpacity(0.2)
                  : AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: CupertinoButton(
              padding: const EdgeInsets.all(10),
              onPressed: () {
                Navigator.push(
                  context,
                  CupertinoPageRoute(
                      builder: (context) => const SettingsView()),
                );
              },
              child: Icon(
                CupertinoIcons.gear,
                size: 22,
                color: isDarkMode
                    ? AppTheme.secondaryColor
                    : AppTheme.primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (5 <= hour && hour < 12) return 'おはようございます'; // 5〜11時
    if (12 <= hour && hour < 18) return 'こんにちは'; // 12〜17時
    return 'こんばんは'; // 18〜4時
  }

  Widget _buildSegmentControl(BuildContext context, bool isDarkMode) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDarkMode
            ? AppTheme.secondaryColor.withOpacity(0.15)
            : AppTheme.primaryColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          _buildSegmentButton(0, '通常', CupertinoIcons.list_bullet, isDarkMode),
          _buildSegmentButton(1, '繰り返し', CupertinoIcons.repeat, isDarkMode),
        ],
      ),
    );
  }

  Widget _buildSegmentButton(
      int index, String label, IconData icon, bool isDarkMode) {
    final isSelected = _selectedSegment == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedSegment = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDarkMode ? AppTheme.secondaryColor : AppTheme.primaryColor)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: (isDarkMode
                              ? AppTheme.secondaryColor
                              : AppTheme.primaryColor)
                          .withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected
                    ? Colors.white
                    : (isDarkMode ? Colors.white60 : Colors.black54),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected
                      ? Colors.white
                      : (isDarkMode ? Colors.white60 : Colors.black54),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingActionButton(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.4),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: FloatingActionButton.extended(
        onPressed: () => _showTaskForm(),
        elevation: 0,
        highlightElevation: 0,
        backgroundColor: Colors.transparent,
        icon: const Icon(CupertinoIcons.add, color: Colors.white),
        label: const Text(
          '新規追加',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildTaskList(List<Task> tasks, bool isDarkMode) {
    if (tasks.isEmpty) {
      return _buildEmptyState(isDarkMode);
    }

    return ListView.builder(
      key: ValueKey(_selectedSegment),
      padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 100.h),
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        return _buildTaskCard(context, tasks[index], index, isDarkMode);
      },
    );
  }

  Widget _buildEmptyState(bool isDarkMode) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryColor.withOpacity(0.1),
                  AppTheme.secondaryColor.withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Icon(
              CupertinoIcons.checkmark_circle,
              size: 48,
              color:
                  isDarkMode ? AppTheme.secondaryColor : AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'リマインダーがありません',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDarkMode ? Colors.white70 : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '下のボタンから追加してみましょう',
            style: TextStyle(
              fontSize: 14,
              color: isDarkMode ? Colors.white54 : Colors.black45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskCard(
      BuildContext context, Task task, int index, bool isDarkMode) {
    final isRecurring =
        task.recurrenceInterval != null && task.recurrenceInterval!.isNotEmpty;
    // 繰り返しタスクの場合、次の期限を考慮してisExpiredを判定
    DateTime effectiveDueDate = task.dueDate;
    if (isRecurring && effectiveDueDate.isBefore(DateTime.now())) {
      effectiveDueDate = DateLogic.getNextValidFutureDate(
          effectiveDueDate, task.recurrenceInterval);
    }
    final isExpired = DateTime.now().isAfter(effectiveDueDate);

    return Dismissible(
      key: ValueKey(task.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: 24.w),
        margin: EdgeInsets.symmetric(vertical: 6.h),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFF6B6B), Color(0xFFFF3B30)],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(CupertinoIcons.trash, color: Colors.white, size: 24),
      ),
      confirmDismiss: (direction) async {
        final prefs = await SharedPreferences.getInstance();
        final showConfirmation =
            prefs.getBool('show_delete_confirmation') ?? true;

        if (!showConfirmation) return true;

        bool doNotShowAgain = false;

        return await showCupertinoDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return StatefulBuilder(
              builder: (context, setState) {
                return CupertinoAlertDialog(
                  title: const Text("削除確認"),
                  content: Column(
                    children: [
                      const SizedBox(height: 8),
                      const Text("このリマインダーをゴミ箱に移動しますか？"),
                      const SizedBox(height: 16),
                      GestureDetector(
                        onTap: () =>
                            setState(() => doNotShowAgain = !doNotShowAgain),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              doNotShowAgain
                                  ? CupertinoIcons.checkmark_square_fill
                                  : CupertinoIcons.square,
                              color: AppTheme.primaryColor,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            const Text("次回から表示しない",
                                style: TextStyle(fontSize: 13)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  actions: [
                    CupertinoDialogAction(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text("キャンセル"),
                    ),
                    CupertinoDialogAction(
                      isDestructiveAction: true,
                      onPressed: () async {
                        if (doNotShowAgain) {
                          await prefs.setBool(
                              'show_delete_confirmation', false);
                        }
                        Navigator.of(context).pop(true);
                      },
                      child: const Text("削除"),
                    ),
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
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 6.h),
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: isDarkMode
                  ? Colors.black26
                  : AppTheme.primaryColor.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => _showTaskForm(task),
            child: Padding(
              padding: EdgeInsets.all(16.w),
              child: Row(
                children: [
                  // チェックボックスまたはリピートアイコン
                  _buildLeadingWidget(task, isRecurring, isDarkMode),
                  SizedBox(width: 14.w),
                  // メインコンテンツ
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          task.title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            decoration: task.isCompleted
                                ? TextDecoration.lineThrough
                                : null,
                            color: task.isCompleted
                                ? (isDarkMode ? Colors.white38 : Colors.black38)
                                : (isDarkMode ? Colors.white : Colors.black87),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 6.h),
                        _buildSubtitle(
                            task, isRecurring, isExpired, isDarkMode),
                      ],
                    ),
                  ),
                  // 残り時間バッジ
                  if (!task.isCompleted && task.shouldNotify)
                    _buildTimeBadge(task, isExpired, isDarkMode),
                  SizedBox(width: 8.w),
                  Icon(
                    CupertinoIcons.chevron_right,
                    size: 16,
                    color: isDarkMode ? Colors.white30 : Colors.black26,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLeadingWidget(Task task, bool isRecurring, bool isDarkMode) {
    if (isRecurring) {
      return Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          gradient: AppTheme.primaryGradient,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(
          CupertinoIcons.repeat,
          color: Colors.white,
          size: 20,
        ),
      );
    }

    return GestureDetector(
      onTap: () {
        ref.read(taskListProvider.notifier).toggleTaskCompletion(task);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: task.isCompleted ? AppTheme.primaryGradient : null,
          border: task.isCompleted
              ? null
              : Border.all(
                  color: isDarkMode
                      ? AppTheme.secondaryColor.withOpacity(0.5)
                      : AppTheme.primaryColor.withOpacity(0.4),
                  width: 2,
                ),
        ),
        child: task.isCompleted
            ? const Icon(
                CupertinoIcons.checkmark,
                size: 16,
                color: Colors.white,
              )
            : null,
      ),
    );
  }

  Widget _buildSubtitle(
      Task task, bool isRecurring, bool isExpired, bool isDarkMode) {
    if (isRecurring) {
      return Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: isDarkMode
                  ? AppTheme.secondaryColor.withOpacity(0.2)
                  : AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              DateLogic.getRecurrenceDescription(task),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isDarkMode
                    ? AppTheme.secondaryColor
                    : AppTheme.primaryColor,
              ),
            ),
          ),
        ],
      );
    }

    return Row(
      children: [
        Icon(
          CupertinoIcons.calendar,
          size: 14,
          color: isExpired && !task.isCompleted
              ? AppTheme.destructiveColor
              : (isDarkMode ? Colors.white54 : Colors.black45),
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            DateLogic.formatToJapanese(task.dueDate),
            style: TextStyle(
              fontSize: 13,
              color: isExpired && !task.isCompleted
                  ? AppTheme.destructiveColor
                  : (isDarkMode ? Colors.white54 : Colors.black45),
              fontWeight: isExpired ? FontWeight.w600 : FontWeight.normal,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildTimeBadge(Task task, bool isExpired, bool isDarkMode) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: isExpired
            ? AppTheme.destructiveColor.withOpacity(0.1)
            : (isDarkMode
                ? AppTheme.secondaryColor.withOpacity(0.15)
                : AppTheme.primaryColor.withOpacity(0.08)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        _getTimeRemaining(task),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: isExpired
              ? AppTheme.destructiveColor
              : (isDarkMode ? AppTheme.secondaryColor : AppTheme.primaryColor),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:deadline_manager/utils/date_logic.dart';
import 'package:deadline_manager/view_models/delete_task_view_model.dart';
import 'package:deadline_manager/theme/app_theme.dart';

class DeleteTaskView extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deleteTasks = ref.watch(deleteTaskListProvider);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor =
        isDarkMode ? const Color(0xFF121212) : const Color(0xFFF8F7FC);
    final cardColor = isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // モダンなヘッダー
            _buildHeader(context, isDarkMode),
            Expanded(
              child: deleteTasks.isEmpty
                  ? _buildEmptyState(isDarkMode)
                  : _buildTaskList(deleteTasks, cardColor, isDarkMode, ref),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 16),
      child: Row(
        children: [
          CupertinoButton(
            padding: const EdgeInsets.all(8),
            onPressed: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDarkMode
                    ? AppTheme.secondaryColor.withOpacity(0.2)
                    : AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                CupertinoIcons.back,
                size: 20,
                color: isDarkMode
                    ? AppTheme.secondaryColor
                    : AppTheme.primaryColor,
              ),
            ),
          ),
          const Spacer(),
          Text(
            'ゴミ箱',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          const Spacer(),
          const SizedBox(width: 44),
        ],
      ),
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
              CupertinoIcons.trash,
              size: 48,
              color:
                  isDarkMode ? AppTheme.secondaryColor : AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'ゴミ箱は空です',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDarkMode ? Colors.white70 : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '削除されたリマインダーは\n30日後に自動削除されます',
            style: TextStyle(
              fontSize: 14,
              color: isDarkMode ? Colors.white54 : Colors.black45,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTaskList(List<dynamic> deleteTasks, Color cardColor,
      bool isDarkMode, WidgetRef ref) {
    return ListView.builder(
      padding: EdgeInsets.fromLTRB(16, 8, 16, 100.h),
      itemCount: deleteTasks.length + 1,
      itemBuilder: (context, index) {
        if (index == deleteTasks.length) {
          return Padding(
            padding: EdgeInsets.symmetric(vertical: 20.h),
            child: Center(
              child: Text(
                "リマインダーは30日経過後に自動削除されます",
                style: TextStyle(
                  fontSize: 13,
                  color: isDarkMode ? Colors.white38 : Colors.black38,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        final task = deleteTasks[index];
        return Container(
          margin: EdgeInsets.symmetric(vertical: 6.h),
          decoration: BoxDecoration(
            color: cardColor,
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
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // 復元ボタン
                GestureDetector(
                  onTap: () {
                    ref.read(deleteTaskListProvider.notifier).restoreTask(task);
                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      CupertinoIcons.arrow_counterclockwise,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                // タスク情報
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
                          color: isDarkMode ? Colors.white : Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            CupertinoIcons.calendar,
                            size: 14,
                            color: isDarkMode ? Colors.white54 : Colors.black45,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            DateLogic.formatToJapanese(task.dueDate),
                            style: TextStyle(
                              fontSize: 13,
                              color:
                                  isDarkMode ? Colors.white54 : Colors.black45,
                            ),
                          ),
                          if (task.shouldNotify) ...[
                            const SizedBox(width: 8),
                            Icon(
                              CupertinoIcons.bell,
                              size: 14,
                              color:
                                  isDarkMode ? Colors.white54 : Colors.black45,
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                // 完全削除ボタン
                GestureDetector(
                  onTap: () {
                    showCupertinoDialog(
                      context: context,
                      builder: (context) {
                        return CupertinoAlertDialog(
                          title: const Text('完全に削除'),
                          content:
                              const Text('このリマインダーを完全に削除しますか？\nこの操作は取り消せません。'),
                          actions: [
                            CupertinoDialogAction(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('キャンセル'),
                            ),
                            CupertinoDialogAction(
                              isDestructiveAction: true,
                              onPressed: () {
                                ref
                                    .read(deleteTaskListProvider.notifier)
                                    .deleteTask(task);
                                Navigator.pop(context);
                              },
                              child: const Text('削除'),
                            ),
                          ],
                        );
                      },
                    );
                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppTheme.destructiveColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      CupertinoIcons.trash,
                      color: AppTheme.destructiveColor,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

import 'package:deadline_manager/database.dart';
import 'package:deadline_manager/views/delete_task_view.dart';
import 'package:deadline_manager/views/task_from_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:deadline_manager/view_models/home_view_model.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:settings_ui/settings_ui.dart';
import 'package:deadline_manager/views/license_view.dart';

class HomeView extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = ref.watch(taskListProvider);

    ref.read(taskListProvider.notifier).sortTask();

    // 1. _showTaskForm関数の定義
    void _showTaskForm([Task? task]) {
      showModalBottomSheet(
        elevation: 0.1,
        context: context,
        builder: (BuildContext context) {
          return ScreenUtilInit(
            designSize: const Size(926, 428),
            minTextAdapt: true,
            splitScreenMode: true,
            builder: (context, child) {
              return Container(
                height: 290.h,
                padding: EdgeInsets.all(16.0.w),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20.0.r),
                    topRight: Radius.circular(20.0.r),
                  ),
                ),
                child: TaskFormView(task: task),
              );
            },
          );
        },
        isScrollControlled: true,
        barrierColor: Colors.black.withOpacity(0.7),
      );
    }

    return ScreenUtilInit(
      designSize: const Size(926, 428),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('リスト'),
            actions: <Widget>[
              PopupMenuButton<String>(
                icon: const Icon(Icons.sort),
                onSelected: (String value) async {
                  await ref
                      .read(taskListProvider.notifier)
                      .changeSortOrder(value);
                },
                itemBuilder: (BuildContext context) {
                  return ['作成順', '期限日が早い順', '期限日が遅い順'].map((String choice) {
                    return PopupMenuItem<String>(
                      value: choice,
                      child: Text(choice),
                    );
                  }).toList();
                },
              ),
            ],
          ),
          drawer: Drawer(
            child: Container(
              color: const Color.fromRGBO(255, 252, 239, 100),
              child: Padding(
                padding: EdgeInsets.only(top: 35.w),
                child: AppSettingsList(),
              ),
            ),
          ),
          body: ListView.builder(
            itemCount: tasks.length + 1,
            itemBuilder: (context, index) {
              if (index == tasks.length) {
                return SizedBox(height: 50.h);
              }
              final task = tasks[index];
              return Card(
                margin: EdgeInsets.symmetric(vertical: 10.w, horizontal: 15.w),
                child: ListTile(
                  leading: Checkbox(
                    checkColor: Colors.indigo,
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
                      decorationThickness: 2.5.sp,
                    ),
                  ),
                  subtitle: Row(
                    children: [
                      Text(
                        DateFormat.yMMMEd('ja').add_jm().format(task.dueDate),
                      ),
                      if (task.shouldNotify && !task.isCompleted)
                        Icon(
                          Icons.notifications,
                          size: 35.sp,
                        ),
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
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
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }
}

class AppSettingsList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(926, 428),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return Padding(
          padding: EdgeInsets.only(top: 45.0.h),
          child: SettingsList(
            sections: [
              SettingsSection(
                // title: Text('設定'),
                tiles: [
                  SettingsTile(
                    title: const Text('ゴミ箱'),
                    leading: const Icon(Icons.delete_outline),
                    onPressed: (BuildContext context) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => DeleteTaskView()),
                      );
                    },
                  ),
                  SettingsTile(
                    title: const Text('ライセンス'),
                    leading: const Icon(Icons.policy),
                    onPressed: (BuildContext context) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const LicenseView()),
                      );
                    },
                  ),
                  // 他の設定項目を追加
                ],
              ),
              SettingsSection(
                // title: Text('その他'),
                tiles: [
                  SettingsTile(
                    title: const Text('バージョン'),
                    leading: const Icon(Icons.info),
                    trailing: const Text('1.0.0'),
                    // onPressed: (BuildContext context) {
                    //   // アプリの情報画面への遷移などの処理をここに書く
                    // },
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

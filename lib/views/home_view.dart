import 'package:deadline_manager/database.dart';
import 'package:deadline_manager/views/task_from_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:deadline_manager/view_models/home_view_model.dart';
import 'package:intl/intl.dart';
import 'package:settings_ui/settings_ui.dart'; // 日付のフォーマットに使用

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
            child: Scaffold(
              appBar: PreferredSize(
                preferredSize: Size.fromHeight(30.0),
                child: AppBar(
                  backgroundColor: Colors.white,
                  elevation: 0,
                  actions: [
                    IconButton(
                      icon: Icon(Icons.check, color: Colors.deepPurple),
                      onPressed: () {
                        // ここにタスク追加のロジックを書く
                        // 例: _addOrUpdateTask();
                      },
                    ),
                  ],
                ),
              ),
              body: TaskFormView(task: task),
            ),
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
      drawer: Drawer(
        child: Container(
          color: Colors.deepPurple,
          child: Padding(
            padding: const EdgeInsets.only(top: 80.0),
            child: SettingsList(
              sections: [
                SettingsSection(
                  // title: Text('設定'),
                  tiles: [
                    SettingsTile(
                      title: Text('テーマカラー'),
                      leading: Icon(Icons.color_lens),
                      onPressed: (BuildContext context) {
                        // アカウント設定画面への遷移などの処理をここに書く
                      },
                    ),
                    SettingsTile(
                      title: Text('通知'),
                      leading: Icon(Icons.notifications),
                      onPressed: (BuildContext context) {
                        // 通知設定画面への遷移などの処理をここに書く
                      },
                    ),
                    SettingsTile(
                      title: Text('ダークモード'),
                      leading: Icon(Icons.light_mode),
                      onPressed: (BuildContext context) {
                        // 通知設定画面への遷移などの処理をここに書く
                      },
                    ),
                    // 他の設定項目を追加
                  ],
                ),
                SettingsSection(
                  // title: Text('その他'),
                  tiles: [
                    SettingsTile(
                      title: Text('情報'),
                      leading: Icon(Icons.info),
                      onPressed: (BuildContext context) {
                        // アプリの情報画面への遷移などの処理をここに書く
                      },
                    ),
                    SettingsTile(
                      title: Text('使い方'),
                      leading: Icon(Icons.help),
                      onPressed: (BuildContext context) {
                        // ヘルプ画面への遷移などの処理をここに書く
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
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

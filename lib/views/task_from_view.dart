import 'package:flutter/material.dart';
import 'package:flutter_datetime_picker_plus/flutter_datetime_picker_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_datetime_picker_plus/flutter_datetime_picker_plus.dart'
    as picker; // 追加
import 'package:deadline_manager/view_models/home_view_model.dart';
import 'package:deadline_manager/database.dart';
import 'package:intl/intl.dart';

class TaskFormView extends ConsumerStatefulWidget {
  final Task? task;

  TaskFormView({this.task});

  @override
  _TaskFormViewState createState() => _TaskFormViewState();
}

class _TaskFormViewState extends ConsumerState<TaskFormView> {
  final _titleController = TextEditingController();
  // final _focusNode = FocusNode();
  DateTime? _selectedDateTime;
  String? _errorMessage;
  bool _isNotificationEnabled = false;

  @override
  void initState() {
    super.initState();
    if (widget.task != null) {
      _titleController.text = widget.task!.title;
      _selectedDateTime = widget.task!.dueDate;
      _isNotificationEnabled = widget.task!.shouldNotify;
    }
    // // 2. initStateでFocusNodeを初期化
    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   _focusNode.requestFocus();
    // });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(30.0),
        child: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          actions: [
            IconButton(
              icon: Icon(Icons.check),
              onPressed: _addOrUpdateTask,
            ),
          ],
        ),
      ),
      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20.0),
              topRight: Radius.circular(20.0),
            ),
          ),
          child: ListView(
            children: [
              // エラーメッセージを表示するウィジェットを追加
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.all(1.0),
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    TextField(
                      controller: _titleController,
                      // focusNode: _focusNode,
                      decoration: InputDecoration(
                        labelText: 'タスク',
                        border: OutlineInputBorder(), // 入力フィールドのスタイル変更
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(),
                        ),
                      ),
                    ),
                    SizedBox(height: 16), // スペースを追加
                    Column(
                      children: [
                        ListTile(
                          title: Text(
                            _selectedDateTime == null
                                ? _isNotificationEnabled == false
                                    ? "日時を選択してください"
                                    : "通知する日時を選択してください"
                                : "${DateFormat.yMMMEd('ja').add_jm().format(_selectedDateTime!)}",
                            style: TextStyle(fontSize: 16),
                          ),
                          trailing: Icon(
                            Icons.calendar_today,
                          ),
                          onTap: () {
                            picker.DatePicker.showDateTimePicker(context,
                                showTitleActions: true,
                                onChanged: (date) {}, onConfirm: (date) {
                              setState(() {
                                _selectedDateTime = date;
                              });
                            },
                                currentTime:
                                    _selectedDateTime ?? DateTime.now(),
                                locale: LocaleType.jp);
                          },
                        ),
                        SwitchListTile(
                          title: Text(
                            _isNotificationEnabled == false ? "通知しない" : "通知する",
                            style: TextStyle(fontSize: 16),
                          ),
                          value: _isNotificationEnabled,
                          onChanged: (bool value) {
                            setState(() {
                              _isNotificationEnabled = value;
                            });
                          },
                          secondary: const Icon(Icons.notifications),
                        ),
                      ],
                    ),
                    SizedBox(height: 16), // スペースを追加
                    ElevatedButton(
                      onPressed: _addOrUpdateTask,
                      child: Text(widget.task == null ? '追加' : '更新'),
                      style: ElevatedButton.styleFrom(
                        // backgroundColor: Colors.deepPurple,
                        padding:
                            EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _addOrUpdateTask() {
    if (_titleController.text.isEmpty) {
      setState(() {
        _errorMessage = 'タスクを入力してください。';
      });
      return;
    }
    if (_titleController.text.length >= 100) {
      setState(() {
        _errorMessage = '最大文字数は100文字です。';
      });
      return;
    }
    if (_selectedDateTime == null) {
      setState(() {
        _errorMessage = '日時を選択してください。';
      });
      return;
    }
    if (_isNotificationEnabled && !_selectedDateTime!.isAfter(DateTime.now())) {
      setState(() {
        _errorMessage = '未来の日時を選択してください。';
      });
      return;
    }
    final newTask = Task(
      id: widget.task?.id,
      title: _titleController.text,
      dueDate: _selectedDateTime!,
      isCompleted: false,
      isDeleted: false,
      shouldNotify: _isNotificationEnabled,
    );
    ref.read(taskListProvider.notifier).addOrUpdateTask(newTask);
    Navigator.pop(context);
  }
}

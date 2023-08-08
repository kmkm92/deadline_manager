import 'package:deadline_manager/view_models/notification_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:deadline_manager/models/task.dart';
import 'package:deadline_manager/view_models/task_provider.dart';

class TaskEditScreen extends ConsumerStatefulWidget {
  final int index;
  final Task task;

  TaskEditScreen({required this.index, required this.task});

  @override
  _TaskEditScreenState createState() => _TaskEditScreenState();
}

class _TaskEditScreenState extends ConsumerState<TaskEditScreen> {
  late TextEditingController _titleController;
  late TextEditingController _dueDateController;
  TaskStatus _status;

  _TaskEditScreenState()
      : _titleController = TextEditingController(),
        _dueDateController = TextEditingController(),
        _status = TaskStatus.undone;

  @override
  void initState() {
    super.initState();
    _titleController.text = widget.task.title;
    _dueDateController.text = widget.task.dueDate.toIso8601String();
    _status = widget.task.status;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _dueDateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Task'),
        backgroundColor: Colors.blueGrey,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16.0),
            TextField(
              controller: _dueDateController,
              decoration: InputDecoration(
                labelText: 'Due Date',
                border: OutlineInputBorder(),
              ),
              onTap: () async {
                FocusScope.of(context).requestFocus(new FocusNode());
                final DateTime? date = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2022, 1),
                  lastDate: DateTime(2101),
                );
                if (date != null) {
                  // 時間を選択
                  TimeOfDay? time = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.now(),
                  );

                  if (time != null) {
                    // 日付と時間を結合
                    DateTime dateTime = DateTime(
                      date.year,
                      date.month,
                      date.day,
                      time.hour,
                      time.minute,
                    );
                    if (dateTime != null)
                      setState(() {
                        _dueDateController.text = dateTime.toIso8601String();
                      });
                  }
                }
              },
            ),
            SizedBox(height: 16.0),
            DropdownButton<TaskStatus>(
              value: _status,
              onChanged: (TaskStatus? newValue) {
                setState(() {
                  _status = newValue!;
                });
              },
              items: TaskStatus.values
                  .map<DropdownMenuItem<TaskStatus>>((TaskStatus value) {
                return DropdownMenuItem<TaskStatus>(
                  value: value,
                  child: Text(value.toString().split('.').last),
                );
              }).toList(),
            ),
            SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: () async {
                final Task updatedTask = Task(
                  id: widget.index,
                  title: _titleController.text,
                  dueDate: DateTime.parse(_dueDateController.text),
                  status: _status,
                );
                ref
                    .read(taskProvider.notifier)
                    .updateTask(widget.index, updatedTask);

                // Schedule a notification at the due date and time
                final notificationViewModel = ref.watch(notificationProvider);
                await notificationViewModel.scheduleNotification(updatedTask);

                Navigator.pop(context);
              },
              child: Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }
}

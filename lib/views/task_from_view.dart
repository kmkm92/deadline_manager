import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:deadline_manager/models/task.dart';
import 'package:deadline_manager/view_models/home_view_model.dart';
import 'package:deadline_manager/database.dart';

class TaskFormView extends ConsumerStatefulWidget {
  final Task? task;

  TaskFormView({this.task});

  @override
  _TaskFormViewState createState() => _TaskFormViewState();
}

class _TaskFormViewState extends ConsumerState<TaskFormView> {
  final _titleController = TextEditingController();
  DateTime? _selectedDateTime;

  @override
  void initState() {
    super.initState();
    if (widget.task != null) {
      _titleController.text = widget.task!.title;
      _selectedDateTime = widget.task!.dueDate;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
          AppBar(title: Text(widget.task == null ? 'Add Task' : 'Edit Task')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              decoration: InputDecoration(labelText: 'Title'),
            ),
            ListTile(
              title: Text(_selectedDateTime == null
                  ? 'Select Due Date and Time'
                  : "${_selectedDateTime!.toIso8601String().split('T')[0]} ${TimeOfDay.fromDateTime(_selectedDateTime!).format(context)}"),
              trailing: Icon(Icons.calendar_today),
              onTap: () async {
                DateTime? pickedDate = await showDatePicker(
                  context: context,
                  initialDate: _selectedDateTime ?? DateTime.now(),
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2101),
                );
                if (pickedDate != null) {
                  TimeOfDay? pickedTime = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.fromDateTime(pickedDate),
                  );
                  if (pickedTime != null) {
                    setState(() {
                      _selectedDateTime = DateTime(
                        pickedDate.year,
                        pickedDate.month,
                        pickedDate.day,
                        pickedTime.hour,
                        pickedTime.minute,
                      );
                    });
                  }
                }
              },
            ),
            ElevatedButton(
              onPressed: () {
                if (_selectedDateTime != null &&
                    _titleController.text != '' &&
                    _selectedDateTime!.isAfter(DateTime.now())) {
                  final newTask = Task(
                    id: widget.task?.id,
                    title: _titleController.text,
                    dueDate: _selectedDateTime!,
                  );
                  ref.read(taskListProvider.notifier).addOrUpdateTask(newTask);
                  Navigator.pop(context);
                } else {
                  // 日付や時間が選択されていない場合のエラーハンドリングをここに追加できます。
                }
              },
              child: Text(widget.task == null ? 'Add' : 'Update'),
            ),
          ],
        ),
      ),
    );
  }
}

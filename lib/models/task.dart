import 'package:freezed_annotation/freezed_annotation.dart';

part 'task.freezed.dart';
part 'task.g.dart';

enum TaskStatus { unhandled, processing, done, undone }

@freezed
class Task with _$Task {
  factory Task({
    int? id,
    required String title,
    required DateTime dueDate,
    required TaskStatus status,
  }) = _Task;

  factory Task.fromJson(Map<String, dynamic> json) => _$TaskFromJson(json);
}

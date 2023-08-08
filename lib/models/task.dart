import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:drift/drift.dart' hide JsonKey;

part 'task.freezed.dart';
// part 'task.g.dart';

@DataClassName('Task')
class Tasks extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text().withLength(min: 1, max: 100)();
  DateTimeColumn get dueDate => dateTime()();
}

@freezed
class Task with _$Task {
  const factory Task({
    required int id,
    required String title,
    required DateTime dueDate,
  }) = _Task;

  factory Task.fromRow(Map<String, dynamic> row) {
    return Task(
      id: row['id'] as int,
      title: row['title'] as String,
      dueDate: DateTime.parse(row['dueDate'] as String),
    );
  }
}

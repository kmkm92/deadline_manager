import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:drift/drift.dart' hide JsonKey;

part 'task.freezed.dart';
// part 'task.g.dart';

@DataClassName('Task')
class Tasks extends Table {
  IntColumn get id => integer().autoIncrement().nullable()();
  TextColumn get title => text().withLength(min: 1, max: 100)();
  DateTimeColumn get dueDate => dateTime()();
  BoolColumn get isCompleted => boolean().withDefault(const Constant(false))();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  BoolColumn get shouldNotify => boolean().withDefault(const Constant(true))();
}

@freezed
class Task with _$Task {
  const factory Task({
    required int? id,
    required String title,
    required DateTime dueDate,
    required bool isCompleted,
    required bool isDeleted,
    required bool shouldNotify,
  }) = _Task;

  factory Task.fromRow(Map<String, dynamic> row) {
    return Task(
      id: row['id'] as int,
      title: row['title'] as String,
      dueDate: DateTime.parse(row['dueDate'] as String),
      isCompleted: row['isCompleted'] as bool,
      isDeleted: row['isDeleted'] as bool,
      shouldNotify: row['shouldNotify'] as bool,
    );
  }
}

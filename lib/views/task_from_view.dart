import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_datetime_picker_plus/flutter_datetime_picker_plus.dart'
    as picker;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:deadline_manager/view_models/home_view_model.dart';
import 'package:deadline_manager/database.dart';
import 'package:deadline_manager/utils/date_logic.dart';
import 'package:permission_handler/permission_handler.dart';

class TaskFormView extends ConsumerStatefulWidget {
  final Task? task;
  final String? initialTitle;
  final bool isRecurringMode;

  const TaskFormView({
    Key? key,
    this.task,
    this.initialTitle,
    this.isRecurringMode = false,
  }) : super(key: key);

  @override
  _TaskFormViewState createState() => _TaskFormViewState();
}

class _TaskFormViewState extends ConsumerState<TaskFormView>
    with SingleTickerProviderStateMixin {
  final _titleController = TextEditingController();
  DateTime? _selectedDateTime;
  String? _errorMessage;
  bool _isNotificationEnabled = true;
  String? _recurrenceInterval; // 'daily', 'weekly', 'monthly', 'yearly'

  // Recurring specific
  TimeOfDay _selectedTime = const TimeOfDay(hour: 9, minute: 0);

  // Monday = 1, Sunday = 7
  int _selectedWeekday = DateTime.now().weekday;
  // 1-31
  int _selectedDayOfMonth = DateTime.now().day;

  // Relative Time
  late TabController _tabController;
  late FixedExtentScrollController _hoursController;
  late FixedExtentScrollController _minutesController;
  int _selectedHours = 0;
  int _selectedMinutes = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _hoursController = FixedExtentScrollController(initialItem: _selectedHours);
    _minutesController =
        FixedExtentScrollController(initialItem: _selectedMinutes);

    if (widget.task != null) {
      _titleController.text = widget.task!.title;
      _selectedDateTime = widget.task!.dueDate;
      _isNotificationEnabled = widget.task!.shouldNotify;
      _recurrenceInterval = widget.task!.recurrenceInterval;

      // Initialize time from task due date
      _selectedTime = TimeOfDay.fromDateTime(widget.task!.dueDate);
    } else if (widget.initialTitle != null) {
      _titleController.text = widget.initialTitle!;
      _isNotificationEnabled = true;
    }

    // Default recurrence if in recurring mode and new task
    if (widget.task == null && widget.isRecurringMode) {
      _recurrenceInterval = 'daily';
      _isNotificationEnabled = true;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _hoursController.dispose();
    _minutesController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      // Height controlled by content or parent, simplified for bottom sheet
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24.0)),
      ),
      child: Column(
        children: [
          _buildHandle(context),
          Expanded(
            child: Scaffold(
              backgroundColor: Colors.transparent,
              appBar: AppBar(
                title: Text(widget.task == null ? 'リマインダー追加' : 'リマインダー編集'),
                automaticallyImplyLeading: false,
                actions: [
                  TextButton(
                    onPressed: _addOrUpdateTask,
                    child: const Text('保存',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              body: GestureDetector(
                onTap: () => FocusScope.of(context).unfocus(),
                child: ListView(
                  padding: const EdgeInsets.all(20.0),
                  children: [
                    if (_errorMessage != null)
                      Container(
                        padding: const EdgeInsets.all(8),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.errorContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onErrorContainer),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    TextField(
                      controller: _titleController,
                      autofocus:
                          widget.task == null && widget.initialTitle == null,
                      decoration: const InputDecoration(
                        labelText: 'リマインダー名',
                        hintText: '例: 燃えるゴミを出す',
                        prefixIcon: Icon(Icons.task_alt),
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (widget.isRecurringMode) ...[
                      // RECURRING TASK UI
                      _buildRecurringTaskUI(),
                    ] else ...[
                      // NORMAL TASK UI
                      _buildNormalTaskUI(),
                    ],
                    SizedBox(
                        height: MediaQuery.of(context).viewInsets.bottom + 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNormalTaskUI() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text("通知設定"),
          subtitle: Text(_isNotificationEnabled ? "指定日時に通知します" : "通知しません"),
          value: _isNotificationEnabled,
          onChanged: (val) {
            setState(() => _isNotificationEnabled = val);
          },
        ),
        const Divider(),

        // TabBar for Time Selection
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.symmetric(vertical: 16),
          child: TabBar(
            controller: _tabController,
            indicatorSize: TabBarIndicatorSize.tab,
            indicator: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            labelColor: Theme.of(context).colorScheme.onPrimary,
            unselectedLabelColor:
                Theme.of(context).colorScheme.onSurfaceVariant,
            dividerColor: Colors.transparent,
            tabs: const [
              Tab(text: '日時指定'),
              Tab(text: '相対時間'),
            ],
          ),
        ),

        SizedBox(
          height: 250,
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildAbsoluteDateTimePicker(),
              _buildRelativeTimePicker(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRecurringTaskUI() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("繰り返しパターン", style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildRecurrenceChip('daily', '毎日'),
              _buildRecurrenceChip('weekly', '毎週'),
              _buildRecurrenceChip('monthly', '毎月'),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // 1. Time Selection (Drum Roll) - Always visible for repeating tasks
        Text("時間設定", style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        SizedBox(
          height: 120,
          child: CupertinoDatePicker(
            mode: CupertinoDatePickerMode.time,
            use24hFormat: true,
            // Create a DateTime with the selected time (Date part doesn't matter for display in time mode usually, but better be safe)
            initialDateTime:
                DateTime(2020, 1, 1, _selectedTime.hour, _selectedTime.minute),
            onDateTimeChanged: (DateTime newDateTime) {
              setState(() {
                _selectedTime = TimeOfDay.fromDateTime(newDateTime);
              });
            },
          ),
        ),
        const SizedBox(height: 24),

        // 2. Interval Specific Settings
        if (_recurrenceInterval == 'weekly') ...[
          Text("曜日設定", style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          _buildDayOfWeekSelector(),
        ] else if (_recurrenceInterval == 'monthly') ...[
          Text("日付設定", style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          _buildDayOfMonthSelector(),
        ],
      ],
    );
  }

  Widget _buildHandle(BuildContext context) {
    return Container(
      width: 40,
      height: 4,
      margin: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.outlineVariant,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildRecurrenceChip(String? value, String label) {
    final isSelected = _recurrenceInterval == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (bool selected) {
          if (selected) {
            setState(() {
              _recurrenceInterval = value;
            });
          }
        },
      ),
    );
  }

  Widget _buildDayOfWeekSelector() {
    // Determine initially selected weekday based on existing logic or default
    // Using a simple Row of chips for Mon-Sun
    final weekDays = ['月', '火', '水', '木', '金', '土', '日'];
    return Wrap(
      spacing: 8.0,
      children: List.generate(7, (index) {
        final dayIndex = index + 1; // 1-based
        final isSelected = _selectedWeekday == dayIndex;
        return FilterChip(
          label: Text(weekDays[index]),
          selected: isSelected,
          onSelected: (selected) {
            if (selected) {
              setState(() => _selectedWeekday = dayIndex);
            }
          },
          showCheckmark: false,
          selectedColor: Theme.of(context).colorScheme.primaryContainer,
          labelStyle: TextStyle(
            color: isSelected
                ? Theme.of(context).colorScheme.onPrimaryContainer
                : null,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        );
      }),
    );
  }

  FixedExtentScrollController? _dayOfMonthScrollController;

  Widget _buildDayOfMonthSelector() {
    // Drum roll for 1-31
    // Initialize controller only once or when needed
    // Note: If reusing view, be careful.
    _dayOfMonthScrollController ??=
        FixedExtentScrollController(initialItem: _selectedDayOfMonth - 1);

    return SizedBox(
      height: 120,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 80,
            child: CupertinoPicker(
              scrollController: _dayOfMonthScrollController,
              itemExtent: 32,
              onSelectedItemChanged: (index) {
                setState(() {
                  _selectedDayOfMonth = index + 1;
                });
              },
              children: List.generate(
                  31, (index) => Center(child: Text('${index + 1}'))),
            ),
          ),
          const Text("日"),
        ],
      ),
    );
  }

  Widget _buildAbsoluteDateTimePicker({String label = "日時を選択"}) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        InkWell(
          onTap: () {
            // For recurring, we might only want Date picker if Time is separate?
            // But let's use the full picker for simplicity or restrict it.
            // If Recurring, we override the TIME part with _selectedTime usually?
            // Or we just use this to pick the FULL start date/time.
            picker.DatePicker.showDateTimePicker(context,
                showTitleActions: true, onConfirm: (date) {
              setState(() {
                _selectedDateTime = date;
                // Sync time if using separate time picker
                _selectedTime = TimeOfDay.fromDateTime(date);
              });
            },
                currentTime: _selectedDateTime ?? DateTime.now(),
                locale: picker.LocaleType.jp);
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Theme.of(context).colorScheme.outline),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.calendar_month,
                    color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  _selectedDateTime == null
                      ? label
                      : DateLogic.formatToJapanese(_selectedDateTime!),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRelativeTimePicker() {
    return Column(
      children: [
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildCupertinoPicker(_hoursController, 24, "時間", (val) {
                setState(() => _selectedHours = val);
              }),
              const SizedBox(width: 16),
              _buildCupertinoPicker(_minutesController, 60, "分", (val) {
                setState(() => _selectedMinutes = val);
              }),
            ],
          ),
        ),
        if (_selectedHours > 0 || _selectedMinutes > 0)
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(
              '${_selectedHours}時間 ${_selectedMinutes}分後に設定',
              style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold),
            ),
          ),
      ],
    );
  }

  Widget _buildCupertinoPicker(FixedExtentScrollController controller,
      int count, String unit, Function(int) onChanged) {
    return Row(
      children: [
        SizedBox(
          width: 60,
          child: CupertinoPicker(
            scrollController: controller,
            itemExtent: 32,
            onSelectedItemChanged: onChanged,
            children:
                List.generate(count, (index) => Center(child: Text('$index'))),
          ),
        ),
        Text(unit, style: const TextStyle(fontSize: 16)),
      ],
    );
  }

  Future<void> _addOrUpdateTask() async {
    // Validation
    if (_titleController.text.isEmpty) {
      setState(() => _errorMessage = 'リマインダー名を入力してください。');
      return;
    }

    DateTime? finalDateTime;

    if (widget.isRecurringMode) {
      // RECURRING LOGIC
      if (_recurrenceInterval == null) {
        setState(() => _errorMessage = '繰り返しパターンを選択してください。');
        return;
      }

      if (_recurrenceInterval == 'daily') {
        finalDateTime = DateLogic.getNextDailyDate(_selectedTime);
      } else if (_recurrenceInterval == 'weekly') {
        finalDateTime =
            DateLogic.getNextWeeklyDate(_selectedWeekday, _selectedTime);
      } else {
        // monthly
        finalDateTime =
            DateLogic.getNextMonthlyDate(_selectedDayOfMonth, _selectedTime);
      }

      // Ensure not null
      if (finalDateTime == null) {
        finalDateTime = DateTime.now();
      }
    } else {
      // NORMAL LOGIC
      if (_tabController.index == 0) {
        if (_selectedDateTime == null) {
          setState(() => _errorMessage = '日時を選択してください。');
          return;
        }
        finalDateTime = _selectedDateTime;
      } else {
        if (_selectedHours == 0 && _selectedMinutes == 0) {
          setState(() => _errorMessage = '時間を設定してください。');
          return;
        }
        finalDateTime = DateTime.now()
            .add(Duration(hours: _selectedHours, minutes: _selectedMinutes));
      }

      if (_isNotificationEnabled && !finalDateTime!.isAfter(DateTime.now())) {
        setState(() => _errorMessage = '未来の日時を指定してください。');
        return;
      }
    }

    if (_isNotificationEnabled &&
        await Permission.notification.isPermanentlyDenied) {
      setState(() => _errorMessage = '通知権限がありません。設定から許可してください。');
      return;
    }

    final newTask = Task(
      id: widget.task?.id,
      title: _titleController.text,
      dueDate: finalDateTime!,
      isCompleted: false,
      isDeleted: false,
      shouldNotify: _isNotificationEnabled,
      sortOrder: widget.task?.sortOrder ?? 0,
      deletedAt: widget.task?.deletedAt,
      recurrenceInterval: widget.isRecurringMode ? _recurrenceInterval : null,
    );

    await ref.read(taskListProvider.notifier).addOrUpdateTask(newTask);
    if (mounted) Navigator.pop(context);
  }
}

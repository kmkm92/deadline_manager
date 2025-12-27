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

  const TaskFormView({Key? key, this.task, this.initialTitle})
      : super(key: key);

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
    } else if (widget.initialTitle != null) {
      _titleController.text = widget.initialTitle!;
      // Default to slightly in future or allow user to pick
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
                title: Text(widget.task == null ? 'タスク追加' : 'タスク編集'),
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
                        labelText: 'タスク名',
                        hintText: '例: 燃えるゴミを出す',
                        prefixIcon: Icon(Icons.task_alt),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Notification Toggle
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text("通知設定"),
                      subtitle: Text(
                          _isNotificationEnabled ? "指定日時に通知します" : "通知しません"),
                      value: _isNotificationEnabled,
                      onChanged: (val) {
                        setState(() => _isNotificationEnabled = val);
                      },
                    ),
                    const Divider(),

                    // TabBar for Time Selection
                    Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest,
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

                    const SizedBox(height: 24),
                    const Text("繰り返し設定",
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildRecurrenceChip(null, 'なし'),
                          _buildRecurrenceChip('daily', '毎日'),
                          _buildRecurrenceChip('weekly', '毎週'),
                          _buildRecurrenceChip('monthly', '毎月'),
                          _buildRecurrenceChip('yearly', '毎年'),
                        ],
                      ),
                    ),

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
          setState(() {
            _recurrenceInterval = selected ? value : null;
          });
        },
      ),
    );
  }

  Widget _buildAbsoluteDateTimePicker() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        InkWell(
          onTap: () {
            picker.DatePicker.showDateTimePicker(context,
                showTitleActions: true, onConfirm: (date) {
              setState(() => _selectedDateTime = date);
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
                      ? "日時を選択"
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
      setState(() => _errorMessage = 'タスク名を入力してください。');
      return;
    }

    DateTime? finalDateTime;
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
      recurrenceInterval: _recurrenceInterval,
    );

    await ref.read(taskListProvider.notifier).addOrUpdateTask(newTask);
    if (mounted) Navigator.pop(context);
  }
}

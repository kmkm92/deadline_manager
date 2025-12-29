import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_datetime_picker_plus/flutter_datetime_picker_plus.dart'
    as picker;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:deadline_manager/view_models/home_view_model.dart';
import 'package:deadline_manager/database.dart';
import 'package:deadline_manager/utils/date_logic.dart';
import 'package:deadline_manager/widgets/banner_ad_widget.dart';
import 'package:deadline_manager/services/ad_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:deadline_manager/theme/app_theme.dart';

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

class _TaskFormViewState extends ConsumerState<TaskFormView> {
  final _titleController = TextEditingController();
  DateTime? _selectedDateTime;
  String? _errorMessage;
  bool _isNotificationEnabled = true;
  String? _recurrenceInterval;

  TimeOfDay _selectedTime = const TimeOfDay(hour: 9, minute: 0);
  int _selectedWeekday = DateTime.now().weekday;
  int _selectedDayOfMonth = DateTime.now().day;

  int _selectedTab = 0;
  late FixedExtentScrollController _hoursController;
  late FixedExtentScrollController _minutesController;
  int _selectedHours = 0;
  int _selectedMinutes = 0;

  @override
  void initState() {
    super.initState();
    _hoursController = FixedExtentScrollController(initialItem: _selectedHours);
    _minutesController =
        FixedExtentScrollController(initialItem: _selectedMinutes);

    if (widget.task != null) {
      _titleController.text = widget.task!.title;
      _selectedDateTime = widget.task!.dueDate;
      _isNotificationEnabled = widget.task!.shouldNotify;
      _recurrenceInterval = widget.task!.recurrenceInterval;
      _selectedTime = TimeOfDay.fromDateTime(widget.task!.dueDate);
    } else if (widget.initialTitle != null) {
      _titleController.text = widget.initialTitle!;
      _isNotificationEnabled = true;
    }

    if (widget.task == null && widget.isRecurringMode) {
      _recurrenceInterval = 'daily';
      _isNotificationEnabled = true;
    }
  }

  @override
  void dispose() {
    _hoursController.dispose();
    _minutesController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          _buildHandle(),
          _buildHeader(isDarkMode),
          Expanded(
            child: GestureDetector(
              onTap: () => FocusScope.of(context).unfocus(),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                children: [
                  if (_errorMessage != null) _buildErrorMessage(),
                  _buildTitleField(isDarkMode),
                  const SizedBox(height: 24),
                  if (widget.isRecurringMode)
                    ..._buildRecurringTaskUI(isDarkMode)
                  else
                    ..._buildNormalTaskUI(isDarkMode),
                  SizedBox(
                      height: MediaQuery.of(context).viewInsets.bottom + 20),
                ],
              ),
            ),
          ),
          BannerAdWidget(placement: AdPlacement.taskForm),
        ],
      ),
    );
  }

  Widget _buildHandle() {
    return Container(
      width: 40,
      height: 5,
      margin: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }

  Widget _buildHeader(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDarkMode
                ? AppTheme.secondaryColor.withOpacity(0.2)
                : AppTheme.primaryColor.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          CupertinoButton(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            onPressed: () => Navigator.pop(context),
            child: Text(
              'キャンセル',
              style: TextStyle(
                color: isDarkMode
                    ? AppTheme.secondaryColor
                    : AppTheme.primaryColor,
                fontSize: 17,
              ),
            ),
          ),
          Text(
            widget.task == null ? '新規リマインダー' : 'リマインダー編集',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          CupertinoButton(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            onPressed: _addOrUpdateTask,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                '保存',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorMessage() {
    return Container(
      padding: const EdgeInsets.all(14),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.destructiveColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.destructiveColor.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            CupertinoIcons.exclamationmark_circle,
            color: AppTheme.destructiveColor,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _errorMessage!,
              style: const TextStyle(
                color: AppTheme.destructiveColor,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitleField(bool isDarkMode) {
    return Container(
      decoration: BoxDecoration(
        color: isDarkMode
            ? const Color(0xFF2C2C2E)
            : AppTheme.primaryColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDarkMode
              ? AppTheme.secondaryColor.withOpacity(0.3)
              : AppTheme.primaryColor.withOpacity(0.15),
        ),
      ),
      child: TextField(
        controller: _titleController,
        autofocus: widget.task == null && widget.initialTitle == null,
        style: TextStyle(
          fontSize: 17,
          color: isDarkMode ? Colors.white : Colors.black87,
        ),
        decoration: InputDecoration(
          hintText: 'リマインダー名を入力',
          hintStyle: TextStyle(
            color: isDarkMode ? Colors.white38 : Colors.black38,
          ),
          prefixIcon: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              CupertinoIcons.text_cursor,
              color: Colors.white,
              size: 18,
            ),
          ),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  List<Widget> _buildNormalTaskUI(bool isDarkMode) {
    return [
      // 通知設定
      _buildSettingCard(
        isDarkMode: isDarkMode,
        icon: CupertinoIcons.bell_fill,
        iconColor: const Color(0xFFFF9500),
        title: '通知設定',
        subtitle: _isNotificationEnabled ? '指定日時に通知します' : '通知しません',
        trailing: CupertinoSwitch(
          value: _isNotificationEnabled,
          activeTrackColor: AppTheme.primaryColor,
          onChanged: (val) => setState(() => _isNotificationEnabled = val),
        ),
      ),
      const SizedBox(height: 20),

      // タブ選択
      _buildModernSegmentControl(isDarkMode),
      const SizedBox(height: 20),

      if (_selectedTab == 0)
        _buildAbsoluteDateTimePicker(isDarkMode)
      else
        _buildRelativeTimePicker(isDarkMode),
    ];
  }

  Widget _buildSettingCard({
    required bool isDarkMode,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required Widget trailing,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF2C2C2E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isDarkMode
                ? Colors.black26
                : AppTheme.primaryColor.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDarkMode ? Colors.white54 : Colors.black45,
                  ),
                ),
              ],
            ),
          ),
          trailing,
        ],
      ),
    );
  }

  Widget _buildModernSegmentControl(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDarkMode
            ? AppTheme.secondaryColor.withOpacity(0.15)
            : AppTheme.primaryColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          _buildSegmentButton(0, '日時指定', CupertinoIcons.calendar, isDarkMode),
          _buildSegmentButton(1, '相対時間', CupertinoIcons.timer, isDarkMode),
        ],
      ),
    );
  }

  Widget _buildSegmentButton(
      int index, String label, IconData icon, bool isDarkMode) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDarkMode ? AppTheme.secondaryColor : AppTheme.primaryColor)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected
                    ? Colors.white
                    : (isDarkMode ? Colors.white54 : Colors.black45),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected
                      ? Colors.white
                      : (isDarkMode ? Colors.white54 : Colors.black45),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildRecurringTaskUI(bool isDarkMode) {
    return [
      _buildSectionLabel('繰り返しパターン'),
      const SizedBox(height: 8),
      _buildRecurrenceSelector(isDarkMode),
      const SizedBox(height: 24),
      _buildSectionLabel('時間設定'),
      const SizedBox(height: 8),
      _buildTimePicker(isDarkMode),
      const SizedBox(height: 24),
      if (_recurrenceInterval == 'weekly') ...[
        _buildSectionLabel('曜日設定'),
        const SizedBox(height: 8),
        _buildDayOfWeekSelector(isDarkMode),
      ] else if (_recurrenceInterval == 'monthly') ...[
        _buildSectionLabel('日付設定'),
        const SizedBox(height: 8),
        _buildDayOfMonthSelector(isDarkMode),
      ],
    ];
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppTheme.primaryColor,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildRecurrenceSelector(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDarkMode
            ? AppTheme.secondaryColor.withOpacity(0.15)
            : AppTheme.primaryColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          _buildRecurrenceButton('daily', '毎日', isDarkMode),
          _buildRecurrenceButton('weekly', '毎週', isDarkMode),
          _buildRecurrenceButton('monthly', '毎月', isDarkMode),
        ],
      ),
    );
  }

  Widget _buildRecurrenceButton(String value, String label, bool isDarkMode) {
    final isSelected = _recurrenceInterval == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _recurrenceInterval = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDarkMode ? AppTheme.secondaryColor : AppTheme.primaryColor)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: isSelected
                  ? Colors.white
                  : (isDarkMode ? Colors.white54 : Colors.black45),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimePicker(bool isDarkMode) {
    return Container(
      height: 150,
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF2C2C2E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: CupertinoDatePicker(
        mode: CupertinoDatePickerMode.time,
        use24hFormat: true,
        initialDateTime:
            DateTime(2020, 1, 1, _selectedTime.hour, _selectedTime.minute),
        onDateTimeChanged: (DateTime newDateTime) {
          setState(() => _selectedTime = TimeOfDay.fromDateTime(newDateTime));
        },
      ),
    );
  }

  Widget _buildDayOfWeekSelector(bool isDarkMode) {
    final weekDays = ['月', '火', '水', '木', '金', '土', '日'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(7, (index) {
        final dayIndex = index + 1;
        final isSelected = _selectedWeekday == dayIndex;
        return GestureDetector(
          onTap: () => setState(() => _selectedWeekday = dayIndex),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              gradient: isSelected ? AppTheme.primaryGradient : null,
              color: isSelected
                  ? null
                  : (isDarkMode
                      ? const Color(0xFF2C2C2E)
                      : AppTheme.primaryColor.withOpacity(0.08)),
              borderRadius: BorderRadius.circular(12),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: AppTheme.primaryColor.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Center(
              child: Text(
                weekDays[index],
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: isSelected
                      ? Colors.white
                      : (isDarkMode ? Colors.white70 : Colors.black54),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  FixedExtentScrollController? _dayOfMonthScrollController;

  Widget _buildDayOfMonthSelector(bool isDarkMode) {
    _dayOfMonthScrollController ??=
        FixedExtentScrollController(initialItem: _selectedDayOfMonth - 1);

    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF2C2C2E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 80,
            child: CupertinoPicker(
              scrollController: _dayOfMonthScrollController,
              itemExtent: 36,
              onSelectedItemChanged: (index) =>
                  setState(() => _selectedDayOfMonth = index + 1),
              children: List.generate(
                31,
                (index) => Center(
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
              ),
            ),
          ),
          const Text("日", style: TextStyle(fontSize: 18)),
        ],
      ),
    );
  }

  Widget _buildAbsoluteDateTimePicker(bool isDarkMode) {
    return GestureDetector(
      onTap: () {
        picker.DatePicker.showDateTimePicker(context, showTitleActions: true,
            onConfirm: (date) {
          setState(() {
            _selectedDateTime = date;
            _selectedTime = TimeOfDay.fromDateTime(date);
          });
        },
            currentTime: _selectedDateTime ?? DateTime.now(),
            locale: picker.LocaleType.jp);
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF2C2C2E) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _selectedDateTime != null
                ? (isDarkMode ? AppTheme.secondaryColor : AppTheme.primaryColor)
                : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryColor.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(CupertinoIcons.calendar,
                  color: Colors.white, size: 22),
            ),
            const SizedBox(width: 14),
            Text(
              _selectedDateTime == null
                  ? '日時を選択してください'
                  : DateLogic.formatToJapanese(_selectedDateTime!),
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w500,
                color: _selectedDateTime == null
                    ? (isDarkMode ? Colors.white38 : Colors.black38)
                    : (isDarkMode ? Colors.white : Colors.black87),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRelativeTimePicker(bool isDarkMode) {
    return Column(
      children: [
        Container(
          height: 160,
          decoration: BoxDecoration(
            color: isDarkMode ? const Color(0xFF2C2C2E) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryColor.withOpacity(0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildCupertinoPicker(_hoursController, 24, "時間",
                  (val) => setState(() => _selectedHours = val)),
              const SizedBox(width: 20),
              _buildCupertinoPicker(_minutesController, 60, "分",
                  (val) => setState(() => _selectedMinutes = val)),
            ],
          ),
        ),
        if (_selectedHours > 0 || _selectedMinutes > 0)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '$_selectedHours時間 $_selectedMinutes分後に通知',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
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
          width: 70,
          child: CupertinoPicker(
            scrollController: controller,
            itemExtent: 36,
            onSelectedItemChanged: onChanged,
            children: List.generate(
              count,
              (index) => Center(
                child: Text('$index', style: const TextStyle(fontSize: 20)),
              ),
            ),
          ),
        ),
        Text(unit, style: const TextStyle(fontSize: 17)),
      ],
    );
  }

  Future<void> _addOrUpdateTask() async {
    if (_titleController.text.isEmpty) {
      setState(() => _errorMessage = 'リマインダー名を入力してください。');
      return;
    }

    DateTime? finalDateTime;

    if (widget.isRecurringMode) {
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
        finalDateTime =
            DateLogic.getNextMonthlyDate(_selectedDayOfMonth, _selectedTime);
      }

      finalDateTime ??= DateTime.now();
    } else {
      if (_selectedTab == 0) {
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

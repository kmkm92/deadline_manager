import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:deadline_manager/views/delete_task_view.dart';
import 'package:deadline_manager/views/license_view.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:deadline_manager/view_models/theme_view_model.dart';
import 'package:app_settings/app_settings.dart';
import 'package:deadline_manager/widgets/banner_ad_widget.dart';
import 'package:deadline_manager/services/ad_service.dart';
import 'package:deadline_manager/theme/app_theme.dart';

class SettingsView extends ConsumerStatefulWidget {
  const SettingsView({Key? key}) : super(key: key);

  @override
  ConsumerState<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends ConsumerState<SettingsView> {
  bool _showDeleteConfirmation = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _showDeleteConfirmation =
          prefs.getBool('show_delete_confirmation') ?? true;
    });
  }

  Future<void> _updateDeleteConfirmation(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('show_delete_confirmation', value);
    setState(() => _showDeleteConfirmation = value);
  }

  String _getThemeText(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return 'システム設定';
      case ThemeMode.light:
        return 'ライト';
      case ThemeMode.dark:
        return 'ダーク';
    }
  }

  IconData _getThemeIcon(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return CupertinoIcons.device_phone_portrait;
      case ThemeMode.light:
        return CupertinoIcons.sun_max_fill;
      case ThemeMode.dark:
        return CupertinoIcons.moon_fill;
    }
  }

  void _showThemeSelectionDialog(BuildContext context) {
    final currentTheme = ref.read(themeViewModelProvider);

    showCupertinoModalPopup(
      context: context,
      builder: (context) {
        return CupertinoActionSheet(
          title: const Text('テーマ設定'),
          actions: [
            _buildThemeAction(ThemeMode.system, 'システム設定に従う', currentTheme),
            _buildThemeAction(ThemeMode.light, 'ライトモード', currentTheme),
            _buildThemeAction(ThemeMode.dark, 'ダークモード', currentTheme),
          ],
          cancelButton: CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
        );
      },
    );
  }

  Widget _buildThemeAction(ThemeMode mode, String label, ThemeMode current) {
    return CupertinoActionSheetAction(
      onPressed: () {
        ref.read(themeViewModelProvider.notifier).setTheme(mode);
        Navigator.pop(context);
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label),
          if (current == mode) ...[
            const SizedBox(width: 8),
            Icon(CupertinoIcons.checkmark,
                color: AppTheme.primaryColor, size: 18),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor =
        isDarkMode ? const Color(0xFF121212) : const Color(0xFFF8F7FC);
    final cardColor = isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // モダンなヘッダー
            _buildHeader(context, isDarkMode),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  // 一般セクション
                  _buildSectionHeader('一般'),
                  _buildSettingsCard(
                    cardColor: cardColor,
                    isDarkMode: isDarkMode,
                    children: [
                      _buildSettingsTile(
                        icon: _getThemeIcon(ref.watch(themeViewModelProvider)),
                        iconColor: AppTheme.primaryColor,
                        title: 'テーマ',
                        subtitle:
                            _getThemeText(ref.watch(themeViewModelProvider)),
                        isDarkMode: isDarkMode,
                        onTap: () => _showThemeSelectionDialog(context),
                        showArrow: true,
                      ),
                      _buildDivider(isDarkMode),
                      _buildSwitchTile(
                        icon: CupertinoIcons.exclamationmark_triangle_fill,
                        iconColor: const Color(0xFFFF9500),
                        title: 'リマインダー削除時の確認',
                        subtitle: '削除前に確認ダイアログを表示',
                        value: _showDeleteConfirmation,
                        isDarkMode: isDarkMode,
                        onChanged: _updateDeleteConfirmation,
                      ),
                      _buildDivider(isDarkMode),
                      _buildSettingsTile(
                        icon: CupertinoIcons.bell_fill,
                        iconColor: AppTheme.destructiveColor,
                        title: '端末の通知設定',
                        subtitle: '端末の設定アプリを開く',
                        isDarkMode: isDarkMode,
                        onTap: () => AppSettings.openAppSettings(
                            type: AppSettingsType.notification),
                        showArrow: true,
                      ),
                      _buildDivider(isDarkMode),
                      _buildSettingsTile(
                        icon: CupertinoIcons.trash_fill,
                        iconColor: const Color(0xFF8E8E93),
                        title: 'ゴミ箱',
                        subtitle: '削除したリマインダーを確認・復元',
                        isDarkMode: isDarkMode,
                        onTap: () => Navigator.push(
                          context,
                          CupertinoPageRoute(
                              builder: (context) => DeleteTaskView()),
                        ),
                        showArrow: true,
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: Text(
                      '※ ゴミ箱のリマインダーは30日後に自動削除されます',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDarkMode ? Colors.white38 : Colors.black38,
                      ),
                    ),
                  ),

                  // アプリについてセクション
                  _buildSectionHeader('アプリについて'),
                  _buildSettingsCard(
                    cardColor: cardColor,
                    isDarkMode: isDarkMode,
                    children: [
                      _buildSettingsTile(
                        icon: CupertinoIcons.doc_text_fill,
                        iconColor: const Color(0xFF5856D6),
                        title: 'ライセンス',
                        isDarkMode: isDarkMode,
                        onTap: () => Navigator.push(
                          context,
                          CupertinoPageRoute(
                              builder: (context) => const LicenseView()),
                        ),
                        showArrow: true,
                      ),
                      _buildDivider(isDarkMode),
                      _buildSettingsTile(
                        icon: CupertinoIcons.info_circle_fill,
                        iconColor: AppTheme.confirmColor,
                        title: 'バージョン',
                        trailing: Text(
                          '1.0.0',
                          style: TextStyle(
                            fontSize: 15,
                            color: isDarkMode ? Colors.white54 : Colors.black45,
                          ),
                        ),
                        isDarkMode: isDarkMode,
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
            BannerAdWidget(placement: AdPlacement.settings),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 16),
      child: Row(
        children: [
          CupertinoButton(
            padding: const EdgeInsets.all(8),
            onPressed: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDarkMode
                    ? AppTheme.secondaryColor.withOpacity(0.2)
                    : AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                CupertinoIcons.back,
                size: 20,
                color: isDarkMode
                    ? AppTheme.secondaryColor
                    : AppTheme.primaryColor,
              ),
            ),
          ),
          const Spacer(),
          Text(
            '設定',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          const Spacer(),
          const SizedBox(width: 44), // バランス用
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 24, 8, 12),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppTheme.primaryColor,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildSettingsCard({
    required Color cardColor,
    required bool isDarkMode,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
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
      child: Column(children: children),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    String? subtitle,
    Widget? trailing,
    required bool isDarkMode,
    VoidCallback? onTap,
    bool showArrow = false,
  }) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: iconColor, size: 18),
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
                      fontWeight: FontWeight.w500,
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDarkMode ? Colors.white54 : Colors.black45,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null) trailing,
            if (showArrow)
              Icon(
                CupertinoIcons.chevron_right,
                size: 16,
                color: isDarkMode ? Colors.white30 : Colors.black26,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    required bool isDarkMode,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 18),
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
                    fontWeight: FontWeight.w500,
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
          CupertinoSwitch(
            value: value,
            activeTrackColor: AppTheme.primaryColor,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildDivider(bool isDarkMode) {
    return Container(
      margin: const EdgeInsets.only(left: 62),
      height: 1,
      color: isDarkMode
          ? AppTheme.secondaryColor.withOpacity(0.1)
          : AppTheme.primaryColor.withOpacity(0.08),
    );
  }
}

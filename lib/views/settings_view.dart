import 'package:flutter/material.dart';
import 'package:deadline_manager/views/delete_task_view.dart';
import 'package:deadline_manager/views/license_view.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:deadline_manager/view_models/theme_view_model.dart';
import 'package:app_settings/app_settings.dart';
import 'package:deadline_manager/widgets/banner_ad_widget.dart';
import 'package:deadline_manager/services/ad_service.dart';

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
    setState(() {
      _showDeleteConfirmation = value;
    });
  }

  String _getThemeText(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return 'システム設定に従う';
      case ThemeMode.light:
        return 'ライトモード';
      case ThemeMode.dark:
        return 'ダークモード';
    }
  }

  void _showThemeSelectionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        final currentTheme = ref.read(themeViewModelProvider);
        return SimpleDialog(
          title: const Text('テーマ設定'),
          children: [
            RadioListTile<ThemeMode>(
              title: const Text('システム設定に従う'),
              value: ThemeMode.system,
              groupValue: currentTheme,
              onChanged: (value) {
                ref.read(themeViewModelProvider.notifier).setTheme(value!);
                Navigator.pop(context);
              },
            ),
            RadioListTile<ThemeMode>(
              title: const Text('ライトモード'),
              value: ThemeMode.light,
              groupValue: currentTheme,
              onChanged: (value) {
                ref.read(themeViewModelProvider.notifier).setTheme(value!);
                Navigator.pop(context);
              },
            ),
            RadioListTile<ThemeMode>(
              title: const Text('ダークモード'),
              value: ThemeMode.dark,
              groupValue: currentTheme,
              onChanged: (value) {
                ref.read(themeViewModelProvider.notifier).setTheme(value!);
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('設定'),
        centerTitle: true,
      ),
      body: ListView(
        children: [
          _buildSettingsSection(
            context,
            title: '一般',
            children: [
              _buildSettingsTile(
                context,
                icon: Icons.brightness_6_outlined,
                title: 'テーマ',
                subtitle: _getThemeText(ref.watch(themeViewModelProvider)),
                onTap: () => _showThemeSelectionDialog(context),
              ),
              SwitchListTile(
                secondary: Icon(Icons.warning_amber_rounded,
                    color: Theme.of(context).colorScheme.onSurfaceVariant),
                title: const Text('リマインダー削除時の確認'),
                subtitle: const Text('削除前に確認ダイアログを表示します'),
                value: _showDeleteConfirmation,
                onChanged: _updateDeleteConfirmation,
              ),
              _buildSettingsTile(
                context,
                icon: Icons.notifications_outlined,
                title: '端末の通知設定',
                subtitle: '端末の設定アプリを開きます',
                onTap: () => AppSettings.openAppSettings(
                    type: AppSettingsType.notification),
              ),
              _buildSettingsTile(
                context,
                icon: Icons.delete_outline,
                title: 'ゴミ箱',
                subtitle: '削除したリマインダーを確認・復元します\n※30日経過すると自動削除されます',
                isThreeLine: true,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => DeleteTaskView()),
                  );
                },
              ),
            ],
          ),
          _buildSettingsSection(
            context,
            title: 'アプリについて',
            children: [
              _buildSettingsTile(
                context,
                icon: Icons.policy_outlined,
                title: 'ライセンス',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const LicenseView()),
                  );
                },
              ),
              _buildSettingsTile(
                context,
                icon: Icons.info_outline,
                title: 'バージョン',
                trailing: Text(
                  '1.0.0',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      // 画面下部にバナー広告を配置
      bottomNavigationBar: BannerAdWidget(placement: AdPlacement.settings),
    );
  }

  Widget _buildSettingsSection(BuildContext context,
      {required String title, required List<Widget> children}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        ...children,
      ],
    );
  }

  Widget _buildSettingsTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
    bool isThreeLine = false,
  }) {
    return ListTile(
      leading:
          Icon(icon, color: Theme.of(context).colorScheme.onSurfaceVariant),
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle) : null,
      trailing:
          trailing ?? (onTap != null ? const Icon(Icons.chevron_right) : null),
      onTap: onTap,
      isThreeLine: isThreeLine,
    );
  }
}

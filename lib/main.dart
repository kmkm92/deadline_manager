import 'package:flutter/material.dart';
import 'package:deadline_manager/theme/app_theme.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:timezone/data/latest_all.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'views/home_view.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:deadline_manager/view_models/theme_view_model.dart';
import 'package:deadline_manager/services/ad_service.dart';

Future<void> main() async {
  initializeDateFormatting('ja');
  WidgetsFlutterBinding.ensureInitialized();
  initializeTimeZones();
  // tz.initializeTimeZones();
  tz.setLocalLocation(tz.getLocation("Asia/Tokyo"));
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  final InitializationSettings initializationSettings = InitializationSettings(
      iOS: DarwinInitializationSettings(
          requestSoundPermission: true,
          requestBadgePermission: true,
          requestAlertPermission: true,
          onDidReceiveLocalNotification:
              (int id, String? title, String? body, String? payload) async {}),
      macOS: DarwinInitializationSettings(
          requestSoundPermission: true,
          requestBadgePermission: true,
          requestAlertPermission: true));
  flutterLocalNotificationsPlugin.initialize(initializationSettings);

  // AdMob初期化
  await AdService.initialize();

  runApp(ProviderScope(child: DeadlineManagerApp()));
}

class DeadlineManagerApp extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ScreenUtilInit(
      designSize: const Size(375, 812), // Standard mobile size
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp(
          title: 'Deadline Manager',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ref.watch(themeViewModelProvider),
          home: HomeView(),
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}

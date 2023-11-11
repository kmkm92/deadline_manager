import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:timezone/data/latest_all.dart';
import 'views/home_view.dart';
import 'package:timezone/timezone.dart' as tz;

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
              (int id, String? title, String? body, String? payload) async {}));
  flutterLocalNotificationsPlugin.initialize(initializationSettings);

  runApp(ProviderScope(child: DeadlineManagerApp()));
}

class DeadlineManagerApp extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'Deadline Manager',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
      ),
      home: HomeView(),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/data/latest_all.dart';
import 'views/home_view.dart';
import 'package:timezone/timezone.dart' as tz;

Future<void> main() async {
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

class DeadlineManagerApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Deadline Manager',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: HomeView(),
    );
  }
}

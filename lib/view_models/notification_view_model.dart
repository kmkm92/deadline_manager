import 'dart:math';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../models/task.dart';

final notificationProvider = Provider<NotificationViewModel>((ref) {
  final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  return NotificationViewModel(
    flutterLocalNotificationsPlugin: flutterLocalNotificationsPlugin,
  );
});

class NotificationViewModel {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;

  NotificationViewModel({required this.flutterLocalNotificationsPlugin});

  Future<void> scheduleNotification(Task task) async {
    final int notificationId = Random().nextInt(100000);
    await flutterLocalNotificationsPlugin.zonedSchedule(
      notificationId,
      'Task due',
      task.title,
      tz.TZDateTime.from(task.dueDate, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'your channel id',
          'your channel name',
        ),
      ),
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:deadline_manager/view_models/notification_view_model.dart';

// final notificationProvider = Provider<NotificationViewModel>((ref) {
//   final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
//   return NotificationViewModel(
//     flutterLocalNotificationsPlugin: flutterLocalNotificationsPlugin,
//   );
// });


// class NotificationPage extends ConsumerWidget {
//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     final viewModel = ref.watch(notificationProvider);

//     return Scaffold(
//       body: Center(
//         child: TextButton(
//           child: Text('Show Notification'),
//           onPressed: viewModel.showNotification,
//         ),
//       ),
//     );
//   }
// }

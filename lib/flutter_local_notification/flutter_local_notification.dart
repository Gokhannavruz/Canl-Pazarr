import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'package:timezone/timezone.dart' as tz;

// Future<void> createNotification({
//   required int id,
//   required String title,
//   required String body,
//   String? payload,
//   required FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin,
// }) async {
//   const AndroidNotificationDetails androidPlatformChannelSpecifics =
//       AndroidNotificationDetails(
//     'your channel id',
//     'your channel name',
//     importance: Importance.max,
//     priority: Priority.high,
//     showWhen: false,
//   );
//   const NotificationDetails platformChannelSpecifics =
//       NotificationDetails(android: androidPlatformChannelSpecifics);
//   await flutterLocalNotificationsPlugin.show(
//     id,
//     title,
//     body,
//     platformChannelSpecifics,
//     payload: payload,
//   );
// }

// class Noti {
//   static Future initialize(
//       FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin) async {
//     var androidInitialize = new AndroidInitializationSettings('giftinglogo2');

//     var initializationsSettings = new InitializationSettings(
//       android: androidInitialize,
//     );
//     await flutterLocalNotificationsPlugin.initialize(initializationsSettings);
//   }

//   static Future showBigTextNotification(
//       FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin,
//       {var id = 0,
//       required String title,
//       required String body,
//       var payload,
//       required FlutterLocalNotificationsPlugin fln}) async {
//     AndroidNotificationDetails androidPlatformChannelSpecifics =
//         new AndroidNotificationDetails(
//       'you_can_name_it_whatever1',
//       'channel_name',
//       playSound: false,
//       // sound: RawResourceAndroidNotificationSound('notification'),
//       importance: Importance.max,
//       priority: Priority.high,
//     );

//     var not = NotificationDetails(
//       android: androidPlatformChannelSpecifics,
//     );
//     await fln.show(id, title, body, not, payload: payload);
//   }
// }

class NotificationService {
  final FlutterLocalNotificationsPlugin notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> initNotification() async {
    AndroidInitializationSettings initializationSettingsAndroid =
        const AndroidInitializationSettings('mipmap/ic_launcher');

    var initializationSettingsIOS = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
        onDidReceiveLocalNotification:
            (int id, String? title, String? body, String? payload) async {});

    var initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid, iOS: initializationSettingsIOS);
    await notificationsPlugin.initialize(initializationSettings,
        onDidReceiveNotificationResponse:
            (NotificationResponse notificationResponse) async {});
  }

  notificationDetails() {
    return const NotificationDetails(
        android: AndroidNotificationDetails(
          'channelId',
          'channelName',
          importance: Importance.max,
          playSound: true,
        ),
        iOS: DarwinNotificationDetails());
  }

  Future showNotification(
      {int id = 0, String? title, String? body, String? payLoad}) async {
    await initNotification(); // initialize the plugin if not initialized
    await notificationsPlugin.show(
        id, title, body, await notificationDetails());
  }

  Future scheduleNotification(
      {int id = 0,
      String? title,
      String? body,
      String? payLoad,
      required DateTime scheduledNotificationDateTime}) async {
    await initNotification(); // initialize the plugin if not initialized
    return notificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.from(
          scheduledNotificationDateTime,
          tz.local,
        ),
        await notificationDetails(),
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime);
  }
}

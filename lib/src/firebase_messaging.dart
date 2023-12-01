import 'package:firebase_messaging/firebase_messaging.dart';

class FirebaseMessagingService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  Future<void> setupFirebaseMessaging() async {
    // Cihaz token'ını almak için izin isteyin
    await _fcm.requestPermission(sound: true, badge: true, alert: true);

    // Cihaz token'ını alın ve sunucunuza gönderin (Bu, kullanıcıya özel bildirimler için kullanılabilir)
    String? fcmToken = await _fcm.getToken();
    print('FCM Token: $fcmToken');

    // Bildirimleri dinlemek için gerekli konfigürasyon
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Received a message from Firebase: ${message.notification?.body}');
      // show notification
    });

    // Uygulama arka planda çalışırken bildirim açılacaksa, kullanıcı bildirime tıkladığında hangi sayfaya yönlendireceğimizi belirlemek için bu listener'ı kullanabiliriz.
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print(
          'User tapped on the notification in background: ${message.notification?.body}');
      // redirect user to specific page
    });
  }
}

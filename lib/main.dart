import 'dart:io';
import 'dart:convert';
import 'dart:io';
import 'dart:convert';
import 'package:animal_trade/screens/location_picker_screen.dart';
import 'package:animal_trade/screens/message_screen.dart';
import 'package:animal_trade/screens/services/firebase_messaging_service.dart';
import 'package:animal_trade/src/rvncat_constant.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:google_fonts/google_fonts.dart';
// import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import 'package:animal_trade/providers/user_provider.dart';
import 'package:animal_trade/responsive/mobile_screen_layout.dart';
import 'package:animal_trade/responsive/responsive_layout_screen.dart';
import 'package:animal_trade/responsive/web_screen_layout.dart';
import 'package:animal_trade/screens/login_screen.dart';
import 'package:animal_trade/utils/colors.dart';
import 'package:firebase_app_check/firebase_app_check.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'firebase_options.dart';

// Conditionally import dart:io
import 'dart:io'
    if (dart.library.html) 'package:animal_trade/utils/web_stub.dart' as io;
import 'screens/location_picker_demo.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("Handling a background message: ${message.messageId}");

  // Mesaj tipine göre işlem yapma
  if (message.data['type'] == 'message') {
    print("Yeni mesaj bildirimi alındı: ${message.notification?.title}");

    // FCM tarafından gönderilen default notification,
    // UI'a tıklanabilir bir bildirim olarak zaten gösterilecek
    // Arka planda çalışan bu handler'da fazla işlem yapmıyoruz
    // Eğer ihtiyaç olursa burada Flutter Local Notifications kullanılabilir
  }
}

Future<void> requestNotificationPermissions() async {
  FirebaseMessaging messaging = FirebaseMessaging.instance;

  NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    announcement: false,
    badge: true,
    carPlay: false,
    criticalAlert: false,
    provisional: false,
    sound: true,
  );

  print('User granted permission: ${settings.authorizationStatus}');
}

Future<void> setupLocalNotifications() async {
  // Skip local notifications setup on web
  if (kIsWeb) {
    print("Skipping local notifications setup on web platform");
    return;
  }

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Android için
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  // iOS için
  const DarwinInitializationSettings initializationSettingsIOS =
      DarwinInitializationSettings(
    requestAlertPermission: true,
    requestBadgePermission: true,
    requestSoundPermission: true,
  );

  // Ayarları birleştir
  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    iOS: initializationSettingsIOS,
  );

  // Bildirim tıklandığında
  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse: (NotificationResponse response) {
      if (response.payload != null) {
        Map<String, dynamic> data = jsonDecode(response.payload!);
        print('Bildirim tıklandı, yük: $data');
        // Burada bildirime tıklandığında yapılacak işlemleri belirleyebilirsiniz
      }
    },
  );
}

Future<void> _handleBackgroundMessage(RemoteMessage message) async {
  print("Handling background message: ${message.messageId}");
  // Burada minimum işlem yapın, yalnızca loglama gibi hafif işlemler olmalı
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Turkish locale data for date formatting
  try {
    await initializeDateFormatting('tr_TR', null);
    print("Turkish locale data initialized successfully");
  } catch (e) {
    print("Error initializing Turkish locale data: $e");
    // Continue with the app even if locale initialization fails
  }

  // Firebase initialization with better error handling
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print("Firebase initialized successfully in Flutter");
  } catch (e) {
    print("Firebase initialization error in Flutter: $e");
    // Continue with the app even if Firebase fails
  }

  // FCM handling (skip on web or handle differently)
  try {
    if (!kIsWeb) {
      // Set background message handler BEFORE FCM service initialization
      FirebaseMessaging.onBackgroundMessage(
          _firebaseMessagingBackgroundHandler);
    }

    // Initialize FCM service
    await FCMService().initialize();
  } catch (e) {
    print("FCM initialization error: $e");
    // Continue with the app even if FCM fails
  }

  // AdMob initialization removed

  // Notification permissions (skip on web or handle differently)
  if (!kIsWeb) {
    await requestNotificationPermissions();
    await setupLocalNotifications();
  }

  // Store configuration (skip on web)
  if (!kIsWeb) {
    bool isIOS = false;
    bool isAndroid = false;
    bool isMacOS = false;

    try {
      isIOS = io.Platform.isIOS;
      isAndroid = io.Platform.isAndroid;
      isMacOS = io.Platform.isMacOS;
    } catch (e) {
      print("Error detecting platform: $e");
    }
  }

  // FirebaseAppCheck initialization (with web handling)
  try {
    if (kIsWeb) {
      await FirebaseAppCheck.instance.activate(
        webProvider: ReCaptchaV3Provider('YOUR_RECAPTCHA_SITE_KEY_HERE'),
      );
    } else {
      await FirebaseAppCheck.instance.activate(
        androidProvider: AndroidProvider.debug,
        appleProvider: AppleProvider.debug,
      );
    }
  } catch (e) {
    print("Error initializing Firebase App Check: $e");
  }

  // Arka plan mesaj işleyicisini ayarla (skip on web)
  if (!kIsWeb) {
    FirebaseMessaging.onBackgroundMessage(_handleBackgroundMessage);
  }

  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  MyApp({Key? key}) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();

    // FCM mesaj işleme için gerekli dinleyicileri kuralım
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Uygulama açıldığında bildirim kontrolü
    _checkForInitialMessage();
  }

  SystemUiOverlayStyle _systemUiOverlayStyle() {
    return const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.light,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Call setupInteractedMessage here, after the context is available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setupInteractedMessage(context);
    });

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<UserProvider>(
          create: (context) {
            final provider = UserProvider();
            provider.initialize();
            return provider;
          },
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'CanlıPazar',
        theme: ThemeData.light().copyWith(
          scaffoldBackgroundColor: Colors.white,
          primaryColor: const Color(0xFF2E7D32),
          colorScheme: ColorScheme.light(
            primary: const Color(0xFF2E7D32),
            secondary: const Color(0xFFFF9800),
            surface: const Color(0xFFF5F5F5),
            background: Colors.white,
            onPrimary: Colors.white,
            onSecondary: Colors.white,
            onSurface: const Color(0xFF000000),
            onBackground: const Color(0xFF000000),
          ),
          textSelectionTheme: TextSelectionThemeData(
            cursorColor: Colors.black,
            selectionColor: Colors.black.withOpacity(0.3),
            selectionHandleColor: Colors.black,
          ),
          inputDecorationTheme: InputDecorationTheme(
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: const Color(0xFF2E7D32)),
            ),
            border: OutlineInputBorder(
              borderSide: BorderSide(color: const Color(0xFFE0E0E0)),
            ),
          ),
        ),
        routes: {
          '/login': (context) => const LoginScreen(),
          '/location': (context) => const LocationPickerScreen(),
          '/location_picker': (context) => const LocationPickerDemo(),
        },
        onUnknownRoute: (settings) {
          return MaterialPageRoute(
            builder: (context) => const LoginScreen(),
          );
        },
        initialRoute: '/',
        onGenerateRoute: (settings) {
          if (settings.name == '/') {
            return MaterialPageRoute(
              builder: (context) => Consumer<UserProvider>(
                builder: (context, userProvider, child) {
                  // Minimal splash screen
                  if (userProvider.isLoading) {
                    return Scaffold(
                      backgroundColor: const Color(0xFF2E7D32),
                      body: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // App name
                            Text(
                              'CanlıPazar',
                              style: GoogleFonts.poppins(
                                fontSize: 32,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Güvenilir hayvan alım satım platformu',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                                color: Colors.white.withOpacity(0.8),
                                letterSpacing: 0.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  // Kullanıcı giriş yapmış
                  final userUid = userProvider.getUser?.uid;
                  if (userUid != null && userUid.isNotEmpty) {
                    return const ResponsiveLayout(
                      mobileScreenLayout: MobileScreenLayout(),
                      webScreenLayout: WebScreenLayout(),
                    );
                  } else {
                    // Kullanıcı giriş yapmamış
                    return const LoginScreen();
                  }
                },
              ),
            );
          }
          return null;
        },
      ),
    );
  }

  void setupInteractedMessage(BuildContext context) async {
    RemoteMessage? initialMessage =
        await FirebaseMessaging.instance.getInitialMessage();

    if (initialMessage != null) {
      _handleMessage(initialMessage, context);
    }

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleMessage(message, context);
    });
  }

  void _handleMessage(RemoteMessage message, BuildContext context) {
    if (message.data['type'] == 'message') {
      // Mesaj sayfasına yönlendirme
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MessagesPage(
            currentUserUid: FirebaseAuth.instance.currentUser?.uid ?? '',
            recipientUid: message.data['sender_id'] ?? '',
            postId: message.data['post_id'] ?? '',
          ),
        ),
      );
    }
  }

  Future<void> _checkForInitialMessage() async {
    // Uygulama bildirimden başlatıldı mı kontrol et
    RemoteMessage? initialMessage =
        await FirebaseMessaging.instance.getInitialMessage();

    if (initialMessage != null) {
      // Burada direkt yönlendirme yapamazsınız, çünkü uygulama henüz tam olarak başlamadı
      // Veriyi saklayın ve uygulama başladıktan sonra yönlendirin
      print('Initial message: ${initialMessage.data}');

      // Bu veriyi bir global değişkende veya bir serviste saklayın
      // Daha sonra ana sayfaya geçildiğinde kontrol edin
    }
  }
}

// ConsentManager class removed

import 'dart:io';
import 'dart:convert';
import 'package:freecycle/screens/country_state_city_picker.dart';
import 'package:freecycle/screens/message_screen.dart';
import 'package:freecycle/screens/services/firebase_messaging_service.dart';
import 'package:freecycle/src/rvncat_constant.dart';
import 'package:freecycle/store_config.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import 'package:freecycle/providers/user_provider.dart';
import 'package:freecycle/responsive/mobile_screen_layout.dart';
import 'package:freecycle/responsive/responsive_layout_screen.dart';
import 'package:freecycle/responsive/web_screen_layout.dart';
import 'package:freecycle/screens/login_screen.dart';
import 'package:freecycle/utils/colors.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:purchases_flutter/models/store.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';

// Conditionally import dart:io
import 'dart:io' if (dart.library.html) 'package:freecycle/utils/web_stub.dart'
    as io;
import 'package:animated_text_kit/animated_text_kit.dart';
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

Future<void> _configureSDK() async {
  // Skip RevenueCat configuration on web
  if (kIsWeb) {
    print("Skipping RevenueCat configuration on web platform");
    return;
  }

  await Purchases.setLogLevel(LogLevel.debug);

  PurchasesConfiguration configuration;
  if (StoreConfig.isForAmazonAppstore()) {
    configuration = AmazonConfiguration(StoreConfig.instance.apiKey)
      ..appUserID = null;
  } else if (StoreConfig.isForAppleStore() || StoreConfig.isForGooglePlay()) {
    configuration = PurchasesConfiguration(StoreConfig.instance.apiKey)
      ..appUserID = null;
  } else {
    throw Exception("Unsupported store configuration");
  }

  await Purchases.configure(configuration);

  // Enable RevenueCat experiments
  await Purchases.enableAdServicesAttributionTokenCollection();
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

class SplashScreen extends StatefulWidget {
  final Widget? child;
  const SplashScreen({Key? key, this.child}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(seconds: 5), () {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => widget.child ?? Container()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade700, Colors.blue.shade200],
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.recycling,
              size: 100,
              color: Colors.white,
            ),
            SizedBox(height: 20),
            AnimatedTextKit(
              animatedTexts: [
                TypewriterAnimatedText(
                  'freecycle',
                  textStyle: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  speed: Duration(milliseconds: 200),
                ),
              ],
              totalRepeatCount: 1,
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _handleBackgroundMessage(RemoteMessage message) async {
  print("Handling background message: ${message.messageId}");
  // Burada minimum işlem yapın, yalnızca loglama gibi hafif işlemler olmalı
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

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

  // AdMob initialization (with web check)
  try {
    // AdMob initialization
    if (!kIsWeb) {
      await MobileAds.instance.initialize();
      print("AdMob initialized successfully");

      // Initialize consent after successful AdMob initialization
      await ConsentManager.initializeConsent();
    } else {
      print("Skipping AdMob initialization on web");
    }
  } catch (e) {
    print("Error initializing AdMob: $e");
  }

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

    if (isIOS || isMacOS) {
      StoreConfig(
        store: Store.appStore,
        apiKey: appleApiKey,
      );
    } else if (isAndroid) {
      const useAmazon = bool.fromEnvironment("amazon");
      StoreConfig(
        store: useAmazon ? Store.amazon : Store.playStore,
        apiKey: useAmazon ? amazonApiKey : googleApiKey,
      );
    }

    await _configureSDK();
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
          create: (context) => UserProvider(),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'freecycle',
        theme: ThemeData.dark().copyWith(
          scaffoldBackgroundColor: mobileBackgroundColor,
        ),
        routes: {
          '/login': (context) => const LoginScreen(),
          '/location': (context) => const CountryStateCityForFirstSelect(),
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
              builder: (context) => StreamBuilder(
                stream: FirebaseAuth.instance.authStateChanges(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.active) {
                    if (snapshot.hasData) {
                      return const ResponsiveLayout(
                        mobileScreenLayout: MobileScreenLayout(),
                        webScreenLayout: WebScreenLayout(),
                      );
                    } else if (snapshot.hasError) {
                      return Center(
                        child: Text('${snapshot.error}'),
                      );
                    }
                  }
                  return const LoginScreen();
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

class ConsentManager {
  static const String _consentShownKey = 'gdpr_consent_shown';

  static Future<void> initializeConsent() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final bool consentShown = prefs.getBool(_consentShownKey) ?? false;

      // Eğer daha önce consent gösterilmemişse devam et
      if (!consentShown) {
        ConsentRequestParameters params = ConsentRequestParameters(
          consentDebugSettings: ConsentDebugSettings(
            debugGeography:
                DebugGeography.debugGeographyDisabled, // Production için
          ),
        );

        ConsentInformation.instance.requestConsentInfoUpdate(
          params,
          () async {
            try {
              // Kullanıcının GDPR bölgesinde olup olmadığını kontrol et
              bool isConsentRequired =
                  await ConsentInformation.instance.isConsentFormAvailable();

              if (isConsentRequired) {
                await loadAndShowConsentForm();
                // Consent form gösterildi olarak işaretle
                await prefs.setBool(_consentShownKey, true);
              } else {
                // GDPR bölgesi dışındaki kullanıcılar için
                print("Consent form is not required for this region");
                await prefs.setBool(_consentShownKey, true);
              }
            } catch (e) {
              print("Error during consent check: $e");
            }
          },
          (FormError error) {
            print("Consent form error: ${error.message}");
          },
        );
      } else {
        print("Consent form has already been shown before");
      }
    } catch (e) {
      print("ConsentManager initialization error: $e");
    }
  }

  static Future<void> loadAndShowConsentForm() async {
    try {
      ConsentForm.loadConsentForm(
        (ConsentForm consentForm) async {
          try {
            consentForm.show(
              (FormError? formError) {
                if (formError != null) {
                  print("Consent form show error: ${formError.message}");
                  return;
                }
                print("Consent form shown successfully");
              },
            );
          } catch (e) {
            print("Error showing consent form: $e");
          }
        },
        (FormError formError) {
          print("Consent form load error: ${formError.message}");
        },
      );
    } catch (e) {
      print("Error loading consent form: $e");
    }
  }

  // Consent durumunu sıfırlamak için (test amaçlı)
  static Future<void> resetConsentStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_consentShownKey);
      await ConsentInformation.instance.reset();
    } catch (e) {
      print("Error resetting consent status: $e");
    }
  }
}

import 'dart:io';
import 'package:Freecycle/screens/message_screen.dart';
import 'package:Freecycle/src/rvncat_constant.dart';
import 'package:Freecycle/store_config.dart';
import 'package:another_flutter_splash_screen/another_flutter_splash_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import 'package:Freecycle/providers/user_provider.dart';
import 'package:Freecycle/responsive/mobile_screen_layout.dart';
import 'package:Freecycle/responsive/responsive_layout_screen.dart';
import 'package:Freecycle/responsive/web_screen_layout.dart';
import 'package:Freecycle/screens/login_screen.dart';
import 'package:Freecycle/utils/colors.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:purchases_flutter/models/store.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';

import 'dart:io' show Platform;
import 'package:animated_text_kit/animated_text_kit.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("Handling a background message: ${message.messageId}");
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
                  'Freecycle',
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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase initialization
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // AdMob initialization ve consent yönetimi
  await MobileAds.instance.initialize();

  await ConsentManager.initializeConsent();
  // Notification permissions
  await requestNotificationPermissions();

  // Store configuration
  if (Platform.isIOS || Platform.isMacOS) {
    StoreConfig(
      store: Store.appStore,
      apiKey: appleApiKey,
    );
  } else if (Platform.isAndroid) {
    const useAmazon = bool.fromEnvironment("amazon");
    StoreConfig(
      store: useAmazon ? Store.amazon : Store.playStore,
      apiKey: useAmazon ? amazonApiKey : googleApiKey,
    );
  }

  await _configureSDK();
  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.debug,
    appleProvider: AppleProvider.debug,
  );

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  await flutterLocalNotificationsPlugin.initialize(
    InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    ),
  );

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
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<UserProvider>(
          create: (context) => UserProvider(),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Freecycle',
        theme: ThemeData.dark().copyWith(
          scaffoldBackgroundColor: mobileBackgroundColor,
        ),
        routes: {
          '/chat': (context) {
            final args = ModalRoute.of(context)!.settings.arguments
                as Map<String, dynamic>;
            return MessagesPage(
              currentUserUid: args['currentUserUid'] ?? '',
              recipientUid: args['recipientUid'] ?? '',
              postId: args['postId'] ?? '',
            );
          },
        },
        home: SplashScreen(
          child: Builder(
            builder: (BuildContext context) {
              setupInteractedMessage(context);
              return StreamBuilder(
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
                        child: Text("${snapshot.error}"),
                      );
                    }
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: primaryColor,
                      ),
                    );
                  }
                  return const LoginScreen();
                },
              );
            },
          ),
        ),
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
    if (message.data['type'] == 'chat') {
      Navigator.pushNamed(
        context,
        '/chat',
        arguments: {
          'currentUserUid': FirebaseAuth.instance.currentUser?.uid ?? '',
          'recipientUid': message.data['recipientUid'] ?? '',
          'postId': message.data['postId'] ?? '',
        },
      );
    }
  }
}

class ConsentManager {
  static const String _consentShownKey = 'gdpr_consent_shown';

  static Future<void> initializeConsent() async {
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
        },
        (FormError error) {
          print("Consent form error: ${error.message}");
        },
      );
    } else {
      print("Consent form has already been shown before");
    }
  }

  static Future<void> loadAndShowConsentForm() async {
    try {
      ConsentForm.loadConsentForm(
        (ConsentForm consentForm) async {
          consentForm.show(
            (FormError? formError) {
              if (formError != null) {
                print("Consent form show error: ${formError.message}");
                return;
              }
              print("Consent form shown successfully");
            },
          );
        },
        (FormError formError) {
          print("Consent form load error: ${formError.message}");
        },
      );
    } catch (e) {
      print("Error showing consent form: $e");
    }
  }

  // Consent durumunu sıfırlamak için (test amaçlı)
  static Future<void> resetConsentStatus() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_consentShownKey);
    await ConsentInformation.instance.reset();
  }
}

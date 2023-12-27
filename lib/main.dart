import 'package:another_flutter_splash_screen/another_flutter_splash_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import 'package:Freecycle/providers/user_provider.dart';
import 'package:Freecycle/responsive/mobile_screen_layout.dart';
import 'package:Freecycle/responsive/responsive_layout_screen.dart';
import 'package:Freecycle/responsive/web_screen_layout.dart';
import 'package:Freecycle/screens/login_screen.dart';
import 'package:Freecycle/utils/colors.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'firebase_options.dart';
import 'src/firebase_messaging.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  // Initialize Firebase App Check
  // usage of any Firebase services.
  await FirebaseAppCheck.instance
      // Your personal reCaptcha public key goes here:
      .activate(
    androidProvider: AndroidProvider.debug,
    appleProvider: AppleProvider.debug,
  );
  MobileAds.instance.initialize();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  SystemUiOverlayStyle _systemUiOverlayStyle() {
    return const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.light,
    );
  }

  final FirebaseMessagingService _firebaseMessagingService =
      FirebaseMessagingService();

  MyApp({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    // save fcm token to firestore

    _firebaseMessagingService.setupFirebaseMessaging();
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

        // add splash screen
        home: FlutterSplashScreen.fadeIn(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              // Live blue
              Color.fromARGB(255, 68, 118, 255),
              // Live purple
              Color.fromARGB(255, 68, 118, 255),
            ],
          ),
          childWidget: SizedBox(
            height: 130,
            width: 130,
            child: Image.asset(
              'assets/frees.png',
              fit: BoxFit.contain,
            ),
          ),
          nextScreen: StreamBuilder(
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
          ),
        ),
      ),
    );
  }
}

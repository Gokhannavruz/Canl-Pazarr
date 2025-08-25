import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../providers/user_provider.dart';
import '../utils/colors.dart';
import '../utils/global_variables.dart';
import '../utils/animal_colors.dart';

class MobileScreenLayout extends StatefulWidget {
  const MobileScreenLayout({Key? key}) : super(key: key);

  @override
  State<MobileScreenLayout> createState() => _MobileScreenLayoutState();
}

class _MobileScreenLayoutState extends State<MobileScreenLayout> {
  int _page = 0;
  late PageController pageController; // for tabs animation

  @override
  void initState() {
    super.initState();
    pageController = PageController();

    // Uygulama başladığında FCM token'ı güncelle
    _updateFCMToken();
  }

  @override
  void dispose() {
    super.dispose();
    pageController.dispose();
  }

  void onPageChanged(int page) {
    setState(() {
      _page = page;
    });
  }

  void navigationTapped(int page) {
    //Animating Page
    pageController.jumpToPage(page);
  }

  // FCM token'ı güncelleyen method
  void _updateFCMToken() async {
    try {
      final currentUser =
          Provider.of<UserProvider>(context, listen: false).getUser;
      if (currentUser != null && currentUser.uid != null) {
        // Get and update FCM token
        final fcmToken = await FirebaseMessaging.instance.getToken();
        if (fcmToken != null) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(currentUser.uid)
              .update({'fcmToken': fcmToken});
          print('FCM token updated on app startup: $fcmToken');
        }
      }
    } catch (e) {
      print('Error updating FCM token on startup: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserProvider>(context).getUser;
    return Scaffold(
      body: PageView(
        physics: const NeverScrollableScrollPhysics(),
        controller: pageController,
        onPageChanged: onPageChanged,
        children: homeScreenItem,
      ),
      bottomNavigationBar: CupertinoTabBar(
        border: const Border(
          top: BorderSide(
            color: Colors.grey,
            width: 0.1,
          ),
        ),
        iconSize: 28,
        backgroundColor: Colors.white, // Arkaplan beyaz/yeşil
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Padding(
              padding: const EdgeInsets.only(top: 12.0),
              child: Icon(
                Icons.home,
                size: (_page == 0) ? 32 : 28,
                color: (_page == 0) ? Colors.black : Colors.grey.shade400,
                shadows: (_page == 0)
                    ? [
                        Shadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 6)
                      ]
                    : [],
              ),
            ),
            label: '',
            backgroundColor: AnimalColors.background,
          ),
          BottomNavigationBarItem(
            icon: Padding(
              padding: const EdgeInsets.only(top: 12.0),
              child: Icon(
                Icons.mail,
                size: (_page == 1) ? 32 : 28,
                color: (_page == 1) ? Colors.black : Colors.grey.shade400,
                shadows: (_page == 1)
                    ? [
                        Shadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 6)
                      ]
                    : [],
              ),
            ),
            label: '',
            backgroundColor: AnimalColors.background,
          ),
          BottomNavigationBarItem(
            icon: Padding(
              padding: const EdgeInsets.only(top: 12.0),
              child: Icon(
                Icons.add_circle_outline,
                size: (_page == 2) ? 36 : 28,
                color: (_page == 2) ? Colors.black : Colors.grey.shade400,
                shadows: (_page == 2)
                    ? [
                        Shadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 8)
                      ]
                    : [],
              ),
            ),
            label: '',
            backgroundColor: AnimalColors.background,
          ),
          BottomNavigationBarItem(
            icon: Padding(
              padding: const EdgeInsets.only(top: 12.0),
              child: Icon(
                Icons.local_hospital,
                size: (_page == 3) ? 32 : 28,
                color: (_page == 3) ? Colors.black : Colors.grey.shade400,
                shadows: (_page == 3)
                    ? [
                        Shadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 6)
                      ]
                    : [],
              ),
            ),
            label: '',
            backgroundColor: AnimalColors.background,
          ),
          BottomNavigationBarItem(
            icon: Padding(
              padding: const EdgeInsets.only(top: 12.0),
              child: Icon(
                Icons.person,
                size: (_page == 4) ? 32 : 28,
                color: (_page == 4) ? Colors.black : Colors.grey.shade400,
                shadows: (_page == 4)
                    ? [
                        Shadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 6)
                      ]
                    : [],
              ),
            ),
            label: '',
            backgroundColor: AnimalColors.background,
          ),
        ],
        onTap: navigationTapped,
        currentIndex: _page,
      ),
    );
  }
}

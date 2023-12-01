import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/user_provider.dart';
import '../utils/colors.dart';
import '../utils/global_variables.dart';

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
        backgroundColor: mobileBackgroundColor,
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Padding(
              padding: const EdgeInsets.only(top: 12.0),
              child: Icon(
                Icons.home,
                color: (_page == 0) ? primaryColor : secondaryColor,
              ),
            ),
            label: '',
            backgroundColor: primaryColor,
          ),
          BottomNavigationBarItem(
              // asset image
              icon: Padding(
                padding: const EdgeInsets.only(top: 12.0),
                child: Icon(
                  Icons.mail,
                  color: (_page == 1) ? primaryColor : secondaryColor,
                ),
              ),
              label: '',
              backgroundColor: primaryColor),
          BottomNavigationBarItem(
            icon: Padding(
              padding: const EdgeInsets.only(top: 12.0),
              child: Icon(
                Icons.add_circle_outline,
                color: (_page == 3) ? primaryColor : secondaryColor,
              ),
            ),
            label: '',
            backgroundColor: primaryColor,
          ),
          BottomNavigationBarItem(
            icon: Padding(
              padding: const EdgeInsets.only(top: 12.0),
              child: Icon(
                Icons.person,
                color: (_page == 4) ? primaryColor : secondaryColor,
              ),
            ),
            label: '',
            backgroundColor: primaryColor,
          ),
        ],
        onTap: navigationTapped,
        currentIndex: _page,
      ),
    );
  }
}

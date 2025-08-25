import 'package:flutter/material.dart';
import 'package:animal_trade/utils/global_variables.dart';
import 'package:animal_trade/utils/colors.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class WebScreenLayout extends StatefulWidget {
  const WebScreenLayout({Key? key}) : super(key: key);

  @override
  State<WebScreenLayout> createState() => _WebScreenLayoutState();
}

class _WebScreenLayoutState extends State<WebScreenLayout> {
  int _page = 0;
  late PageController pageController;

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

  void navigationTapped(int page) {
    pageController.jumpToPage(page);
    setState(() {
      _page = page;
    });
  }

  void onPageChanged(int page) {
    setState(() {
      _page = page;
    });
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    bool isWideScreen = screenWidth > 1200;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black.withOpacity(0.8),
        elevation: 0,
        centerTitle: false,
        title: Row(
          children: [
            Text(
              'freecycle',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 1.5,
              ),
            ),
            SizedBox(width: 8),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'WEB',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        actions: [
          Container(
            margin: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            width: isWideScreen ? 300 : 200,
            decoration: BoxDecoration(
              color: Colors.grey[800],
              borderRadius: BorderRadius.circular(20),
            ),
            child: TextField(
              style: TextStyle(fontSize: 14, color: Colors.white),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: 'Search...',
                hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                prefixIcon:
                    Icon(Icons.search, color: Colors.grey[400], size: 20),
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                isDense: true,
              ),
            ),
          ),
        ],
      ),
      body: Row(
        children: [
          // Sidebar (for wide screens only)
          if (isWideScreen)
            Container(
              width: 200,
              color: Colors.grey[900],
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Column(
                children: [
                  _buildSidebarItem(Icons.home, 'Home', 0),
                  _buildSidebarItem(Icons.mail, 'Messages', 1),
                  _buildSidebarItem(Icons.add_circle_outline, 'Add Post', 2),
                  _buildSidebarItem(Icons.local_hospital, 'Veterinarians', 3),
                  _buildSidebarItem(Icons.person, 'Profile', 4),
                  _buildSidebarItem(Icons.category, 'Categories', -1,
                      onTap: () {}),
                  _buildSidebarItem(Icons.location_on, 'Location', -1,
                      onTap: () {}),
                  _buildSidebarItem(Icons.search, 'Search', -1, onTap: () {
                    // Navigate to search page
                  }),
                  Divider(color: Colors.grey[800], height: 40),
                  _buildSidebarItem(Icons.settings, 'Settings', -1,
                      onTap: () {}),
                  _buildSidebarItem(Icons.help_outline, 'Help', -1,
                      onTap: () {}),
                  Spacer(),
                  _buildSidebarItem(Icons.exit_to_app, 'Logout', -1,
                      onTap: () {}),
                ],
              ),
            ),
          // Main content area
          Expanded(
            child: PageView(
              physics: const NeverScrollableScrollPhysics(),
              controller: pageController,
              onPageChanged: onPageChanged,
              children: homeScreenItem,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int pageIndex) {
    final bool isSelected = _page == pageIndex;

    return Tooltip(
      message: label,
      child: InkWell(
        onTap: () => navigationTapped(pageIndex),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isSelected ? primaryColor : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Icon(
            icon,
            color: isSelected ? primaryColor : Colors.white,
            size: 24,
          ),
        ),
      ),
    );
  }

  Widget _buildSidebarItem(IconData icon, String label, int pageIndex,
      {VoidCallback? onTap}) {
    final bool isSelected = _page == pageIndex;

    return InkWell(
      onTap: onTap ?? () => navigationTapped(pageIndex),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? primaryColor : Colors.white,
              size: 22,
            ),
            SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? primaryColor : Colors.white,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

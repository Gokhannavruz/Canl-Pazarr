import 'dart:io';

import 'package:freecycle/screens/android_substermsofuse.dart';
import 'package:freecycle/screens/country_state_city_picker.dart';
import 'package:freecycle/src/model/experiment_manager.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:freecycle/responsive/mobile_screen_layout.dart';
import 'package:freecycle/responsive/responsive_layout_screen.dart';
import 'package:freecycle/responsive/web_screen_layout.dart';
import 'package:freecycle/src/model/singletons_data.dart';
import 'package:freecycle/src/rvncat_constant.dart';
import 'package:freecycle/src/views/subscriptionterms_page.dart';
import 'package:google_fonts/google_fonts.dart';

class PaywallForFirstLaunch extends StatefulWidget {
  final Offering offering;

  const PaywallForFirstLaunch({Key? key, required this.offering})
      : super(key: key);

  @override
  _PaywallForFirstLaunchState createState() => _PaywallForFirstLaunchState();
}

class _PaywallForFirstLaunchState extends State<PaywallForFirstLaunch>
    with TickerProviderStateMixin {
  int? _selectedPackageIndex;
  late List<Package> _sortedPackages;
  bool _isInTreatmentGroup = false;
  bool _isLoading = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Add a glow animation controller and animation
  late AnimationController _glowAnimationController;
  late Animation<double> _glowAnimation;

  // Consistent color scheme for better visual harmony
  final Color _primaryColor = Color(0xFF36B37E); // Fresh green
  final Color _primaryDarkColor = Color(0xFF2E9D71); // Deeper green
  final Color _secondaryColor = Color(0xFF2684FF); // Bright blue
  final Color _accentColor = Color(0xFFFFAB00); // Warm amber/gold
  final Color _accentDarkColor = Color(0xFFF08C00); // Deeper amber
  final Color _surfaceColor = Colors.white;
  final Color _textPrimaryColor = Colors.white;
  final Color _textSecondaryColor = Colors.white70;

  // Consistent gradient for primary buttons and selected items
  LinearGradient get _primaryGradient => LinearGradient(
        colors: [_primaryColor, _secondaryColor],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  // Premium gradient for highlighted elements
  LinearGradient get _premiumGradient => LinearGradient(
        colors: [_accentColor, _accentDarkColor],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      );

  // Premium features
  final List<Map<String, dynamic>> _premiumFeatures = [
    {
      'icon': Icons.chat_rounded,
      'title': 'Unlimited Messaging Access',
      'description': 'Be first to claim items before they\'re gone'
    },
    {
      'icon': Icons.shopping_bag_rounded,
      'title': 'Priority Item Requests',
      'description': 'Get higher chances of receiving the items you need'
    },
    {
      'icon': Icons.savings_rounded,
      'title': 'Save Hundreds of Dollars',
      'description': 'Get unlimited free items instead of buying new'
    },
    {
      'icon': Icons.verified_user_rounded,
      'title': 'Verified Member Status',
      'description': 'Donors prefer giving items to premium members'
    },
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutQuint,
      ),
    );

    // Initialize the glow animation controller
    _glowAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _glowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _glowAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    _validateOffering();
    _initializeExperiment();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _glowAnimationController.dispose(); // Clean up the controller
    super.dispose();
  }

  void _validateOffering() {
    if (widget.offering.availablePackages.isEmpty) {
      print('Warning: Offering has no available packages!');
    } else {
      print(
          'Offering has ${widget.offering.availablePackages.length} packages');
      for (var package in widget.offering.availablePackages) {
        print(
            'Available Package: ${package.identifier} - ${package.packageType} - ${package.storeProduct.priceString}');
      }
    }
  }

  Future<void> _initializeExperiment() async {
    try {
      // Get all available packages from the offering - show ALL packages to everyone
      _sortedPackages = List<Package>.from(widget.offering.availablePackages);

      // Check if we have packages
      if (_sortedPackages.isEmpty) {
        print('Warning: No packages available from offering');
        setState(() {
          _isLoading = false;
        });
        _animationController.forward();
        return;
      }

      // Log packages for debugging
      print('Available packages: ${_sortedPackages.length}');
      for (var package in _sortedPackages) {
        print('Using package: ${package.identifier} - ${package.packageType}');
      }

      // Sort the packages by type
      _sortPackages();

      // Select a default package (annual)
      _selectDefaultPackage();

      setState(() {
        _isLoading = false;
        // Set _isInTreatmentGroup to false for all users
        _isInTreatmentGroup = false;
      });

      _animationController.forward();
    } catch (e) {
      print('Error initializing packages: $e');

      // Fallback logic
      try {
        _sortedPackages = List<Package>.from(widget.offering.availablePackages);
        _sortPackages();
        _selectDefaultPackage();
      } catch (fallbackError) {
        print('Error in fallback logic: $fallbackError');
        _sortedPackages = [];
      }

      setState(() {
        _isLoading = false;
        // Set _isInTreatmentGroup to false for all users
        _isInTreatmentGroup = false;
      });

      _animationController.forward();
    }
  }

  void _selectDefaultPackage() {
    // Try to select the annual package by default
    for (int i = 0; i < _sortedPackages.length; i++) {
      if (_sortedPackages[i].packageType == PackageType.annual) {
        _selectedPackageIndex = i;
        return;
      }
    }

    // If no annual package, select the first package
    if (_sortedPackages.isNotEmpty) {
      _selectedPackageIndex = 0;
    } else {
      _selectedPackageIndex = null;
    }
  }

  void _sortPackages() {
    _sortedPackages.sort((a, b) {
      return _getPackagePriority(a.packageType) -
          _getPackagePriority(b.packageType);
    });
  }

  int _getPackagePriority(PackageType packageType) {
    switch (packageType) {
      case PackageType.weekly:
        return 0;
      case PackageType.monthly:
        return 1;
      case PackageType.annual:
        return 2;
      default:
        return 3;
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = size.width;
    final screenHeight = size.height;
    final isSmallScreen = screenWidth < 360;
    final isLandscape = screenWidth > screenHeight;
    final statusBarHeight = MediaQuery.of(context).viewPadding.top;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: null,
      body: Stack(
        children: [
          // Premium background with improved gradient
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF1A237E).withOpacity(0.9), // Deep indigo
                  Color(0xFF283593).withOpacity(0.95), // Rich indigo
                  Color(0xFF1565C0).withOpacity(0.9), // Blue
                  Color(0xFF0D47A1).withOpacity(0.95), // Dark blue
                ],
                stops: [0.0, 0.3, 0.7, 1.0],
              ),
            ),
            child: CustomPaint(
              painter: BubblesPainter(),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.5),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Main content
          _isLoading
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 40,
                        height: 40,
                        child: CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                          strokeWidth: 3,
                        ),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Preparing subscription options...',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                )
              : Padding(
                  padding: EdgeInsets.only(top: statusBarHeight),
                  child: _buildMainContent(size, isSmallScreen, isLandscape),
                ),

          // Close button positioned at the very top of the page
          Positioned(
            top: statusBarHeight + 10,
            right: 16,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (_) => CountryStateCityForFirstSelect(),
                  ),
                ),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: Colors.white.withOpacity(0.2), width: 0.5),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.close,
                      color: Colors.white.withOpacity(0.7),
                      size: 20,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent(Size size, bool isSmallScreen, bool isLandscape) {
    final horizontalPadding = isSmallScreen ? 16.0 : 24.0;
    final statusBarHeight = MediaQuery.of(context).viewPadding.top;

    return LayoutBuilder(builder: (context, constraints) {
      // Get available dimensions
      final screenWidth = constraints.maxWidth;
      final screenHeight = constraints.maxHeight;

      // Determine if it's a very small device
      final isTinyScreen = screenWidth < 320 || screenHeight < 600;
      final isLargeScreen = screenWidth > 600;

      // Adjust spacing for different screen sizes
      final verticalSpacing =
          isTinyScreen ? 16.0 : (isSmallScreen ? 24.0 : 32.0);
      final titleFontSize = isTinyScreen ? 20.0 : (isSmallScreen ? 24.0 : 28.0);
      final packageHeight =
          isTinyScreen ? 110.0 : (isSmallScreen ? 130.0 : 140.0);

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Extra space for close button
          SizedBox(height: 40),

          // Scrollable content
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Title section
                  _buildTitleSection(
                      isSmallScreen, isTinyScreen, titleFontSize),
                  SizedBox(height: verticalSpacing * 0.75),

                  // Features
                  ..._buildFeaturesList(isSmallScreen, isTinyScreen),
                  SizedBox(height: verticalSpacing * 0.75),

                  // Choose your plan text
                  Text(
                    'Choose Your Access Plan',
                    style: GoogleFonts.montserrat(
                      textStyle: TextStyle(
                        color: Colors.white,
                        fontSize: isTinyScreen ? 14 : (isSmallScreen ? 16 : 18),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: verticalSpacing * 0.5),

                  // Package options
                  _sortedPackages.isEmpty
                      ? _buildErrorMessage()
                      : _buildPackageOptions(isSmallScreen, isTinyScreen,
                          packageHeight, screenWidth)[0],
                  SizedBox(height: verticalSpacing * 0.75),

                  // Continue button
                  _buildContinueButton(isSmallScreen, isTinyScreen),
                  SizedBox(height: verticalSpacing * 0.5),

                  // Footer
                  _buildFooter(isSmallScreen, isTinyScreen),
                  SizedBox(height: isTinyScreen ? 4 : 8),
                ],
              ),
            ),
          ),
        ],
      );
    });
  }

  Widget _buildTitleSection(
      bool isSmallScreen, bool isTinyScreen, double titleFontSize) {
    final iconSize = isTinyScreen ? 24.0 : (isSmallScreen ? 28.0 : 32.0);
    final subtitleFontSize =
        isTinyScreen ? 12.0 : (isSmallScreen ? 14.0 : 16.0);

    return Column(
      children: [
        Container(
          padding:
              EdgeInsets.all(isTinyScreen ? 6.0 : (isSmallScreen ? 8.0 : 10.0)),
          decoration: BoxDecoration(
            color: _surfaceColor,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: _primaryColor.withOpacity(0.3),
                blurRadius: 12,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Icon(
            Icons.verified_rounded,
            color: _primaryColor,
            size: iconSize,
          ),
        ),
        SizedBox(height: isTinyScreen ? 8 : 12),
        Text(
          'Get More Free Items',
          style: GoogleFonts.montserrat(
            textStyle: TextStyle(
              color: _textPrimaryColor,
              fontSize: titleFontSize,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
              shadows: [
                Shadow(
                  blurRadius: 4.0,
                  color: Colors.black.withOpacity(0.3),
                  offset: Offset(0, 2),
                ),
              ],
            ),
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: isTinyScreen ? 8 : 12),
        Container(
          padding: EdgeInsets.symmetric(horizontal: isTinyScreen ? 8 : 16),
          child: RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: GoogleFonts.poppins(
                textStyle: TextStyle(
                  color: _textPrimaryColor.withOpacity(0.9),
                  fontSize: subtitleFontSize,
                  height: 1.4,
                ),
              ),
              children: [
                TextSpan(
                  text: 'Premium members get items ',
                  style: TextStyle(
                    color: _textPrimaryColor.withOpacity(0.95),
                  ),
                ),
                TextSpan(
                  text: '5x faster ',
                  style: TextStyle(
                    color: _accentColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextSpan(
                  text: 'and have ',
                  style: TextStyle(
                    color: _textPrimaryColor.withOpacity(0.95),
                  ),
                ),
                TextSpan(
                  text: '10x more success ',
                  style: TextStyle(
                    color: _accentColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextSpan(
                  text: 'in receiving their favorite items!',
                  style: TextStyle(
                    color: _textPrimaryColor.withOpacity(0.95),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildFeaturesList(bool isSmallScreen, bool isTinyScreen) {
    final iconSize = isTinyScreen ? 18.0 : 22.0;
    final titleSize = isTinyScreen ? 13.0 : 15.0;
    final descSize = isTinyScreen ? 11.0 : 13.0;
    final iconPadding = isTinyScreen ? 8.0 : 10.0;

    return _premiumFeatures.map((feature) {
      return Container(
        margin: EdgeInsets.only(bottom: isTinyScreen ? 12.0 : 16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(iconPadding),
              decoration: BoxDecoration(
                color: _primaryColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _primaryColor.withOpacity(0.3),
                  width: 1.0,
                ),
              ),
              child: Icon(
                feature['icon'],
                color: _primaryColor,
                size: iconSize,
              ),
            ),
            SizedBox(width: isTinyScreen ? 10.0 : 14.0),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    feature['title'],
                    style: GoogleFonts.poppins(
                      textStyle: TextStyle(
                        color: _textPrimaryColor,
                        fontSize: titleSize,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(height: isTinyScreen ? 2 : 3),
                  Text(
                    feature['description'],
                    style: GoogleFonts.poppins(
                      textStyle: TextStyle(
                        color: _textSecondaryColor,
                        fontSize: descSize,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  List<Widget> _buildPackageOptions(bool isSmallScreen, bool isTinyScreen,
      double packageHeight, double screenWidth) {
    // Calculate package width based on screen width
    final cellSpacing = isTinyScreen ? 2.0 : 3.0;

    return [
      Container(
        margin: EdgeInsets.symmetric(vertical: isTinyScreen ? 6 : 8),
        height: packageHeight,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: _sortedPackages.asMap().entries.map((entry) {
            int index = entry.key;
            Package package = entry.value;
            bool isSelected = _selectedPackageIndex == index;
            bool isPopular = package.packageType == PackageType.annual;

            final String durationText = _getSubscriptionTypeInEnglish(package);
            final String priceText = package.storeProduct.priceString;

            // Responsive font sizes
            final durationFontSize =
                isTinyScreen ? 11.0 : (isSmallScreen ? 13.0 : 15.0);
            final priceFontSize =
                isTinyScreen ? 11.0 : (isSmallScreen ? 12.0 : 13.0);
            final tagFontSize = isTinyScreen ? 7.0 : 8.0;
            final savingsFontSize =
                isTinyScreen ? 8.0 : (isSmallScreen ? 9.0 : 10.0);

            // Responsive icon sizes
            final selectionIconSize =
                isTinyScreen ? 16.0 : (isSmallScreen ? 18.0 : 20.0);
            final checkIconSize =
                isTinyScreen ? 10.0 : (isSmallScreen ? 12.0 : 14.0);

            return Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedPackageIndex = index;
                  });
                },
                child: AnimatedBuilder(
                  animation: _glowAnimation,
                  builder: (context, child) {
                    // Calculate border width and glow opacity
                    double borderWidth = isPopular && !isSelected
                        ? 2.0 + _glowAnimation.value * 1.0
                        : isSelected
                            ? 2.0
                            : 1.0;

                    double glowOpacity = isPopular && !isSelected
                        ? 0.3 + (_glowAnimation.value * 0.2)
                        : 0.0;

                    return Container(
                      margin: EdgeInsets.symmetric(horizontal: cellSpacing),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: isSelected ? _primaryGradient : null,
                        color:
                            isSelected ? null : Colors.white.withOpacity(0.12),
                        border: Border.all(
                          color: isPopular && !isSelected
                              ? _accentColor
                              : isSelected
                                  ? Colors.transparent
                                  : Colors.white24,
                          width: borderWidth,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: _primaryColor.withOpacity(0.4),
                                  blurRadius: 12,
                                  offset: Offset(0, 4),
                                  spreadRadius: 2,
                                ),
                              ]
                            : isPopular
                                ? [
                                    BoxShadow(
                                      color:
                                          _accentColor.withOpacity(glowOpacity),
                                      blurRadius: 10,
                                      spreadRadius: 0,
                                      offset: Offset(0, 0),
                                    ),
                                  ]
                                : null,
                      ),
                      child: Stack(
                        children: [
                          // Main content
                          Padding(
                            padding: EdgeInsets.all(isTinyScreen
                                ? 6.0
                                : (isSmallScreen ? 8.0 : 10.0)),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // Duration text
                                Text(
                                  durationText,
                                  style: GoogleFonts.poppins(
                                    textStyle: TextStyle(
                                      color: Colors.white,
                                      fontSize: durationFontSize,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  textAlign: TextAlign.center,
                                ),

                                SizedBox(height: isTinyScreen ? 4 : 6),

                                // Price text
                                Text(
                                  priceText,
                                  style: GoogleFonts.poppins(
                                    textStyle: TextStyle(
                                      color: isSelected
                                          ? Colors.white
                                          : Colors.white.withOpacity(0.8),
                                      fontSize: priceFontSize,
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                    ),
                                  ),
                                  textAlign: TextAlign.center,
                                ),

                                // Savings text if applicable
                                if (_getSavingsText(package).isNotEmpty)
                                  Container(
                                    margin: EdgeInsets.only(
                                        top: isTinyScreen ? 4 : 6),
                                    padding: EdgeInsets.symmetric(
                                        horizontal: isTinyScreen
                                            ? 3
                                            : (isSmallScreen ? 4 : 6),
                                        vertical: isTinyScreen
                                            ? 1
                                            : (isSmallScreen ? 2 : 3)),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? Colors.white.withOpacity(0.25)
                                          : _accentColor,
                                      borderRadius: BorderRadius.circular(
                                          isTinyScreen ? 8 : 10),
                                      boxShadow: isSelected
                                          ? []
                                          : [
                                              BoxShadow(
                                                color: _accentColor
                                                    .withOpacity(0.3),
                                                blurRadius: 4,
                                                offset: Offset(0, 1),
                                              ),
                                            ],
                                    ),
                                    child: Text(
                                      _getSavingsText(package),
                                      style: GoogleFonts.poppins(
                                        textStyle: TextStyle(
                                          color: isSelected
                                              ? Colors.white
                                              : Colors.black87,
                                          fontSize: savingsFontSize,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),

                          // Selection indicator
                          Positioned(
                            top: isTinyScreen ? 6 : 8,
                            right: isTinyScreen ? 6 : 8,
                            child: Container(
                              width: isTinyScreen ? 16 : selectionIconSize,
                              height: isTinyScreen ? 16 : selectionIconSize,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected
                                      ? Colors.white
                                      : isPopular
                                          ? _accentColor
                                          : Colors.white54,
                                  width: isSelected || isPopular ? 2 : 1.5,
                                ),
                                color: isSelected
                                    ? Colors.white
                                    : Colors.transparent,
                              ),
                              child: isSelected
                                  ? Center(
                                      child: Icon(
                                        Icons.check,
                                        size: checkIconSize,
                                        color: _primaryColor,
                                      ),
                                    )
                                  : isPopular
                                      ? Center(
                                          child: Icon(
                                            Icons.star,
                                            size: checkIconSize,
                                            color: _accentColor,
                                          ),
                                        )
                                      : null,
                            ),
                          ),

                          // Best value tag for popular package - only on larger screens
                          if (isPopular && !isTinyScreen)
                            Positioned(
                              top: 0,
                              left: 0,
                              right: 0,
                              child: Center(
                                child: Container(
                                  transform:
                                      Matrix4.translationValues(0, -6, 0),
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    gradient: isSelected
                                        ? LinearGradient(
                                            colors: [
                                              Colors.white.withOpacity(0.3),
                                              Colors.white.withOpacity(0.2)
                                            ],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          )
                                        : _premiumGradient,
                                    borderRadius: BorderRadius.circular(10),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.2),
                                        blurRadius: 4,
                                        offset: Offset(0, 1),
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    'BEST VALUE',
                                    style: GoogleFonts.poppins(
                                      textStyle: TextStyle(
                                        color: Colors.white,
                                        fontSize: tagFontSize,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            );
          }).toList(),
        ),
      )
    ];
  }

  Widget _buildContinueButton(bool isSmallScreen, bool isTinyScreen) {
    String buttonText = 'GET PREMIUM ACCESS';

    // Responsive sizes
    final buttonHeight = isTinyScreen ? 48.0 : 54.0;
    final fontSize = isTinyScreen ? 14.0 : 16.0;
    final iconSize = isTinyScreen ? 18.0 : 22.0;
    final borderRadius = isTinyScreen ? 12.0 : 16.0;

    return Container(
      width: double.infinity,
      height: buttonHeight,
      decoration: BoxDecoration(
        gradient: _primaryGradient,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: _primaryColor.withOpacity(0.6),
            blurRadius: 12,
            offset: Offset(0, 4),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(borderRadius),
          onTap: _subscribeNow,
          splashColor: Colors.white.withOpacity(0.1),
          highlightColor: Colors.transparent,
          child: Container(
            alignment: Alignment.center,
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.verified_user_rounded,
                  color: Colors.white,
                  size: iconSize,
                ),
                SizedBox(width: isTinyScreen ? 6 : 8),
                Text(
                  buttonText,
                  style: GoogleFonts.montserrat(
                    textStyle: TextStyle(
                      color: Colors.white,
                      fontSize: fontSize,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                SizedBox(width: isTinyScreen ? 6 : 8),
                Icon(
                  Icons.arrow_forward_rounded,
                  color: Colors.white,
                  size: iconSize,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFooter(bool isSmallScreen, bool isTinyScreen) {
    final fontSize = isTinyScreen ? 10.0 : (isSmallScreen ? 12.0 : 13.0);
    final linkFontSize = isTinyScreen ? 11.0 : (isSmallScreen ? 13.0 : 14.0);

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(
              horizontal: isTinyScreen ? 16 : 24,
              vertical: isTinyScreen ? 6 : 8),
          child: Text(
            'Subscription auto-renews. Cancel anytime.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              textStyle: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: fontSize,
                height: 1.5,
              ),
            ),
          ),
        ),
        GestureDetector(
          onTap: () async {
            try {
              await Purchases.restorePurchases();
              // Show success message
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Purchases restored successfully!',
                      style: GoogleFonts.poppins(),
                    ),
                    backgroundColor: _primaryColor,
                  ),
                );
              }
            } catch (e) {
              // Show error message
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Failed to restore purchases. Please try again.',
                      style: GoogleFonts.poppins(),
                    ),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          },
          child: Container(
            padding: EdgeInsets.symmetric(
                horizontal: isTinyScreen ? 12 : 16,
                vertical: isTinyScreen ? 8 : 12),
            child: Text(
              'Restore Purchases',
              style: GoogleFonts.poppins(
                textStyle: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: linkFontSize,
                  fontWeight: FontWeight.w500,
                  decoration: TextDecoration.underline,
                  decorationColor: Colors.white.withOpacity(0.4),
                ),
              ),
            ),
          ),
        ),
        SizedBox(height: isTinyScreen ? 2 : 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton(
              onPressed: () {
                if (Platform.isIOS) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SubscriptionTermsPage(),
                    ),
                  );
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          const SubscriptionTermsPageAndroid(),
                    ),
                  );
                }
              },
              child: Text(
                'Terms of Use',
                style: GoogleFonts.poppins(
                  textStyle: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: fontSize,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ),
            Text(
              '•',
              style: GoogleFonts.poppins(
                textStyle: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: fontSize,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                if (Platform.isIOS) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SubscriptionTermsPage(),
                    ),
                  );
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          const SubscriptionTermsPageAndroid(),
                    ),
                  );
                }
              },
              child: Text(
                'Privacy Policy',
                style: GoogleFonts.poppins(
                  textStyle: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: fontSize,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildErrorMessage() {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white24,
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.error_outline,
            color: Colors.amber,
            size: 48,
          ),
          SizedBox(height: 16),
          Text(
            'Subscription packages cannot be loaded',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8),
          Text(
            'Please check your internet connection and try again later.',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24),
          OutlinedButton(
            onPressed: () {
              setState(() {
                _isLoading = true;
              });
              _initializeExperiment();
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: BorderSide(color: Colors.white),
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Text(
              'TRY AGAIN',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> updatePremiumStatus(bool isPremium) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .update({'is_premium': isPremium});

    if (!isPremium) {
      await updateCredits(0);
    }
  }

  Future<void> updateCredits(int credits) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .update({'credit': credits});
  }

  String _getSubscriptionTypeInEnglish(Package package) {
    switch (package.packageType) {
      case PackageType.weekly:
        return 'Weekly';
      case PackageType.monthly:
        return 'Monthly';
      case PackageType.annual:
        return 'Annual';
      default:
        return 'Unknown';
    }
  }

  String _getTrialText(Package package) {
    // No trial text displayed for any user
    return '';
  }

  String _getSavingsText(Package package) {
    if (package.packageType == PackageType.weekly) return '';

    // Find the weekly package in the available packages
    Package? weeklyPackage;
    for (var p in _sortedPackages) {
      if (p.packageType == PackageType.weekly) {
        weeklyPackage = p;
        break;
      }
    }

    if (weeklyPackage == null) return '';

    double weeklyPrice = weeklyPackage.storeProduct.price;
    double packagePrice = package.storeProduct.price;

    int weeks;
    switch (package.packageType) {
      case PackageType.monthly:
        weeks = 4;
        break;
      case PackageType.annual:
        weeks = 52;
        break;
      default:
        weeks = 0;
    }

    double totalWeeklyPrice = weeklyPrice * weeks;
    double savings = totalWeeklyPrice - packagePrice;
    double savingsPercentage = (savings / totalWeeklyPrice) * 100;

    return '${savingsPercentage.toStringAsFixed(0)}% savings';
  }

  void _subscribeNow() async {
    if (_selectedPackageIndex == null ||
        _selectedPackageIndex! >= _sortedPackages.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select a subscription package')),
      );
      return;
    }

    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return Dialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            child: Center(
              child: Container(
                padding: EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 40,
                      height: 40,
                      child: CircularProgressIndicator(
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Color(0xFF4CAF50)),
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Processing your transaction...',
                      style: TextStyle(
                        color: Colors.black87,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );

      CustomerInfo customerInfo = await Purchases.purchasePackage(
          _sortedPackages[_selectedPackageIndex!]);

      // Close loading dialog
      Navigator.of(context, rootNavigator: true).pop();

      EntitlementInfo? entitlement =
          customerInfo.entitlements.all[entitlementID];

      if (entitlement?.isActive ?? false) {
        // Purchase successful, update user status
        await updatePremiumStatus(true);
        await updateCredits(9999999);

        // Show success animation
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return Dialog(
              backgroundColor: Colors.transparent,
              elevation: 0,
              child: Container(
                padding: EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      color: Color(0xFF4CAF50),
                      size: 64,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Congratulations!',
                      style: TextStyle(
                        color: Colors.black87,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Your premium membership has been successfully activated.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.black54,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop(); // Close dialog
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (context) =>
                                CountryStateCityForFirstSelect(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF4CAF50),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding:
                            EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                      ),
                      child: Text(
                        'CONTINUE',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      } else {
        // Purchase failed or entitlement not active
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Subscription process could not be completed. Please try again.'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('Error during purchase: $e');

      // Close loading dialog if open
      if (Navigator.of(context).canPop()) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('An error occurred. Please try again later.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

// Premium background bubble effect painter
class BubblesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..style = PaintingStyle.fill;

    // Add some decorative circles of different sizes
    canvas.drawCircle(
      Offset(size.width * 0.2, size.height * 0.2),
      size.width * 0.15,
      paint,
    );

    canvas.drawCircle(
      Offset(size.width * 0.75, size.height * 0.3),
      size.width * 0.1,
      paint,
    );

    canvas.drawCircle(
      Offset(size.width * 0.6, size.height * 0.7),
      size.width * 0.2,
      paint,
    );

    canvas.drawCircle(
      Offset(size.width * 0.1, size.height * 0.75),
      size.width * 0.08,
      paint,
    );

    // Add smaller accent circles
    final accentPaint = Paint()
      ..color = Colors.white.withOpacity(0.07)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(size.width * 0.3, size.height * 0.5),
      size.width * 0.06,
      accentPaint,
    );

    canvas.drawCircle(
      Offset(size.width * 0.8, size.height * 0.8),
      size.width * 0.05,
      accentPaint,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

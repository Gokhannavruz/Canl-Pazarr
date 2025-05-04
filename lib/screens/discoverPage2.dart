import 'dart:convert';
import 'dart:ui';
import 'dart:async';
import 'dart:math' as math;

// Use platform-specific imports
import 'package:flutter/foundation.dart' show kIsWeb;
// Import IO for non-web platforms
import 'dart:io' if (dart.library.html) 'package:freecycle/utils/web_stub.dart';
// Only import FFI for non-web platforms
import 'ffi_import.dart' if (dart.library.html) 'web_ffi_stub.dart';

import 'package:freecycle/ad_helper/ad_helper.dart';
import 'package:freecycle/screens/add_post_screen.dart';
import 'package:freecycle/screens/country_state_city2.dart';
import 'package:freecycle/screens/country_state_city_picker.dart';
import 'package:freecycle/screens/credit_page.dart';
import 'package:freecycle/screens/post_screen.dart';
import 'package:freecycle/screens/search_screen.dart';
import 'package:freecycle/src/rvncat_constant.dart';
import 'package:freecycle/widgets/post_card.dart';
import 'package:country_state_city_picker/country_state_city_picker.dart';
import 'package:flutter/scheduler.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:get/utils.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:purchases_flutter/models/customer_info_wrapper.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:shimmer/shimmer.dart';
import 'package:country_state_city_picker/country_state_city_picker.dart';
import 'package:google_fonts/google_fonts.dart';

class DiscoverPage2 extends StatefulWidget {
  const DiscoverPage2({Key? key}) : super(key: key);

  @override
  _DiscoverPage2State createState() => _DiscoverPage2State();
}

class _DiscoverPage2State extends State<DiscoverPage2> {
  late bool _isGridView = true;
  late String selectedCategory = 'All';
  String? country;
  List<DocumentSnapshot> _posts = [];
  bool _isLoading = false;
  bool _hasMore = true;
  int _limit = 15;
  bool isLoading = true;
  int _totalProductsInCountry = 0;
  int _countryTotalProducts = 0;
  bool _showCountryTotal = false;
  Timer? _countryTotalTimer;
  OverlayEntry? _overlayEntry;

  // Stream abonelikleri için değişkenler
  StreamSubscription<QuerySnapshot>? _postsQuerySubscription;
  StreamSubscription<DocumentSnapshot>? _userSubscription;

  DocumentSnapshot? _lastDocument;
  late bool _isPostSelected = false;
  late String _selectedPostId = '';
  late String _selectedPostUid = '';
  String? city;
  String? state;
  String? countryValue;
  String? stateValue;
  String? cityValue;
  InterstitialAd? _interstitialAd;
  bool _isInterstitialAdReady = false;
  bool _isPremium = false;
  final ScrollController _scrollController = ScrollController();
  bool _isLoadingMore = false;
  bool _isInitialLoading = true;
  double _savedScrollPosition = 0.0;
  bool _isLocationSet = false;
  String _selectedFilter = 'All';
  String? userCountry;
  bool showState = false;
  bool showCity = false;

  // Add these variables for the alternating location display animation
  bool _showingLocationName = true;
  Timer? _locationDisplayTimer;

  // Add variables for top countries
  List<Map<String, dynamic>> _topCountries = [];
  bool _isLoadingTopCountries = false;

  // Add variables for hiding app bar on scroll
  bool _isAppBarVisible = true;
  double _lastScrollOffset = 0;

  // Function to remove flag emojis from country names
  String _cleanCountryName(String? countryName) {
    if (countryName == null || countryName.isEmpty) return '';

    // Remove flag emojis (country flag emoji is typically 2 regional indicator symbols)
    // Each regional indicator symbol is 2 bytes in UTF-16
    if (countryName.length >= 2 &&
        countryName.codeUnitAt(0) >= 0xD83C &&
        countryName.codeUnitAt(1) >= 0xDDE6) {
      // Find the first non-emoji character
      int startIndex = 0;
      while (startIndex < countryName.length &&
          startIndex + 1 < countryName.length &&
          countryName.codeUnitAt(startIndex) >= 0xD83C &&
          countryName.codeUnitAt(startIndex + 1) >= 0xDDE6) {
        startIndex += 2;
      }

      // Remove extra spaces after flag emoji
      return countryName.substring(startIndex).trim();
    }

    return countryName;
  }

  @override
  void initState() {
    super.initState();
    _getUserLocation();

    _checkPremiumStatus();
    _loadInterstitialAd();
    _getUserCountry();

    // Start location name / product count alternating animation
    _startLocationDisplayAnimation();

    if (country != null && country!.isNotEmpty) {
      showState = true;
      if (state != null && state!.isNotEmpty) {
        showCity = true;
      }
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.addListener(_onScroll);
      _scrollController.addListener(_handleAppBarVisibility);
    });
  }

  Future<void> _getUserCountry() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (mounted) {
          setState(() {
            if (userDoc.exists) {
              final data = userDoc.data() as Map<String, dynamic>?;
              userCountry = data?['country'] as String? ?? "";
            } else {
              userCountry = "";
              print("User document doesn't exist in Firestore");
            }
          });
        }
      } catch (e) {
        print("Error fetching user country: $e");
      }
    }
  }

  Future<void> _loadMorePosts() async {
    if (_isLoadingMore || !_hasMore || !mounted) return;

    setState(() {
      _isLoadingMore = true;
    });

    print("Loading more posts. Current count: ${_posts.length}");

    try {
      Query query = FirebaseFirestore.instance
          .collection('posts')
          .orderBy('datePublished', descending: true);

      if (_selectedFilter == 'Country' && country != null) {
        String cleanedCountry = _cleanCountryName(country);
        query = query.where('country', isEqualTo: cleanedCountry);
      } else if (_selectedFilter == 'State' && state != null) {
        query = query.where('state', isEqualTo: state);
        // Also add cleaned country to match products correctly
        if (country != null) {
          String cleanedCountry = _cleanCountryName(country);
          query = query.where('country', isEqualTo: cleanedCountry);
        }
      } else if (_selectedFilter == 'City' && city != null) {
        query = query.where('city', isEqualTo: city);
      }

      if (selectedCategory != 'All') {
        query = query.where('category', isEqualTo: selectedCategory);
      }

      if (_lastDocument != null) {
        query = query.startAfterDocument(_lastDocument!);
      }

      query = query.limit(_limit);

      // Önceki sorgu aboneliğini iptal et
      _postsQuerySubscription?.cancel();

      // Tek seferlik sorgu yap, stream aboneliği değil
      final snapshots = await query.get();

      if (!mounted) return;

      if (snapshots.docs.isEmpty) {
        print("No more posts to load");
        setState(() {
          _hasMore = false;
          _isLoadingMore = false;
          _isInitialLoading = false;
        });
        return;
      }

      _lastDocument = snapshots.docs.last;

      final newPosts = snapshots.docs
          .where(
              (doc) => !_posts.any((existingDoc) => existingDoc.id == doc.id))
          .toList();

      print("New posts loaded: ${newPosts.length}");

      if (!mounted) return;

      if (newPosts.isEmpty) {
        print("All loaded posts are duplicates");
        if (_posts.length < _limit) {
          _hasMore = false;
        } else {
          return _loadMorePosts();
        }
      } else {
        setState(() {
          _posts.addAll(newPosts);
          _isInitialLoading = false;
        });
      }
    } catch (e) {
      print("Error loading posts: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
          _isInitialLoading = false;
        });
      }
    }
  }

  void _updatePostsStream(String category, {String? filter}) {
    print("Updating posts stream for category: $category, filter: $filter");

    // Mevcut overlay'i kaldır
    _removeOverlay();

    // Önceki sorgu aboneliğini iptal et
    _postsQuerySubscription?.cancel();

    setState(() {
      selectedCategory = category;
      if (filter != null) _selectedFilter = filter;
      _posts.clear();
      _lastDocument = null;
      _hasMore = true;
      _isLoadingMore = false;
      _isInitialLoading = true;
    });

    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0);
    }

    _loadMorePosts();

    // Kategori değiştiğinde de ürün kontrolü yap
    if (_isLocationSet) {
      _getProductCountInCountry();
    }
  }

  void _checkPremiumStatus() async {
    try {
      CustomerInfo customerInfo = await Purchases.getCustomerInfo();
      setState(() {
        _isPremium =
            customerInfo.entitlements.all[entitlementID]?.isActive ?? false;
      });
      if (!_isPremium) {
        _loadInterstitialAd();
      } else {
        // Ensure no ads are loaded for premium users
        _disposeInterstitialAd();
      }
    } catch (e) {
      print("Error checking premium status: $e");
    }
  }

  // Add a method to properly dispose of any loaded ads for premium users
  void _disposeInterstitialAd() {
    if (_interstitialAd != null) {
      _interstitialAd!.dispose();
      _interstitialAd = null;
    }
    _isInterstitialAdReady = false;
  }

  void _showLocationSelectionBottomSheet() {
    // Store existing values to use if user doesn't select new ones
    String? existingCountry = country;
    String? existingState = state;

    // Initialize with empty values to not pre-populate fields
    countryValue = null;
    stateValue = null;

    // Variable to track if country has been selected
    bool countrySelected = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (BuildContext context, StateSetter setModalState) {
          // Calculate responsive height based on screen size and content state
          final screenHeight = MediaQuery.of(context).size.height;
          final screenWidth = MediaQuery.of(context).size.width;

          // Calculate dynamic height based on device and whether state is shown
          // Different heights for different screen sizes and orientations
          double modalHeight = countrySelected
              ? screenHeight < 700
                  ? 0.75 // Smaller screens with state shown
                  : 0.7 // Larger screens with state shown
              : screenHeight < 700
                  ? 0.65 // Smaller screens without state
                  : 0.6; // Larger screens without state

          // Adjust for extremely small screens
          if (screenHeight < 600) {
            modalHeight = 0.85; // Almost full screen on very small devices
          }

          // On large tablets, cap the max size
          if (screenWidth > 700) {
            modalHeight = countrySelected ? 0.6 : 0.55;
          }

          return Container(
            height: MediaQuery.of(context).size.height * modalHeight,
            decoration: BoxDecoration(
              color: Color(0xFF121212),
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 20,
                  offset: Offset(0, -5),
                ),
              ],
            ),
            child: SafeArea(
              child: Column(
                children: [
                  // Handle bar and header combined in a cleaner design
                  Container(
                    padding: EdgeInsets.only(top: 16, bottom: 12),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: Colors.grey.withOpacity(0.1),
                          width: 1,
                        ),
                      ),
                    ),
                    child: Column(
                      children: [
                        // Handle bar
                        Container(
                          height: 4,
                          width: 40,
                          margin: EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Color(0xFF36B37E).withOpacity(0.5),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),

                        // Header
                        Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: screenWidth * 0.06),
                          child: Row(
                            children: [
                              Icon(
                                Icons.location_on_rounded,
                                color: Color(0xFF36B37E),
                                size: 24,
                              ),
                              SizedBox(width: 12),
                              Text(
                                'Set Your Location',
                                style: GoogleFonts.poppins(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              Spacer(),
                              Material(
                                color: Colors.transparent,
                                borderRadius: BorderRadius.circular(20),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(20),
                                  onTap: () => Navigator.pop(context),
                                  child: Container(
                                    padding: EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: Color(0xFF36B37E).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Icon(
                                      Icons.close_rounded,
                                      color: Color(0xFF36B37E),
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Brief explanation text
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                        screenWidth * 0.06, 16, screenWidth * 0.06, 8),
                    child: Text(
                      "We use your location to show you free items available near you. You can always change this later.",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                  ),

                  // Location picker - wrapped in Expanded to use remaining space
                  Expanded(
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                            screenWidth * 0.06, 16, screenWidth * 0.06, 0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Country Selection
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Country Dropdown Label
                                  Padding(
                                    padding: const EdgeInsets.only(
                                        left: 16, top: 16, right: 16),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.public_rounded,
                                          size: 18,
                                          color: Colors.blue,
                                        ),
                                        SizedBox(width: 8),
                                        Text(
                                          "Country",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Divider
                                  Padding(
                                    padding: const EdgeInsets.only(
                                        top: 12, bottom: 8),
                                    child: Divider(
                                      height: 1,
                                      thickness: 1,
                                      color: Colors.white.withOpacity(0.05),
                                    ),
                                  ),

                                  // Custom Country Dropdown - with adequate height
                                  Container(
                                    height:
                                        150, // Increased height to prevent overflow
                                    padding: const EdgeInsets.only(bottom: 16),
                                    child: SingleChildScrollView(
                                      child: SelectState(
                                        // Style for text
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 15,
                                        ),

                                        // Dropdown color
                                        dropdownColor: Colors.black,

                                        // Callbacks
                                        onCountryChanged: (value) {
                                          setModalState(() {
                                            countryValue = value;
                                            countrySelected = value.isNotEmpty;
                                            // Reset state when country changes
                                            stateValue = "";
                                          });
                                        },

                                        onStateChanged: (value) {
                                          setModalState(() {
                                            stateValue = value;
                                          });
                                        },

                                        onCityChanged: (value) {
                                          // Not used in this implementation
                                        },
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Show state selection only after country is selected
                            if (countrySelected)
                              Container(
                                margin: EdgeInsets.only(top: 20),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // State Dropdown Label
                                    Padding(
                                      padding: const EdgeInsets.only(
                                          left: 16, top: 16, right: 16),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.map_rounded,
                                            size: 18,
                                            color: Colors.green,
                                          ),
                                          SizedBox(width: 8),
                                          Text(
                                            "State/Region (Optional)",
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    // Optional hint text
                                    Padding(
                                      padding: const EdgeInsets.only(
                                          left: 16, top: 4, right: 16),
                                      child: Text(
                                        "Leave empty to see items across the entire country",
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.5),
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),

                                    // Divider
                                    Padding(
                                      padding: const EdgeInsets.only(
                                          top: 12, bottom: 8),
                                      child: Divider(
                                        height: 1,
                                        thickness: 1,
                                        color: Colors.white.withOpacity(0.05),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                            // Selected location summary
                            if (countryValue != null &&
                                countryValue!.isNotEmpty)
                              Container(
                                margin: EdgeInsets.only(top: 20, bottom: 16),
                                padding: EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Color(0xFF1A3C34),
                                      Color(0xFF0D2018),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Colors.green.withOpacity(0.3),
                                    width: 1,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 10,
                                      offset: Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color:
                                                Colors.green.withOpacity(0.2),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.check_rounded,
                                            color: Colors.green,
                                            size: 18,
                                          ),
                                        ),
                                        SizedBox(width: 12),
                                        Text(
                                          "You're browsing items in",
                                          style: TextStyle(
                                            color: Colors.green.shade100,
                                            fontWeight: FontWeight.w500,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 12),
                                    Row(
                                      children: [
                                        Icon(
                                          stateValue != null &&
                                                  stateValue!.isNotEmpty
                                              ? Icons.place_rounded
                                              : Icons.public_rounded,
                                          color: Colors.green.shade200,
                                          size: 20,
                                        ),
                                        SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            stateValue != null &&
                                                    stateValue!.isNotEmpty
                                                ? "$stateValue, $countryValue"
                                                : countryValue!,
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                            // Add extra space at the bottom to prevent overflow
                            SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Action button
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(screenWidth * 0.06),
                    child: Container(
                      width: double.infinity,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF36B37E), Color(0xFF2E9F6F)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Color(0xFF36B37E).withOpacity(0.4),
                            spreadRadius: 0,
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () {
                            Navigator.pop(context);
                            // If user didn't select a new country, keep the existing one
                            if (countryValue == null || countryValue!.isEmpty) {
                              countryValue = existingCountry;
                              stateValue = existingState;
                            }
                            // If no state selected, ensure it's null and not empty string
                            if (stateValue == "") {
                              stateValue = null;
                            }
                            // Always set city to null as we're removing that field
                            cityValue = null;
                            _saveAndUpdateLocation();
                          },
                          child: Center(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.check_circle_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  "Apply Location",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _saveAndUpdateLocation() {
    _removeOverlay();

    setState(() {
      _isLocationSet = true;
      if (stateValue != null && stateValue!.isNotEmpty) {
        _selectedFilter = 'State';
        country = _cleanCountryName(countryValue);
        state = stateValue;
        city = cityValue;
      } else if (countryValue != null && countryValue!.isNotEmpty) {
        _selectedFilter = 'Country';
        country = _cleanCountryName(countryValue);
        state = null;
        city = null;
      }
    });
    _saveUserLocation();
    _updatePostsStream(selectedCategory, filter: _selectedFilter);
    _getProductCountInCountry();
  }

  void _saveUserLocation() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      String cleanedCountry = _cleanCountryName(countryValue);
      FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'country': cleanedCountry,
        'state': stateValue,
        'city': cityValue,
        'address': stateValue != null && stateValue!.isNotEmpty
            ? "$stateValue, $cleanedCountry"
            : cleanedCountry,
      });
    }
  }

  Widget _buildStepIndicator(
      {required int step, required bool isActive, required bool isCompleted}) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: isCompleted
            ? Colors.blue
            : (isActive
                ? Colors.blue.withOpacity(0.2)
                : Colors.grey.withOpacity(0.1)),
        shape: BoxShape.circle,
        border: Border.all(
          color: isActive ? Colors.blue : Colors.grey.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Center(
        child: isCompleted
            ? Icon(Icons.check, size: 14, color: Colors.white)
            : Text(
                '$step',
                style: TextStyle(
                  color: isActive ? Colors.blue : Colors.grey,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  Widget _buildSelectionTab(
      {required String label, required bool isActive, required IconData icon}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isActive ? Colors.blue.withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isActive
              ? Colors.blue.withOpacity(0.3)
              : Colors.grey.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 14,
            color: isActive ? Colors.blue : Colors.grey,
          ),
          SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: isActive ? Colors.blue : Colors.grey,
              fontSize: 12,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationSelector(
      String title, String? value, Function(String?) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
          SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: SelectState(
              onCountryChanged: (value) {
                setState(() {
                  countryValue = value;
                  onChanged(value);
                });
              },
              onStateChanged: (value) {
                if (title == 'State') {
                  setState(() {
                    stateValue = value;
                    onChanged(value);
                  });
                }
              },
              onCityChanged: (value) {
                if (title == 'City') {
                  setState(() {
                    cityValue = value;
                    onChanged(value);
                  });
                }
              },
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
              dropdownColor: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToLocationSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CountryStateCity(),
      ),
    );
  }

  void _loadInterstitialAd() {
    // Don't load ads for premium users
    if (_isPremium) {
      return;
    }

    InterstitialAd.load(
      adUnitId: AdHelper.interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (InterstitialAd ad) {
          // Additional premium check before setting the ad
          if (!_isPremium) {
            _interstitialAd = ad;
            _isInterstitialAdReady = true;
            _setFullScreenContentCallback(ad);
          } else {
            // If user became premium after ad load started
            ad.dispose();
          }
        },
        onAdFailedToLoad: (LoadAdError error) {
          print("Failed to load Interstitial Ad: ${error.message}");
          _isInterstitialAdReady = false;
          // Only retry loading if still not premium
          if (!_isPremium) {
            _loadInterstitialAd();
          }
        },
      ),
    );
  }

  void _setFullScreenContentCallback(InterstitialAd ad) {
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (InterstitialAd ad) {
        ad.dispose();
        _loadInterstitialAd();
      },
      onAdFailedToShowFullScreenContent: (InterstitialAd ad, AdError error) {
        print('$ad failed to show with error $error');
        ad.dispose();
        _loadInterstitialAd();
      },
    );
  }

  void _showInterstitialAd() {
    // Extra safety check to never show ads to premium users
    if (_isPremium) {
      return;
    }

    if (_interstitialAd != null && _isInterstitialAdReady) {
      _interstitialAd!.show();
      _isInterstitialAdReady = false;
    } else {
      print("Interstitial ad is not ready yet.");
      _loadInterstitialAd();
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >
            _scrollController.position.maxScrollExtent - 500 &&
        !_isLoadingMore) {
      _loadMorePosts();
    }
  }

  // Update the _handleAppBarVisibility method for smoother behavior
  void _handleAppBarVisibility() {
    if (_scrollController.hasClients) {
      final currentOffset = _scrollController.offset;

      // At the top of the list, always show app bar
      if (currentOffset <= 0) {
        if (!_isAppBarVisible) {
          setState(() {
            _isAppBarVisible = true;
          });
        }
        _lastScrollOffset = currentOffset;
        return;
      }

      // Determine scroll direction and toggle visibility with a threshold
      final isScrollingDown = currentOffset > _lastScrollOffset;

      // Use a small threshold to avoid flickering (e.g., 10 pixels)
      if (isScrollingDown &&
          _isAppBarVisible &&
          (currentOffset - _lastScrollOffset > 10)) {
        setState(() {
          _isAppBarVisible = false;
        });
      } else if (!isScrollingDown &&
          !_isAppBarVisible &&
          (_lastScrollOffset - currentOffset > 10)) {
        setState(() {
          _isAppBarVisible = true;
        });
      }

      _lastScrollOffset = currentOffset;
    }
  }

  @override
  void dispose() {
    // Scroll listeners
    _scrollController.removeListener(_onScroll);
    _scrollController.removeListener(_handleAppBarVisibility);
    _scrollController.dispose();

    // Ad stuff
    if (_interstitialAd != null) {
      _interstitialAd!.dispose();
    }

    // Timers
    _countryTotalTimer?.cancel();
    _locationDisplayTimer?.cancel();

    // Overlay
    _removeOverlay();

    // Stream aboneliklerini iptal et
    _postsQuerySubscription?.cancel();
    _userSubscription?.cancel();

    super.dispose();
  }

  void _removeOverlay() {
    if (_overlayEntry != null) {
      _overlayEntry?.remove();
      _overlayEntry = null;
    }
  }

  void _showCountryProductsOverlay() {
    _removeOverlay();

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        bottom: MediaQuery.of(context).size.height * 0.15,
        right: 16,
        child: Material(
          color: Colors.transparent,
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0.0, end: 1.0),
            duration: Duration(milliseconds: 400),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return Transform.translate(
                offset: Offset(30 * (1 - value), 0),
                child: Opacity(
                  opacity: value,
                  child: child,
                ),
              );
            },
            child: Container(
              width: 220,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF2E7D32),
                    Color(0xFF1B5E20),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(
                  color: Colors.white.withOpacity(0.15),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.public,
                                size: 16,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                "Across $country",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  letterSpacing: 0.3,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 2,
                              ),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: _removeOverlay,
                        child: Container(
                          padding: EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Icon(
                            Icons.close,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Divider(
                    color: Colors.white.withOpacity(0.2),
                    height: 24,
                  ),
                  Row(
                    children: [
                      Icon(
                        Icons.shopping_bag_outlined,
                        size: 16,
                        color: Colors.white.withOpacity(0.8),
                      ),
                      SizedBox(width: 10),
                      Text(
                        "$_countryTotalProducts items found",
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedFilter = 'Country';
                        state = "";
                        city = "";
                        FirebaseFirestore.instance
                            .collection('users')
                            .doc(FirebaseAuth.instance.currentUser!.uid)
                            .update({
                          'state': "",
                          'city': "",
                        });
                      });
                      _updateLocationOnly(country!);
                      _removeOverlay();
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          vertical: 10, horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.visibility,
                            size: 16,
                            color: Color(0xFF1B5E20),
                          ),
                          SizedBox(width: 8),
                          Text(
                            "View All Items",
                            style: TextStyle(
                              color: Color(0xFF1B5E20),
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  Future<void> _getUserLocation() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        // Önceki abonelik varsa iptal et
        _userSubscription?.cancel();

        // Kullanıcı dokümanını anlık izlemek için bir stream aboneliği oluştur
        _userSubscription = FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .snapshots()
            .listen((userDoc) {
          if (mounted) {
            setState(() {
              if (userDoc.exists) {
                final data = userDoc.data() as Map<String, dynamic>?;
                country = data?['country'] as String? ?? "";
                state = data?['state'] as String? ?? "";
                city = data?['city'] as String? ?? "";
              } else {
                country = "";
                state = "";
                city = "";
                print("User document doesn't exist in Firestore");
              }
              isLoading = false;

              // Set the appropriate flags based on the user's location data
              showState = country != null && country!.isNotEmpty;
              showCity = state != null && state!.isNotEmpty;

              if (city != null && city!.isNotEmpty) {
                _selectedFilter = 'City';
                _isLocationSet = true;
              } else if (state != null && state!.isNotEmpty) {
                _selectedFilter = 'State';
                _isLocationSet = true;
              } else if (country != null && country!.isNotEmpty) {
                _selectedFilter = 'Country';
                _isLocationSet = true;
              }
            });

            if (_isLocationSet && country != null && country!.isNotEmpty) {
              _updatePostsStream(selectedCategory, filter: _selectedFilter);
              _getProductCountInCountry();
            }
          }
        });
      } catch (e) {
        print("Error setting up user location listener: $e");
        isLoading = false;
      }
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _getProductCountInCountry() async {
    if (country == null || country!.isEmpty) return;

    // Clean country name before querying
    String cleanedCountry = _cleanCountryName(country);

    try {
      QuerySnapshot countQuery;
      QuerySnapshot countryQuery;

      // Önce ülkedeki toplam ürün sayısını al
      countryQuery = await FirebaseFirestore.instance
          .collection('posts')
          .where('country', isEqualTo: cleanedCountry)
          .get();

      int totalCountryProducts = countryQuery.size;

      // Seçilen filtreye göre ürün sayısını al
      if (_selectedFilter == 'Country' && cleanedCountry.isNotEmpty) {
        countQuery = countryQuery;
      } else if (_selectedFilter == 'State' &&
          state != null &&
          state!.isNotEmpty) {
        countQuery = await FirebaseFirestore.instance
            .collection('posts')
            .where('country', isEqualTo: cleanedCountry)
            .where('state', isEqualTo: state)
            .get();

        // Eyalette ürün varsa ve ülkede daha fazla ürün varsa overlay göster
        // Ayrıca, ülkedeki ürün sayısı eyaletteki ürün sayısının en az 2 katı olmalı
        if (countQuery.size > 0 &&
            totalCountryProducts > countQuery.size * 2 &&
            mounted) {
          _countryTotalProducts = totalCountryProducts;
          // Overlay'i göstermek için kısa bir gecikme ekle
          Future.delayed(Duration(milliseconds: 800), () {
            if (mounted) {
              _showCountryProductsOverlay();
            }
          });
        }
      } else if (_selectedFilter == 'City' &&
          city != null &&
          city!.isNotEmpty) {
        countQuery = await FirebaseFirestore.instance
            .collection('posts')
            .where('country', isEqualTo: cleanedCountry)
            .where('city', isEqualTo: city)
            .get();

        // Şehirde ürün varsa ve ülkede daha fazla ürün varsa overlay göster
        // Ayrıca, ülkedeki ürün sayısı şehirdeki ürün sayısının en az 2 katı olmalı
        if (countQuery.size > 0 &&
            totalCountryProducts > countQuery.size * 2 &&
            mounted) {
          _countryTotalProducts = totalCountryProducts;
          // Overlay'i göstermek için kısa bir gecikme ekle
          Future.delayed(Duration(milliseconds: 800), () {
            if (mounted) {
              _showCountryProductsOverlay();
            }
          });
        }
      } else {
        countQuery = countryQuery;
      }

      if (mounted) {
        setState(() {
          _totalProductsInCountry = countQuery.size;

          if (totalCountryProducts > 0) {
            _countryTotalProducts = totalCountryProducts;
          } else {
            _countryTotalProducts = 0;
            _showCountryTotal = false;

            // If there are no products in the user's country, fetch top countries
            if (_topCountries.isEmpty && !_isLoadingTopCountries) {
              _getTopCountriesWithProducts();
            }
          }
        });
      }
      print("Total products in $country: $_totalProductsInCountry");
      if (_countryTotalProducts > 0) {
        print("Total products in country level: $_countryTotalProducts");
      }
    } catch (e) {
      print("Error getting product count: $e");

      // On error, try to fetch top countries
      if (_topCountries.isEmpty && !_isLoadingTopCountries && mounted) {
        _getTopCountriesWithProducts();
      }
    }
  }

  Widget _buildLocationFilterDisplay() {
    String locationName = 'Select Location';
    if (city != null && city!.isNotEmpty) {
      locationName = city!;
    } else if (state != null && state!.isNotEmpty) {
      locationName = state!;
    } else if (country != null && country!.isNotEmpty) {
      locationName = country!;
    }

    String productCountText = '';
    if (_totalProductsInCountry > 0) {
      productCountText = "$_totalProductsInCountry free items";
    } else {
      productCountText = "No items yet";
    }

    // Calculate fixed width based on screen size and content state
    final screenWidth = MediaQuery.of(context).size.width;

    // Use different width ratios based on screen size
    double widthRatio;
    if (screenWidth < 360) {
      // Very small phones
      widthRatio = 0.5;
    } else if (screenWidth < 480) {
      // Regular phones
      widthRatio = 0.55;
    } else if (screenWidth < 600) {
      // Large phones
      widthRatio = 0.5;
    } else if (screenWidth < 900) {
      // Tablets
      widthRatio = 0.4;
    } else {
      // Large tablets and desktops
      widthRatio = 0.3;
    }

    // Set minimum and maximum width constraints
    final containerWidth = math.max(
        120.0, // Minimum width in pixels
        math.min(
            screenWidth * widthRatio * 0.8, // Proportional width, %20 daha dar
            240.0 // Maximum width in pixels, daha küçük maksimum
            ));

    // Use AnimatedSwitcher to smoothly transition between the two text displays
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: _showLocationSelectionBottomSheet,
          child: Container(
            width: containerWidth, // Fixed width to prevent size changes
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  _showingLocationName
                      ? Color(0xFF36B37E).withOpacity(0.15)
                      : Color(0xFF36B37E).withOpacity(0.2),
                  _showingLocationName
                      ? Color(0xFF36B37E).withOpacity(0.08)
                      : Color(0xFF36B37E).withOpacity(0.15),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _showingLocationName
                    ? Color(0xFF36B37E).withOpacity(0.3)
                    : Color(0xFF36B37E).withOpacity(0.5),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Animated container for the icon
                AnimatedContainer(
                  duration: Duration(milliseconds: 300),
                  height: 22,
                  width: 22,
                  decoration: BoxDecoration(
                    color: _showingLocationName
                        ? Color(0xFF36B37E).withOpacity(0.2)
                        : Color(0xFF36B37E).withOpacity(0.3),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Center(
                    child: AnimatedSwitcher(
                      duration: Duration(milliseconds: 300),
                      child: Icon(
                        _showingLocationName
                            ? Icons.location_on_rounded
                            : Icons.shopping_bag_rounded,
                        key: ValueKey<bool>(_showingLocationName),
                        size: 14,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 6),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: Duration(milliseconds: 400),
                    transitionBuilder:
                        (Widget child, Animation<double> animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: Offset(0, 0.3),
                            end: Offset.zero,
                          ).animate(CurvedAnimation(
                            parent: animation,
                            curve: Curves.easeOutCubic,
                          )),
                          child: child,
                        ),
                      );
                    },
                    child: Text(
                      _showingLocationName ? locationName : productCountText,
                      key: ValueKey<bool>(_showingLocationName),
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        letterSpacing: 0.1,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ),
                // Animated drop-down indicator
                AnimatedContainer(
                  duration: Duration(milliseconds: 300),
                  height: 18,
                  width: 18,
                  decoration: BoxDecoration(
                    color: _showingLocationName
                        ? Color(0xFF36B37E).withOpacity(0.15)
                        : Color(0xFF36B37E).withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: Colors.white,
                      size: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildShimmerEffect(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[800]!,
      highlightColor: Colors.grey[700]!,
      child: _isGridView
          ? GridView.builder(
              padding: EdgeInsets.only(top: 6),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 2,
                mainAxisSpacing: 2,
              ),
              itemCount: 15,
              itemBuilder: (context, index) {
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(8),
                  ),
                );
              },
            )
          : ListView.builder(
              padding: EdgeInsets.only(top: 6),
              itemCount: 10,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: 8.0, horizontal: 16.0),
                  child: Container(
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildPostPlaceholder(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[800]!,
      highlightColor: Colors.grey[700]!,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  List<Widget> _buildAppBarActions() {
    List<Widget> actions = [];

    actions.addAll([
      IconButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const SearchScreen()),
          );
        },
        icon: Icon(
          Icons.search,
          color: Colors.white,
          size: 22,
        ),
        padding: EdgeInsets.zero,
        constraints: BoxConstraints(),
        iconSize: 22,
      ),
      SizedBox(width: 8),
      _isPostSelected
          ? Container()
          : Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: IconButton(
                onPressed: () {
                  setState(() {
                    _isGridView = !_isGridView;
                  });
                },
                icon: _isGridView
                    ? Icon(
                        Icons.notes_rounded,
                        color: Colors.white,
                        size: 20,
                      )
                    : Icon(
                        Icons.grid_view_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                padding: EdgeInsets.all(6),
                constraints: BoxConstraints(),
                iconSize: 20,
                tooltip: _isGridView ? "List View" : "Grid View",
              ),
            ),
      SizedBox(width: 16),
    ]);

    return actions;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_isPostSelected) {
          setState(() {
            _isPostSelected = false;
          });
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _scrollController.jumpTo(_savedScrollPosition);
          });
          return false;
        } else {
          return true;
        }
      },
      child: Scaffold(
        appBar: _isPostSelected
            ? AppBar(
                backgroundColor: Colors.black,
                leading: IconButton(
                  icon: Icon(Icons.arrow_back_ios, color: Colors.white),
                  onPressed: () {
                    setState(() {
                      _isPostSelected = false;
                    });
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _scrollController.jumpTo(_savedScrollPosition);
                    });
                  },
                ),
              )
            : null,
        body: NestedScrollView(
          physics: const BouncingScrollPhysics(),
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return _isPostSelected
                ? []
                : [
                    SliverAppBar(
                      pinned: false,
                      automaticallyImplyLeading: false,
                      systemOverlayStyle: const SystemUiOverlayStyle(
                        statusBarColor: Colors.transparent,
                        statusBarIconBrightness: Brightness.light,
                      ),
                      snap: true,
                      floating: true,
                      expandedHeight: _isAppBarVisible ? 75 : 0,
                      collapsedHeight: _isAppBarVisible ? kToolbarHeight : 0,
                      toolbarHeight: _isAppBarVisible ? kToolbarHeight : 0,
                      flexibleSpace: _isAppBarVisible
                          ? FlexibleSpaceBar(
                              background: Stack(
                                children: [
                                  Container(
                                    decoration: const BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          Colors.transparent,
                                          Colors.black,
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : null,
                      title: _isAppBarVisible
                          ? Row(
                              children: [
                                Expanded(child: _buildLocationFilterDisplay()),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: _buildAppBarActions(),
                                ),
                              ],
                            )
                          : null,
                      titleSpacing: 16,
                      backgroundColor: Colors.black,
                      elevation: 0,
                    ),
                  ];
          },
          body: _isPostSelected
              ? PostScreen(
                  postId: _selectedPostId,
                  uid: _selectedPostUid,
                )
              : Column(
                  children: [
                    // Animated visibility for category list
                    AnimatedContainer(
                      duration: Duration(milliseconds: 300),
                      height: _isAppBarVisible ? 28 : 0,
                      child: _isAppBarVisible
                          ? ListView(
                              scrollDirection: Axis.horizontal,
                              children: [
                                for (var category in [
                                  'All',
                                  'Electronics',
                                  'Appliances',
                                  'Automotive',
                                  'Baby',
                                  'Beauty',
                                  'Books',
                                  'Clothing',
                                  'Fitness',
                                  'Food',
                                  'Furniture',
                                  'Garden',
                                  'Health',
                                  'Home',
                                  'Jewelry',
                                  'Kitchen',
                                  'Music',
                                  'Office',
                                  'Outdoors',
                                  'Pets',
                                  'Shoes',
                                  'Sports',
                                  'Toys',
                                  'Travel',
                                  'Video Games',
                                  'Watches',
                                  'Crafts',
                                  'Collectibles',
                                  'Art',
                                  'Movies',
                                  'Computers',
                                ])
                                  Padding(
                                    padding: const EdgeInsets.only(left: 5.0),
                                    child: ElevatedButton(
                                      onPressed: () {
                                        _updatePostsStream(category);
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            selectedCategory == category
                                                ? Color(0xFF36B37E)
                                                : Colors.grey.shade800,
                                        foregroundColor:
                                            selectedCategory == category
                                                ? Colors.white
                                                : Colors.grey.shade300,
                                        elevation: selectedCategory == category
                                            ? 1
                                            : 0,
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 0),
                                        minimumSize: Size(10, 24),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(14),
                                          side: BorderSide(
                                            width: 0.5,
                                            color: selectedCategory == category
                                                ? Color(0xFF36B37E)
                                                    .withOpacity(0.3)
                                                : Colors.grey.shade700,
                                          ),
                                        ),
                                      ),
                                      child: Text(
                                        category,
                                        style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          fontWeight:
                                              selectedCategory == category
                                                  ? FontWeight.w600
                                                  : FontWeight.w400,
                                          letterSpacing: 0,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            )
                          : SizedBox.shrink(),
                    ),

                    // Add a small spacing after the category list that animates with it
                    AnimatedContainer(
                      duration: Duration(milliseconds: 300),
                      height: _isAppBarVisible ? 8 : 0,
                    ),

                    Expanded(
                      child: _isInitialLoading
                          ? _buildShimmerEffect(context)
                          : _posts.isEmpty
                              ? Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Center(
                                    child: country == null || country!.isEmpty
                                        ? Column(
                                            children: [
                                              Text(
                                                "Please select your country to see products \nin your area",
                                                textAlign: TextAlign.center,
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                              const SizedBox(height: 10),
                                              // Country selection widget remains the same
                                              // ...
                                            ],
                                          )
                                        : _buildEmptyStateMessage(),
                                  ),
                                )
                              : NotificationListener<ScrollNotification>(
                                  onNotification:
                                      (ScrollNotification scrollInfo) {
                                    if (!_isLoading &&
                                        _hasMore &&
                                        scrollInfo.metrics.pixels ==
                                            scrollInfo
                                                .metrics.maxScrollExtent) {
                                      _loadMorePosts();
                                    }
                                    return true;
                                  },
                                  child: _isGridView
                                      ? GridView.builder(
                                          padding: EdgeInsets.only(top: 6),
                                          controller: _scrollController,
                                          itemCount: _posts.length + 1,
                                          gridDelegate:
                                              const SliverGridDelegateWithFixedCrossAxisCount(
                                            crossAxisCount: 3,
                                            crossAxisSpacing: 2,
                                            mainAxisSpacing: 2,
                                          ),
                                          itemBuilder: (context, index) {
                                            if (index == _posts.length) {
                                              return _isLoadingMore
                                                  ? _buildPostPlaceholder(
                                                      context)
                                                  : Container();
                                            }
                                            DocumentSnapshot data =
                                                _posts[index];
                                            return GestureDetector(
                                              onTap: () {
                                                _savedScrollPosition =
                                                    _scrollController
                                                        .position.pixels;
                                                if (!_isPremium) {
                                                  _showInterstitialAd();
                                                }
                                                setState(() {
                                                  _isPostSelected = true;
                                                  _selectedPostId = data.id;
                                                  _selectedPostUid =
                                                      data['uid'];
                                                });
                                              },
                                              child:
                                                  _buildGridItem(data, context),
                                            );
                                          },
                                        )
                                      : ListView.builder(
                                          padding: EdgeInsets.only(top: 6),
                                          controller: _scrollController,
                                          itemCount: _posts.length + 1,
                                          itemBuilder: (context, index) {
                                            if (index == _posts.length) {
                                              return _isLoadingMore
                                                  ? _buildPostPlaceholder(
                                                      context)
                                                  : Container();
                                            }
                                            DocumentSnapshot data =
                                                _posts[index];
                                            return GestureDetector(
                                              onTap: () {
                                                _savedScrollPosition =
                                                    _scrollController
                                                        .position.pixels;
                                                if (!_isPremium) {
                                                  _showInterstitialAd();
                                                }
                                                setState(() {
                                                  _isPostSelected = true;
                                                  _selectedPostId = data.id;
                                                  _selectedPostUid =
                                                      data['uid'];
                                                });
                                              },
                                              child: PostCard(
                                                snap: data,
                                                isBlocked: false,
                                                isGridView: false,
                                              ),
                                            );
                                          },
                                        ),
                                ),
                    )
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildEmptyStateMessage() {
    // Ekran boyutunu al
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.height < 600;

    // Fetch top countries if we haven't already and there are no products in user's country
    if (_topCountries.isEmpty && !_isLoadingTopCountries) {
      _getTopCountriesWithProducts();
    }

    return SingleChildScrollView(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: screenSize.height * 0.7, // Minimum yükseklik ekranın %70'i
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Resim container'ı - ekran boyutuna göre ölçeklendirme
              Container(
                padding: EdgeInsets.all(isSmallScreen ? 15 : 20),
                width: screenSize.width * 0.4, // Ekran genişliğinin %40'ı
                height: screenSize.width * 0.4, // Kare görünüm için
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.blue.withOpacity(0.15),
                      Colors.purple.withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.blue.withOpacity(0.3),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.1),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Image.asset(
                  'assets/sharing.png',
                  fit: BoxFit.contain,
                ),
              ),

              SizedBox(height: isSmallScreen ? 16 : 24),

              // Başlık - ekran boyutuna göre font boyutu
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: "Pioneer ",
                      style: GoogleFonts.poppins(
                        fontSize: isSmallScreen ? 20 : 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF36B37E),
                        letterSpacing: 0.5,
                      ),
                    ),
                    TextSpan(
                      text: "Your Community!",
                      style: GoogleFonts.poppins(
                        fontSize: isSmallScreen ? 20 : 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: isSmallScreen ? 12 : 16),

              // Açıklama kutusu
              Container(
                padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: EdgeInsets.all(isSmallScreen ? 6 : 8),
                      decoration: BoxDecoration(
                        color: Color(0xFF36B37E).withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.eco_outlined,
                        color: Color(0xFF36B37E),
                        size: isSmallScreen ? 16 : 20,
                      ),
                    ),
                    SizedBox(width: isSmallScreen ? 8 : 12),
                    Expanded(
                      child: Text(
                        _selectedFilter == 'State' &&
                                state != null &&
                                state!.isNotEmpty
                            ? "Be the first to share in $state! Your items will inspire others to join our sustainable community."
                            : "Be the first to share in $country! Your items will inspire others to join our sustainable community.",
                        style: TextStyle(
                          fontSize: isSmallScreen ? 13 : 15,
                          color: Colors.white.withOpacity(0.9),
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Add Top Countries Widget
              if (_topCountries.isNotEmpty) ...[
                SizedBox(height: isSmallScreen ? 24 : 32),
                _buildTopCountriesWidget(isSmallScreen),
              ] else if (_isLoadingTopCountries) ...[
                SizedBox(height: isSmallScreen ? 24 : 32),
                Center(
                  child: CircularProgressIndicator(
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Color(0xFF36B37E)),
                    strokeWidth: 3,
                  ),
                ),
              ],

              SizedBox(height: isSmallScreen ? 20 : 24),

              // Aksiyon butonu - ekran boyutuna göre yükseklik
              Container(
                width: double.infinity,
                height: isSmallScreen ? 44 : 50,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue, Colors.blue.shade700],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.3),
                      blurRadius: 12,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton.icon(
                  icon: Icon(Icons.add_circle_outline,
                      size: isSmallScreen ? 16 : 18),
                  label: Text(
                    "Share Your First Item",
                    style: TextStyle(
                      fontSize: isSmallScreen ? 13 : 15,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF36B37E),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: EdgeInsets.symmetric(
                      horizontal: isSmallScreen ? 12 : 16,
                      vertical: isSmallScreen ? 8 : 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const AddPostScreen()),
                    );
                  },
                ),
              ),

              SizedBox(height: isSmallScreen ? 16 : 20),

              // Motivasyon metni
              Container(
                padding: EdgeInsets.symmetric(
                    horizontal: isSmallScreen ? 12 : 14,
                    vertical: isSmallScreen ? 8 : 10),
                decoration: BoxDecoration(
                  color: Color(0xFF36B37E).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Color(0xFF36B37E).withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.people_outline,
                      color: Color(0xFF36B37E),
                      size: isSmallScreen ? 16 : 18,
                    ),
                    SizedBox(width: isSmallScreen ? 8 : 10),
                    Expanded(
                      child: Text(
                        "Every shared item creates a more sustainable future. Start the movement today!",
                        style: GoogleFonts.poppins(
                          fontSize: isSmallScreen ? 12 : 13,
                          color: Color(0xFF36B37E),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Add this new method to fetch top countries with most products
  Future<void> _getTopCountriesWithProducts() async {
    if (_isLoadingTopCountries) return;

    setState(() {
      _isLoadingTopCountries = true;
    });

    try {
      // Get all posts and group them by country
      final QuerySnapshot postsSnapshot =
          await FirebaseFirestore.instance.collection('posts').get();

      // Create a map to count posts by country
      Map<String, int> countryPostCounts = {};

      // Count posts for each country
      for (var doc in postsSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final countryName = data['country'] as String? ?? '';

        if (countryName.isNotEmpty) {
          countryPostCounts[countryName] =
              (countryPostCounts[countryName] ?? 0) + 1;
        }
      }

      // Convert to list and sort by count (descending)
      List<Map<String, dynamic>> sortedCountries = countryPostCounts.entries
          .map((entry) => {'country': entry.key, 'count': entry.value})
          .toList();

      sortedCountries.sort((a, b) => b['count'].compareTo(a['count']));

      // Take top 5 countries
      final topCountries = sortedCountries.take(5).toList();

      if (mounted) {
        setState(() {
          _topCountries = topCountries;
          _isLoadingTopCountries = false;
        });
      }

      print("Top countries loaded: ${_topCountries.length}");
    } catch (e) {
      print("Error loading top countries: $e");
      if (mounted) {
        setState(() {
          _isLoadingTopCountries = false;
        });
      }
    }
  }

  // Add this new method to build the top countries widget
  Widget _buildTopCountriesWidget(bool isSmallScreen) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Container(
          margin: EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Explore Global Community",
                style: TextStyle(
                  fontSize: isSmallScreen ? 18 : 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
              SizedBox(height: 4),
              Text(
                "Discover thousands of free items in these active countries",
                style: TextStyle(
                  fontSize: isSmallScreen ? 12 : 14,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ),

        // Countries list
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              for (int i = 0; i < _topCountries.length; i++)
                _buildCountryItem(_topCountries[i], i, isSmallScreen),
            ],
          ),
        ),
      ],
    );
  }

  // Method to only change location without affecting UI state
  void _changeLocationOnly(String countryName) {
    print("Changing location only to: $countryName");

    // Mevcut overlay'i kaldır
    _removeOverlay();

    // Clean country name
    String cleanedCountry = _cleanCountryName(countryName);

    // Update location data
    countryValue = cleanedCountry;
    country = cleanedCountry;
    state = null;
    city = null;
    _selectedFilter = 'Country';
    _isLocationSet = true;

    // Clear posts to load new ones
    _posts.clear();
    _lastDocument = null;
    _hasMore = true;
    _isLoadingMore = false;
    _isInitialLoading = true;

    // Load posts for the new location
    _loadMorePosts();
    _getProductCountInCountry();

    // Save the location to user profile
    _saveUserLocation();

    // Force UI update
    setState(() {});
  }

  // New method that only updates location without changing category or UI
  void _updateLocationOnly(String newCountry) {
    print("Updating location only to: $newCountry");

    // Save current UI state
    String currentCategory = selectedCategory;
    bool currentGridView = _isGridView;

    // Mevcut overlay'i kaldır
    _removeOverlay();

    // Clean country name
    String cleanedCountry = _cleanCountryName(newCountry);

    // Update location data without changing UI state
    setState(() {
      countryValue = cleanedCountry;
      country = cleanedCountry;
      state = null;
      city = null;
      _selectedFilter = 'Country';
      _isLocationSet = true;

      // Preserve current UI state
      selectedCategory = currentCategory;
      _isGridView = currentGridView;

      // Reset posts to load new ones
      _posts.clear();
      _lastDocument = null;
      _hasMore = true;
      _isLoadingMore = false;
      _isInitialLoading = true;
    });

    // Load posts for the new location with current category
    Query query = FirebaseFirestore.instance
        .collection('posts')
        .orderBy('datePublished', descending: true)
        .where('country', isEqualTo: cleanedCountry);

    if (selectedCategory != 'All') {
      query = query.where('category', isEqualTo: selectedCategory);
    }

    query = query.limit(_limit);

    // Execute query and update posts
    query.get().then((snapshots) {
      if (snapshots.docs.isEmpty) {
        setState(() {
          _hasMore = false;
          _isLoadingMore = false;
          _isInitialLoading = false;
        });
        return;
      }

      _lastDocument = snapshots.docs.last;

      setState(() {
        _posts = snapshots.docs;
        _isInitialLoading = false;
        _isLoadingMore = false;
      });

      // Save the location to user profile
      _saveUserLocation();

      // Check product count in new country
      _getProductCountInCountry();
    }).catchError((error) {
      print("Error loading posts for new location: $error");
      setState(() {
        _isInitialLoading = false;
        _isLoadingMore = false;
      });
    });
  }

  Widget _buildCountryItem(
      Map<String, dynamic> countryData, int index, bool isSmallScreen) {
    final countryName = countryData['country'] as String;
    final itemCount = countryData['count'] as int;

    // Different colors for different positions
    Color getPositionColor(int position) {
      switch (position) {
        case 0:
          return Colors.amber;
        case 1:
          return Colors.grey.shade300;
        case 2:
          return Colors.brown.shade300;
        default:
          return Colors.blue.shade300;
      }
    }

    return InkWell(
      onTap: () {
        // Use the new method that only changes location
        _updateLocationOnly(countryName);
      },
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: 16,
          vertical: isSmallScreen ? 12 : 14,
        ),
        decoration: BoxDecoration(
          border: index < _topCountries.length - 1
              ? Border(
                  bottom: BorderSide(
                    color: Colors.white.withOpacity(0.1),
                    width: 1,
                  ),
                )
              : null,
        ),
        child: Row(
          children: [
            // Position indicator
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: getPositionColor(index).withOpacity(0.2),
                shape: BoxShape.circle,
                border: Border.all(
                  color: getPositionColor(index),
                  width: 1.5,
                ),
              ),
              child: Center(
                child: Text(
                  "${index + 1}",
                  style: TextStyle(
                    color: getPositionColor(index),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            SizedBox(width: 12),

            // Country name
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    countryName,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: isSmallScreen ? 14 : 16,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    "$itemCount free items available",
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: isSmallScreen ? 12 : 13,
                    ),
                  ),
                ],
              ),
            ),

            // Arrow icon
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.white54,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  // Start the 5-second alternating animation with a smoother easing
  void _startLocationDisplayAnimation() {
    _locationDisplayTimer?.cancel();
    _locationDisplayTimer = Timer.periodic(Duration(seconds: 5), (timer) {
      if (mounted) {
        setState(() {
          _showingLocationName = !_showingLocationName;
        });
      }
    });
  }

  // Build a grid item with "Free" or "Needed" label
  Widget _buildGridItem(DocumentSnapshot data, BuildContext context) {
    // Get post location
    String postCountry = data['country'] ?? '';
    String postState = data['state'] ?? '';
    String postCity = data['city'] ?? '';

    // Determine if we should show location (only when user has only country set)
    bool shouldShowLocation = country != null &&
        country!.isNotEmpty &&
        (state == null || state!.isEmpty) &&
        (city == null || city!.isEmpty);

    // Determine what location text to show
    String locationText = '';
    if (postCity.isNotEmpty) {
      locationText = postCity;
    } else if (postState.isNotEmpty) {
      locationText = postState;
    } else if (postCountry.isNotEmpty) {
      locationText = postCountry;
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        // Image
        CachedNetworkImage(
          imageUrl: data['postUrl'],
          fit: BoxFit.cover,
          placeholder: (context, url) => _buildPostPlaceholder(context),
          errorWidget: (context, url, error) => const Icon(Icons.error),
        ),

        // Free or Needed label
        Positioned(
          top: 5,
          right: 5,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: data['isWanted'] == true
                  ? Colors.blue.withOpacity(0.85)
                  : Colors.green.withOpacity(0.85),
              borderRadius: BorderRadius.circular(4),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              data['isWanted'] == true ? 'Needed' : 'Free',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),

        // Location indicator (only shown when user has only country set)
        if (shouldShowLocation && locationText.isNotEmpty)
          Positioned(
            bottom: 5,
            right: 5,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 6,
                vertical: 3,
              ),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(3),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.location_on,
                    color: Colors.white.withOpacity(0.9),
                    size: 8,
                  ),
                  SizedBox(width: 2),
                  // Limit the width of the text to prevent overflow
                  LimitedBox(
                    maxWidth: 70, // Maximum width in pixels
                    child: Text(
                      locationText,
                      style: GoogleFonts.poppins(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 8,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class CustomSelectState extends StatefulWidget {
  final String? initialCountry;
  final String? initialState;
  final String? initialCity;
  final Function(String?) onCountryChanged;
  final Function(String?) onStateChanged;
  final Function(String?) onCityChanged;

  const CustomSelectState({
    Key? key,
    this.initialCountry,
    this.initialState,
    this.initialCity,
    required this.onCountryChanged,
    required this.onStateChanged,
    required this.onCityChanged,
  }) : super(key: key);

  @override
  _CustomSelectStateState createState() => _CustomSelectStateState();
}

class _CustomSelectStateState extends State<CustomSelectState> {
  String? _currentCountry;
  bool _showStates = false;

  @override
  void initState() {
    super.initState();
    _currentCountry = widget.initialCountry;
    _showStates = _currentCountry != null && _currentCountry!.isNotEmpty;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.initialCountry != null) {
        widget.onCountryChanged?.call(widget.initialCountry);
      }
      if (widget.initialState != null) {
        widget.onStateChanged?.call(widget.initialState);
      }
      if (widget.initialCity != null) {
        widget.onCityChanged?.call(widget.initialCity);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 150,
      child: SingleChildScrollView(
        child: SelectState(
          onCountryChanged: (value) {
            setState(() {
              widget.onCountryChanged?.call(value);
            });
          },
          onStateChanged: (value) {
            setState(() {
              widget.onStateChanged?.call(value);
            });
          },
          onCityChanged: (value) {
            setState(() {
              widget.onCityChanged?.call(value);
            });
          },
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
          ),
          dropdownColor: Colors.black,
        ),
      ),
    );
  }
}

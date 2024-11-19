import 'dart:convert';
import 'dart:ffi';
import 'dart:io';

import 'package:Freecycle/ad_helper/ad_helper.dart';
import 'package:Freecycle/screens/country_state_city2.dart';
import 'package:Freecycle/screens/credit_page.dart';
import 'package:Freecycle/screens/post_screen.dart';
import 'package:Freecycle/screens/search_screen.dart';
import 'package:Freecycle/src/rvncat_constant.dart';
import 'package:Freecycle/widgets/post_card.dart';
import 'package:flutter/scheduler.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:csc_picker/csc_picker.dart';
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

  @override
  void initState() {
    super.initState();
    _getUserLocation();

    _checkPremiumStatus();
    _loadInterstitialAd();
    _getUserCountry();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.addListener(_onScroll);
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

        setState(() {
          userCountry = userDoc['country'];
        });
      } catch (e) {
        print("Error fetching user country: $e");
      }
    }
  }

// _loadMorePosts metodunda değişiklikler
  Future<void> _loadMorePosts() async {
    if (_isLoadingMore || !_hasMore) return;

    setState(() {
      _isLoadingMore = true;
    });

    print("Loading more posts. Current count: ${_posts.length}");

    Query query = FirebaseFirestore.instance
        .collection('posts')
        .orderBy('datePublished', descending: true);

    if (_selectedFilter == 'Country' && country != null) {
      query = query.where('country', isEqualTo: country);
    } else if (_selectedFilter == 'State' && state != null) {
      query = query.where('state', isEqualTo: state);
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

    try {
      final snapshots = await query.get();

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

      if (newPosts.isEmpty) {
        print("All loaded posts are duplicates");
        if (_posts.length < _limit) {
          _hasMore = false;
        } else {
          // Try to load more posts
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
      setState(() {
        _isLoadingMore = false;
        _isInitialLoading = false;
      });
    }
  }

// _updatePostsStream metodunda değişiklikler
  void _updatePostsStream(String category, {String? filter}) {
    print("Updating posts stream for category: $category, filter: $filter");
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
      }
    } catch (e) {
      print("Error checking premium status: $e");
    }
  }

  void _showLocationSelectionBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (BuildContext context, StateSetter setModalState) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.5,
            decoration: BoxDecoration(
              color: Color(0xFF1E1E1E),
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                Container(
                  height: 4,
                  width: 40,
                  margin: EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.grey,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Update Location',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: CSCPicker(
                      showStates: showState,
                      showCities: showCity,
                      flagState: CountryFlag.SHOW_IN_DROP_DOWN_ONLY,
                      dropdownDecoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: Colors.white.withOpacity(0.1),
                        border:
                            Border.all(color: Colors.grey.shade400, width: 1),
                      ),
                      disabledDropdownDecoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: Colors.grey.withOpacity(0.1),
                        border:
                            Border.all(color: Colors.grey.shade400, width: 1),
                      ),
                      selectedItemStyle: TextStyle(color: Colors.white),
                      dropdownHeadingStyle:
                          TextStyle(color: Colors.white, fontSize: 17),
                      dropdownItemStyle: TextStyle(color: Colors.white),
                      dropdownDialogRadius: 10.0,
                      searchBarRadius: 10.0,
                      onCountryChanged: (value) {
                        setModalState(() {
                          countryValue = value;
                          stateValue = null;
                          cityValue = null;
                          showState = true;
                          showCity = false;
                        });
                      },
                      onStateChanged: (value) {
                        setModalState(() {
                          stateValue = value;
                          cityValue = null;
                          showCity = true;
                        });
                      },
                      onCityChanged: (value) {
                        setModalState(() {
                          cityValue = value;
                        });
                      },
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ElevatedButton(
                    child: Text('Save'),
                    style: ElevatedButton.styleFrom(
                      primary: Colors.blue,
                      onPrimary: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      _saveAndUpdateLocation();
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _saveAndUpdateLocation() {
    setState(() {
      _isLocationSet = true;
      if (cityValue != null && cityValue!.isNotEmpty) {
        _selectedFilter = 'City';
        country = countryValue;
        state = stateValue;
        city = cityValue;
      } else if (stateValue != null && stateValue!.isNotEmpty) {
        _selectedFilter = 'State';
        country = countryValue;
        state = stateValue;
        city = null;
      } else if (countryValue != null && countryValue!.isNotEmpty) {
        _selectedFilter = 'Country';
        country = countryValue;
        state = null;
        city = null;
      }
    });
    _saveUserLocation();
    _updatePostsStream(selectedCategory, filter: _selectedFilter);
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
            child: CSCPicker(
              showStates: title == 'State',
              showCities: title == 'City',
              flagState: CountryFlag.DISABLE,
              dropdownDecoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: Colors.transparent,
              ),
              disabledDropdownDecoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: Colors.grey.withOpacity(0.1),
              ),
              selectedItemStyle: TextStyle(color: Colors.white),
              dropdownHeadingStyle:
                  TextStyle(color: Colors.white, fontSize: 17),
              dropdownItemStyle: TextStyle(color: Colors.white),
              dropdownDialogRadius: 10.0,
              searchBarRadius: 10.0,
              onCountryChanged: title == 'Country' ? onChanged : null,
              onStateChanged: title == 'State' ? onChanged : null,
              onCityChanged: title == 'City' ? onChanged : null,
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
    InterstitialAd.load(
      adUnitId: AdHelper.interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (InterstitialAd ad) {
          _interstitialAd = ad;
          _isInterstitialAdReady = true;
          _setFullScreenContentCallback(ad);
        },
        onAdFailedToLoad: (LoadAdError error) {
          print("Failed to load Interstitial Ad: ${error.message}");
          _isInterstitialAdReady = false;
          _loadInterstitialAd(); // Retry loading the ad
        },
      ),
    );
  }

  void _setFullScreenContentCallback(InterstitialAd ad) {
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (InterstitialAd ad) {
        ad.dispose();
        _loadInterstitialAd(); // Load a new ad
      },
      onAdFailedToShowFullScreenContent: (InterstitialAd ad, AdError error) {
        print('$ad failed to show with error $error');
        ad.dispose();
        _loadInterstitialAd(); // Load a new ad
      },
    );
  }

  void _showInterstitialAd() {
    if (_interstitialAd != null && _isInterstitialAdReady) {
      _interstitialAd!.show();
      _isInterstitialAdReady = false;
    } else {
      print("Interstitial ad is not ready yet.");
      _loadInterstitialAd(); // Try to load the ad again
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >
            _scrollController.position.maxScrollExtent - 500 &&
        !_isLoadingMore) {
      _loadMorePosts();
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _interstitialAd?.dispose();
    super.dispose();
  }

  Future<void> _getUserLocation() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        setState(() {
          country = userDoc['country'];
          state = userDoc['state'];
          city = userDoc['city'];
          isLoading = false;

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

        if (_isLocationSet) {
          _updatePostsStream(selectedCategory, filter: _selectedFilter);
        }
      } catch (e) {
        print("Error fetching user location: $e");
        setState(() {
          isLoading = false;
        });
      }
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _saveUserLocation() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'country': countryValue,
        'state': stateValue,
        'city': cityValue,
      });
    }
  }

  Widget _buildLocationFilterDisplay() {
    String displayText = 'Select Location';
    if (city != null && city!.isNotEmpty) {
      displayText = '$city, $country';
    } else if (state != null && state!.isNotEmpty) {
      displayText = '$state, $country';
    } else if (country != null && country!.isNotEmpty) {
      displayText = country!;
    }

    return GestureDetector(
      onTap: _showLocationSelectionBottomSheet,
      child: Container(
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.5),
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.location_on, size: 16, color: Colors.white),
            SizedBox(width: 4),
            Flexible(
              child: Text(
                displayText,
                style:
                    TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(Icons.arrow_drop_down, color: Colors.white),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerEffect(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[800]!,
      highlightColor: Colors.grey[700]!,
      child: _isGridView
          ? GridView.builder(
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
      Padding(
        padding: const EdgeInsets.only(top: 21.0),
        child: IconButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SearchScreen()),
            );
          },
          icon: const Icon(Icons.search),
        ),
      ),
      Padding(
        padding: const EdgeInsets.only(top: 21.0),
        child: _isPostSelected
            ? Container()
            : IconButton(
                onPressed: () {
                  setState(() {
                    _isGridView = !_isGridView;
                  });
                },
                icon: _isGridView
                    ? const Icon(Icons.notes_rounded)
                    : const Icon(Icons.grid_view_rounded),
              ),
      ),
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
                title:
                    Text('Post Details', style: TextStyle(color: Colors.white)),
              )
            : null,
        body: NestedScrollView(
          physics: const BouncingScrollPhysics(),
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return _isPostSelected
                ? []
                : [
                    SliverAppBar(
                      pinned: true,
                      automaticallyImplyLeading: false,
                      systemOverlayStyle: const SystemUiOverlayStyle(
                        statusBarColor: Colors.transparent,
                        statusBarIconBrightness: Brightness.light,
                      ),
                      snap: true,
                      floating: true,
                      expandedHeight: 100,
                      collapsedHeight: 60,
                      flexibleSpace: FlexibleSpaceBar(
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
                            Positioned(
                              bottom: 15,
                              left: 0,
                              right: 0,
                              child: Padding(
                                padding: EdgeInsets.all(20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildLocationFilterDisplay(),
                                    SizedBox(height: 5),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      actions: _buildAppBarActions(),
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
                    SizedBox(
                      height: 30,
                      child: ListView(
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
                              padding: const EdgeInsets.only(left: 8.0),
                              child: ElevatedButton(
                                onPressed: () {
                                  _updatePostsStream(category);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: selectedCategory == category
                                      ? const Color.fromARGB(255, 13, 98, 167)
                                      : Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                                child: Text(
                                  category,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: selectedCategory == category
                                        ? Colors.white
                                        : Colors.black,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: _isInitialLoading
                          ? _buildShimmerEffect(context)
                          : _posts.isEmpty
                              ? Padding(
                                  padding: const EdgeInsets.only(top: 35.0),
                                  child: Center(
                                    child: Column(
                                      children: [
                                        Text(
                                          country == null || country!.isEmpty
                                              ? "Please select your country to see products \nin your area"
                                              : "No products found for the selected filter: $_selectedFilter",
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            color: Colors.grey,
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        country == null || country!.isEmpty
                                            ? Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: <Widget>[
                                                  CSCPicker(
                                                    showStates: false,
                                                    showCities: false,
                                                    flagState: CountryFlag
                                                        .SHOW_IN_DROP_DOWN_ONLY,
                                                    dropdownDecoration:
                                                        BoxDecoration(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              8),
                                                      color: Colors.white
                                                          .withOpacity(0.2),
                                                    ),
                                                    disabledDropdownDecoration:
                                                        BoxDecoration(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              8),
                                                      color: Colors.grey
                                                          .withOpacity(0.1),
                                                    ),
                                                    selectedItemStyle:
                                                        const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 14,
                                                    ),
                                                    dropdownHeadingStyle:
                                                        const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 17,
                                                    ),
                                                    dropdownItemStyle:
                                                        const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 14,
                                                    ),
                                                    onCountryChanged: (value) {
                                                      setState(() {
                                                        countryValue =
                                                            value ?? "";
                                                      });
                                                    },
                                                    onStateChanged: (value) {
                                                      setState(() {
                                                        stateValue =
                                                            value ?? "";
                                                      });
                                                    },
                                                    onCityChanged: (value) {
                                                      setState(() {
                                                        cityValue = value ?? "";
                                                      });
                                                    },
                                                  ),
                                                  SizedBox(height: 25),
                                                  ElevatedButton(
                                                    style: ElevatedButton
                                                        .styleFrom(
                                                      backgroundColor:
                                                          Colors.blue,
                                                      shape:
                                                          RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(8),
                                                      ),
                                                    ),
                                                    onPressed: () {
                                                      setState(() {
                                                        country = countryValue;
                                                        city = cityValue;
                                                        state = stateValue;
                                                      });
                                                      _updatePostsStream(
                                                          selectedCategory);
                                                      FirebaseFirestore.instance
                                                          .collection('users')
                                                          .doc(FirebaseAuth
                                                              .instance
                                                              .currentUser!
                                                              .uid)
                                                          .update({
                                                        'country': countryValue,
                                                        'state': stateValue,
                                                        'city': cityValue,
                                                        'address':
                                                            "$city, $state, $country",
                                                      });
                                                    },
                                                    child: const Text(
                                                      "Save",
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              )
                                            : Container()
                                      ],
                                    ),
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
                                              child: CachedNetworkImage(
                                                imageUrl: data['postUrl'],
                                                fit: BoxFit.cover,
                                                placeholder: (context, url) =>
                                                    _buildPostPlaceholder(
                                                        context),
                                                errorWidget:
                                                    (context, url, error) =>
                                                        const Icon(Icons.error),
                                              ),
                                            );
                                          },
                                        )
                                      : ListView.builder(
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
}

class FlexibleLocationPicker extends StatefulWidget {
  final Function(String?) onCountryChanged;
  final Function(String?) onStateChanged;
  final Function(String?) onCityChanged;
  final String? initialCountry;
  final String? initialState;
  final String? initialCity;

  const FlexibleLocationPicker({
    Key? key,
    required this.onCountryChanged,
    required this.onStateChanged,
    required this.onCityChanged,
    this.initialCountry,
    this.initialState,
    this.initialCity,
  }) : super(key: key);

  @override
  _FlexibleLocationPickerState createState() => _FlexibleLocationPickerState();
}

class _FlexibleLocationPickerState extends State<FlexibleLocationPicker> {
  List<String> countries = [];
  List<String> states = [];
  List<String> cities = [];
  String? errorMessage;

  String? currentCountry;
  String? currentState;
  String? currentCity;

  @override
  void initState() {
    super.initState();
    currentCountry = widget.initialCountry;
    currentState = widget.initialState;
    currentCity = widget.initialCity;

    SchedulerBinding.instance.addPostFrameCallback((_) {
      _loadCountries().then((_) {
        if (currentCountry != null) {
          _handleCountrySelection(currentCountry!);
        }
      });
    });
  }

  Future<void> _loadCountries() async {
    try {
      final loadedCountries = await LocationService.getCountries();
      setState(() {
        countries = loadedCountries;
        errorMessage = null;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Error loading countries: $e';
      });
      print(errorMessage);
    }
  }

  Future<void> _loadStates(String country) async {
    try {
      final loadedStates = await LocationService.getStates(country);
      setState(() {
        states = loadedStates;
        errorMessage = null;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Error loading states: $e';
      });
      print(errorMessage);
    }
  }

  Future<void> _loadCities(String country, String state) async {
    try {
      final loadedCities = await LocationService.getCities(country, state);
      setState(() {
        cities = loadedCities;
        errorMessage = null;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Error loading cities: $e';
      });
      print(errorMessage);
    }
  }

  void _handleCountrySelection(String country) {
    setState(() {
      currentCountry = country;
      currentState = null;
      currentCity = null;
      states = [];
      cities = [];
    });
    widget.onCountryChanged(country);
    _loadStates(country);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (errorMessage != null)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              errorMessage!,
              style: TextStyle(color: Colors.red),
            ),
          ),
        _buildDropdown(
          value: currentCountry,
          items: countries,
          hint: 'Select Country',
          onChanged: (value) {
            if (value != null) {
              _handleCountrySelection(value);
            }
          },
        ),
        SizedBox(height: 16),
        _buildDropdown(
          value: currentState,
          items: states,
          hint: 'Select State',
          onChanged: (value) {
            if (value != null && currentCountry != null) {
              setState(() {
                currentState = value;
                currentCity = null;
                cities = [];
              });
              widget.onStateChanged(value);
              _loadCities(currentCountry!, value);
            }
          },
        ),
        SizedBox(height: 16),
        _buildDropdown(
          value: currentCity,
          items: cities,
          hint: 'Select City',
          onChanged: (value) {
            if (value != null) {
              setState(() {
                currentCity = value;
              });
              widget.onCityChanged(value);
            }
          },
        ),
      ],
    );
  }

  Widget _buildDropdown({
    required String? value,
    required List<String> items,
    required String hint,
    required Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: items.contains(value) ? value : null,
      items: items.map((String item) {
        return DropdownMenuItem<String>(
          value: item,
          child: Text(item, style: TextStyle(color: Colors.white)),
        );
      }).toList(),
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white70),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.grey.shade700),
          borderRadius: BorderRadius.circular(10),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.blue),
          borderRadius: BorderRadius.circular(10),
        ),
        filled: true,
        fillColor: Color(0xFF2C2C2C),
      ),
      dropdownColor: Color(0xFF2C2C2C),
      style: TextStyle(color: Colors.white),
    );
  }
}

class LocationService {
  static const String username = 'gokhannavrz'; // GeoNames kullanıcı adınız
  static const String baseUrl = 'http://api.geonames.org';

  static Future<List<String>> getCountries() async {
    final url = '$baseUrl/countryInfoJSON?username=$username';
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return List<String>.from(
          data['geonames'].map((country) => country['countryName']));
    } else {
      throw Exception('Failed to load countries: ${response.body}');
    }
  }

  static Future<List<String>> getStates(String country) async {
    if (country == 'United States') {
      return _getUSStates();
    }

    final countryCode = await _getCountryCode(country);
    final url =
        '$baseUrl/childrenJSON?geonameId=$countryCode&username=$username&maxRows=1000';
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final allRegions = data['geonames'] as List<dynamic>;

      final filteredRegions = allRegions.where((region) {
        final name = region['name'] as String;
        final fcode = region['fcode'] as String;

        bool isAdminRegion = ['ADM1', 'ADM2', 'ADM3'].contains(fcode);
        bool containsUnwantedWords = [
          'County',
          'Province',
          'Municipality',
          'District',
          'Region',
          'Department',
          'Prefecture'
        ].any((word) => name.toLowerCase().contains(word.toLowerCase()));

        return isAdminRegion && !containsUnwantedWords && name.length > 2;
      }).toList();

      filteredRegions
          .sort((a, b) => (a['name'] as String).compareTo(b['name'] as String));

      if (filteredRegions.isEmpty) {
        // Eğer eyalet/bölge bulunamazsa, doğrudan şehirleri listeleyelim
        return getCities(country, '');
      }

      return filteredRegions.map((region) => region['name'] as String).toList();
    } else {
      throw Exception('Failed to load states: ${response.body}');
    }
  }

  static Future<List<String>> getCities(String country, String state) async {
    String geonameId;
    if (state.isEmpty) {
      geonameId = await _getCountryCode(country);
    } else {
      geonameId = await _getStateId(country, state);
    }

    final url =
        '$baseUrl/childrenJSON?geonameId=$geonameId&username=$username&maxRows=1000';
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final allPlaces = data['geonames'] as List<dynamic>;

      final filteredPlaces = allPlaces.where((place) {
        final name = place['name'] as String;
        final fcode = place['fcode'] as String;

        bool isPopulatedPlace = [
          'PPL',
          'PPLA',
          'PPLC',
          'PPLG',
          'PPLL',
          'PPLR',
          'PPLS'
        ].contains(fcode);

        return isPopulatedPlace && name.length > 2;
      }).toList();

      filteredPlaces
          .sort((a, b) => (a['name'] as String).compareTo(b['name'] as String));

      return filteredPlaces.map((place) => place['name'] as String).toList();
    } else {
      throw Exception('Failed to load cities: ${response.body}');
    }
  }

  static Future<String> _getCountryCode(String countryName) async {
    final url = '$baseUrl/searchJSON?q=$countryName&username=$username';
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['geonames'].isEmpty) {
        throw Exception('Country not found');
      }
      return data['geonames'][0]['geonameId'].toString();
    } else {
      throw Exception('Failed to get country code: ${response.body}');
    }
  }

  static Future<String> _getStateId(String country, String stateName) async {
    final countryCode = await _getCountryCode(country);
    final url =
        '$baseUrl/searchJSON?q=$stateName&country=$countryCode&username=$username';
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['geonames'].isEmpty) {
        throw Exception('State not found');
      }
      return data['geonames'][0]['geonameId'].toString();
    } else {
      throw Exception('Failed to get state ID: ${response.body}');
    }
  }

  static Future<List<String>> _getUSStates() async {
    return [
      'Alabama',
      'Alaska',
      'Arizona',
      'Arkansas',
      'California',
      'Colorado',
      'Connecticut',
      'Delaware',
      'Florida',
      'Georgia',
      'Hawaii',
      'Idaho',
      'Illinois',
      'Indiana',
      'Iowa',
      'Kansas',
      'Kentucky',
      'Louisiana',
      'Maine',
      'Maryland',
      'Massachusetts',
      'Michigan',
      'Minnesota',
      'Mississippi',
      'Missouri',
      'Montana',
      'Nebraska',
      'Nevada',
      'New Hampshire',
      'New Jersey',
      'New Mexico',
      'New York',
      'North Carolina',
      'North Dakota',
      'Ohio',
      'Oklahoma',
      'Oregon',
      'Pennsylvania',
      'Rhode Island',
      'South Carolina',
      'South Dakota',
      'Tennessee',
      'Texas',
      'Utah',
      'Vermont',
      'Virginia',
      'Washington',
      'West Virginia',
      'Wisconsin',
      'Wyoming',
      'District of Columbia'
    ];
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
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.initialCountry != null) {
        widget.onCountryChanged(widget.initialCountry);
      }
      if (widget.initialState != null) {
        widget.onStateChanged(widget.initialState);
      }
      if (widget.initialCity != null) {
        widget.onCityChanged(widget.initialCity);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SelectState(
      onCountryChanged: widget.onCountryChanged,
      onStateChanged: widget.onStateChanged,
      onCityChanged: widget.onCityChanged,
      style: TextStyle(color: Colors.white),
      dropdownColor: Color(0xFF2C2C2C),
    );
  }
}

import 'dart:io';

import 'package:freecycle/ad_helper/ad_helper.dart';
import 'package:freecycle/screens/credit_page.dart';
import 'package:freecycle/screens/job_post_screen.dart';
import 'package:freecycle/widgets/job_card.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:country_state_city_picker/country_state_city_picker.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:freecycle/screens/post_screen.dart';
import 'package:freecycle/screens/search_screen.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
// import math

import '../widgets/post_card.dart';

class DiscoverJobs extends StatefulWidget {
  const DiscoverJobs({Key? key}) : super(key: key);

  @override
  _DiscoverJobsState createState() => _DiscoverJobsState();
}

class _DiscoverJobsState extends State<DiscoverJobs> {
  late bool _isGridView = true;
  late String selectedCategory = 'All';
  String? country;
  late Stream<QuerySnapshot> _postsStream; // Stream'i tanımla
  late bool _isPostSelected = false;
  late String _selectedPostId = '';
  late String _selectedPostUid = '';
  String? city;
  String? state;
  String countryValue = "";
  String stateValue = "";
  String cityValue = "";
  InterstitialAd? _interstitialAd;
  bool isPremium = false;

  @override
  void initState() {
    super.initState();
    _getUserLocation();
    _prepareInterstitialAd();
    _postsStream =
        _buildStream('All'); // Başlangıçta 'All' kategorisiyle Stream'i başlat
  }

  // Helper method to build the Firestore stream
  Stream<QuerySnapshot> _buildStream(String category) {
    if (category == 'All') {
      return FirebaseFirestore.instance
          .collection('jobs')
          .where('country', isEqualTo: country)
          .orderBy('datePublished', descending: true)
          .snapshots();
    } else {
      return FirebaseFirestore.instance
          .collection('jobs')
          .where('category', isEqualTo: category)
          .where('country', isEqualTo: country)
          .orderBy('datePublished', descending: true)
          .snapshots();
    }
  }

  // This function will update the stream based on the selected category
  void _updatePostsStream(String category) {
    setState(() {
      selectedCategory = category;
      if (country != null) {
        _postsStream = _buildStream(category);
      }
    });
  }

  // get if user is premium, if user is premium set isPremium to true
  void _getPremiumStatus() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get()
          .then((value) {
        setState(() {
          isPremium = value['is_premium'];
        });
      });
    }
  }

  void _prepareInterstitialAd() {
    InterstitialAd.load(
      adUnitId: AdHelper.interstitialAdUnit,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(onAdLoaded: (currentAd) {
        currentAd.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (currentAd) {});
        setState(() {
          _interstitialAd = currentAd;
        });
      }, onAdFailedToLoad: (error) {
        print("Failed to load : Flutter AdMob Interstitial Ad");
      }),
    );
  }

  @override
  void dispose() {
    super.dispose();
    _postsStream.drain();
  }

  void _getUserLocation() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get()
          .then((value) {
        setState(() {
          country = value['country'];
          city = value['city'];
          state = value['state'];
          _updatePostsStream(selectedCategory);
        });
      });
    }
  }

  void _clearSelectedPost() {
    setState(() {
      _isPostSelected = false;
      _selectedPostId = '';
      _selectedPostUid = '';
    });
  }

  // Build a location widget based on the available location details
  Widget _buildLocationWidget() {
    if (state != null && state!.isNotEmpty) {
      return Text(state!,
          style: const TextStyle(fontSize: 15, color: Colors.grey));
    } else if (city != null && city!.isNotEmpty) {
      return Text(city!,
          style: const TextStyle(fontSize: 15, color: Colors.grey));
    } else if (country != null && country!.isNotEmpty) {
      return Text(
        country!,
        style: const TextStyle(fontSize: 15, color: Colors.grey),
      );
    } else {
      return Container(); // Fallback empty container if all location details are missing
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_isPostSelected) {
          // If a post is selected, clear the selection and prevent back navigation
          setState(() {
            _isPostSelected = false; // Post seçimini temizle
          });
          return false; // Prevent default back navigation
        } else {
          return true; // Allow default back navigation
        }
      },
      child: NestedScrollView(
        physics: const BouncingScrollPhysics(),
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              // change pinned background color
              pinned: true,
              automaticallyImplyLeading: false,
              systemOverlayStyle: const SystemUiOverlayStyle(
                statusBarColor: Colors.transparent,
                statusBarIconBrightness: Brightness.light,
              ),
              snap: true,
              floating: true,
              // Make the app bar responsive
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
                    const Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Jobs",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 30,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(
                              height: 5,
                            ),
                            Text(
                              "Find what you need!",
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                // be premium button text button. gradient color
                if (!Platform.isIOS)
                  Padding(
                    padding: const EdgeInsets.only(top: 21.0),
                    child: TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const CreditPage(),
                          ),
                        );
                      },
                      // gradient colors
                      style: TextButton.styleFrom(
                        padding: EdgeInsets
                            .zero, // Remove the padding from TextButton
                      ),
                      child: Container(
                        height: 35,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Colors.blue,
                              Colors.purple
                            ], // Replace with your gradient colors
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Padding(
                          padding: EdgeInsets.all(
                              10.0), // Adjust the padding as needed
                          child: Center(
                            child: Text(
                              'Free Credits',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.only(top: 21.0),
                  child: IconButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const SearchScreen()),
                      );
                    },
                    icon: const Icon(Icons.search),
                  ),
                ),
                // Show location icon only when no post is selected and navigate to location screen

                // Show grid view icon only when no post is selected
                Padding(
                  padding: const EdgeInsets.only(top: 21.0),
                  child: _isPostSelected
                      ? Container() // Don't render the button when a post is selected
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
              ],
            ),
          ];
        },
        body: _isPostSelected
            ? jobscreen(
                postId: _selectedPostId,
                uid: _selectedPostUid,
              )
            : Column(
                children: [
                  SizedBox(
                    height: 30, // Adjust the height as needed
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        for (var category in [
                          'All',
                          "Attic conversion",
                          "Bathroom remodeling",
                          "Cabinet installation",
                          "Carpet cleaning",
                          "Childcare",
                          "Cleaning",
                          "Countertop installation",
                          "Crop rotation",
                          "Dishwashing",
                          "Door replacement",
                          "Elderly care",
                          "Electrical",
                          "Equipment maintenance",
                          "Feeding",
                          "Fence maintenance",
                          "Fertilizing",
                          "Flooring installation",
                          "Garden maintenance",
                          "General repairs",
                          "Grooming",
                          "Grocery shopping",
                          "Harvesting crops",
                          "HVAC",
                          "Ironing",
                          "Irrigation management",
                          "Irrigation system maintenance",
                          "Kitchen remodeling",
                          "Landscaping projects",
                          "Lawn mowing",
                          "Laundry",
                          "Livestock care and management",
                          "Meal preparation",
                          "Mulching",
                          "Masonry",
                          "Organizing",
                          "Pest control",
                          "Pest management",
                          "Painting",
                          "Pet boarding",
                          "Pet sitting",
                          "Planting",
                          "Planting crops",
                          "Plumbing",
                          "Pruning",
                          "Private tutoring",
                          "Roofing",
                          "Soil testing and fertilization",
                          "Training",
                          "Wall tiling",
                          "Walking",
                          "Weeding",
                          "Window replacement",
                          "Workplace assistance"
                        ])
                          // show category buttons with nice animation
                          Padding(
                            padding: const EdgeInsets.only(left: 8.0),
                            child: ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  _updatePostsStream(category);
                                });
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
                    child: StreamBuilder<QuerySnapshot>(
                      stream: _postsStream, // Güncellenmiş Stream'i kullan
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return const Center(
                            child: Text('Something went wrong'),
                          );
                        }

                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(
                              color: Colors.black,
                            ),
                          );
                        }

                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20.0, vertical: 50),
                              child: Column(
                                children: [
                                  Text(
                                    // if country is not selected show this message "Please select your country to see products in your area"
                                    country == null || country!.isEmpty
                                        ? "Please select your country to see products \nin your area"
                                        : // if selected category is 'All' show this message "No products found" else show "No products found in this category"
                                        selectedCategory == 'All'
                                            ? "No products found"
                                            : "No products found in this category",
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  // if country is not selected show add location button else show change location button
                                  country == null || country!.isEmpty
                                      ? Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: <Widget>[
                                            Container(
                                              height:
                                                  180, // Yüksekliği artıralım çünkü alanlar alt alta olacak
                                              child: ClipRect(
                                                child: SelectState(
                                                  onCountryChanged: (value) {
                                                    setState(() {
                                                      countryValue = value;
                                                      stateValue = "";
                                                      cityValue = "";
                                                    });
                                                  },
                                                  onStateChanged: (value) {
                                                    setState(() {
                                                      stateValue = value;
                                                      cityValue = "";
                                                    });
                                                  },
                                                  onCityChanged: (value) {
                                                    setState(() {
                                                      cityValue = value;
                                                    });
                                                  },
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 16,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            SizedBox(height: 25),
                                            ElevatedButton(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.blue,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                              ),
                                              onPressed: () {
                                                setState(() {
                                                  country = countryValue;
                                                  state = stateValue;
                                                });
                                                // refresh the stream
                                                _updatePostsStream(
                                                    selectedCategory);
                                                FirebaseFirestore.instance
                                                    .collection('users')
                                                    .doc(FirebaseAuth.instance
                                                        .currentUser!.uid)
                                                    .update({
                                                  'country': countryValue,
                                                  'state': stateValue,
                                                  'address': "$state, $country",
                                                });
                                              },
                                              child: const Text("Save",
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                  )),
                                            ),
                                          ],
                                        )
                                      : Container()
                                ],
                              ),
                            ),
                          );
                        }

                        return _isGridView
                            ? GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: snapshot.data!.docs.length,
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 3,
                                  crossAxisSpacing: 2,
                                  mainAxisSpacing: 2,
                                ),
                                itemBuilder: (context, index) {
                                  DocumentSnapshot data =
                                      snapshot.data!.docs[index];
                                  return GestureDetector(
                                    onTap: () {
                                      if (_interstitialAd != null &&
                                          !isPremium) {
                                        _interstitialAd?.show();
                                      } else {}
                                      setState(() {
                                        _isPostSelected = true;
                                        _selectedPostId = data.id;
                                        _selectedPostUid = data['uid'];
                                      });
                                    },
                                    child: CachedNetworkImage(
                                      imageUrl: data['postUrl'],
                                      fit: BoxFit.cover,
                                      placeholder: (context, url) =>
                                          const Center(),
                                      errorWidget: (context, url, error) =>
                                          const Icon(Icons.error),
                                    ),
                                  );
                                },
                              )
                            : ListView.builder(
                                itemCount: snapshot.data!.docs.length,
                                itemBuilder: (context, index) {
                                  DocumentSnapshot data =
                                      snapshot.data!.docs[index];
                                  return PostCard(
                                    snap: data,
                                    isBlocked: false,
                                    isGridView: false,
                                  );
                                },
                              );
                      },
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

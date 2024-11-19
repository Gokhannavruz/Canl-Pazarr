import 'package:Freecycle/screens/credit_page.dart';
import 'package:Freecycle/screens/job_post_screen.dart';
import 'package:Freecycle/widgets/job_card.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:Freecycle/screens/post_screen.dart';
import 'package:Freecycle/screens/search_screen.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
// import math

import '../widgets/post_card.dart';

class DiscoverJobsPage extends StatefulWidget {
  const DiscoverJobsPage({Key? key}) : super(key: key);

  @override
  State<DiscoverJobsPage> createState() => _DiscoverJobsPage();
}

class _DiscoverJobsPage extends State<DiscoverJobsPage> {
  late final bool _isShuffleActive = false;
  BannerAd? _bannerAd;
  late bool _isGridView = true;
  int adIndex = 3;
  int currenAdCount = 0;
  bool isAdLoaded = false;
  NativeAd? _nativeAd;
  NativeAd? _nativeAd2;
  late String selectedCategory = 'All';
  late String country;
  late String city;
  late String state;
  bool isFiltered = false;
  bool isTextVisible = true;

  void toggleTextVisibility() {
    setState(() {
      isTextVisible = !isTextVisible;
    });
  }

  @override
  void initState() {
    super.initState();
    _loadNativeAd();
    _getUserLocation();
  }

  @override
  void dispose() {
    super.dispose();
    _bannerAd?.dispose();
    _loadNativeAd();
    _nativeAd?.dispose();
    _nativeAd2?.dispose();
  }

  // get user location  and add to variable country, city, state
  void _getUserLocation() {
    FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .get()
        .then((value) {
      setState(() {
        country = value['country'];
        city = value['city'];
        state = value['state'];
      });
    });
  }

  void _loadNativeAd() {
    _nativeAd = NativeAd(
      adUnitId: 'ca-app-pub-8445989958080180/7276038914',
      factoryId: 'listTile',
      request: const AdRequest(),
      listener: NativeAdListener(
        // Called when an ad is successfully received.
        onAdLoaded: (Ad ad) {
          var add = ad as NativeAd;
          setState(() {
            _nativeAd = add;
            isAdLoaded = true;
          });
        },

        // Called when an ad request failed.
        onAdFailedToLoad: (Ad ad, LoadAdError error) {
          // Dispose the ad here to free resources.
          ad.dispose();
        },
        // Called when an ad opens an overlay that covers the screen.
        onAdOpened: (Ad ad) => print('Ad opened.'),
        // Called when an ad removes an overlay that covers the screen.
        onAdClosed: (Ad ad) => print('Ad closed.'),
        // Called when an impression occurs on the ad.
        onAdImpression: (Ad ad) => print('Ad impression.'),
        // Called when a click is recorded for a NativeAd.
        onAdClicked: (Ad ad) => print('Ad clicked.'),
      ),
    );

    _nativeAd!.load();
  }

  @override
  Widget build(BuildContext context) {
    return NestedScrollView(
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
                    padding:
                        EdgeInsets.zero, // Remove the padding from TextButton
                  ),
                  child: Container(
                    height: 35,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.blue,
                          Colors.purple
                        ], // Replace with your gradient colors
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(
                          10.0), // Adjust the padding as needed
                      child: Center(
                        child: const Text(
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

              // İS GRID VIEW TRUE THEN SHOW GRID VIEW ICON
              Padding(
                padding: const EdgeInsets.only(top: 21.0),
                child: IconButton(
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
              // Padding(
              //   padding: const EdgeInsets.only(top: 24.0),
              //   child: IconButton(
              //     onPressed: () {
              //       setState(() {
              //         _isShuffleActive = !_isShuffleActive;
              //       });
              //       _createBannerAd();
              //     },
              //     icon: _isShuffleActive
              //         ? const Icon(Icons.sort)
              //         : const Icon(Icons.shuffle),
              //   ),
              // ),
            ],
          ),
        ];
      },
      body: Column(
        children: [
          SizedBox(
            height: 30, // Adjust the height as needed
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (var category in [
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
                          selectedCategory = category;
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
          // text
          // Padding(
          //   padding: const EdgeInsets.only(top: 10.0),
          //   child: Align(
          //     alignment: Alignment.center,
          //     child: Container(
          //       decoration: BoxDecoration(
          //         borderRadius: BorderRadius.circular(10),
          //         color: Colors.green[700],
          //       ),
          //       width: MediaQuery.of(context).size.width * 0.9,
          //       child: Padding(
          //         padding: const EdgeInsets.all(8.0),
          //         child: Text(
          //           "Welcome to Freecycle \nwhere sharing means caring! At Freecycle, we believe in the power of giving and receiving. Share what you no longer need and discover treasures from others, all for FREE. Together, we can reduce waste and build a stronger, more connected community. Start sharing now and make a difference! ",
          //           style: TextStyle(
          //             fontSize: 13,
          //             color: Colors.white,
          //           ),
          //         ),
          //       ),
          //     ),
          //   ),
          // ),

          // select location button and show location with nice animation
          // Padding(
          //   padding: const EdgeInsets.only(left: 8.0),
          //   child: Row(
          //     children: [
          //       // show location icon
          //       const Icon(
          //         Icons.location_on,
          //         color: Colors.grey,
          //       ),
          //       const SizedBox(width: 5),
          //       // show current user location with stream builder
          //       StreamBuilder(
          //         stream: FirebaseFirestore.instance
          //             .collection('users')
          //             .doc(FirebaseAuth.instance.currentUser!.uid)
          //             .snapshots(),
          //         builder: (context, AsyncSnapshot<DocumentSnapshot> snapshot) {
          //           if (snapshot.hasData) {
          //             final country = snapshot.data!['country'];
          //             final state = snapshot.data!['state'];
          //             if (country != "" && state != "") {
          //               return Text(
          //                 '$state $country',
          //                 style:
          //                     const TextStyle(fontSize: 13, color: Colors.grey),
          //               );
          //             } else if (country != "") {
          //               return Text(
          //                 country,
          //                 style:
          //                     const TextStyle(fontSize: 13, color: Colors.grey),
          //               );
          //             } else if (state != "") {
          //               return Text(
          //                 state,
          //                 style:
          //                     const TextStyle(fontSize: 13, color: Colors.grey),
          //               );
          //             }
          //           }
          //           return const Text('Select your country and state');
          //         },
          //       ),
          //       // show select location button
          //       TextButton(
          //         onPressed: () {
          //           // show country_state_city page only half screen
          //           showModalBottomSheet(
          //             // nice animation for show modal bottom sheet
          //             backgroundColor: const Color.fromARGB(0, 60, 58, 58),
          //             isScrollControlled: true,
          //             constraints: BoxConstraints(
          //               maxHeight: MediaQuery.of(context).size.height * 0.75,
          //             ),
          //             context: context,
          //             builder: (context) => const CountryStateCity(),
          //           );
          //         },
          //         // show csc picker dialog

          //         child: const Text(
          //           'Select Location',
          //           style: TextStyle(
          //             color: Colors.blue,
          //           ),
          //         ),
          //       ),
          //       const SizedBox(width: 5),
          //       // icon button for filter
          //       Row(
          //         children: [
          //           IconButton(
          //             onPressed: () {
          //               setState(() {
          //                 isFiltered = !isFiltered;
          //               });
          //             },
          //             icon: Icon(
          //               Icons.filter_list,
          //               color: isFiltered ? Colors.blue : Colors.grey,
          //             ),
          //           ),
          //         ],
          //       ),
          //     ],
          //   ),
          // ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refresh,
              child: // if shuffle true then show posts from random users
                  _isShuffleActive == true
                      ?
                      // if selectedCategory 'All' then show posts from random users
                      (selectedCategory == 'All')
                          ? StreamBuilder<QuerySnapshot>(
                              stream: FirebaseFirestore.instance
                                  .collection('jobs')
                                  .snapshots(),
                              builder: (context, snapshot) {
                                return Padding(
                                  padding: const EdgeInsets.all(4),
                                  child: Visibility(
                                    visible: _isGridView,
                                    child: GridView.builder(
                                      shrinkWrap: true,
                                      physics:
                                          const NeverScrollableScrollPhysics(),
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
                                            Navigator.of(context).push(
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    jobPostScreen(
                                                  postId: data.id,
                                                  uid: data['uid'],
                                                ),
                                              ),
                                            );
                                          },
                                          child: Image.network(
                                            data['postUrl'],
                                            fit: BoxFit.cover,
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                );
                              },
                            )
                          : _isGridView == true
                              ?

                              // if selected category 'All' then show all posts
                              // if selected category is not 'All' then show posts from selected category
                              (selectedCategory == 'All')
                                  ? StreamBuilder<QuerySnapshot>(
                                      stream: FirebaseFirestore.instance
                                          .collection('jobs')
                                          .snapshots(),
                                      builder: (context, snapshot) {
                                        if (snapshot.hasError) {
                                          return const Center(
                                            child: Text("Something went wrong"),
                                          );
                                        }

                                        if (snapshot.connectionState ==
                                            ConnectionState.waiting) {
                                          return const Center(
                                            child: CircularProgressIndicator(
                                              color: Colors.blue,
                                            ),
                                          );
                                        }

                                        return Padding(
                                          padding: const EdgeInsets.all(4),
                                          child: Visibility(
                                            visible: _isGridView,
                                            child: GridView.builder(
                                              shrinkWrap: true,
                                              physics:
                                                  const NeverScrollableScrollPhysics(),
                                              itemCount:
                                                  snapshot.data!.docs.length,
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
                                                    Navigator.of(context).push(
                                                      MaterialPageRoute(
                                                        builder: (context) =>
                                                            jobPostScreen(
                                                          postId: data.id,
                                                          uid: data['uid'],
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                  child: Image.network(
                                                    data['postUrl'],
                                                    fit: BoxFit.cover,
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                        );
                                      },
                                    )
                                  : StreamBuilder<QuerySnapshot>(
                                      stream: FirebaseFirestore.instance
                                          .collection('jobs')
                                          //if selectedCategory is not empty then show posts from
                                          .where('category',
                                              isEqualTo: selectedCategory)
                                          .snapshots(),
                                      builder: (context, snapshot) {
                                        if (snapshot.hasError) {
                                          return const Center(
                                            child: Text("Something went wrong"),
                                          );
                                        }

                                        if (snapshot.connectionState ==
                                            ConnectionState.waiting) {
                                          return const Center(
                                            child: CircularProgressIndicator(
                                              color: Colors.blue,
                                            ),
                                          );
                                        }

                                        return // show ad every 3 post card
                                            Padding(
                                          padding: const EdgeInsets.all(4),
                                          child: Visibility(
                                            visible: _isGridView,
                                            child: GridView.builder(
                                              shrinkWrap: true,
                                              physics:
                                                  const NeverScrollableScrollPhysics(),
                                              itemCount:
                                                  snapshot.data!.docs.length,
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
                                                    Navigator.of(context).push(
                                                      MaterialPageRoute(
                                                        builder: (context) =>
                                                            jobPostScreen(
                                                          postId: data.id,
                                                          uid: data['uid'],
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                  child: Image.network(
                                                    data['postUrl'],
                                                    fit: BoxFit.cover,
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                        );
                                      },
                                    )
                              // if grid view false then show posts in list view
                              : // if selected category 'All' then show all posts
                              // if selected category is not 'All' then show posts from selected category
                              (selectedCategory == 'All')
                                  ? StreamBuilder<QuerySnapshot>(
                                      stream: FirebaseFirestore.instance
                                          .collection('jobs')
                                          .snapshots(),
                                      builder: (context, snapshot) {
                                        if (snapshot.hasError) {
                                          return const Center(
                                            child: Text("Something went wrong"),
                                          );
                                        }

                                        if (snapshot.connectionState ==
                                            ConnectionState.waiting) {
                                          return const Center(
                                            child: CircularProgressIndicator(
                                              color: Colors.blue,
                                            ),
                                          );
                                        }

                                        return ListView.builder(
                                          itemCount: snapshot.data!.docs.length,
                                          itemBuilder: (context, index) {
                                            currenAdCount++;
                                            if (currenAdCount % adIndex == 0 &&
                                                isAdLoaded) {
                                              return Column(
                                                children: [
                                                  JobCard(
                                                    isBlocked: false,
                                                    isGridView: false,
                                                    snap: snapshot
                                                        .data!.docs[index],
                                                  ),
                                                  Container(
                                                    alignment: Alignment.center,
                                                    child: AdWidget(
                                                        ad: _nativeAd!),
                                                  ),
                                                ],
                                              );
                                            } else {
                                              return JobCard(
                                                isBlocked: false,
                                                isGridView: false,
                                                snap:
                                                    snapshot.data!.docs[index],
                                              );
                                            }
                                          },
                                        );
                                      },
                                    )
                                  : StreamBuilder<QuerySnapshot>(
                                      stream: FirebaseFirestore.instance
                                          .collection('jobs')
                                          // if selectedCategory is not empty then show posts from selectedCategory
                                          .where('category',
                                              isEqualTo: selectedCategory)
                                          .snapshots(),
                                      builder: (context, snapshot) {
                                        if (snapshot.hasError) {
                                          return const Center(
                                            child: Text("Something went wrong"),
                                          );
                                        }

                                        if (snapshot.connectionState ==
                                            ConnectionState.waiting) {
                                          return const Center(
                                            child: CircularProgressIndicator(
                                              color: Colors.blue,
                                            ),
                                          );
                                        }

                                        return ListView.builder(
                                          itemCount: snapshot.data!.docs.length,
                                          itemBuilder: (context, index) {
                                            currenAdCount++;
                                            if (currenAdCount % adIndex == 0 &&
                                                isAdLoaded) {
                                              return Column(
                                                children: [
                                                  JobCard(
                                                    isBlocked: false,
                                                    isGridView: false,
                                                    snap: snapshot
                                                        .data!.docs[index],
                                                  ),
                                                  Container(
                                                    height: 55.0,
                                                    alignment: Alignment.center,
                                                    child: AdWidget(
                                                        ad: _nativeAd!),
                                                  ),
                                                ],
                                              );
                                            } else {
                                              return JobCard(
                                                isBlocked: false,
                                                isGridView: false,
                                                snap:
                                                    snapshot.data!.docs[index],
                                              );
                                            }
                                          },
                                        );
                                      },
                                    )
                      // if shuffle false then show posts
                      // is grid view true then show posts in grid view
                      //if selectedCategory 'All' then show all posts
                      : _isGridView == true
                          ? (selectedCategory == 'All')
                              ? StreamBuilder<QuerySnapshot>(
                                  stream: FirebaseFirestore.instance
                                      .collection('jobs')
                                      .snapshots(),
                                  builder: (context, snapshot) {
                                    if (snapshot.hasError) {
                                      return const Center(
                                        child: Text("Something went wrong"),
                                      );
                                    }

                                    if (snapshot.connectionState ==
                                        ConnectionState.waiting) {
                                      return const Center(
                                        child: CircularProgressIndicator(
                                          color: Colors.blue,
                                        ),
                                      );
                                    }

                                    return Padding(
                                      padding: const EdgeInsets.all(4),
                                      child: Visibility(
                                        visible: _isGridView,
                                        child: GridView.builder(
                                          shrinkWrap: true,
                                          physics:
                                              const NeverScrollableScrollPhysics(),
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
                                                Navigator.of(context).push(
                                                  MaterialPageRoute(
                                                    builder: (context) =>
                                                        jobPostScreen(
                                                      postId: data.id,
                                                      uid: data['uid'],
                                                    ),
                                                  ),
                                                );
                                              },
                                              child: Image.network(
                                                data['postUrl'],
                                                fit: BoxFit.cover,
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    );
                                  },
                                )
                              : StreamBuilder<QuerySnapshot>(
                                  stream: FirebaseFirestore.instance
                                      .collection('jobs')
                                      //if selectedCategory is not empty then show posts from selectedCategory
                                      .where('category',
                                          isEqualTo: selectedCategory)
                                      .snapshots(),
                                  builder: (context, snapshot) {
                                    if (snapshot.hasError) {
                                      return const Center(
                                        child: Text("Something went wrong"),
                                      );
                                    }

                                    if (snapshot.connectionState ==
                                        ConnectionState.waiting) {
                                      return const Center(
                                        child: CircularProgressIndicator(
                                          color: Colors.blue,
                                        ),
                                      );
                                    }

                                    return Padding(
                                      padding: const EdgeInsets.all(4),
                                      child: Visibility(
                                        visible: _isGridView,
                                        child: GridView.builder(
                                          shrinkWrap: true,
                                          physics:
                                              const NeverScrollableScrollPhysics(),
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
                                                Navigator.of(context).push(
                                                  MaterialPageRoute(
                                                    builder: (context) =>
                                                        jobPostScreen(
                                                      postId: data.id,
                                                      uid: data['uid'],
                                                    ),
                                                  ),
                                                );
                                              },
                                              child: Image.network(
                                                data['postUrl'],
                                                fit: BoxFit.cover,
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    );
                                  },
                                )
                          // if grid view false then show posts in list view
                          // if selected category 'All' then show all posts
                          : (selectedCategory == 'All')
                              ? StreamBuilder<QuerySnapshot>(
                                  stream: FirebaseFirestore.instance
                                      .collection('jobs')
                                      .snapshots(),
                                  builder: (context, snapshot) {
                                    if (snapshot.hasError) {
                                      return const Center(
                                        child: Text("Something went wrong"),
                                      );
                                    }

                                    if (snapshot.connectionState ==
                                        ConnectionState.waiting) {
                                      return const Center(
                                        child: CircularProgressIndicator(
                                          color: Colors.blue,
                                        ),
                                      );
                                    }

                                    return ListView.builder(
                                      itemCount: snapshot.data!.docs.length,
                                      itemBuilder: (context, index) {
                                        currenAdCount++;
                                        if (currenAdCount % adIndex == 0 &&
                                            isAdLoaded) {
                                          return Column(
                                            children: [
                                              JobCard(
                                                isBlocked: false,
                                                isGridView: false,
                                                snap:
                                                    snapshot.data!.docs[index],
                                              ),
                                              Container(
                                                height: 55.0,
                                                alignment: Alignment.center,
                                                child: AdWidget(ad: _nativeAd!),
                                              ),
                                            ],
                                          );
                                        } else {
                                          return JobCard(
                                            isBlocked: false,
                                            isGridView: false,
                                            snap: snapshot.data!.docs[index],
                                          );
                                        }
                                      },
                                    );
                                  },
                                )
                              // if selected category is not 'All' then show posts from selected category
                              : StreamBuilder<QuerySnapshot>(
                                  stream: FirebaseFirestore.instance
                                      .collection('jobs')
                                      // if selectedCategory is not empty then show posts from selectedCategory
                                      .where('category',
                                          isEqualTo: selectedCategory)
                                      .orderBy('likes', descending: true)
                                      .snapshots(),
                                  builder: (context, snapshot) {
                                    if (snapshot.hasError) {
                                      return const Center(
                                        child: Text("Something went wrong"),
                                      );
                                    }

                                    if (snapshot.connectionState ==
                                        ConnectionState.waiting) {
                                      return const Center(
                                        child: CircularProgressIndicator(
                                          color: Colors.blue,
                                        ),
                                      );
                                    }

                                    return ListView.builder(
                                      itemCount: snapshot.data!.docs.length,
                                      itemBuilder: (context, index) {
                                        currenAdCount++;
                                        if (currenAdCount % adIndex == 0 &&
                                            isAdLoaded) {
                                          return Column(
                                            children: [
                                              JobCard(
                                                isBlocked: false,
                                                isGridView: false,
                                                snap:
                                                    snapshot.data!.docs[index],
                                              ),
                                              Container(
                                                height: 55.0,
                                                alignment: Alignment.center,
                                                child: AdWidget(ad: _nativeAd!),
                                              ),
                                            ],
                                          );
                                        } else {
                                          return JobCard(
                                            isBlocked: false,
                                            isGridView: false,
                                            snap: snapshot.data!.docs[index],
                                          );
                                        }
                                      },
                                    );
                                  },
                                ),
            ),
          ),
        ],
      ),
    );
  }

  // refresh stream
  Future<void> _refresh() async {
    setState(() {});
  }

  //  create a list for Posts liked by users who like posts the current user likes
  final List<String> _likedByUsersWhoLikePostsLikedByCurrentUser = [];
  // add to list posts liked by users who like posts the current user likes
  void _addToLikedByUsersWhoLikePostsLikedByCurrentUser(String postId) {
    FirebaseFirestore.instance
        .collection('jobs')
        .doc(postId)
        .collection('likes')
        .get()
        .then((value) {
      for (var element in value.docs) {
        FirebaseFirestore.instance
            .collection('jobs')
            .doc(element.id)
            .collection('likes')
            .get()
            .then((value) {
          for (var element in value.docs) {
            _likedByUsersWhoLikePostsLikedByCurrentUser.add(element.id);
          }
        });
      }
    });
  }
}

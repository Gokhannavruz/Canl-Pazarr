// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:freecycle/screens/incoming_messages.dart';
import 'package:freecycle/screens/login_screen.dart';
import 'package:freecycle/screens/notification_page.dart';
import 'package:freecycle/widgets/post_card.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class FeedScreen extends StatefulWidget {
  final String uid;
  const FeedScreen({
    Key? key,
    required this.uid,
  }) : super(key: key);

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  final user = FirebaseAuth.instance.currentUser!;
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  late String? fcmToken;
  final currentUser = FirebaseAuth.instance.currentUser;
  BannerAd? _bannerAd;
  NativeAd? _nativeAd;
  bool isAdLoaded = false;
  NativeAd? _nativeAd2;
  int adIndex = 4;
  int currenAdCount = 0;

  // following lists
  List<dynamic> following = [];

  @override
  void initState() {
    super.initState();
    _loadNativeAd();
    _fcm.getToken().then((token) {
      fcmToken = token;
      // save token to firestore current user fcmToken field
      if (fcmToken != null) {
        //save token to firestore
        FirebaseFirestore.instance
            .collection('users')
            .doc(FirebaseAuth.instance.currentUser!.uid)
            .update({'fcmToken': fcmToken});
        //if user does not have fcmToken field, create it
        FirebaseFirestore.instance
            .collection('users')
            .doc(FirebaseAuth.instance.currentUser!.uid)
            .get()
            .then((value) {
          if (!value.exists) {
            FirebaseFirestore.instance
                .collection('users')
                .doc(FirebaseAuth.instance.currentUser!.uid)
                .set({'fcmToken': fcmToken});
          }
        });
      }
    });
  }

  void _loadNativeAd() {
    _nativeAd = NativeAd(
      adUnitId: 'ca-app-pub-3940256099942544/2247696110',
      factoryId: 'listTile',
      request: const AdRequest(),
      listener: NativeAdListener(
        // Called when an ad is successfully received.
        onAdLoaded: (Ad ad) {
          var add = ad as NativeAd;
          print("**** AD ***** ${add.responseInfo}");
          setState(() {
            _nativeAd = add;
            isAdLoaded = true;
          });
        },

        // Called when an ad request failed.
        onAdFailedToLoad: (Ad ad, LoadAdError error) {
          // Dispose the ad here to free resources.
          ad.dispose();
          print('Ad load failed (code=${error.code} message=${error.message})');
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
  void dispose() {
    // _createBannerAd();
    _bannerAd?.dispose();
    _nativeAd?.dispose();
    _nativeAd2?.dispose();
    super.dispose();
  }

  // _nativeAd2 = NativeAd(
  //   adUnitId: 'ca-app-pub-8445989958080180/4958135755',
  //   factoryId: 'listTile',
  //   request: AdRequest(),
  //   listener: NativeAdListener(
  //     // Called when an ad is successfully received.
  //     onAdLoaded: (Ad ad) {
  //       var _add = ad as NativeAd;
  //       print("**** AD ***** ${_add.responseInfo}");
  //       setState(() {
  //         _nativeAd2 = _add;
  //         isAdLoaded = true;
  //       });
  //     },

  //     // Called when an ad request failed.
  //     onAdFailedToLoad: (Ad ad, LoadAdError error) {
  //       // Dispose the ad here to free resources.
  //       ad.dispose();
  //       print('Ad load failed (code=${error.code} message=${error.message})');
  //     },
  //     // Called when an ad opens an overlay that covers the screen.
  //     onAdOpened: (Ad ad) => print('Ad opened.'),
  //     // Called when an ad removes an overlay that covers the screen.
  //     onAdClosed: (Ad ad) => print('Ad closed.'),
  //     // Called when an impression occurs on the ad.
  //     onAdImpression: (Ad ad) => print('Ad impression.'),
  //     // Called when a click is recorded for a NativeAd.
  //     onAdClicked: (Ad ad) => print('Ad clicked.'),
  //   ),
  // );

  // // create a banner ad
  // void _createBannerAd() {
  //   _bannerAd = BannerAd(
  //     adUnitId: AdHelper.bannerAdUnitId,
  //     size: AdSize.banner,
  //     request: const AdRequest(),
  //     listener: const BannerAdListener(),
  //   )..load();
  // }

  final FlutterLocalNotificationsPlugin notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // dont show back button
        automaticallyImplyLeading: false,
        title: Container(
          child: Image.asset(
            "assets/freecycle.png",
            width: 40,
            height: 40,
          ),
        ),
        backgroundColor: Colors.black,
        actions: [
          // show notification page
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NotificationPage(),
                ),
              );
            },
            icon: const Icon(Icons.keyboard_arrow_up,
                color: Colors.white, size: 40),
          ),
          // if there is a new message, show a red dot
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => IncomingMessagesPage(
                          currentUserUid: user.uid,
                        )),
              );
            },
            icon: const Icon(Icons.mail),
          ),
          // sign out user
          IconButton(
            onPressed: () async {
              try {
                await FirebaseAuth.instance.signOut();
                if (mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (context) => const LoginScreen(),
                    ),
                    (route) => false,
                  );
                }
              } catch (e) {
                print('Error signing out: $e');
              }
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: // show user following post
          RefreshIndicator(
        onRefresh: _refresh,
        child: // check if the following list is empty, is emoty show text else show
            // following post
            following.isEmpty
                // show most liked posts
                ? StreamBuilder(
                    stream: // most liked posts
                        FirebaseFirestore.instance
                            .collection("posts")
                            .orderBy("likes", descending: true)
                            .snapshots(),
                    builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                      if (snapshot.hasError) {
                        return const Center(
                          child: Text("Something went wrong"),
                        );
                      }
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      }
                      if (snapshot.data!.docs.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.only(top: 15.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text("No posts yet. Try following someone!"),
                            ],
                          ),
                        );
                      }

                      // show native ad in the middle of the list with listview builder
                      return ListView.builder(
                        itemCount: snapshot.data!.docs.length,
                        itemBuilder: (context, index) {
                          currenAdCount++;
                          if (currenAdCount % adIndex == 0 && isAdLoaded) {
                            return Column(
                              children: [
                                PostCard(
                                  isBlocked: false,
                                  isGridView: false,
                                  snap: snapshot.data!.docs[index],
                                ),
                                Container(
                                  height: 55.0,
                                  alignment: Alignment.center,
                                  child: AdWidget(ad: _nativeAd!),
                                ),
                              ],
                            );
                          } else {
                            return PostCard(
                              isBlocked: false,
                              isGridView: false,
                              snap: snapshot.data!.docs[index],
                            );
                          }
                        },
                      );
                    },
                  )
                : StreamBuilder(
                    stream: FirebaseFirestore.instance
                        .collection("posts")
                        .where("uid", whereIn: following)
                        .orderBy('datePublished', descending: true)
                        .snapshots(),
                    builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                      if (following.isNotEmpty) {
                        // ...
                        return ListView.builder(
                          itemCount: snapshot.data!.docs.length,
                          itemBuilder: (context, index) {
                            currenAdCount++;
                            if (currenAdCount % adIndex == 0 && isAdLoaded) {
                              return Column(
                                children: [
                                  PostCard(
                                    isBlocked: false,
                                    isGridView: false,
                                    snap: snapshot.data!.docs[index],
                                  ),
                                  Container(
                                    height: 55.0,
                                    alignment: Alignment.center,
                                    child: AdWidget(ad: _nativeAd!),
                                  ),
                                ],
                              );
                            } else {
                              return PostCard(
                                isBlocked: false,
                                isGridView: false,
                                snap: snapshot.data!.docs[index],
                              );
                            }
                          },
                        );
                      } else {
                        return const Center(
                          child: Text("Not following anyone yet"),
                        );
                      }
                    },
                  ),
      ),
    );
  }

  // if post does not exist, remove the postID from the user's post list and remove the post
  // from the posts collection
  void _checkPostExist(String postID) {
    FirebaseFirestore.instance
        .collection("posts")
        .doc(postID)
        .get()
        .then((value) {
      if (!value.exists) {
        FirebaseFirestore.instance.collection("users").doc(user.uid).update({
          "posts": FieldValue.arrayRemove([postID])
        });
        FirebaseFirestore.instance.collection("posts").doc(postID).delete();
      }
    });
  }

  Future<void> _refresh() async {
    setState(() {});
    await Future.delayed(
      const Duration(seconds: 2),
    );
  }
}

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:Freecycle/screens/profile_screen2.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../resources/firestore_methods.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({Key? key}) : super(key: key);

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _searchTerm = '';
  NativeAd? _nativeAd;
  bool isAdLoaded = false;
  // current user uid
  final String uid = FirebaseFirestore.instance.collection('users').doc().id;
  final String userId = FirebaseFirestore.instance.collection('users').doc().id;

  void _loadNativeAd() {
    _nativeAd = NativeAd(
      adUnitId: 'ca-app-pub-8445989958080180/5829790999',
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

  // init state
  @override
  void initState() {
    super.initState();
    _loadNativeAd();
  }

  // dispose
  @override
  void dispose() {
    super.dispose();
    _nativeAd!.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0.4,
        shadowColor: Colors.grey,
        backgroundColor: Colors.black,
        title: TextField(
          style: const TextStyle(fontSize: 15),
          controller: _searchController,
          focusNode: _searchFocusNode,
          decoration: const InputDecoration(
            border: InputBorder.none,
            hintText: 'Search users by username',
          ),
          onChanged: (value) {
            setState(() {
              _searchTerm = value;
            });
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Expanded(
              child: StreamBuilder(
                stream: _searchTerm.isEmpty
                    ? null
                    : FirebaseFirestore.instance
                        .collection("users")
                        .orderBy('username')
                        .startAt([_searchTerm]).endAt(
                            ['$_searchTerm\uf8ff']).snapshots(),
                builder: (context,
                    AsyncSnapshot<QuerySnapshot<Map<String, dynamic>>>
                        snapshot) {
                  if (_searchTerm.isEmpty) {
                    return const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 30),
                        Text(
                          'Search for new users',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    );
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }
                  return ListView.builder(
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      final user = snapshot.data!.docs[index].data();
                      return Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: Row(
                          children: [
                            InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ProfileScreen2(
                                      uid: user['uid'],
                                      snap: null,
                                      userId: user['uid'],
                                    ),
                                  ),
                                );
                              },
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 27,
                                    backgroundImage: NetworkImage(
                                      user['photoUrl'],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(
                              width: 10,
                            ),
                            InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ProfileScreen2(
                                      uid: user['uid'],
                                      snap: null,
                                      userId: user['uid'],
                                    ),
                                  ),
                                );
                              },
                              child: Text(user['username'],
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  )),
                            ),
                            // message icon button
                            const Spacer(),
                            // if uid is not equal to current user uid
                            if (user['uid'] !=
                                FirebaseAuth.instance.currentUser!.uid)
                              TextButton(
                                style: TextButton.styleFrom(
                                  backgroundColor: Colors.grey[850],
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                                onPressed: () {
                                  if (user['followers'].contains(
                                      FirebaseAuth.instance.currentUser!.uid)) {
                                    // user is already being followed
                                    FireStoreMethods().unfollowUser(
                                      FirebaseAuth.instance.currentUser!.uid,
                                      user['uid'],
                                    );
                                  } else {
                                    // user is not being followed
                                    FireStoreMethods().followUser(
                                      FirebaseAuth.instance.currentUser!.uid,
                                      user['uid'],
                                    );
                                  }
                                },
                                child: Text(
                                  user['followers'].contains(FirebaseAuth
                                          .instance.currentUser!.uid)
                                      ? 'Following'
                                      : 'Follow',
                                  style: const TextStyle(
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            if (isAdLoaded)
              SizedBox(
                height: 55,
                child: AdWidget(ad: _nativeAd!),
              )
            else
              const SizedBox.shrink(),
          ],
        ),
      ),
    );
  }
}

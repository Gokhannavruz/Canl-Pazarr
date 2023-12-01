import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frees/screens/search_screen.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
// import math
import 'dart:math' as math;

import '../widgets/post_card.dart';

class DiscoverPage extends StatefulWidget {
  const DiscoverPage({Key? key}) : super(key: key);

  @override
  State<DiscoverPage> createState() => _DiscoverPageState();
}

class _DiscoverPageState extends State<DiscoverPage> {
  late bool _isShuffleActive = false;
  final bool _isGridView = false;
  BannerAd? _bannerAd;

  Stream<QuerySnapshot<Map<String, dynamic>>> stream = FirebaseFirestore
      .instance
      .collection("posts")
      .orderBy("random", descending: true)
      .snapshots();

  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    // create a banner ad
    _createBannerAd();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _randomizePosts() {
    setState(() {
      _isShuffleActive = !_isShuffleActive;
      // Generate a random number for each query
      double randomNumber = math.Random().nextDouble();
      // Update the stream to use a random order instead of ordering by likes
      stream = FirebaseFirestore.instance
          .collection("posts")
          .orderBy(randomNumber.toString(), descending: !_isShuffleActive)
          .snapshots();
    });
  }

  // create a banner ad
  void _createBannerAd() {
    _bannerAd = BannerAd(
      adUnitId: 'ca-app-pub-3940256099942544/6300978111',
      size: AdSize.banner,
      request: const AdRequest(),
      listener: const BannerAdListener(),
    )..load();
  }

  void _sortPostsByLikes() {
    setState(() {
      _isShuffleActive = !_isShuffleActive;
      // Update the stream to use a random order instead of ordering by likes
      stream = FirebaseFirestore.instance
          .collection("posts")
          .orderBy("likes", descending: !_isShuffleActive)
          .snapshots();
    });
  }

  Future<List<String>> retrieveBlockedUserIds() async {
    // Get the current user's ID
    final currentUser = FirebaseAuth.instance.currentUser;
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;
    if (currentUserId == null) {
      return [];
    }

    // Retrieve the document for the current user from the 'users' collection
    final currentUserDoc = await FirebaseFirestore.instance
        .collection("users")
        .doc(currentUserId)
        .get();

    // Get the list of blocked user IDs from the 'blocked' field in the current user's document
    final blockedUserIds = currentUserDoc.data()!['blocked'] as List<String>;

    return blockedUserIds;
  }

  @override
  Widget build(BuildContext context) {
    return NestedScrollView(
      physics: const BouncingScrollPhysics(),
      controller: _scrollController,
      headerSliverBuilder: (context, innerBoxIsScrolled) {
        return [
          SliverAppBar(
            // change pinned background color
            pinned: true,

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
                            "Discover",
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
                            "Find new people and posts",
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 13,
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
              Padding(
                padding: const EdgeInsets.only(top: 24.0),
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
              Padding(
                padding: const EdgeInsets.only(top: 24.0),
                child: Tooltip(
                  textStyle: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                  ),
                  message:
                      _isShuffleActive ? "Sort by Likes" : "Randomize Posts",
                  child: IconButton(
                    onPressed: () {
                      _isShuffleActive
                          ? _sortPostsByLikes()
                          : _randomizePosts();
                    },
                    icon: _isShuffleActive
                        ? const Icon(Icons.sort)
                        : const Icon(Icons.shuffle),
                  ),
                ),
              ),
            ],
          ),
        ];
      },
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: StreamBuilder(
          stream: stream,
          builder: (context,
              AsyncSnapshot<QuerySnapshot<Map<String, dynamic>>> snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            return _isGridView
                ? GridView.count(
                    crossAxisCount: 2,
                    childAspectRatio: 1,
                    children: List.generate(
                        snapshot.data!.docs.length,
                        (index) => PostCard(
                              snap: snapshot.data!.docs[index].data(),
                              isGridView: false,
                              isBlocked: false,
                            )),
                  )
                : // show ad every 5 posts if banner not null
                ListView.builder(
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      if (index % 5 == 0 && _bannerAd != null) {
                        return Column(
                          children: [
                            PostCard(
                              snap: snapshot.data!.docs[index].data(),
                              isGridView: false,
                              isBlocked: false,
                            ),
                            SizedBox(
                              height: // ad height
                                  _bannerAd!.size.height.toDouble(),
                              width: double.infinity,
                              child: AdWidget(ad: _bannerAd!),
                            )
                          ],
                        );
                      } else {
                        return PostCard(
                          snap: snapshot.data!.docs[index].data(),
                          isGridView: false,
                          isBlocked: false,
                        );
                      }
                    },
                  );
          },
        ),
      ),
    );
  }

  Future<void> _refresh() async {
    setState(() {});
    await Future.delayed(
      const Duration(seconds: 2),
    );
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frees/screens/search_screen.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
// import math

import '../widgets/post_card.dart';

class DiscoverPage22 extends StatefulWidget {
  const DiscoverPage22({Key? key}) : super(key: key);

  @override
  State<DiscoverPage22> createState() => _DiscoverPage22State();
}

class _DiscoverPage22State extends State<DiscoverPage22> {
  late bool _isShuffleActive = false;
  BannerAd? _bannerAd;
  late final bool _isGridView = false;

  @override
  void initState() {
    super.initState();
    _createBannerAd();
  }

  @override
  void dispose() {
    super.dispose();
  }

  // create a banner ad
  void _createBannerAd() {
    _bannerAd = BannerAd(
      adUnitId: 'ca-app-pub-8445989958080180/9975137648',
      size: AdSize.banner,
      request: const AdRequest(),
      listener: const BannerAdListener(),
    )..load();
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
                child: IconButton(
                  onPressed: () {
                    setState(() {
                      _isShuffleActive = !_isShuffleActive;
                    });
                    _createBannerAd();
                  },
                  icon: _isShuffleActive
                      ? const Icon(Icons.sort)
                      : const Icon(Icons.shuffle),
                ),
              ),
            ],
          ),
        ];
      },
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: // if shuffle true then show posts from random users
            _isShuffleActive == true
                ? // show _likedByUsersWhoLikePostsLikedByCurrentUser posts if _likedByUsersWhoLikePostsLikedByCurrentUser is not empty
                _likedByUsersWhoLikePostsLikedByCurrentUser.isNotEmpty
                    ? StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('posts')
                            .where('uid',
                                whereIn:
                                    _likedByUsersWhoLikePostsLikedByCurrentUser)
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
                              child: CircularProgressIndicator(),
                            );
                          }

                          return ListView.builder(
                            physics: const BouncingScrollPhysics(),
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
                      )
                    : // show posts from random users
                    StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('posts')
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
                              child: CircularProgressIndicator(),
                            );
                          }

                          return ListView.builder(
                            physics: const BouncingScrollPhysics(),
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
                      )
                // if shuffle false then show posts from following users
                : StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('posts')
                        .orderBy('likes', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
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

                      return ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        itemCount: snapshot.data!.docs.length,
                        itemBuilder: (context, index) {
                          DocumentSnapshot data = snapshot.data!.docs[index];
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
    );
  }

  Future<void> _refresh() async {
    setState(() {});
    await Future.delayed(
      const Duration(seconds: 2),
    );
  }

  //  create a list for Posts liked by users who like posts the current user likes
  final List<String> _likedByUsersWhoLikePostsLikedByCurrentUser = [];
  // add to list posts liked by users who like posts the current user likes
  void _addToLikedByUsersWhoLikePostsLikedByCurrentUser(String postId) {
    FirebaseFirestore.instance
        .collection('posts')
        .doc(postId)
        .collection('likes')
        .get()
        .then((value) {
      for (var element in value.docs) {
        FirebaseFirestore.instance
            .collection('posts')
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

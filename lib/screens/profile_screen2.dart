import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:freecycle/resources/auth_methods.dart';
import 'package:freecycle/resources/firestore_methods.dart';
import 'package:freecycle/screens/bio_and_profil.dart';
import 'package:freecycle/screens/credit_page.dart';
import 'package:freecycle/screens/following_Page.dart';
import 'package:freecycle/screens/login_screen.dart';
import 'package:freecycle/screens/post_screen.dart';
import 'package:freecycle/screens/settings.dart';
import 'package:freecycle/utils/colors.dart';
import 'package:freecycle/utils/utils.dart';
import '../widgets/follow_button.dart';
import '../widgets/post_card.dart';
import 'followers_list_page.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class ProfileScreen2 extends StatefulWidget {
  final String uid;
  const ProfileScreen2(
      {Key? key, required this.uid, required snap, required userId})
      : super(key: key);

  @override
  ProfileScreen2State createState() => ProfileScreen2State();
}

class ProfileScreen2State extends State<ProfileScreen2>
    with SingleTickerProviderStateMixin {
  final user = FirebaseAuth.instance.currentUser!;
  late bool _isGridView = false;
  final PageController _pageController = PageController(initialPage: 0);
  late TabController _tabController;

  var userData = {};
  int postLen = 0;
  int followers = 0;
  int following = 0;
  bool isFollowing = false;
  bool isLoading = false;
  bool isBlocked = false;
  String sendingRate = '0';
  int matches = 0;
  NativeAd? _nativeAd;

  int sentGifts = 0;
  double giftPoint = 0;
  int rateCount = 0;
  double ratePoint = 0;
  bool isAdLoaded = false;
  NativeAd? _nativeAd2;
  int adIndex = 4;
  int currenAdCount = 0;
  @override
  void initState() {
    super.initState();
    getData();
    _tabController = TabController(
      length: 2,
      vsync: this,
      animationDuration: const Duration(milliseconds: 200),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  getData() async {
    setState(() {
      isLoading = true;
    });
    try {
      var userSnap = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.uid)
          .get();

      if (!userSnap.exists) {
        throw 'User data not found';
      }

      var postSnap = await FirebaseFirestore.instance
          .collection('posts')
          .where('uid', isEqualTo: widget.uid)
          .get();

      postLen = postSnap.docs.length;
      userData = userSnap.data()!;

      followers = userData['followers']?.length ?? 0;
      following = userData['following']?.length ?? 0;

      isBlocked = (userData['blocked'] != null &&
              userData['blocked']
                  .contains(FirebaseAuth.instance.currentUser!.uid)) ||
          (userData['blockedBy'] != null &&
              userData['blockedBy']
                  .contains(FirebaseAuth.instance.currentUser!.uid));

      isFollowing = userData['followers']
              ?.contains(FirebaseAuth.instance.currentUser!.uid) ??
          false;

      setState(() {});
    } catch (e) {
      if (mounted) {
        showSnackBar(context, 'Error loading profile data');
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const LoginScreen(),
          ),
        );
      }
    }

    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;
    return isLoading
        ? const Center(
            child: CircularProgressIndicator(
              color: Colors.white,
            ),
          )
        : Scaffold(
            backgroundColor: Colors.black,
            appBar: AppBar(
              elevation: 0,
              automaticallyImplyLeading: false,
              backgroundColor: Colors.transparent,
              leading: widget.uid != currentUserId
                  ? IconButton(
                      icon: const Icon(
                        Icons.arrow_back_ios_new,
                        color: Colors.white,
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    )
                  : IconButton(
                      icon: const Icon(
                        Icons.edit_outlined,
                        color: Colors.white,
                        size: 28,
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EditProfileScreen(
                              userId: currentUserId,
                            ),
                          ),
                        );
                      },
                    ),
              titleSpacing: 0,
              centerTitle: true,
              title: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(widget.uid)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData || !snapshot.data!.exists) {
                    return const SizedBox();
                  }

                  final data = snapshot.data!.data()!;
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          data['username'],
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (data['is_premium'] == true)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF36B37E).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.verified,
                            size: 16,
                            color: Color(0xFF36B37E),
                          ),
                        ),
                    ],
                  );
                },
              ),
              actions: [
                widget.uid == currentUserId
                    ? IconButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const SettingsPage(),
                            ),
                          );
                        },
                        icon: const Icon(
                          Icons.settings_outlined,
                          color: Colors.white,
                          size: 28,
                        ),
                      )
                    : PopupMenuButton<String>(
                        color: Colors.grey[900],
                        icon: const Icon(
                          Icons.more_vert,
                          color: Colors.white,
                        ),
                        onSelected: (value) async {
                          if (value == 'block') {
                            final BuildContext outerContext = context;

                            final shouldBlock = await showDialog<bool>(
                                  context: context,
                                  builder: (dialogContext) => AlertDialog(
                                    backgroundColor: Color(0xFF222222),
                                    title: Text(
                                      'Block User',
                                      style: GoogleFonts.poppins(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    content: Text(
                                      'Are you sure you want to block this user? You will no longer see their posts and they will not be able to see yours.',
                                      style: GoogleFonts.poppins(
                                        color: Colors.white.withOpacity(0.8),
                                      ),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(dialogContext, false),
                                        child: Text(
                                          'Cancel',
                                          style: GoogleFonts.poppins(
                                            color:
                                                Colors.white.withOpacity(0.7),
                                          ),
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(dialogContext, true),
                                        child: Text(
                                          'Block',
                                          style: GoogleFonts.poppins(
                                            color: Colors.red,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ) ??
                                false;

                            if (shouldBlock) {
                              Navigator.of(outerContext).pop();

                              FireStoreMethods()
                                  .blockUser(
                                FirebaseAuth.instance.currentUser!.uid,
                                userData['uid'],
                              )
                                  .catchError((e) {
                                print("Error blocking user: $e");
                              });
                            }
                          } else if (value == 'report') {
                            final BuildContext outerContext = context;

                            final shouldReport = await showDialog<bool>(
                                  context: context,
                                  builder: (dialogContext) => AlertDialog(
                                    backgroundColor: Color(0xFF222222),
                                    title: Text(
                                      'Report User',
                                      style: GoogleFonts.poppins(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    content: Text(
                                      'Are you sure you want to report this user? Our team will review this account.',
                                      style: GoogleFonts.poppins(
                                        color: Colors.white.withOpacity(0.8),
                                      ),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(dialogContext, false),
                                        child: Text(
                                          'Cancel',
                                          style: GoogleFonts.poppins(
                                            color:
                                                Colors.white.withOpacity(0.7),
                                          ),
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(dialogContext, true),
                                        child: Text(
                                          'Report',
                                          style: GoogleFonts.poppins(
                                            color: Colors.red,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ) ??
                                false;

                            if (shouldReport) {
                              if (mounted) {
                                ScaffoldMessenger.of(outerContext).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'User reported successfully',
                                      style: GoogleFonts.poppins(),
                                    ),
                                    backgroundColor: Colors.orange,
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              }

                              FireStoreMethods()
                                  .reportUser(
                                FirebaseAuth.instance.currentUser!.uid,
                                userData['uid'],
                              )
                                  .catchError((e) {
                                print("Error reporting user: $e");
                              });
                            }
                          }
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem<String>(
                            value: 'block',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.block,
                                  color: Colors.red[300],
                                  size: 20,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  'Block User',
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          PopupMenuItem<String>(
                            value: 'report',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.report_problem,
                                  color: Colors.orange[300],
                                  size: 20,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  'Report User',
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
              ],
            ),
            body: RefreshIndicator(
              color: Colors.white,
              onRefresh: _refresh,
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Column(
                      children: [
                        const SizedBox(height: 20),
                        // Profile Image
                        StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                          stream: FirebaseFirestore.instance
                              .collection('users')
                              .doc(widget.uid)
                              .snapshots(),
                          builder: (context, snapshot) {
                            if (snapshot.hasData) {
                              return Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.2),
                                    width: 3,
                                  ),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(60),
                                  child: Image.network(
                                    snapshot.data!['photoUrl'],
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              );
                            }
                            return const SizedBox();
                          },
                        ),
                        const SizedBox(height: 24),

                        // Stats Row
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildStatItem(postLen, "Posts"),
                              Container(
                                height: 30,
                                width: 1,
                                color: Colors.white.withOpacity(0.2),
                              ),
                              GestureDetector(
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => FollowersListScreen(
                                          userId: widget.uid),
                                    ),
                                  );
                                },
                                child: _buildStatItem(followers, "Followers"),
                              ),
                              Container(
                                height: 30,
                                width: 1,
                                color: Colors.white.withOpacity(0.2),
                              ),
                              GestureDetector(
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => FollowingListScreen(
                                          userId: widget.uid),
                                    ),
                                  );
                                },
                                child: _buildStatItem(following, "Following"),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Bio
                        StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                          stream: FirebaseFirestore.instance
                              .collection('users')
                              .doc(widget.uid)
                              .snapshots(),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData || !snapshot.data!.exists) {
                              return const SizedBox();
                            }

                            final data = snapshot.data!.data() ?? {};
                            return Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 24),
                              child: Text(
                                data['bio'] ?? '',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  color: Colors.white.withOpacity(0.8),
                                ),
                                textAlign: TextAlign.center,
                              ),
                            );
                          },
                        ),

                        const SizedBox(height: 24),

                        // Action Buttons
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Row(
                            children: [
                              if (FirebaseAuth.instance.currentUser!.uid ==
                                  widget.uid)
                                Expanded(
                                  child: _buildActionButton(
                                    'Sign Out',
                                    Icons.logout,
                                    () async {
                                      await AuthMethods().signOut();
                                      Navigator.of(context).pushAndRemoveUntil(
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const LoginScreen(),
                                        ),
                                        (Route<dynamic> route) => false,
                                      );
                                    },
                                  ),
                                )
                              else if (isBlocked)
                                Expanded(
                                  child: _buildActionButton(
                                    'Unblock',
                                    Icons.block_outlined,
                                    () async {
                                      await FireStoreMethods().unblockUser(
                                        FirebaseAuth.instance.currentUser!.uid,
                                        userData['uid'],
                                      );
                                      setState(() {
                                        isBlocked = false;
                                      });
                                    },
                                  ),
                                )
                              else
                                Expanded(
                                  child: _buildActionButton(
                                    isFollowing ? 'Unfollow' : 'Follow',
                                    isFollowing
                                        ? Icons.person_remove
                                        : Icons.person_add,
                                    () async {
                                      if (isFollowing) {
                                        await FireStoreMethods().unfollowUser(
                                          FirebaseAuth
                                              .instance.currentUser!.uid,
                                          userData['uid'],
                                        );
                                        setState(() {
                                          isFollowing = false;
                                          followers--;
                                        });
                                      } else {
                                        await FireStoreMethods().followUser(
                                          FirebaseAuth
                                              .instance.currentUser!.uid,
                                          userData['uid'],
                                        );
                                        setState(() {
                                          isFollowing = true;
                                          followers++;
                                        });
                                      }
                                    },
                                  ),
                                ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Posts Section
                        if (postLen > 0)
                          TabBar(
                            controller: _tabController,
                            indicatorColor: Colors.white,
                            labelColor: Colors.white,
                            unselectedLabelColor: Colors.white.withOpacity(0.7),
                            tabs: const [
                              Tab(icon: Icon(Icons.grid_on_outlined)),
                              Tab(icon: Icon(Icons.list_outlined)),
                            ],
                          ),
                      ],
                    ),
                  ),
                  if (postLen == 0)
                    SliverToBoxAdapter(
                      child: Column(
                        children: [
                          const SizedBox(height: 48),
                          Icon(
                            Icons.photo_camera_outlined,
                            size: 64,
                            color: Colors.white.withOpacity(0.4),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            FirebaseAuth.instance.currentUser!.uid == widget.uid
                                ? 'You have no posts yet'
                                : '${userData['username']} has no posts yet',
                            style: GoogleFonts.poppins(
                              color: Colors.white.withOpacity(0.6),
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    SliverToBoxAdapter(
                      child: SizedBox(
                        height: MediaQuery.of(context).size.height * 0.7,
                        child: TabBarView(
                          controller: _tabController,
                          physics: const ClampingScrollPhysics(),
                          children: [
                            // Grid View
                            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                              stream: FirebaseFirestore.instance
                                  .collection('posts')
                                  .where('uid', isEqualTo: widget.uid)
                                  .orderBy('datePublished', descending: true)
                                  .snapshots(),
                              builder: (context, snapshot) {
                                if (!snapshot.hasData) {
                                  return const Center(
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                    ),
                                  );
                                }

                                return GridView.builder(
                                  physics: const BouncingScrollPhysics(),
                                  padding: const EdgeInsets.all(2),
                                  gridDelegate:
                                      const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 3,
                                    crossAxisSpacing: 2,
                                    mainAxisSpacing: 2,
                                  ),
                                  itemCount: snapshot.data!.docs.length,
                                  itemBuilder: (context, index) {
                                    return GestureDetector(
                                      onTap: () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (context) => PostScreen(
                                              postId:
                                                  snapshot.data!.docs[index].id,
                                              uid: widget.uid,
                                            ),
                                          ),
                                        );
                                      },
                                      child: Container(
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          image: DecorationImage(
                                            image: NetworkImage(
                                              snapshot.data!.docs[index]
                                                  ['postUrl'],
                                            ),
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),

                            // List View
                            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                              stream: FirebaseFirestore.instance
                                  .collection('posts')
                                  .where('uid', isEqualTo: widget.uid)
                                  .orderBy('datePublished', descending: true)
                                  .snapshots(),
                              builder: (context, snapshot) {
                                if (!snapshot.hasData) {
                                  return const Center(
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                    ),
                                  );
                                }

                                return ListView.builder(
                                  physics: const BouncingScrollPhysics(),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16),
                                  itemCount: snapshot.data!.docs.length,
                                  itemBuilder: (context, index) {
                                    return Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 16),
                                      child: PostCard(
                                        snap: snapshot.data!.docs[index],
                                        isBlocked: false,
                                        isGridView: false,
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
  }

  Widget _buildStatItem(int value, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value.toString(),
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: Colors.white.withOpacity(0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(
      String text, IconData icon, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: text == 'Follow' ? Colors.blue : Colors.transparent,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: text == 'Follow'
                ? Colors.transparent
                : Colors.white.withOpacity(0.2),
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20, color: Colors.white),
          const SizedBox(width: 8),
          Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _refresh() async {
    setState(() {});
    await Future.delayed(const Duration(seconds: 1));
  }
}

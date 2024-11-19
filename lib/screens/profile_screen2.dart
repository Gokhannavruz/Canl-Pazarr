import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:Freecycle/resources/auth_methods.dart';
import 'package:Freecycle/resources/firestore_methods.dart';
import 'package:Freecycle/screens/bio_and_profil.dart';
import 'package:Freecycle/screens/credit_page.dart';
import 'package:Freecycle/screens/following_Page.dart';
import 'package:Freecycle/screens/login_screen.dart';
import 'package:Freecycle/screens/post_screen.dart';
import 'package:Freecycle/screens/settings.dart';
import 'package:Freecycle/utils/colors.dart';
import 'package:Freecycle/utils/utils.dart';
import '../widgets/follow_button.dart';
import '../widgets/post_card.dart';
import 'followers_list_page.dart';

class ProfileScreen2 extends StatefulWidget {
  final String uid;
  const ProfileScreen2(
      {Key? key, required this.uid, required snap, required userId})
      : super(key: key);

  @override
  ProfileScreen2State createState() => ProfileScreen2State();
}

class ProfileScreen2State extends State<ProfileScreen2> {
  final user = FirebaseAuth.instance.currentUser!;
  late bool _isGridView = false;
  final PageController _pageController = PageController(initialPage: 0);

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
    /* _loadNativeAd(); */
  }

  @override
  void dispose() {
    super.dispose();
    // _nativeAd2!.dispose();
    // _loadNativeAd();
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

      // get post lENGTH
      var postSnap = await FirebaseFirestore.instance
          .collection('posts')
          .where('uid', isEqualTo: widget.uid)
          .get();

      postLen = postSnap.docs.length;
      userData = userSnap.data()!;

      if (userData['followers'] != null) {
        followers = userData['followers'].length;
      } else {
        followers = 0;
      }

      if (userData['blocked'] != null &&
          userData['blocked']
              .contains(FirebaseAuth.instance.currentUser!.uid)) {
        isBlocked = true;
      } else {
        isBlocked = false;
      }

      if (userData['following'] != null) {
        following = userData['following'].length;
      } else {
        following = 0;
      }
      isFollowing = userSnap
          .data()!['followers']
          .contains(FirebaseAuth.instance.currentUser!.uid);

      if (userData['blockedBy'] != null) {
        isBlocked = userData['blockedBy']
            .contains(FirebaseAuth.instance.currentUser!.uid);
      } else {
        isBlocked = false;
      }
      setState(() {});
    } catch (e) {
      showSnackBar(
        context,
        e.toString(),
      );
    }
    setState(() {
      isLoading = false;
    });
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
            appBar: AppBar(
              automaticallyImplyLeading:
                  widget.uid == currentUserId ? false : false, // false
              backgroundColor: mobileBackgroundColor,
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // show edit button if your profile else show back button
                  widget.uid == currentUserId
                      ? Row(
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.edit_attributes,
                                color: Colors.white,
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
                          ],
                        )
                      : IconButton(
                          icon: const Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                          ),
                          onPressed: () {
                            Navigator.pop(context);
                          },
                        ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // when profile changes, it will update
                      StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                        stream: FirebaseFirestore.instance
                            .collection('users')
                            .doc(widget.uid)
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.hasData) {
                            return Row(
                              // space between
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Text(
                                  snapshot.data!['username'],
                                  style: const TextStyle(
                                    color: Color.fromARGB(255, 255, 255, 255),
                                    fontSize: 17,
                                  ),
                                ),
                                const SizedBox(width: 3),
                                // if sent gifts / match count == %90 show verified icon
                                snapshot.data!['match_count'] != null &&
                                        snapshot.data![
                                                'number_of_sent_gifts'] !=
                                            null &&
                                        snapshot.data!['match_count'] != 0 &&
                                        snapshot.data![
                                                'number_of_sent_gifts'] !=
                                            0 &&
                                        snapshot.data!['number_of_sent_gifts'] /
                                                snapshot.data!['match_count'] >=
                                            0.9
                                    ? Padding(
                                        padding: const EdgeInsets.only(top: 4),
                                        child: InkWell(
                                          child: const Icon(
                                            Icons.verified,
                                            size: 15,
                                            color: Colors.blue,
                                          ),
                                          // show verified user info if clicked
                                          onTap: () {
                                            // show bottom sheet verified user info if clicked
                                            showModalBottomSheet(
                                              context: context,
                                              builder: (context) {
                                                return Container(
                                                  decoration:
                                                      const BoxDecoration(
                                                    color: Color.fromARGB(
                                                        255, 0, 0, 0),
                                                    borderRadius:
                                                        BorderRadius.only(
                                                      topLeft:
                                                          Radius.circular(20),
                                                      topRight:
                                                          Radius.circular(20),
                                                    ),
                                                  ),
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 20),
                                                  height: 100,
                                                  child: const Column(
                                                    children: [
                                                      SizedBox(
                                                        height: 10,
                                                      ),
                                                      Row(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .start,
                                                        children: [
                                                          Text(
                                                            'Verified User',
                                                            style: TextStyle(
                                                              fontSize: 17,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                            ),
                                                          ),
                                                          SizedBox(
                                                            width: 5,
                                                          ),
                                                          Padding(
                                                              padding: EdgeInsets
                                                                  .only(top: 2),
                                                              child: InkWell(
                                                                child: Icon(
                                                                  Icons
                                                                      .verified,
                                                                  size: 18,
                                                                  color: Colors
                                                                      .blue,
                                                                ),
                                                              ))
                                                        ],
                                                      ),
                                                      SizedBox(
                                                        height: 10,
                                                      ),
                                                      Text(
                                                        'This user has been verified by our system, which means that they have a sending rate of over 90%',
                                                        textAlign:
                                                            TextAlign.center,
                                                        style: TextStyle(
                                                          fontSize: 15,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                );
                                              },
                                            );
                                          },
                                        ),
                                      )
                                    : const SizedBox(),
                              ],
                            );
                          } else {
                            return Container();
                          }
                        },
                      ),
                    ],
                  ),
                  // dont show edit profile button if not your profile
                  if (FirebaseAuth.instance.currentUser!.uid == widget.uid)
                    IconButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const SettingsPage(),
                          ),
                        );
                      },
                      icon: const Icon(
                        Icons.menu,
                        color: Color.fromARGB(255, 188, 180, 180),
                      ),
                    ),
                  // show options if not your profile
                  if (FirebaseAuth.instance.currentUser!.uid != widget.uid)
                    PopupMenuButton(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      splashRadius: 0.1,
                      onSelected: (value) {
                        if (value == 1) {
                          // block user, if blocked user dont show block option
                          if (isBlocked) {
                            showSnackBar(
                              context,
                              'User already blocked',
                            );
                          } else {
                            FirebaseFirestore.instance
                                .collection('users')
                                .doc(widget.uid)
                                .update({
                              'blockedBy': FieldValue.arrayUnion(
                                [currentUserId],
                              ),
                            });
                            FirebaseFirestore.instance
                                .collection('users')
                                .doc(currentUserId)
                                .update({
                              'blocked': FieldValue.arrayUnion(
                                [widget.uid],
                              ),
                            });
                            setState(() {
                              isBlocked = true;
                            });
                            showSnackBar(
                              context,
                              'User blocked',
                            );
                          }
                        } else if (value == 2) {
                          //
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 1,
                          child: Text('Block'),
                        ),
                        const PopupMenuItem(
                          value: 2,
                          child: Text('Report'),
                        ),
                      ],
                    ),
                ],
              ),
              centerTitle: false,
            ),
            body: RefreshIndicator(
              color: Colors.white,
              onRefresh: _refresh,
              child: ListView(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 16, right: 16, top: 5),
                    child: Column(
                      children: [
                        // user profile with future builder to get user profile
                        StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                          stream: FirebaseFirestore.instance
                              .collection('users')
                              .doc(widget.uid)
                              .snapshots(),
                          builder: (context, snapshot) {
                            if (snapshot.hasData) {
                              return CircleAvatar(
                                radius: 80,
                                backgroundColor: Colors.black,
                                backgroundImage: NetworkImage(
                                  snapshot.data!['photoUrl'],
                                ),
                              );
                            } else {
                              return const CircleAvatar(
                                radius: 80,
                                backgroundColor: Colors.black,
                              );
                            }
                          },
                        ),

                        const SizedBox(
                          height: 10,
                        ),
                        // show only if your profile

                        Row(
                          children: [
                            Expanded(
                              flex: 1,
                              child: Column(
                                children: [
                                  // show user credit count with stream builder
                                  if (FirebaseAuth.instance.currentUser!.uid ==
                                      widget.uid)
                                    StreamBuilder<
                                            DocumentSnapshot<
                                                Map<String, dynamic>>>(
                                        stream: FirebaseFirestore.instance
                                            .collection('users')
                                            .doc(widget.uid)
                                            .snapshots(),
                                        builder: (context, snapshot) {
                                          if (snapshot.hasData) {
                                            if (snapshot.data!['credit'] !=
                                                null) {
                                              return Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Text(
                                                    "Your credit: ${snapshot.data!['credit']}",
                                                    style: const TextStyle(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                  const SizedBox(
                                                    width: 2,
                                                  ),
                                                  const Icon(
                                                    // coin icon
                                                    Icons.monetization_on,
                                                    size: 18,
                                                    color: Colors.yellow,
                                                  ),
                                                ],
                                              );
                                            } else {
                                              return const SizedBox();
                                            }
                                          } else {
                                            return const SizedBox();
                                          }
                                        }),
                                  const SizedBox(
                                    height: 7,
                                  ),
                                  // earn more credit button
                                  if (FirebaseAuth.instance.currentUser!.uid ==
                                      widget.uid)
                                    ElevatedButton(
                                      onPressed: () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                const CreditPage(),
                                          ),
                                        );
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.blue,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal:
                                                5), // Adjust the horizontal padding
                                      ),
                                      child: const SizedBox(
                                        width:
                                            120, // Set a specific width for the button
                                        child: Center(
                                          child: Text(
                                            'Earn Free Credit',
                                            style: TextStyle(
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  const SizedBox(
                                    height: 10,
                                  ),
                                  Row(
                                    mainAxisSize: MainAxisSize.max,
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: [
                                      InkWell(
                                        onTap: () {
                                          Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  FollowersListScreen(
                                                      userId: widget.uid),
                                            ),
                                          );
                                        },
                                        child: buildStatColumn(
                                            followers, "followers"),
                                      ),
                                      InkWell(
                                        onTap: () {
                                          Navigator.of(context).push(
                                            MaterialPageRoute(
                                                builder: (context) =>
                                                    FollowingListScreen(
                                                        userId: widget.uid)),
                                          );
                                        },
                                        child: buildStatColumn(
                                            following, "following"),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      if (FirebaseAuth
                                              .instance.currentUser!.uid ==
                                          widget.uid)
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 35),
                                          child: FollowButton(
                                            size: // media query
                                                (MediaQuery.of(context)
                                                            .size
                                                            .width /
                                                        1 -
                                                    MediaQuery.of(context)
                                                            .size
                                                            .width /
                                                        3.1),
                                            text: 'Sign Out',
                                            backgroundColor:
                                                mobileBackgroundColor,
                                            textColor: primaryColor,
                                            borderColor: Colors.grey,
                                            function: () async {
                                              await AuthMethods().signOut();
                                              Navigator.of(context)
                                                  .pushAndRemoveUntil(
                                                MaterialPageRoute(
                                                    builder: (context) =>
                                                        const LoginScreen()),
                                                (Route<dynamic> route) =>
                                                    false, // Tüm sayfaları kaldır
                                              );
                                            },
                                          ),
                                        )
                                      else if (isBlocked)
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 39),
                                          child: FollowButton(
                                            size: // media query  size = horizontal padding
                                                (MediaQuery.of(context)
                                                            .size
                                                            .width /
                                                        1 -
                                                    MediaQuery.of(context)
                                                            .size
                                                            .width /
                                                        3.1),
                                            text: 'Unblock',
                                            backgroundColor: Colors.white,
                                            textColor: Colors.black,
                                            borderColor: Colors.grey,
                                            function: () async {
                                              await FireStoreMethods()
                                                  .unblockUser(
                                                      FirebaseAuth.instance
                                                          .currentUser!.uid,
                                                      userData['uid']);

                                              setState(() {
                                                isBlocked = false;
                                              });
                                            },
                                          ),
                                        )
                                      else if (isFollowing)
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(left: 42),
                                          child: FollowButton(
                                            size: // mobile width / 2 - 44 - 44 - 44
                                                (MediaQuery.of(context)
                                                            .size
                                                            .width /
                                                        1 -
                                                    MediaQuery.of(context)
                                                            .size
                                                            .width /
                                                        2.3),
                                            text: 'Unfollow',
                                            backgroundColor: Colors.white,
                                            textColor: Colors.black,
                                            borderColor: Colors.white,
                                            function: () async {
                                              await FireStoreMethods()
                                                  .unfollowUser(
                                                      FirebaseAuth.instance
                                                          .currentUser!.uid,
                                                      userData['uid']);

                                              setState(() {
                                                isFollowing = false;
                                                followers--;
                                              });
                                            },
                                          ),
                                        )
                                      else
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(left: 67),
                                          child: FollowButton(
                                            // responsive button
                                            size: // screen width / 2 - 44 - 44 - 44
                                                (MediaQuery.of(context)
                                                            .size
                                                            .width /
                                                        1 -
                                                    MediaQuery.of(context)
                                                            .size
                                                            .width /
                                                        2.3),
                                            text: 'Follow',
                                            backgroundColor: Colors.blue,
                                            textColor: Colors.white,
                                            borderColor: Colors.blue,
                                            function: () async {
                                              await FireStoreMethods()
                                                  .followUser(
                                                      FirebaseAuth.instance
                                                          .currentUser!.uid,
                                                      userData['uid']);

                                              setState(() {
                                                isFollowing = true;
                                                followers++;
                                              });
                                            },
                                          ),
                                        ),
                                      // show message button if not your profile and not blocked
                                      // if (FirebaseAuth
                                      //             .instance.currentUser!.uid !=
                                      //         widget.uid &&
                                      //     !isBlocked)
                                      //   IconButton(
                                      //     onPressed: () {
                                      //       // Navigator.of(context).push(
                                      //       //   MaterialPageRoute(
                                      //       //     builder: (context) =>
                                      //       //         MessagesPage(
                                      //       //             currentUserUid:
                                      //       //                 FirebaseAuth
                                      //       //                     .instance
                                      //       //                     .currentUser!
                                      //       //                     .uid,
                                      //       //             recipientUid:
                                      //       //                 widget.uid),
                                      //       //   ),
                                      //       // );
                                      //     },
                                      //     icon: const Icon(
                                      //       Icons.mail,
                                      //       color: Colors.white,
                                      //     ),
                                      //   ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        //bio with stream builder
                        StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                          stream: FirebaseFirestore.instance
                              .collection('users')
                              .doc(widget.uid)
                              .snapshots(),
                          builder: (context, snapshot) {
                            if (snapshot.hasData) {
                              return Column(
                                children: [
                                  Container(
                                    alignment: Alignment.centerLeft,
                                    padding: const EdgeInsets.only(
                                      top: 1,
                                      left: 15,
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.only(top: 6.0),
                                      child: Text(
                                        snapshot.data!['bio'],
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            } else {
                              return const SizedBox(
                                height: 0,
                              );
                            }
                          },
                        ),

                        // icon button for changing grid view
                      ],
                    ),
                  ),
                  //if post len is 0 show nothing else show grid view or list view
                  if (postLen != 0)
                    Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          IconButton(
                            onPressed: () {
                              setState(() {
                                _isGridView = !_isGridView;
                              });
                            },
                            icon: Icon(
                              _isGridView
                                  ? Icons.grid_view_rounded
                                  : Icons.notes_rounded,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  // if post len is 0 and if this is your profile show text else show username
                  if (postLen == 0)
                    const Padding(
                      padding: EdgeInsets.only(left: 20.0, right: 20),
                      child: Divider(
                        thickness: 0.2,
                        color: Color.fromARGB(255, 179, 167, 167),
                      ),
                    ),
                  if (postLen == 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 20),
                      child: Column(
                        children: [
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.photo_camera_outlined,
                                size: 50,
                                color: Color.fromARGB(255, 112, 107, 107),
                              ),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                FirebaseAuth.instance.currentUser!.uid ==
                                        widget.uid
                                    ? 'You have no posts yet'
                                    : '${userData['username']} has no posts yet',
                                style: const TextStyle(
                                  color: Color.fromARGB(255, 151, 143, 143),
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          /* SizedBox(
                            height: MediaQuery.of(context).size.height *
                                0.13, // Ekran yüksekliğinin %10'u kadar bir boşluk
                          ),
                          if (isAdLoaded)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 4.0),
                              child: SizedBox(
                                height: 55,
                                child: AdWidget(ad: _nativeAd!),
                              ),
                            )
                          else
                            const SizedBox.shrink(), */
                        ],
                      ),
                    ),
                  // show user's posts with stream builder
                  _isGridView
                      ? StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                          stream: FirebaseFirestore.instance
                              .collection('posts')
                              .where('uid', isEqualTo: widget.uid)
                              .orderBy('datePublished', descending: true)
                              .snapshots(),
                          builder: (context, snapshot) {
                            if (snapshot.hasData) {
                              return Padding(
                                padding: const EdgeInsets.all(4),
                                child: GridView.builder(
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
                                      child: Image.network(
                                        snapshot.data!.docs[index]['postUrl'],
                                        fit: BoxFit.cover,
                                      ),
                                    );
                                  },
                                ),
                              );
                            } else {
                              return const Center(
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                ),
                              );
                            }
                          },
                        )
                      : // show user's posts with stream builder with listview use postCard
                      StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                          stream: FirebaseFirestore.instance
                              .collection('posts')
                              .where('uid', isEqualTo: widget.uid)
                              .orderBy('datePublished', descending: true)
                              .snapshots(),
                          builder: (context, snapshot) {
                            if (snapshot.hasData) {
                              return ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: snapshot.data!.docs.length,
                                itemBuilder: (context, index) {
                                  return PostCard(
                                    snap: snapshot.data!.docs[index],
                                    isBlocked: false,
                                    isGridView: false,
                                  );
                                },
                              );
                            } else {
                              return const Center(
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                ),
                              );
                            }
                          },
                        ),
                ],
              ),
            ));
  }

  Column buildStatColumn(int num, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          num.toString(),
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        Container(
          margin: const EdgeInsets.only(top: 4),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: Colors.grey,
            ),
          ),
        ),
      ],
    );
  }

  Column buildStatColumn2(double num, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          children: [
            Text(
              num.toString(),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        Container(
          margin: const EdgeInsets.only(top: 4),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: Colors.grey,
            ),
          ),
        ),
      ],
    );
  }

  //if there is new info in the database, it will refresh the page
  Future<void> _refresh() async {
    setState(() {});
    await Future.delayed(
      const Duration(seconds: 1),
    );
  }
}

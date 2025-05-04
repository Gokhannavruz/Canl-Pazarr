import 'dart:io' if (dart.library.html) 'package:freecycle/utils/web_stub.dart'
    as io;
import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;

import 'package:freecycle/src/components/native_dialog.dart';
import 'package:freecycle/src/model/singletons_data.dart';
import 'package:freecycle/src/model/weather_data.dart';
import 'package:freecycle/src/rvncat_constant.dart';
import 'package:freecycle/src/views/paywall.dart';
import 'package:freecycle/src/views/paywallfirstlaunch.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import 'package:freecycle/models/user.dart' as model;
import 'package:freecycle/screens/credit_page.dart';
import 'package:freecycle/screens/message_screen.dart';
import 'package:freecycle/utils/colors.dart';
import 'package:freecycle/utils/utils.dart';
import 'package:freecycle/utils/styles/text_styles.dart';
import 'package:freecycle/widgets/like_animation.dart';
import 'package:purchases_flutter/models/customer_info_wrapper.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../providers/user_provider.dart';
import '../resources/firestore_methods.dart';
import '../screens/profile_screen2.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';

class PostCard extends StatefulWidget {
  final snap;
  final bool isGridView;
  final bool isBlocked;

  const PostCard({
    Key? key,
    required this.snap,
    required this.isGridView,
    required this.isBlocked,
  }) : super(key: key);

  @override
  State<PostCard> createState() => _PostCardState();
}

// save post to and create savedpost collection in user document

class _PostCardState extends State<PostCard> {
  bool isLikeAnimating = false;
  int commentLen = 0;
  late List<String> savedList;
  final currentUser = FirebaseAuth.instance.currentUser!.uid;
  late bool isRecipentExist = false;
  late String recipientUid;
  late String fcmToken;
  String country = "";
  String state = "";
  String city = "";
  late bool _isLoading;
  bool isWanted = false;
  // Beğeni durumunu yerel olarak takip etmek için
  List<dynamic> _likes = [];
  // Track premium status
  bool _isPremium = false;
  // Add page controller and current page for multi-image PageView
  final PageController _pageController = PageController();
  int _currentImageIndex = 0;
  // Flag to track if post has multiple images
  bool _hasMultipleImages = false;
  // List to store image URLs
  List<String> _imageUrls = [];

  // Stream subscriptions
  late StreamSubscription<DocumentSnapshot> _recipientSubscription;
  late StreamSubscription<DocumentSnapshot> _wantedSubscription;
  // Flags to track if subscriptions were initialized
  bool _subscriptionsInitialized = false;

  @override
  void initState() {
    super.initState();
    _isLoading = false;
    getPostLocation();
    savedList = [];
    getSavedList();
    getComments();
    // Initialize image URLs
    _initializeImageUrls();

    // Safely initialize likes - protect against null
    try {
      if (widget.snap != null && widget.snap['likes'] != null) {
        _likes = List.from(widget.snap['likes']);
      } else {
        _likes = [];
      }
    } catch (e) {
      print("Error initializing likes: $e");
      _likes = [];
    }

    // Check premium status
    _checkPremiumStatus();

    // initialize isRecipentExist if recipient is exist with stream builder
    try {
      if (widget.snap != null && widget.snap.id != null) {
        _recipientSubscription = FirebaseFirestore.instance
            .collection("posts")
            .doc(widget.snap.id)
            .snapshots()
            .listen((event) {
          if (!mounted) return;

          final data = event.data();
          if (data == null) return; // Eğer doküman silinmişse, null olabilir

          if (data["recipient"] != null && data["recipient"] != "") {
            setState(() {
              isRecipentExist = true;
              recipientUid = data["recipient"];
            });
          } else {
            setState(() {
              isRecipentExist = false;
            });
          }

          // Beğeni listesini güncel tut
          if (data["likes"] != null) {
            setState(() {
              _likes = List.from(data["likes"]);
            });
          }

          // Update image URLs if they change
          _updateImageUrls(data);
        });

        // initialize isWanted if isWanted is true set state true with stream builder
        _wantedSubscription = FirebaseFirestore.instance
            .collection("posts")
            .doc(widget.snap.id)
            .snapshots()
            .listen((event) {
          if (!mounted) return;

          final data = event.data();
          if (data == null) return; // Eğer doküman silinmişse, null olabilir

          if (data["isWanted"] == true) {
            setState(() {
              isWanted = true;
            });
          } else {
            setState(() {
              isWanted = false;
            });
          }

          // Beğeni listesini güncel tut
          if (data["likes"] != null) {
            setState(() {
              _likes = List.from(data["likes"]);
            });
          }
        });

        _subscriptionsInitialized = true;
      } else {
        print("Error: Missing ID in widget.snap");
        _subscriptionsInitialized = false;
      }
    } catch (e) {
      print("Error setting up subscriptions: $e");
      _subscriptionsInitialized = false;
    }
  }

  @override
  void dispose() {
    // Cancel all active streams and operations before setting mounted to false
    try {
      if (_subscriptionsInitialized) {
        _recipientSubscription.cancel();
        _wantedSubscription.cancel();
      }
      _pageController.dispose();
    } catch (e) {
      print("Error in dispose: $e");
    }

    // Do not try to access context-dependent resources like ScaffoldMessenger here
    super.dispose();
  }

  // get current post owner fcm token
  Future<void> getFcmToken() async {
    if (!mounted) return;

    try {
      DocumentSnapshot value = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.snap["uid"])
          .get();

      if (mounted && value.exists) {
        final data = value.data() as Map<String, dynamic>?;
        if (data != null && data.containsKey('fcmToken')) {
          fcmToken = data['fcmToken'] as String;
        }
      }
    } catch (e) {
      print("Error fetching FCM token: $e");
    }
  }

  // get post location from post document and save them to variables
  @override
  void getPostLocation() async {
    try {
      // Check if postId exists in widget.snap
      if (widget.snap == null || widget.snap["postId"] == null) {
        print("Error: Missing postId in widget.snap");
        return;
      }

      DocumentSnapshot postDoc = await FirebaseFirestore.instance
          .collection('posts')
          .doc(widget.snap["postId"])
          .get();

      if (!mounted) return;

      if (postDoc.exists) {
        final data = postDoc.data() as Map<String, dynamic>?;
        if (data == null) return;

        setState(() {
          country = data['country'] ?? '';
          state = data['state'] ?? '';
          city = data['city'] ?? '';
        });
      }
    } catch (e) {
      print("Error fetching post location: $e");
    }
  }

// Initialize the plugin
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  void savePost(BuildContext context, String postId) async {
    if (!mounted) return;

    var currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    String currentUserId = currentUser.uid;
    DocumentReference postRef = FirebaseFirestore.instance
        .collection("users")
        .doc(currentUserId)
        .collection("savedPosts")
        .doc(postId);

    if (savedList.contains(postId)) {
      // post zaten kaydedilmiş, dolayısıyla kaydedilenleri geri al
      try {
        await postRef.delete();
        if (mounted) {
          setState(() {
            savedList.remove(postId);
          });
          showSnackBar(
            context,
            "Unsaved",
          );
        }
      } catch (e) {
        if (mounted) {
          showSnackBar(
            context,
            e.toString(),
          );
        }
      }
    } else {
      // post kaydedilmemiş, dolayısıyla kaydet
      try {
        await postRef.set({
          "postId": postId,
        });
        if (mounted) {
          setState(() {
            savedList.add(postId);
          });
          showSnackBar(
            context,
            "Saved",
          );
        }
      } catch (e) {
        if (mounted) {
          showSnackBar(
            context,
            e.toString(),
          );
        }
      }
    }
  }

  Future<void> getSavedList() async {
    try {
      QuerySnapshot value = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser)
          .collection('savedPosts')
          .get();

      if (!mounted) return;

      if (value.docs.isNotEmpty) {
        setState(() {
          savedList = value.docs.map((doc) => doc.id).toList();
        });
      }
    } catch (e) {
      print("Error fetching saved list: $e");
    }
  }

  void getComments() async {
    try {
      QuerySnapshot snap = await FirebaseFirestore.instance
          .collection("posts")
          .doc(widget.snap["postId"])
          .collection("comments")
          .get();

      if (!mounted) return;

      setState(() {
        commentLen = snap.docs.length;
      });
    } catch (e) {
      if (!mounted) return;

      showSnackBar(
        context,
        e.toString(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final model.User? user = Provider.of<UserProvider>(context).getUser;
    var currentUser = FirebaseAuth.instance.currentUser;

    // If widget.snap is null or critical fields are missing, show a placeholder
    if (widget.snap == null ||
        widget.snap["postId"] == null ||
        widget.snap["uid"] == null) {
      return Container(
        color: mobileBackgroundColor,
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, color: Colors.grey, size: 48),
              SizedBox(height: 16),
              Text(
                "Post data is missing or corrupted",
                style: TextStyle(color: Colors.grey[400]),
              ),
            ],
          ),
        ),
      );
    }

    bool isSaved = savedList.contains(widget.snap["postId"]);
    String currentUserId = currentUser!.uid;
    return Container(
      color: mobileBackgroundColor,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 1),
            // child: Divider(
            //   color: Color.fromARGB(255, 78, 74, 74),
            //   thickness: 0.5,
            // ),
          ),
          // Header section
          Container(
            padding: const EdgeInsets.symmetric(
              vertical: 8,
            ).copyWith(right: 0),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        InkWell(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ProfileScreen2(
                                  uid: widget.snap["uid"],
                                  snap: user,
                                  userId: currentUserId),
                            ),
                          ),
                          child: Row(
                            children: [
                              // Kullanıcı profili ve kullanıcı adı ile ilgili StreamBuilder (değişmedi)
                              StreamBuilder(
                                stream: FirebaseFirestore.instance
                                    .collection("users")
                                    .doc(widget.snap["uid"])
                                    .snapshots(),
                                builder: (context, AsyncSnapshot snapshot) {
                                  if (snapshot.hasData) {
                                    return Row(
                                      children: [
                                        Container(
                                          margin:
                                              const EdgeInsets.only(left: 12),
                                          width: 42,
                                          height: 42,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color:
                                                  Colors.white.withOpacity(0.1),
                                              width: 1,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black
                                                    .withOpacity(0.2),
                                                blurRadius: 4,
                                                offset: Offset(0, 2),
                                              ),
                                            ],
                                            image: DecorationImage(
                                              image: NetworkImage(
                                                  snapshot.data["photoUrl"]),
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          snapshot.data["username"],
                                          style: PostCardTextStyles.username,
                                        ),
                                        // Premium badge for premium users
                                        if (snapshot.data["is_premium"] == true)
                                          Padding(
                                            padding: const EdgeInsets.only(
                                                left: 4, top: 2),
                                            child: InkWell(
                                              onTap: () {
                                                // Show premium info when badge is tapped
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
                                                              Radius.circular(
                                                                  24),
                                                          topRight:
                                                              Radius.circular(
                                                                  24),
                                                        ),
                                                      ),
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                        horizontal: 20,
                                                        vertical: 16,
                                                      ),
                                                      height: 110,
                                                      child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Row(
                                                            mainAxisAlignment:
                                                                MainAxisAlignment
                                                                    .start,
                                                            children: [
                                                              Text(
                                                                'Premium Member',
                                                                style:
                                                                    GoogleFonts
                                                                        .poppins(
                                                                  fontSize: 18,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                ),
                                                              ),
                                                              const SizedBox(
                                                                  width: 6),
                                                              const Padding(
                                                                padding: EdgeInsets
                                                                    .only(
                                                                        top: 2),
                                                                child: Icon(
                                                                  Icons
                                                                      .verified,
                                                                  size: 18,
                                                                  color: Color(
                                                                      0xFF36B37E),
                                                                ),
                                                              )
                                                            ],
                                                          ),
                                                          const SizedBox(
                                                              height: 10),
                                                          Text(
                                                            'This user is a premium member with access to exclusive features and benefits',
                                                            style: GoogleFonts
                                                                .poppins(
                                                              fontSize: 14,
                                                              color: Colors
                                                                  .white
                                                                  .withOpacity(
                                                                      0.8),
                                                              height: 1.4,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    );
                                                  },
                                                );
                                              },
                                              child: Container(
                                                padding: EdgeInsets.all(4),
                                                decoration: BoxDecoration(
                                                  color: Color(0xFF36B37E)
                                                      .withOpacity(0.1),
                                                  shape: BoxShape.circle,
                                                ),
                                                child: Icon(
                                                  Icons.verified,
                                                  size: 14,
                                                  color: Color(0xFF36B37E),
                                                ),
                                              ),
                                            ),
                                          ),
                                      ],
                                    );
                                  } else {
                                    return const SizedBox();
                                  }
                                },
                              ),
                              Container(
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 10),
                                width: 3,
                                height: 3,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.grey,
                                ),
                              ),
                              Expanded(
                                child: Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        city.isNotEmpty
                                            ? city
                                            : state.isNotEmpty
                                                ? state
                                                : country.isNotEmpty
                                                    ? country
                                                    : '',
                                        style: PostCardTextStyles.location,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ]),
                ),
                IconButton(
                  onPressed: () {
                    showModalBottomSheet(
                      isScrollControlled: true,
                      backgroundColor: PostCardDesign.menuItemBackground,
                      shape: RoundedRectangleBorder(
                        borderRadius: PostCardDesign.menuRadius,
                      ),
                      context: context,
                      builder: (context) => Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          borderRadius: PostCardDesign.menuRadius,
                          boxShadow: PostCardDesign.dialogShadow,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              width: 40,
                              height: 4,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(4),
                                color: Colors.grey.shade600,
                              ),
                            ),
                            if (currentUserId == widget.snap["uid"])
                              ListTile(
                                leading: Icon(
                                  Icons.delete_outline,
                                  color: Colors.red,
                                  size: 24,
                                ),
                                title: Text(
                                  "Delete Post",
                                  style: PostCardTextStyles.menuItemTitle,
                                ),
                                onTap: () async {
                                  showDialog(
                                    useRootNavigator: false,
                                    context: context,
                                    builder: (context) {
                                      return AlertDialog(
                                        backgroundColor:
                                            PostCardDesign.dialogBackground,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              PostCardDesign.dialogRadius,
                                          side: BorderSide(
                                            color: Colors.grey.withOpacity(0.2),
                                            width: 1,
                                          ),
                                        ),
                                        title: Row(
                                          children: [
                                            Icon(
                                              Icons.delete_outline,
                                              color: Colors.red,
                                              size: 24,
                                            ),
                                            SizedBox(width: 12),
                                            Text(
                                              "Delete Post",
                                              style: PostCardTextStyles
                                                  .dialogTitle,
                                            ),
                                          ],
                                        ),
                                        content: Text(
                                          "Are you sure you want to delete this post? This action cannot be undone.",
                                          style:
                                              PostCardTextStyles.dialogContent,
                                        ),
                                        contentPadding:
                                            PostCardDesign.dialogPadding,
                                        titlePadding: EdgeInsets.only(
                                            left: 24, right: 24, top: 24),
                                        actionsPadding: EdgeInsets.only(
                                            bottom: 16, right: 16),
                                        actions: [
                                          TextButton(
                                            onPressed: () {
                                              Navigator.of(context).pop();
                                            },
                                            child: Text(
                                              "Cancel",
                                              style: PostCardTextStyles
                                                  .dialogNeutralButton,
                                            ),
                                          ),
                                          TextButton(
                                            onPressed: () async {
                                              // Close the dialog first to provide immediate feedback
                                              Navigator.of(context).pop();

                                              // Close the bottom sheet next
                                              Navigator.of(context).pop();

                                              // Delete the post
                                              String res =
                                                  await FireStoreMethods()
                                                      .deletePost(widget
                                                          .snap['postId']);

                                              // Show success message
                                              if (res == "success" &&
                                                  context.mounted) {
                                                showSnackBar(context,
                                                    'Post deleted successfully');
                                              }
                                            },
                                            style: TextButton.styleFrom(
                                              backgroundColor: PostCardDesign
                                                  .deleteActionBackgroundColor,
                                              padding: EdgeInsets.symmetric(
                                                  horizontal: 16, vertical: 8),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    PostCardDesign.buttonRadius,
                                              ),
                                            ),
                                            child: Text(
                                              "Delete",
                                              style: PostCardTextStyles
                                                  .dialogNegativeButton,
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                },
                              ),
                            if (currentUserId != widget.snap["uid"])
                              ListTile(
                                leading: Icon(
                                  Icons.block,
                                  color: Colors.red.shade300,
                                  size: 24,
                                ),
                                title: Text(
                                  "Block User",
                                  style: PostCardTextStyles.menuItemTitle,
                                ),
                                onTap: () {
                                  // show a dialog to confirm block
                                  showDialog(
                                    barrierColor: Colors.black.withOpacity(0.5),
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      backgroundColor:
                                          PostCardDesign.dialogBackground,
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            PostCardDesign.dialogRadius,
                                        side: BorderSide(
                                          color: Colors.grey.withOpacity(0.2),
                                          width: 1,
                                        ),
                                      ),
                                      title: Row(
                                        children: [
                                          Icon(
                                            Icons.block,
                                            color: Colors.red.shade300,
                                            size: 24,
                                          ),
                                          SizedBox(width: 12),
                                          Text(
                                            "Block User",
                                            style:
                                                PostCardTextStyles.dialogTitle,
                                          ),
                                        ],
                                      ),
                                      content: Text(
                                        "Are you sure you want to block this user? You will no longer see their posts and they won't be able to message you.",
                                        style: PostCardTextStyles.dialogContent,
                                      ),
                                      contentPadding:
                                          PostCardDesign.dialogPadding,
                                      titlePadding: EdgeInsets.only(
                                          left: 24, right: 24, top: 24),
                                      actionsPadding: EdgeInsets.only(
                                          bottom: 16, right: 16),
                                      actions: [
                                        TextButton(
                                          onPressed: () {
                                            Navigator.pop(context);
                                          },
                                          child: Text(
                                            "Cancel",
                                            style: PostCardTextStyles
                                                .dialogNeutralButton,
                                          ),
                                        ),
                                        TextButton(
                                          onPressed: () async {
                                            // block the user
                                            await FireStoreMethods().blockUser(
                                              currentUserId,
                                              widget.snap["uid"],
                                            );
                                            // show a snackbar in the center of the screen
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              SnackBar(
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.all(
                                                    Radius.circular(10),
                                                  ),
                                                ),
                                                behavior:
                                                    SnackBarBehavior.floating,
                                                content: Text(
                                                  "User blocked",
                                                  style: GoogleFonts.poppins(
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                                backgroundColor: Colors
                                                    .red.shade800
                                                    .withOpacity(0.9),
                                                duration: Duration(seconds: 2),
                                              ),
                                            );
                                            // close the dialog
                                            Navigator.pop(context);
                                            // close the bottom sheet
                                            Navigator.pop(context);
                                          },
                                          style: TextButton.styleFrom(
                                            backgroundColor: PostCardDesign
                                                .deleteActionBackgroundColor,
                                            padding: EdgeInsets.symmetric(
                                                horizontal: 16, vertical: 8),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  PostCardDesign.buttonRadius,
                                            ),
                                          ),
                                          child: Text(
                                            "Block",
                                            style: PostCardTextStyles
                                                .dialogNegativeButton,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            if (currentUserId != widget.snap["uid"])
                              ListTile(
                                leading: Icon(
                                  Icons.visibility_off,
                                  color: Colors.amber.shade700,
                                  size: 24,
                                ),
                                title: Text(
                                  "Hide Post",
                                  style: PostCardTextStyles.menuItemTitle,
                                ),
                                onTap: () {
                                  // code to hide the post from the current user
                                  FireStoreMethods().dontShowPost(
                                    currentUserId,
                                    widget.snap["postId"],
                                  );
                                  // show a snackbar
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.all(
                                          Radius.circular(10),
                                        ),
                                      ),
                                      behavior: SnackBarBehavior.floating,
                                      content: Text(
                                        "Post hidden from your feed",
                                        style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      backgroundColor: Colors.amber.shade700
                                          .withOpacity(0.9),
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                  // close the bottom sheet
                                  Navigator.pop(context);
                                },
                              ),
                            if (currentUserId != widget.snap["uid"])
                              ListTile(
                                leading: Icon(
                                  Icons.report_outlined,
                                  color: Colors.orange,
                                  size: 24,
                                ),
                                title: Text(
                                  "Report Post",
                                  style: PostCardTextStyles.menuItemTitle,
                                ),
                                onTap: () {
                                  showDialog(
                                    barrierColor: Colors.black.withOpacity(0.5),
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      backgroundColor:
                                          PostCardDesign.dialogBackground,
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            PostCardDesign.dialogRadius,
                                        side: BorderSide(
                                          color: Colors.grey.withOpacity(0.2),
                                          width: 1,
                                        ),
                                      ),
                                      title: Row(
                                        children: [
                                          Icon(
                                            Icons.report_outlined,
                                            color: Colors.orange,
                                            size: 24,
                                          ),
                                          SizedBox(width: 12),
                                          Text(
                                            "Report Post",
                                            style:
                                                PostCardTextStyles.dialogTitle,
                                          ),
                                        ],
                                      ),
                                      content: Text(
                                        "Are you sure you want to report this post? Our team will review it for any community guidelines violations.",
                                        style: PostCardTextStyles.dialogContent,
                                      ),
                                      contentPadding:
                                          PostCardDesign.dialogPadding,
                                      titlePadding: EdgeInsets.only(
                                          left: 24, right: 24, top: 24),
                                      actionsPadding: EdgeInsets.only(
                                          bottom: 16, right: 16),
                                      actions: [
                                        TextButton(
                                          onPressed: () {
                                            Navigator.pop(context);
                                          },
                                          child: Text(
                                            "Cancel",
                                            style: PostCardTextStyles
                                                .dialogNeutralButton,
                                          ),
                                        ),
                                        TextButton(
                                          onPressed: () async {
                                            // code to report the user who posted the content
                                            FireStoreMethods().reportUser(
                                              currentUserId,
                                              widget.snap["uid"],
                                            );
                                            // show a snackbar in the center of the screen
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              SnackBar(
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.all(
                                                    Radius.circular(10),
                                                  ),
                                                ),
                                                behavior:
                                                    SnackBarBehavior.floating,
                                                content: Text(
                                                  "Post reported successfully",
                                                  style: GoogleFonts.poppins(
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                                backgroundColor: Colors.orange
                                                    .withOpacity(0.9),
                                                duration: Duration(seconds: 2),
                                              ),
                                            );
                                            // close the dialog
                                            Navigator.pop(context);
                                            // close the bottom sheet
                                            Navigator.pop(context);
                                          },
                                          style: TextButton.styleFrom(
                                            backgroundColor:
                                                Colors.orange.withOpacity(0.1),
                                            padding: EdgeInsets.symmetric(
                                                horizontal: 16, vertical: 8),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  PostCardDesign.buttonRadius,
                                            ),
                                          ),
                                          child: Text(
                                            "Report",
                                            style: GoogleFonts.poppins(
                                              color: Colors.orange,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                  icon: const Icon(
                    Icons.more_vert,
                    color: Colors.white,
                    size: 20,
                  ),
                )
              ],
            ),
          ),
          // image section
          GestureDetector(
            onDoubleTap: () async {
              if (user != null && mounted) {
                // Beğeni durumunu değiştirmeden önce mevcut durumu kontrol et
                bool isLiked = _likes.contains(user.uid!);

                // Eğer zaten beğenilmişse, çift tıklama ile beğeniyi kaldırma
                if (!isLiked) {
                  // Kullanıcı arayüzünü hemen güncelle
                  if (mounted) {
                    setState(() {
                      _likes.add(user.uid!);
                      isLikeAnimating = true;
                    });
                  }

                  // Firestore'da beğeni durumunu güncelle
                  try {
                    await FirebaseFirestore.instance
                        .collection('posts')
                        .doc(widget.snap["postId"])
                        .update({
                      'likes': FieldValue.arrayUnion([user.uid!])
                    });
                  } catch (e) {
                    print("Error updating like status: $e");
                    // Hata durumunda UI'ı geri al
                    if (mounted) {
                      setState(() {
                        _likes.remove(user.uid!);
                        isLikeAnimating = false;
                      });
                    }
                  }

                  // Bildirim ekle
                  if (mounted && currentUserId != widget.snap["uid"]) {
                    await FireStoreMethods().addNotification(
                        "liked",
                        widget.snap["postId"],
                        widget.snap["uid"],
                        user.uid!,
                        currentUserId,
                        "");
                  }
                }
              }
            },
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.38,
                  width: double.infinity,
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: _imageUrls.length,
                    onPageChanged: (index) {
                      setState(() {
                        _currentImageIndex = index;
                      });
                    },
                    itemBuilder: (context, index) {
                      return Image.network(
                        _imageUrls[index],
                        fit: BoxFit.fitWidth,
                        errorBuilder: (context, error, stackTrace) {
                          print('Error loading post image: $error');
                          return Container(
                            color: Colors.grey.shade800,
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.image_not_supported_outlined,
                                    color: Colors.white,
                                    size: 50.0,
                                  ),
                                  SizedBox(height: 10),
                                  Text(
                                    'Image could not be loaded',
                                    style: PostCardTextStyles.errorMessage,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            color: Colors.grey.shade900,
                            child: Center(
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes !=
                                        null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                    : null,
                                color: Colors.white,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
                if (isWanted)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 6, horizontal: 12),
                      decoration: BoxDecoration(
                        color: PostCardDesign.itemBadgeColor,
                        borderRadius: PostCardDesign.badgeRadius,
                        boxShadow: PostCardDesign.badgeShadow,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.search,
                            color: Colors.white,
                            size: 14,
                          ),
                          SizedBox(width: 4),
                          Text(
                            "Wanted",
                            style: PostCardTextStyles.wantedBadge,
                          ),
                        ],
                      ),
                    ),
                  ),
                // show how many credits
                Positioned(
                  bottom: 12,
                  right: 12,
                  child: (
                      // only show credits if not premium user and not wanted post
                      isWanted == false && !_isPremium
                          ? Container(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 6, horizontal: 12),
                              decoration: BoxDecoration(
                                color: PostCardDesign.itemBadgeColor,
                                borderRadius: PostCardDesign.badgeRadius,
                                boxShadow: PostCardDesign.badgeShadow,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.credit_card,
                                    color: Colors.white,
                                    size: 14,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    widget.snap["category"] == "Electronics"
                                        ? "30 credits"
                                        : "20 credits",
                                    style: PostCardTextStyles.creditBadge,
                                  ),
                                ],
                              ),
                            )
                          : const SizedBox()),
                ),

                AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: isLikeAnimating ? 1 : 0,
                  child: LikeAnimation(
                    isAnimating: isLikeAnimating,
                    duration: const Duration(milliseconds: 400),
                    onEnd: () {
                      setState(() {
                        isLikeAnimating = false;
                      });
                    },
                    child: Icon(
                      user != null && _likes.contains(user.uid!)
                          ? Icons.favorite
                          : Icons.favorite_border,
                      color: user != null && _likes.contains(user.uid!)
                          ? const Color.fromARGB(255, 209, 34, 22)
                          : const Color.fromARGB(255, 255, 255, 255),
                      size: 150,
                    ),
                  ),
                ),

                // Page indicator dots for multiple images
                if (_hasMultipleImages)
                  Positioned(
                    bottom: 12,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        _imageUrls.length,
                        (index) => Container(
                          width: 8,
                          height: 8,
                          margin: EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _currentImageIndex == index
                                ? Colors.white
                                : Colors.white.withOpacity(0.4),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 3,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                // Image counter
                if (_hasMultipleImages)
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        "${_currentImageIndex + 1}/${_imageUrls.length}",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // like comment section
          // if post owner current user then show nothing
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: <Widget>[
                    LikeAnimation(
                      isAnimating: user != null && _likes.contains(user.uid!),
                      smallLike: true,
                      child: IconButton(
                        onPressed: () async {
                          if (user != null && mounted) {
                            // Beğeni durumunu değiştirmeden önce mevcut durumu kontrol et
                            bool isLiked = _likes.contains(user.uid!);

                            // Kullanıcı arayüzünü hemen güncelle
                            if (mounted) {
                              setState(() {
                                if (isLiked) {
                                  _likes.remove(user.uid!);
                                } else {
                                  _likes.add(user.uid!);
                                }
                                isLikeAnimating = !isLiked;
                              });
                            }

                            // Firestore'da beğeni durumunu güncelle
                            // Burada _likes listesini değil, sadece uid'yi gönderiyoruz
                            try {
                              await FirebaseFirestore.instance
                                  .collection('posts')
                                  .doc(widget.snap["postId"])
                                  .update({
                                'likes': isLiked
                                    ? FieldValue.arrayRemove([user.uid!])
                                    : FieldValue.arrayUnion([user.uid!])
                              });
                            } catch (e) {
                              print("Error updating like status: $e");
                              // Hata durumunda UI'ı geri al
                              if (mounted) {
                                setState(() {
                                  if (isLiked) {
                                    _likes.add(user.uid!);
                                  } else {
                                    _likes.remove(user.uid!);
                                  }
                                  isLikeAnimating = isLiked;
                                });
                              }
                            }

                            // Bildirim ekle (sadece beğeni eklendiyse)
                            if (!isLiked &&
                                mounted &&
                                currentUserId != widget.snap["uid"]) {
                              await FireStoreMethods().addNotification(
                                  "liked",
                                  widget.snap["postId"],
                                  widget.snap["uid"],
                                  user.uid!,
                                  currentUserId,
                                  "");
                            }
                          }
                        },
                        icon: user != null && _likes.contains(user.uid!)
                            ? const Icon(
                                Icons.favorite,
                                color: Colors.red,
                                size: 25,
                              )
                            : const Icon(
                                Icons.favorite_border,
                                color: Color.fromARGB(255, 255, 255, 255),
                                size: 25,
                              ),
                      ),
                    ),

                    DefaultTextStyle(
                      style: Theme.of(context).textTheme.titleSmall!.copyWith(
                            fontWeight: FontWeight.w900,
                            fontSize: 35,
                          ),
                      child: _likes.length > 0
                          ? Text(
                              _likes.length.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                                fontSize: 18,
                              ),
                            )
                          : const Text(""),
                    ),

                    const SizedBox(
                      width: 0,
                    ),

                    // comment button
                    // IconButton(
                    //   onPressed: () => Navigator.of(context).push(
                    //     MaterialPageRoute(
                    //       builder: (context) => CommentsScreen(
                    //         postId: widget.snap["postId"],
                    //         uid: widget.snap["uid"],
                    //         snap: widget.snap,
                    //       ),
                    //     ),
                    //   ),
                    //   icon: const Icon(
                    //     Icons.chat_bubble_outline,
                    //     size: 23,
                    //   ),
                    // ),
                    // InkWell(
                    //   onTap: () {
                    //     Navigator.of(context).push(
                    //       MaterialPageRoute(
                    //         builder: (context) => CommentsScreen(
                    //           postId: widget.snap["postId"],
                    //           uid: widget.snap["uid"],
                    //           snap: widget.snap,
                    //         ),
                    //       ),
                    //     );
                    //   },
                    //   child: Padding(
                    //     padding: const EdgeInsets.only(top: 8.0),
                    //     child: DefaultTextStyle(
                    //         style: Theme.of(context).textTheme.titleSmall!.copyWith(
                    //               fontWeight: FontWeight.w800,
                    //               fontSize: 30,
                    //             ),
                    //         child: // if commentLen is 0 then show nothing else show the commentLen
                    //             commentLen > 0
                    //                 ? Text(
                    //                     "$commentLen",
                    //                     style: Theme.of(context).textTheme.bodyMedium,
                    //                   )
                    //                 : const Text("")),
                    //   ),
                    // ),

                    // const SizedBox(
                    //   width: 10,
                    // ),

                    // IconButton(
                    //   icon: isSaved
                    //       ? const Icon(Icons.bookmark, size: 23, color: Colors.green)
                    //       : const Icon(Icons.bookmark_border,
                    //           size: 23, color: Colors.white),
                    //   onPressed: () {
                    //     savePost(context, widget.snap["postId"]);
                    //   },
                    // ),

                    // button to message the user
                    // get current user credit and check if it is more than 0 then show the message button else show get credit button
                    // if post owner current user then show nothing
                    const SizedBox(
                      width: 10,
                    ),

                    if (currentUserId != widget.snap["uid"])
                      StreamBuilder(
                        stream: FirebaseFirestore.instance
                            .collection("users")
                            .doc(currentUserId)
                            .snapshots(),
                        builder: (context, AsyncSnapshot snapshot) {
                          if (snapshot.hasData) {
                            int userCredits = snapshot.data["credit"];

                            return Row(children: [
                              TextButton.icon(
                                onPressed: () async {
                                  int requiredCredit =
                                      widget.snap["category"] == "Electronics"
                                          ? 30
                                          : 20;

                                  // Check if user is premium
                                  bool isPremium =
                                      snapshot.data["is_premium"] ?? false;

                                  if (isPremium) {
                                    // Premium users can send unlimited messages
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) => MessagesPage(
                                          currentUserUid: currentUserId,
                                          recipientUid: widget.snap["uid"],
                                          postId: widget.snap["postId"],
                                        ),
                                      ),
                                    );
                                  } else if (userCredits >= requiredCredit) {
                                    // User has enough credits
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) => MessagesPage(
                                          currentUserUid: currentUserId,
                                          recipientUid: widget.snap["uid"],
                                          postId: widget.snap["postId"],
                                        ),
                                      ),
                                    );
                                  } else {
                                    // User doesn't have enough credits
                                    showDialog(
                                      context: context,
                                      builder: (BuildContext context) {
                                        return AlertDialog(
                                          backgroundColor: Color(0xFF0A0A0A),
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(20)),
                                          title: Row(
                                            children: [
                                              Icon(Icons.warning_amber_rounded,
                                                  color: Colors.amber,
                                                  size: 28),
                                              SizedBox(width: 10),
                                              Text(
                                                "Not enough credit",
                                                style: GoogleFonts.poppins(
                                                  color: Colors.white,
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                          content: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                widget.snap["category"] ==
                                                        "Electronics"
                                                    ? "You need at least 30 credits to message this user."
                                                    : "You need at least 20 credits to message this user.",
                                                style: GoogleFonts.poppins(
                                                    color: Colors.white,
                                                    fontSize: 16),
                                              ),
                                              SizedBox(height: 10),
                                              Text(
                                                "Since there is a limited number of free products, we have implemented a credit system. You can earn credits by watching ads to get products for free before other users.",
                                                style: GoogleFonts.poppins(
                                                    color: Colors.grey[400],
                                                    fontSize: 14),
                                              ),
                                            ],
                                          ),
                                          actions: [
                                            Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 16,
                                                      vertical: 8),
                                              child: Column(
                                                children: [
                                                  ElevatedButton(
                                                    onPressed: () {
                                                      Navigator.pop(context);
                                                      Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                            builder: (context) =>
                                                                const CreditPage()),
                                                      );
                                                    },
                                                    style: ElevatedButton
                                                        .styleFrom(
                                                      backgroundColor:
                                                          Colors.blue,
                                                      shape:
                                                          RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(12),
                                                      ),
                                                      minimumSize: Size(
                                                          double.infinity, 50),
                                                    ),
                                                    child: Text(
                                                      'Earn Free Credit',
                                                      style:
                                                          GoogleFonts.poppins(
                                                        fontSize: 16,
                                                        color: Colors.white,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                  SizedBox(height: 12),
                                                  Text(
                                                    "Or you can get unlimited credit",
                                                    style: GoogleFonts.poppins(
                                                        color: Colors.white,
                                                        fontSize: 14),
                                                  ),
                                                  SizedBox(height: 8),
                                                  ElevatedButton(
                                                    onPressed: () {
                                                      perfomMagic();
                                                    },
                                                    style: ElevatedButton
                                                        .styleFrom(
                                                      backgroundColor:
                                                          Colors.green,
                                                      shape:
                                                          RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(12),
                                                      ),
                                                      minimumSize: Size(
                                                          double.infinity, 50),
                                                    ),
                                                    child: Text(
                                                      'Get Unlimited Credit',
                                                      style:
                                                          GoogleFonts.poppins(
                                                        fontSize: 16,
                                                        color: Colors.white,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                  }
                                },
                                icon: Icon(
                                  Icons.mail_outline_rounded,
                                  size: 20,
                                  color: Color(0xFF36B37E),
                                ),
                                label: Text(
                                  "Message",
                                  style: PostCardTextStyles.actionButton,
                                ),
                                style: TextButton.styleFrom(
                                  backgroundColor:
                                      Color(0xFF36B37E).withOpacity(0.15),
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 8),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                    side: BorderSide(
                                      color: Color(0xFF36B37E).withOpacity(0.4),
                                      width: 1,
                                    ),
                                  ),
                                ),
                              ),
                            ]);
                          } else {
                            return const SizedBox();
                          }
                        },
                      )
                  ],
                ),
              ),
              if (currentUserId != widget.snap["uid"])

                // show current user credit only if not premium
                if (currentUserId != widget.snap["uid"] && !_isPremium)
                  StreamBuilder(
                    stream: FirebaseFirestore.instance
                        .collection("users")
                        .doc(currentUserId)
                        .snapshots(),
                    builder: (context, AsyncSnapshot snapshot) {
                      if (snapshot.hasData) {
                        int userCredits = snapshot.data["credit"];

                        return Row(
                          children: [
                            Text(
                              "Your credit: $userCredits",
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(
                              width: 3,
                            ),
                          ],
                        );
                      } else {
                        return const SizedBox();
                      }
                    },
                  ),
            ],
          ),

          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.only(
                    top: 8,
                  ),
                  child: InkWell(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (context) => ProfileScreen2(
                                uid: widget.snap["uid"],
                                snap: user,
                                userId: currentUserId)),
                      );
                    },
                    child: // if description not empty show username and description, if null not show anything
                        widget.snap["description"] != ""
                            ? // username and description with streambuilder and rich text
                            StreamBuilder(
                                stream: FirebaseFirestore.instance
                                    .collection("users")
                                    .doc(widget.snap["uid"])
                                    .snapshots(),
                                builder: (context, AsyncSnapshot snapshot) {
                                  if (!snapshot.hasData) {
                                    return const Text("");
                                  }
                                  return RichText(
                                    text: TextSpan(
                                      children: [
                                        TextSpan(
                                          text: snapshot.data!["username"],
                                          style: PostCardTextStyles.username,
                                        ),
                                        TextSpan(
                                          text: " ",
                                          style: GoogleFonts.poppins(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        TextSpan(
                                          text: widget.snap["description"],
                                          style: PostCardTextStyles.description,
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              )
                            : const Text(""),
                  ),
                ),
                const SizedBox(
                  height: 3,
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Future<bool> hasUserSentMessage(String userId, String postId) async {
    QuerySnapshot<Map<String, dynamic>> result = await FirebaseFirestore
        .instance
        .collection("conversations")
        .where("sender", isEqualTo: userId)
        .limit(1)
        .get();

    return result.docs.isNotEmpty;
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return '${difference.inSeconds}s';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h';
    } else if (difference.inDays < 30) {
      return '${difference.inDays}d';
    } else if (difference.inDays < 365) {
      final months =
          (now.year - dateTime.year) * 12 + now.month - dateTime.month;
      return '$months months';
    } else {
      return '${difference.inDays ~/ 365} years ago';
    }
  }

  Future<void> sendNotificationToUser(
      String receiverUid, String title, String body) async {
    // Alıcı kullanıcının FCM token'ını veritabanından alın
    String receiverToken = fcmToken;

    if (receiverToken.isNotEmpty) {
      // Bildirim oluşturma ve gönderme
      var notification = {
        'notification': {
          'title': title,
          'body': body,
        },
        'to': receiverToken,
      };
    }
  }

  void perfomMagic() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    CustomerInfo customerInfo = await Purchases.getCustomerInfo();

    if (!mounted) return;

    if (customerInfo.entitlements.all[entitlementID] != null &&
        customerInfo.entitlements.all[entitlementID]?.isActive == true) {
      appData.currentData = WeatherData.generateData();

      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    } else {
      Offerings? offerings;
      try {
        offerings = await Purchases.getOfferings();
      } on PlatformException catch (e) {
        if (!mounted) return;
        await showDialog(
            context: context,
            builder: (BuildContext context) => ShowDialogToDismiss(
                title: "Error",
                content: e.message ?? "Unknown error",
                buttonText: 'OK'));
      }

      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });

      if (offerings == null || offerings.current == null) {
        // offerings are empty, show a message to your user
        if (!mounted) return;
        await showDialog(
            context: context,
            builder: (BuildContext context) => ShowDialogToDismiss(
                title: "Error",
                content: "No offerings available",
                buttonText: 'OK'));
      } else {
        // current offering is available, show paywall
        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => Paywall(offering: offerings!.current!)),
        );
      }
    }
  }

  // Check if user is premium
  Future<void> _checkPremiumStatus() async {
    try {
      if (!mounted) return;

      // Get user data from Firestore
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser)
          .get();

      if (!mounted) return;

      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>?;
        setState(() {
          _isPremium = data?['is_premium'] == true;
        });
      }

      // Also check RevenueCat premium status
      try {
        if (!mounted) return;
        CustomerInfo customerInfo = await Purchases.getCustomerInfo();

        if (!mounted) return;

        setState(() {
          _isPremium = _isPremium ||
              (customerInfo.entitlements.all[entitlementID]?.isActive ?? false);
        });
      } catch (e) {
        print("Error checking RevenueCat premium status: $e");
      }
    } catch (e) {
      print("Error checking premium status: $e");
    }
  }

  // Initialize image URLs from post data
  void _initializeImageUrls() {
    try {
      if (widget.snap != null) {
        // Check for postUrls field first (newer format)
        bool hasPostUrls = false;
        bool hasPostUrl = false;
        List<dynamic>? postUrlsList;
        String? singlePostUrl;

        // Safely check if postUrls exists and has content
        try {
          postUrlsList = widget.snap['postUrls'];
          hasPostUrls = postUrlsList != null && postUrlsList.isNotEmpty;
        } catch (e) {
          // Field doesn't exist, that's okay, we'll try the other one
          hasPostUrls = false;
        }

        // If no postUrls array, try the single postUrl
        if (!hasPostUrls) {
          try {
            singlePostUrl = widget.snap['postUrl'];
            hasPostUrl =
                singlePostUrl != null && singlePostUrl.toString().isNotEmpty;
          } catch (e) {
            // Field doesn't exist either
            hasPostUrl = false;
          }
        }

        // Now use the data we safely retrieved
        if (hasPostUrls && postUrlsList != null) {
          List<String> urls =
              postUrlsList.map((url) => url.toString()).toList();
          _imageUrls = urls.length > 5 ? urls.sublist(0, 5) : urls;
          _hasMultipleImages = _imageUrls.length > 1;
        } else if (hasPostUrl && singlePostUrl != null) {
          _imageUrls = [singlePostUrl];
          _hasMultipleImages = false;
        } else {
          _imageUrls = [];
          _hasMultipleImages = false;
        }
      } else {
        _imageUrls = [];
        _hasMultipleImages = false;
      }
    } catch (e) {
      print("Error initializing image URLs: $e");
      _imageUrls = [];
      _hasMultipleImages = false;
    }
  }

  // Update image URLs from post data
  void _updateImageUrls(dynamic data) {
    if (!mounted) return;

    try {
      // Check for postUrls field first (newer format)
      bool hasPostUrls = false;
      bool hasPostUrl = false;
      List<dynamic>? postUrlsList;
      String? singlePostUrl;

      // Safely check if postUrls exists and has content
      try {
        postUrlsList = data['postUrls'];
        hasPostUrls = postUrlsList != null && postUrlsList.isNotEmpty;
      } catch (e) {
        // Field doesn't exist, that's okay, we'll try the other one
        hasPostUrls = false;
      }

      // If no postUrls array, try the single postUrl
      if (!hasPostUrls) {
        try {
          singlePostUrl = data['postUrl'];
          hasPostUrl =
              singlePostUrl != null && singlePostUrl.toString().isNotEmpty;
        } catch (e) {
          // Field doesn't exist either
          hasPostUrl = false;
        }
      }

      setState(() {
        // Now use the data we safely retrieved
        if (hasPostUrls && postUrlsList != null) {
          List<String> urls =
              postUrlsList.map((url) => url.toString()).toList();
          _imageUrls = urls.length > 5 ? urls.sublist(0, 5) : urls;
          _hasMultipleImages = _imageUrls.length > 1;
        } else if (hasPostUrl && singlePostUrl != null) {
          _imageUrls = [singlePostUrl];
          _hasMultipleImages = false;
        } else {
          _imageUrls = [];
          _hasMultipleImages = false;
        }
      });
    } catch (e) {
      print("Error updating image URLs: $e");
      // Ensure we have at least an empty list on error
      setState(() {
        _imageUrls = [];
        _hasMultipleImages = false;
      });
    }
  }
}

class NotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  // UID'ye göre alıcı kullanıcının FCM token'ını getiren metot
  Future<String> getReceiverToken(String receiverUid) async {
    String token = '';

    await FirebaseFirestore.instance
        .collection('users')
        .doc(receiverUid)
        .get()
        .then((value) {
      token = value.data()!['fcmToken'];
    });

    return token;
  }
}

// Yardımcı widget fonksiyonları ekleyelim
Widget _buildInfoRow({
  required IconData icon,
  required String text,
  required bool isSmallScreen,
}) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        margin: EdgeInsets.only(top: 2),
        padding: EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.blue.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: Colors.blue,
          size: isSmallScreen ? 12 : 14,
        ),
      ),
      SizedBox(width: 8),
      Expanded(
        child: Text(
          text,
          style: GoogleFonts.poppins(
            color: Colors.white.withOpacity(0.8),
            fontSize: isSmallScreen ? 12 : 13,
            height: 1.3,
          ),
        ),
      ),
    ],
  );
}

Widget _buildPremiumBenefit({
  required String text,
  required bool isSmallScreen,
  IconData icon = Icons.check_circle,
}) {
  return Row(
    children: [
      Container(
        padding: EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Color(0xFF36B37E).withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: Color(0xFF36B37E),
          size: isSmallScreen ? 12 : 14,
        ),
      ),
      SizedBox(width: 8),
      Expanded(
        child: Text(
          text,
          style: GoogleFonts.poppins(
            color: Colors.white.withOpacity(0.9),
            fontSize: isSmallScreen ? 12 : 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    ],
  );
}

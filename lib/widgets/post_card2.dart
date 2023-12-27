// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:provider/provider.dart';
import 'package:Freecycle/models/user.dart' as model;

import 'package:Freecycle/screens/credit_page.dart';
import 'package:Freecycle/screens/message_screen.dart';
import 'package:Freecycle/utils/colors.dart';
import 'package:Freecycle/utils/utils.dart';
import 'package:Freecycle/widgets/like_animation.dart';

import '../providers/user_provider.dart';
import '../resources/firestore_methods.dart';
import '../screens/profile_screen2.dart';

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
  bool isWanted = false;

  @override
  void initState() {
    super.initState();
    getPostLocation();
    getComments();
    savedList = [];
    getSavedList();

    // initialize isRecipentExist if recipient is exist with stream builder
    FirebaseFirestore.instance
        .collection("posts")
        .doc(widget.snap.id)
        .snapshots()
        .listen((event) {
      if (event.data()!["recipient"] != "") {
        setState(() {
          isRecipentExist = true;
          recipientUid = event.data()!["recipient"];
        });
      } else {
        setState(() {
          isRecipentExist = false;
        });
      }
    });

    // initialize isWanted if isWanted is true set state true with stream builder
    FirebaseFirestore.instance
        .collection("posts")
        .doc(widget.snap.id)
        .snapshots()
        .listen((event) {
      if (event.data()!["isWanted"] == true) {
        setState(() {
          isWanted = true;
        });
      } else {
        setState(() {
          isWanted = false;
        });
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  // get current post owner fcm token
  Future<void> getFcmToken() async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.snap["uid"])
        .get()
        .then((value) {
      fcmToken = value.data()!['fcmToken'];
    });
  }

  // get post location from post document and save them to variables
  Future<void> getPostLocation() async {
    await FirebaseFirestore.instance
        .collection('posts')
        .doc(widget.snap["postId"])
        .get()
        .then((value) {
      country = value.data()!['country'];
      state = value.data()!['state'];
      city = value.data()!['city'];
    });
  }

// Initialize the plugin
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  void savePost(BuildContext context, String postId) async {
    var currentUser = FirebaseAuth.instance.currentUser;
    String currentUserId = currentUser!.uid;
    DocumentReference postRef = FirebaseFirestore.instance
        .collection("users")
        .doc(currentUserId)
        .collection("savedPosts")
        .doc(postId);

    if (savedList.contains(postId)) {
      // post zaten kaydedilmiş, dolayısıyla kaydedilenleri geri al
      try {
        await postRef.delete();
        setState(() {
          savedList.remove(postId);
        });
        showSnackBar(
          context,
          "Unsaved",
        );
      } catch (e) {
        showSnackBar(
          context,
          e.toString(),
        );
      }
    } else {
      // post kaydedilmemiş, dolayısıyla kaydet
      try {
        await postRef.set({
          "postId": postId,
        });
        setState(() {
          savedList.add(postId);
        });
        showSnackBar(
          context,
          "Saved",
        );
      } catch (e) {
        showSnackBar(
          context,
          e.toString(),
        );
      }
    }
  }

  Future<void> getSavedList() async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser)
        .collection('savedPosts')
        .get()
        .then((value) {
      if (value.docs.isEmpty) {
      } else {
        for (var doc in value.docs) {
          setState(() {
            savedList.add(doc.id);
          });
        }
      }
    });
  }

  void getComments() async {
    try {
      QuerySnapshot snap = await FirebaseFirestore.instance
          .collection("posts")
          .doc(widget.snap["postId"])
          .collection("comments")
          .get();

      commentLen = snap.docs.length;
    } catch (e) {
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
              vertical: 6,
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
                              // show user profile and username with stream builder
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
                                          margin: const EdgeInsets.only(
                                            left: 10,
                                          ),
                                          width: 40,
                                          height: 40,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            image: DecorationImage(
                                              image: NetworkImage(
                                                snapshot.data["photoUrl"],
                                              ),
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(
                                          width: 10,
                                        ),
                                        Text(
                                          snapshot.data["username"],
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(width: 3),
                                        // if sent gifts / match count == %100 show verified icon
                                        if (snapshot.data!['match_count'] !=
                                                null &&
                                            snapshot.data![
                                                    'number_of_sent_gifts'] !=
                                                null &&
                                            snapshot.data!['match_count'] !=
                                                0 &&
                                            snapshot.data![
                                                    'number_of_sent_gifts'] !=
                                                0 &&
                                            snapshot.data!['match_count'] /
                                                    snapshot.data![
                                                        'number_of_sent_gifts'] >=
                                                9)
                                          const Padding(
                                            padding: EdgeInsets.only(top: 2),
                                            child: Icon(
                                              Icons.verified,
                                              size: 15,
                                              color: Colors.blue,
                                            ),
                                          ),

                                        // show middle dot
                                        Container(
                                          margin: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                          ),
                                          width: 3,
                                          height: 3,
                                          decoration: const BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: Colors.grey,
                                          ),
                                        ),
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(right: 8.0),
                                          child: Text(
                                            _getTimeAgo(widget
                                                .snap["datePublished"]
                                                .toDate()),
                                            style: const TextStyle(
                                                color: Colors.grey,
                                                fontWeight: FontWeight.normal),
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
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                ),
                                width: 3,
                                height: 3,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.grey,
                                ),
                              ),
                              Row(children: [
                                if (country != "")
                                  const Text(
                                    "",
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                if (country != "" && state != "")
                                  const SizedBox(
                                    width: 3,
                                  ),
                                if (state != "")
                                  Text(
                                    state,
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                if (state != "" && city != "")
                                  const SizedBox(
                                    width: 3,
                                  ),
                                if (city != "")
                                  Text(
                                    city,
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                              ])
                            ],
                          ),
                        ),
                      ]),
                ),
                IconButton(
                  onPressed: () {
                    showModalBottomSheet(
                      isScrollControlled: true,
                      backgroundColor: Colors.grey[900],
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(20),
                        ),
                      ),
                      context: context,
                      builder: (context) => Container(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(
                              height: 5,
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Container(
                                // shadow
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                ),
                                width: 40,
                                height: 4,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(2),
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            if (currentUserId == widget.snap["uid"])
                              ListTile(
                                onTap: () async {
                                  // SHOW A DIALOG TO CONFIRM DELETE;
                                  showDialog(
                                    // circile border
                                    barrierColor: Colors.black.withOpacity(0.5),
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      backgroundColor: Colors.grey[900],
                                      title: const Text("Delete Post"),
                                      content: const Text(
                                          "Are you sure you want to delete this post?"),
                                      actions: [
                                        TextButton(
                                          onPressed: () {
                                            Navigator.pop(context);
                                          },
                                          child: const Text(
                                            "Cancel",
                                            style:
                                                TextStyle(color: Colors.white),
                                          ),
                                        ),
                                        TextButton(
                                          onPressed: () async {
                                            // delete the post and set isDeleted to true
                                            await FireStoreMethods().deletePost(
                                                widget.snap["postId"]);
                                            Navigator.pop(context);

                                            // delete notification about this post
                                            await FireStoreMethods()
                                                .deleteNotification(
                                                    widget.snap["postId"]);
                                          },
                                          child: const Text(
                                            "Delete",
                                            style: TextStyle(color: Colors.red),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                                title: const Column(
                                  children: [
                                    Padding(
                                      padding: EdgeInsets.only(left: 8.0),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.delete,
                                            color: Colors.red,
                                          ),
                                          SizedBox(
                                            width: 10,
                                          ),
                                          Text("Delete"),
                                        ],
                                      ),
                                    ),
                                    SizedBox(
                                      height: 20,
                                    ),
                                  ],
                                ),
                              ),
                            if (currentUserId != widget.snap["uid"])
                              ListTile(
                                onTap: () {
                                  // show a dialog to confirm block
                                  showDialog(
                                    barrierColor: Colors.black.withOpacity(0.5),
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      backgroundColor: Colors.grey[900],
                                      title: const Row(
                                        children: [
                                          Text("Block User"),
                                        ],
                                      ),
                                      content: const Text(
                                          "Are you sure you want to block this user?"),
                                      actions: [
                                        TextButton(
                                          onPressed: () {
                                            Navigator.pop(context);
                                          },
                                          child: const Text(
                                            "Cancel",
                                            style:
                                                TextStyle(color: Colors.white),
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
                                              const SnackBar(
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
                                                ),
                                                duration: Duration(seconds: 2),
                                              ),
                                            );
                                            // close the dialog or bottom sheet
                                            Navigator.pop(context);
                                          },
                                          child: const Text(
                                            "Block",
                                            style: TextStyle(color: Colors.red),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                                title: const Row(
                                  children: [
                                    Icon(
                                      Icons.block,
                                    ),
                                    SizedBox(
                                      width: 10,
                                    ),
                                    Text("Block User"),
                                  ],
                                ),
                              ),
                            if (currentUserId != widget.snap["uid"])
                              ListTile(
                                onTap: () {
                                  // code to hide the post from the current user
                                  FireStoreMethods().dontShowPost(
                                    currentUserId,
                                    widget.snap["postId"],
                                  );
                                },
                                title: const Row(
                                  children: [
                                    Icon(
                                      Icons.visibility_off,
                                    ),
                                    SizedBox(
                                      width: 10,
                                    ),
                                    Text("Hide"),
                                  ],
                                ),
                              ),
                            if (currentUserId != widget.snap["uid"])
                              ListTile(
                                onTap: () {
                                  // code to report the user who posted the content
                                  FireStoreMethods().reportUser(
                                    currentUserId,
                                    widget.snap["uid"],
                                  );
                                  // show a snackbar in the center of the screen
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.all(
                                          Radius.circular(10),
                                        ),
                                      ),
                                      behavior: SnackBarBehavior.floating,
                                      content: Text(
                                        "User reported",
                                      ),
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                },
                                title: const Row(
                                  children: [
                                    Icon(
                                      Icons.report,
                                    ),
                                    SizedBox(
                                      width: 10,
                                    ),
                                    Text("Report"),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                  icon: const Icon(
                    Icons.more_vert,
                    size: 18,
                  ),
                )
              ],
            ),
          ),
          // image section
          GestureDetector(
            onDoubleTap: () async {
              await FireStoreMethods().likePost(
                  widget.snap["postId"], user!.uid, widget.snap["likes"]);

              // if user not liked the post before add notification
              // if (!widget.snap["likes"].contains(user.uid) &&
              //     currentUserId != widget.snap["uid"]) {
              //   NotificationService().showNotification(
              //     id: 0,
              //     title: "New Notification",
              //     body: "${user.username} liked your post",
              //   );
              // add notification
              await FireStoreMethods().addNotification(
                  "liked",
                  widget.snap["postId"],
                  widget.snap["uid"],
                  user.uid,
                  currentUserId,
                  "");
              setState(() {
                isLikeAnimating = true;
              });
              // }
            },
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.38,
                  width: double.infinity,
                  child: Image.network(
                    widget.snap["postUrl"],
                    fit: BoxFit.fitWidth,
                  ),
                ),
                if (isWanted)
                  Positioned(
                    top: 10, // Adjust the top position according to your needs
                    right:
                        10, // Adjust the right position according to your needs
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        "Wanted",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                // show how many credits
                Positioned(
                  bottom: 10, // Adjust the top position according to your needs
                  right:
                      10, // Adjust the right position according to your needs
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      "6 Credit",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: isLikeAnimating ? 1 : 0,
                  child: LikeAnimation(
                    isAnimating: isLikeAnimating,
                    duration: const Duration(
                      milliseconds: 400,
                    ),
                    onEnd: () {
                      setState(() {
                        isLikeAnimating = false;
                      });
                    },
                    // if the already liked the post then show the keyboard arrow down else show the keyboard arrow up
                    child: Icon(
                      widget.snap["likes"].contains(user!.uid)
                          ? Icons.favorite
                          : Icons.favorite_border,
                      // if the already liked the post then show the red color else show the white color
                      color: widget.snap["likes"].contains(user.uid)
                          ? const Color.fromARGB(255, 209, 34, 22)
                          : const Color.fromARGB(255, 255, 255, 255),
                      size: 150,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // like comment section
          // if post owner current user then show nothing
          if (currentUserId != widget.snap["uid"])
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: <Widget>[
                      LikeAnimation(
                        isAnimating: widget.snap['likes'].contains(user.uid),
                        smallLike: true,
                        child: IconButton(
                          onPressed: () async {
                            // add like to the post
                            await FireStoreMethods().likePost(
                                widget.snap["postId"],
                                user.uid,
                                widget.snap["likes"]);

                            // if user not liked the post before add notification
                            // if (!widget.snap["likes"].contains(user.uid) &&
                            //     currentUserId != widget.snap["uid"]) {
                            //   NotificationService().showNotification(
                            //     id: 0,
                            //     title: "New Notification",
                            //     body: "${user.username} liked your post",
                            //   );
                            // add notification
                            await FireStoreMethods().addNotification(
                                "liked",
                                widget.snap["postId"],
                                widget.snap["uid"],
                                user.uid,
                                currentUserId,
                                "");
                            // }
                          },
                          icon: widget.snap['likes'].contains(user.uid)
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
                        child: widget.snap['likes'].length > 0
                            ? Text(
                                widget.snap['likes'].length.toString(),
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
                      StreamBuilder(
                        stream: FirebaseFirestore.instance
                            .collection("users")
                            .doc(currentUserId)
                            .snapshots(),
                        builder: (context, AsyncSnapshot snapshot) {
                          if (snapshot.hasData) {
                            int userCredits = snapshot.data["credit"];

                            return userCredits >= 6
                                ? Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      TextButton(
                                        style: TextButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 5,
                                          ),
                                          backgroundColor: const Color.fromARGB(
                                              255, 50, 133, 196),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                        ),
                                        onPressed: () {
                                          Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  MessagesPage(
                                                recipientUid:
                                                    widget.snap["uid"],
                                                currentUserUid: currentUserId,
                                                postId: widget.snap["postId"],
                                              ),
                                            ),
                                          );
                                        },
                                        child: const Row(
                                          children: [
                                            Icon(
                                              Icons.mail,
                                              color: Colors.white,
                                              size: 23,
                                            ),
                                            SizedBox(
                                              width: 3,
                                            ),
                                            Text(
                                              "Message",
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  )
                                : TextButton(
                                    style: TextButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 2,
                                      ),
                                      backgroundColor: const Color.fromARGB(
                                          255, 50, 133, 196),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    onPressed: () {
                                      if (userCredits < 6) {
                                        // Show an alert dialog
                                        showDialog(
                                          context: context,
                                          builder: (BuildContext context) {
                                            return // redirect to credit page
                                                AlertDialog(
                                              backgroundColor: Colors.grey[900],
                                              title: const Text(
                                                "Not enough credit",
                                                style: TextStyle(
                                                  color: Color.fromARGB(
                                                      255, 255, 255, 255),
                                                ),
                                              ),
                                              content: const Text(
                                                "You need at least 6 credits to message this user \n \nBut don't worry you can get more credits by watching ads just in 1 minute",
                                                style: TextStyle(
                                                  color: Colors.white,
                                                ),
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () {
                                                    Navigator.pop(context);
                                                  },
                                                  child: const Text(
                                                    "Cancel",
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ),
                                                TextButton(
                                                  style: TextButton.styleFrom(
                                                    padding:
                                                        const EdgeInsets.all(
                                                            10),
                                                    backgroundColor:
                                                        const Color.fromARGB(
                                                            255, 50, 133, 196),
                                                    shape:
                                                        RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              10),
                                                    ),
                                                  ),
                                                  onPressed: () {
                                                    Navigator.pop(context);
                                                    Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder: (context) =>
                                                            const CreditPage(),
                                                      ),
                                                    );
                                                  },
                                                  child: const Text(
                                                    "Get Credit",
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            );
                                          },
                                        );
                                      }
                                    },
                                    child: const Row(
                                      children: [
                                        Icon(
                                          Icons.mail,
                                          color: Colors.white,
                                          size: 23,
                                        ),
                                        SizedBox(
                                          width: 3,
                                        ),
                                        Text(
                                          "Message",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w400,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                          } else {
                            return const SizedBox();
                          }
                        },
                      ),
                    ],
                  ),
                ),
                // show current user credit
                // if post owner current user then show nothing
                if (currentUserId != widget.snap["uid"])
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
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium!
                                              .copyWith(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w800,
                                              ),
                                        ),
                                        TextSpan(
                                          text: " ",
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium!
                                              .copyWith(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w800,
                                              ),
                                        ),
                                        TextSpan(
                                          text: widget.snap["description"],
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium!
                                              .copyWith(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w400,
                                              ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              )
                            : const Text(""),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 0),
                )
              ],
            ),
          )
        ],
      ),
    );
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
      return '$months months ago';
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

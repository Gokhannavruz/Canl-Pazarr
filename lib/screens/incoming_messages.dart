import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freecycle/screens/message_screen.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../models/user.dart';
import 'package:freecycle/screens/jobs_messages_page.dart' hide Message;

class IncomingMessagesPage extends StatefulWidget {
  final String currentUserUid;

  const IncomingMessagesPage({Key? key, required this.currentUserUid})
      : super(key: key);

  @override
  _IncomingMessagesPageState createState() => _IncomingMessagesPageState();
}

class _IncomingMessagesPageState extends State<IncomingMessagesPage> {
  late Future<Map<String, List<Message>>> _futureConversations;
  bool isJobPost = false;

  NativeAd? _nativeAd;
  bool isAdLoaded = false;
  final StreamController<Message> _messageStreamController =
      StreamController.broadcast();

  // get messagesId from conversations that contain current user uid and recipient uid or vice versa and delete them
  Future<void> _deleteConversation(
      String currentUserUid, String recipientUid) async {
    QuerySnapshot conversations = await FirebaseFirestore.instance
        .collection("conversations")
        .where("users", arrayContains: currentUserUid)
        .get();
    for (var conversation in conversations.docs) {
      List<dynamic> users = conversation["users"];
      if (users.contains(recipientUid)) {
        String conversationId = conversation.id;
        await FirebaseFirestore.instance
            .collection("conversations")
            .doc(conversationId)
            .delete();
        setState(() {
          _futureConversations = _loadConversations();
        });
        break;
      }
    }
  }

  void _loadNativeAd() {
    _nativeAd = NativeAd(
      adUnitId: 'ca-app-pub-8445989958080180/5911867262',
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
  void initState() {
    super.initState();
    _futureConversations = _loadConversations();

    /* _loadNativeAd(); */
    // Listen for new messages
    FirebaseFirestore.instance
        .collection("conversations")
        .where("users", arrayContains: widget.currentUserUid)
        .snapshots()
        .listen((snapshot) {
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          Message message = Message.fromSnapshot(change.doc);
          _messageStreamController.add(message);
          setState(() {
            _futureConversations = _loadConversations();
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _messageStreamController.close();
    _nativeAd?.dispose();
    super.dispose();
  }

  Future<void> _getPostIdAndRedirect(String recipientUid) async {
    try {
      String postId = await _getPostId(recipientUid);

      // Check if postId exists in either "posts" or "jobPosts" collection
      bool isJobPost = await _isJobPost(postId);

      // Always direct to MessagesPage for deleted posts
      if (postId.isEmpty || (!await _postExists(postId))) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MessagesPage(
              currentUserUid: widget.currentUserUid,
              recipientUid: recipientUid,
              postId: postId,
            ),
          ),
        );
        return;
      }

      // Direct to appropriate page based on post type
      if (isJobPost) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => jobMessagesPage(
              currentUserUid: widget.currentUserUid,
              recipientUid: recipientUid,
              postId: postId,
            ),
          ),
        );
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MessagesPage(
              currentUserUid: widget.currentUserUid,
              recipientUid: recipientUid,
              postId: postId,
            ),
          ),
        );
      }
    } catch (e) {
      print("Error in _getPostIdAndRedirect: $e");
      // Default to MessagesPage in case of any error
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MessagesPage(
            currentUserUid: widget.currentUserUid,
            recipientUid: recipientUid,
            postId: "",
          ),
        ),
      );
    }
  }

  // Helper method to check if post exists in either collection
  Future<bool> _postExists(String postId) async {
    if (postId.isEmpty) return false;

    DocumentSnapshot postSnapshot =
        await FirebaseFirestore.instance.collection("posts").doc(postId).get();

    DocumentSnapshot jobPostSnapshot = await FirebaseFirestore.instance
        .collection("jobPosts")
        .doc(postId)
        .get();

    return postSnapshot.exists || jobPostSnapshot.exists;
  }

  // Helper method to determine if a post is a job post
  Future<bool> _isJobPost(String postId) async {
    if (postId.isEmpty) return false;

    DocumentSnapshot jobPostSnapshot = await FirebaseFirestore.instance
        .collection("jobPosts")
        .doc(postId)
        .get();

    return jobPostSnapshot.exists;
  }

// get clicked conversation's post id
  Future<String> _getPostId(String recipientUid) async {
    QuerySnapshot conversations = await FirebaseFirestore.instance
        .collection("conversations")
        .where("users", arrayContains: widget.currentUserUid)
        .get();
    for (var conversation in conversations.docs) {
      List<dynamic> users = conversation["users"];
      if (users.contains(recipientUid)) {
        String postId = conversation["postId"] ?? "";
        return postId;
      }
    }
    return "";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          title: Text(
            "Messages",
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 20,
              color: Colors.white,
            ),
          ),
          centerTitle: true,
          backgroundColor: Color(0xFF1A1A1A),
          elevation: 0,
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF1A1A1A),
                Colors.black,
              ],
            ),
          ),
          child: Column(
            children: [
              Expanded(
                child: FutureBuilder<Map<String, List<Message>>>(
                  future: _futureConversations,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: Colors.white,
                        ),
                      );
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return Center(
                        child: Container(
                          padding: const EdgeInsets.all(24),
                          margin: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.1),
                            ),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.inbox_outlined,
                                size: 80,
                                color: Colors.blue.withOpacity(0.7),
                              ),
                              const SizedBox(height: 24),
                              Text(
                                "Your inbox is empty",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                "Messages will appear here when you connect with other users",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    Map<String, List<Message>> chats = snapshot.data!;
                    List<String> senderUids = chats.keys.toList()
                      ..sort((a, b) {
                        var aMessages = chats[a]!;
                        var bMessages = chats[b]!;
                        return bMessages.first.timestamp
                            .compareTo(aMessages.first.timestamp);
                      });

                    return ListView.builder(
                      physics: BouncingScrollPhysics(),
                      padding: EdgeInsets.symmetric(vertical: 8),
                      itemCount: senderUids.length,
                      itemBuilder: (context, index) {
                        late Message lastMessage;
                        String senderUid = senderUids[index];
                        List<Message> messages = chats[senderUid]!;
                        messages
                            .sort((a, b) => b.timestamp.compareTo(a.timestamp));
                        lastMessage = messages.first;

                        return FutureBuilder<User>(
                          future: _getUser(senderUid),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const SizedBox.shrink();
                            } else if (!snapshot.hasData) {
                              return const SizedBox.shrink();
                            }
                            User user = snapshot.data!;
                            String username = user.username ?? "User";
                            String profilePhotoUrl = user.photoUrl ?? "";
                            bool isCurrentUser =
                                senderUid == widget.currentUserUid;

                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 6),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () {
                                    _getPostIdAndRedirect(senderUid);
                                  },
                                  onLongPress: () {
                                    // Show bottom sheet with options to delete conversation
                                    showModalBottomSheet(
                                      backgroundColor: Color(0xFF1E1E1E),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.vertical(
                                          top: Radius.circular(20),
                                        ),
                                      ),
                                      context: context,
                                      builder: (context) => Container(
                                        padding:
                                            EdgeInsets.symmetric(vertical: 20),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Container(
                                              width: 50,
                                              height: 5,
                                              decoration: BoxDecoration(
                                                color: Colors.grey[600],
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                            ),
                                            SizedBox(height: 20),
                                            ListTile(
                                              leading: Container(
                                                padding: EdgeInsets.all(10),
                                                decoration: BoxDecoration(
                                                  color: Colors.red
                                                      .withOpacity(0.1),
                                                  shape: BoxShape.circle,
                                                ),
                                                child: Icon(
                                                  Icons.delete_outline,
                                                  color: Colors.red,
                                                ),
                                              ),
                                              title: Text(
                                                "Delete conversation",
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                              subtitle: Text(
                                                "This action cannot be undone",
                                                style: TextStyle(
                                                  color: Colors.white
                                                      .withOpacity(0.5),
                                                  fontSize: 12,
                                                ),
                                              ),
                                              onTap: () {
                                                Navigator.pop(context);
                                                _deleteConversation(
                                                    widget.currentUserUid,
                                                    senderUid);
                                              },
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                  borderRadius: BorderRadius.circular(16),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.05),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.1),
                                      ),
                                    ),
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 55,
                                          height: 55,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color:
                                                  Colors.white.withOpacity(0.2),
                                              width: 2,
                                            ),
                                          ),
                                          child: ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(30),
                                            child: profilePhotoUrl.isNotEmpty
                                                ? Image.network(
                                                    profilePhotoUrl,
                                                    fit: BoxFit.cover,
                                                    errorBuilder: (context,
                                                        error, stackTrace) {
                                                      return Icon(
                                                        Icons.account_circle,
                                                        size: 55,
                                                        color: Colors.white
                                                            .withOpacity(0.7),
                                                      );
                                                    },
                                                  )
                                                : Icon(
                                                    Icons.account_circle,
                                                    size: 55,
                                                    color: Colors.white
                                                        .withOpacity(0.7),
                                                  ),
                                          ),
                                        ),
                                        SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  Flexible(
                                                    child: Text(
                                                      username,
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 16,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                      ),
                                                    ),
                                                  ),
                                                  SizedBox(width: 8),
                                                  Text(
                                                    _formatTimestamp(
                                                        lastMessage.timestamp),
                                                    style: TextStyle(
                                                      color: Colors.white
                                                          .withOpacity(0.5),
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              SizedBox(height: 6),
                                              lastMessage.sender ==
                                                      widget.currentUserUid
                                                  ? Text(
                                                      "You: ${_truncateMessage(lastMessage.text)}",
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: TextStyle(
                                                        fontSize: 14,
                                                        color: Colors.white
                                                            .withOpacity(0.5),
                                                      ),
                                                    )
                                                  : Text(
                                                      _truncateMessage(
                                                          lastMessage.text),
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: TextStyle(
                                                        fontSize: 14,
                                                        color: Colors.white
                                                            .withOpacity(0.7),
                                                      ),
                                                    ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
              // show native ad
              /*  if (isAdLoaded)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: SizedBox(
                    height: 55,
                    child: AdWidget(ad: _nativeAd!),
                  ),
                )
              else
                const SizedBox.shrink(), */
            ],
          ),
        ));
    // floatingActionButton: FloatingActionButton(
    //   onPressed: () {
    //     // show bottom sheet with search bar
    //     showModalBottomSheet(
    //       context: context,
    //       builder: (context) => const SearchForMessageScreen(),
    //     );
    //   },
    //   backgroundColor: Colors.blue,
    //   child: const Icon(
    //     Icons.add,
    //     size: 35,
    //     weight: 100,
    //     color: Colors.white,
    //   ),
    // ));
  }

  Future<Map<String, List<Message>>> _loadConversations() async {
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection("conversations")
        .where("users", arrayContains: widget.currentUserUid)
        .get();

    Map<String, List<Message>> chats = {};
    for (DocumentSnapshot doc in snapshot.docs) {
      Message message = Message.fromSnapshot(doc);
      String recipientUid = message.recipient;
      String senderUid = message.sender;

      String otherUserUid =
          recipientUid == widget.currentUserUid ? senderUid : recipientUid;
      if (chats.containsKey(otherUserUid)) {
        chats[otherUserUid]!.add(message);
      } else {
        chats[otherUserUid] = [message];
      }
    }

    return chats;
  }

  String _formatTimestamp(Timestamp timestamp) {
    DateTime date = timestamp.toDate();
    Duration diff = DateTime.now().difference(date);
    if (diff.inDays >= 7) {
      return "${date.day}/${date.month}/${date.year}";
    } else if (diff.inDays >= 1) {
      return "${diff.inDays}d ago";
    } else if (diff.inHours >= 1) {
      return "${diff.inHours}h ago";
    } else if (diff.inMinutes >= 1) {
      return "${diff.inMinutes}m ago";
    } else {
      return "Just now";
    }
  }

  Future<User> _getUser(String uid) async {
    DocumentSnapshot doc =
        await FirebaseFirestore.instance.collection("users").doc(uid).get();
    return User.fromSnap(doc);
  }

  String _truncateMessage(String message) {
    // Maksimum 40 karakter göster
    if (message.length > 40) {
      return '${message.substring(0, 40)}...';
    }
    return message;
  }
}

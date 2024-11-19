import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:Freecycle/screens/message_screen.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../models/user.dart';
import 'package:Freecycle/screens/jobs_messages_page.dart' hide Message;

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

    _loadNativeAd();
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
    String postId = await _getPostId(recipientUid);
    if (isJobPost == false) {
      // PostId varsa MessagesPage'e yönlendir
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
    } else {
      // PostId yoksa JobMessagesPage'e yönlendir
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
    }
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
        String postId = conversation["postId"];
        // Check if postId exists in the "posts" collection
        DocumentSnapshot<Map<String, dynamic>> postSnapshot =
            await FirebaseFirestore.instance
                .collection("posts")
                .doc(postId)
                .get();
        if (postSnapshot.exists) {
          setState(() {
            isJobPost = false;
          });
        } else {
          setState(() {
            isJobPost = true;
          });
        }
        return postId;
      }
    }
    return "";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text("Messages"),
          backgroundColor: Colors.black,
          shadowColor: Colors.grey,
          elevation: 0.5,
        ),
        body: Column(
          children: [
            Expanded(
              child: FutureBuilder<Map<String, List<Message>>>(
                future: _futureConversations,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                        child: CircularProgressIndicator(
                      color: Colors.white,
                    ));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.only(top: 20.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Your inbox is as empty as a desert!",
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
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
                          String username = user.username;
                          String profilePhotoUrl = user.photoUrl ?? "";
                          bool isCurrentUser =
                              senderUid == widget.currentUserUid;
                          return InkWell(
                            child: Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: InkWell(
                                onLongPress: () {
                                  // show bottom sheet with options to delete conversation
                                  showModalBottomSheet(
                                    context: context,
                                    builder: (context) => SizedBox(
                                      height: 100,
                                      child: Column(
                                        children: [
                                          ListTile(
                                            leading: const Icon(Icons.delete),
                                            title: const Text(
                                                "Delete conversation"),
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
                                child: ListTile(
                                  leading: CircleAvatar(
                                    radius: 30,
                                    backgroundImage:
                                        NetworkImage(profilePhotoUrl),
                                  ),
                                  title: Text(
                                    username,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: lastMessage.sender ==
                                          widget.currentUserUid
                                      ? Text(
                                          // show only 2 lines of text for last message if it was sent by current user show "you:" before the message
                                          "You: ${lastMessage.text}",
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,

                                          style: const TextStyle(
                                              color: Colors.grey),
                                        )
                                      : Text(
                                          lastMessage.text,
                                          style: const TextStyle(
                                              color: Color.fromARGB(
                                                  255, 183, 181, 181)),
                                        ),
                                  trailing: Text(
                                    _formatTimestamp(lastMessage.timestamp),
                                    style: const TextStyle(color: Colors.grey),
                                  ),
                                  onTap: () {
                                    // get post id of clicked conversation
                                    _getPostIdAndRedirect(senderUid);
                                  },
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
            if (isAdLoaded)
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: SizedBox(
                  height: 55,
                  child: AdWidget(ad: _nativeAd!),
                ),
              )
            else
              const SizedBox.shrink(),
          ],
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
}

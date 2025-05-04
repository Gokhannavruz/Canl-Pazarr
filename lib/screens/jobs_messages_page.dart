import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:freecycle/screens/profile_screen2.dart';
import 'package:intl/intl.dart';

import '../models/user.dart';

class jobMessagesPage extends StatefulWidget {
  final String currentUserUid;
  final String recipientUid;
  final String postId;

  const jobMessagesPage({
    Key? key,
    required this.currentUserUid,
    required this.recipientUid,
    required this.postId,
  }) : super(key: key);

  @override
  _jobMessagesPageState createState() => _jobMessagesPageState();
}

class _jobMessagesPageState extends State<jobMessagesPage> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  late StreamSubscription<QuerySnapshot> _subscription;
  late Key _listKey = UniqueKey();
  User? recipientUser;
  late CollectionReference _messagesCollection;
  late bool _isListViewRendered;
  String currentUserUid = "";
  String PostUid = "";

  late String conversationId =
      widget.currentUserUid.hashCode <= widget.recipientUid.hashCode
          ? "${widget.currentUserUid}-${widget.recipientUid}"
          : "${widget.recipientUid}-${widget.currentUserUid}";

  @override
  void initState() {
    super.initState();
    // initialize _conversationId
    _isListViewRendered = false;
    getCurrentUserUid();
    getPostUid();
    getCurrentUser();
    getUserProfile().then((_) {
      _loadMessages();
      _messagesCollection = FirebaseFirestore.instance
          .collection("conversations")
          .doc(conversationId)
          .collection("messages");
      _subscription = _messagesCollection
          .orderBy("timestamp", descending: true)
          .snapshots()
          .listen((event) {
        setState(() {});
      });
    });
  }

  @override
  void dispose() {
    _subscription.cancel();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // users collection
  Future<User> getUser(String uid) async {
    DocumentSnapshot doc =
        await FirebaseFirestore.instance.collection("users").doc(uid).get();
    return User.fromSnap(doc);
  }

  // current user profile
  Future<User> getCurrentUser() async {
    DocumentSnapshot doc = await FirebaseFirestore.instance
        .collection("users")
        .doc(widget.currentUserUid)
        .get();
    return User.fromSnap(doc);
  }

  // recipient user profile
  Future<void> getUserProfile() async {
    recipientUser = await getUser(widget.recipientUid);
    setState(() {});
  }

  // get current users uid
  Future<void> getCurrentUserUid() async {
    currentUserUid = await getCurrentUser().then((value) => value.uid!);
    setState(() {
      currentUserUid = currentUserUid;
    });
  }

  // get uid field from posts collection with postId
  Future<void> getPostUid() async {
    try {
      DocumentSnapshot postDoc = await FirebaseFirestore.instance
          .collection('jobs')
          .doc(widget.postId)
          .get();

      if (!mounted) return;

      if (postDoc.exists) {
        final data = postDoc.data() as Map<String, dynamic>?;
        if (data != null) {
          setState(() {
            PostUid = data['uid'] ?? '';
          });
        }
      }
    } catch (e) {
      print("Error getting post uid: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 80,
        shadowColor: Colors.grey,
        elevation: 0.4,
        title: Row(
          children: [
            recipientUser == null
                ? Container()
                : Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: InkWell(
                        child: CircleAvatar(
                          radius: 23,
                          backgroundImage:
                              NetworkImage(recipientUser!.photoUrl!),
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ProfileScreen2(
                                  snap: null,
                                  uid: widget.recipientUid,
                                  userId: widget.currentUserUid),
                            ),
                          );
                        }),
                  ),
            const SizedBox(width: 8),
            recipientUser == null
                ? Container()
                : InkWell(
                    child: Text(recipientUser!.username!,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProfileScreen2(
                              snap: null,
                              uid: widget.recipientUid,
                              userId: widget.currentUserUid),
                        ),
                      );
                    },
                  ),
          ],
        ),
        backgroundColor: Colors.black,
      ),
      body: Column(
        children: [
          // show post with post id if it exists in container only pot image not profile image
          Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                widget.postId.isNotEmpty
                    ? StreamBuilder<DocumentSnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('jobPosts')
                            .doc(widget.postId)
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return Container(
                              width: MediaQuery.of(context).size.width - 40,
                              margin: const EdgeInsets.all(12),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.orange.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.info_outline,
                                      color: Colors.orange, size: 20),
                                  SizedBox(width: 12),
                                  Flexible(
                                    child: Text(
                                      "Loading job post information...",
                                      style: TextStyle(
                                          color: Colors.orange, fontSize: 14),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }

                          if (!snapshot.data!.exists) {
                            return Container(
                              width: MediaQuery.of(context).size.width - 40,
                              margin: const EdgeInsets.all(12),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.red.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.error_outline,
                                      color: Colors.red, size: 20),
                                  SizedBox(width: 12),
                                  Flexible(
                                    child: Text(
                                      "This job posting has been removed or is no longer available",
                                      style: TextStyle(
                                          color: Colors.red, fontSize: 14),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }

                          // Safe access to data
                          final data =
                              snapshot.data!.data() as Map<String, dynamic>?;

                          // Check if data is null or required fields are missing
                          if (data == null || !data.containsKey('category')) {
                            return Container(
                              width: MediaQuery.of(context).size.width - 40,
                              margin: const EdgeInsets.all(12),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.red.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.error_outline,
                                      color: Colors.red, size: 20),
                                  SizedBox(width: 12),
                                  Flexible(
                                    child: Text(
                                      "This job posting has been removed or is no longer available",
                                      style: TextStyle(
                                          color: Colors.red, fontSize: 14),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }

                          // If we get here, the data exists and has the required fields
                          final String postUrl = data['postUrl'] ?? '';
                          final String category = data['category'] ?? '';
                          final String isGiven =
                              data['isGiven']?.toString() ?? '';

                          return Container(
                            height: 80,
                            width: 80,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              image: DecorationImage(
                                image: NetworkImage(postUrl),
                                fit: BoxFit.fill,
                              ),
                            ),
                          );
                        },
                      )
                    : Container(),
                // get post category and location information
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      widget.postId.isNotEmpty
                          ? StreamBuilder<DocumentSnapshot>(
                              stream: FirebaseFirestore.instance
                                  .collection('jobPosts')
                                  .doc(widget.postId)
                                  .snapshots(),
                              builder: (context, snapshot) {
                                if (!snapshot.hasData) {
                                  return const SizedBox.shrink();
                                }

                                if (!snapshot.data!.exists) {
                                  return const SizedBox.shrink();
                                }

                                // Safe data access
                                final data = snapshot.data!.data()
                                    as Map<String, dynamic>?;
                                if (data == null) {
                                  return const SizedBox.shrink();
                                }

                                final String category = data['category'] ?? '';
                                final String country = data['country'] ?? '';
                                final String state = data['state'] ?? '';
                                final String city = data['city'] ?? '';

                                return Container(
                                  padding: const EdgeInsets.only(left: 8.0),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const SizedBox(width: 4),
                                      // location information
                                      Flexible(
                                        child: city.isNotEmpty
                                            ? Text(
                                                "- $city, $state, $country",
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.grey,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              )
                                            : state.isNotEmpty
                                                ? Text(
                                                    "- $state, $country",
                                                    style: const TextStyle(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Colors.grey,
                                                    ),
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  )
                                                : Text(
                                                    "- $country",
                                                    style: const TextStyle(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Colors.grey,
                                                    ),
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            )
                          : Container(),
                    ],
                  ),
                ),
              ],
            ),
          ),
// confirm button for is this item given this user or not
          PostUid == currentUserUid
              ? StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('jobs')
                      .doc(widget.postId)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const SizedBox.shrink();
                    }

                    if (!snapshot.data!.exists) {
                      return const SizedBox.shrink();
                    }

                    // Safe data access
                    final data = snapshot.data!.data() as Map<String, dynamic>?;
                    if (data == null) {
                      return const SizedBox.shrink();
                    }

                    final bool isGiven = data['isGiven'] ?? false;

                    return Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        // if not given show confirm button, if given show text given
                        children: [
                          isGiven
                              ? const Text(
                                  "Given",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey,
                                  ),
                                )
                              : ElevatedButton(
                                  onPressed: () {
                                    // show dialog to confirm
                                    showDialog(
                                      context: context,
                                      builder: (context) {
                                        return AlertDialog(
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(8.0),
                                          ),
                                          title: const Text(
                                              "Confirm this item is given?"),
                                          actions: [
                                            TextButton(
                                              onPressed: () {
                                                Navigator.pop(context);
                                              },
                                              child: const Text("Cancel"),
                                            ),
                                            TextButton(
                                              style: TextButton.styleFrom(
                                                foregroundColor: Colors.white,
                                                backgroundColor:
                                                    Colors.blueAccent,
                                                disabledForegroundColor:
                                                    Colors.grey.withOpacity(
                                                        0.38), // foreground
                                              ),
                                              onPressed: () {
                                                Navigator.pop(context);
                                                // update post isGiven to true
                                                FirebaseFirestore.instance
                                                    .collection("jobs")
                                                    .doc(widget.postId)
                                                    .update({
                                                  "isGiven": true,
                                                });

                                                updateCredit();
                                              },
                                              child: const Text("Confirm"),
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    backgroundColor: Colors.black,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(32.0),
                                    ),
                                  ),
                                  child: const Text("Confirm"),
                                ),
                        ],
                      ),
                    );
                  },
                )
              : Container(),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(3.0),
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection("conversations")
                    .where("messagesId", isEqualTo: conversationId)
                    .orderBy("timestamp", descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  // if its firs time loading messages
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Container();
                  }
                  if (snapshot.hasData) {
                    List<Message> messages = [];
                    for (var doc in snapshot.data!.docs) {
                      messages.add(Message.fromSnapshot(doc));
                    }
                    return ListView.builder(
                      key: _listKey,
                      cacheExtent: 1000,
                      controller: _scrollController,
                      reverse: true,
                      addAutomaticKeepAlives: true,
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        bool isCurrentUser =
                            messages[index].sender == widget.currentUserUid;
                        bool isFirstMessage = index == messages.length - 1 ||
                            messages[index + 1].sender !=
                                messages[index].sender;
                        return FutureBuilder<User>(
                          future: getUser(messages[index].sender),
                          builder: (context, snapshot) {
                            if (!_isListViewRendered) {
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                _scrollController.jumpTo(
                                    _scrollController.position.maxScrollExtent);
                              });
                            }
                            _isListViewRendered = true;
                            if (snapshot.hasData) {
                              return Padding(
                                padding: const EdgeInsets.only(
                                    left: 8.0,
                                    right: 8.0,
                                    top: 2.0,
                                    bottom: 2.0),
                                child: Column(
                                    crossAxisAlignment: isCurrentUser
                                        ? CrossAxisAlignment.end
                                        : CrossAxisAlignment.start,
                                    children: [
                                      // if its first message show sized box
                                      if (isFirstMessage)
                                        const SizedBox(height: 13),
                                      Container(
                                        // max size
                                        constraints: BoxConstraints(
                                          maxWidth: MediaQuery.of(context)
                                                  .size
                                                  .width *
                                              0.9,
                                        ),
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(15),
                                          color: isCurrentUser
                                              ? const Color.fromARGB(
                                                  255, 176, 49, 11)
                                              : const Color.fromARGB(
                                                  255, 37, 79, 118),
                                        ),

                                        padding: const EdgeInsets.all(8),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: [
                                            Padding(
                                              padding:
                                                  const EdgeInsets.all(2.0),
                                              child: Text(
                                                // deccrypt message text
                                                messages[index].text,
                                                textAlign: TextAlign.left,
                                                style: TextStyle(
                                                  fontSize: 17,
                                                  color: isCurrentUser
                                                      ? Colors.white
                                                      : const Color.fromARGB(
                                                          255, 255, 255, 255),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            // if in today show time, if yesterday show yesterday, if not show date
                                            // show in the bottom right
                                            Text(
                                              DateFormat("HH:mm").format(
                                                  messages[index]
                                                      .timestamp
                                                      .toDate()),
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: isCurrentUser
                                                    ? Colors.white
                                                    : const Color.fromARGB(
                                                        255, 255, 255, 255),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      // if this last message show size box
                                    ]),
                              );
                            } else {
                              return Container();
                            }
                          },
                        );
                      },
                    );
                  } else {
                    return Container();
                  }
                },
              ),
            ),
          ),
          Padding(
            padding:
                const EdgeInsets.only(bottom: 8.0, top: 6, left: 6, right: 6),
            child: Container(
              decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  // border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      spreadRadius: 1,
                      blurRadius: 1,
                      offset: const Offset(0, 1), // changes position of shadow
                    ),
                  ]),
              child: _buildTextComposer(),
            ),
          ),
        ],
      ),
    );
  }

  // create conversation id if users is same doesnt matter who is first or second
  String getConversationId(String uid1, String uid2) {
    if (uid1.compareTo(uid2) > 0) {
      return uid1 + uid2;
    } else {
      return uid2 + uid1;
    }
  }

// create conversation if it doesnt exist
  Future<void> createConversation(String conversationId) async {
    await FirebaseFirestore.instance
        .collection("conversations")
        .doc(conversationId)
        .set({
      "messagesId": conversationId,
    });
  }

  Widget _buildTextComposer() {
    return IconTheme(
      data: IconThemeData(color: Theme.of(context).colorScheme.secondary),
      child: Container(
        margin: const EdgeInsets.symmetric(
          horizontal: 10.0,
        ),
        child: Row(
          // circle
          children: <Widget>[
            Flexible(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  cursorColor: Colors.white,
                  controller: _textController,
                  onSubmitted: _handleSubmitted,
                  decoration: const InputDecoration.collapsed(
                      hintText: "Send a message"),
                ),
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 4.0),
              child: IconButton(
                  iconSize: 21,
                  color: Colors.white,
                  icon: const Icon(Icons.send),
                  onPressed: () {
                    // if recipient is current user, show local notification with NotificationService
                    // if (widget.recipientUid == widget.currentUserUid) {
                    // NotificationService().showNotification(
                    //   id: 0,
                    //   title: "New message",
                    //   body: // sender name + text
                    //       "New message from " +
                    //           currentUserName +
                    //           ": " +
                    //           _textController.text,
                    // );
                    // }
// if text is not empty, send message
                    _textController.text.isNotEmpty
                        ? _handleSubmitted(_textController.text)
                        : null;
                  }),
            )
          ],
        ),
      ),
    );
  }

  // add ,+1 to current user's credit, add -1 to recipient user's credit
  Future<void> updateCredit() async {
    // get current user's credit
    DocumentSnapshot doc = await FirebaseFirestore.instance
        .collection("users")
        .doc(widget.currentUserUid)
        .get();
    int credit = doc["credit"];
    // update current user's credit
    FirebaseFirestore.instance
        .collection("users")
        .doc(widget.currentUserUid)
        .update({
      "credit": credit + 20,
    });
    // get recipient user's credit
    DocumentSnapshot doc2 = await FirebaseFirestore.instance
        .collection("users")
        .doc(widget.recipientUid)
        .get();
    int credit2 = doc2["credit"];
    // update recipient user's credit
    FirebaseFirestore.instance
        .collection("users")
        .doc(widget.recipientUid)
        .update({
      "credit": credit2 - 10,
    });
  }

  void _addMessage(Message message) {
    _messagesCollection.add(message.toMap()).then((value) {
      setState(() {});
    });
  }

  void _handleSubmitted(String text) {
    _textController.clear();
    FirebaseFirestore.instance.collection("conversations").add({
      "text": // encrypt text
          text,
      "sender": widget.currentUserUid,
      "recipient": widget.recipientUid,
      "timestamp": DateTime.now(),
      "messagesId": conversationId,
      "users": [widget.currentUserUid, widget.recipientUid],
      "postId": widget.postId,
    });
    // Update the key to force the ListView to rebuild
    _listKey = UniqueKey();

    // load messages from database and if there are none, create a conversation
  }

  void _loadMessages() async {
    var messages = await FirebaseFirestore.instance
        .collection("conversations")
        .where("messagesId", isEqualTo: conversationId)
        .orderBy("timestamp", descending: true)
        .get();
    for (var doc in messages.docs) {
      var message = Message.fromSnapshot(doc);
      _addMessage(message);
    }
  }
}

class Message {
  String text;
  String sender;
  String recipient;
  Timestamp timestamp;
  String messagesId;
  List<String> users = [];
  String postId;
  Message(
      {required this.text,
      required this.sender,
      required this.recipient,
      required this.timestamp,
      required this.messagesId,
      required this.users,
      required this.postId});

  Message.fromSnapshot(DocumentSnapshot snapshot)
      : text = snapshot.get("text"),
        postId = snapshot.get("postId"),
        sender = snapshot.get("sender"),
        recipient = snapshot.get("recipient"),
        timestamp = snapshot.get("timestamp"),
        messagesId = snapshot.get("messagesId"),
        users = List<String>.from(
          snapshot.get("users"),
        );

  Map<String, dynamic> toMap() {
    return {
      "text": text,
      "sender": sender,
      "recipient": recipient,
      "timestamp": timestamp,
      "messagesId": messagesId,
      "users": users,
      postId: postId,
    };
  }

  // json
  Map<String, dynamic> toJson() => {
        "text": text,
        "sender": sender,
        "recipient": recipient,
        "timestamp": timestamp,
        "messagesId": messagesId,
        "users": users,
        postId: postId,
      };
}

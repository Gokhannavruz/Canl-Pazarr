import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:Freecycle/screens/profile_screen2.dart';
import 'package:intl/intl.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../models/user.dart';

class MessagesPage extends StatefulWidget {
  final String currentUserUid;
  final String recipientUid;
  final String postId;

  const MessagesPage({
    Key? key,
    required this.currentUserUid,
    required this.recipientUid,
    required this.postId,
  }) : super(key: key);

  @override
  _MessagesPageState createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  late StreamSubscription<QuerySnapshot> _subscription;
  late Key _listKey = UniqueKey();
  User? recipientUser;
  late CollectionReference _messagesCollection;
  late bool _isListViewRendered;
  String currentUserUid = "";
  String PostUid = "";
  String? _senderToken;
  String? _recipientToken;

  late String conversationId =
      widget.currentUserUid.hashCode <= widget.recipientUid.hashCode
          ? "${widget.currentUserUid}-${widget.recipientUid}"
          : "${widget.recipientUid}-${widget.currentUserUid}";

  @override
  void initState() {
    super.initState();
    FirebaseMessaging.instance.onTokenRefresh.listen((String token) {
      print('FCM token refreshed');
      _updateToken(widget.currentUserUid, token);
    });
    // initialize _conversationId
    _isListViewRendered = false;
    getCurrentUserUid();
    getPostUid(widget.postId);
    _loadTokens();
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

  Future<void> _updateToken(String uid, String token) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .update({'fcmToken': token});
      print('Token updated for $uid: $token');
    } catch (e) {
      print('Error updating token: $e');
    }
  }

  Future<void> _loadTokens() async {
    _senderToken = await _getAndUpdateToken(widget.currentUserUid);
    _recipientToken = await _getAndUpdateToken(widget.recipientUid);
  }

  Future<String?> _getToken(String uid) async {
    DocumentSnapshot doc =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();
    print(doc.get('fcmToken'));
    return doc.get('fcmToken');
  }

  Future<String?> _getAndUpdateToken(String uid) async {
    try {
      String? token = await FirebaseMessaging.instance.getToken();
      if (token != null && token.isNotEmpty) {
        // Mevcut token'ı kontrol et
        DocumentSnapshot doc =
            await FirebaseFirestore.instance.collection('users').doc(uid).get();
        String currentToken = doc.get('fcmToken') ?? "";

        // Eğer mevcut token boşsa veya yeni token'dan farklıysa güncelle
        if (currentToken.isEmpty || currentToken != token) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .update({'fcmToken': token});
          print('Updated token for $uid: $token');
        } else {
          print('Token for $uid is up to date');
        }
        return token;
      }
    } catch (e) {
      print('Error getting/updating FCM token: $e');
    }
    return null;
  }

  // reduce cureent user's credit, if post category is "Electronics" reduce 30, else reduce 20
  Future<void> reduceCredit() async {
    DocumentSnapshot doc = await FirebaseFirestore.instance
        .collection("users")
        .doc(widget.currentUserUid)
        .get();
    int credit = doc["credit"];
    if (doc["credit"] >= 30) {
      FirebaseFirestore.instance
          .collection("users")
          .doc(widget.currentUserUid)
          .update({
        "credit": credit - 30,
      });
    } else if (doc["credit"] >= 20) {
      FirebaseFirestore.instance
          .collection("users")
          .doc(widget.currentUserUid)
          .update({
        "credit": credit - 20,
      });
    }
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
  Future<String> getPostUid(String postId) async {
    DocumentSnapshot doc =
        await FirebaseFirestore.instance.collection("posts").doc(postId).get();
    setState(() {
      PostUid = doc["uid"];
    });
    return PostUid;
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
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                widget.postId != ""
                    ? StreamBuilder<DocumentSnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('posts')
                            .doc(widget.postId)
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return const SizedBox.shrink();
                          }
                          final String postUrl = snapshot.data!['postUrl'];
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    widget.postId != ""
                        ? StreamBuilder<DocumentSnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection('posts')
                                .doc(widget.postId)
                                .snapshots(),
                            builder: (context, snapshot) {
                              if (!snapshot.hasData) {
                                return const SizedBox.shrink();
                              }
                              final String category =
                                  snapshot.data!['category'];
                              final String country = snapshot.data!['country'];
                              final String state = snapshot.data!['state'];
                              final String city = snapshot.data!['city'];

                              return Padding(
                                padding: const EdgeInsets.only(left: 8.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(
                                        height:
                                            4), // Burada boşluk ekledim, ihtiyacınıza göre ayarlayabilirsiniz
                                    // location information
                                    if (city != "")
                                      Text(
                                        "- $city, $state, $country",
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.grey,
                                        ),
                                      )
                                    else if (state != "")
                                      Text(
                                        "- $state, $country",
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.grey,
                                        ),
                                      )
                                    else
                                      Text(
                                        "- $country",
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.grey,
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
              ],
            ),
          ),
// confirm button for is this item given this user or not
          PostUid == currentUserUid
              ? StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('posts')
                      .doc(widget.postId)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const SizedBox.shrink();
                    }
                    final bool isGiven = snapshot.data!['isGiven'];
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
                                                    .collection("posts")
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
                    // İF PLATFORM İS REDUCE CREDİT ELSE DO NOT
                    if (Platform.isAndroid) {
                      reduceCredit();
                    }
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
      "credit": credit + 1,
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
      "credit": credit2 - 1,
    });
  }

  void _addMessage(Message message) {
    _messagesCollection.add(message.toMap()).then((value) {
      setState(() {});
    });
  }

  void _handleSubmitted(String text) async {
    _textController.clear();

    // Gönderen kullanıcının token'ını güncelle
    await _updateSenderFCMToken();

    FirebaseFirestore.instance.collection("conversations").add({
      "text": text,
      "sender": widget.currentUserUid,
      "recipient": widget.recipientUid,
      "timestamp": DateTime.now(),
      "messagesId": conversationId,
      "users": [widget.currentUserUid, widget.recipientUid],
      "postId": widget.postId,
    }).then((_) async {});

    // Update the key to force the ListView to rebuild
    _listKey = UniqueKey();

    // load messages from database and if there are none, create a conversation
    _loadMessages();
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

  Future<String?> _updateRecipientFCMToken() async {
    try {
      String? newToken = await FirebaseMessaging.instance.getToken();
      if (newToken != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.recipientUid)
            .update({'fcmToken': newToken});
        _recipientToken = newToken;
        return newToken;
      }
    } catch (e) {
      print('Error updating FCM token: $e');
    }
    return null;
  }

  Future<void> _updateSenderFCMToken() async {
    try {
      String? newToken = await FirebaseMessaging.instance.getToken();
      if (newToken != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.currentUserUid)
            .update({'fcmToken': newToken});
        _senderToken = newToken;
      }
    } catch (e) {
      print('Error updating sender FCM token: $e');
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

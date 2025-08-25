import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:animal_trade/screens/message_screen.dart';
import '../models/user.dart';
import '../utils/animal_colors.dart';
import 'package:google_fonts/google_fonts.dart';

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

  // AdMob kodları kaldırıldı
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
    // AdMob kodu kaldırıldı
    super.dispose();
  }

  Future<void> _getPostIdAndRedirect(String recipientUid) async {
    try {
      String postId = await _getPostId(recipientUid);

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

      // Navigate to MessagesPage
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

  // Helper method to check if post exists
  Future<bool> _postExists(String postId) async {
    if (postId.isEmpty) return false;

    DocumentSnapshot postSnapshot =
        await FirebaseFirestore.instance.collection("posts").doc(postId).get();

    return postSnapshot.exists;
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
      backgroundColor: AnimalColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Mesajlar',
          style: GoogleFonts.poppins(
            color: Color(0xFF212121), // textPrimary
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        iconTheme: IconThemeData(color: AnimalColors.primary),
      ),
      body: Container(
        color: Colors.white,
        child: Column(
          children: [
            Expanded(
              child: FutureBuilder<Map<String, List<Message>>>(
                future: _futureConversations,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: AnimalColors.primary,
                      ),
                    );
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        margin: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: AnimalColors.background,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Color(0xFFE0E0E0), // dividerColor
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.03),
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.inbox_outlined,
                              size: 80,
                              color: AnimalColors.primary.withOpacity(0.7),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              "Gelen kutunuz boş",
                              style: GoogleFonts.poppins(
                                color: Color(0xFF212121),
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              "Diğer kullanıcılarla iletişime geçtiğinizde mesajlar burada görünecek",
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(
                                color: Color(0xFF757575),
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
                          String username = user.username ?? "Kullanıcı";
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
                                borderRadius: BorderRadius.circular(16),
                                child: Container(
                                  padding: EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Color(0xFFFAFAFA), // surfaceColor
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                        color:
                                            Color(0xFFE0E0E0)), // dividerColor
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.03),
                                        blurRadius: 4,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 24,
                                        backgroundImage:
                                            profilePhotoUrl.isNotEmpty
                                                ? NetworkImage(profilePhotoUrl)
                                                : null,
                                        backgroundColor: AnimalColors.secondary
                                            .withOpacity(0.2),
                                        child: profilePhotoUrl.isEmpty
                                            ? Icon(Icons.person,
                                                color: AnimalColors.primary,
                                                size: 28)
                                            : null,
                                      ),
                                      SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              username,
                                              style: GoogleFonts.poppins(
                                                color: Color(0xFF212121),
                                                fontWeight: FontWeight.w600,
                                                fontSize: 16,
                                              ),
                                            ),
                                            SizedBox(height: 4),
                                            Text(
                                              lastMessage.text,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: GoogleFonts.poppins(
                                                color: Color(0xFF757575),
                                                fontSize: 14,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        _formatTimestamp(lastMessage.timestamp),
                                        style: GoogleFonts.poppins(
                                          color: Color(0xFF757575),
                                          fontSize: 12,
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
          ],
        ),
      ),
    );
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

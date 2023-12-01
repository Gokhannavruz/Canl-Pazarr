import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:frees/screens/post_screen.dart';
import 'package:frees/screens/profile_screen2.dart';

class NotificationPage extends StatefulWidget {
  final snap;
  const NotificationPage({Key? key, this.snap}) : super(key: key);

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late String _currentUserId;
  List<Notification> _notifications = [];

  // Initialize the plugin
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();

    _currentUserId = FirebaseAuth.instance.currentUser!.uid;
    _firestore
        .collection('notifications')
        .where("postOwnerId", isEqualTo: _currentUserId)
        .orderBy("date", descending: true)
        .snapshots()
        .listen((snapshot) {
      setState(() {
        _notifications = snapshot.docs
            .map((doc) => Notification.fromMap(doc.data()))
            .toList();

        // show notification
        // if (_notifications.isNotEmpty) {
        //   NotificationService().showNotification(
        //     id: 0,
        //     title: // if notification type is "like" show like text
        //         _notifications[0].type == "liked" ? "like" : "comment",
        //     body: // if notification type is "like" show like text
        //         _notifications[0].type == "liked"
        //             ? "${_notifications[0]}"
        //             : "${_notifications[0]}",
        //   );
        // }
      });
    });
  }

  // dispose
  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        shadowColor: Colors.grey,
        elevation: 0.5,
        backgroundColor: Colors.black,
        title: const Text('Notifications'),
        actions: [
          if (_notifications.isNotEmpty)
            IconButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      // circular edge
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      backgroundColor: const Color.fromARGB(255, 34, 29, 29),
                      title: const Text('Delete All Notifications'),
                      content: const Text(
                          'Are you sure you want to delete all notifications?'),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: const Text(
                            'Cancel',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            _firestore
                                .collection('notifications')
                                .where("postOwnerId", isEqualTo: _currentUserId)
                                .get()
                                .then((snapshot) {
                              for (DocumentSnapshot ds in snapshot.docs) {
                                ds.reference.delete();
                              }
                            });
                            Navigator.pop(context);
                            setState(() {
                              _notifications.clear();
                            });
                          },
                          child: const Text(
                            'Delete',
                            style: TextStyle(
                              color: Colors.red,
                            ),
                          ),
                        ),
                        // remove the notification from the list
                      ],
                    );
                  },
                );
              },
              icon: const Icon(Icons.delete),
              color: Colors.white,
            ),
          const SizedBox(
            width: 15,
          )
        ],
      ),
      body: _notifications.isNotEmpty
          ? ListView.builder(
              itemCount: _notifications.length,
              itemBuilder: (context, index) {
                return ListTile(
                  // onlongpress show the delete option and remove the notification
                  onLongPress: () {
                    showDialog(
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                            // circular edge
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                            backgroundColor:
                                const Color.fromARGB(255, 34, 29, 29),
                            title: const Text('Delete Notification'),
                            content: const Text(
                                'Are you sure you want to delete this notification?'),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                                child: const Text(
                                  'Cancel',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                              TextButton(
                                onPressed: () async {},
                                child: const Text(
                                  'Delete',
                                  style: TextStyle(
                                    color: Colors.red,
                                  ),
                                ),
                              ),
                              // remove the notification from the list
                            ],
                          );
                        });
                  },

                  leading: StreamBuilder<DocumentSnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('users')
                          .doc(_notifications[index].userId)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const CircleAvatar();
                        }
                        final String photoUrl = snapshot.data!['photoUrl'];
                        return InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ProfileScreen2(
                                  userId: _notifications[index].userId,
                                  uid: _currentUserId,
                                  snap: null,
                                ),
                              ),
                            );
                          },
                          child: CircleAvatar(
                            backgroundImage: NetworkImage(photoUrl),
                          ),
                        );
                      }),
                  title: StreamBuilder<DocumentSnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('users')
                          .doc(_notifications[index].userId)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const CircularProgressIndicator();
                        }
                        final String username = snapshot.data!['username'];
                        return InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ProfileScreen2(
                                    snap: null,
                                    uid: _currentUserId,
                                    userId: _notifications[index].userId),
                              ),
                            );
                          },
                          child: Row(
                            children: [
                              _notifications[index].notificationText != ""
                                  ? Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              username,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                            Text(
                                              ' ${_notifications[index].type} your post',
                                              style: const TextStyle(
                                                color: Colors.white,
                                              ),
                                            ),
                                          ],
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Container(
                                            width: MediaQuery.of(context)
                                                    .size
                                                    .width *
                                                0.56,
                                            padding: const EdgeInsets.all(8.0),
                                            decoration: BoxDecoration(
                                              color: const Color.fromARGB(
                                                  255,
                                                  30,
                                                  31,
                                                  31), // burada container rengi seçebilirsiniz
                                              borderRadius:
                                                  BorderRadius.circular(8.0),
                                            ),
                                            child: //notification text in "" because it is a string
                                                Text(
                                              '"${_notifications[index].notificationText}"',
                                              style: const TextStyle(
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    )
                                  : Text(
                                      '$username ${_notifications[index].type} your post',
                                      style:
                                          const TextStyle(color: Colors.white),
                                    ),
                            ],
                          ),
                        );
                      }),
                  subtitle: Text(
                      formatNotificationDate(
                          _notifications[index].date.toDate()),
                      style: const TextStyle(color: Colors.white)),
                  trailing: StreamBuilder<DocumentSnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('posts')
                          .doc(_notifications[index].postId)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const SizedBox.shrink();
                        }
                        final String postImageUrl = snapshot.data!['postUrl'];
                        return InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PostScreen(
                                  postId: _notifications[index].postId,
                                  uid: _notifications[index].postOwnerId,
                                ),
                              ),
                            );
                          },
                          child: SizedBox(
                            width: 48.0,
                            height: 48.0,
                            child: Image.network(
                              postImageUrl,
                              fit: BoxFit.cover,
                            ),
                          ),
                        );
                      }),
                );
              },
            )
          : // awaait 2 seconds and show the text
          const Padding(
              padding: EdgeInsets.all(20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "isn't too quiet?",
                    style: TextStyle(
                      color: Color.fromARGB(255, 166, 160, 160),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

String formatNotificationDate(DateTime notificationDate) {
  initializeDateFormatting(Intl.defaultLocale);
  final now = DateTime.now();
  final difference = now.difference(notificationDate);

  if (difference.inDays >= 1) {
    return DateFormat.yMMMd().format(notificationDate);
  } else if (difference.inHours >= 1) {
    return '${difference.inHours}h';
  } else if (difference.inMinutes >= 1) {
    return '${difference.inMinutes}m';
  } else {
    return 'Just now';
  }
}

class Notification {
  final String type;
  final String postId;
  final String postOwnerId;
  final String userId;
  final String notificationText;

  final Timestamp date;

  Notification(
      {required this.type,
      required this.postId,
      required this.postOwnerId,
      required this.userId,
      required this.date,
      this.notificationText = ""});

  factory Notification.fromMap(Map<String, dynamic> data) {
    return Notification(
      type: data['type'],
      postId: data['postId'],
      postOwnerId: data['postOwnerId'],
      userId: data['userId'],
      date: data['date'],
      notificationText: data['notificationText'],
    );
  }
}

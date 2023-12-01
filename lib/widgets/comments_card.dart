import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:intl/intl.dart';

import '../screens/profile_screen2.dart';

class CommentCard extends StatefulWidget {
  final snap;
  const CommentCard({
    Key? key,
    required this.snap,
  }) : super(key: key);

  @override
  State<CommentCard> createState() => _CommentCardState();
}

class _CommentCardState extends State<CommentCard> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: 18,
        horizontal: 16,
      ),
      child: Row(
        children: [
          InkWell(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProfileScreen2(
                  userId: widget.snap["uid"],
                  snap: null,
                  uid: widget.snap["uid"],
                ),
              ),
            ),
            child: // user profile photo with stream builder
                StreamBuilder(
              stream: FirebaseFirestore.instance
                  .collection("users")
                  .doc(widget.snap["uid"])
                  .snapshots(),
              builder: (context, AsyncSnapshot snapshot) {
                if (snapshot.hasData) {
                  return CircleAvatar(
                    backgroundImage: NetworkImage(snapshot.data["photoUrl"]),
                    radius: 20,
                  );
                } else {
                  return const CircleAvatar(
                      backgroundColor: Colors.black, radius: 20);
                }
              },
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(
                left: 16,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  InkWell(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProfileScreen2(
                          userId: FirebaseAuth.instance.currentUser!.uid,
                          snap: User,
                          uid: widget.snap["uid"],
                        ),
                      ),
                    ),
                    child: StreamBuilder(
                      stream: FirebaseFirestore.instance
                          .collection("users")
                          .doc(widget.snap["uid"])
                          .snapshots(),
                      builder: (context, AsyncSnapshot snapshot) {
                        if (snapshot.hasData) {
                          return Row(
                            children: [
                              Text(
                                snapshot.data["username"],
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                widget.snap["text"],
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                          );
                        } else {
                          return const CircleAvatar(
                              backgroundColor: Colors.black, radius: 20);
                        }
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      DateFormat.yMMMd()
                          .format(widget.snap["datePublished"].toDate()),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Container(
          //   padding: const EdgeInsets.all(8),
          //   child: const Icon(
          //     Icons.favorite,
          //     size: 16,
          //   ),
          // ),
        ],
      ),
    );
  }
}

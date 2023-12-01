import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../widgets/post_card.dart';

class RecipientScreen extends StatefulWidget {
  final String userId;

  const RecipientScreen({Key? key, required this.userId}) : super(key: key);

  @override
  RecipientScreenState createState() => RecipientScreenState();
}

class RecipientScreenState extends State<RecipientScreen> {
// LİKED LİST
  late List<String> recipientList;
  // current user id
  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;

  @override
  void initState() {
    super.initState();
    recipientList = []; // moved this line up
    getrecipientList();
  }

  // get liked list from firestore posts collection and add to likes list
  Future<void> getrecipientList() async {
    await FirebaseFirestore.instance
        .collection('posts')
        .where('recipient', isEqualTo: widget.userId)
        .get()
        .then((value) {
      for (var element in value.docs) {
        setState(() {
          recipientList.add(element.id);
        });
      }
    });
    // if post doesn't exist, remove from liked list and delete from posts collection
    for (var postId in recipientList) {
      FirebaseFirestore.instance
          .collection('posts')
          .doc(postId)
          .get()
          .then((value) {
        if (!value.exists) {
          setState(() {
            recipientList.remove(postId);
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // if liked list is empty show elevation 0.6
        // else show 'Liked Posts'
        elevation: recipientList.isEmpty ? 0.6 : 0,
        shadowColor: Colors.grey,
        title: const Text('Tagged Posts'),
        backgroundColor: Colors.black,
      ),
      body: // show liked post as postcard in ListView
          recipientList == null
              ? const Center(child: CircularProgressIndicator())
              : recipientList.isEmpty
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          height: 60,
                        ),
                        Row(
                          children: [
                            Icon(Icons.person_pin_circle_outlined, size: 25),
                            SizedBox(
                              width: 5,
                            ),
                            Text('No tagged posts',
                                style: TextStyle(fontSize: 15)),
                          ],
                        ),
                      ],
                    )
                  : ListView.builder(
                      itemCount: recipientList.length,
                      itemBuilder: (context, index) {
                        return StreamBuilder<DocumentSnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('posts')
                              .doc(recipientList[index])
                              .snapshots(),
                          builder: (context, snapshot) {
                            if (snapshot.hasData) {
                              // RETURN POSTCARD

                              return PostCard(
                                  isBlocked: false,
                                  isGridView: false,
                                  snap: snapshot.data!);
                            } else {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }
                          },
                        );
                      },
                    ),
    );
  }
}

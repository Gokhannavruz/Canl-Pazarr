import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../widgets/post_card.dart';

class SavedPostsScreen extends StatefulWidget {
  final String userId;

  const SavedPostsScreen({Key? key, required this.userId}) : super(key: key);

  @override
  _SavedPostsScreenState createState() => _SavedPostsScreenState();
}

class _SavedPostsScreenState extends State<SavedPostsScreen> {
  late List<String> savedList;
  final currentUser = FirebaseAuth.instance.currentUser!.uid;

  @override
  void initState() {
    super.initState();
    savedList = [];
    getSavedList();
  }

  Future<void> getSavedList() async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser)
        .collection('savedPosts')
        .get()
        .then((value) {
      if (value.docs.isEmpty) {
        setState(() {
          // Kaydedilen gönderi yoksa, savedPostIds listesi boş kalacak
        });
      } else {
        for (var doc in value.docs) {
          setState(() {
            savedList.add(doc.id);
          });
        }

        // if post doesn't exist, remove from saved list and delete from savedPosts collection
        for (var postId in savedList) {
          FirebaseFirestore.instance
              .collection('posts')
              .doc(postId)
              .get()
              .then((value) {
            if (!value.exists) {
              setState(() {
                savedList.remove(postId);
              });
            }
          });
        }
      }
      // if post deleted, remove from saved list
      FirebaseFirestore.instance
          .collection('posts')
          .where('isDeleted', isEqualTo: true)
          .get()
          .then((value) {
        for (var doc in value.docs) {
          if (savedList.contains(doc.id)) {
            setState(() {
              savedList.remove(doc.id);
            });
          }
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: savedList.isEmpty ? 0.6 : 0,
        shadowColor: Colors.grey,
        title: const Text('Saved Posts'),
        backgroundColor: Colors.black,
      ),
      body: savedList == null
          ? const Center(child: CircularProgressIndicator())
          : savedList.isEmpty
              ? const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      height: 60,
                    ),
                    Row(
                      children: [
                        Icon(Icons.bookmark_outline, size: 20),
                        SizedBox(
                          width: 5,
                        ),
                        Text(
                          'You haven\'t saved any posts yet',
                          style: TextStyle(fontSize: 15),
                        ),
                      ],
                    ),
                  ],
                )
              : ListView.builder(
                  itemCount: savedList.length,
                  itemBuilder: (context, index) {
                    return StreamBuilder<DocumentSnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('posts')
                          .doc(savedList[index])
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.hasData) {
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

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../widgets/post_card.dart';

class LikedPostsScreen extends StatefulWidget {
  final String userId;

  const LikedPostsScreen({Key? key, required this.userId}) : super(key: key);

  @override
  _LikedPostsScreenState createState() => _LikedPostsScreenState();
}

class _LikedPostsScreenState extends State<LikedPostsScreen> {
// LİKED LİST
  late List<String> likedList;

  @override
  void initState() {
    super.initState();
    likedList = []; // moved this line up
    getLikedList();
  }

  // get liked list from firestore posts collection and add to likes list
  Future<void> getLikedList() async {
    await FirebaseFirestore.instance
        .collection('posts')
        .where('likes', arrayContains: widget.userId)
        .get()
        .then((value) {
      for (var element in value.docs) {
        setState(() {
          likedList.add(element.id);
        });
      }
    });
    // if post doesn't exist, remove from liked list and delete from posts collection
    for (var postId in likedList) {
      FirebaseFirestore.instance
          .collection('posts')
          .doc(postId)
          .get()
          .then((value) {
        if (!value.exists) {
          setState(() {
            likedList.remove(postId);
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
        elevation: likedList.isEmpty ? 0.6 : 0,
        shadowColor: Colors.grey,
        title: const Text('Liked Posts'),
        backgroundColor: Colors.black,
      ),
      body: // show liked post as postcard in ListView
          likedList == null
              ? const Center(child: CircularProgressIndicator())
              : likedList.isEmpty
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          height: 60,
                        ),
                        Row(
                          children: [
                            Icon(Icons.keyboard_arrow_down, size: 30),
                            SizedBox(
                              width: 5,
                            ),
                            Text('You haven\'t liked any posts yet',
                                style: TextStyle(fontSize: 15)),
                          ],
                        ),
                      ],
                    )
                  : ListView.builder(
                      itemCount: likedList.length,
                      itemBuilder: (context, index) {
                        return StreamBuilder<DocumentSnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('posts')
                              .doc(likedList[index])
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

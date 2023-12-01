import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class PopularPostCard extends StatelessWidget {
  const PopularPostCard(
      {Key? key,
      required String id,
      required userId,
      required description,
      required title,
      required imageUrl,
      required likes,
      required comments,
      required shares})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: FirebaseFirestore.instance
          .collection("posts")
          .orderBy("likes", descending: true)
          .limit(1)
          .snapshots(),
      builder: (context,
          AsyncSnapshot<QuerySnapshot<Map<String, dynamic>>> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        DocumentSnapshot snap = snapshot.data!.docs[0];
        return Container(
          padding: const EdgeInsets.all(8),
          child: Column(
            children: [
              Text(
                "Popular post",
                style: Theme.of(context).textTheme.titleLarge,
              ),
              Image(
                image: NetworkImage(snap['postUrl']),
                fit: BoxFit.cover,
              ),
              Text(
                snap['caption'],
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(
                "${snap['likes']} likes",
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ],
          ),
        );
      },
    );
  }
}

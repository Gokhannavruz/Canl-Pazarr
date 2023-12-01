// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:frees/screens/profile_screen2.dart';

class FollowingListScreen extends StatefulWidget {
  final String userId;

  const FollowingListScreen({Key? key, required this.userId}) : super(key: key);

  @override
  _FollowingListScreenState createState() => _FollowingListScreenState();
}

class _FollowingListScreenState extends State<FollowingListScreen> {
  late List<String> followingList;

  @override
  void initState() {
    super.initState();
    getFollowingList();
    followingList = [];
  }

  void getFollowingList() async {
    DocumentSnapshot<Map<String, dynamic>> documentSnapshot =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.userId)
            .get();
    Map<String, dynamic> data = documentSnapshot.data()!;
    setState(() {
      followingList = List<String>.from(data['following']);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Following List'),
        backgroundColor: Colors.black,
      ),
      body: followingList == null
          ? const Center(child: CircularProgressIndicator())
          : followingList.isEmpty
              ? widget.userId == FirebaseAuth.instance.currentUser!.uid
                  ? const Center(
                      child: Text("You're not following anyone yet"),
                    )
                  : const Center(
                      child: Text('This user is not following anyone yet'),
                    )
              : ListView.builder(
                  itemCount: followingList.length,
                  itemBuilder: (BuildContext context, int index) {
                    return FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('users')
                          .doc(followingList[index])
                          .get(),
                      builder: (BuildContext context,
                          AsyncSnapshot<DocumentSnapshot> snapshot) {
                        if (snapshot.connectionState == ConnectionState.done) {
                          Map<String, dynamic> data =
                              snapshot.data!.data() as Map<String, dynamic>;
                          return Column(
                            children: [
                              ListTile(
                                leading: CircleAvatar(
                                  radius: 30,
                                  backgroundImage: NetworkImage(
                                    data['photoUrl'],
                                  ),
                                ),
                                title: Text(data['username']),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ProfileScreen2(
                                        snap: data,
                                        userId: widget.userId,
                                        uid: followingList[index],
                                      ),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(
                                height: 5,
                              ),
                            ],
                          );
                        }
                        return const Center(child: CircularProgressIndicator());
                      },
                    );
                  },
                ),
    );
  }
}

// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:frees/screens/profile_screen2.dart';


class FollowersListScreen extends StatefulWidget {
  final String userId;

  const FollowersListScreen({Key? key, required this.userId}) : super(key: key);

  @override
  _FollowersListScreenState createState() => _FollowersListScreenState();
}

class _FollowersListScreenState extends State<FollowersListScreen> {
  late List<String> followersList;

  @override
  void initState() {
    super.initState();
    getFollowersList();
    followersList = [];
  }

  void getFollowersList() async {
    DocumentSnapshot<Map<String, dynamic>> documentSnapshot =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.userId)
            .get();
    Map<String, dynamic> data = documentSnapshot.data()!;
    setState(() {
      followersList = List<String>.from(data['followers']);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Followers List'),
        backgroundColor: Colors.black,
      ),
      body: followersList == null
          ? const Center(child: CircularProgressIndicator())
          : followersList.isEmpty // takipçi yoksa
              ? // if this yourprofile show this
              widget.userId == FirebaseAuth.instance.currentUser!.uid
                  ? const Center(
                      child: Text('You have no followers yet'),
                    )
                  : const Center(
                      child: Text('This user has no followers yet'),
                    )
              : ListView.builder(
                  itemCount: followersList.length,
                  itemBuilder: (BuildContext context, int index) {
                    return FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('users')
                          .doc(followersList[index])
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
                                  radius: 25,
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
                                        uid: followersList[index],
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

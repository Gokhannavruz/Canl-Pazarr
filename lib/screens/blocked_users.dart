import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'package:freecycle/screens/profile_screen2.dart';

class BlockedListScreen extends StatefulWidget {
  final String userId;

  const BlockedListScreen({Key? key, required this.userId}) : super(key: key);

  @override
  _BlockedListScreenState createState() => _BlockedListScreenState();
}

class _BlockedListScreenState extends State<BlockedListScreen> {
  late List<String> blockedList;

  @override
  void initState() {
    super.initState();
    getBlockedList();
    blockedList = [];
  }

  void getBlockedList() async {
    DocumentSnapshot<Map<String, dynamic>> documentSnapshot =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.userId)
            .get();
    Map<String, dynamic> data = documentSnapshot.data()!;
    setState(() {
      blockedList = List<String>.from(data['blocked']);
    });

    //if user doesn't exist, remove from blocked list
    for (var userId in blockedList) {
      FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get()
          .then((value) {
        if (!value.exists) {
          setState(() {
            blockedList.remove(userId);
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0.6,
        shadowColor: Colors.grey,
        title: const Text('Blocked users'),
        backgroundColor: Colors.black,
      ),
      body: blockedList == null
          ? const Center(child: CircularProgressIndicator())
          : blockedList.isEmpty
              ? const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      height: 60,
                    ),
                    Row(
                      children: [
                        Icon(
                          Icons.person_off_outlined,
                          size: 20,
                        ),
                        SizedBox(
                          width: 5,
                        ),
                        Text('You haven\'t blocked anyone yet',
                            style: TextStyle(
                              fontSize: 15,
                            )),
                      ],
                    ),
                  ],
                )
              : ListView.builder(
                  itemCount: blockedList.length,
                  itemBuilder: (BuildContext context, int index) {
                    return FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('users')
                          .doc(blockedList[index])
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
                                        uid: blockedList[index],
                                      ),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(
                                  height: 2), // added SizedBox widget
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

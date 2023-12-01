import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


class SearchForMessageScreen extends StatefulWidget {
  const SearchForMessageScreen({Key? key}) : super(key: key);

  @override
  State<SearchForMessageScreen> createState() => _SearchForMessageScreenState();
}

class _SearchForMessageScreenState extends State<SearchForMessageScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _searchTerm = '';
  late String username = '';
  // current user uid
  final String uid = FirebaseFirestore.instance.collection('users').doc().id;
  final String userId = FirebaseFirestore.instance.collection('users').doc().id;

  @override
  void initState() {
    super.initState();
    // get currentuser username and set it to username
    FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .get()
        .then((value) {
      setState(() {
        username = value.data()!['username'];
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 50,
        shape: const RoundedRectangleBorder(
          // top left and right radius
          borderRadius: BorderRadius.all(
            Radius.circular(13),
          ),
        ),
        elevation: 0.4,
        shadowColor: Colors.grey,
        backgroundColor: Colors.grey[900],
        title: TextField(
          style: const TextStyle(fontSize: 15),
          controller: _searchController,
          focusNode: _searchFocusNode,
          decoration: const InputDecoration(
            border: InputBorder.none,
            hintText: 'Search users by username',
          ),
          onChanged: (value) {
            setState(() {
              _searchTerm = value;
            });
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: StreamBuilder(
          stream: _searchTerm.isEmpty
              ? null
              : FirebaseFirestore.instance
                  .collection("users")
                  .orderBy('username')
                  .where('username', isNotEqualTo: username)
                  .startAt([_searchTerm]).endAt(
                      ['$_searchTerm\uf8ff']).snapshots(),
          builder: (context,
              AsyncSnapshot<QuerySnapshot<Map<String, dynamic>>> snapshot) {
            if (_searchTerm.isEmpty) {
              return const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(height: 30),
                  Text(
                    'Search for users to start a chat',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 13,
                    ),
                  ),
                ],
              );
            }
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }
            return ListView.builder(
              itemCount: snapshot.data!.docs.length,
              itemBuilder: (context, index) {
                final user = snapshot.data!.docs[index].data();
                return Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: InkWell(
                    onTap: () {
                      // Navigator.push(
                      //   context,
                      //   MaterialPageRoute(
                      //     builder: (context) => MessagesPage(
                      //         currentUserUid:
                      //             FirebaseAuth.instance.currentUser!.uid,
                      //         recipientUid: user['uid']),
                      //   ),
                      // );
                    },
                    child: Row(
                      children: [
                        InkWell(
                          onTap: () {
                            // Navigator.push(
                            //   context,
                            //   MaterialPageRoute(
                            //     builder: (context) => MessagesPage(
                            //         currentUserUid:
                            //             FirebaseAuth.instance.currentUser!.uid,
                            //         recipientUid: user['uid']),
                            //   ),
                            // );
                          },
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 27,
                                backgroundImage: NetworkImage(
                                  user['photoUrl'],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(
                          width: 10,
                        ),
                        InkWell(
                          onTap: () {
                            // Navigator.push(
                            //   context,
                            //   MaterialPageRoute(
                            //       builder: (context) => MessagesPage(
                            //           currentUserUid: FirebaseAuth
                            //               .instance.currentUser!.uid,
                            //           recipientUid: user['uid'])),
                            // );
                          },
                          child: Text(user['username'],
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              )),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

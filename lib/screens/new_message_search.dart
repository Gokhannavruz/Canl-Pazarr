import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:frees/screens/profile_screen2.dart';


class SearchScreenForMessage extends StatefulWidget {
  const SearchScreenForMessage({Key? key}) : super(key: key);

  @override
  State<SearchScreenForMessage> createState() => _SearchScreenForMessageState();
}

class _SearchScreenForMessageState extends State<SearchScreenForMessage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _searchTerm = '';

  // get the current user from firebase
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0.4,
        shadowColor: Colors.grey,
        backgroundColor: Colors.black,
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
                    'Try searching for new frees friends',
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
                  child: Row(
                    children: [
                      InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ProfileScreen2(
                                uid: user['uid'],
                                snap: user,
                                userId: user['uid'],
                              ),
                            ),
                          );
                        },
                        child: CircleAvatar(
                          radius: 30,
                          backgroundImage: NetworkImage(
                            user['photoUrl'],
                          ),
                        ),
                      ),
                      const SizedBox(
                        width: 10,
                      ),
                      InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ProfileScreen2(
                                uid: user['uid'],
                                snap: user,
                                userId: user['uid'],
                              ),
                            ),
                          );
                        },
                        child: Text(user['username']),
                      ),
                      // for message button
                      const Spacer(),
                      IconButton(
                        onPressed: () {
                          // Navigator.push(
                          //   context,
                          //   MaterialPageRoute(
                          //     builder: (context) => MessagesPage(
                          //       currentUserUid:
                          //           FirebaseAuth.instance.currentUser!.uid,
                          //       recipientUid: user['uid'],
                          //     ),
                          //   ),
                          // );
                        },
                        icon: const Icon(Icons.message),
                      ),
                    ],
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

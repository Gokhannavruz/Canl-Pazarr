// import 'dart:math';

// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';

// class MatchPage extends StatefulWidget {
//   @override
//   _MatchPageState createState() => _MatchPageState();
// }

// class _MatchPageState extends State<MatchPage> {
//   bool _matching = false;
//   late String _matchError;
//   late User _matchedUser;
//   late User _currentUser;

//   @override
//   void initState() {
//     super.initState();
//     _loadCurrentUser();
//   }

//   void _loadCurrentUser() async {
//     var currentUser = FirebaseAuth.instance.currentUser;
//     var currentUserData = await FirebaseFirestore.instance
//         .collection('users')
//         .doc(currentUser!.uid)
//         .get();
//     _currentUser = FirebaseFirestore.instance.currentUser.uid;
//     setState(() {});
//   }

//   Future<void> _initiateMatch() async {
//     if (_matching) return;
//     setState(() {
//       _matching = true;
//     });

//     // Check if the user has reached the maximum number of matches allowed
//     if (_currentUser.matchCount >= 2 && !_currentUser.isPremium) {
//       setState(() {
//         _matchError = 'You need to be premium to make more than 2 matches';
//         _matching = false;
//       });
//       return;
//     }

//     // Check if the user has to wait before making another match
//     int currentTimestamp = DateTime.now().millisecondsSinceEpoch;
//     int remainingTime = (_currentUser.lastMatchTimestamp + 604800000) -
//         currentTimestamp; // 1 week in milliseconds
//     if (remainingTime > 0) {
//       setState(() {
//         _matchError =
//             'You need to wait ${remainingTime ~/ 86400000} days before making another match';
//         _matching = false;
//       });
//       return;
//     }

//     // Query the database for users that have not been matched with the current user
//     var users = await FirebaseFirestore.instance
//         .collection('users')
//         .where('matchedWith', isNull: true)
//         .get();

//     if (users.size == 0) {
//       setState(() {
//         _matchError = 'There are no users available to match with';
//         _matching = false;
//       });
//       return;
//     }

//     // Select a random user from the query
//     var randomIndex = Random().nextInt(users.size);
//     var matchedUserData = users.docs[randomIndex];
//     _matchedUser = User.fromSnap(matchedUserData);

//     // Update the matchedWith field for both users
//     var matchRef = matchedUserData.reference;
//     var currentUserRef =
//         FirebaseFirestore.instance.collection('users').doc(currentUser.uid);
//     await matchRef.updateData({'matchedWith': currentUser.uid});
//     await currentUserRef.updateData({'matchedWith': matchedUserData.id});

//     // Increment the match count for both users
//     await matchRef
//         .updateData({'matchCount': matchedUserData.data()['matchCount'] + 1});
//     await currentUserRef
//         .updateData({'matchCount': currentUserData.data()['matchCount'] + 1});

//     // Update the last match timestamp for both users
//     int timestamp = DateTime.now().millisecondsSinceEpoch;
//     await matchRef.updateData({'lastMatchTimestamp': timestamp});
//     await currentUserRef.updateData({'lastMatchTimestamp': timestamp});

//     setState(() {
//       _matching = false;
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//         body: Center(
//       child: _matching
//           ? CircularProgressIndicator()
//           : _matchedUser != null
//               ? Column(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: <Widget>[
//                     Text(
//                       'You have been matched with',
//                       style: TextStyle(fontSize: 18, color: Colors.black),
//                     ),
//                     SizedBox(height: 10),
//                     Text(_matchedUser.username,
//                         style: TextStyle(
//                             fontSize: 24,
//                             fontWeight: FontWeight.bold,
//                             color: Colors.black)),
//                     SizedBox(height: 10),
//                     CircleAvatar(
//                       backgroundImage: NetworkImage(_matchedUser.photoUrl),
//                       radius: 50,
//                     ),
//                   ],
//                 )
//               : _matchError != null
//                   ? Column(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: <Widget>[
//                         Text(_matchError,
//                             style: TextStyle(
//                                 fontSize: 18,
//                                 color: Colors.red,
//                                 fontWeight: FontWeight.bold)),
//                         SizedBox(height: 10),
//                         RaisedButton(
//                             child: Text('Try again'),
//                             onPressed: _loadCurrentUser)
//                       ],
//                     )
//                   : Column(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: <Widget>[
//                         RaisedButton(
//                             child: Text('Initiate match'),
//                             onPressed: _initiateMatch),
//                       ],
//                     ),
//     ));
//   }
// }

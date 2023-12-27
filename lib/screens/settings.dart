import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:Freecycle/screens/blocked_users.dart';
import 'package:Freecycle/screens/liked_posts_screen.dart';
import 'package:Freecycle/screens/login_screen.dart';

import 'package:Freecycle/screens/reset_password.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Row(
          children: [
            Text('Settings'),
          ],
        ),
      ),
      body: ListView(
        children: [
          Card(
            color: Colors.black,
            child: ListTile(
              // icon and text for liked posts
              title: const Row(
                children: [
                  Icon(Icons.favorite_border_outlined, size: 25),
                  SizedBox(width: 10),
                  Text('Favorites'),
                ],
              ),
              onTap: () {
                // Navigate to blocked users page
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => LikedPostsScreen(
                      userId: FirebaseAuth.instance.currentUser!.uid,
                    ),
                  ),
                );
              },
            ),
          ),
          // Card(
          //   color: Colors.black,
          //   child: ListTile(
          //     // icon and text for liked posts
          //     title: Row(
          //       children: const [
          //         Icon(Icons.person_pin_circle_outlined, size: 25),
          //         SizedBox(width: 10),
          //         Text('Tagged posts'),
          //       ],
          //     ),
          //     onTap: () {
          //       // Navigate to blocked users page
          //       Navigator.push(
          //         context,
          //         MaterialPageRoute(
          //           builder: (context) => RecipientScreen(
          //             userId: FirebaseAuth.instance.currentUser!.uid,
          //           ),
          //         ),
          //       );
          //     },
          //   ),
          // ),
          Card(
            color: Colors.black,
            child: ListTile(
              title: const Row(
                children: [
                  Icon(
                    Icons.person_off_outlined,
                    size: 25,
                  ),
                  SizedBox(width: 10),
                  Text('Blocked Users'),
                ],
              ),
              onTap: () {
                // Navigate to blocked users page
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BlockedListScreen(
                      userId: FirebaseAuth.instance.currentUser!.uid,
                    ),
                  ),
                );
              },
            ),
          ),
          InkWell(
            child: Card(
              color: Colors.black,
              child: ListTile(
                title: const Row(
                  children: [
                    Icon(
                      Icons.lock_outline_sharp,
                      color: Colors.white,
                    ),
                    SizedBox(width: 10),
                    Text('Change Password'),
                  ],
                ),
                onTap: () {
                  // navigate to change password page
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const ForgetPassword(),
                    ),
                  );
                },
              ),
            ),
          ),
          InkWell(
            child: Card(
              color: Colors.black,
              child: ListTile(
                title: const Row(
                  children: [
                    Icon(
                      Icons.delete_forever,
                      color: Colors.red,
                    ),
                    SizedBox(width: 10),
                    Text('Delete account'),
                  ],
                ),
                onTap: () {
                  // Show confirm delete account dialog
                  deleteAccount(context);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  void deleteAccount(BuildContext context) async {
    // Show confirmation dialog
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        backgroundColor: const Color.fromARGB(255, 24, 22, 22),
        title: const Text('Delete account'),
        content: const Text(
            'Are you sure you want to delete your account? \n \n If you delete your account, you will lose all your data and you will not be able to use your phone number again.'),
        actions: [
          TextButton(
            child: const Text('Cancel', style: TextStyle(color: Colors.white)),
            onPressed: () => Navigator.pop(context, false),
          ),
          TextButton(
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (confirm) {
      // Delete user data from database but create deleted user document and save user data in it
      await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .get()
          .then(
        (doc) {
          if (doc.exists) {
            // Create deleted user document
            FirebaseFirestore.instance
                .collection('deleted_users')
                .doc(FirebaseAuth.instance.currentUser!.uid)
                .set(doc.data()!);

            // Delete user document
            FirebaseFirestore.instance
                .collection('users')
                .doc(FirebaseAuth.instance.currentUser!.uid)
                .delete();
          }
        },
      );
      // Sign out user
      await FirebaseAuth.instance.signOut();

      // Navigate to login page with material page route
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => const LoginScreen(),
        ),
        (route) => false,
      );
    }
  }
  // blocked users lists
}

import 'package:freecycle/screens/discoverPage2.dart';
import 'package:freecycle/screens/discover_jobs_page.dart';
import 'package:freecycle/screens/welcomepage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:freecycle/screens/add_post_screen.dart';
import 'package:freecycle/screens/incoming_messages.dart';
import 'package:freecycle/screens/profile_screen2.dart';

// Web ekran boyutu eşik değeri - 900 piksel genişliğinden büyük ekranlar web düzeni kullanacak
const webScreenSize = 9000;

List<Widget> homeScreenItem = [
  const DiscoverPage2(),
  IncomingMessagesPage(
      currentUserUid: FirebaseAuth.instance.currentUser?.uid ?? ''),
  const AddPostScreen(),
  StreamBuilder<DocumentSnapshot>(
    stream: FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser?.uid)
        .snapshots(),
    builder: (context, snapshot) {
      if (snapshot.hasData) {
        return ProfileScreen2(
          uid: FirebaseAuth.instance.currentUser?.uid ?? '',
          snap: snapshot.data,
          userId: FirebaseAuth.instance.currentUser?.uid ?? '',
        );
      } else {
        return const Center(
          child: SizedBox(
            height: 50,
            width: 50,
            child: CircularProgressIndicator(
              strokeWidth: 4,
            ),
          ),
        );
      }
    },
  )
];

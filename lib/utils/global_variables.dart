import 'package:animal_trade/screens/animal_discover_screen.dart';
import 'package:animal_trade/screens/add_animal_screen.dart';
import 'package:animal_trade/screens/veterinarian_discover_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:animal_trade/screens/incoming_messages.dart';
import 'package:animal_trade/screens/profile_screen2.dart';

// Web ekran boyutu eşik değeri - 900 piksel genişliğinden büyük ekranlar web düzeni kullanacak
const webScreenSize = 9000;

List<Widget> homeScreenItem = [
  const AnimalDiscoverScreen(), // Ana hayvan listesi sayfası
  IncomingMessagesPage(
      // Hayvan mesajlaşma
      currentUserUid: FirebaseAuth.instance.currentUser?.uid ?? ''),
  const AddAnimalScreen(), // Hayvan ilanı ekleme sayfası
  const VeterinarianDiscoverScreen(), // Veteriner discover sayfası
  StreamBuilder<DocumentSnapshot>(
    // Çiftçi profili
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

// Ana navigasyon ikonları
const List<IconData> navIcons = [
  Icons.home, // Ana sayfa
  Icons.message, // Mesajlar
  Icons.add_circle_outline, // İlan ekle
  Icons.local_hospital, // Veterinerler
  Icons.person, // Profil
];

// Navigasyon etiketleri
const List<String> navLabels = [
  'Hayvanlar',
  'Mesajlar',
  'İlan Ekle',
  'Veterinerler',
  'Profil',
];

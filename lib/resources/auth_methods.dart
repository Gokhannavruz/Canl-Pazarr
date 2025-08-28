import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:animal_trade/models/user.dart' as model;
import 'package:animal_trade/resources/storage_methods.dart';

class AuthMethods {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String photoUrl =
      "https://firebasestorage.googleapis.com/v0/b/canlipazar-b3697.firebasestorage.app/o/defaulprofilephoto%2FdefaultProfilePhoto.png?alt=media&token=f2500621-2916-4601-bcbe-93c63d7fa802";

  // get user details
  Future<model.User> getUserDetails() async {
    User currentUser = _auth.currentUser!;
    return await getUserDetailsFromFirestore(currentUser.uid);
  }

  // Get user details from Firestore using uid
  Future<model.User> getUserDetailsFromFirestore(String uid) async {
    try {
      DocumentSnapshot documentSnapshot =
          await _firestore.collection('users').doc(uid).get();

      if (documentSnapshot.exists) {
        return model.User.fromSnap(documentSnapshot);
      } else {
        // Return a default user if document doesn't exist
        return model.User(
          username: "",
          uid: uid,
          email: "",
          bio: "",
          followers: [],
          following: [],
          blocked: [],
          blockedBy: [],
        );
      }
    } catch (e) {
      print("Error getting user details: $e");
      // Return a default user on error
      return model.User(
        username: "",
        uid: uid,
        email: "",
        bio: "",
        followers: [],
        following: [],
        blocked: [],
        blockedBy: [],
      );
    }
  }

  // Signing Up User
  Future<String> signUpUser({
    required String email,
    required String password,
    required String username,
    required String bio,
    required Uint8List? file,
  }) async {
    String res = "Some error Occurred";
    try {
      if (password.length < 6) {
        res = "Password should be at least 6 characters long";
      } else if (!RegExp(r"^[a-z0-9_]+$").hasMatch(username) ||
          username.contains(" ")) {
        res =
            "Username should be with small letters, shouldn't include any special character and space";
      } else if (username.isEmpty || username.length > 25) {
        res = "Username should be between 1 and 25 characters long";
      } else if (bio.length > 100) {
        res = "Bio should be at most 150 characters long";
      } else {
        // Create user with email and password
        UserCredential cred = await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );

        // Prepare profile picture
        if (file != null) {
          photoUrl = await StorageMethods()
              .uploadImageToStorage('profilePics', file, true);
        } else {
          photoUrl =
              "https://firebasestorage.googleapis.com/v0/b/canlipazar-b3697.firebasestorage.app/o/defaulprofilephoto%2FdefaultProfilePhoto.png?alt=media&token=f2500621-2916-4601-bcbe-93c63d7fa802";
        }

        // Prepare user data as a Map directly, avoiding potential issues with User model
        final userData = {
          'username': username,
          'uid': cred.user!.uid,
          'photoUrl': photoUrl,
          'email': email,
          'bio': bio,
          'matched_with': null,
          'followers': [],
          'following': [],
          'blocked': [],
          'blockedBy': [],
          'country': "",
          'state': "",
          'city': "",
          'match_count': 0,
          'is_premium': false,
          'number_of_sent_gifts': 0,
          'number_of_unsent_gifts': 0,
          'gift_sending_rate': "",
          'isVerified': false,
          'isConfirmed': false,
          'gift_point': 0.0,
          'isRated': false,
          'rateCount': 0,
          'fcmToken': "",
          'credit': 0,
          'referralCode': "",
          'referredBy': "",
        };

        // Save user data to Firestore
        await _firestore.collection("users").doc(cred.user!.uid).set(userData);

        res = "success";
      }
    } catch (err) {
      print("Error during signup: $err");
      return err.toString();
    }
    return res;
  }

  // logging in user
  Future<String> loginUser({
    required String email,
    required String password,
  }) async {
    String res = "Some error Occurred";
    try {
      if (email.isNotEmpty || password.isNotEmpty) {
        FirebaseAuth.instance.idTokenChanges().listen((User? user) {
          if (user == null) {
            print('User is currently signed out!');
          } else {
            print('User is signed in!');
          }
        });

        QuerySnapshot deletedUserQuery = await _firestore
            .collection("deleted_users")
            .where("email", isEqualTo: email)
            .get();
        if (deletedUserQuery.docs.isNotEmpty) {
          res = "Deleted account. Please contact support";
        } else {
          await _auth.signInWithEmailAndPassword(
            email: email,
            password: password,
          );
          res = "success";
        }
      } else {
        res = "Please enter all the fields";
      }
    } catch (err) {
      return "Invalid email or password";
    }
    return res;
  }

  Future<void> signOut() async {
    await _auth.signOut();

    FirebaseAuth.instance.idTokenChanges().listen((User? user) {
      if (user == null) {
        print('User is currently signed out!');
      } else {
        print('User is signed in!');
      }
    });
  }

  // image variable is of type Uint8List
  Future<String> updateProfilePic(Uint8List image) async {
    String res = "Some error Occurred";
    try {
      String photoUrl = await StorageMethods()
          .uploadImageToStorage('profilePics', image, true);

      User currentUser = _auth.currentUser!;

      await _firestore.collection('users').doc(currentUser.uid).update({
        'photoUrl': photoUrl,
      });

      res = "success";
    } catch (err) {
      return err.toString();
    }
    return res;
  }
}

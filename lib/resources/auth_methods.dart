import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:Freecycle/models/user.dart' as model;
import 'package:Freecycle/resources/storage_methods.dart';

class AuthMethods {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String photoUrl = // photo Url from firebase storage defaultptofilrpic folder
      "https://firebasestorage.googleapis.com/v0/b/freethings-257b6.appspot.com/o/defaulprofilephoto%2FdefaultProfilePhoto.png?alt=media&token=f2500621-2916-4601-bcbe-93c63d7fa802";

  // get user details
  Future<model.User> getUserDetails() async {
    User currentUser = _auth.currentUser!;

    DocumentSnapshot documentSnapshot =
        await _firestore.collection('users').doc(currentUser.uid).get();

    return model.User.fromSnap(documentSnapshot);
  }

  // Signing Up User

  // Signing Up User

  Future<String> signUpUser({
    required String email,
    required String password,
    required String username,
    required String bio,
    required Uint8List? file,
    required String phoneNumber,
  }) async {
    String res = "Some error Occurred";
    try {
      if (password.length < 6) {
        res = "Password should be at least 6 characters long";
      } // username shoul be with small letters, shouldn't incuilde any spacial character and space
      else if (
          // !RegExp(r"^[a-z0-9_]+$").hasMatch(username) ||
          !RegExp(r"^[a-z0-9_]+$").hasMatch(username) ||
              username.contains(" ")) {
        res =
            "Username should be with small letters, shouldn't incuilde any spacial character and space";
      } else if (username.isEmpty || username.length > 25) {
        res = "Username should be between 1 and 25 characters long";
      } else if (bio.length > 100) {
        res = "Bio should be at most 150 characters long";
      } // phone number shouldn't be used by another user
      else if (await _firestore
          .collection('users')
          .where('phone_number', isEqualTo: phoneNumber)
          .limit(1) // limit sadece 1 sonuç getirir
          .get()
          .then((value) => value.docs.isNotEmpty)) {
        res = "Phone number already in use";
      } else {
        FirebaseAuth.instance.idTokenChanges().listen((User? user) {
          if (user == null) {
            print('User is currently signed out!');
          } else {
            print('User is signed in!');
          }
        });
        // registering user in auth with email and password
        UserCredential cred = await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );

        if (file != null) {
          photoUrl = await StorageMethods()
              .uploadImageToStorage('profilePics', file, true);
        } else {
          // Set a default photoUrl if user doesn't upload any photo from assets folder
          // photo Url from assets
          photoUrl =
              "https://firebasestorage.googleapis.com/v0/b/freethings-257b6.appspot.com/o/defaulprofilephoto%2FdefaultProfilePhoto.png?alt=media&token=f2500621-2916-4601-bcbe-93c63d7fa802";
        }

        model.User user = model.User(
          // matchCount: 0,
          // isPremium: false,
          username: username,
          uid: cred.user!.uid,
          photoUrl: photoUrl,
          email: email,
          bio: bio,
          matchedWith: null,
          followers: [],
          following: [],
          blocked: [],
          blockedBy: [],
          country: "",
          state: "",
          city: "",
          phoneNumber: phoneNumber,
          numberOfSentGifts: 0,
          numberOfUnsentGifts: 0,
          matchCount: 0,
          isPremium: false,
          isVerified: false,
          giftSendingRate: "",
          isConfirmed: false,
          isRated: false,
          giftPoint: 0,
          rateCount: 0,
          fcmToken: "",
          credit: 5,
        );

        // adding user in our database
        await _firestore
            .collection("users")
            .doc(cred.user!.uid)
            .set(user.toJson());

        res = "success";
      }
    } catch (err) {
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

        // Check if the user's email is in the deleted_user list
        QuerySnapshot deletedUserQuery = await _firestore
            .collection("deleted_users")
            .where("email", isEqualTo: email)
            .get();
        if (deletedUserQuery.docs.isNotEmpty) {
          // User is not allowed to log in
          res = "Deleted account. Please contact support";
        } else {
          // User is allowed to log in
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

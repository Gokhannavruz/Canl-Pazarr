import 'package:flutter/widgets.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:animal_trade/models/user.dart';
import 'package:animal_trade/resources/auth_methods.dart';

class UserProvider with ChangeNotifier {
  User? _user;
  final AuthMethods _authMethods = AuthMethods();
  bool _isLoading = true;

  User? get getUser =>
      _user ??
      User(
        uid: '',
        email: '',
        username: '',
        photoUrl: '',
        bio: '',
        followers: [],
        following: [],
        blocked: [],
        blockedBy: [],
        matchedWith: '',
        country: '',
        state: '',
        city: '',
        matchCount: 0,
        isPremium: false,
        numberOfSentGifts: 0,
        numberOfUnsentGifts: 0,
        giftSendingRate: '',
        isVerified: false,
        isConfirmed: false,
        giftPoint: 0,
        isRated: false,
        rateCount: 0,
        fcmToken: '',
        credit: 0,
      );

  bool get isLoading => _isLoading;

  // Initialize user provider with auth stream
  void initialize() {
    firebase_auth.FirebaseAuth.instance
        .authStateChanges()
        .listen((firebase_auth.User? firebaseUser) async {
      if (firebaseUser != null) {
        // User is signed in
        User? user = await _authMethods.getUserDetails();
        _user = user;
        _isLoading = false;
        notifyListeners();
      } else {
        // User is signed out
        _user = null;
        _isLoading = false;
        notifyListeners();
      }
    });
  }

  // refresh user
  Future<void> refreshUser() async {
    User? user = await _authMethods.getUserDetails();
    _user = user;
    notifyListeners();
  }
}

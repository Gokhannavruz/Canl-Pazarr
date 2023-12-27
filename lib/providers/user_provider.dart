import 'package:flutter/widgets.dart';
import 'package:Freecycle/models/user.dart';
import 'package:Freecycle/resources/auth_methods.dart';

class UserProvider with ChangeNotifier {
  User? _user;
  final AuthMethods _authMethods = AuthMethods();

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
        phoneNumber: '',
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
        credit: 5,
      );

  // refresh user
  Future<void> refreshUser() async {
    User? user = await _authMethods.getUserDetails();
    _user = user;
    notifyListeners();
  }
}

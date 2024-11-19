import 'package:flutter/widgets.dart';
import 'package:Freecycle/models/user.dart';
import 'package:Freecycle/resources/auth_methods.dart';

class UserProvider with ChangeNotifier {
  User? _user;
  final AuthMethods _authMethods = AuthMethods();

  User? get getUser {
    if (_user == null) {
      return null;
    } else {
      User user = User(
        uid: _user!.uid,
        email: _user!.email,
        username: _user!.username,
        photoUrl: _user!.photoUrl,
        bio: _user!.bio,
        followers: _user!.followers,
        following: _user!.following,
        blocked: _user!.blocked,
        blockedBy: _user!.blockedBy,
        matchedWith: _user!.matchedWith,
        country: _user!.country,
        state: _user!.state,
        city: _user!.city,
        matchCount: _user!.matchCount,
        isPremium: _user!.isPremium,
        numberOfSentGifts: _user!.numberOfSentGifts,
        numberOfUnsentGifts: _user!.numberOfUnsentGifts,
        giftSendingRate: _user!.giftSendingRate,
        isVerified: _user!.isVerified,
        isConfirmed: _user!.isConfirmed,
        giftPoint: _user!.giftPoint,
        isRated: _user!.isRated,
        rateCount: _user!.rateCount,
        fcmToken: '',
        credit: _user!.credit,
      );
      return user;
    }
  }

  Future<void> refreshUser() async {
    User? user = await _authMethods.getUserDetails();
    _user = user;
    notifyListeners();
  }
}

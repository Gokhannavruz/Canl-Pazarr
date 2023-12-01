import 'dart:async';
import 'dart:math' show Random;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:frees/screens/in_app_purchase.dart';
import 'package:frees/screens/profile_screen2.dart';
import 'package:frees/screens/rules_page.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'country_state_city_picker.dart';

class MatchPage101 extends StatefulWidget {
  MatchPage101({Key? key}) : super(key: key);

  final User user = FirebaseAuth.instance.currentUser!;

  @override
  _MatchPage101State createState() => _MatchPage101State();
}

class _MatchPage101State extends State<MatchPage101> {
  late StreamSubscription<List<PurchaseDetails>> _subscription;
  BannerAd? _bannerAd;
  late Timer _timer;

  late DateTime _nextMonday;
  String? country;
  String? state;
  bool _isLoading = false;
  bool isPremium = false;
  late bool isConfirmed;
  late String matchedUserUid;
  double _points = 0;
  final int _selectedStarIndex = -1;
  final bool _isRated = false;

  @override
  void initState() {
    super.initState();
    matchedUserUid = userId ?? '';
    _getUserPremiumStatus();
    //difference between now and if day > 7 first monday or if day < 7 previous monday
    _nextMonday = _getNextMonday();
    _getUserIsConfirmed();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          // update state here
        });
      }
    });
    FirebaseAuth.instance.idTokenChanges().listen((User? user) {
      if (user != null) {
        _getUserCountryState();
      }
    });
    // _createBannerAd();
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
    // _createBannerAd();
  }

  // void _createBannerAd() {
  //   _bannerAd = BannerAd(
  //     adUnitId: 'ca-app-pub-8445989958080180/9975137648',
  //     size: AdSize.banner,
  //     request: const AdRequest(),
  //     listener: const BannerAdListener(),
  //   )..load();
  // }

  // get user premium status from firebase and set isPremium to true if user is premium
  Future<void> _getUserPremiumStatus() async {
    var currentUser = FirebaseAuth.instance.currentUser;
    var currentUserData = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser!.uid)
        .get();
    setState(() {
      isPremium = currentUserData['is_premium'];
    });
  }

  DateTime _getNextMonday() {
    final now = DateTime.now();
    final monday =
        now.weekday == 1 ? now : now.subtract(Duration(days: now.weekday - 1));
    return DateTime(monday.year, monday.month, monday.day, 0, 0, 0)
        .add(const Duration(days: 14));
  }

// get the user country, state from firebase
  Future<void> _getUserCountryState() async {
    var currentUser = FirebaseAuth.instance.currentUser;
    var currentUserData = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser!.uid)
        .get();
    setState(() {
      country = currentUserData['country'];
      state = currentUserData['state'];
    });
  }

  // get user isConfirmed from firebase
  Future<void> _getUserIsConfirmed() async {
    var currentUser = FirebaseAuth.instance.currentUser;
    var currentUserData = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser!.uid)
        .get();
    setState(() {
      isConfirmed = currentUserData['isConfirmed'];
    });
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final difference = _nextMonday.difference(now);
    final days = difference.inDays.toString().padLeft(2, '');
    final hours = difference.inHours.remainder(24).toString().padLeft(2, '0');
    final minutes =
        difference.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds =
        difference.inSeconds.remainder(60).toString().padLeft(2, '0');

    // if difference is less than 0, delete matched user

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.black,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("Matching"),
            // icon button for naviggate to rules page
            IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const RulesPage()),
                );
              },
              icon: const Icon(Icons.help_outline),
            ),
          ],
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: MediaQuery.of(context).size.height * 0.055,
              width: MediaQuery.of(context).size.width * 0.9,
              decoration: const BoxDecoration(
                color: Color.fromARGB(255, 30, 31, 33),
                // ,
                borderRadius: BorderRadius.all(Radius.circular(30)),
              ),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.only(right: 3.0, left: 3),
                  child: Center(
                    child: InkWell(
                      // naviaget to country state city picker
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const CountryStateCity(),
                          ),
                        );
                      },
                      child: Row(
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(left: 8.0),
                            child: Icon(
                              Icons.location_on,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(width: 10),
                          // if country and state is null show 'Select your location'
                          // state and country with stream builder
                          StreamBuilder(
                            stream: FirebaseFirestore.instance
                                .collection('users')
                                .doc(FirebaseAuth.instance.currentUser!.uid)
                                .snapshots(),
                            builder: (context,
                                AsyncSnapshot<DocumentSnapshot> snapshot) {
                              if (snapshot.hasData) {
                                final country = snapshot.data!['country'];
                                final state = snapshot.data!['state'];
                                if (country != "" && state != "") {
                                  return Text(
                                    '$state $country',
                                    style: const TextStyle(fontSize: 13),
                                  );
                                } else if (country != "") {
                                  return Text(
                                    country,
                                    style: const TextStyle(fontSize: 13),
                                  );
                                } else if (state != "") {
                                  return Text(
                                    state,
                                    style: const TextStyle(fontSize: 13),
                                  );
                                }
                              }
                              return const Text(
                                  'Select your country and state');
                            },
                          )
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: MediaQuery.of(context).size.height * 0.02),
            // show remaining time to next monday with nice ui
            Container(
              height: MediaQuery.of(context).size.height * 0.1,
              width: MediaQuery.of(context).size.width * 0.9,
              decoration: const BoxDecoration(
                color: Color.fromARGB(255, 30, 31, 33),
                borderRadius: BorderRadius.all(Radius.circular(15)),
              ),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.only(right: 12.0, left: 8),
                  child: Row(
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(left: 8.0),
                        child: Icon(
                          Icons.timer,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'Next match in: ',
                        style: TextStyle(fontSize: 16),
                      ),
                      const SizedBox(width: 3),
                      Text(
                        '$days:$hours:$minutes:$seconds',
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(height: MediaQuery.of(context).size.height * 0.02),

            // premium button right side of the screen
            Container(
              height: MediaQuery.of(context).size.height * 0.07,
              width: MediaQuery.of(context).size.width * 0.9,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color.fromARGB(255, 54, 105, 214),
                    Color.fromARGB(255, 22, 185, 25),
                  ],
                ),
                color: // gradient color
                    Color.fromARGB(255, 63, 101, 195),
                borderRadius: BorderRadius.all(Radius.circular(10)),
              ),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.only(right: 3.0, left: 3),
                  child: Center(
                    child: InkWell(
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SubscriptionPage(),
                          ),
                        );
                      },
                      child: const Row(
                        children: [
                          Padding(
                            padding: EdgeInsets.only(left: 8.0),
                            child: Icon(
                              Icons.star,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(width: 10),
                          Text(
                            'Be premium! Get gifts every week',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            Expanded(
              child: FutureBuilder(
                future: _getMatchButton(context),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    return snapshot.data as Widget;
                  } else {
                    return Center(
                      child: TextButton(
                        onPressed: () {
                          // get current user country and state with stream builder,
                          // if country and state is null show alert dialog
                          // if country and state is not null, show match button
                          StreamBuilder(
                            stream: FirebaseFirestore.instance
                                .collection('users')
                                .doc(FirebaseAuth.instance.currentUser!.uid)
                                .snapshots(),
                            builder: (context,
                                AsyncSnapshot<DocumentSnapshot> snapshot) {
                              if (snapshot.hasData) {
                                final country = snapshot.data!['country'];
                                final state = snapshot.data!['state'];
                                if (country == "" || state == "") {
                                  showDialog(
                                    context: context,
                                    builder: (context) {
                                      return AlertDialog(
                                        title: const Text('Error'),
                                        content: const Text(
                                            'Please select your country and state'),
                                        actions: [
                                          TextButton(
                                            onPressed: () {
                                              Navigator.pop(context);
                                            },
                                            child: const Text('OK'),
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                } else {
                                  _selectRandomUser(
                                    context,
                                  );
                                }
                              }
                              return const Text('');
                            },
                          );
                        },
                        child: const Text(
                          'Match',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
      // bottomNavigationBar: _bannerAd == null
      //     ? Container()
      //     : Container(
      //         height: _bannerAd!.size.height.toDouble(),
      //         width: _bannerAd!.size.width.toDouble(),
      //         child: AdWidget(ad: _bannerAd!),
      //       ),
    );
  }

  void _deleteMatchedUser() {
    var currentUser = FirebaseAuth.instance.currentUser;
    FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser!.uid)
        .update({
      'matched_with': null,
      'isConfirmed': false,
      'isRated': false,
    });
  }

  String? userId = FirebaseAuth.instance.currentUser!.uid;

  Future<Widget> _getMatchButton(BuildContext context) async {
    var currentUser = FirebaseAuth.instance.currentUser;
    var currentUserData = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser!.uid)
        .get();

    String? matchedUserId = currentUserData['matched_with'];
    if (matchedUserId == null) {}

    if (matchedUserId != null) {
      var matchedUserSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(matchedUserId)
          .get();

      int matchCount = matchedUserSnapshot['match_count'];
      int numberOfSentGifts = matchedUserSnapshot['number_of_sent_gifts'];
      String? name = matchedUserSnapshot['username'];
      String? profilePhotoUrl = matchedUserSnapshot['photoUrl'];
      double giftPoint = matchedUserSnapshot['gift_point'];
      int rateCount = matchedUserSnapshot['rateCount'];
      double ratePoint = giftPoint / rateCount;

      return Center(
        child: Column(
          children: [
            const SizedBox(height: 20),
            const Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                SizedBox(width: 55),
                Text(
                  'You have matched with',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              width: MediaQuery.of(context).size.width * 0.8,
              height: MediaQuery.of(context).size.height * 0.46,
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 63, 101, 195),
                // ,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        name!,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 2),
                      // if numberofsentgifts / matchcount * 100 = 100 show verified icon
                      if (numberOfSentGifts / matchCount * 100 >= 90)
                        const Padding(
                          padding: EdgeInsets.only(top: 2),
                          child: Icon(
                            Icons.verified,
                            size: 15,
                            color: Color.fromARGB(255, 255, 255, 255),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Center(
                    child: InkWell(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => ProfileScreen2(
                              snap: null,
                              userId: matchedUserId,
                              uid: matchedUserId,
                            ),
                          ),
                        );
                      },
                      child: CircleAvatar(
                        radius: 60,
                        backgroundImage: NetworkImage(profilePhotoUrl!),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        // if matchCount 0 show text 'first match' eşlse show matchCount / nunberofsentgifts * 100
                        matchCount == 0
                            ? 'First match'
                            : '${(numberOfSentGifts / matchCount * 100)}% Sending Rate',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // show rate point if rate count is greater than 0 with stars and if point is 4.5 show 4 stars and half star
                  // if (rateCount > 0)
                  //   Row(
                  //     mainAxisAlignment: MainAxisAlignment.center,
                  //     children: [
                  //       for (var i = 0; i < ratePoint.toInt(); i++)
                  //         const Icon(
                  //           Icons.star,
                  //           color: Colors.yellowAccent,
                  //           size: 20,
                  //         ),
                  //       if (ratePoint % ratePoint.toInt() != 0)
                  //         const Icon(
                  //           Icons.star_half,
                  //           color: Colors.yellowAccent,
                  //           size: 20,
                  //         ),
                  //       if (ratePoint % ratePoint.toInt() != 0)
                  //         for (var i = 0; i < 5 - ratePoint.toInt() - 1; i++)
                  //           const Icon(
                  //             Icons.star_border,
                  //             color: Colors.white,
                  //             size: 20,
                  //           ),
                  //       const SizedBox(width: 5),
                  //       Text(
                  //         '$ratePoint',
                  //         style: const TextStyle(
                  //           fontSize: 15,
                  //           fontWeight: FontWeight.bold,
                  //         ),
                  //       ),
                  //     ],
                  //   ),

                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // followers count
                        Row(
                          children: [
                            Column(
                              children: [
                                Text(
                                  '$matchCount',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Center(
                                  child: Text(
                                    'matches',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(width: 15),
                            // number of sent gifts
                            Column(
                              children: [
                                Text(
                                  '$numberOfSentGifts',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Text(
                                  'gifts sent',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 20),
                            Column(
                              children: [
                                Text(
                                  // don't show last 2 digits of the gift point if it is 0
                                  giftPoint % 100 == 0
                                      ? '${giftPoint ~/ 100}'
                                      : '$giftPoint',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Text(
                                  'gift point',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    // go to the profile page of the matched user
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // send a message to the matched user icon button
                      IconButton(
                        icon: const Icon(
                          Icons.mail,
                          color: Colors.white,
                        ),
                        onPressed: () {
                          // if (currentUser != null) {
                          //   Navigator.of(context).push(
                          //     MaterialPageRoute(
                          //       builder: (context) => MessagesPage(
                          //         currentUserUid: currentUser.uid,
                          //         recipientUid: matchedUserId,
                          //       ),
                          //     ),
                          //   );
                          // } else {
                          //   // handle the case where the current user is not available
                          // }
                        },
                      ),
                      // confirm with textButton if the matcheduser sent a gift to the current user, and add to +1 to the matched user's number of sent gifts
                      // with stream builder isConfirmed, if isConfirmed false then show dialog, if true then show text 'confirmed'
                      StreamBuilder(
                        stream: FirebaseFirestore.instance
                            .collection('users')
                            .doc(currentUser.uid)
                            .snapshots(),
                        builder: (context,
                            AsyncSnapshot<DocumentSnapshot> snapshot) {
                          if (snapshot.hasData) {
                            return snapshot.data!['isConfirmed'] == false
                                ? TextButton(
                                    onPressed: () {
                                      showDialog(
                                        context: context,
                                        builder: (context) {
                                          return AlertDialog(
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            backgroundColor:
                                                const Color.fromARGB(
                                                    255, 24, 22, 22),
                                            title: const Text(
                                              'Confirm',
                                              style: TextStyle(
                                                fontSize: 16,
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            content: const Text(
                                              'Did you receive a gift from this user?',
                                              style: TextStyle(
                                                fontSize: 15,
                                              ),
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () {
                                                  Navigator.of(context).pop();
                                                },
                                                child: const Text(
                                                  'No',
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ),
                                              TextButton(
                                                style: TextButton.styleFrom(
                                                  backgroundColor: Colors.green,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            10),
                                                  ),
                                                ),
                                                onPressed: () {
                                                  _confirmSending();
                                                  Navigator.of(context).pop();
                                                },
                                                child: const Text(
                                                  'Yes',
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          );
                                        },
                                      );
                                    },
                                    child: const Text(
                                      'Confirm',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                      ),
                                    ),
                                  )
                                : const Text(
                                    'Confirmed',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                    ),
                                  );
                          } else {
                            return const Text('Loading...');
                          }
                        },
                      ),

                      const SizedBox(width: 10),
                      // if isConfirmed true show text button for "give points" else show text button for "points given"
                      StreamBuilder(
                        stream: FirebaseFirestore.instance
                            .collection('users')
                            .doc(currentUser.uid)
                            .snapshots(),
                        builder: (context,
                            AsyncSnapshot<DocumentSnapshot> snapshot) {
                          if (snapshot.hasData) {
                            final isConfirmed = snapshot.data!['isConfirmed'];
                            final isRated = snapshot.data!['isRated'];

                            if (isConfirmed == false) {
                              return const SizedBox
                                  .shrink(); // Hiçbir şey gösterme
                            } else if (isConfirmed == true &&
                                isRated == false) {
                              return TextButton(
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (context) {
                                      return AlertDialog(
                                        title: const Text(
                                          'Give Points',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        content: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Text(
                                              'How many points would you like to give?',
                                              style: TextStyle(
                                                fontSize: 14,
                                              ),
                                            ),
                                            const SizedBox(height: 15),
                                            Column(
                                              children: [
                                                RatingBar.builder(
                                                  itemSize: 35,
                                                  initialRating: _points,
                                                  minRating: 1,
                                                  direction: Axis.horizontal,
                                                  allowHalfRating: true,
                                                  itemCount: 5,
                                                  itemPadding: const EdgeInsets
                                                      .symmetric(
                                                    horizontal: 4.0,
                                                  ),
                                                  itemBuilder: (context, _) =>
                                                      const Icon(
                                                    Icons.star,
                                                    color: Colors.amber,
                                                  ),
                                                  onRatingUpdate: (rating) {
                                                    setState(() {
                                                      _points = rating;
                                                    });
                                                  },
                                                ),
                                                const SizedBox(height: 15),
                                              ],
                                            )
                                          ],
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () {
                                              Navigator.of(context).pop();
                                            },
                                            child: const Text(
                                              'Cancel',
                                              style: TextStyle(
                                                fontSize: 14,
                                              ),
                                            ),
                                          ),
                                          TextButton(
                                            onPressed: () {
                                              _givePoint();
                                              Navigator.of(context).pop();
                                            },
                                            child: const Text(
                                              'Give',
                                              style: TextStyle(
                                                fontSize: 14,
                                              ),
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                },
                                child: const Text(
                                  'Rate',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                  ),
                                ),
                              );
                            } else {
                              return const Text(
                                'Rated',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                              );
                            }
                          } else {
                            return const Text('Loading...');
                          }
                        },
                      )
                    ],
                  ),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        const SizedBox(width: 10),
                        const Icon(
                          Icons.location_on,
                        ),
                        const SizedBox(width: 5),

                        // country and state with stream builder
                        StreamBuilder(
                          stream: FirebaseFirestore.instance
                              .collection('users')
                              .doc(matchedUserId)
                              .snapshots(),
                          builder: (context,
                              AsyncSnapshot<DocumentSnapshot> snapshot) {
                            if (snapshot.hasData) {
                              return Text(
                                // if country null then show state only, if state null then show country only but dont show "-"", if both null then show "FROM EARTH"
                                snapshot.data!['country'] == ""
                                    ? snapshot.data!['state'] == ""
                                        ? 'From Earth'
                                        : snapshot.data!['state']
                                    : snapshot.data!['state'] == ""
                                        ? snapshot.data!['country']
                                        : snapshot.data!['country'] +
                                            ' - ' +
                                            snapshot.data!['state'],

                                style: const TextStyle(
                                  fontSize: 15,
                                ),
                              );
                            } else {
                              return const Text('Loading...');
                            }
                          },
                        ),
                        //
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Display the "Match" button
    return Padding(
      padding: const EdgeInsets.only(bottom: 80.0),
      child: Center(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.8,
          height: 300,
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 63, 101, 195),
            borderRadius: BorderRadius.circular(30),
          ),
          child: // if isLoading true then show CircularProgressIndicator
              // show circular progress indicator for only for 5 seconds
              _isLoading
                  ? const Center(
                      child: SizedBox(
                        width: 50,
                        height: 50,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 6,
                        ),
                      ),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 10),
                        const Image(
                          image: AssetImage('assets/giftbox.png'),
                          width: 100,
                          height: 100,
                        ),
                        const SizedBox(height: 30),
                        const Text(
                          'Match For Mystery',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            TextButton(
                              style: TextButton.styleFrom(
                                backgroundColor:
                                    const Color.fromARGB(255, 23, 53, 126),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(5),
                                ),
                              ),
                              onPressed: () {
                                // wait for 5 seconds
                                setState(() {
                                  _isLoading = true;
                                });
                                _selectRandomUser(context);
                              },
                              child: const Text(
                                'Match',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
        ),
      ),
    );
  }

  void _selectRandomUser(BuildContext context) async {
    // Get the current user's data from the database
    var currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      showDialog(
        context: context,
        builder: (context) => const AlertDialog(
          title: Text(
            'Error',
            style: TextStyle(color: Colors.white),
          ),
          content: Text(
            'You must be signed in to use this feature',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
      return;
    }

    QuerySnapshot users;

    if (country != "" && state != "") {
      users = await FirebaseFirestore.instance
          .collection('users')
          .where('country', isEqualTo: country)
          .where('state', isEqualTo: state)
          .get();
    } else if (country != "") {
      users = await FirebaseFirestore.instance
          .collection('users')
          .where('country', isEqualTo: country)
          .get();
    } else {
      users = await FirebaseFirestore.instance.collection('users').get();
    }

    // if (users.size == 0) {
    //   Duration duration = const Duration(seconds: 5);
    //   Future.delayed(duration, () {
    //     setState(() {
    //       _isLoading = false;
    //     });
    //     showDialog(
    //       context: context,
    //       builder: (context) => Dialog(
    //         shape: RoundedRectangleBorder(
    //           borderRadius: BorderRadius.circular(14),
    //         ),
    //         backgroundColor: const Color.fromARGB(255, 24, 22, 22),
    //         child: Padding(
    //           padding: const EdgeInsets.all(16.0),
    //           child: Column(
    //             mainAxisSize: MainAxisSize.min,
    //             children: [
    //               Text(
    //                 'Error',
    //                 style: TextStyle(color: Colors.white, fontSize: 18),
    //               ),
    //               SizedBox(height: 8),
    //               Text(
    //                 'No users available to match with',
    //                 style: TextStyle(color: Colors.white),
    //               ),
    //             ],
    //           ),
    //         ),
    //       ),
    //     );
    //   });
    // }

    var filteredUsers = users.docs.where((user) {
      return user['uid'] != currentUser.uid && user['matched_with'] == null;
    }).toList();

    if (filteredUsers.isEmpty) {
      // wait for 5 seconds and then show dialog "No users available to match with"
      Duration duration = const Duration(seconds: 5);
      Future.delayed(duration, () {
        setState(() {
          _isLoading = false;
        });
        showDialog(
          context: context,
          builder: (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            backgroundColor: const Color.fromARGB(255, 24, 22, 22),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // nice ui for the dialog box
                  const Text(
                    'oops!',
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'No users available to match with',
                    style: TextStyle(color: Colors.white),
                  ),

                  // add a button to close the dialog box
                  const SizedBox(height: 24),
                  TextButton(
                    style: TextButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 23, 53, 126),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text(
                      'OK',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      });
    }

    var randomIndex = Random().nextInt(filteredUsers.length);
    var randomUser = filteredUsers[randomIndex];
    String userId = randomUser.id;
    // Add the current user to the matched user's "matchedUsers" list
    await FirebaseFirestore.instance.collection('users').doc(userId).update({
      'matchedUsers': FieldValue.arrayUnion([currentUser.uid])
    });

    // Add the matched user to the current user's "matchedUsers" list
    await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.uid)
        .update({
      'matchedUsers': FieldValue.arrayUnion([userId])
    });

    // add to +1 to the matched user's and current user's match_count field
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .update({'match_count': FieldValue.increment(1)});
    await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.uid)
        .update({'match_count': FieldValue.increment(1)});

// Update the "matched_with" field for both the current user and the matched user
    var matchedUser =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();
    await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.uid)
        .update({'matched_with': userId});
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .update({'matched_with': currentUser.uid});
  }

  // set currentUser isConfirmed to true
  void _confirmSending() async {
    var currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return;
    }
    await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.uid)
        .update({
      'isConfirmed': true,
    });

    // and add to +1 to the current user's gifts sent field

    // matched user's id from the matched_with field
    var matchedUserId = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.uid)
        .get();
    String matcheduser = matchedUserId['matched_with'];
    await FirebaseFirestore.instance
        .collection('users')
        .doc(matcheduser)
        .update({'number_of_sent_gifts': FieldValue.increment(1)});
  }

  // give point to the current user add the points to the current user's giftPoint field
  void _givePoint() async {
    setState(() {});
    var currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return;
    }
    // get the matched user's id from the matched_with field
    var matchedUserId = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.uid)
        .get();
    String matcheduseruid = matchedUserId['matched_with'];
    await FirebaseFirestore.instance
        .collection('users')
        .doc(matcheduseruid)
        .update({
      'gift_point': FieldValue.increment(_points),
    });
    // update the current user's isRated field to true
    await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.uid)
        .update({
      'isRated': true,
    });

    // add to +1 to the matched user's rateCount field
    var matchedUserid = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.uid)
        .get();
    String matcheduser = matchedUserId['matched_with'];
    await FirebaseFirestore.instance
        .collection('users')
        .doc(matcheduser)
        .update({'rateCount': FieldValue.increment(1)});
  }
}

import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class CreditPage extends StatefulWidget {
  const CreditPage({Key? key}) : super(key: key);

  @override
  _CreditPageState createState() => _CreditPageState();
}

class _CreditPageState extends State<CreditPage> {
  late int credits;
  RewardedAd? _rewardedAd;
  var earnedCredits = 0;
  var watchedAds = 0;
  final adUnitId = Platform.isAndroid
      ? 'ca-app-pub-8445989958080180/1538574301'
      : 'ca-app-pub-3940256099942544/1712485313';
  late Completer<void> _adLoadCompleter;

  @override
  void initState() {
    super.initState();
    _adLoadCompleter = Completer<void>();
    loadAd();
    getCredit();
  }

  @override
  void dispose() {
    _rewardedAd?.dispose();
    super.dispose();
  }

  Future<void> getCredit() async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .get()
        .then((value) {
      setState(() {
        credits = value.data()!['credit'];
      });
    });
  }

  Future<void> _watchAd() async {
    if (_rewardedAd == null) {
      await _adLoadCompleter.future; // Wait for the ad to be loaded
      if (_rewardedAd == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ad is not loaded yet. Please try again later.'),
          ),
        );
        return;
      }
    }

    _rewardedAd!.show(
      onUserEarnedReward: (AdWithoutView ad, RewardItem rewardItem) {
        setState(() {
          // Increment the watchedAds count
          watchedAds++;

          // Update credits based on the number of ads watched
          FirebaseFirestore.instance
              .collection('users')
              .doc(FirebaseAuth.instance.currentUser!.uid)
              .update({'credit': credits + watchedAds}).then((value) {});
        });
      },
    );
  }

  void loadAd() {
    RewardedAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdShowedFullScreenContent: (ad) {},
            onAdImpression: (ad) {},
            onAdFailedToShowFullScreenContent: (ad, err) {
              ad.dispose();
            },
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              loadAd();
            },
            onAdClicked: (ad) {},
          );

          debugPrint('$ad loaded.');
          _rewardedAd = ad;
          _adLoadCompleter.complete(); // Notify that the ad is loaded
        },
        onAdFailedToLoad: (LoadAdError error) {
          debugPrint('RewardedAd failed to load: $error');
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Earn Credits'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(
              height: 20,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'You have:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(
                  width: 3,
                ),
                const Icon(
                  Icons.monetization_on,
                  color: Colors.yellow,
                  size: 25,
                ),
                const SizedBox(
                  width: 3,
                ),
                StreamBuilder(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .doc(FirebaseAuth.instance.currentUser!.uid)
                      .snapshots(),
                  builder: (context, AsyncSnapshot<DocumentSnapshot> snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Container();
                      // Show loading indicator while data is being fetched
                    } else if (snapshot.hasData) {
                      return Text(
                        '${snapshot.data!['credit']}',
                        style: const TextStyle(
                            fontSize: 20,
                            color: Colors.white,
                            fontWeight: FontWeight.bold),
                      );
                    } else {
                      return const Text('0');
                    }
                  },
                ),
              ],
            ),
            const SizedBox(
              height: 20,
            ),
            const Text(
              "You can earn credits by watching ads. \nYou will receive 1 credit for each ad",
              style: TextStyle(
                fontSize: 15,
              ),
              textAlign: TextAlign.center,
            ),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Earned credit:',
                      style:
                          TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '$watchedAds',
                      style: const TextStyle(
                          fontSize: 48,
                          color: Colors.white,
                          fontWeight: FontWeight.bold),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: const Color.fromARGB(255, 6, 114, 229),
                      ),
                      onPressed: _watchAd,
                      child: const Text('Earn Credit',
                          style: TextStyle(fontSize: 19)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

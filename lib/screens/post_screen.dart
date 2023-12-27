import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:Freecycle/widgets/post_card.dart';

class PostScreen extends StatefulWidget {
  final String postId;
  final String uid;

  const PostScreen({Key? key, required this.postId, required this.uid})
      : super(key: key);

  @override
  State<PostScreen> createState() => _PostScreenState();
}

class _PostScreenState extends State<PostScreen> {
  NativeAd? _nativeAd;
  NativeAd? _nativeAd2;
  bool isAdLoaded = false;
  bool isAdLoaded2 = false;

  @override
  void initState() {
    super.initState();
    _loadNativeAd();
    _loadNativeAd2();
  }

  void _loadNativeAd() {
    _nativeAd = NativeAd(
      adUnitId: 'ca-app-pub-8445989958080180/6416858905',
      factoryId: 'listTile',
      request: const AdRequest(),
      listener: NativeAdListener(
        // Called when an ad is successfully received.
        onAdLoaded: (Ad ad) {
          var add = ad as NativeAd;
          print("**** AD ***** ${add.responseInfo}");
          setState(() {
            _nativeAd = add;
            isAdLoaded = true;
          });
        },

        // Called when an ad request failed.
        onAdFailedToLoad: (Ad ad, LoadAdError error) {
          // Dispose the ad here to free resources.
          ad.dispose();
          print('Ad load failed (code=${error.code} message=${error.message})');
        },
        // Called when an ad opens an overlay that covers the screen.
        onAdOpened: (Ad ad) => print('Ad opened.'),
        // Called when an ad removes an overlay that covers the screen.
        onAdClosed: (Ad ad) => print('Ad closed.'),
        // Called when an impression occurs on the ad.
        onAdImpression: (Ad ad) => print('Ad impression.'),
        // Called when a click is recorded for a NativeAd.
        onAdClicked: (Ad ad) => print('Ad clicked.'),
      ),
    );

    _nativeAd!.load();
  }

  void _loadNativeAd2() {
    _nativeAd2 = NativeAd(
      adUnitId: 'ca-app-pub-8445989958080180/6985284551',
      factoryId: 'listTile',
      request: const AdRequest(),
      listener: NativeAdListener(
        // Called when an ad is successfully received.
        onAdLoaded: (Ad ad) {
          var add = ad as NativeAd;
          print("**** AD ***** ${add.responseInfo}");
          setState(() {
            _nativeAd2 = add;
            isAdLoaded2 = true;
          });
        },

        // Called when an ad request failed.
        onAdFailedToLoad: (Ad ad, LoadAdError error) {
          // Dispose the ad here to free resources.
          ad.dispose();
          print('Ad load failed (code=${error.code} message=${error.message})');
        },
        // Called when an ad opens an overlay that covers the screen.
        onAdOpened: (Ad ad) => print('Ad opened.'),
        // Called when an ad removes an overlay that covers the screen.
        onAdClosed: (Ad ad) => print('Ad closed.'),
        // Called when an impression occurs on the ad.
        onAdImpression: (Ad ad) => print('Ad impression.'),
        // Called when a click is recorded for a NativeAd.
        onAdClicked: (Ad ad) => print('Ad clicked.'),
      ),
    );

    _nativeAd2!.load();
  }

  @override
  void dispose() {
    _nativeAd!.dispose();
    _nativeAd2!.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Post"),
        backgroundColor: Colors.black,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              children: [
                if (isAdLoaded2 == false)
                  SizedBox(
                    height: 55,
                  )
                else
                  SizedBox(
                    height: 55,
                    child: AdWidget(ad: _nativeAd2!),
                  ),

                // sized box
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.001,
                ),

                StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('posts')
                      .doc(widget.postId)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const SizedBox.shrink();
                    }
                    return PostCard(
                      snap: snapshot.data!,
                      isBlocked: false,
                      isGridView: false,
                    );
                  },
                ),

                // sized box
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.05,
                ),
              ],
            ),
          ),

          // show the ad at the bottom
          if (isAdLoaded)
            Container(
              height: 55,
              child: AdWidget(ad: _nativeAd!),
            ),
        ],
      ),
    );
  }
}

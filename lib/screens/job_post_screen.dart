import 'package:Freecycle/widgets/job_card.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:Freecycle/widgets/post_card.dart';

class jobPostScreen extends StatefulWidget {
  final String postId;
  final String uid;

  const jobPostScreen({Key? key, required this.postId, required this.uid})
      : super(key: key);

  @override
  State<jobPostScreen> createState() => _jobPostScreenState();
}

class _jobPostScreenState extends State<jobPostScreen> {
  NativeAd? _nativeAd;
  bool isAdLoaded = false;

  @override
  void initState() {
    super.initState();
    /*  _loadNativeAd(); */
  }

  void _loadNativeAd() {
    _nativeAd = NativeAd(
      adUnitId: 'ca-app-pub-8445989958080180/2322368783',
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

  @override
  void dispose() {
    _nativeAd!.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              children: [
                StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('jobs')
                      .doc(widget.postId)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const SizedBox.shrink();
                    }
                    return JobCard(
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
/*           if (isAdLoaded)
            SizedBox(
              height: 55,
              child: AdWidget(ad: _nativeAd!),
            ), */
        ],
      ),
    );
  }
}

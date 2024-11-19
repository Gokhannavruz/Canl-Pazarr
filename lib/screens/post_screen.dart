import 'package:Freecycle/src/components/native_dialog.dart';
import 'package:Freecycle/src/model/singletons_data.dart';
import 'package:Freecycle/src/model/weather_data.dart';
import 'package:Freecycle/src/rvncat_constant.dart';
import 'package:Freecycle/src/views/paywall.dart';
import 'package:Freecycle/src/views/paywallfirstlaunch.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:Freecycle/widgets/post_card.dart';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

class PostScreen extends StatefulWidget {
  final String postId;
  final String uid;

  const PostScreen({Key? key, required this.postId, required this.uid})
      : super(key: key);

  @override
  State<PostScreen> createState() => _PostScreenState();
}

class _PostScreenState extends State<PostScreen> {
  bool isAdLoaded = false;
  String category = '';
  String country = '';
  bool _isLoading = false;
  bool _isPremium = false;

  @override
  void initState() {
    super.initState();
    _checkPremiumStatus();
  }

  void _checkPremiumStatus() async {
    CustomerInfo customerInfo = await Purchases.getCustomerInfo();
    setState(() {
      _isPremium =
          customerInfo.entitlements.all[entitlementID]?.isActive ?? false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('posts')
            .doc(widget.postId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
                child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
            ));
          }
          var postData = snapshot.data!;
          return ListView(
            children: [
              PostCard(
                snap: postData,
                isBlocked: false,
                isGridView: false,
              ),
              const SizedBox(height: 20),
              Builder(
                builder: (BuildContext context) {
                  final Size screenSize = MediaQuery.of(context).size;
                  final double width = screenSize.width;
                  final double height = screenSize.height;

                  return Container(
                    padding: EdgeInsets.all(width * 0.04),
                    margin: EdgeInsets.symmetric(horizontal: width * 0.04),
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 33, 32, 32),
                      borderRadius: BorderRadius.circular(width * 0.03),
                    ),
                    child: _isPremium
                        ? _buildPremiumMessage(width, height)
                        : _buildNonPremiumMessage(width, height),
                  );
                },
              ),
              SizedBox(height: 20),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPremiumMessage(double width, double height) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Thank You, Premium Member!',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: width * 0.045,
            color: Colors.white,
          ),
        ),
        SizedBox(height: height * 0.015),
        Text(
          'We appreciate your support in keeping our platform sustainable. Enjoy your ad-free experience and all the premium features!',
          style: TextStyle(fontSize: width * 0.035, color: Colors.white),
        ),
        SizedBox(height: height * 0.015),
        Text(
          'Your contribution helps us maintain and improve our free item exchange service for the community.',
          style: TextStyle(fontSize: width * 0.035, color: Colors.white),
        ),
      ],
    );
  }

  Widget _buildNonPremiumMessage(double width, double height) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Dear User,',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: width * 0.045,
            color: Colors.white,
          ),
        ),
        SizedBox(height: height * 0.015),
        Text(
          'Our app provides a platform for people to give away their unused items to other users for free. To keep this service free, we rely on ad revenue. However, we understand that ads can sometimes be disruptive.',
          style: TextStyle(fontSize: width * 0.035, color: Colors.white),
        ),
        SizedBox(height: height * 0.015),
        Text(
          'For an ad-free experience, consider our subscriptions. You\'ll enjoy a smoother app usage while supporting the sustainability of our platform.',
          style: TextStyle(fontSize: width * 0.035, color: Colors.white),
        ),
        SizedBox(height: height * 0.025),
        Center(
          child: ElevatedButton(
            onPressed: perfomMagic,
            child: Text(
              'Subscribe for Ad-Free Experience',
              style: TextStyle(
                fontSize: width * 0.04,
                color: Colors.white,
              ),
            ),
            style: ElevatedButton.styleFrom(
              primary: Colors.green,
              padding: EdgeInsets.symmetric(
                horizontal: width * 0.05,
                vertical: height * 0.018,
              ),
            ),
          ),
        ),
      ],
    );
  }

  void perfomMagic() async {
    setState(() {
      _isLoading = true;
    });

    CustomerInfo customerInfo = await Purchases.getCustomerInfo();

    if (customerInfo.entitlements.all[entitlementID] != null &&
        customerInfo.entitlements.all[entitlementID]?.isActive == true) {
      appData.currentData = WeatherData.generateData();

      setState(() {
        _isLoading = false;
      });
    } else {
      Offerings? offerings;
      try {
        offerings = await Purchases.getOfferings();
      } on PlatformException catch (e) {
        await showDialog(
            context: context,
            builder: (BuildContext context) => ShowDialogToDismiss(
                title: "Error",
                content: e.message ?? "Unknown error",
                buttonText: 'OK'));
      }

      setState(() {
        _isLoading = false;
      });

      if (offerings == null || offerings.current == null) {
        // offerings are empty, show a message to your user
        await showDialog(
            context: context,
            builder: (BuildContext context) => ShowDialogToDismiss(
                title: "Error",
                content: "No offerings available",
                buttonText: 'OK'));
      } else {
        // current offering is available, show paywall
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => Paywall(offering: offerings!.current!)),
        );
      }
    }
  }
}

import 'package:freecycle/src/components/native_dialog.dart';
import 'package:freecycle/src/model/singletons_data.dart';
import 'package:freecycle/src/model/weather_data.dart';
import 'package:freecycle/src/rvncat_constant.dart';
import 'package:freecycle/src/views/paywall.dart';
import 'package:freecycle/src/views/paywallfirstlaunch.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:freecycle/widgets/post_card.dart';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:freecycle/src/model/experiment_manager.dart';

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
  DocumentSnapshot? _postData;
  bool _isDataLoaded = false;

  @override
  void initState() {
    super.initState();
    _checkPremiumStatus();
    _fetchPostDataOnce();
  }

  Future<void> _fetchPostDataOnce() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('posts')
          .doc(widget.postId)
          .get();

      if (mounted) {
        setState(() {
          _postData = doc;
          _isDataLoaded = true;
        });
      }
    } catch (e) {
      print("Error fetching post data: $e");
    }
  }

  void _checkPremiumStatus() async {
    CustomerInfo customerInfo = await Purchases.getCustomerInfo();

    if (!mounted) return;

    setState(() {
      _isPremium =
          customerInfo.entitlements.all[entitlementID]?.isActive ?? false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: !_isDataLoaded
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF36B37E)),
              ),
            )
          : _postData == null || !_postData!.exists
              ? const Center(
                  child: Text('Post not found',
                      style: TextStyle(color: Colors.white)),
                )
              : _buildPostContent(),
    );
  }

  Widget _buildPostContent() {
    final Size screenSize = MediaQuery.of(context).size;
    final double width = screenSize.width;
    final double height = screenSize.height;

    return ListView(
      physics: const BouncingScrollPhysics(),
      children: [
        PostCard(
          snap: _postData!,
          isBlocked: false,
          isGridView: false,
        ),
        const SizedBox(height: 12),
        Container(
          padding: EdgeInsets.all(width * 0.035),
          margin: EdgeInsets.symmetric(horizontal: width * 0.04),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.green.shade800,
                Colors.green.shade900,
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.green.shade500,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.green.shade700.withOpacity(0.3),
                blurRadius: 8,
                spreadRadius: 0,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: _isPremium
              ? _buildPremiumMessage(width, height)
              : _buildNonPremiumMessage(width, height),
        ),
        SizedBox(height: 20),
      ],
    );
  }

  Widget _buildPremiumMessage(double width, double height) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white.withOpacity(0.3),
                Colors.white.withOpacity(0.1)
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                spreadRadius: 0,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            Icons.verified_user_rounded,
            color: Colors.white,
            size: 22,
          ),
        ),
        SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Premium Experience',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: width * 0.04,
                  color: Colors.white,
                  letterSpacing: 0.3,
                ),
              ),
              SizedBox(height: 3),
              Text(
                'Ad-free browsing with all premium benefits',
                style: TextStyle(
                  fontSize: width * 0.032,
                  color: Colors.white,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        )
      ],
    );
  }

  Widget _buildNonPremiumMessage(double width, double height) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white.withOpacity(0.3),
                Colors.white.withOpacity(0.1)
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                spreadRadius: 0,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            Icons.volunteer_activism_rounded,
            color: Colors.white,
            size: 22,
          ),
        ),
        SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Support Us',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: width * 0.04,
                  color: Colors.white,
                  letterSpacing: 0.3,
                ),
              ),
              SizedBox(height: 3),
              Text(
                'Ads help keep this platform free for everyone. Premium removes ads and adds unlimited messaging.',
                style: TextStyle(
                  fontSize: width * 0.032,
                  color: Colors.white,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
        SizedBox(width: 10),
        Container(
          height: 36,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 4,
                spreadRadius: 0,
                offset: Offset(0, 1),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: perfomMagic,
            child: Text(
              'Go Premium',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.green.shade600,
                letterSpacing: 0.5,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              shadowColor: Colors.transparent,
              padding: EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 8,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              elevation: 0,
            ),
          ),
        ),
      ],
    );
  }

  void perfomMagic() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    CustomerInfo customerInfo = await Purchases.getCustomerInfo();

    if (!mounted) return;

    if (customerInfo.entitlements.all[entitlementID] != null &&
        customerInfo.entitlements.all[entitlementID]?.isActive == true) {
      appData.currentData = WeatherData.generateData();

      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    } else {
      Offerings? offerings;
      try {
        offerings = await Purchases.getOfferings();
      } on PlatformException catch (e) {
        if (!mounted) return;
        await showDialog(
            context: context,
            builder: (BuildContext context) => ShowDialogToDismiss(
                title: "Error",
                content: e.message ?? "Unknown error",
                buttonText: 'OK'));
      }

      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });

      if (offerings == null || offerings.current == null) {
        // offerings are empty, show a message to your user
        if (!mounted) return;
        await showDialog(
            context: context,
            builder: (BuildContext context) => ShowDialogToDismiss(
                title: "Error",
                content: "No offerings available",
                buttonText: 'OK'));
      } else {
        // current offering is available, show paywall
        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => Paywall(offering: offerings!.current!)),
        );
      }
    }
  }
}

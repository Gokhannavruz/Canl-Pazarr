import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:freecycle/src/views/paywall.dart';
import 'package:intl/intl.dart';
import 'package:freecycle/src/components/native_dialog.dart';
import 'package:freecycle/src/model/singletons_data.dart';
import 'package:freecycle/src/model/weather_data.dart';
import 'package:freecycle/src/rvncat_constant.dart';
import 'package:freecycle/src/views/paywallfirstlaunch.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:purchases_flutter/models/offerings_wrapper.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:freecycle/src/model/experiment_manager.dart';

class CreditPage extends StatefulWidget {
  const CreditPage({Key? key}) : super(key: key);

  @override
  _CreditPageState createState() => _CreditPageState();
}

class _CreditPageState extends State<CreditPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<int> _animation;

  RewardedAd? _rewardedAd;
  int watchedAds = 0;
  final adUnitId = Platform.isAndroid
      ? 'ca-app-pub-8445989958080180/1538574301'
      : 'ca-app-pub-8445989958080180/3066395195';
  bool _isAdLoaded = false;
  bool _isAdBeingWatched = false;
  int _totalUsersToday = 100;
  int _totalCreditsToday = 300;
  bool _isLoading = true;
  Timer? _timer;
  final int _dailyGoal = 20;
  int _currentCredit = 0;
  late SharedPreferences prefs;
  String today = DateFormat('yyyy-MM-dd').format(DateTime.now());
  final ValueNotifier<int> _creditNotifier = ValueNotifier<int>(0);

  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _animation = IntTween(begin: 0, end: 0).animate(_controller);
    loadAd();
    _initPrefs();
  }

  Future<void> _initPrefs() async {
    prefs = await SharedPreferences.getInstance();
    await _loadSocialProofData();
    _startDynamicStats();
    await _loadWatchedAds();
    await _initCredit();
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _initCredit() async {
    _currentCredit = await getCredit();
    _creditNotifier.value = _currentCredit;
    _updateCreditAnimation(_currentCredit);
  }

  void _updateCreditAnimation(int newCredit) {
    _animation =
        IntTween(begin: _currentCredit, end: newCredit).animate(_controller);
    _currentCredit = newCredit;
    _controller.forward(from: 0);
  }

  Future<int> getCredit() async {
    DocumentSnapshot doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .get();
    return doc['credit'] ?? 0;
  }

  Future<void> _loadSocialProofData() async {
    String? lastDate = prefs.getString('lastDate');
    if (lastDate != today) {
      _totalUsersToday = 100 + Random().nextInt(50);
      _totalCreditsToday = _totalUsersToday * (3 + Random().nextInt(2));
    } else {
      _totalUsersToday = prefs.getInt('totalUsers') ?? 100;
      _totalCreditsToday = prefs.getInt('totalCredits') ?? 300;
    }
  }

  Future<void> _loadWatchedAds() async {
    String? lastWatchedDate = prefs.getString('lastWatchedDate');
    if (lastWatchedDate != today) {
      watchedAds = 0;
      await prefs.setInt('watchedAds', 0);
      await prefs.setString('lastWatchedDate', today);
    } else {
      watchedAds = prefs.getInt('watchedAds') ?? 0;
    }
  }

  void _startDynamicStats() {
    const oneSec = Duration(seconds: 10);
    _timer = Timer.periodic(oneSec, (Timer timer) {
      setState(() {
        _totalUsersToday += 1;
        _totalCreditsToday += 3 + Random().nextInt(2);
        _saveSocialProofData();
      });
    });
  }

  void _saveSocialProofData() {
    prefs.setString('lastDate', today);
    prefs.setInt('totalUsers', _totalUsersToday);
    prefs.setInt('totalCredits', _totalCreditsToday);
  }

  @override
  void dispose() {
    _rewardedAd?.dispose();
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _watchAd() async {
    if (_rewardedAd == null || !_isAdLoaded || _isAdBeingWatched) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ad is not loaded yet. Please try again later.'),
        ),
      );
      return;
    }

    setState(() {
      _isAdBeingWatched = true;
    });

    _rewardedAd!.show(
      onUserEarnedReward: (AdWithoutView ad, RewardItem rewardItem) async {
        int newCredit = _currentCredit + 1;
        int newWatchedAds = watchedAds + 1;

        await FirebaseFirestore.instance
            .collection('users')
            .doc(FirebaseAuth.instance.currentUser!.uid)
            .update({
          'credit': newCredit,
        });

        prefs.setInt('watchedAds', newWatchedAds);

        setState(() {
          watchedAds = newWatchedAds;
          _creditNotifier.value = newCredit;
          _updateCreditAnimation(newCredit);
        });
      },
    );

    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        setState(() {
          _isAdBeingWatched = false;
          _isAdLoaded = false;
        });
        loadAd();
      },
      onAdFailedToShowFullScreenContent: (ad, err) {
        ad.dispose();
        setState(() {
          _isAdBeingWatched = false;
          _isAdLoaded = false;
        });
        loadAd();
      },
    );
  }

  void loadAd() {
    RewardedAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          setState(() {
            _isAdLoaded = true;
          });
        },
        onAdFailedToLoad: (LoadAdError error) {
          setState(() {
            _isAdLoaded = false;
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: const Color(0xFF1E1E1E),
        appBar: AppBar(
          backgroundColor: const Color(0xFF1E1E1E),
          title:
              const Text('Earn Credits', style: TextStyle(color: Colors.white)),
          elevation: 0,
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SafeArea(
                child: Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              _buildCreditWidget(),
                              const SizedBox(height: 30),
                              _buildExplanationText(),
                              const SizedBox(height: 30),
                              _buildActionButtons(),
                              const SizedBox(height: 30),
                              _buildDailyGoalProgress(),
                              const SizedBox(height: 20),
                              _buildSocialProof(),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ));
  }

  Widget _buildCreditWidget() {
    return Container(
      padding: const EdgeInsets.all(20),
      height: 180,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF3A3A3A), Color(0xFF2A2A2A)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Your Credits',
            style: TextStyle(
                color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 15),
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  '${_animation.value}',
                  style: const TextStyle(
                    fontSize: 60,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4CAF50),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildExplanationText() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: const [
          Icon(Icons.info_outline, color: Colors.white70),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              "Watch ads to earn credits. Use credits to message users and get free items.",
              style: TextStyle(fontSize: 14, color: Colors.white70),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(child: _buildAdWatchingButton()),
        const SizedBox(width: 15),
        Expanded(child: _buildUnlimitedCreditsButton()),
      ],
    );
  }

  Widget _buildAdWatchingButton() {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: const Color(0xFF4CAF50),
        padding: const EdgeInsets.symmetric(vertical: 15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
      ),
      onPressed: _isAdBeingWatched || !_isAdLoaded ? null : _watchAd,
      child: _isAdLoaded && !_isAdBeingWatched
          ? Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.play_circle_outline, size: 20),
                SizedBox(width: 8),
                Text('Watch Ad', style: TextStyle(fontSize: 16)),
              ],
            )
          : const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                strokeWidth: 2,
              ),
            ),
    );
  }

  Widget _buildUnlimitedCreditsButton() {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: const Color(0xFF9C27B0),
        padding: const EdgeInsets.symmetric(vertical: 15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
      ),
      onPressed: performMagic,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.stars, size: 20),
          SizedBox(width: 8),
          Text('Unlimited', style: TextStyle(fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildDailyGoalProgress() {
    return Column(
      children: [
        Text(
          'Daily Goal: $watchedAds / $_dailyGoal',
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: watchedAds / _dailyGoal,
            backgroundColor: const Color(0xFF3A3A3A),
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF4CAF50)),
            minHeight: 10,
          ),
        ),
      ],
    );
  }

  Widget _buildSocialProof() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          const Icon(Icons.people, color: Colors.white70),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Today $_totalUsersToday users earned a total of $_totalCreditsToday credits!',
              style: const TextStyle(fontSize: 14, color: Colors.white70),
            ),
          ),
        ],
      ),
    );
  }

  void performMagic() async {
    setState(() {
      _isLoading = true;
    });

    CustomerInfo customerInfo = await Purchases.getCustomerInfo();

    if (customerInfo.entitlements.all[entitlementID] != null &&
        customerInfo.entitlements.all[entitlementID]?.isActive == true) {
      // Implement your logic for unlimited credits here
      setState(() {
        _isLoading = false;
      });
    } else {
      Offerings? offerings;
      try {
        // Get the appropriate offerings based on experiment variant
        offerings = await Purchases.getOfferings();

        // Log the experiment variant for analytics
        final variant = await ExperimentManager.getCurrentVariant();
        print('RevenueCat Experiment Variant: $variant');

        // Track experiment view for analytics
        final isInTreatment = await ExperimentManager.isInTreatmentGroup();
        print('User is in treatment group: $isInTreatment');
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
        await showDialog(
            context: context,
            builder: (BuildContext context) => ShowDialogToDismiss(
                title: "Error",
                content: "No offerings available",
                buttonText: 'OK'));
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => Paywall(offering: offerings!.current!)),
        );
      }
    }
  }
}

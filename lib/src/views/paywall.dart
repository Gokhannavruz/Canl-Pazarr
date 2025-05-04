import 'dart:io';

import 'package:freecycle/screens/android_substermsofuse.dart';
import 'package:freecycle/screens/country_state_city_picker.dart';
import 'package:freecycle/screens/discoverPage2.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:freecycle/responsive/mobile_screen_layout.dart';
import 'package:freecycle/responsive/responsive_layout_screen.dart';
import 'package:freecycle/responsive/web_screen_layout.dart';
import 'package:freecycle/src/model/singletons_data.dart';
import 'package:freecycle/src/rvncat_constant.dart';
import 'package:freecycle/src/views/subscriptionterms_page.dart';

class Paywall extends StatefulWidget {
  final Offering offering;

  const Paywall({Key? key, required this.offering}) : super(key: key);

  @override
  _PaywallState createState() => _PaywallState();
}

class _PaywallState extends State<Paywall> {
  int? _selectedPackageIndex = 2;
  late List<Package> _sortedPackages;

  @override
  void initState() {
    super.initState();
    _sortedPackages = List<Package>.from(widget.offering.availablePackages);
    _sortPackages();
  }

  void _sortPackages() {
    _sortedPackages.sort((a, b) {
      return _getPackagePriority(a.packageType) -
          _getPackagePriority(b.packageType);
    });
  }

  int _getPackagePriority(PackageType packageType) {
    switch (packageType) {
      case PackageType.weekly:
        return 0;
      case PackageType.monthly:
        return 1;
      case PackageType.annual:
        return 2;
      default:
        return 3;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF2E7D32),
              Color(0xFF1565C0),
            ],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Padding(
                      padding: EdgeInsets.all(constraints.maxWidth * 0.05),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          Text(
                            'Unlock Premium',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: constraints.maxWidth * 0.07,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: constraints.maxHeight * 0.02),
                          _premiumFeaturesList(constraints),
                          SizedBox(height: constraints.maxHeight * 0.03),
                          Text(
                            'Choose Your Plan',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: constraints.maxWidth * 0.05,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: constraints.maxHeight * 0.02),
                          ..._buildPackageOptions(constraints),
                          SizedBox(height: constraints.maxHeight * 0.03),
                          ElevatedButton(
                            onPressed: _selectedPackageIndex != null
                                ? _subscribeNow
                                : null,
                            style: ElevatedButton.styleFrom(
                              foregroundColor: Color(0xFF1565C0),
                              backgroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(
                                  vertical: constraints.maxHeight * 0.02),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            child: Text(
                              'Start Premium',
                              style: TextStyle(
                                fontSize: constraints.maxWidth * 0.045,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          SizedBox(height: constraints.maxHeight * 0.02),
                          TextButton(
                            onPressed: () {
                              if (Platform.isIOS) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const SubscriptionTermsPage(),
                                  ),
                                );
                              } else {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const SubscriptionTermsPageAndroid(),
                                  ),
                                );
                              }
                            },
                            child: Text(
                              'Subscription terms',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: constraints.maxWidth * 0.035,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  List<Widget> _buildPackageOptions(BoxConstraints constraints) {
    return _sortedPackages.asMap().entries.map((entry) {
      int index = entry.key;
      Package package = entry.value;
      bool isSelected = _selectedPackageIndex == index;

      return Padding(
        padding: EdgeInsets.only(bottom: constraints.maxHeight * 0.012),
        child: GestureDetector(
          onTap: () {
            setState(() {
              _selectedPackageIndex = index;
            });
          },
          child: AnimatedContainer(
            duration: Duration(milliseconds: 300),
            padding: EdgeInsets.all(constraints.maxWidth * 0.04),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              gradient: isSelected
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.blue.withOpacity(0.7),
                        Colors.green.withOpacity(0.7),
                      ],
                    )
                  : null,
              color: isSelected ? null : Colors.white.withOpacity(0.1),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        spreadRadius: 1,
                      )
                    ]
                  : null,
              border: Border.all(
                color:
                    isSelected ? Colors.white : Colors.white.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getSubscriptionType(package),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: constraints.maxWidth * 0.045,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: constraints.maxHeight * 0.005),
                      Text(
                        package.storeProduct.priceString,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: constraints.maxWidth * 0.04,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_getSavingsText(package).isNotEmpty)
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: constraints.maxWidth * 0.02,
                      vertical: constraints.maxHeight * 0.005,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.white.withOpacity(0.2)
                          : Colors.green.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _getSavingsText(package),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: constraints.maxWidth * 0.035,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    }).toList();
  }

  Widget _premiumFeaturesList(BoxConstraints constraints) {
    return Column(
      children: [
        _premiumFeature(
            'Unlimited Messaging Credit', Icons.message, constraints),
        _premiumFeature('Unlimited Product Purchasing Rights',
            Icons.shopping_bag, constraints),
        _premiumFeature(
            'Ad-Free Experience', Icons.remove_red_eye, constraints),
        _premiumFeature(
            'Priority customer support', Icons.support_agent, constraints),
      ],
    );
  }

  Widget _premiumFeature(
      String title, IconData icon, BoxConstraints constraints) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: constraints.maxHeight * 0.01),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(constraints.maxWidth * 0.02),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: constraints.maxWidth * 0.05,
            ),
          ),
          SizedBox(width: constraints.maxWidth * 0.04),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: Colors.white,
                fontSize: constraints.maxWidth * 0.035,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getSubscriptionType(Package package) {
    switch (package.packageType) {
      case PackageType.weekly:
        return 'Weekly';
      case PackageType.monthly:
        return 'Monthly';
      case PackageType.annual:
        return 'Annually';
      default:
        return 'Unknown';
    }
  }

  String _getSavingsText(Package package) {
    if (package.packageType == PackageType.weekly) return '';

    double weeklyPrice = _sortedPackages
        .firstWhere((p) => p.packageType == PackageType.weekly)
        .storeProduct
        .price;
    double packagePrice = package.storeProduct.price;

    int weeks;
    switch (package.packageType) {
      case PackageType.monthly:
        weeks = 4;
        break;
      case PackageType.annual:
        weeks = 52;
        break;
      default:
        weeks = 0;
    }

    double totalWeeklyPrice = weeklyPrice * weeks;
    double savings = totalWeeklyPrice - packagePrice;
    double savingsPercentage = (savings / totalWeeklyPrice) * 100;

    return 'Save ${savingsPercentage.toStringAsFixed(0)}%';
  }

  void _subscribeNow() async {
    try {
      CustomerInfo customerInfo = await Purchases.purchasePackage(
          _sortedPackages[_selectedPackageIndex!]);
      EntitlementInfo? entitlement =
          customerInfo.entitlements.all[entitlementID];

      if (entitlement?.isActive ?? false) {
        // Satın alma başarılı oldu, şimdi kullanıcının durumunu güncelleyebiliriz
        await updatePremiumStatus(true);
        await updateCredits(9999999);

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const ResponsiveLayout(
              mobileScreenLayout: MobileScreenLayout(),
              webScreenLayout: WebScreenLayout(),
            ),
          ),
        );
      } else {
        // Satın alma başarısız oldu veya entitlement aktif değil
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Subscription failed. Please try again.')),
        );
      }
    } catch (e) {
      print('Error during purchase: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred. Please try again later.')),
      );
    }
  }

  Future<void> updatePremiumStatus(bool isPremium) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .update({'is_premium': isPremium});

    if (!isPremium) {
      await updateCredits(0);
    }
  }

  Future<void> updateCredits(int credits) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .update({'credit': credits});
  }
}

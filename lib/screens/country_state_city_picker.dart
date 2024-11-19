import 'package:Freecycle/responsive/mobile_screen_layout.dart';
import 'package:Freecycle/responsive/responsive_layout_screen.dart';
import 'package:Freecycle/responsive/web_screen_layout.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:csc_picker/csc_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CountryStateCityForFirstSelect extends StatefulWidget {
  const CountryStateCityForFirstSelect({
    Key? key,
  }) : super(key: key);

  @override
  _CountryStateCityForFirstSelectState createState() =>
      _CountryStateCityForFirstSelectState();
}

class _CountryStateCityForFirstSelectState
    extends State<CountryStateCityForFirstSelect> {
  /// Variables to store country state city data in onChanged method.
  String countryValue = "";
  String stateValue = "";
  String cityValue = "";
  String address = "";
  NativeAd? _nativeAd;
  bool isAdLoaded = false;

  // initialize the native ad
  @override
  void initState() {
    super.initState();
    getUserData();
  }

  // dispose the native ad
  @override
  void dispose() {
    _nativeAd?.dispose();
    super.dispose();
  }

  // GET USER COUNTRY, STATE, AND CITY DATA
  Future<void> getUserData() async {
    final currentUser = await FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .get();

    setState(() {
      countryValue = currentUser.get('country') ?? "";
      stateValue = currentUser.get('state') ?? "";
      cityValue = currentUser.get('city') ?? "";
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Handle back button press here
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const ResponsiveLayout(
              mobileScreenLayout: MobileScreenLayout(),
              webScreenLayout: WebScreenLayout(),
            ),
          ),
        );
        return false; // Return false to prevent default back button behavior
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.black,
          title: const Text("Location"),
        ),
        body: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            height: 600,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(
                      16.0), // Adjust the padding for spacing
                  child: Container(
                    padding: const EdgeInsets.all(
                        16.0), // Inner padding for text container
                    decoration: BoxDecoration(
                      color:
                          Colors.black87, // Background color for the container
                      borderRadius:
                          BorderRadius.circular(10), // Rounded corners
                    ),
                    child: Text(
                      "To see products in your area,\nplease select your location below",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center, // Center align text
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Kullanıcı daha önce ülke seçtiyse, CSCPicker'ı bu ülkeye göre ayarla

                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    CSCPicker(
                      /// Enable disable auto validation.
                      showStates: true,
                      showCities: true,
                      flagState: CountryFlag.SHOW_IN_DROP_DOWN_ONLY,

                      /// Enable disable dropdown dialog animation.
                      dropdownDecoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.white.withOpacity(0.2),
                      ),
                      disabledDropdownDecoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.grey.withOpacity(0.1),
                      ),
                      selectedItemStyle: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                      dropdownHeadingStyle: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                      ),
                      dropdownItemStyle: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),

                      /// Callback you will get country object as a result.
                      onCountryChanged: (value) {
                        setState(() {
                          countryValue = value ?? "";
                        });
                      },

                      /// Callback you will get state object as a result.
                      onStateChanged: (value) {
                        setState(() {
                          stateValue = value ?? "";
                        });
                      },

                      /// Callback you will get city object as a result.
                      onCityChanged: (value) {
                        setState(() {
                          cityValue = value ?? "";
                        });
                      },
                    ),
                    SizedBox(height: 25),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(90, 35),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        primary: Colors.blue,
                        onPrimary: Colors.white,
                      ),
                      onPressed: () async {
                        setState(() {
                          address = "$cityValue, $stateValue, $countryValue";
                        });

                        // update isUserFirstLaunch to false
                        // firstLaunch değerini false yap
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setBool('firstLaunch', false);
                        await prefs.setBool('locationSelected', true);

                        FirebaseFirestore.instance
                            .collection('users')
                            .doc(FirebaseAuth.instance.currentUser!.uid)
                            .update({
                          'country': countryValue,
                          'state': stateValue,
                          'city': cityValue,
                          'address': address,
                        });
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (context) => const ResponsiveLayout(
                              mobileScreenLayout: MobileScreenLayout(),
                              webScreenLayout: WebScreenLayout(),
                            ),
                          ),
                        );
                      },
                      child: const Text("Save"),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

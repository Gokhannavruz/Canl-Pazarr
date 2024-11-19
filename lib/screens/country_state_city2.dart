import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:csc_picker/csc_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class CountryStateCity extends StatefulWidget {
  const CountryStateCity({
    Key? key,
  }) : super(key: key);

  @override
  _CountryStateCityState createState() => _CountryStateCityState();
}

class _CountryStateCityState extends State<CountryStateCity> {
  /// Variables to store country state city data in onChanged method.
  late String countryValue;
  late String stateValue;
  late String cityValue;
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
    return Scaffold(
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
                    color: Colors.black87, // Background color for the container
                    borderRadius: BorderRadius.circular(10), // Rounded corners
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
                    currentCountry: countryValue,
                    currentState: stateValue,
                    currentCity: cityValue,

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
                    onPressed: () {
                      setState(() {
                        address = "$cityValue, $stateValue, $countryValue";
                      });

                      FirebaseFirestore.instance
                          .collection('users')
                          .doc(FirebaseAuth.instance.currentUser!.uid)
                          .update({
                        'country': countryValue,
                        'state': stateValue,
                        'city': cityValue,
                        'address': address,
                      });
                      Navigator.pop(context);
                    },
                    child: const Text("Save"),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

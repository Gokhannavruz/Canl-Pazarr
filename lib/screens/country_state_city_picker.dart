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
  }

  // dispose the native ad
  @override
  void dispose() {
    _nativeAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    GlobalKey<CSCPickerState> cscPickerKey = GlobalKey();

    void getUserData() async {
      final currentUser = await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .get();
      setState(() {
        countryValue = currentUser.get('country');
        stateValue = currentUser.get('state');
        cityValue = currentUser.get('city');
      });
    }

    @override
    void initState() {
      getUserData();
      super.initState();
    }

    // get curret user data
    var currentUser = FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .get();

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
              const SizedBox(
                height: 20,
              ),

              ///Adding CSC Picker Widget in app
              CSCPicker(
                ///Enable disable state dropdown [OPTIONAL PARAMETER]
                showStates: true,

                /// Enable disable city drop down [OPTIONAL PARAMETER]
                showCities: true,

                ///Enable (get flag with country name) / Disable (Disable flag) / ShowInDropdownOnly (display flag in dropdown only) [OPTIONAL PARAMETER]
                flagState: CountryFlag.SHOW_IN_DROP_DOWN_ONLY,

                ///Dropdown box decoration to style your dropdown selector [OPTIONAL PARAMETER] (USE with disabledDropdownDecoration)
                dropdownDecoration: BoxDecoration(
                  shape: BoxShape.rectangle,
                  borderRadius: const BorderRadius.all(
                    Radius.circular(10),
                  ),
                  color: Colors.white,
                  border: Border.all(
                    color: const Color.fromARGB(255, 255, 255, 255),
                    width: 1,
                  ),
                ),

                ///Disabled Dropdown box decoration to style your dropdown selector [OPTIONAL PARAMETER]  (USE with disabled dropdownDecoration)
                disabledDropdownDecoration: BoxDecoration(
                    borderRadius: const BorderRadius.all(Radius.circular(10)),
                    color: const Color.fromARGB(255, 255, 255, 255),
                    border: Border.all(
                        color: const Color.fromARGB(255, 255, 255, 255),
                        width: 1)),

                ///placeholders for dropdown search field
                countrySearchPlaceholder: "Country",
                stateSearchPlaceholder: "State",
                citySearchPlaceholder: "City",

                ///labels for dropdown
                countryDropdownLabel: "Country",
                stateDropdownLabel: "State",
                cityDropdownLabel: "City",

                ///Disable country dropdown (Note: use it with default country)
                //disableCountry: true,

                ///selected item style [OPTIONAL PARAMETER]
                selectedItemStyle: const TextStyle(
                  color: Colors.black,
                  fontSize: 17,
                ),

                ///DropdownDialog Heading style [OPTIONAL PARAMETER]
                dropdownHeadingStyle: const TextStyle(
                    color: Color.fromARGB(255, 255, 255, 255),
                    fontSize: 17,
                    fontWeight: FontWeight.bold),

                ///DropdownDialog Item style [OPTIONAL PARAMETER]
                dropdownItemStyle: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                ),

                ///Dialog box radius [OPTIONAL PARAMETER]
                dropdownDialogRadius: 10.0,

                ///Search bar radius [OPTIONAL PARAMETER]
                searchBarRadius: 10.0,

                ///triggers once country selected in dropdown
                onCountryChanged: (value) {
                  setState(() {
                    ///store value in country variable
                    countryValue = value;
                  });
                },

                ///triggers once state selected in dropdown
                onStateChanged: (value) {
                  setState(() {
                    ///store value in state variable
                    stateValue = value ?? "";
                  });
                },

                ///triggers once city selected in dropdown
                onCityChanged: (value) {
                  setState(() {
                    ///store value in city variable
                    cityValue = value ?? "";
                  });
                },

                ///Show only specific countries using country filter
                // countryFilter: ["United States", "Canada", "Mexico"],
              ),

              ///print newly selected country state and city in Text Widget
              const SizedBox(
                height: 25,
              ),
              TextButton(
                style: TextButton.styleFrom(
                  minimumSize: const Size(80, 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  foregroundColor: Colors.white,
                  backgroundColor: const Color.fromARGB(255, 49, 79, 180),
                ),
                onPressed: () {
                  // update the country, state and city fields of the current user
                  FirebaseFirestore.instance
                      .collection('users')
                      .doc(FirebaseAuth.instance.currentUser!.uid)
                      .update({
                    'country': countryValue,
                    'state': stateValue,
                    'city': cityValue,
                  });
                  Navigator.of(context).pop();
                },
                child: const Text('Save'),
              ),
              const SizedBox(
                height: 65,
              ),
              // const Text(
              //   "Select where you want to be matched with other users from. \n \n If you don't select a country or a city, you will be matched with users from all over the world. \n \n If you select a country, you will be matched with users from that country. If you select a city, you will be matched with users from that city.",
              //   style: TextStyle(
              //     fontSize: 17,
              //   ),
              // ),
              // text but with nice formatting
              // Column(
              //   children: [
              //     Row(
              //       children: const [
              //         Padding(
              //           padding: EdgeInsets.only(bottom: 15.0),
              //           child: Icon(
              //             Icons.info_outline,
              //             color: Color.fromARGB(255, 250, 250, 250),
              //             size: 20,
              //           ),
              //         ),
              //         SizedBox(
              //           width: 10,
              //         ),
              //         Expanded(
              //           child: Padding(
              //             padding: EdgeInsets.only(left: 8.0),
              //             child: Text(
              //               "Select where you want to be matched with other users from.",
              //               style: TextStyle(
              //                 fontSize: 17,
              //                 color: Color.fromARGB(255, 250, 250, 250),
              //               ),
              //               softWrap: true,
              //             ),
              //           ),
              //         ),
              //       ],
              //     ),
              //     const SizedBox(
              //       height: 10,
              //     ),
              //     Row(
              //       children: const [
              //         Padding(
              //           padding: EdgeInsets.only(bottom: 35.0),
              //           child: Icon(
              //             Icons.info_outline,
              //             color: Color.fromARGB(255, 250, 250, 250),
              //             size: 20,
              //           ),
              //         ),
              //         SizedBox(
              //           width: 10,
              //         ),
              //         Expanded(
              //           child: Padding(
              //             padding: EdgeInsets.only(left: 8.0),
              //             child: Text(
              //               "If you don't select a country or a city, you will be matched with users from all over the world.",
              //               style: TextStyle(
              //                 fontSize: 17,
              //                 color: Color.fromARGB(255, 250, 250, 250),
              //               ),
              //               softWrap: true,
              //             ),
              //           ),
              //         ),
              //       ],
              //     ),
              //     const SizedBox(
              //       height: 10,
              //     ),
              //     Row(
              //       children: const [
              //         Padding(
              //           padding: EdgeInsets.only(bottom: 55),
              //           child: Icon(
              //             Icons.info_outline,
              //             color: Color.fromARGB(255, 250, 250, 250),
              //             size: 20,
              //           ),
              //         ),
              //         SizedBox(
              //           width: 10,
              //         ),
              //         Expanded(
              //           child: Padding(
              //             padding: EdgeInsets.only(left: 8.0),
              //             child: Text(
              //               "If you select a country, you will be matched with users from that country. If you select a city, you will be matched with users from that city.",
              //               style: TextStyle(
              //                 fontSize: 17,
              //                 color: Color.fromARGB(255, 250, 250, 250),
              //               ),
              //               softWrap: true,
              //             ),
              //           ),
              //         ),
              //       ],
              //     ),
              //   ],
              // ),

              SizedBox(
                height: MediaQuery.of(context).size.height * 0.36,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:country_state_city_picker/country_state_city_picker.dart';
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
  String address = "";
  NativeAd? _nativeAd;
  bool isAdLoaded = false;
  bool isLoading = true;

  // Add function to clean country names
  String _cleanCountryName(String? countryName) {
    if (countryName == null || countryName.isEmpty) return '';

    // Remove flag emojis (country flag emoji is typically 2 regional indicator symbols)
    // Each regional indicator symbol is 2 bytes in UTF-16
    if (countryName.length >= 2 &&
        countryName.codeUnitAt(0) >= 0xD83C &&
        countryName.codeUnitAt(1) >= 0xDDE6) {
      // Find the first non-emoji character
      int startIndex = 0;
      while (startIndex < countryName.length &&
          startIndex + 1 < countryName.length &&
          countryName.codeUnitAt(startIndex) >= 0xD83C &&
          countryName.codeUnitAt(startIndex + 1) >= 0xDDE6) {
        startIndex += 2;
      }

      // Remove extra spaces after flag emoji
      return countryName.substring(startIndex).trim();
    }

    return countryName;
  }

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

  // GET USER DATA
  Future<void> getUserData() async {
    setState(() {
      isLoading = true;
    });

    try {
      // Sadece yükleme işlemini tamamla
      // Country her zaman boş olacak
      setState(() {
        countryValue = "";
        stateValue = "";
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching user data: $e');
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Ekran boyutunu al
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.height < 700;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_rounded,
            color: Colors.white,
            size: 20,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text(
          "Location",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Colors.white,
              ),
            )
          : Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black,
                    Colors.blue.shade900.withOpacity(0.2),
                    Colors.black,
                  ],
                ),
              ),
              child: SafeArea(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(height: isSmallScreen ? 20 : 30),
                        // Lokasyon ikonu
                        Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.blue.shade700.withOpacity(0.7),
                                Colors.blue.shade900.withOpacity(0.7),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.blue.shade700.withOpacity(0.3),
                                blurRadius: 20,
                                spreadRadius: 0,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.location_on_rounded,
                            color: Colors.white,
                            size: 35,
                          ),
                        ),

                        SizedBox(height: isSmallScreen ? 16 : 24),

                        // Başlık
                        const Text(
                          "Choose Your Location",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                          textAlign: TextAlign.center,
                        ),

                        SizedBox(height: isSmallScreen ? 8 : 12),

                        // Açıklama
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.08),
                            ),
                          ),
                          child: const Text(
                            "To see products in your area,\nplease select your location below",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              height: 1.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),

                        SizedBox(height: isSmallScreen ? 25 : 35),

                        // Country seçici container
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.white.withOpacity(0.07),
                                Colors.white.withOpacity(0.04),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.1),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 15,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Country State Picker
                              SelectState(
                                // Style
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                ),

                                // Dropdown decoration
                                dropdownColor: Colors.black,

                                // Callbacks
                                onCountryChanged: (value) {
                                  setState(() {
                                    countryValue = _cleanCountryName(value);
                                    // Reset state when country changes
                                    stateValue = "";
                                  });
                                },

                                onStateChanged: (value) {
                                  setState(() {
                                    stateValue = value;
                                  });
                                },

                                onCityChanged: (value) {
                                  // Not used in this implementation
                                },
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: isSmallScreen ? 25 : 35),

                        // Selected location summary if available
                        if (countryValue.isNotEmpty)
                          Container(
                            margin: const EdgeInsets.only(bottom: 25),
                            padding: const EdgeInsets.symmetric(
                                vertical: 12, horizontal: 16),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.06),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.1),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  stateValue.isNotEmpty
                                      ? Icons.place_rounded
                                      : Icons.public_rounded,
                                  color: Colors.green,
                                  size: 18,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    stateValue.isNotEmpty
                                        ? "$stateValue, $countryValue"
                                        : countryValue,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 15,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Icon(
                                  Icons.check_circle_outline,
                                  color: Colors.green,
                                  size: 16,
                                ),
                              ],
                            ),
                          ),

                        // Save Button
                        Container(
                          width: double.infinity,
                          height: 56,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: countryValue.isNotEmpty
                                  ? [Colors.blue.shade500, Colors.blue.shade700]
                                  : [
                                      Colors.grey.shade700,
                                      Colors.grey.shade800
                                    ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: countryValue.isNotEmpty
                                ? [
                                    BoxShadow(
                                      color:
                                          Colors.blue.shade900.withOpacity(0.4),
                                      spreadRadius: 0,
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ]
                                : [],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: countryValue.isNotEmpty
                                  ? () {
                                      String cleanedCountry =
                                          _cleanCountryName(countryValue);
                                      setState(() {
                                        address = stateValue.isNotEmpty
                                            ? "$stateValue, $cleanedCountry"
                                            : cleanedCountry;
                                      });

                                      FirebaseFirestore.instance
                                          .collection('users')
                                          .doc(FirebaseAuth
                                              .instance.currentUser!.uid)
                                          .update({
                                        'country': cleanedCountry,
                                        'state': stateValue.isEmpty
                                            ? ""
                                            : stateValue,
                                        'city':
                                            "", // City alanını boş string olarak ayarla
                                        'address': address,
                                      });
                                      Navigator.pop(context);
                                    }
                                  : null,
                              child: Center(
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.check_circle_outline_rounded,
                                      color: countryValue.isNotEmpty
                                          ? Colors.white
                                          : Colors.grey.shade400,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      "Save Location",
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: countryValue.isNotEmpty
                                            ? Colors.white
                                            : Colors.grey.shade400,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}

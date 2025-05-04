import 'package:freecycle/responsive/mobile_screen_layout.dart';
import 'package:freecycle/responsive/responsive_layout_screen.dart';
import 'package:freecycle/responsive/web_screen_layout.dart';
import 'package:freecycle/screens/login_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:country_state_city_picker/country_state_city_picker.dart';

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
  String countryValue = "";
  String stateValue = "";
  String address = "";
  bool isLoading = true;
  User? currentUser;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
    });

    try {
      currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser == null) {
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const LoginScreen(),
          ),
        );
        return;
      }

      // Sadece yükleme işlemini tamamla
      // Country her zaman boş olacak
      setState(() {
        countryValue = "";
        stateValue = "";
        isLoading = false;
      });
    } catch (e) {
      print('Error initializing data: $e');
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _saveLocation() async {
    if (countryValue.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please select a country',
            style: GoogleFonts.poppins(
              fontSize: 14,
            ),
          ),
          backgroundColor: Colors.red.shade800,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }

    try {
      setState(() {
        isLoading = true;
      });

      // Clean country name
      String cleanedCountry = _cleanCountryName(countryValue);

      // Konum bilgilerini kaydet
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .update({
        'country': cleanedCountry,
        'state': stateValue.isEmpty ? "" : stateValue,
        'city': "",
        'address': stateValue.isNotEmpty
            ? "$stateValue, $cleanedCountry"
            : cleanedCountry,
      });

      // firstLaunch değerini güncelle
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('firstLaunch', false);
      await prefs.setBool('locationSelected', true);

      if (!mounted) return;

      // Ana sayfaya yönlendir
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const ResponsiveLayout(
            mobileScreenLayout: MobileScreenLayout(),
            webScreenLayout: WebScreenLayout(),
          ),
        ),
      );
    } catch (e) {
      print('Error saving location: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error saving location: $e',
              style: GoogleFonts.poppins(
                fontSize: 14,
              ),
            ),
            backgroundColor: Colors.red.shade800,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        setState(() {
          isLoading = false;
        });
      }
    }
  }

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
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => const ResponsiveLayout(
                  mobileScreenLayout: MobileScreenLayout(),
                  webScreenLayout: WebScreenLayout(),
                ),
              ),
            );
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

                                // Labels
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
                                  ? _saveLocation
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

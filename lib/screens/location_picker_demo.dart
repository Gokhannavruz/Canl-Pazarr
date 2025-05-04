import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:country_state_city_picker/country_state_city_picker.dart';

class LocationPickerDemo extends StatefulWidget {
  const LocationPickerDemo({Key? key}) : super(key: key);

  @override
  _LocationPickerDemoState createState() => _LocationPickerDemoState();
}

class _LocationPickerDemoState extends State<LocationPickerDemo> {
  String? countryValue;
  String? stateValue;
  String? cityValue;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    getUserData();
  }

  Future<void> getUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final currentUser = await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .get();

      if (mounted && currentUser.exists) {
        final data = currentUser.data();
        setState(() {
          countryValue = data?['country'] as String? ?? "";
          stateValue = data?['state'] as String? ?? "";
          cityValue = data?['city'] as String? ?? "";
        });
      }
    } catch (e) {
      print("Error getting user data: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> saveLocation() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Create the address string
      final address = "$stateValue, $countryValue";

      await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .update({
        'country': countryValue,
        'state': stateValue,
        'city': cityValue,
        'address': address,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Location saved successfully!',
              style: GoogleFonts.poppins(fontSize: 14),
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      print("Error saving location: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error saving location: $e',
              style: GoogleFonts.poppins(fontSize: 14),
            ),
            backgroundColor: Colors.red.shade800,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          "Location",
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.white,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.white),
            )
          : Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black,
                    Colors.blue.shade900.withOpacity(0.3),
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
                      children: [
                        const SizedBox(height: 30),
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.location_on_rounded,
                            color: Colors.blue,
                            size: 40,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          "Update Your Location",
                          style: GoogleFonts.poppins(
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.1),
                            ),
                          ),
                          child: Text(
                            "Please select your country, state, and city to help you connect with nearby users.",
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.7),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 40),

                        // Location Picker Container
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.1),
                            ),
                          ),
                          child: Column(
                            children: [
                              Container(
                                height: 180,
                                child: ClipRect(
                                  child: DefaultTextStyle(
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontSize: 14,
                                    ),
                                    child: Theme(
                                      data: Theme.of(context).copyWith(
                                        // Customize dropdown menu theme
                                        canvasColor: const Color(0xFF1E1E1E),
                                        dividerColor:
                                            Colors.white.withOpacity(0.1),
                                        colorScheme: const ColorScheme.dark(
                                          primary: Colors.white,
                                          onPrimary: Colors.white,
                                          secondary: Colors.white,
                                          onSecondary: Colors.white,
                                          onSurface: Colors.white,
                                          surface: Colors.white,
                                        ),
                                        textSelectionTheme:
                                            const TextSelectionThemeData(
                                          cursorColor: Colors.white,
                                          selectionColor: Colors.white24,
                                          selectionHandleColor: Colors.white,
                                        ),
                                        iconTheme: const IconThemeData(
                                          color: Colors.white,
                                        ),
                                        appBarTheme: const AppBarTheme(
                                          iconTheme: IconThemeData(
                                            color: Colors.white,
                                          ),
                                          actionsIconTheme: IconThemeData(
                                            color: Colors.white,
                                          ),
                                        ),
                                        textTheme: TextTheme(
                                          titleMedium: GoogleFonts.poppins(
                                            color: Colors.white,
                                            fontSize: 16,
                                          ),
                                          bodyMedium: GoogleFonts.poppins(
                                            color: Colors.white,
                                          ),
                                          bodyLarge: GoogleFonts.poppins(
                                            color: Colors.white,
                                          ),
                                          bodySmall: GoogleFonts.poppins(
                                            color: Colors.white,
                                          ),
                                          labelMedium: GoogleFonts.poppins(
                                            color: Colors.white,
                                          ),
                                          labelLarge: GoogleFonts.poppins(
                                            color: Colors.white,
                                          ),
                                        ),
                                        inputDecorationTheme:
                                            InputDecorationTheme(
                                          filled: true,
                                          fillColor:
                                              Colors.white.withOpacity(0.05),
                                          hintStyle: GoogleFonts.poppins(
                                            color:
                                                Colors.white.withOpacity(0.5),
                                            fontSize: 14,
                                          ),
                                          prefixIconColor: Colors.white,
                                          suffixIconColor: Colors.white,
                                          iconColor: Colors.white,
                                          border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            borderSide: BorderSide(
                                              color:
                                                  Colors.white.withOpacity(0.1),
                                            ),
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            borderSide: BorderSide(
                                              color:
                                                  Colors.white.withOpacity(0.1),
                                            ),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            borderSide: const BorderSide(
                                              color: Colors.white,
                                              width: 1.5,
                                            ),
                                          ),
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 14,
                                          ),
                                        ),
                                        scrollbarTheme: ScrollbarThemeData(
                                          radius: const Radius.circular(8),
                                          thickness:
                                              MaterialStateProperty.all(6),
                                          thumbColor: MaterialStateProperty.all(
                                            Colors.white.withOpacity(0.5),
                                          ),
                                        ),
                                        cupertinoOverrideTheme:
                                            const CupertinoThemeData(
                                          primaryColor: Colors.white,
                                        ),
                                      ),
                                      child: SelectState(
                                        onCountryChanged: (value) {
                                          if (mounted && value != null) {
                                            setState(() {
                                              countryValue = value;
                                            });
                                          } else if (mounted) {
                                            setState(() {
                                              countryValue = "";
                                            });
                                          }
                                        },
                                        onStateChanged: (value) {
                                          if (mounted) {
                                            setState(() {
                                              stateValue = value;
                                            });
                                          }
                                        },
                                        onCityChanged: (value) {
                                          if (mounted) {
                                            setState(() {
                                              cityValue = value;
                                            });
                                          }
                                        },
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 40),

                        // Selected Location Display (Optional)
                        if (countryValue != null && countryValue!.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.1),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Selected Location:",
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.location_on,
                                      color: Colors.blue,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        cityValue != null &&
                                                cityValue!.isNotEmpty
                                            ? "$cityValue, $stateValue, $countryValue"
                                            : "$stateValue, $countryValue",
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          color: Colors.white.withOpacity(0.9),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                        const SizedBox(height: 40),

                        // Save button
                        Container(
                          width: double.infinity,
                          height: 56,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.blue.shade400,
                                Colors.blue.shade600
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.blue.shade700.withOpacity(0.3),
                                spreadRadius: 0,
                                blurRadius: 12,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: saveLocation,
                              child: Center(
                                child: Text(
                                  "Save Location",
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}

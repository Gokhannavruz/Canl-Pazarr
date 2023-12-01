import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:image_picker/image_picker.dart';
import 'package:frees/responsive/mobile_screen_layout.dart';
import 'package:frees/responsive/responsive_layout_screen.dart';
import 'package:intl_phone_field/intl_phone_field.dart';

import '../resources/auth_methods.dart';
import '../responsive/web_screen_layout.dart';
import '../utils/utils.dart';

class PhoneVerificationScreen extends StatefulWidget {
  const PhoneVerificationScreen({Key? key}) : super(key: key);

  @override
  State<PhoneVerificationScreen> createState() =>
      _PhoneVerificationScreenState();
}

class _PhoneVerificationScreenState extends State<PhoneVerificationScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  NativeAd? _nativeAd;
  bool isAdLoaded = false;
  // username controller
  bool _isLoading = false;
  Uint8List? _image;
  double screenHeight = 0;
  double screenWidth = 0;
  double bottom = 0;
  String otpPin = "";
  String countryDial = "+1";
  String verID = "";
  int screenState = 0;
  Color blue = const Color.fromARGB(255, 0, 0, 0);

  // init state
  @override
  void initState() {
    super.initState();
    _loadNativeAd(adUnits[currentAdIndex]);
  }

  // dispose
  @override
  void dispose() {
    super.dispose();
    _phoneController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _emailController.dispose();
    _bioController.dispose();
    _nativeAd?.dispose();
  }

  // Define a list of ad units
  List<String> adUnits = [
    'ca-app-pub-8445989958080180/2627192019',
    'ca-app-pub-8445989958080180/6254627595',
    'ca-app-pub-8445989958080180/5488340837',
    // Add more ad units as needed
  ];

  // Counter to keep track of the current ad
  int currentAdIndex = 0;

  void _loadNativeAd(String adUnitId) {
    // Dispose of the previous ad if it exists
    _nativeAd?.dispose();

    _nativeAd = NativeAd(
      adUnitId: adUnitId,
      factoryId: 'listTile',
      request: const AdRequest(),
      listener: NativeAdListener(
        onAdLoaded: (Ad ad) {
          var add = ad as NativeAd;
          print("**** AD ***** ${add.responseInfo}");
          setState(() {
            _nativeAd = add;
            isAdLoaded = true;
          });
        },
        onAdFailedToLoad: (Ad ad, LoadAdError error) {
          // Dispose the ad here to free resources.
          ad.dispose();
          print('Ad load failed (code=${error.code} message=${error.message})');
        },
        onAdOpened: (Ad ad) => print('Ad opened.'),
        onAdClosed: (Ad ad) => print('Ad closed.'),
        onAdImpression: (Ad ad) => print('Ad impression.'),
        onAdClicked: (Ad ad) => print('Ad clicked.'),
      ),
    );

    _nativeAd!.load();
  }

  void loadNextAd() {
    // Check if an ad is already loaded
    if (isAdLoaded) {
      setState(() {
        isAdLoaded = false;
      });

      // Dispose of the current ad if it exists
      if (_nativeAd != null) {
        _nativeAd!.dispose();
      }
    }

    // Load the ad using the current ad unit
    _loadNativeAd(adUnits[currentAdIndex]);

    // Increment the counter for the next ad
    currentAdIndex = (currentAdIndex + 1) % adUnits.length;
  }

  Future<void> verifyPhone(String number) async {
    // if phone number already in use return error
    if (await FirebaseFirestore.instance
        .collection('users')
        .where('phone_number', isEqualTo: _phoneController.text)
        .limit(1)
        .get()
        .then((value) => value.docs.isNotEmpty)) {
      showSnackBarText("Phone number already in use");
      return;
    }
    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: number,
      timeout: const Duration(seconds: 60),
      verificationCompleted: (PhoneAuthCredential credential) {
        showSnackBarText("Your account is successfully verified!");
      },
      verificationFailed: (FirebaseAuthException e) {
        showSnackBarText("Authentication failed!");
      },
      codeSent: (String verificationId, int? resendToken) {
        showSnackBarText("OTP Sent!");
        verID = verificationId;
        setState(() {
          loadNextAd();
          screenState = 1;
        });
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        showSnackBarText("Timeout!");
      },
    );
  }

  Future<void> verifyOTP() async {
    await FirebaseAuth.instance
        .signInWithCredential(
      PhoneAuthProvider.credential(
        verificationId: verID,
        smsCode: otpPin,
      ),
    )
        .whenComplete(() {
      // Navigate to the username and password page
      setState(() {
        loadNextAd();
        screenState = 2;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    screenHeight = MediaQuery.of(context).size.height;
    screenWidth = MediaQuery.of(context).size.width;
    bottom = MediaQuery.of(context).viewInsets.bottom;

    return WillPopScope(
      onWillPop: () async {
        if (screenState == 0) {
          return true;
        } else if (screenState == 1) {
          setState(() {
            screenState = 0;
          });
          return false;
        } else if (screenState == 2) {
          setState(() {
            screenState = 1;
          });
          return false;
        }
        return true;
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: const Color.fromARGB(255, 0, 0, 0),
        body: SafeArea(
          child: Flex(
            direction: Axis.vertical,
            children: [
              Expanded(
                child: Stack(
                  children: [
                    //for icon animation. when page is opened, icon will be animated it will turn into a circle
                    // AnimatedPositioned(
                    //   duration: const Duration(milliseconds: 500),
                    //   curve: Curves.linearToEaseOut,
                    //   top: screenHeight * 0.1 - bottom,
                    //   left: screenWidth * 0.37,
                    //   child: Container(
                    //     height: 120,
                    //     width: 120,
                    //     decoration: const BoxDecoration(
                    //       color: Color.fromARGB(255, 0, 0, 0),
                    //       shape: BoxShape.circle,
                    //     ),
                    //     child: // frees logo image
                    //         Image.asset(
                    //       "assets/frees.png",
                    //       fit: BoxFit.cover,
                    //     ),
                    //   ),
                    // ),

                    Positioned(
                      bottom: screenHeight * 0.1,
                      child: Container(
                        height: screenHeight * 0.8,
                        width: screenWidth,
                        decoration: const BoxDecoration(
                          color: Color.fromARGB(255, 0, 0, 0),
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(40),
                            topRight: Radius.circular(40),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 30),
                                Text(
                                  screenState == 0
                                      ? "Phone Verification"
                                      : screenState == 1
                                          ? "Verify OTP"
                                          : "Create Account",
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Color.fromARGB(255, 255, 255, 255),
                                  ),
                                ),
                                const SizedBox(height: 30),
                                if (screenState == 0)
                                  IntlPhoneField(
                                    dropdownDecoration: const BoxDecoration(
                                      shape: BoxShape.rectangle,
                                      borderRadius: BorderRadius.all(
                                        Radius.circular(30),
                                      ),
                                      color: Color.fromARGB(255, 0, 0, 0),
                                    ),
                                    style: const TextStyle(
                                      color: Color.fromARGB(255, 255, 255, 255),
                                    ),
                                    dropdownTextStyle: const TextStyle(
                                      fontFamily: "Poppins",
                                      fontSize: 16,
                                      color: Color.fromARGB(255, 255, 255, 255),
                                    ),
                                    dropdownIcon: const Icon(
                                      Icons.arrow_drop_down,
                                      size: 25,
                                      color: Color.fromARGB(255, 255, 255, 255),
                                    ),
                                    cursorColor: Colors.white,
                                    controller: _phoneController,
                                    decoration: const InputDecoration(
                                        labelText: "Phone Number",
                                        border: OutlineInputBorder()),
                                    initialCountryCode: 'US',
                                    onChanged: (phone) {
                                      countryDial = phone.countryCode;
                                    },
                                  ),
                                if (screenState == 1)
                                  TextFormField(
                                    onChanged: (value) {
                                      otpPin = value;
                                    },
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(
                                      labelText: "OTP",
                                      labelStyle: TextStyle(
                                        color:
                                            Color.fromARGB(255, 255, 255, 255),
                                      ),
                                      hintText: "Enter OTP",
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.all(
                                          Radius.circular(5),
                                        ),
                                      ),
                                    ),
                                  ),
                                if (screenState == 2)
                                  Column(
                                    children: [
                                      // username
                                      TextFormField(
                                        maxLength: 25,
                                        controller: _usernameController,
                                        decoration: const InputDecoration(
                                          labelStyle: TextStyle(
                                            color: Color.fromARGB(
                                                255, 255, 255, 255),
                                          ),
                                          labelText: "Username",
                                          hintText: "Enter your username",
                                          border: OutlineInputBorder(
                                            borderSide: BorderSide(
                                              color: Color.fromARGB(
                                                  255, 255, 255, 255),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 20),
                                      TextFormField(
                                        controller: _emailController,
                                        keyboardType:
                                            TextInputType.emailAddress,
                                        decoration: const InputDecoration(
                                          labelText: "Email",
                                          labelStyle: TextStyle(
                                            color: Color.fromARGB(
                                                255, 255, 255, 255),
                                          ),
                                          hintText: "Enter your email address",
                                          border: OutlineInputBorder(),
                                        ),
                                      ),
                                      const SizedBox(height: 20),
                                      TextFormField(
                                        controller: _passwordController,
                                        obscureText: true,
                                        decoration: const InputDecoration(
                                          labelText: "Password",
                                          labelStyle: TextStyle(
                                            color: Color.fromARGB(
                                                255, 255, 255, 255),
                                          ),
                                          hintText: "Enter your password",
                                          border: OutlineInputBorder(),
                                        ),
                                      ),
                                    ],
                                  ),
                                const SizedBox(height: 30),
                                Center(
                                  child: ElevatedButton(
                                    onPressed: () {
                                      if (screenState == 0) {
                                        verifyPhone(countryDial +
                                            _phoneController.text);
                                      } else if (screenState == 1) {
                                        verifyOTP();
                                      } else {
                                        signUpUser();
                                      }
                                    },
                                    style: ButtonStyle(
                                      shape: MaterialStateProperty.all(
                                        RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(30),
                                        ),
                                      ),
                                      backgroundColor:
                                          MaterialStateProperty.all(
                                              Colors.blue),
                                    ),
                                    child: SizedBox(
                                      width: 140,
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 15),
                                        child: Text(
                                          screenState == 0
                                              ? "Send OTP"
                                              : screenState == 1
                                                  ? "Verify OTP"
                                                  : "Create Account",
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                if (screenState == 0)
                                  SizedBox(
                                    height: MediaQuery.of(context).size.height *
                                        0.42,
                                  ),
                                if (screenState == 1)
                                  SizedBox(
                                    height: MediaQuery.of(context).size.height *
                                        0.45,
                                  ),
                                if (screenState == 2)
                                  SizedBox(
                                    height: MediaQuery.of(context).size.height *
                                        0.22,
                                  ),

                                // show the add on the bottom
                                if (isAdLoaded)
                                  SizedBox(
                                    height: 55,
                                    child: AdWidget(ad: _nativeAd!),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void showSnackBarText(String message) {
    final snackBar = SnackBar(content: Text(message));
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  selectImage() async {
    Uint8List im = await pickImage(ImageSource.gallery);
    // set state because we need to display the image we selected on the circle avatar
    setState(() {
      _image = im;
    });
  }

  void signUpUser() async {
    setState(() {
      _isLoading = true;
    });

    // signup user using authmethods
    String res = await AuthMethods().signUpUser(
        email: _emailController.text,
        password: _passwordController.text,
        username: _usernameController.text,
        bio: _bioController.text,
        phoneNumber: _phoneController.text,
        file: _image);

    // if string returned is sucess, user has been created
    if (res == "success") {
      setState(() {
        _isLoading = false;
      });
      // navigate to the home screen
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const ResponsiveLayout(
            mobileScreenLayout: MobileScreenLayout(),
            webScreenLayout: WebScreenLayout(),
          ),
        ),
      );
    } else {
      setState(() {
        _isLoading = false;
      });
      // show the error
      showSnackBar(context, res);
    }
  }
}

  // Future<void> registerUser() async {
  //   try {
  //     // Create a new Firebase user with the entered username and password
  //     UserCredential userCredential =
  //         await FirebaseAuth.instance.createUserWithEmailAndPassword(
  //       email: _usernameController.text,
  //       password: _passwordController.text,
  //     );
  //     // Show a success message and navigate to the home page
  //     showSnackBarText("User created successfully!");
  //     Navigator.of(context).pushReplacement(
  //       MaterialPageRoute(
  //         builder: (context) => const MobileScreenLayout(),
  //       ),
  //     );
  //   } on FirebaseAuthException catch (e) {
  //     // Show an error message if the username is already taken or the password is invalid
  //     if (e.code == 'weak-password') {
  //       showSnackBarText('The password provided is too weak.');
  //     } else if (e.code == 'email-already-in-use') {
  //       showSnackBarText('The account already exists for that email.');
  //     }
  //   } catch (e) {
  //     showSnackBarText(e.toString());
  //   }
  // }
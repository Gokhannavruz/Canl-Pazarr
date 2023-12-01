// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:frees/screens/country_state_city_picker.dart';
import 'package:frees/screens/credit_page.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:image_picker/image_picker.dart';
import 'package:frees/resources/firestore_methods.dart';
import 'package:frees/utils/colors.dart';
import 'package:frees/utils/utils.dart';

class AddPostScreen extends StatefulWidget {
  const AddPostScreen({
    Key? key,
  }) : super(key: key);

  @override
  _AddPostScreenState createState() => _AddPostScreenState();
}

class _AddPostScreenState extends State<AddPostScreen> {
  Uint8List? _file;
  String? username;
  String? profImage;
  bool showWhoSent = false;
  bool isLoading = false;
  bool _switchValue = false;
  String _country = '';
  String _state = '';
  String _city = '';
  bool isWanted = false;
  List<String> productCategories = [
    'Appliances',
    'Automotive',
    'Baby',
    'Beauty',
    'Books',
    'Clothing',
    'Electronics',
    'Fitness',
    'Food',
    'Furniture',
    'Garden',
    'Health',
    'Home',
    'Jewelry',
    'Kitchen',
    'Music',
    'Office',
    'Outdoors',
    'Pets',
    'Shoes',
    'Sports',
    'Toys',
    'Travel',
    'Video Games',
    'Watches',
    'Crafts',
    'Collectibles',
    'Art',
    'Movies',
    'Computers',
  ];
  String dropdownValue = 'Appliances';
  String value = '';
  late final TextEditingController _descriptionController =
      TextEditingController();
  BannerAd? _bannerAd;
  final bool _isBannerAdReady = false;
  NativeAd? _nativeAd;
  bool isAdLoaded = false;

  String uid = FirebaseAuth.instance.currentUser!.uid;
  // matched with
  late String recipient;

  // Fetch the user's data from Firestore and store it in the variables with stream builder
  void getData() async {
    await Firebase.initializeApp();
    FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .snapshots()
        .listen((event) {
      setState(() {
        username = event.get('username');
        profImage = event.get('photoUrl');
      });
    });
  }

  // create a banner ad
  void _createBannerAd() {
    _bannerAd = BannerAd(
      adUnitId: 'ca-app-pub-8445989958080180/6205431258',
      size: AdSize.banner,
      request: const AdRequest(),
      listener: const BannerAdListener(),
    )..load();
  }

  void _loadNativeAd() {
    _nativeAd = NativeAd(
      adUnitId: 'ca-app-pub-8445989958080180/9778716899',
      factoryId: 'listTile',
      request: const AdRequest(),
      listener: NativeAdListener(
        // Called when an ad is successfully received.
        onAdLoaded: (Ad ad) {
          var add = ad as NativeAd;
          setState(() {
            _nativeAd = add;
            isAdLoaded = true;
          });
        },

        // Called when an ad request failed.
        onAdFailedToLoad: (Ad ad, LoadAdError error) {
          // Dispose the ad here to free resources.
          ad.dispose();
        },
        // Called when an ad opens an overlay that covers the screen.
        onAdOpened: (Ad ad) => print('Ad opened.'),
        // Called when an ad removes an overlay that covers the screen.
        onAdClosed: (Ad ad) => print('Ad closed.'),
        // Called when an impression occurs on the ad.
        onAdImpression: (Ad ad) => print('Ad impression.'),
        // Called when a click is recorded for a NativeAd.
        onAdClicked: (Ad ad) => print('Ad clicked.'),
      ),
    );

    _nativeAd!.load();
  }

  @override
  void initState() {
    super.initState();
    _switchValue = false;
    isWanted = false;
    _descriptionController.text = '';
    recipient = '';
    _getUserLocation();
    _createBannerAd();
    _loadNativeAd();

    FirebaseAuth.instance.idTokenChanges().listen((user) {
      if (user != null) {
        getData();
        setState(() {});
      }
    });
  }

  // get user country, state, city from firestore and add to fields
  Future<void> _getUserLocation() async {
    await Firebase.initializeApp();
    FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .snapshots()
        .listen((event) {
      setState(() {
        _country = event.get('country');
        _state = event.get('state');
        _city = event.get('city');
      });
    });
  }

  selectImage(BuildContext parentContext) async {
    return showDialog(
      context: parentContext,
      builder: (BuildContext context) {
        return SimpleDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          backgroundColor: const Color.fromARGB(255, 24, 22, 22),
          title: const Text('Create a Post'),
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.only(left: 14.0),
              child: SimpleDialogOption(
                  padding: const EdgeInsets.all(20),
                  child: const Row(
                    children: [
                      Icon(Icons.camera_alt, color: Colors.white),
                      SizedBox(width: 10),
                      Text('Camera'),
                    ],
                  ),
                  onPressed: () async {
                    Navigator.pop(context);
                    Uint8List file = await pickImage(ImageSource.camera);
                    setState(() {
                      _file = file;
                    });
                  }),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 14.0),
              child: SimpleDialogOption(
                  padding: const EdgeInsets.all(20),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.image,
                        color: Colors.white,
                      ),
                      SizedBox(width: 10),
                      Text('Gallery'),
                    ],
                  ),
                  onPressed: () async {
                    Navigator.of(context).pop();
                    Uint8List file = await pickImage(ImageSource.gallery);
                    setState(() {
                      _file = file;
                    });
                  }),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 14),
              child: SimpleDialogOption(
                padding: const EdgeInsets.all(20),
                child: const Row(
                  children: [
                    Icon(
                      Icons.cancel,
                      color: Color.fromARGB(255, 161, 36, 28),
                    ),
                    SizedBox(width: 10),
                    Text("Cancel"),
                  ],
                ),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
            )
          ],
        );
      },
    );
  }

  void postImage(String uid, String username, String profImage) async {
    setState(() {
      isLoading = true;
    });
    // start the loading
    try {
      // upload to storage and db
      String res = await FireStoreMethods().uploadPost(
          _descriptionController.text, _file!, uid, username, profImage,
          recipient: recipient,
          country: _country,
          state: _state,
          city: _city,
          isWanted: isWanted,
          category: dropdownValue);
      if (res == "success") {
        setState(() {
          isLoading = false;
        });
        showSnackBar(
          context,
          'Posted!',
        );
        clearImage();
      } else {
        showSnackBar(context, res);
      }
    } catch (err) {
      setState(() {
        isLoading = false;
      });
      showSnackBar(
        context,
        err.toString(),
      );
    }
  }

  void clearImage() {
    setState(() {
      _file = null;
    });
  }

  @override
  void dispose() {
    super.dispose();
    _descriptionController.dispose();
    _bannerAd?.dispose();
    _nativeAd?.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // get user profile photo from firebase  storage

    if (_file == null) {
      return Center(
        child: Padding(
          padding: // media query for top padding
              EdgeInsets.only(top: MediaQuery.of(context).size.height * 0.4),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(Icons.image),
              const SizedBox(height: 10),
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: MediaQuery.of(context).size.width * 0.06,
                ),
                child: const Material(
                  color: Colors.transparent,
                  child: Text(
                    "Share your needs and get them from other people for free. Or share things you don't use.",
                    style: TextStyle(
                      fontSize: 17,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),

              const SizedBox(height: 10),
              TextButton.icon(
                onPressed: () => selectImage(context),
                icon: const Icon(
                  Icons.add_a_photo,
                  color: Colors.white,
                ),
                label: const Text(
                  'Add Image',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.all<Color>(
                    const Color.fromARGB(255, 24, 64, 151),
                  ),
                  padding: MaterialStateProperty.all<EdgeInsetsGeometry>(
                    const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 10,
                    ),
                  ),
                ),
              ),
              // Spacer widget ile yazılar ortada ve reklam en altta olacak
              const Spacer(),
              // show on the bottom of the screen native ad
              if (isAdLoaded)
                SizedBox(
                  height: 100,
                  width: MediaQuery.of(context).size.width,
                  child: AdWidget(ad: _nativeAd!),
                ),
            ],
          ),
        ),
      );
    } else {
      return Scaffold(
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          backgroundColor: mobileBackgroundColor,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: clearImage,
          ),
          title: const Text(
            'Post to',
          ),
          actions: [
            TextButton(
              onPressed: // if location and category is empty show snackbar
                  _country.isEmpty
                      ? () {
                          showSnackBar(
                            context,
                            'Please select location',
                          );
                        }
                      : () {
                          postImage(
                            uid,
                            username!,
                            profImage!,
                          );
                        },
              child: const Text(
                "Share",
                style: TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                    fontSize: 16.0),
              ),
            ),
          ],
        ),
        // POST FORM
        body: SingleChildScrollView(
          child: SafeArea(
            child: Column(
              children: [
                // linear progress indicator
                if (isLoading)
                  const LinearProgressIndicator(
                    backgroundColor: Colors.white,
                  ),
                // user profile
                ListTile(
                  leading: CircleAvatar(
                    radius: 23,
                    backgroundImage: NetworkImage(
                      profImage!,
                    ),
                  ),
                  title: Padding(
                    padding: const EdgeInsets.only(),
                    child: Text(
                      username!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  // share button
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.tag_rounded,
                        size: 17,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(width: 1),
                      Text(
                        "Category",
                        style: TextStyle(
                          color: Colors.grey[400],
                        ),
                      ),
                      const SizedBox(width: 10),
                      DropdownButton<String>(
                        dropdownColor: const Color.fromARGB(255, 24, 22, 22),
                        menuMaxHeight: 300,

                        value: dropdownValue,
                        icon:
                            const SizedBox(), // Remove the default icon and use the one in the Row
                        elevation: 16,
                        style: const TextStyle(color: Colors.white),
                        underline: Container(
                          height: 2,
                          color: const Color.fromARGB(255, 91, 85, 85),
                        ),
                        onChanged: (String? newValue) {
                          setState(() {
                            dropdownValue = newValue!;
                          });
                        },
                        items: productCategories
                            .map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(
                              value,
                              style: const TextStyle(color: Colors.white),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 5),
                // show country, state, city
                Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              if (_country.isNotEmpty ||
                                  _state.isNotEmpty ||
                                  _city.isNotEmpty) ...[
                                if (_country.isNotEmpty) ...[
                                  Text(_country,
                                      style:
                                          const TextStyle(color: Colors.white)),
                                  if (_state.isNotEmpty) ...[
                                    Text(', $_state',
                                        style: const TextStyle(
                                            color: Colors.white)),
                                    if (_city.isNotEmpty) ...[
                                      Text(', $_city',
                                          style: const TextStyle(
                                              color: Colors.white)),
                                    ],
                                  ],
                                ],
                                // change location button
                                TextButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const CountryStateCity(),
                                      ),
                                    );
                                  },
                                  child: const Text(
                                    'Change',
                                    style: TextStyle(
                                      color: Colors.blue,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ] else ...[
                                // Set your location button
                                TextButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const CountryStateCity(),
                                      ),
                                    );
                                  },
                                  child: const Text(
                                    'Set Your Location',
                                    style: TextStyle(
                                      color: Colors.blue,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // image preview
                Container(
                  height: MediaQuery.of(context).size.height * 0.4,
                  width: MediaQuery.of(context).size.width,
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: MemoryImage(_file!),
                      fit: BoxFit.cover,
                    ),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      if (isWanted)
                        Positioned(
                          top:
                              10, // Adjust the top position according to your needs
                          right:
                              10, // Adjust the right position according to your needs
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              "Wanted",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                StreamBuilder(
                  stream: FirebaseFirestore.instance
                      .collection("users")
                      .doc(FirebaseAuth.instance.currentUser!
                          .uid) // Replace with the actual user document ID
                      .snapshots(),
                  builder: (context, AsyncSnapshot<DocumentSnapshot> snapshot) {
                    if (snapshot.hasData && snapshot.data != null) {
                      int userCredit = snapshot.data!["credit"] ?? 0;

                      return Row(
                        children: [
                          const Text(
                            'Is this your need?',
                            style: TextStyle(
                              color: Colors.white,
                            ),
                          ),
                          Switch(
                            value: _switchValue,
                            onChanged: (value) {
                              if (userCredit >= 6) {
                                setState(() {
                                  _switchValue = value;
                                  isWanted = value;
                                });
                              } else {
                                // User doesn't have enough credits, show a dialog
                                showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(14.0),
                                      ),
                                      backgroundColor:
                                          const Color.fromARGB(255, 0, 0, 0),
                                      title: const Text('Insufficient Credits'),
                                      content: Text(
                                          'You have $userCredit credit. You need at least 6 credits to use this feature. Watch an ad to earn more credits?'),
                                      actions: [
                                        TextButton(
                                          onPressed: () {
                                            Navigator.of(context).pop();
                                          },
                                          child: const Text(
                                            'Cancel',
                                            style: TextStyle(color: Colors.red),
                                          ),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            // Navigate to the credit page or show an ad
                                            // Implement the navigation logic here
                                            // For example, you can use Navigator.push to navigate to the credit page
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    const CreditPage(),
                                              ),
                                            );
                                          },
                                          style: ButtonStyle(
                                            backgroundColor:
                                                MaterialStateProperty.all<
                                                    Color>(Colors.green),
                                            shape: MaterialStateProperty.all<
                                                RoundedRectangleBorder>(
                                              RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(
                                                    14.0), // Adjust the radius as needed
                                              ),
                                            ),
                                          ),
                                          child: const Text(
                                            'Watch Ad',
                                            style: TextStyle(
                                              color: Colors
                                                  .white, // You can set the text color here
                                            ),
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              }
                            },
                            activeTrackColor:
                                const Color.fromARGB(255, 27, 137, 173),
                            activeColor:
                                const Color.fromARGB(255, 255, 255, 255),
                          ),
                        ],
                      );
                    } else {
                      // Handle the case when data is not available yet
                      return const CircularProgressIndicator(); // You can replace this with a loading indicator or other UI element
                    }
                  },
                ),
                // description
                // show username and description field
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    maxLength: 100,
                    controller: // Display the selected user's username as a clickable text
                        _descriptionController,
                    maxLines: 5,
                    decoration: const InputDecoration(
                      hintText: 'Write a caption...',
                      hintStyle: TextStyle(
                        color: Colors.grey,
                      ),
                      border: InputBorder.none,
                    ),
                    style: const TextStyle(
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }
}

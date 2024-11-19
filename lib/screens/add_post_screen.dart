// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:io';
import 'dart:typed_data';
import 'package:Freecycle/screens/add_jobs_screen.dart';
import 'package:Freecycle/screens/country_state_city2.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:Freecycle/screens/country_state_city_picker.dart';
import 'package:Freecycle/screens/credit_page.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:image_picker/image_picker.dart';
import 'package:Freecycle/resources/firestore_methods.dart';
import 'package:Freecycle/utils/colors.dart';
import 'package:Freecycle/utils/utils.dart';
import 'package:image/image.dart' as img;
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:ui';

import 'package:url_launcher/url_launcher.dart';

class AddPostScreen extends StatefulWidget {
  const AddPostScreen({Key? key}) : super(key: key);

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
  bool _hasRated = false;
  List<String> productCategories = [
    'Select a category',
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
  String dropdownValue = 'Select a category';
  String value = '';
  late final TextEditingController _descriptionController =
      TextEditingController();
  bool _isPosting = false;

  String uid = FirebaseAuth.instance.currentUser!.uid;
  late String recipient;

  @override
  void initState() {
    super.initState();
    _switchValue = false;
    isWanted = false;
    _descriptionController.text = '';
    recipient = '';
    _getUserLocation();
    _checkIfRated();

    FirebaseAuth.instance.idTokenChanges().listen((user) {
      if (user != null) {
        getData();
        setState(() {});
      }
    });
  }

  Future<void> _checkIfRated() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _hasRated = prefs.getBool('hasRated') ?? false;
    });
  }

  void getData() async {
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

  Future<void> _getUserLocation() async {
    FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .snapshots()
        .listen((event) {
      if (event.exists && event.data() != null) {
        setState(() {
          _country = event.get('country') as String? ?? '';
          _state = event.get('state') as String? ?? '';
          _city = event.get('city') as String? ?? '';
        });
      } else {
        setState(() {
          _country = '';
          _state = '';
          _city = '';
        });
      }
    });
  }

  Future<Uint8List> compressImage(Uint8List imageData) async {
    img.Image? image = img.decodeImage(imageData);
    if (image == null) return imageData;

    // Resize the image to a maximum width of 800 pixels while maintaining aspect ratio
    int targetWidth = 800;
    int targetHeight = (800 * image.height ~/ image.width);

    img.Image resizedImage =
        img.copyResize(image, width: targetWidth, height: targetHeight);

    // Compress the image with a quality of 85
    List<int> compressedImage = img.encodeJpg(resizedImage, quality: 85);

    return Uint8List.fromList(compressedImage);
  }

  Future<void> selectImage(BuildContext parentContext) async {
    return showModalBottomSheet(
      context: parentContext,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Container(
            height: MediaQuery.of(context).size.height * 0.35,
            decoration: BoxDecoration(
              color: Color(0xFF1E1E1E), // Koyu arka plan rengi
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(30),
                topRight: Radius.circular(30),
              ),
            ),
            child: Column(
              children: [
                SizedBox(height: 10),
                Container(
                  width: 50,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey[600],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                SizedBox(height: 20),
                Text(
                  'Add Photo',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildCircularOption(
                      context: context,
                      icon: Icons.camera_alt,
                      label: 'Camera',
                      color: Colors.blue,
                      onTap: () async {
                        Navigator.pop(context);
                        Uint8List file = await pickImage(ImageSource.camera);
                        Uint8List compressedFile = await compressImage(file);
                        setState(() {
                          _file = compressedFile;
                        });
                      },
                    ),
                    _buildCircularOption(
                      context: context,
                      icon: Icons.photo_library,
                      label: 'Gallery',
                      color: Colors.green,
                      onTap: () async {
                        Navigator.pop(context);
                        Uint8List file = await pickImage(ImageSource.gallery);
                        Uint8List compressedFile = await compressImage(file);
                        setState(() {
                          _file = compressedFile;
                        });
                      },
                    ),
                  ],
                ),
                SizedBox(height: 30),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      color: Colors.red[300],
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCircularOption({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  spreadRadius: 2,
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 30,
            ),
          ),
          SizedBox(height: 10),
          Text(
            label,
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  void postImage(String uid, String username, String profImage) async {
    if (_isPosting) return; // Prevent multiple posts

    if (dropdownValue == 'Select a category') {
      showSnackBar(context, 'Please select a category');
      return;
    }

    setState(() {
      isLoading = true;
      _isPosting = true;
    });

    try {
      String res = await FireStoreMethods().uploadPost(
        _descriptionController.text,
        _file!,
        uid,
        username,
        profImage,
        recipient: recipient,
        country: _country,
        state: _state,
        city: _city,
        isWanted: isWanted,
        category: dropdownValue,
      );

      if (res == "success") {
        setState(() {
          isLoading = false;
        });
        showSnackBar(context, 'Posted!');
        clearImage();

        if (!_hasRated) {
          _showRatingDialog();
        }
      } else {
        showSnackBar(context, res);
      }
    } catch (err) {
      showSnackBar(context, err.toString());
    } finally {
      setState(() {
        isLoading = false;
        _isPosting = false;
      });
    }
  }

  void _showRatingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          double _rating = 0;
          return Dialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            elevation: 0,
            backgroundColor: Colors.transparent,
            child: Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                shape: BoxShape.rectangle,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10.0,
                    offset: const Offset(0.0, 10.0),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Your Kindness Matters!',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 15),
                  Text(
                    'Your rating helps us reach more people in need.',
                    style: TextStyle(fontSize: 16, color: Colors.white70),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 20),
                  RatingBar.builder(
                    initialRating: 0,
                    minRating: 1,
                    direction: Axis.horizontal,
                    allowHalfRating: false,
                    itemCount: 5,
                    itemPadding: EdgeInsets.symmetric(horizontal: 4.0),
                    itemBuilder: (context, _) => Icon(
                      Icons.star,
                      color: Colors.amber,
                    ),
                    onRatingUpdate: (rating) {
                      setState(() {
                        _rating = rating;
                      });
                      _handleRating(rating.toInt());
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _handleRating(int rating) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasRated', true);
    setState(() {
      _hasRated = true;
    });

    if (rating >= 4) {
      _redirectToStore();
    } else {
      _showFeedbackForm(rating);
    }
  }

  void _redirectToStore() async {
    String url;
    if (Platform.isAndroid) {
      url =
          'https://play.google.com/store/apps/details?id=com.thingsfree'; // Android paket adınızı buraya yazın
    } else if (Platform.isIOS) {
      url =
          'https://apps.apple.com/us/app/free-stuff-freecycle/id6476391295'; // iOS App ID'nizi buraya yazın
    } else {
      return; // Desteklenmeyen platform
    }

    if (await canLaunch(url)) {
      await launch(url);
    } else {
      // URL açılamazsa hata mesajı göster
      showSnackBar(context, 'Could not open app store');
    }
  }

  void _showFeedbackForm(int rating) {
    TextEditingController feedbackController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('We value your feedback',
            style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold)),
        content: Container(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('How can we improve your experience?',
                  style: TextStyle(color: Colors.white70, fontSize: 16)),
              SizedBox(height: 20),
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: TextField(
                  controller: feedbackController,
                  maxLines: 5,
                  style: TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Share your thoughts...',
                    hintStyle: TextStyle(color: Colors.white54),
                    filled: true,
                    fillColor: Colors.transparent,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: EdgeInsets.all(16),
                  ),
                ),
              ),
              SizedBox(height: 20),
              Row(
                children: [
                  Icon(Icons.star, color: Colors.amber),
                  SizedBox(width: 8),
                  Text('Your rating: $rating',
                      style: TextStyle(color: Colors.white70)),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            child: Text('Cancel', style: TextStyle(color: Colors.white70)),
            onPressed: () => Navigator.of(context).pop(),
          ),
          ElevatedButton(
            child: Text('Submit', style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              primary: Colors.blue,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            onPressed: () {
              if (feedbackController.text.isNotEmpty) {
                _submitFeedback(rating, feedbackController.text);
                Navigator.of(context).pop();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text(
                          'Please enter your feedback before submitting.')),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  void _submitFeedback(int rating, String feedback) async {
    User? user = FirebaseAuth.instance.currentUser;
    String deviceType = Platform.isIOS ? 'iOS' : 'Android';

    await FirebaseFirestore.instance.collection('feedback').add({
      'userId': user?.uid,
      'userEmail': user?.email,
      'rating': rating,
      'feedback': feedback,
      'deviceType': deviceType,
      'timestamp': FieldValue.serverTimestamp(),
    }).then((_) {
      showSnackBar(context, 'Thank you for your feedback!');
    }).catchError((error) {
      showSnackBar(context, 'Error submitting feedback: $error');
    });
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
  }

  @override
  Widget build(BuildContext context) {
    if (_file == null) {
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.shade900, Colors.black],
          ),
        ),
        child: SingleChildScrollView(
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 40),
                  Image.asset(
                    'assets/sharingimagepng.png',
                    height: MediaQuery.of(context).size.height * 0.3,
                  ),
                  const SizedBox(height: 40),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      "Share your needs and find help from others for free.\n\nOr share items you no longer need.",
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 40),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.blue.shade400, Colors.blue.shade800],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.shade200.withOpacity(0.3),
                          spreadRadius: 1,
                          blurRadius: 5,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ElevatedButton.icon(
                      onPressed: () => selectImage(context),
                      icon: const Icon(
                        Icons.add_a_photo,
                        color: Colors.white,
                        size: 20,
                      ),
                      label: const Text(
                        'Add Image',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        primary: Colors.transparent,
                        onPrimary: Colors.white,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
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
      );
    } else {
      return Scaffold(
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
            onPressed: clearImage,
          ),
          title:
              const Text('Create Post', style: TextStyle(color: Colors.white)),
          actions: [
            TextButton(
              onPressed:
                  _country.isEmpty || dropdownValue == 'Select a category'
                      ? () {
                          if (_country.isEmpty) {
                            showSnackBar(context, 'Please select location');
                          } else {
                            showSnackBar(context, 'Please select a category');
                          }
                        }
                      : () {
                          postImage(uid, username!, profImage!);
                        },
              child: const Text(
                "Share",
                style: TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                  fontSize: 16.0,
                ),
              ),
            ),
          ],
        ),
        body: SingleChildScrollView(
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isLoading)
                    const LinearProgressIndicator(
                      backgroundColor: Colors.white,
                    ),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundImage: NetworkImage(profImage!),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        username!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[900],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton2<String>(
                        isExpanded: true,
                        items: productCategories
                            .map((item) => DropdownMenuItem<String>(
                                  value: item,
                                  child: Text(
                                    item,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: item == dropdownValue
                                          ? Colors.white
                                          : Colors.white,
                                    ),
                                  ),
                                ))
                            .toList(),
                        value: dropdownValue,
                        onChanged: (value) {
                          setState(() {
                            dropdownValue = value!;
                          });
                        },
                        buttonStyleData: ButtonStyleData(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          height: 40,
                          width: double.infinity,
                        ),
                        dropdownStyleData: DropdownStyleData(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: Colors.grey[900],
                          ),
                          offset: const Offset(0, -14),
                          scrollbarTheme: ScrollbarThemeData(
                            radius: const Radius.circular(40),
                            thickness: MaterialStateProperty.all(6),
                            thumbVisibility: MaterialStateProperty.all(true),
                          ),
                        ),
                        menuItemStyleData: const MenuItemStyleData(
                          height: 40,
                          padding: EdgeInsets.symmetric(horizontal: 16),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[900],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        const Icon(Icons.location_on,
                            color: Colors.grey, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _country.isNotEmpty
                                ? [_country, _state, _city]
                                    .where((s) => s.isNotEmpty)
                                    .join(', ')
                                : 'Set Your Location',
                            style: const TextStyle(
                                color: Colors.white, fontSize: 14),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      const CountryStateCity()),
                            );
                          },
                          child: Text(
                            _country.isNotEmpty ? 'Change' : 'Set',
                            style: const TextStyle(
                                color: Colors.blue, fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 15),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      height: MediaQuery.of(context).size.height * 0.4,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: MemoryImage(_file!),
                          fit: BoxFit.cover,
                        ),
                      ),
                      child: Stack(
                        alignment: Alignment.topRight,
                        children: [
                          if (isWanted)
                            Container(
                              margin: const EdgeInsets.all(10),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.green,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                "Wanted",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  StreamBuilder(
                    stream: FirebaseFirestore.instance
                        .collection("users")
                        .doc(FirebaseAuth.instance.currentUser!.uid)
                        .snapshots(),
                    builder:
                        (context, AsyncSnapshot<DocumentSnapshot> snapshot) {
                      if (snapshot.hasData && snapshot.data != null) {
                        int userCredit = snapshot.data!["credit"] ?? 0;

                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[900],
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Mark as needed',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                              ),
                              Switch(
                                value: _switchValue,
                                onChanged: (value) {
                                  if (Platform.isIOS || userCredit >= 5) {
                                    setState(() {
                                      _switchValue = value;
                                      isWanted = value;
                                    });
                                  } else {
                                    showDialog(
                                      context: context,
                                      builder: (BuildContext context) {
                                        return AlertDialog(
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(14.0),
                                          ),
                                          backgroundColor: Colors.grey[900],
                                          title: const Text(
                                              'Insufficient Credits',
                                              style: TextStyle(
                                                  color: Colors.white)),
                                          content: Text(
                                            'You have $userCredit credit. You need at least 5 credits to use this feature. Watch an ad to earn more credits?',
                                            style: const TextStyle(
                                                color: Colors.white),
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () {
                                                Navigator.of(context).pop();
                                              },
                                              child: const Text('Cancel',
                                                  style: TextStyle(
                                                      color: Colors.white)),
                                            ),
                                            ElevatedButton(
                                              onPressed: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                      builder: (context) =>
                                                          const CreditPage()),
                                                );
                                              },
                                              style: ElevatedButton.styleFrom(
                                                  primary: Colors.blue),
                                              child: const Text(
                                                  'Earn Free Credit',
                                                  style: TextStyle(
                                                      color: Colors.white)),
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                  }
                                },
                                activeColor: Colors.greenAccent,
                              ),
                            ],
                          ),
                        );
                      } else {
                        return const CircularProgressIndicator();
                      }
                    },
                  ),
                  const SizedBox(height: 15),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[900],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: TextField(
                      maxLength: 300,
                      controller: _descriptionController,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        hintText: 'Write a caption...',
                        hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                        border: InputBorder.none,
                      ),
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
  }
}

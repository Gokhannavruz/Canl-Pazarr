// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:io' if (dart.library.html) 'package:freecycle/utils/web_stub.dart'
    as io;
import 'dart:typed_data';
import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:freecycle/screens/add_jobs_screen.dart';
import 'package:freecycle/screens/country_state_city2.dart';
import 'package:freecycle/src/components/native_dialog.dart';
import 'package:freecycle/src/model/singletons_data.dart';
import 'package:freecycle/src/model/weather_data.dart';
import 'package:freecycle/src/rvncat_constant.dart';
import 'package:freecycle/src/views/paywall.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:freecycle/screens/country_state_city_picker.dart';
import 'package:freecycle/screens/credit_page.dart';
import 'package:flutter/services.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:image_picker/image_picker.dart';
import 'package:freecycle/resources/firestore_methods.dart';
import 'package:freecycle/utils/colors.dart';
import 'package:freecycle/utils/utils.dart';
import 'package:image/image.dart' as img;
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:ui';

import 'package:url_launcher/url_launcher.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:freecycle/utils/store_review_helper.dart';

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
  List<Uint8List> _selectedImages = [];
  PageController _pageController = PageController();
  int _currentPage = 0;
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

  // Add subscriptions to be canceled on dispose
  StreamSubscription? _authSubscription;
  StreamSubscription? _userDataSubscription;
  StreamSubscription? _locationSubscription;

  // Add category icons map
  final Map<String, IconData> categoryIcons = {
    'Appliances': Icons.kitchen_rounded,
    'Automotive': Icons.directions_car_rounded,
    'Baby': Icons.child_care_rounded,
    'Beauty': Icons.face_rounded,
    'Books': Icons.book_rounded,
    'Clothing': Icons.checkroom_rounded,
    'Electronics': Icons.devices_rounded,
    'Fitness': Icons.fitness_center_rounded,
    'Food': Icons.restaurant_rounded,
    'Furniture': Icons.chair_rounded,
    'Garden': Icons.yard_rounded,
    'Health': Icons.healing_rounded,
    'Home': Icons.home_rounded,
    'Jewelry': Icons.diamond_rounded,
    'Kitchen': Icons.blender_rounded,
    'Music': Icons.music_note_rounded,
    'Office': Icons.work_rounded,
    'Outdoors': Icons.park_rounded,
    'Pets': Icons.pets_rounded,
    'Shoes': Icons.hiking_rounded,
    'Sports': Icons.sports_basketball_rounded,
    'Toys': Icons.toys_rounded,
    'Travel': Icons.flight_rounded,
    'Video Games': Icons.sports_esports_rounded,
    'Watches': Icons.watch_rounded,
    'Crafts': Icons.brush_rounded,
    'Collectibles': Icons.collections_rounded,
    'Art': Icons.palette_rounded,
    'Movies': Icons.movie_rounded,
    'Computers': Icons.computer_rounded,
  };

  @override
  void initState() {
    super.initState();
    _switchValue = false;
    isWanted = false;
    _descriptionController.text = '';
    recipient = '';
    _getUserLocation();
    _checkIfRated();
    // Initialize page controller
    _pageController = PageController();

    _authSubscription = FirebaseAuth.instance.idTokenChanges().listen((user) {
      if (user != null && mounted) {
        getData();
        if (mounted) setState(() {});
      }
    });
  }

  Future<void> _checkIfRated() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _hasRated = prefs.getBool('hasRated') ?? false;
      });
    }
  }

  void getData() async {
    _userDataSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .snapshots()
        .listen((event) {
      if (mounted) {
        setState(() {
          username = event.get('username');
          profImage = event.get('photoUrl');
        });
      }
    });
  }

  Future<void> _getUserLocation() async {
    _locationSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .snapshots()
        .listen((event) {
      if (!mounted) return;

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
    if (kIsWeb) {
      // Web'de "image" kütüphanesi çalışmadığı için orijinal görüntüyü döndür
      print('Web platformunda resim sıkıştırma atlanıyor');
      return imageData;
    }

    try {
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
    } catch (e) {
      print('Resim sıkıştırma hatası: $e');
      return imageData;
    }
  }

  // Method to add an image to the selection with limit enforcement
  Future<void> _addImageToSelection(Uint8List compressedFile) async {
    if (_selectedImages.length >= 5) {
      if (mounted) {
        _showSafeSnackBar('Maximum 5 images allowed');
      }
      return;
    }

    if (mounted) {
      setState(() {
        // Set the first image as the main preview
        if (_selectedImages.isEmpty) {
          _file = compressedFile;
        }
        // Add to the list of selected images
        _selectedImages.add(compressedFile);
      });
    }
  }

  Future<void> selectImage(BuildContext parentContext) async {
    if (_selectedImages.length >= 5) {
      if (mounted) {
        _showSafeSnackBar('Maximum 5 images allowed');
      }
      return;
    }

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

                        // Check again just to be sure
                        if (_selectedImages.length >= 5) {
                          if (mounted) {
                            _showSafeSnackBar('Maximum 5 images allowed');
                          }
                          return;
                        }

                        Uint8List? fileData =
                            await pickImage(ImageSource.camera);
                        if (fileData != null) {
                          Uint8List compressedFile =
                              await compressImage(fileData);
                          await _addImageToSelection(compressedFile);
                        } else {
                          if (mounted) {
                            _showSafeSnackBar('No image selected');
                          }
                        }
                      },
                    ),
                    _buildCircularOption(
                      context: context,
                      icon: Icons.photo_library,
                      label: 'Gallery',
                      color: Colors.green,
                      onTap: () async {
                        Navigator.pop(context);
                        // Check again just to be sure
                        if (_selectedImages.length >= 5) {
                          if (mounted) {
                            _showSafeSnackBar('Maximum 5 images allowed');
                          }
                          return;
                        }

                        // Calculate how many more images can be selected
                        final int remainingImages = 5 - _selectedImages.length;

                        try {
                          final ImagePicker picker = ImagePicker();
                          final List<XFile> images =
                              await picker.pickMultiImage();

                          if (images.isNotEmpty) {
                            // Process each selected image
                            int addedCount = 0;
                            for (var i = 0;
                                i < images.length &&
                                    addedCount < remainingImages;
                                i++) {
                              if (_selectedImages.length >= 5)
                                break; // Double check the limit

                              final image = images[i];
                              final Uint8List fileData =
                                  await image.readAsBytes();
                              final Uint8List compressedFile =
                                  await compressImage(fileData);

                              await _addImageToSelection(compressedFile);
                              addedCount++;
                            }

                            // Notify if some images were not added due to the limit
                            if (images.length > remainingImages && mounted) {
                              _showSafeSnackBar(
                                  'Only $remainingImages more images allowed (maximum 5)');
                            }
                          } else if (mounted) {
                            _showSafeSnackBar('No images selected');
                          }
                        } catch (e) {
                          if (mounted) {
                            _showSafeSnackBar('Error selecting images: $e');
                          }
                        }
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
    if (_isPosting) return;

    if (dropdownValue == 'Select a category') {
      if (mounted) {
        _showSafeSnackBar('Please select a category');
      }
      return;
    }

    // Ensure we have at least one image
    if (_selectedImages.isEmpty) {
      if (mounted) {
        _showSafeSnackBar('Please select at least one image');
      }
      return;
    }

    // Enforce 5-image limit before uploading
    List<Uint8List> imagesToUpload = _selectedImages.length > 5
        ? _selectedImages.sublist(0, 5)
        : _selectedImages;

    if (mounted) {
      setState(() {
        isLoading = true;
        _isPosting = true;
      });
    }

    try {
      String res = await FireStoreMethods().uploadPost(
        _descriptionController.text,
        imagesToUpload, // Use the limited list of images
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
        if (mounted) {
          setState(() {
            isLoading = false;
          });
        }

        // First clear the image to return to the main screen
        clearImage();

        // Then show the success dialog
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              return Dialog(
                backgroundColor: Colors.transparent,
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.1),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check_circle_outline_rounded,
                          color: Colors.green,
                          size: 48,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Thank You for Sharing!',
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Your generosity helps build a stronger community. Thank you for being part of our sharing movement.',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.8),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          minimumSize: const Size(double.infinity, 48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Continue Sharing',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
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

        // Show app store review if appropriate
        if (!kIsWeb && io.Platform.isIOS && mounted) {
          _checkAndShowStoreReview();
        }
      } else {
        if (mounted) {
          _showSafeSnackBar(res);
        }
      }
    } catch (err) {
      if (mounted) {
        _showSafeSnackBar(err.toString());
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
          _isPosting = false;
        });
      }
    }
  }

  void _showRatingDialog() {
    // Bu fonksiyon artık kullanılmıyor, Apple'ın yorum sistemini kullanıyoruz
    return;

    // Aşağıdaki kod devre dışı bırakıldı
    /*
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
    */
  }

  void _handleRating(int rating) async {
    // Bu fonksiyon artık kullanılmıyor, Apple'ın yorum sistemini kullanıyoruz
    return;

    // Aşağıdaki kod devre dışı bırakıldı
    /*
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
    */
  }

  void _redirectToStore() async {
    // Bu fonksiyon artık kullanılmıyor, Apple'ın yorum sistemini kullanıyoruz
    return;

    // Aşağıdaki kod devre dışı bırakıldı
    /*
    String url;
    if (kIsWeb) {
      url = 'https://play.google.com/store/apps/details?id=com.thingsfree'; // Web için varsayılan
    } else if (io.Platform.isAndroid) {
      url = 'https://play.google.com/store/apps/details?id=com.thingsfree'; // Android paket adınızı buraya yazın
    } else if (io.Platform.isIOS) {
      url = 'https://apps.apple.com/us/app/free-stuff-freecycle/id6476391295'; // iOS App ID'nizi buraya yazın
    } else {
      return; // Desteklenmeyen platform
    }

    if (await canLaunch(url)) {
      await launch(url);
    } else {
      // URL açılamazsa hata mesajı göster
      _showSafeSnackBar('Could not open app store');
    }
    */
  }

  void _showFeedbackForm(int rating) {
    // Bu fonksiyon artık kullanılmıyor, Apple'ın yorum sistemini kullanıyoruz
    return;

    // Aşağıdaki kod devre dışı bırakıldı
    /*
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
              backgroundColor: Colors.blue,
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
    */
  }

  void _submitFeedback(int rating, String feedback) async {
    User? user = FirebaseAuth.instance.currentUser;
    String deviceType =
        kIsWeb ? 'Web' : (io.Platform.isIOS ? 'iOS' : 'Android');

    await FirebaseFirestore.instance.collection('feedback').add({
      'userId': user?.uid,
      'userEmail': user?.email,
      'rating': rating,
      'feedback': feedback,
      'deviceType': deviceType,
      'timestamp': FieldValue.serverTimestamp(),
    }).then((_) {
      _showSafeSnackBar('Thank you for your feedback!');
    }).catchError((error) {
      _showSafeSnackBar('Error submitting feedback: $error');
    });
  }

  void clearImage() {
    if (mounted) {
      setState(() {
        _file = null;
        _selectedImages = [];
        _currentPage = 0;
      });
    }
  }

  // Method to delete a specific image from the selection
  void _deleteImage(int index) {
    // Don't allow deleting if only one image left
    if (_selectedImages.length <= 1) {
      if (mounted) {
        _showSafeSnackBar('At least one image is required');
      }
      return;
    }

    // Show confirmation dialog
    if (mounted) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withOpacity(0.1),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Delete Image',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Are you sure you want to delete this image?',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.8),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          'Cancel',
                          style: GoogleFonts.poppins(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          if (mounted) {
                            setState(() {
                              // Remove the image at the specified index
                              _selectedImages.removeAt(index);

                              // Adjust the current page if needed
                              if (_currentPage >= _selectedImages.length) {
                                _currentPage = _selectedImages.length - 1;
                                _pageController.jumpToPage(_currentPage);
                              }

                              // If this was the main image (_file), set the first image as the new main image
                              if (index == 0 && _selectedImages.isNotEmpty) {
                                _file = _selectedImages[0];
                              }
                            });
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          'Delete',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      );
    }
  }

  @override
  void dispose() {
    // Cancel all stream subscriptions
    _authSubscription?.cancel();
    _userDataSubscription?.cancel();
    _locationSubscription?.cancel();
    // Dispose of the page controller
    _pageController.dispose();
    _descriptionController.dispose();

    // Make sure no other operations are attempted after dispose
    super.dispose();
  }

  // Safe context method to get a BuildContext that's safe to use
  // Returns null if the widget is no longer mounted
  BuildContext? get safeContext => mounted ? context : null;

  // Safe method to show snackbar that won't cause errors if widget is disposed
  void _showSafeSnackBar(String message) {
    if (!mounted) return;

    // Use the safer showSnackBar method we defined in utils.dart
    showSnackBar(safeContext, message);
  }

  void _showCategoryPicker() {
    // Controller for the search text field
    final searchController = TextEditingController();
    // List to hold filtered categories
    List<String> filteredCategories = List.from(productCategories);
    filteredCategories.removeAt(0); // Remove the 'Select a category' option

    // Map of category keywords and related terms for better search
    final Map<String, List<String>> categoryKeywords = {
      'Electronics': [
        'phone',
        'mobile',
        'smartphone',
        'computer',
        'laptop',
        'tablet',
        'gadget',
        'headphone',
        'earphone',
        'charger',
        'cable',
        'speaker',
        'tv',
        'television',
        'camera'
      ],
      'Computers': [
        'laptop',
        'desktop',
        'monitor',
        'keyboard',
        'mouse',
        'pc',
        'windows',
        'mac',
        'macbook',
        'apple',
        'dell',
        'hp',
        'lenovo',
        'asus',
        'acer',
        'gaming',
        'ram',
        'ssd',
        'hard drive'
      ],
      'Automotive': [
        'car',
        'vehicle',
        'auto',
        'truck',
        'motorcycle',
        'bike',
        'parts',
        'accessory',
        'tire',
        'wheel',
        'oil',
        'battery',
        'motor'
      ],
      'Baby': [
        'kid',
        'child',
        'infant',
        'toddler',
        'toy',
        'diaper',
        'stroller',
        'crib',
        'pacifier',
        'formula',
        'feeding',
        'clothing'
      ],
      'Beauty': [
        'makeup',
        'cosmetic',
        'skin',
        'care',
        'lotion',
        'cream',
        'perfume',
        'hair',
        'nail',
        'facial',
        'soap',
        'shampoo',
        'lipstick'
      ],
      'Books': [
        'novel',
        'textbook',
        'fiction',
        'nonfiction',
        'magazine',
        'comic',
        'education',
        'literature',
        'reading',
        'author',
        'paperback',
        'hardcover'
      ],
      'Clothing': [
        'clothes',
        'shirt',
        'pant',
        'dress',
        't-shirt',
        'jean',
        'jacket',
        'coat',
        'underwear',
        'sock',
        'hat',
        'scarf',
        'glove',
        'top',
        'hoodie',
        'sweater'
      ],
      'Fitness': [
        'workout',
        'exercise',
        'gym',
        'weight',
        'yoga',
        'running',
        'sport',
        'health',
        'training',
        'muscle',
        'equipment',
        'dumbbell',
        'treadmill'
      ],
      'Food': [
        'grocery',
        'snack',
        'drink',
        'beverage',
        'fruit',
        'vegetable',
        'meat',
        'bread',
        'nutrition',
        'diet',
        'organic',
        'meal',
        'cooking'
      ],
      'Furniture': [
        'chair',
        'table',
        'sofa',
        'couch',
        'bed',
        'desk',
        'drawer',
        'cabinet',
        'shelf',
        'bookcase',
        'stool',
        'bench',
        'mattress'
      ],
      'Garden': [
        'plant',
        'flower',
        'seed',
        'outdoor',
        'gardening',
        'tool',
        'lawn',
        'tree',
        'pot',
        'soil',
        'herb',
        'vegetable',
        'shovel',
        'rake'
      ],
      'Health': [
        'medicine',
        'vitamin',
        'supplement',
        'first aid',
        'bandage',
        'pill',
        'nursing',
        'care',
        'treatment',
        'wellness',
        'pharmacy',
        'mask'
      ],
      'Home': [
        'house',
        'decor',
        'decoration',
        'interior',
        'accessory',
        'living room',
        'bedroom',
        'bathroom',
        'kitchen',
        'curtain',
        'rug',
        'carpet'
      ],
      'Jewelry': [
        'necklace',
        'ring',
        'earring',
        'bracelet',
        'watch',
        'gold',
        'silver',
        'diamond',
        'gem',
        'stone',
        'accessory',
        'chain'
      ],
      'Kitchen': [
        'cooking',
        'utensil',
        'appliance',
        'dish',
        'plate',
        'cup',
        'mug',
        'silverware',
        'knife',
        'fork',
        'spoon',
        'pot',
        'pan',
        'blender',
        'mixer'
      ],
      'Music': [
        'instrument',
        'guitar',
        'piano',
        'keyboard',
        'drum',
        'violin',
        'speaker',
        'headphone',
        'album',
        'cd',
        'vinyl',
        'record',
        'song',
        'audio'
      ],
      'Office': [
        'supplies',
        'stationery',
        'pen',
        'paper',
        'notebook',
        'file',
        'folder',
        'desk',
        'chair',
        'business',
        'document',
        'printer',
        'ink'
      ],
      'Outdoors': [
        'camping',
        'hiking',
        'backpack',
        'tent',
        'sleeping bag',
        'outdoor',
        'adventure',
        'travel',
        'fishing',
        'hunting',
        'biking',
        'nature'
      ],
      'Pets': [
        'dog',
        'cat',
        'bird',
        'fish',
        'animal',
        'food',
        'toy',
        'accessory',
        'cage',
        'tank',
        'leash',
        'collar',
        'bed',
        'treat'
      ],
      'Shoes': [
        'sneaker',
        'boot',
        'sandal',
        'heel',
        'flat',
        'slipper',
        'athletic',
        'running',
        'walking',
        'footwear',
        'men',
        'women',
        'kid'
      ],
      'Sports': [
        'ball',
        'basketball',
        'football',
        'soccer',
        'baseball',
        'tennis',
        'equipment',
        'jersey',
        'helmet',
        'glove',
        'bat',
        'racket',
        'gear'
      ],
      'Toys': [
        'game',
        'doll',
        'action figure',
        'puzzle',
        'lego',
        'building',
        'educational',
        'stuffed animal',
        'remote control',
        'car',
        'board game'
      ],
      'Travel': [
        'luggage',
        'suitcase',
        'bag',
        'backpack',
        'accessory',
        'vacation',
        'trip',
        'flight',
        'ticket',
        'accommodation',
        'hotel',
        'passport'
      ],
      'Video Games': [
        'game',
        'console',
        'playstation',
        'xbox',
        'nintendo',
        'switch',
        'controller',
        'gaming',
        'headset',
        'virtual reality',
        'vr'
      ],
      'Watches': [
        'wristwatch',
        'smartwatch',
        'analog',
        'digital',
        'luxury',
        'fashion',
        'time',
        'chronograph',
        'quartz',
        'automatic',
        'strap',
        'band'
      ],
      'Crafts': [
        'art',
        'handmade',
        'diy',
        'craft',
        'knitting',
        'crochet',
        'sewing',
        'paint',
        'paper',
        'scrapbook',
        'yarn',
        'fabric',
        'tool'
      ],
      'Collectibles': [
        'collection',
        'figure',
        'statue',
        'model',
        'comic',
        'card',
        'antique',
        'vintage',
        'memorabilia',
        'limited edition',
        'rare'
      ],
      'Art': [
        'painting',
        'drawing',
        'print',
        'canvas',
        'sculpture',
        'photograph',
        'artist',
        'frame',
        'wall',
        'decoration',
        'sketch',
        'poster'
      ],
      'Movies': [
        'film',
        'dvd',
        'blu-ray',
        'series',
        'box set',
        'collection',
        'entertainment',
        'show',
        'tv',
        'actor',
        'director',
        'cinema'
      ],
      'Appliances': [
        'refrigerator',
        'microwave',
        'washing machine',
        'dryer',
        'dishwasher',
        'vacuum',
        'cleaner',
        'toaster',
        'coffee maker',
        'blender',
        'mixer',
        'heater'
      ]
    };

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          // Function to filter categories based on search query
          void filterCategories(String query) {
            setState(() {
              if (query.isEmpty) {
                filteredCategories = List.from(productCategories);
                filteredCategories
                    .removeAt(0); // Remove the 'Select a category' option
              } else {
                // Direct match with category names
                Set<String> matches = productCategories
                    .where((category) =>
                        category != 'Select a category' &&
                        category.toLowerCase().contains(query.toLowerCase()))
                    .toSet();

                // Find matches from keywords
                if (query.length >= 2) {
                  // Only use keywords for searches of 2+ characters
                  categoryKeywords.forEach((category, keywords) {
                    for (String keyword in keywords) {
                      if (keyword.toLowerCase().contains(query.toLowerCase()) ||
                          query.toLowerCase().contains(keyword.toLowerCase())) {
                        matches.add(category);
                        break;
                      }
                    }
                  });
                }

                filteredCategories = matches.toList();

                // Sort results: exact matches first, then contains, then keyword matches
                filteredCategories.sort((a, b) {
                  // Exact title match gets priority
                  bool aExact = a.toLowerCase() == query.toLowerCase();
                  bool bExact = b.toLowerCase() == query.toLowerCase();
                  if (aExact && !bExact) return -1;
                  if (!aExact && bExact) return 1;

                  // Title contains match gets second priority
                  bool aContains =
                      a.toLowerCase().contains(query.toLowerCase());
                  bool bContains =
                      b.toLowerCase().contains(query.toLowerCase());
                  if (aContains && !bContains) return -1;
                  if (!aContains && bContains) return 1;

                  // Alphabetical order
                  return a.compareTo(b);
                });
              }
            });
          }

          return Container(
            height: MediaQuery.of(context).size.height * 0.75,
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: Colors.white.withOpacity(0.1),
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Select Category',
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(
                          Icons.close_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ],
                  ),
                ),
                // Search field
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.1),
                      ),
                    ),
                    child: TextField(
                      controller: searchController,
                      onChanged: filterCategories,
                      cursorColor: Colors.white,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                      decoration: InputDecoration(
                        prefixIcon: Icon(
                          Icons.search_rounded,
                          color: Colors.white.withOpacity(0.5),
                        ),
                        hintText: 'Search categories...',
                        hintStyle: GoogleFonts.poppins(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 14,
                        ),
                        border: InputBorder.none,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ),
                // Expanded GridView for scrollable grid
                Expanded(
                  child: filteredCategories.isEmpty
                      ? Center(
                          child: Text(
                            'No matching categories',
                            style: GoogleFonts.poppins(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 14,
                            ),
                          ),
                        )
                      : GridView.builder(
                          padding: const EdgeInsets.all(16),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            childAspectRatio: 0.85,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                          ),
                          itemCount: filteredCategories.length,
                          itemBuilder: (context, index) {
                            final category = filteredCategories[index];
                            final isSelected = category == dropdownValue;

                            return Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () {
                                  if (mounted) {
                                    this.setState(() {
                                      dropdownValue = category;
                                    });
                                  }
                                  Navigator.pop(context);
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? Colors.blue.withOpacity(0.2)
                                        : Colors.white.withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isSelected
                                          ? Colors.blue
                                          : Colors.white.withOpacity(0.1),
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? Colors.blue.withOpacity(0.1)
                                              : Colors.white.withOpacity(0.05),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          categoryIcons[category] ??
                                              Icons.category_rounded,
                                          color: isSelected
                                              ? Colors.blue
                                              : Colors.white,
                                          size: 28,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 4),
                                        child: Text(
                                          category,
                                          style: GoogleFonts.poppins(
                                            fontSize: 12,
                                            fontWeight: isSelected
                                                ? FontWeight.w600
                                                : FontWeight.w500,
                                            color: isSelected
                                                ? Colors.blue
                                                : Colors.white,
                                          ),
                                          textAlign: TextAlign.center,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _checkAndShowStoreReview() async {
    // Wait a moment after posting is complete
    await Future.delayed(const Duration(seconds: 3));

    // Check if we should show a review prompt after posting
    bool shouldShow = await StoreReviewHelper.shouldRequestReviewAfterPost();
    if (shouldShow && mounted) {
      // First, ask the user if they like the app
      bool? likesApp = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withOpacity(0.1),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.thumb_up_alt_rounded,
                      color: Colors.blue,
                      size: 48,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Are you enjoying our app?',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'We\'d love to hear your feedback!',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.8),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context, false),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey[800],
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Not Really',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Yes, I Do!',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      );

      // If the user likes the app, show the App Store review dialog
      if (likesApp == true) {
        // Request a review using Apple's SKStoreReviewController
        await StoreReviewHelper.requestReview();
      } else if (likesApp == false && mounted) {
        // If the user doesn't like the app, show a feedback dialog
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return Dialog(
              backgroundColor: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.sentiment_dissatisfied_rounded,
                        color: Colors.orange,
                        size: 48,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'We\'re Sorry to Hear That',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Your feedback helps us improve. We\'re constantly working to make the app better for you.',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.8),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        minimumSize: const Size(double.infinity, 48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'OK',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
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

      // Mark that we've shown the review request regardless of the response
      await StoreReviewHelper.markPostReviewRequested();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_selectedImages.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.blue.shade900.withOpacity(0.8), Colors.black],
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
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.1),
                        ),
                      ),
                      child: Text(
                        "Share your needs and find help from others for free.\n\nOr share items you no longer need.",
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: Colors.white.withOpacity(0.9),
                          height: 1.6,
                          letterSpacing: 0.3,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 40),
                    Container(
                      width: double.infinity,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.blue.shade400, Colors.blue.shade600],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.shade900.withOpacity(0.3),
                            spreadRadius: 0,
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () => selectImage(context),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.add_a_photo_rounded,
                                  color: Colors.white,
                                  size: 24,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Add Images (${_selectedImages.length}/5)',
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
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
    } else {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
            onPressed: clearImage,
          ),
          title: Text(
            'Create Post',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          actions: [
            TextButton(
              onPressed:
                  _country.isEmpty || dropdownValue == 'Select a category'
                      ? () {
                          if (_country.isEmpty) {
                            _showSafeSnackBar('Please select location');
                          } else {
                            _showSafeSnackBar('Please select a category');
                          }
                        }
                      : () => postImage(uid, username!, profImage!),
              child: Text(
                "Share",
                style: GoogleFonts.poppins(
                  color: Colors.blue,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
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
                    Container(
                      width: double.infinity,
                      height: 3,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.blue.shade400,
                            Colors.blue.shade600,
                            Colors.purple.shade400,
                          ],
                        ),
                      ),
                      child: const LinearProgressIndicator(
                        backgroundColor: Colors.transparent,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.1),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                              width: 2,
                            ),
                          ),
                          child: CircleAvatar(
                            backgroundImage: NetworkImage(profImage!),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          username!,
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.1),
                      ),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _showCategoryPicker,
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: dropdownValue != 'Select a category'
                                      ? Colors.blue.withOpacity(0.1)
                                      : Colors.white.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  dropdownValue != 'Select a category'
                                      ? categoryIcons[dropdownValue] ??
                                          Icons.category_rounded
                                      : Icons.category_rounded,
                                  color: dropdownValue != 'Select a category'
                                      ? Colors.blue
                                      : Colors.white,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  dropdownValue,
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: dropdownValue != 'Select a category'
                                        ? Colors.white
                                        : Colors.white.withOpacity(0.5),
                                  ),
                                ),
                              ),
                              Icon(
                                Icons.arrow_forward_ios_rounded,
                                color: Colors.white.withOpacity(0.5),
                                size: 16,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.1),
                      ),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.location_on_rounded,
                            color: Colors.blue,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _country.isNotEmpty
                                ? [_country, _state, _city]
                                    .where((s) => s.isNotEmpty)
                                    .join(', ')
                                : 'Set Your Location',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const CountryStateCity(),
                              ),
                            );
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.blue,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                          ),
                          child: Text(
                            _country.isNotEmpty ? 'Change' : 'Set',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Image Container with PageView
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          spreadRadius: 0,
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        // PageView for scrolling through images
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: AspectRatio(
                            aspectRatio: 1,
                            child: PageView.builder(
                              controller: _pageController,
                              itemCount: _selectedImages.length,
                              onPageChanged: (index) {
                                setState(() {
                                  _currentPage = index;
                                });
                              },
                              itemBuilder: (context, index) {
                                return Stack(
                                  children: [
                                    // Image
                                    Container(
                                      width: double.infinity,
                                      height: double.infinity,
                                      decoration: BoxDecoration(
                                        image: DecorationImage(
                                          image: MemoryImage(
                                              _selectedImages[index]),
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),

                                    // Delete button in the top-right corner
                                    Positioned(
                                      top: 12,
                                      right: 12,
                                      child: GestureDetector(
                                        onTap: () {
                                          _deleteImage(index);
                                        },
                                        child: Container(
                                          width: 36,
                                          height: 36,
                                          decoration: BoxDecoration(
                                            color: Colors.red.withOpacity(0.8),
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black
                                                    .withOpacity(0.3),
                                                spreadRadius: 1,
                                                blurRadius: 5,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: const Icon(
                                            Icons.delete_outline_rounded,
                                            color: Colors.white,
                                            size: 20,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                        ),

                        // Wanted badge if applicable
                        if (isWanted)
                          Positioned(
                            top: 16,
                            right: 16,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    spreadRadius: 0,
                                    blurRadius: 10,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Text(
                                "Wanted",
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),

                        // Add more images button
                        Positioned(
                          bottom: 16,
                          right: 16,
                          child: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: _selectedImages.length >= 5
                                  ? Colors.grey
                                  : Colors.blue,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  spreadRadius: 0,
                                  blurRadius: 10,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: IconButton(
                              icon: Icon(
                                _selectedImages.length >= 5
                                    ? Icons.check_circle
                                    : Icons.add_photo_alternate,
                                color: Colors.white,
                              ),
                              onPressed: _selectedImages.length >= 5
                                  ? () {
                                      if (mounted) {
                                        _showSafeSnackBar(
                                            'Maximum 5 images allowed');
                                      }
                                    }
                                  : () => selectImage(context),
                            ),
                          ),
                        ),

                        // Page indicator dots
                        if (_selectedImages.length > 1)
                          Positioned(
                            bottom: 16,
                            left: 0,
                            right: 0,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(
                                _selectedImages.length,
                                (index) => Container(
                                  width: 8,
                                  height: 8,
                                  margin: EdgeInsets.symmetric(horizontal: 4),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: _currentPage == index
                                        ? Colors.white
                                        : Colors.white.withOpacity(0.4),
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Image counter
                  if (_selectedImages.length > 1)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Center(
                        child: Text(
                          "${_currentPage + 1}/${_selectedImages.length}",
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),

                  const SizedBox(height: 16),

                  // Rest of the UI remains the same
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
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.1),
                            ),
                          ),
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Mark as needed',
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Switch(
                                value: _switchValue,
                                onChanged: (value) {
                                  if (kIsWeb) {
                                    setState(() {
                                      _switchValue = value;
                                      isWanted = value;
                                    });
                                  } else if ((io.Platform.isAndroid &&
                                          userCredit >= 5) ||
                                      io.Platform.isIOS) {
                                    setState(() {
                                      _switchValue = value;
                                      isWanted = value;
                                    });
                                  } else {
                                    showDialog(
                                      context: context,
                                      builder: (BuildContext context) {
                                        return Dialog(
                                          backgroundColor: Colors.transparent,
                                          child: Container(
                                            padding: const EdgeInsets.all(24),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF1E1E1E),
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                            ),
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(
                                                  Icons.credit_card_rounded,
                                                  color: Colors.amber,
                                                  size: 48,
                                                ),
                                                const SizedBox(height: 16),
                                                Text(
                                                  'Insufficient Credits',
                                                  style: GoogleFonts.poppins(
                                                    fontSize: 20,
                                                    fontWeight: FontWeight.w600,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                                const SizedBox(height: 12),
                                                Text(
                                                  'You have $userCredit credit. You need at least 5 credits to use this feature.',
                                                  style: GoogleFonts.poppins(
                                                    fontSize: 14,
                                                    color: Colors.white
                                                        .withOpacity(0.8),
                                                  ),
                                                  textAlign: TextAlign.center,
                                                ),
                                                const SizedBox(height: 24),
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  children: [
                                                    Expanded(
                                                      child: TextButton(
                                                        onPressed: () =>
                                                            Navigator.pop(
                                                                context),
                                                        style: TextButton
                                                            .styleFrom(
                                                          padding:
                                                              const EdgeInsets
                                                                  .symmetric(
                                                                  vertical: 12),
                                                        ),
                                                        child: Text(
                                                          'Cancel',
                                                          style: GoogleFonts
                                                              .poppins(
                                                            fontSize: 15,
                                                            fontWeight:
                                                                FontWeight.w500,
                                                            color: Colors.white
                                                                .withOpacity(
                                                                    0.8),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 16),
                                                    Expanded(
                                                      child: ElevatedButton(
                                                        onPressed: () {
                                                          Navigator.pop(
                                                              context);
                                                          Navigator.push(
                                                            context,
                                                            MaterialPageRoute(
                                                              builder: (context) =>
                                                                  const CreditPage(),
                                                            ),
                                                          );
                                                        },
                                                        style: ElevatedButton
                                                            .styleFrom(
                                                          backgroundColor:
                                                              Colors.blue,
                                                          padding:
                                                              const EdgeInsets
                                                                  .symmetric(
                                                                  vertical: 12),
                                                          shape:
                                                              RoundedRectangleBorder(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        8),
                                                          ),
                                                        ),
                                                        child: Text(
                                                          'Earn Credits',
                                                          style: GoogleFonts
                                                              .poppins(
                                                            fontSize: 15,
                                                            fontWeight:
                                                                FontWeight.w500,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    );
                                  }
                                },
                                activeColor: Colors.green,
                                inactiveTrackColor:
                                    Colors.white.withOpacity(0.1),
                              ),
                            ],
                          ),
                        );
                      } else {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: Colors.white,
                          ),
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.1),
                      ),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: TextField(
                      maxLength: 300,
                      controller: _descriptionController,
                      maxLines: 4,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Write a caption...',
                        hintStyle: GoogleFonts.poppins(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 14,
                        ),
                        border: InputBorder.none,
                        counterStyle: GoogleFonts.poppins(
                          color: Colors.white.withOpacity(0.5),
                        ),
                      ),
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

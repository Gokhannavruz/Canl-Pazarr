// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:io' as io;
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';

const String defaultProfilePicture =
    "https://firebasestorage.googleapis.com/v0/b/freethings-257b6.appspot.com/o/defaulprofilephoto%2FdefaultProfilePhoto.png?alt=media&token=f2500621-2916-4601-bcbe-93c63d7fa802";

class EditProfileScreen extends StatefulWidget {
  final String userId;

  const EditProfileScreen({
    Key? key,
    required this.userId,
  }) : super(key: key);

  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  XFile? _imageFile;
  bool _isLoading = false;
  String? _photoUrl;
  Uint8List? _webImage;

  @override
  void initState() {
    super.initState();
    _initializeUserData();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _initializeUserData() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .get();

      if (!mounted) return;

      setState(() {
        _usernameController.text = userDoc['username'] ?? '';
        _bioController.text = userDoc['bio'] ?? '';
        _photoUrl = userDoc['photoUrl'];
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      _showError('Error loading profile: $e');
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _handleImageSelection(ImageSource source) async {
    if (!mounted) return;

    Navigator.pop(context);
    try {
      // Web platformu için farklı davranış
      if (kIsWeb) {
        if (source == ImageSource.camera) {
          _showError(
              'Camera is not supported on web. Please choose from gallery instead.');
          return;
        }

        final XFile? imageFile =
            await ImagePicker().pickImage(source: ImageSource.gallery);
        if (imageFile != null && mounted) {
          final imageBytes = await imageFile.readAsBytes();
          setState(() {
            _webImage = imageBytes;
            _imageFile = imageFile;
            _photoUrl = null;
          });
        }
      } else {
        // Mobil platformlar için normal davranış
        final XFile? imageFile = await ImagePicker().pickImage(source: source);
        if (imageFile != null && mounted) {
          setState(() {
            _imageFile = imageFile;
            _photoUrl = null;
          });
        }
      }
    } catch (e) {
      _showError('Error selecting image: $e');
    }
  }

  Future<void> _saveChanges() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      if (_usernameController.text.trim().isEmpty) {
        throw 'Username cannot be empty';
      }

      String imageUrl = _photoUrl ?? defaultProfilePicture;

      if (_imageFile != null) {
        final Reference storageRef = FirebaseStorage.instance
            .ref()
            .child('profile_images')
            .child('${widget.userId}.jpg');

        UploadTask? uploadTask;

        if (kIsWeb) {
          // Web için sadece bytes kullanarak yükleme yapıyoruz
          if (_webImage != null) {
            // Web platformu için metadata
            SettableMetadata metadata = SettableMetadata(
              contentType: 'image/jpeg',
              customMetadata: {'uploaded-from': 'web'},
            );
            uploadTask = storageRef.putData(_webImage!, metadata);
          } else {
            throw 'Web image data is missing';
          }
        } else {
          // Mobil için File kullanıyoruz
          uploadTask = storageRef.putFile(io.File(_imageFile!.path));
        }

        if (uploadTask != null) {
          final TaskSnapshot downloadUrl = await uploadTask;
          imageUrl = await downloadUrl.ref.getDownloadURL();
        }
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .update({
        'username': _usernameController.text.trim(),
        'bio': _bioController.text.trim(),
        'photoUrl': imageUrl,
      });

      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      _showError(e.toString());
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildImageSelectionDialog() {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Change Profile Photo',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            if (!kIsWeb)
              _buildImageOption(
                icon: Icons.camera_alt_rounded,
                label: 'Take Photo',
                onTap: () => _handleImageSelection(ImageSource.camera),
              ),
            if (!kIsWeb) const Divider(color: Colors.white24),
            _buildImageOption(
              icon: Icons.photo_library_rounded,
              label: 'Choose from Library',
              onTap: () => _handleImageSelection(ImageSource.gallery),
            ),
            if (_photoUrl != defaultProfilePicture) ...[
              const Divider(color: Colors.white24),
              _buildImageOption(
                icon: Icons.delete_outline_rounded,
                label: 'Remove Current Photo',
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _imageFile = null;
                    _webImage = null;
                    _photoUrl = defaultProfilePicture;
                  });
                },
                isDestructive: true,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildImageOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Row(
          children: [
            Icon(
              icon,
              color: isDestructive ? Colors.red : Colors.white,
              size: 24,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: isDestructive ? Colors.red : Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileImage() {
    return Stack(
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 3,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(60),
            child: _photoUrl != null
                ? Image.network(
                    _photoUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      print('Error loading profile image: $error');
                      return Image.network(
                        defaultProfilePicture,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey.shade800,
                            child: Icon(
                              Icons.person,
                              color: Colors.white,
                              size: 60.0,
                            ),
                          );
                        },
                      );
                    },
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        color: Colors.grey.shade900,
                        child: Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                            color: Colors.white,
                          ),
                        ),
                      );
                    },
                  )
                : kIsWeb
                    ? _webImage != null
                        ? Image.memory(
                            _webImage!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              print('Error loading web image: $error');
                              return Container(
                                color: Colors.grey.shade800,
                                child: Icon(
                                  Icons.person,
                                  color: Colors.white,
                                  size: 60.0,
                                ),
                              );
                            },
                          )
                        : Image.network(
                            defaultProfilePicture,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey.shade800,
                                child: Icon(
                                  Icons.person,
                                  color: Colors.white,
                                  size: 60.0,
                                ),
                              );
                            },
                          )
                    : _imageFile != null
                        ? kIsWeb
                            ? Container(
                                color: Colors.grey.shade800,
                                child: Icon(
                                  Icons.person,
                                  color: Colors.white,
                                  size: 60.0,
                                ),
                              )
                            : Image.file(
                                io.File(_imageFile!.path),
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  print('Error loading file image: $error');
                                  return Container(
                                    color: Colors.grey.shade800,
                                    child: Icon(
                                      Icons.person,
                                      color: Colors.white,
                                      size: 60.0,
                                    ),
                                  );
                                },
                              )
                        : Image.network(
                            defaultProfilePicture,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey.shade800,
                                child: Icon(
                                  Icons.person,
                                  color: Colors.white,
                                  size: 60.0,
                                ),
                              );
                            },
                          ),
          ),
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: GestureDetector(
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => _buildImageSelectionDialog(),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.black,
                  width: 2,
                ),
              ),
              child: const Icon(
                Icons.camera_alt,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Text(
          'Edit Profile',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Colors.white,
              ),
            )
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Center(child: _buildProfileImage()),
                    const SizedBox(height: 32),
                    _buildTextField(
                      controller: _usernameController,
                      label: 'Username',
                      maxLength: 25,
                    ),
                    const SizedBox(height: 24),
                    _buildTextField(
                      controller: _bioController,
                      label: 'Bio',
                      maxLength: 100,
                      maxLines: 3,
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _saveChanges,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Save Changes',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required int maxLength,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLength: maxLength,
      maxLines: maxLines,
      style: GoogleFonts.poppins(
        color: Colors.white,
        fontSize: 16,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.poppins(
          color: Colors.white.withOpacity(0.7),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Colors.white.withOpacity(0.2),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Colors.blue,
            width: 2,
          ),
        ),
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        counterStyle: GoogleFonts.poppins(
          color: Colors.white.withOpacity(0.5),
        ),
      ),
    );
  }
}

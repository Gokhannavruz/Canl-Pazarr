// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

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

  @override
  void initState() {
    super.initState();
    _getUserData();
    _getPhotoUrl();
  }

  void _getPhotoUrl() async {
    // get photo url form firestore
    final DocumentSnapshot<Map<String, dynamic>> doc = await FirebaseFirestore
        .instance
        .collection('users')
        .doc(widget.userId)
        .get();
    setState(() {
      _photoUrl = doc['photoUrl'];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Edit Profile'),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : SingleChildScrollView(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(3.0),
                    child: GestureDetector(
                      onTap: () {
                        // select image
                        showDialog(
                          context: context,
                          builder: (context) {
                            return AlertDialog(
                              iconPadding: const EdgeInsets.all(15),
                              backgroundColor: const Color.fromARGB(255, 41, 38, 38),
                              title: const Text('Select Image'),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  GestureDetector(
                                    onTap: () async {
                                      Navigator.pop(context);
                                      final XFile? imageFile =
                                          await ImagePicker().pickImage(
                                              source: ImageSource.camera);
                                      if (imageFile != null) {
                                        setState(() {
                                          _imageFile = imageFile;
                                          _photoUrl = null;
                                        });
                                      }
                                    },
                                    child: const Padding(
                                      padding: EdgeInsets.all(8.0),
                                      child: Row(
                                        children: [
                                          Icon(Icons.camera_alt),
                                          SizedBox(
                                            width: 8,
                                          ),
                                          Text('Camera'),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(
                                    height: 10,
                                  ),
                                  GestureDetector(
                                    onTap: () async {
                                      Navigator.pop(context);
                                      final XFile? imageFile =
                                          await ImagePicker().pickImage(
                                              source: ImageSource.gallery);
                                      if (imageFile != null) {
                                        setState(() {
                                          _imageFile = imageFile;
                                          _photoUrl = null;
                                        });
                                      }
                                    },
                                    child: const Padding(
                                      padding: EdgeInsets.all(8.0),
                                      child: Row(
                                        children: [
                                          Icon(Icons.image),
                                          SizedBox(
                                            width: 8,
                                          ),
                                          Text('Gallery'),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                      child: Stack(
                        children: [
                          _photoUrl != null
                              ? CircleAvatar(
                                  radius: 80,
                                  backgroundImage: NetworkImage(_photoUrl!),
                                  backgroundColor:
                                      const Color.fromARGB(255, 255, 255, 255),
                                )
                              : _imageFile != null
                                  ? CircleAvatar(
                                      radius: 80,
                                      backgroundImage:
                                          FileImage(File(_imageFile!.path)),
                                      backgroundColor:
                                          const Color.fromARGB(255, 255, 255, 255),
                                    )
                                  : const CircleAvatar(
                                      radius: 80,
                                      backgroundImage: NetworkImage(
                                          'https://i.stack.imgur.com/l60Hf.png'),
                                      backgroundColor:
                                          Color.fromARGB(255, 255, 255, 255),
                                    ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(
                        left: 30.0, right: 30.0, top: 16.0),
                    child: TextFormField(
                      maxLength: 25,
                      controller: _usernameController,
                      decoration: const InputDecoration(
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: Color.fromARGB(255, 23, 77, 184),
                          ),
                        ),
                        labelText: 'Username',
                        labelStyle: TextStyle(
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(
                        left: 30.0, right: 30.0, top: 16.0),
                    child: TextFormField(
                      strutStyle: const StrutStyle(
                        height: 1.5,
                      ),
                      maxLength: 100,
                      maxLines: 3,
                      controller: _bioController,
                      decoration: const InputDecoration(
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: Color.fromARGB(255, 23, 77, 184),
                          ),
                        ),
                        labelText: 'Bio',
                        labelStyle: TextStyle(
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  // e-mail
                  ElevatedButton(
                    style: // border radius
                        ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 23, 77, 184),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30.0),
                      ),
                    ),
                    onPressed: () {
                      _saveChanges();
                    },
                    child: const Text('Save Changes'),
                  ),
                ],
              ),
            ),
    );
  }

  void _getUserData() async {
    setState(() {
      _isLoading = true;
    });

    DocumentSnapshot userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .get();

    setState(() {
      _usernameController.text = userDoc['username'];
      _bioController.text = userDoc['bio'];
      _isLoading = false;
    });
  }

// save changes
  void _saveChanges() async {
    setState(() {
      _isLoading = true;
    });

    // upload image to firebase storage
    String imageUrl = '';
    if (_imageFile != null) {
      final Reference storageRef = FirebaseStorage.instance
          .ref()
          .child('profile_images')
          .child('${widget.userId}.jpg');
      final UploadTask uploadTask = storageRef.putFile(File(_imageFile!.path));
      final TaskSnapshot downloadUrl = (await uploadTask);
      imageUrl = await downloadUrl.ref.getDownloadURL();
    } else {
      imageUrl = _photoUrl!;
    }

    // if username include space or empty string then return error
    if (_usernameController.text.contains(' ') ||
        _usernameController.text.isEmpty) {
      setState(() {
        _isLoading = false;
      });
      return showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            backgroundColor: const Color.fromARGB(255, 41, 38, 38),
            title: const Text('Error'),
            content: const Text('Username cannot contain space or empty'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('OK', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      );
    }
    // update user data
    await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .update({
      'username': _usernameController.text,
      'bio': _bioController.text,
      'photoUrl': imageUrl,
    });

    setState(() {
      _isLoading = false;
    });

    // go back to profile screen
    Navigator.pop(context);
  }
}

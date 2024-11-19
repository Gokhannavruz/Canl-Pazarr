import 'dart:typed_data';
import 'package:Freecycle/resources/auth_methods.dart';
import 'package:Freecycle/responsive/mobile_screen_layout.dart';
import 'package:Freecycle/responsive/responsive_layout_screen.dart';
import 'package:Freecycle/responsive/web_screen_layout.dart';
import 'package:Freecycle/screens/country_state_city_picker.dart';
import 'package:Freecycle/screens/terms_of_use_page.dart';
import 'package:Freecycle/screens/welcomepage.dart';
import 'package:Freecycle/utils/utils.dart';
import 'package:csc_picker/model/select_status_model.dart';
import 'package:flutter/material.dart';

import 'dart:typed_data';
import 'package:flutter/material.dart';

class PhoneVerificationScreen extends StatefulWidget {
  const PhoneVerificationScreen({Key? key}) : super(key: key);

  @override
  State<PhoneVerificationScreen> createState() =>
      _PhoneVerificationScreenState();
}

class _PhoneVerificationScreenState extends State<PhoneVerificationScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();

  bool _isLoading = false;
  bool _acceptedTerms =
      false; // Kullanıcının şartları kabul edip etmediğini tutar
  Uint8List? _image;
  double screenHeight = 0;
  double screenWidth = 0;

  @override
  void dispose() {
    super.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _emailController.dispose();
    _bioController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    screenHeight = MediaQuery.of(context).size.height;
    screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: const Color.fromARGB(255, 0, 0, 0),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Flex(
            direction: Axis.vertical,
            children: [
              Container(
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 30),
                      const Text(
                        "Create Account",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color.fromARGB(255, 255, 255, 255),
                        ),
                      ),
                      const SizedBox(height: 30),
                      Column(
                        children: [
                          TextFormField(
                            maxLength: 25,
                            controller: _usernameController,
                            decoration: const InputDecoration(
                              labelText: "Username",
                              labelStyle: TextStyle(
                                color: Color.fromARGB(255, 255, 255, 255),
                              ),
                              hintText: "Enter your username",
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: Colors.blue,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              labelText: "Email",
                              labelStyle: TextStyle(
                                color: Color.fromARGB(255, 255, 255, 255),
                              ),
                              hintText: "Enter your email address",
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: Colors.blue,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: true,
                            decoration: const InputDecoration(
                              labelText: "Password",
                              labelStyle: TextStyle(
                                color: Color.fromARGB(255, 255, 255, 255),
                              ),
                              hintText: "Enter your password",
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: Colors.blue,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          CheckboxListTile(
                            title: Text(
                              "I accept the terms and conditions",
                              style: TextStyle(
                                color: Colors.white,
                              ),
                            ),
                            value: _acceptedTerms,
                            onChanged: (value) {
                              setState(() {
                                _acceptedTerms = value!;
                              });
                            },
                            controlAffinity: ListTileControlAffinity.leading,
                            checkColor: Colors.white,
                            activeColor: Colors.blue,
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              TextButton(
                                onPressed: () {
                                  _showTermsDialog();
                                },
                                child: Text(
                                  "Terms",
                                  style: TextStyle(
                                    color: Colors.blue,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  _showConditionDialog();
                                },
                                child: Text(
                                  "Conditions",
                                  style: TextStyle(
                                    color: Colors.blue,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 30),
                      Center(
                        child: _isLoading
                            ? const CircularProgressIndicator(
                                valueColor:
                                    AlwaysStoppedAnimation(Colors.white),
                              )
                            : ElevatedButton(
                                onPressed: () {
                                  if (_acceptedTerms) {
                                    signUpUser();
                                  } else {
                                    // Kullanıcı şartları kabul etmediğinde bir uyarı göster
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          "Please accept the terms and conditions",
                                        ),
                                      ),
                                    );
                                  }
                                },
                                style: ButtonStyle(
                                  shape: MaterialStateProperty.all(
                                    RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                  ),
                                  backgroundColor:
                                      MaterialStateProperty.all(Colors.blue),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(15),
                                  child: const Text(
                                    "Create Account",
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showConditionDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Color.fromARGB(255, 6, 6, 6),
          title: const Text('Terms and Conditions'),
          content: SingleChildScrollView(
            child: RichText(
              text: TextSpan(
                style: TextStyle(fontSize: 16.0, color: Colors.white),
                children: [
                  TextSpan(
                    text: 'Freecycle End User License Agreement (EULA)\n\n',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18.0,
                    ),
                  ),
                  _buildTextSpan('1. License Grant\n'),
                  _buildTextSpan(
                      'We grant you a limited, non-exclusive, non-transferable, revocable license to use Freecycle in accordance with these terms.\n\n'),
                  _buildTextSpan('2. Restrictions\n'),
                  _buildTextSpan('You may not:\n\n'
                      '- Decompile, reverse engineer, disassemble, attempt to derive the source code of, or decrypt Freecycle.\n\n'
                      '- Make any modification, adaptation, improvement, enhancement, translation, or derivative work from Freecycle.\n\n'
                      '- Use Freecycle for any unlawful or illegal activity, or to facilitate any illegal activity.\n\n'),
                  _buildTextSpan('3. User Content\n'),
                  _buildTextSpan(
                      'You are responsible for the content you post on or through Freecycle. By posting content, you grant us a worldwide, non-exclusive, royalty-free, transferable license to use, reproduce, distribute, prepare derivative works of, display, and perform that content in connection with the service.\n\n'),
                  _buildTextSpan('4. No Tolerance for Objectionable Content\n'),
                  _buildTextSpan(
                      'There is zero tolerance for objectionable content or abusive users. Users found to be engaging in such activities will have their accounts terminated.\n\n'),
                  _buildTextSpan('5. Termination\n'),
                  _buildTextSpan(
                      'We may terminate your access to Freecycle if you fail to comply with any of the terms and conditions of this EULA. Upon termination, you must cease all use of Freecycle and delete all copies of Freecycle from your devices.\n\n'),
                  _buildTextSpan('6. Changes to EULA\n'),
                  _buildTextSpan(
                      'We may update this EULA from time to time. The most current version will always be available on our website. Your continued use of Freecycle after any updates indicates your acceptance of the new terms.\n\n'),
                  _buildTextSpan('7. Contact Information\n'),
                  _buildTextSpan(
                      'If you have any questions about this EULA, please contact us at gkhnnavruz@gmail.com'),
                ],
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK',
                  style: TextStyle(
                    color: Colors.blue,
                    fontSize: 16.0,
                  )),
            ),
          ],
        );
      },
    );
  }

  void _showTermsDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Color.fromARGB(255, 6, 6, 6),
          title: const Text('Terms and Conditions'),
          content: SingleChildScrollView(
            child: RichText(
              text: TextSpan(
                style: TextStyle(fontSize: 16.0, color: Colors.white),
                children: [
                  TextSpan(
                    text: 'Freecycle Terms of Service (ToS)\n\n',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18.0,
                    ),
                  ),
                  _buildTextSpan('1. Acceptance of Terms\n'),
                  _buildTextSpan(
                      'By accessing or using Freecycle, you agree to be bound by these Terms of Service and our Privacy Policy. If you do not agree with any part of these terms, you must not use our services.\n\n'),
                  _buildTextSpan('2. User Conduct\n'),
                  _buildTextSpan('You agree not to use Freecycle to:\n\n'
                      '- Post, upload, or share any content that is illegal, harmful, threatening, abusive, harassing, defamatory, vulgar, obscene, hateful, or otherwise objectionable.\n\n'
                      '- Impersonate any person or entity or falsely state or otherwise misrepresent your affiliation with a person or entity.\n\n'
                      '- Engage in any form of bullying, harassment, or intimidation.\n\n'
                      '- Post or transmit any content that infringes any patent, trademark, trade secret, copyright, or other proprietary rights of any party.\n\n'
                      '- Upload, post, or transmit any material that contains software viruses or any other computer code, files, or programs designed to interrupt, destroy, or limit the functionality of any computer software or hardware.\n\n'),
                  _buildTextSpan('3. Content Moderation\n'),
                  _buildTextSpan(
                      'We reserve the right, but have no obligation, to monitor, edit, or remove any activity or content that we determine in our sole discretion violates these terms or is otherwise objectionable.\n\n'),
                  _buildTextSpan('4. Reporting and Blocking\n'),
                  _buildTextSpan(
                      'Users can report offensive content or behavior by using the report feature within Freecycle. We will review and take appropriate action on reported content or users promptly. Users also have the ability to block other users to prevent further interaction.\n\n'),
                  _buildTextSpan('5. Termination\n'),
                  _buildTextSpan(
                      'We reserve the right to terminate or suspend your account and access to Freecycle without notice if we determine, in our sole discretion, that you have violated these terms or engaged in any conduct that we consider inappropriate or harmful.\n\n'),
                  _buildTextSpan('6. Changes to Terms\n'),
                  _buildTextSpan(
                      'We may revise these Terms of Service from time to time. The most current version will always be posted on our website. By continuing to use our services after changes are made, you agree to be bound by the revised terms.\n\n'),
                  _buildTextSpan('7. Contact Information\n'),
                  _buildTextSpan(
                      'If you have any questions about these Terms of Service, please contact us at gkhnnavruz@gmail.com'),
                ],
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK',
                  style: TextStyle(
                    color: Colors.blue,
                    fontSize: 16.0,
                  )),
            ),
          ],
        );
      },
    );
  }

  TextSpan _buildTextSpan(String text) {
    return TextSpan(
      text: text,
      style: TextStyle(fontSize: 16.0),
    );
  }

  void signUpUser() async {
    setState(() {
      _isLoading = true;
    });

    // Remove spaces and convert to lowercase
    String username =
        _usernameController.text.replaceAll(' ', '').toLowerCase();

    // signup user using authmethods
    String res = await AuthMethods().signUpUser(
      email: _emailController.text,
      password: _passwordController.text,
      username: username,
      bio: _bioController.text,
      file: _image,
    );

    setState(() {
      _isLoading = false;
    });

    if (res == "success") {
      // navigate to the CountrStateCityScreen
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const WelcomePage(),
        ),
      );
    } else {
      // show the error
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res)));
    }
  }
}

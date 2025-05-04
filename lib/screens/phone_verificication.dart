import 'dart:typed_data';
import 'package:freecycle/resources/auth_methods.dart';
import 'package:freecycle/responsive/mobile_screen_layout.dart';
import 'package:freecycle/responsive/responsive_layout_screen.dart';
import 'package:freecycle/responsive/web_screen_layout.dart';
import 'package:freecycle/screens/country_state_city_picker.dart';
import 'package:freecycle/screens/terms_of_use_page.dart';
import 'package:freecycle/screens/welcomepage.dart';
import 'package:freecycle/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';

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
  bool _acceptedTerms = false;
  Uint8List? _image;
  double screenHeight = 0;
  double screenWidth = 0;
  bool _obscurePassword = true;

  // Form validation error messages
  String? _usernameError;
  String? _emailError;
  String? _passwordError;

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
    bool isWebLayout = screenWidth > 900;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.arrow_back_ios, size: 18),
          ),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue.shade900.withOpacity(0.8),
              Colors.black,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: isWebLayout ? screenWidth * 0.1 : 24,
                right: isWebLayout ? screenWidth * 0.1 : 24,
                top: 20,
              ),
              child: isWebLayout ? _buildWebLayout() : _buildMobileLayout(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWebLayout() {
    return Container(
      constraints: BoxConstraints(maxWidth: 1200),
      child: Card(
        color: Colors.grey[900]?.withOpacity(0.7),
        elevation: 5,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(40.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text(
                "Create Account",
                style: GoogleFonts.poppins(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Join our community and start sharing",
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 40),

              // Two column layout for web
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left column (form fields)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInputField(
                          controller: _usernameController,
                          label: "Username",
                          hintText: "Enter your username",
                          icon: Icons.person_outline_rounded,
                          maxLength: 25,
                          errorText: _usernameError,
                        ),
                        const SizedBox(height: 24),
                        _buildInputField(
                          controller: _emailController,
                          label: "Email",
                          hintText: "Enter your email address",
                          icon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                          errorText: _emailError,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 40),
                  // Right column (password and terms)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildPasswordField(),
                        const SizedBox(height: 24),
                        _buildTermsCheckbox(),
                        const SizedBox(height: 8),
                        _buildTermsLinks(),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),

              // Create Account Button (full width)
              _buildCreateAccountButton(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Text(
          "Create Account",
          style: GoogleFonts.poppins(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "Join our community and start sharing",
          style: GoogleFonts.poppins(
            fontSize: 16,
            color: Colors.white.withOpacity(0.7),
          ),
        ),
        const SizedBox(height: 40),

        // Form Fields
        _buildInputField(
          controller: _usernameController,
          label: "Username",
          hintText: "Enter your username",
          icon: Icons.person_outline_rounded,
          maxLength: 25,
          errorText: _usernameError,
        ),
        const SizedBox(height: 20),

        _buildInputField(
          controller: _emailController,
          label: "Email",
          hintText: "Enter your email address",
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
          errorText: _emailError,
        ),
        const SizedBox(height: 20),

        _buildPasswordField(),
        const SizedBox(height: 24),

        // Terms and Conditions
        _buildTermsCheckbox(),
        const SizedBox(height: 8),

        _buildTermsLinks(),
        const SizedBox(height: 40),

        // Create Account Button
        _buildCreateAccountButton(),
        const SizedBox(height: 30),
      ],
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hintText,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int? maxLength,
    String? errorText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.white.withOpacity(0.9),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: errorText != null
                  ? Colors.red.withOpacity(0.7)
                  : Colors.white.withOpacity(0.1),
            ),
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            maxLength: maxLength,
            cursorColor: Colors.white,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 15,
            ),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: GoogleFonts.poppins(
                color: Colors.white.withOpacity(0.4),
                fontSize: 15,
              ),
              prefixIcon: Icon(
                icon,
                color: errorText != null
                    ? Colors.red.withOpacity(0.7)
                    : Colors.white.withOpacity(0.7),
                size: 22,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 16),
              counterText: "",
            ),
          ),
        ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 8),
            child: Text(
              errorText,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.red.withOpacity(0.9),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Password",
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.white.withOpacity(0.9),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _passwordError != null
                  ? Colors.red.withOpacity(0.7)
                  : Colors.white.withOpacity(0.1),
            ),
          ),
          child: TextField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            cursorColor: Colors.white,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 15,
            ),
            decoration: InputDecoration(
              hintText: "Enter your password",
              hintStyle: GoogleFonts.poppins(
                color: Colors.white.withOpacity(0.4),
                fontSize: 15,
              ),
              prefixIcon: Icon(
                Icons.lock_outline_rounded,
                color: _passwordError != null
                    ? Colors.red.withOpacity(0.7)
                    : Colors.white.withOpacity(0.7),
                size: 22,
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  color: Colors.white.withOpacity(0.7),
                  size: 22,
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
        if (_passwordError != null)
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 8),
            child: Text(
              _passwordError!,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.red.withOpacity(0.9),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTermsCheckbox() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: CheckboxListTile(
        title: Text(
          "I accept the terms and conditions",
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 14,
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 8),
      ),
    );
  }

  Widget _buildTermsLinks() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        TextButton(
          onPressed: () {
            _showTermsDialog();
          },
          style: TextButton.styleFrom(
            foregroundColor: Colors.blue,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          child: Text(
            "Terms",
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
        Container(
          height: 16,
          width: 1,
          color: Colors.white.withOpacity(0.3),
        ),
        TextButton(
          onPressed: () {
            _showConditionDialog();
          },
          style: TextButton.styleFrom(
            foregroundColor: Colors.blue,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          child: Text(
            "Conditions",
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCreateAccountButton() {
    bool isWebLayout = MediaQuery.of(context).size.width > 900;

    return Container(
      width: double.infinity,
      height: isWebLayout ? 60 : 56,
      constraints: isWebLayout ? BoxConstraints(maxWidth: 600) : null,
      margin: isWebLayout
          ? const EdgeInsets.symmetric(horizontal: 16)
          : EdgeInsets.zero,
      child: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : ElevatedButton(
              onPressed: () {
                if (_acceptedTerms) {
                  signUpUser();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        "Please accept the terms and conditions",
                        style: GoogleFonts.poppins(),
                      ),
                      backgroundColor: Colors.red,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                elevation: isWebLayout ? 3 : 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: EdgeInsets.symmetric(vertical: isWebLayout ? 16 : 12),
              ),
              child: Text(
                "Create Account",
                style: GoogleFonts.poppins(
                  fontSize: isWebLayout ? 18 : 16,
                  fontWeight: FontWeight.w600,
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
          backgroundColor: Color(0xFF222222),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Terms and Conditions',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          content: SingleChildScrollView(
            child: RichText(
              text: TextSpan(
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.9),
                ),
                children: [
                  TextSpan(
                    text: 'freecycle End User License Agreement (EULA)\n\n',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  _buildTextSpan('1. License Grant\n'),
                  _buildTextSpan(
                      'We grant you a limited, non-exclusive, non-transferable, revocable license to use freecycle in accordance with these terms.\n\n'),
                  _buildTextSpan('2. Restrictions\n'),
                  _buildTextSpan('You may not:\n\n'
                      '- Decompile, reverse engineer, disassemble, attempt to derive the source code of, or decrypt freecycle.\n\n'
                      '- Make any modification, adaptation, improvement, enhancement, translation, or derivative work from freecycle.\n\n'
                      '- Use freecycle for any unlawful or illegal activity, or to facilitate any illegal activity.\n\n'),
                  _buildTextSpan('3. User Content\n'),
                  _buildTextSpan(
                      'You are responsible for the content you post on or through freecycle. By posting content, you grant us a worldwide, non-exclusive, royalty-free, transferable license to use, reproduce, distribute, prepare derivative works of, display, and perform that content in connection with the service.\n\n'),
                  _buildTextSpan('4. No Tolerance for Objectionable Content\n'),
                  _buildTextSpan(
                      'There is zero tolerance for objectionable content or abusive users. Users found to be engaging in such activities will have their accounts terminated.\n\n'),
                  _buildTextSpan('5. Termination\n'),
                  _buildTextSpan(
                      'We may terminate your access to freecycle if you fail to comply with any of the terms and conditions of this EULA. Upon termination, you must cease all use of freecycle and delete all copies of freecycle from your devices.\n\n'),
                  _buildTextSpan('6. Changes to EULA\n'),
                  _buildTextSpan(
                      'We may update this EULA from time to time. The most current version will always be available on our website. Your continued use of freecycle after any updates indicates your acceptance of the new terms.\n\n'),
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
              child: Text(
                'OK',
                style: GoogleFonts.poppins(
                  color: Colors.blue,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
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
          backgroundColor: Color(0xFF222222),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Terms and Conditions',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          content: SingleChildScrollView(
            child: RichText(
              text: TextSpan(
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.9),
                ),
                children: [
                  TextSpan(
                    text: 'freecycle Terms of Service (ToS)\n\n',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  _buildTextSpan('1. Acceptance of Terms\n'),
                  _buildTextSpan(
                      'By accessing or using freecycle, you agree to be bound by these Terms of Service and our Privacy Policy. If you do not agree with any part of these terms, you must not use our services.\n\n'),
                  _buildTextSpan('2. User Conduct\n'),
                  _buildTextSpan('You agree not to use freecycle to:\n\n'
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
                      'Users can report offensive content or behavior by using the report feature within freecycle. We will review and take appropriate action on reported content or users promptly. Users also have the ability to block other users to prevent further interaction.\n\n'),
                  _buildTextSpan('5. Termination\n'),
                  _buildTextSpan(
                      'We reserve the right to terminate or suspend your account and access to freecycle without notice if we determine, in our sole discretion, that you have violated these terms or engaged in any conduct that we consider inappropriate or harmful.\n\n'),
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
              child: Text(
                'OK',
                style: GoogleFonts.poppins(
                  color: Colors.blue,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  TextSpan _buildTextSpan(String text) {
    return TextSpan(
      text: text,
      style: GoogleFonts.poppins(fontSize: 14),
    );
  }

  void signUpUser() async {
    // Reset previous error messages
    setState(() {
      _usernameError = null;
      _emailError = null;
      _passwordError = null;
    });

    // Validate form fields
    bool isValid = true;

    if (_usernameController.text.isEmpty) {
      setState(() {
        _usernameError = "Username cannot be empty";
        isValid = false;
      });
    } else if (_usernameController.text.length < 3) {
      setState(() {
        _usernameError = "Username must be at least 3 characters";
        isValid = false;
      });
    }

    if (_emailController.text.isEmpty) {
      setState(() {
        _emailError = "Email cannot be empty";
        isValid = false;
      });
    } else if (!_emailController.text.contains('@') ||
        !_emailController.text.contains('.')) {
      setState(() {
        _emailError = "Please enter a valid email address";
        isValid = false;
      });
    }

    if (_passwordController.text.isEmpty) {
      setState(() {
        _passwordError = "Password cannot be empty";
        isValid = false;
      });
    } else if (_passwordController.text.length < 6) {
      setState(() {
        _passwordError = "Password must be at least 6 characters";
        isValid = false;
      });
    }

    if (!isValid) return;

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
      // Clean Firebase error codes from the error message
      String cleanErrorMessage = res;

      // Remove Firebase error code pattern [firebase_auth/something]
      if (res.contains(']')) {
        cleanErrorMessage = res.split(']').last.trim();
      }

      // Capitalize first letter if needed
      if (cleanErrorMessage.isNotEmpty) {
        cleanErrorMessage =
            cleanErrorMessage[0].toUpperCase() + cleanErrorMessage.substring(1);
      }

      // Parse error message and show in appropriate field
      if (cleanErrorMessage.toLowerCase().contains("email") ||
          res.toLowerCase().contains("email")) {
        setState(() {
          _emailError = cleanErrorMessage;
        });
      } else if (cleanErrorMessage.toLowerCase().contains("password") ||
          res.toLowerCase().contains("password")) {
        setState(() {
          _passwordError = cleanErrorMessage;
        });
      } else if (cleanErrorMessage.toLowerCase().contains("username") ||
          res.toLowerCase().contains("username")) {
        setState(() {
          _usernameError = cleanErrorMessage;
        });
      } else {
        // Show general error in snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              cleanErrorMessage,
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }
}

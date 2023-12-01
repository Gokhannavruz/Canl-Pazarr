import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';


class ForgetPassword extends StatefulWidget {
  const ForgetPassword({Key? key}) : super(key: key);

  @override
  State<ForgetPassword> createState() => _ForgetPasswordState();
}

class _ForgetPasswordState extends State<ForgetPassword> {
  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  // email controller
  final TextEditingController _emailController = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Forget Password'),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            height: 20,
          ),
          // you will get reset link on your email
          Row(
            children: [
              SizedBox(
                width: MediaQuery.of(context).size.width, // 20 is padding
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25.0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      color: const Color.fromARGB(255, 39, 37, 37),
                    ),
                    child: const Text(
                      'You will get reset link on your email. Please check your email box and create new password',
                      style: TextStyle(
                        fontSize: 17,
                      ),
                      overflow: TextOverflow
                          .visible, // metnin sınırlarını aşarak görünmesini sağlayabilirsiniz
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(
            height: 30,
          ),
          // text field for email and send the reset link to the emai
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Center(
              child: TextField(
                keyboardType: TextInputType.emailAddress,
                controller: _emailController,
                decoration: InputDecoration(
                  prefixIcon: const Icon(
                    Icons.email,
                    color: Colors.grey,
                    size: 20,
                  ),
                  hintText: 'Enter your email to get reset link',
                  hintStyle: const TextStyle(
                    color: Colors.grey,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(7),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(
            height: 25,
          ),
          // send reset link button
          InkWell(
            child: Container(
              width: MediaQuery.of(context).size.width / 2,
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(vertical: 13),
              decoration: const ShapeDecoration(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(20)),
                ),
                color: Color.fromARGB(255, 21, 113, 199),
              ),
              child: const Text(
                'Send link',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
            ),
            onTap: () {
              sendPasswordResetEmail(email: _emailController.text);
            },
          ),
          Flexible(
            flex: 2,
            child: Container(),
          ),
        ],
      ),
    );
  }

  // SEND RESET PASSWORD LINK
  Future<void> sendPasswordResetEmail({required String email}) async {
    // circular progress indicator
    try {
      await FirebaseAuth.instance
          .sendPasswordResetEmail(email: _emailController.text.trim());
      Navigator.of(context).popUntil((route) => route.isFirst);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reset password link sent to your email'),
        ),
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No user found for that email'),
          ),
        );
        // if email not found don't go back to login screen and clear the email text field
      } else if (e.code == 'invalid-email') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid email'),
          ),
        );
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    }
  }
}

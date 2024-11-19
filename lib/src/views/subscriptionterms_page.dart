import 'package:flutter/material.dart';

import 'package:flutter/material.dart';

class SubscriptionTermsPage extends StatelessWidget {
  const SubscriptionTermsPage({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Subscription Terms',
              style: TextStyle(
                fontSize: 24.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 20.0),
            // Diğer metinler burada devam ediyor...
            Padding(
              padding: const EdgeInsets.only(top: 20.0),
              child: Text(
                'Payment will be charged to iTunesAccount at confirmation of purchase\n'
                'Subscription automatically renews unless auto-renew is turned off at least 24-hours before the end of the current period.\n'
                'Account will be charged for renewal within 24-hours prior to the end of the current period.\n'
                'Subscriptions may be managed by the user and auto-renewal may be turned off\n'
                'by going to the user\'s Account Settings after purchase.',
                style: TextStyle(
                  fontSize: 16.0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

class SubscriptionTermsPageAndroid extends StatelessWidget {
  const SubscriptionTermsPageAndroid({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Subscription Terms'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Subscription Terms and Conditions',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildSection('1. Subscription Options:', [
              'We offer three subscription plans:',
              'a) Weekly Subscription',
              'b) Monthly Subscription',
              'c) Annual Subscription',
            ]),
            _buildSection('2. Billing Cycle:', [
              '• Your subscription will be charged to your Google Play account at confirmation of purchase.',
              '• The subscription automatically renews unless auto-renew is turned off at least 24-hours before the end of the current period.',
            ]),
            _buildSection('3. Auto-Renewal:', [
              '• Subscriptions automatically renew unless auto-renew is turned off at least 24-hours before the end of the current period.',
              '• Your account will be charged for renewal within 24-hours prior to the end of the current period.',
            ]),
            _buildSection('4. Managing Your Subscription:', [
              '• You can manage your subscriptions and turn off auto-renewal by going to your Google Play account settings after purchase.',
            ]),
            _buildSection('5. Cancellation:', [
              '• You can cancel your subscription at any time through your Google Play account settings.',
              '• Cancellation will take effect at the end of the current billing period.',
              '• No refunds will be provided for the unused portion of the current billing period.',
            ]),
            _buildSection('6. Changes to Subscription:', [
              '• We reserve the right to change subscription fees at any time. Any changes will be communicated to you in advance.',
              '• If we change the subscription price and you do not wish to renew at the new price, you can cancel your subscription.',
            ]),
            _buildSection('7. No Trial Period:', [
              '• Our subscription plans do not include a free trial period.',
              '• All subscriptions are paid from the moment of purchase.',
            ]),
            _buildSection('8. Content Access:', [
              '• Upon subscribing, you will have access to [describe what they get access to].',
              '• If you cancel your subscription, you will lose access to the subscription content at the end of your billing period.',
            ]),
            _buildSection('9. Support:', [
              '• For any questions or issues regarding your subscription, please contact our customer support at [your support email or contact information].',
            ]),
            const SizedBox(height: 16),
            const Text(
              'By subscribing, you acknowledge that you have read and agree to these terms and conditions.',
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 16),
            Text(
              'Last updated: ${DateTime.now().toString().split(' ')[0]}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ...items.map((item) => Padding(
              padding: const EdgeInsets.only(left: 16, bottom: 8),
              child: Text(item),
            )),
      ],
    );
  }
}

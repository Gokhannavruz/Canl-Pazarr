import 'package:Freecycle/src/views/paywallfirstlaunch.dart';
import 'package:flutter/material.dart';
import 'package:purchases_flutter/models/offering_wrapper.dart';
import 'package:purchases_flutter/models/offerings_wrapper.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade700, Colors.blue.shade200],
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: PageView(
                  children: [
                    _WelcomePageItem(
                      icon: Icons.favorite_border,
                      title: 'Welcome to\nFreecycle',
                      description: 'Join our community where sharing is caring',
                      features: [
                        'Share items you no longer need',
                        'Find things you\'re looking for',
                        'Everything is completely free',
                        'Help reduce waste together'
                      ],
                    ),
                    _WelcomePageItem(
                      icon: Icons.upload_outlined,
                      title: 'Share Your Items',
                      description: 'Giving away is simple',
                      features: [
                        'Take a photo of your item',
                        'Write a brief description',
                        'Post it to the community',
                        'Choose who to give it to'
                      ],
                    ),
                    _WelcomePageItem(
                      icon: Icons.search,
                      title: 'Find What You Need',
                      description: 'Getting items is easy',
                      features: [
                        'Browse available items',
                        'Message the giver directly',
                        'Arrange pickup details',
                        'Get it for free!'
                      ],
                    ),
                    _WelcomePageItem(
                      icon: Icons.eco_outlined,
                      title: 'Make an Impact',
                      description: 'Together we can make a difference',
                      features: [
                        'Reduce waste in landfills',
                        'Help others in your community',
                        'Save money on new purchases',
                        'Create a sustainable future'
                      ],
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20.0, vertical: 30.0),
                child: Column(
                  children: [
                    ElevatedButton(
                      onPressed: () async {
                        try {
                          // SharedPreferences'i kaydet
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.setBool('isFirstLaunch', true);

                          // Offering'i al
                          final offering = await getOffering();

                          // Paywall'a yönlendir
                          if (context.mounted) {
                            // Context kontrolü
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(
                                builder: (_) =>
                                    PaywallFirstLaunch(offering: offering),
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text(
                                      'Failed to load offerings. Please try again.')),
                            );
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.blue.shade700,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 50, vertical: 15),
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                        elevation: 3,
                      ),
                      child: const Text(
                        'Get Started',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Offering'i almak için yardımcı method
  Future<Offering> getOffering() async {
    try {
      Offerings offerings = await Purchases.getOfferings();
      if (offerings.current != null) {
        return offerings.current!;
      } else {
        throw Exception('No offerings available');
      }
    } catch (e) {
      throw Exception('Failed to get offerings: $e');
    }
  }
}

class _WelcomePageItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final List<String> features;

  const _WelcomePageItem({
    required this.icon,
    required this.title,
    required this.description,
    required this.features,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 80,
            color: Colors.white,
          ),
          const SizedBox(height: 30),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 15),
          Text(
            description,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18,
              color: Colors.white70,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 40),
          ...features.map((feature) => _buildFeatureItem(feature)).toList(),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(String feature) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.check,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Text(
              feature,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

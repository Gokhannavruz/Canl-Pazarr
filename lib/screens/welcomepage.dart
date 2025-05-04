import 'package:freecycle/src/views/paywallfirstlaunch.dart';
import 'package:flutter/material.dart';
import 'package:purchases_flutter/models/offering_wrapper.dart';
import 'package:purchases_flutter/models/offerings_wrapper.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'dart:async';
import 'package:flutter/rendering.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({Key? key}) : super(key: key);

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage>
    with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  late AnimationController _animationController;
  int _currentPage = 0;
  bool _isLastPage = false;

  // Timer for countdown
  Timer? _countdownTimer;
  int _hoursRemaining = 0;
  int _minutesRemaining = 30;
  int _secondsRemaining = 0;

  final List<WelcomePageData> _pages = [
    WelcomePageData(
      title: 'Welcome to freecycle',
      subtitle: 'Join our community where sharing is caring',
      icon: Icons.people_alt_outlined,
      features: [
        'Share items you no longer need',
        'Find things you\'re looking for',
        'Everything is completely free',
        'Take photos and describe items easily'
      ],
      color: Colors.blue.shade700,
      isPremium: false,
      statistics: null,
    ),
    WelcomePageData(
      title: 'Find & Share Items',
      subtitle: 'Getting and giving items is easy and free',
      icon: Icons.search_outlined,
      features: [
        'Browse available items nearby',
        'Message givers directly',
        'Post your own items to share',
        'Choose who to give your items to'
      ],
      color: Colors.purple.shade700,
      isPremium: false,
      statistics: null,
    ),
    WelcomePageData(
      title: 'Unlock Premium Benefits',
      subtitle: 'Get more items with premium access',
      icon: Icons.diamond_outlined,
      features: [
        'Unlimited messages to all users',
        'Priority access to new items',
        'Higher success rates on requests',
        'Verified member badge'
      ],
      color: Color(0xFF1A237E),
      isPremium: true,
      statistics: [
        {'value': '5x', 'label': 'Faster'},
        {'value': '10x', 'label': 'Success'},
        {'value': '∞', 'label': 'Messages'},
      ],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _animationController.forward();

    // Set status bar to transparent
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );

    _pageController.addListener(() {
      int page = _pageController.page!.round();
      if (page != _currentPage) {
        setState(() {
          _currentPage = page;
          _isLastPage = _currentPage == _pages.length - 1;
        });
        if (_isLastPage) {
          _animationController.repeat(reverse: true);
          _startCountdownTimer();
        } else {
          _animationController.forward();
          _stopCountdownTimer();
        }
      }
    });
  }

  void _startCountdownTimer() {
    // Geri sayım sayacını kaldırıyoruz, sadece görsel olarak tutuyoruz
    _countdownTimer?.cancel();
  }

  void _stopCountdownTimer() {
    _countdownTimer?.cancel();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

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

  void _navigateToPaywall() async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
      );

      // Save first launch preference
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isFirstLaunch', true);

      // Get offering
      final offering = await getOffering();

      // Close loading dialog
      if (context.mounted) Navigator.pop(context);

      // Navigate to paywall
      if (context.mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => PaywallForFirstLaunch(offering: offering),
          ),
        );
      }
    } catch (e) {
      // Close loading dialog if open
      if (context.mounted) Navigator.pop(context);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load premium options. Please try again.'),
            backgroundColor: Colors.red.shade800,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Animated background
          AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            decoration: BoxDecoration(
              gradient: _pages[_currentPage].isPremium == true
                  ? LinearGradient(
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                      colors: [
                        Color(0xFF1A237E),
                        Color(0xFF0D47A1),
                        Colors.black,
                      ],
                      stops: [0.0, 0.5, 1.0],
                    )
                  : LinearGradient(
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                      colors: [
                        _pages[_currentPage].color,
                        _pages[_currentPage].color.withOpacity(0.7),
                        Colors.black,
                      ],
                    ),
            ),
          ),

          // Premium sayfası için arka plan parıltıları
          if (_isLastPage)
            Positioned.fill(
              child: CustomPaint(
                painter: GlitterPainter(),
              ),
            ),

          // Premium sayfası için ışık efekti
          if (_isLastPage)
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return Opacity(
                    opacity: 0.1 + (_animationController.value * 0.1),
                    child: CustomPaint(
                      painter: LightEffectPainter(
                        progress: _animationController.value,
                      ),
                    ),
                  );
                },
              ),
            ),

          // Content
          SafeArea(
            child: Column(
              children: [
                // Skip button
                Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: TextButton(
                      onPressed: _navigateToPaywall,
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: _isLastPage
                            ? Colors.transparent
                            : Colors.white.withOpacity(0.2),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: Text(
                        _isLastPage ? '' : 'Skip',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),

                // Page content
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: _pages.length,
                    itemBuilder: (context, index) {
                      return _buildPage(_pages[index]);
                    },
                  ),
                ),

                // Bottom navigation
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Page indicator
                      SmoothPageIndicator(
                        controller: _pageController,
                        count: _pages.length,
                        effect: ExpandingDotsEffect(
                          activeDotColor:
                              _isLastPage ? Color(0xFFD4AF37) : Colors.white,
                          dotColor: Colors.white.withOpacity(0.4),
                          dotHeight: 8,
                          dotWidth: 8,
                          expansionFactor: 4,
                        ),
                      ),

                      // Next/Get Started button
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: _isLastPage ? 200 : 60,
                        height: 60,
                        child: ElevatedButton(
                          onPressed: () {
                            if (_isLastPage) {
                              _navigateToPaywall();
                            } else {
                              _pageController.nextPage(
                                duration: const Duration(milliseconds: 500),
                                curve: Curves.easeInOut,
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                _isLastPage ? Color(0xFF00A651) : Colors.white,
                            foregroundColor: _pages[_currentPage].color,
                            padding: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            elevation: _isLastPage ? 8 : 5,
                          ),
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            child: _isLastPage
                                ? Row(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Flexible(
                                        child: Text(
                                          'View Premium',
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.poppins(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      AnimatedBuilder(
                                        animation: _animationController,
                                        builder: (context, child) {
                                          return Transform.scale(
                                            scale: 1.0 +
                                                (_animationController.value *
                                                    0.2),
                                            child: Icon(
                                              Icons.diamond,
                                              color: Colors.white,
                                              size: 20,
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  )
                                : Icon(
                                    Icons.arrow_forward,
                                    color: _pages[_currentPage].color,
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPage(WelcomePageData data) {
    if (!data.isPremium) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon
              Container(
                height: MediaQuery.of(context).size.height * 0.25,
                child: FractionallySizedBox(
                  widthFactor: 0.8,
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Center(
                      child: Icon(
                        data.icon,
                        size: 120,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // Title and subtitle
              Text(
                data.title,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                data.subtitle,
                style: GoogleFonts.poppins(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 16,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 40),

              // Features - Diğer sayfalarla tamamen aynı yapıda
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: data.features.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            _getFeatureIcon(index, data.title),
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            data.features[index],
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 15,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      );
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon
            Container(
              height: MediaQuery.of(context).size.height * 0.25,
              child: FractionallySizedBox(
                widthFactor: 0.8,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Center(
                    child: Icon(
                      data.icon,
                      size: 120,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 30),

            // Title and subtitle
            Text(
              data.title,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              data.subtitle,
              style: GoogleFonts.poppins(
                color: Colors.white.withOpacity(0.9),
                fontSize: 16,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 40),

            // Features - Diğer sayfalarla tamamen aynı yapıda
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: data.features.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          _getFeatureIcon(index, data.title),
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          data.features[index],
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 15,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  IconData _getFeatureIcon(int index, String pageTitle) {
    if (pageTitle == 'Welcome to freecycle') {
      List<IconData> icons = [
        Icons.card_giftcard,
        Icons.search,
        Icons.money_off,
        Icons.camera_alt_outlined,
      ];
      return icons[index % icons.length];
    } else if (pageTitle == 'Find & Share Items') {
      List<IconData> icons = [
        Icons.explore_outlined,
        Icons.message_outlined,
        Icons.upload_outlined,
        Icons.people_outline,
      ];
      return icons[index % icons.length];
    } else if (pageTitle.contains('Premium')) {
      List<IconData> icons = [
        Icons.speed,
        Icons.message,
        Icons.savings,
        Icons.verified_user,
      ];
      return icons[index % icons.length];
    }
    return Icons.check;
  }

  IconData _getPremiumFeatureIcon(int index) {
    final List<IconData> icons = [
      Icons.message_rounded,
      Icons.priority_high_rounded,
      Icons.verified_user_rounded,
      Icons.shield_rounded,
    ];

    return index < icons.length ? icons[index] : Icons.star_rounded;
  }

  // Kompakt özellik kartı widget'ı
  Widget _buildCompactFeatureCard(int index, String feature) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white.withOpacity(0.06),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Color(0xFFD4AF37).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _getPremiumFeatureIcon(index),
              color: Color(0xFFD4AF37),
              size: 18,
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              feature,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500,
                height: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Avantaj sütunları için yeni yardımcı metod
  Widget _buildAdvantageColumn(
      String leftHeader, String rightHeader, List<List<String>> comparisons) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Sol sütun (Free)
        Column(
          children: [
            Container(
              padding: EdgeInsets.symmetric(vertical: 6, horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                leftHeader,
                style: GoogleFonts.poppins(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            SizedBox(height: 8),
            ...comparisons.map((comparison) {
              return Container(
                margin: EdgeInsets.only(bottom: 6),
                child: Text(
                  comparison[0],
                  style: GoogleFonts.poppins(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 12,
                  ),
                ),
              );
            }).toList(),
          ],
        ),

        // Ayırıcı
        Container(
          margin: EdgeInsets.symmetric(horizontal: 12),
          height: 85,
          width: 1,
          color: Colors.white.withOpacity(0.2),
        ),

        // Sağ sütun (Premium)
        Column(
          children: [
            Container(
              padding: EdgeInsets.symmetric(vertical: 6, horizontal: 12),
              decoration: BoxDecoration(
                color: Color(0xFFD4AF37).withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                rightHeader,
                style: GoogleFonts.poppins(
                  color: Color(0xFFD4AF37),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(height: 8),
            ...comparisons.map((comparison) {
              return Container(
                margin: EdgeInsets.only(bottom: 6),
                child: Text(
                  comparison[1],
                  style: GoogleFonts.poppins(
                    color: Color(0xFFD4AF37),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            }).toList(),
          ],
        ),
      ],
    );
  }

  // Başlık ve açıklama içeren özellik kartı
  Widget _buildFeatureCardWithDescription(
      String title, String description, IconData icon) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white.withOpacity(0.06),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Color(0xFFD4AF37).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: Color(0xFFD4AF37),
              size: 18,
            ),
          ),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  description,
                  style: GoogleFonts.poppins(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 12,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // İstatistik sütunu oluşturan yardımcı metod
  Widget _buildStatColumn(String value, String label, IconData icon) {
    return Column(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Color(0xFFD4AF37).withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Icon(
              icon,
              color: Color(0xFFD4AF37),
              size: 24,
            ),
          ),
        ),
        SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFFD4AF37),
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: Colors.white.withOpacity(0.8),
          ),
        ),
      ],
    );
  }
}

class WelcomePageData {
  final String title;
  final String subtitle;
  final IconData icon;
  final List<String> features;
  final Color color;
  final bool isPremium;
  final List<Map<String, String>>? statistics;

  WelcomePageData({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.features,
    required this.color,
    required this.isPremium,
    this.statistics,
  });
}

// Premium sayfası için parıltı efekti
class GlitterPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Color(0xFFD4AF37).withOpacity(0.2)
      ..style = PaintingStyle.fill;

    // Rastgele parıltı noktaları
    final random = DateTime.now().millisecondsSinceEpoch;
    for (int i = 0; i < 50; i++) {
      final x = (random * (i + 1) % size.width.toInt()).toDouble();
      final y = (random * (i + 2) % size.height.toInt()).toDouble();
      final radius = (random * (i + 3) % 4).toDouble() + 1;

      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Premium sayfası için ışık efekti
class LightEffectPainter extends CustomPainter {
  final double progress;

  LightEffectPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.5, size.height * 0.3);
    final radius = size.width * (0.3 + progress * 0.2);

    final gradient = RadialGradient(
      colors: [
        Color(0xFFD4AF37).withOpacity(0.3),
        Color(0xFFD4AF37).withOpacity(0.1),
        Colors.transparent,
      ],
      stops: [0.0, 0.5, 1.0],
    );

    final rect = Rect.fromCircle(center: center, radius: radius);
    final paint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(covariant LightEffectPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

// Minimalist parıltı efekti için yeni bir CustomPainter ekle
class MinimalistGlitterPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..style = PaintingStyle.fill;

    // Birkaç sade parıltı elemanı
    canvas.drawCircle(
      Offset(size.width * 0.2, size.height * 0.2),
      size.width * 0.1,
      paint,
    );

    canvas.drawCircle(
      Offset(size.width * 0.8, size.height * 0.3),
      size.width * 0.08,
      paint,
    );

    canvas.drawCircle(
      Offset(size.width * 0.6, size.height * 0.6),
      size.width * 0.15,
      paint,
    );

    canvas.drawCircle(
      Offset(size.width * 0.3, size.height * 0.75),
      size.width * 0.06,
      paint,
    );

    // Daha küçük vurgular
    final accentPaint = Paint()
      ..color = Color(0xFFD4AF37).withOpacity(0.03)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(size.width * 0.5, size.height * 0.4),
      size.width * 0.04,
      accentPaint,
    );

    canvas.drawCircle(
      Offset(size.width * 0.7, size.height * 0.7),
      size.width * 0.05,
      accentPaint,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

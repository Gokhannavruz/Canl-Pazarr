import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:animal_trade/resources/auth_methods.dart';
import 'package:animal_trade/resources/firestore_methods.dart';
import 'package:animal_trade/screens/bio_and_profil.dart';

import 'package:animal_trade/screens/following_Page.dart';
import 'package:animal_trade/screens/login_screen.dart';
import 'package:animal_trade/screens/settings.dart';
import 'package:animal_trade/screens/add_animal_screen.dart';
import 'package:animal_trade/screens/animal_detail_screen.dart';
import 'package:animal_trade/models/animal_post.dart';
import 'package:animal_trade/utils/utils.dart';
import '../widgets/follow_button.dart';
import 'followers_list_page.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animal_trade/screens/transporter_profile_screen.dart';
import 'package:animal_trade/screens/transporter_detail_screen.dart';
import 'package:animal_trade/screens/veterinarian_profile_screen.dart';
import 'package:animal_trade/screens/veterinarian_detail_screen.dart';
import 'package:intl/intl.dart';

class ProfileScreen2 extends StatefulWidget {
  final String uid;
  const ProfileScreen2(
      {Key? key, required this.uid, required snap, required userId})
      : super(key: key);

  @override
  ProfileScreen2State createState() => ProfileScreen2State();
}

class ProfileScreen2State extends State<ProfileScreen2>
    with SingleTickerProviderStateMixin {
  final user = FirebaseAuth.instance.currentUser!;
  late bool _isGridView = false;
  final PageController _pageController = PageController(initialPage: 0);
  late TabController _tabController;

  var userData = {};
  int animalCount = 0;
  int followers = 0;
  int following = 0;
  bool isFollowing = false;
  bool isLoading = false;
  bool isBlocked = false;
  int totalSales = 0;
  double averageRating = 4.8;
  int experienceYears = 5;
  String farmerType = 'Çiftçi';
  String farmLocation = 'Ankara, Çankaya';

  // Classic color palette
  static const Color primaryColor = Color(0xFF2E7D32);
  static const Color accentColor = Color(0xFF4CAF50);
  static const Color warningColor = Color(0xFFFF9800);
  static const Color errorColor = Color(0xFFE53935);
  static const Color successColor = Color(0xFF4CAF50);
  static const Color infoColor = Color(0xFF2196F3);
  static const Color backgroundColor = Colors.white;
  static const Color surfaceColor = Color(0xFFFAFAFA);
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color dividerColor = Color(0xFFE0E0E0);

  // Add state variable to control expansion
  bool _isTransporterCardExpanded = false;
  bool _isVeterinarianCardExpanded = false;

  @override
  void initState() {
    super.initState();
    getData();
    _tabController = TabController(
      length: 2,
      vsync: this,
      animationDuration: const Duration(milliseconds: 200),
      initialIndex: 0, // Varsayılan olarak liste görünümü ve sekmesi seçili
    );
    _isGridView = false; // Liste görünümü default
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  getData() async {
    setState(() {
      isLoading = true;
    });
    try {
      var userSnap = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.uid)
          .get();

      if (!userSnap.exists) {
        throw 'User data not found';
      }

      var animalSnap = await FirebaseFirestore.instance
          .collection('animals')
          .where('uid', isEqualTo: widget.uid)
          .get();

      animalCount = animalSnap.docs.length;
      userData = userSnap.data()!;

      followers = userData['followers']?.length ?? 0;
      following = userData['following']?.length ?? 0;

      // Rating ve satış bilgilerini veritabanından çek
      averageRating = (userData['averageRating'] as double?) ?? 0.0;
      totalSales = (userData['totalSales'] as int?) ?? 0;

      isBlocked = (userData['blocked'] != null &&
              userData['blocked']
                  .contains(FirebaseAuth.instance.currentUser!.uid)) ||
          (userData['blockedBy'] != null &&
              userData['blockedBy']
                  .contains(FirebaseAuth.instance.currentUser!.uid));

      isFollowing = userData['followers']
              ?.contains(FirebaseAuth.instance.currentUser!.uid) ??
          false;

      // Get additional farmer data
      experienceYears = userData['experienceYears'] ?? 0;
      farmerType = userData['farmerType'] ?? 'Belirtilmemiş';

      // Çiftlik adresini oluştur
      String location = '';
      if (userData['farmAddress'] != null &&
          userData['farmAddress'].toString().isNotEmpty) {
        location = userData['farmAddress'];
      } else if (userData['city'] != null &&
          userData['city'].toString().isNotEmpty) {
        String cityStr = userData['city'];
        String stateStr = userData['state'] ?? '';

        // Eğer şehir ve il aynıysa sadece şehri göster
        if (stateStr.isNotEmpty && cityStr != stateStr) {
          location = '$cityStr, $stateStr';
        } else {
          location = cityStr;
        }
      } else {
        location = 'Belirtilmemiş';
      }
      farmLocation = location;

      setState(() {});
    } catch (e) {
      if (mounted) {
        showSnackBar(context, 'Profil bilgileri yüklenemedi');
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const LoginScreen(),
          ),
        );
      }
    }

    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;
    return isLoading
        ? const Scaffold(
            backgroundColor: backgroundColor,
            body: Center(
              child: CircularProgressIndicator(
                color: primaryColor,
              ),
            ),
          )
        : Scaffold(
            backgroundColor: backgroundColor,
            appBar: AppBar(
              elevation: 0,
              automaticallyImplyLeading: false,
              backgroundColor: backgroundColor,
              leading: widget.uid != currentUserId
                  ? IconButton(
                      icon: const Icon(
                        Icons.arrow_back_ios_new,
                        color: textPrimary,
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    )
                  : IconButton(
                      icon: const Icon(
                        Icons.edit_outlined,
                        color: textPrimary,
                        size: 24,
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EditProfileScreen(
                              userId: currentUserId,
                            ),
                          ),
                        );
                      },
                    ),
              titleSpacing: 0,
              centerTitle: true,
              title: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(widget.uid)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData || !snapshot.data!.exists) {
                    return const SizedBox();
                  }

                  final data = snapshot.data!.data()!;
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          data['username'],
                          style: GoogleFonts.poppins(
                            color: textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (data['is_premium'] == true)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.verified,
                            size: 16,
                            color: primaryColor,
                          ),
                        ),
                    ],
                  );
                },
              ),
              actions: [
                widget.uid == currentUserId
                    ? IconButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const SettingsPage(),
                            ),
                          );
                        },
                        icon: const Icon(
                          Icons.settings_outlined,
                          color: textPrimary,
                          size: 24,
                        ),
                      )
                    : PopupMenuButton<String>(
                        color: backgroundColor,
                        icon: const Icon(
                          Icons.more_vert,
                          color: textPrimary,
                        ),
                        onSelected: (value) async {
                          if (value == 'block') {
                            final BuildContext outerContext = context;

                            final shouldBlock = await showDialog<bool>(
                                  context: context,
                                  builder: (dialogContext) => AlertDialog(
                                    backgroundColor: backgroundColor,
                                    title: Text(
                                      'Kullanıcıyı Engelle',
                                      style: GoogleFonts.poppins(
                                        color: textPrimary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    content: Text(
                                      'Bu kullanıcıyı engellemek istediğinizden emin misiniz? Bu kullanıcının ilanlarını artık göremeyeceksiniz.',
                                      style: GoogleFonts.poppins(
                                        color: textSecondary,
                                      ),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(dialogContext, false),
                                        child: Text(
                                          'İptal',
                                          style: GoogleFonts.poppins(
                                            color: textSecondary,
                                          ),
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(dialogContext, true),
                                        child: Text(
                                          'Engelle',
                                          style: GoogleFonts.poppins(
                                            color: errorColor,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ) ??
                                false;

                            if (shouldBlock) {
                              Navigator.of(outerContext).pop();

                              FireStoreMethods()
                                  .blockUser(
                                FirebaseAuth.instance.currentUser!.uid,
                                userData['uid'],
                              )
                                  .catchError((e) {
                                print("Error blocking user: $e");
                              });
                            }
                          } else if (value == 'report') {
                            final BuildContext outerContext = context;

                            final shouldReport = await showDialog<bool>(
                                  context: context,
                                  builder: (dialogContext) => AlertDialog(
                                    backgroundColor: backgroundColor,
                                    title: Text(
                                      'Kullanıcıyı Şikayet Et',
                                      style: GoogleFonts.poppins(
                                        color: textPrimary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    content: Text(
                                      'Bu kullanıcıyı şikayet etmek istediğinizden emin misiniz? Ekibimiz bu hesabı inceleyecek.',
                                      style: GoogleFonts.poppins(
                                        color: textSecondary,
                                      ),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(dialogContext, false),
                                        child: Text(
                                          'İptal',
                                          style: GoogleFonts.poppins(
                                            color: textSecondary,
                                          ),
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(dialogContext, true),
                                        child: Text(
                                          'Şikayet Et',
                                          style: GoogleFonts.poppins(
                                            color: warningColor,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ) ??
                                false;

                            if (shouldReport) {
                              if (mounted) {
                                ScaffoldMessenger.of(outerContext).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Kullanıcı başarıyla şikayet edildi',
                                      style: GoogleFonts.poppins(
                                        color: backgroundColor,
                                      ),
                                    ),
                                    backgroundColor: warningColor,
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              }

                              FireStoreMethods()
                                  .reportUser(
                                FirebaseAuth.instance.currentUser!.uid,
                                userData['uid'],
                              )
                                  .catchError((e) {
                                print("Error reporting user: $e");
                              });
                            }
                          }
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem<String>(
                            value: 'block',
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.block,
                                  color: errorColor,
                                  size: 20,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  'Kullanıcıyı Engelle',
                                  style: GoogleFonts.poppins(
                                    color: textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          PopupMenuItem<String>(
                            value: 'report',
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.report_problem,
                                  color: warningColor,
                                  size: 20,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  'Şikayet Et',
                                  style: GoogleFonts.poppins(
                                    color: textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
              ],
            ),
            body: Stack(
              children: [
                RefreshIndicator(
                  color: primaryColor,
                  onRefresh: _refresh,
                  child: CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(
                        child: Column(
                          children: [
                            const SizedBox(height: 20),
                            // Profile Image
                            StreamBuilder<
                                DocumentSnapshot<Map<String, dynamic>>>(
                              stream: FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(widget.uid)
                                  .snapshots(),
                              builder: (context, snapshot) {
                                if (snapshot.hasData) {
                                  return Container(
                                    width: 100,
                                    height: 100,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: dividerColor,
                                        width: 2,
                                      ),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(50),
                                      child: Image.network(
                                        snapshot.data!['photoUrl'],
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  );
                                }
                                return const SizedBox();
                              },
                            ),
                            const SizedBox(height: 20),

                            // Stats Row
                            Container(
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 24),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 16),
                              decoration: BoxDecoration(
                                color: backgroundColor,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: dividerColor,
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  _buildStatItem(animalCount, "İlan"),
                                  Container(
                                    height: 30,
                                    width: 1,
                                    color: dividerColor,
                                  ),
                                  _buildStatItem(totalSales, "Satış"),
                                  Container(
                                    height: 30,
                                    width: 1,
                                    color: dividerColor,
                                  ),
                                  _buildStatItem(
                                      averageRating > 0
                                          ? averageRating.toStringAsFixed(1)
                                          : '-',
                                      "Puan"),
                                ],
                              ),
                            ),

                            const SizedBox(height: 20),

                            // Farmer Info Card
                            Container(
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: backgroundColor,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: dividerColor,
                                  width: 1,
                                ),
                              ),
                              child: StreamBuilder<
                                  DocumentSnapshot<Map<String, dynamic>>>(
                                stream: FirebaseFirestore.instance
                                    .collection('users')
                                    .doc(widget.uid)
                                    .snapshots(),
                                builder: (context, snapshot) {
                                  if (!snapshot.hasData ||
                                      !snapshot.data!.exists) {
                                    return const SizedBox();
                                  }

                                  final data = snapshot.data!.data() ?? {};
                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Title
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.agriculture,
                                            color: primaryColor,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Çiftçi Bilgileri',
                                            style: GoogleFonts.poppins(
                                              color: textPrimary,
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 16),

                                      // Farmer Type & Experience
                                      Row(
                                        children: [
                                          Expanded(
                                            child: _buildInfoItem(
                                              'Çiftçi Tipi',
                                              farmerType,
                                              Icons.person,
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: _buildInfoItem(
                                              'Deneyim',
                                              experienceYears > 0
                                                  ? '$experienceYears Yıl'
                                                  : 'Belirtilmemiş',
                                              Icons.timeline,
                                            ),
                                          ),
                                        ],
                                      ),

                                      const SizedBox(height: 16),

                                      // Çiftlik Büyüklüğü
                                      StreamBuilder<
                                          DocumentSnapshot<
                                              Map<String, dynamic>>>(
                                        stream: FirebaseFirestore.instance
                                            .collection('users')
                                            .doc(widget.uid)
                                            .snapshots(),
                                        builder: (context, snapshot) {
                                          if (!snapshot.hasData ||
                                              !snapshot.data!.exists) {
                                            return const SizedBox();
                                          }

                                          final userData =
                                              snapshot.data!.data() ?? {};
                                          final farmSize =
                                              userData['farmSize'] ?? '';

                                          if (farmSize.isEmpty)
                                            return const SizedBox();

                                          return Column(
                                            children: [
                                              _buildInfoItem(
                                                'Çiftlik Büyüklüğü',
                                                farmSize,
                                                Icons.agriculture,
                                              ),
                                              const SizedBox(height: 16),
                                            ],
                                          );
                                        },
                                      ),

                                      // Bio/Description
                                      if (data['bio'] != null &&
                                          data['bio']
                                              .toString()
                                              .isNotEmpty) ...[
                                        Text(
                                          'Hakkında',
                                          style: GoogleFonts.poppins(
                                            color: textPrimary,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          data['bio'],
                                          style: GoogleFonts.poppins(
                                            color: textSecondary,
                                            fontSize: 14,
                                            height: 1.4,
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                      ],

                                      // Certifications
                                      if (data['certifications'] != null &&
                                          (data['certifications'] as List)
                                              .isNotEmpty) ...[
                                        Text(
                                          'Sertifikalar',
                                          style: GoogleFonts.poppins(
                                            color: textPrimary,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Wrap(
                                          spacing: 8,
                                          runSpacing: 6,
                                          children: (data['certifications']
                                                  as List)
                                              .map((certification) => Container(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 12,
                                                        vertical: 6),
                                                    decoration: BoxDecoration(
                                                      color: successColor
                                                          .withOpacity(0.1),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              16),
                                                      border: Border.all(
                                                        color: successColor
                                                            .withOpacity(0.3),
                                                      ),
                                                    ),
                                                    child: Row(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        const Icon(
                                                          Icons.verified,
                                                          size: 14,
                                                          color: successColor,
                                                        ),
                                                        const SizedBox(
                                                            width: 4),
                                                        Text(
                                                          certification
                                                              .toString(),
                                                          style: GoogleFonts
                                                              .poppins(
                                                            color: successColor,
                                                            fontSize: 12,
                                                            fontWeight:
                                                                FontWeight.w500,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ))
                                              .toList(),
                                        ),
                                        const SizedBox(height: 16),
                                      ],

                                      // Farmer Features
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        children: [
                                          if (data['hasHealthCertificate'] ==
                                              true)
                                            _buildFeatureChip(
                                                'Sağlık Belgeli',
                                                Icons.health_and_safety,
                                                successColor),
                                          if (data['transportAvailable'] ==
                                              'Mevcut')
                                            _buildFeatureChip(
                                                'Nakliye Mevcut',
                                                Icons.local_shipping,
                                                infoColor),
                                          if (data['hasVeterinarySupport'] ==
                                              true)
                                            _buildFeatureChip(
                                                'Veteriner Desteği',
                                                Icons.medical_services,
                                                primaryColor),
                                        ],
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ),

                            const SizedBox(height: 16),

                            // Nakliyeci Bilgileri Card - Only show if user has transporter data
                            StreamBuilder<
                                DocumentSnapshot<Map<String, dynamic>>>(
                              stream: FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(widget.uid)
                                  .snapshots(),
                              builder: (context, snapshot) {
                                if (!snapshot.hasData ||
                                    !snapshot.data!.exists) {
                                  return const SizedBox();
                                }

                                final data = snapshot.data!.data() ?? {};

                                // Check if user has any transporter data
                                final hasTransporterData = (data[
                                                'transporterCompanyName'] !=
                                            null &&
                                        data['transporterCompanyName']
                                            .toString()
                                            .isNotEmpty) ||
                                    (data['transporterVehicleType'] != null &&
                                        data['transporterVehicleType']
                                            .toString()
                                            .isNotEmpty) ||
                                    (data['transporterMaxAnimals'] != null) ||
                                    (data['transporterMinPrice'] != null &&
                                        data['transporterMaxPrice'] != null) ||
                                    (data['transporterPricePerKm'] != null) ||
                                    (data['transporterMaxDistanceKm'] !=
                                        null) ||
                                    (data['transporterDescription'] != null &&
                                        data['transporterDescription']
                                            .toString()
                                            .isNotEmpty) ||
                                    (_getTransporterCities(
                                            data['transporterCities'])
                                        .isNotEmpty);

                                if (!hasTransporterData) {
                                  return const SizedBox();
                                }

                                return Container(
                                  margin: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 10),
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: backgroundColor,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                        color: dividerColor, width: 1),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(Icons.local_shipping,
                                              color: primaryColor, size: 20),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text('Nakliyeci Bilgileri',
                                                style: GoogleFonts.poppins(
                                                  color: textPrimary,
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600,
                                                )),
                                          ),
                                          IconButton(
                                            icon: Icon(
                                                _isTransporterCardExpanded
                                                    ? Icons.keyboard_arrow_up
                                                    : Icons.keyboard_arrow_down,
                                                color: textSecondary),
                                            onPressed: () {
                                              setState(() {
                                                _isTransporterCardExpanded =
                                                    !_isTransporterCardExpanded;
                                              });
                                            },
                                          ),
                                        ],
                                      ),
                                      if (_isTransporterCardExpanded) ...[
                                        const SizedBox(height: 12),
                                        // Show serviced cities as chips with heading at the top
                                        if (_getTransporterCities(
                                                data['transporterCities'])
                                            .isNotEmpty) ...[
                                          Padding(
                                            padding: const EdgeInsets.only(
                                                bottom: 12),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Icon(Icons.location_city,
                                                        color: primaryColor,
                                                        size: 18),
                                                    const SizedBox(width: 6),
                                                    Text(
                                                      'Hizmet Verilen Şehirler',
                                                      style:
                                                          GoogleFonts.poppins(
                                                        color: textSecondary,
                                                        fontSize: 13,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 6),
                                                Wrap(
                                                  spacing: 8,
                                                  runSpacing: 8,
                                                  children:
                                                      _getTransporterCities(data[
                                                              'transporterCities'])
                                                          .map<Widget>((city) =>
                                                              Chip(
                                                                label:
                                                                    Text(city),
                                                                backgroundColor:
                                                                    surfaceColor,
                                                              ))
                                                          .toList(),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                        if (data['transporterCompanyName'] !=
                                                null &&
                                            data['transporterCompanyName']
                                                .toString()
                                                .isNotEmpty)
                                          _buildInfoItem(
                                              'Firma',
                                              data['transporterCompanyName'],
                                              Icons.business),
                                        if (data['transporterVehicleType'] !=
                                                null &&
                                            data['transporterVehicleType']
                                                .toString()
                                                .isNotEmpty)
                                          _buildInfoItem(
                                              'Araç Tipi',
                                              data['transporterVehicleType'],
                                              Icons.directions_car),
                                        if (data['transporterMaxAnimals'] !=
                                            null)
                                          _buildInfoItem(
                                              'Kapasite',
                                              data['transporterMaxAnimals']
                                                  .toString(),
                                              Icons.pets),
                                        if (data['transporterMinPrice'] !=
                                                null &&
                                            data['transporterMaxPrice'] != null)
                                          _buildInfoItem(
                                              'Fiyat Aralığı',
                                              '${_formatPrice(data['transporterMinPrice'])} - ${_formatPrice(data['transporterMaxPrice'])}',
                                              Icons.attach_money),
                                        if (data['transporterPricePerKm'] !=
                                            null)
                                          _buildInfoItem(
                                              'Km Başı Ücret',
                                              _formatPrice(data[
                                                  'transporterPricePerKm']),
                                              Icons.straighten),
                                        if (data['transporterMaxDistanceKm'] !=
                                            null)
                                          _buildInfoItem(
                                              'Maks. Mesafe',
                                              _formatKm(data[
                                                  'transporterMaxDistanceKm']),
                                              Icons.route),
                                        if (data['transporterInsurance'] ==
                                            true)
                                          _buildInfoItem('Sigorta', 'Var',
                                              Icons.verified_user),
                                        if (data['transporterDescription'] !=
                                                null &&
                                            data['transporterDescription']
                                                .toString()
                                                .isNotEmpty)
                                          _buildInfoItem(
                                              'Açıklama',
                                              data['transporterDescription'],
                                              Icons.info_outline),
                                        const SizedBox(height: 12),
                                        SizedBox(
                                          width: double.infinity,
                                          child: ElevatedButton.icon(
                                            icon:
                                                const Icon(Icons.info_outline),
                                            label: const Text('Detaylı Bilgi'),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: primaryColor,
                                              foregroundColor: backgroundColor,
                                              shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          12)),
                                              elevation: 0,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 14),
                                            ),
                                            onPressed: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      TransporterDetailScreen(
                                                    transporterData: data.cast<
                                                        String, dynamic>(),
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                        // Show edit button if current user is viewing their own profile
                                        if (FirebaseAuth
                                                .instance.currentUser?.uid ==
                                            widget.uid) ...[
                                          const SizedBox(height: 8),
                                          SizedBox(
                                            width: double.infinity,
                                            child: OutlinedButton.icon(
                                              icon: const Icon(Icons.edit,
                                                  size: 20),
                                              label: const Text(
                                                  'Nakliye Bilgilerini Düzenle'),
                                              style: OutlinedButton.styleFrom(
                                                foregroundColor: primaryColor,
                                                side: BorderSide(
                                                    color: primaryColor,
                                                    width: 1.5),
                                                shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            12)),
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        vertical: 14),
                                              ),
                                              onPressed: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) =>
                                                        TransporterProfileScreen(
                                                      userId: widget.uid,
                                                      existingTransporterData:
                                                          data.cast<String,
                                                              dynamic>(),
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                        ],
                                      ],
                                    ],
                                  ),
                                );
                              },
                            ),

                            const SizedBox(height: 16),

                            // Veteriner Bilgileri Card - Only show if user has veterinarian data
                            StreamBuilder<
                                DocumentSnapshot<Map<String, dynamic>>>(
                              stream: FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(widget.uid)
                                  .snapshots(),
                              builder: (context, snapshot) {
                                if (!snapshot.hasData ||
                                    !snapshot.data!.exists) {
                                  return const SizedBox();
                                }

                                final data = snapshot.data!.data() ?? {};

                                // Check if user has any veterinarian data
                                final hasVeterinarianData =
                                    (data['veterinarianClinicName'] != null &&
                                            data['veterinarianClinicName']
                                                .toString()
                                                .isNotEmpty) ||
                                        (data['veterinarianPhone'] != null &&
                                            data['veterinarianPhone']
                                                .toString()
                                                .isNotEmpty) ||
                                        (data['veterinarianConsultationFee'] !=
                                            null) ||
                                        (data['veterinarianEmergencyFee'] !=
                                            null) ||
                                        (data['veterinarianDescription'] !=
                                                null &&
                                            data['veterinarianDescription']
                                                .toString()
                                                .isNotEmpty) ||
                                        (_getVeterinarianCities(
                                                data['veterinarianCities'])
                                            .isNotEmpty);

                                if (!hasVeterinarianData) {
                                  return const SizedBox();
                                }

                                return Container(
                                  margin: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 10),
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: backgroundColor,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                        color: dividerColor, width: 1),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(Icons.local_hospital,
                                              color: primaryColor, size: 20),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text('Veteriner Bilgileri',
                                                style: GoogleFonts.poppins(
                                                  color: textPrimary,
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600,
                                                )),
                                          ),
                                          IconButton(
                                            icon: Icon(
                                                _isVeterinarianCardExpanded
                                                    ? Icons.keyboard_arrow_up
                                                    : Icons.keyboard_arrow_down,
                                                color: textSecondary),
                                            onPressed: () {
                                              setState(() {
                                                _isVeterinarianCardExpanded =
                                                    !_isVeterinarianCardExpanded;
                                              });
                                            },
                                          ),
                                        ],
                                      ),
                                      if (_isVeterinarianCardExpanded) ...[
                                        const SizedBox(height: 12),
                                        // Show serviced cities as chips with heading at the top
                                        if (_getVeterinarianCities(
                                                data['veterinarianCities'])
                                            .isNotEmpty) ...[
                                          Padding(
                                            padding: const EdgeInsets.only(
                                                bottom: 12),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Icon(Icons.location_city,
                                                        color: primaryColor,
                                                        size: 18),
                                                    const SizedBox(width: 6),
                                                    Text(
                                                      'Hizmet Verilen Şehirler',
                                                      style:
                                                          GoogleFonts.poppins(
                                                        color: textSecondary,
                                                        fontSize: 13,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 6),
                                                Wrap(
                                                  spacing: 8,
                                                  runSpacing: 8,
                                                  children:
                                                      _getVeterinarianCities(data[
                                                              'veterinarianCities'])
                                                          .map<Widget>((city) =>
                                                              Chip(
                                                                label:
                                                                    Text(city),
                                                                backgroundColor:
                                                                    surfaceColor,
                                                              ))
                                                          .toList(),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                        if (data['veterinarianClinicName'] !=
                                                null &&
                                            data['veterinarianClinicName']
                                                .toString()
                                                .isNotEmpty)
                                          _buildInfoItem(
                                              'Klinik',
                                              data['veterinarianClinicName'],
                                              Icons.local_hospital),
                                        if (data['veterinarianPhone'] != null &&
                                            data['veterinarianPhone']
                                                .toString()
                                                .isNotEmpty)
                                          _buildInfoItem(
                                              'Telefon',
                                              data['veterinarianPhone'],
                                              Icons.phone),
                                        if (data[
                                                'veterinarianConsultationFee'] !=
                                            null)
                                          _buildInfoItem(
                                              'Muayene Ücreti',
                                              _formatPrice(data[
                                                  'veterinarianConsultationFee']),
                                              Icons.attach_money),
                                        if (data['veterinarianEmergencyFee'] !=
                                            null)
                                          _buildInfoItem(
                                              'Acil Ücret',
                                              _formatPrice(data[
                                                  'veterinarianEmergencyFee']),
                                              Icons.attach_money),
                                        if (data['veterinarianHomeVisit'] ==
                                            true)
                                          _buildInfoItem(
                                              'Ev Ziyareti', 'Var', Icons.home),
                                        if (data[
                                                'veterinarianEmergencyService'] ==
                                            true)
                                          _buildInfoItem('Acil Hizmet', 'Var',
                                              Icons.emergency),
                                        if (data['veterinarianDescription'] !=
                                                null &&
                                            data['veterinarianDescription']
                                                .toString()
                                                .isNotEmpty)
                                          _buildInfoItem(
                                              'Açıklama',
                                              data['veterinarianDescription'],
                                              Icons.info_outline),
                                        const SizedBox(height: 12),
                                        SizedBox(
                                          width: double.infinity,
                                          child: ElevatedButton.icon(
                                            icon:
                                                const Icon(Icons.info_outline),
                                            label: const Text('Detaylı Bilgi'),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: primaryColor,
                                              foregroundColor: backgroundColor,
                                              shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          12)),
                                              elevation: 0,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 14),
                                            ),
                                            onPressed: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      VeterinarianDetailScreen(
                                                    veterinarianId: widget.uid,
                                                    veterinarianData: data.cast<
                                                        String, dynamic>(),
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                        // Show edit button if current user is viewing their own profile
                                        if (FirebaseAuth
                                                .instance.currentUser?.uid ==
                                            widget.uid) ...[
                                          const SizedBox(height: 8),
                                          SizedBox(
                                            width: double.infinity,
                                            child: OutlinedButton.icon(
                                              icon: const Icon(Icons.edit,
                                                  size: 20),
                                              label: const Text(
                                                  'Veteriner Bilgilerini Düzenle'),
                                              style: OutlinedButton.styleFrom(
                                                foregroundColor: primaryColor,
                                                side: BorderSide(
                                                    color: primaryColor,
                                                    width: 1.5),
                                                shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            12)),
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        vertical: 14),
                                              ),
                                              onPressed: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) =>
                                                        VeterinarianProfileScreen(
                                                      userId: widget.uid,
                                                      existingVeterinarianData:
                                                          data.cast<String,
                                                              dynamic>(),
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                        ],
                                      ],
                                    ],
                                  ),
                                );
                              },
                            ),

                            const SizedBox(height: 16),

                            // Performance Stats Card
                            Container(
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: backgroundColor,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: dividerColor,
                                  width: 1,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Title
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.star,
                                        color: warningColor,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Satış Performansı',
                                        style: GoogleFonts.poppins(
                                          color: textPrimary,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),

                                  // Performance Stats
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _buildRatingCard(),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: _buildPerformanceCard(
                                          totalSales > 0
                                              ? totalSales.toString()
                                              : '0',
                                          'Toplam Satış',
                                          Icons.shopping_cart,
                                          primaryColor,
                                          subtitle: totalSales > 0
                                              ? 'Başarılı satış'
                                              : 'Henüz satış yapmadı',
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 16),

                            // Location & Contact Card
                            Container(
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: backgroundColor,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: dividerColor,
                                  width: 1,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Title
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.location_on,
                                        color: primaryColor,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Konum & İletişim',
                                        style: GoogleFonts.poppins(
                                          color: textPrimary,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),

                                  // Contact Info
                                  _buildContactInfo(Icons.location_on, 'Konum',
                                      farmLocation, primaryColor),
                                  const SizedBox(height: 12),
                                  StreamBuilder<
                                      DocumentSnapshot<Map<String, dynamic>>>(
                                    stream: FirebaseFirestore.instance
                                        .collection('users')
                                        .doc(widget.uid)
                                        .snapshots(),
                                    builder: (context, snapshot) {
                                      if (!snapshot.hasData ||
                                          !snapshot.data!.exists) {
                                        return _buildContactInfo(
                                            Icons.phone,
                                            'Telefon',
                                            'Belirtilmemiş',
                                            infoColor);
                                      }

                                      final userData =
                                          snapshot.data!.data() ?? {};
                                      final phoneNumber =
                                          userData['phoneNumber'] ?? '';

                                      return _buildContactInfo(
                                          Icons.phone,
                                          'Telefon',
                                          phoneNumber.isEmpty
                                              ? 'Belirtilmemiş'
                                              : phoneNumber,
                                          infoColor);
                                    },
                                  ),
                                  const SizedBox(height: 12),
                                  StreamBuilder<
                                      DocumentSnapshot<Map<String, dynamic>>>(
                                    stream: FirebaseFirestore.instance
                                        .collection('users')
                                        .doc(widget.uid)
                                        .snapshots(),
                                    builder: (context, snapshot) {
                                      if (!snapshot.hasData ||
                                          !snapshot.data!.exists) {
                                        return _buildContactInfo(
                                            Icons.access_time,
                                            'Çalışma Saatleri',
                                            'Belirtilmemiş',
                                            textSecondary);
                                      }

                                      final userData =
                                          snapshot.data!.data() ?? {};
                                      final workingHours =
                                          userData['workingHours'] ?? '';

                                      return _buildContactInfo(
                                          Icons.access_time,
                                          'Çalışma Saatleri',
                                          workingHours.isEmpty
                                              ? 'Belirtilmemiş'
                                              : workingHours,
                                          textSecondary);
                                    },
                                  ),
                                  const SizedBox(height: 12),
                                  StreamBuilder<
                                      DocumentSnapshot<Map<String, dynamic>>>(
                                    stream: FirebaseFirestore.instance
                                        .collection('users')
                                        .doc(widget.uid)
                                        .snapshots(),
                                    builder: (context, snapshot) {
                                      if (!snapshot.hasData ||
                                          !snapshot.data!.exists) {
                                        return _buildContactInfo(
                                            Icons.local_shipping,
                                            'Nakliye Durumu',
                                            'Belirtilmemiş',
                                            infoColor);
                                      }

                                      final userData =
                                          snapshot.data!.data() ?? {};
                                      final transportAvailable =
                                          userData['transportAvailable'] ?? '';

                                      return _buildContactInfo(
                                          Icons.local_shipping,
                                          'Nakliye Durumu',
                                          transportAvailable.isEmpty
                                              ? 'Belirtilmemiş'
                                              : transportAvailable,
                                          infoColor);
                                    },
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 16),

                            // Animal Specialization Card
                            StreamBuilder<
                                DocumentSnapshot<Map<String, dynamic>>>(
                              stream: FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(widget.uid)
                                  .snapshots(),
                              builder: (context, snapshot) {
                                if (!snapshot.hasData ||
                                    !snapshot.data!.exists) {
                                  return const SizedBox();
                                }

                                final userData = snapshot.data!.data() ?? {};
                                final animalCounts = userData['animalCounts']
                                    as Map<String, dynamic>?;

                                if (animalCounts == null ||
                                    animalCounts.isEmpty) {
                                  return const SizedBox();
                                }

                                // Sadece 0'dan büyük değerleri filtrele
                                final validAnimals = animalCounts.entries
                                    .where((entry) => (entry.value as num) > 0)
                                    .toList();

                                if (validAnimals.isEmpty) {
                                  return const SizedBox();
                                }

                                return Container(
                                  margin: const EdgeInsets.symmetric(
                                      horizontal: 16),
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: backgroundColor,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: dividerColor,
                                      width: 1,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Title
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.pets,
                                            color: primaryColor,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Sahip Olduğu Hayvanlar',
                                            style: GoogleFonts.poppins(
                                              color: textPrimary,
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 16),

                                      // Animal Tags
                                      Wrap(
                                        spacing: 12,
                                        runSpacing: 12,
                                        children: validAnimals.map((entry) {
                                          final animalType = entry.key;
                                          final count =
                                              (entry.value as num).toInt();

                                          return _buildSpecializationChip(
                                            _getAnimalDisplayText(animalType),
                                            count,
                                            _getAnimalColor(animalType),
                                          );
                                        }).toList(),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),

                            const SizedBox(height: 24),

                            // Action Buttons
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 24),
                              child: Column(
                                children: [
                                  // Service Provider Buttons - Only show for current user
                                  if (FirebaseAuth.instance.currentUser!.uid ==
                                      widget.uid) ...[
                                    // Check if user has transporter or veterinarian data
                                    StreamBuilder<
                                        DocumentSnapshot<Map<String, dynamic>>>(
                                      stream: FirebaseFirestore.instance
                                          .collection('users')
                                          .doc(widget.uid)
                                          .snapshots(),
                                      builder: (context, snapshot) {
                                        if (!snapshot.hasData ||
                                            !snapshot.data!.exists) {
                                          return const SizedBox();
                                        }

                                        final data =
                                            snapshot.data!.data() ?? {};

                                        // Check if user has transporter data
                                        final hasTransporterData = (data[
                                                        'transporterCompanyName'] !=
                                                    null &&
                                                data['transporterCompanyName']
                                                    .toString()
                                                    .isNotEmpty) ||
                                            (data[
                                                        'transporterVehicleType'] !=
                                                    null &&
                                                data['transporterVehicleType']
                                                    .toString()
                                                    .isNotEmpty) ||
                                            (data['transporterMaxAnimals'] !=
                                                null) ||
                                            (data['transporterMinPrice'] !=
                                                    null &&
                                                data['transporterMaxPrice'] !=
                                                    null) ||
                                            (data['transporterPricePerKm'] !=
                                                null) ||
                                            (data['transporterMaxDistanceKm'] !=
                                                null) ||
                                            (data['transporterDescription'] !=
                                                    null &&
                                                data['transporterDescription']
                                                    .toString()
                                                    .isNotEmpty) ||
                                            (_getTransporterCities(
                                                    data['transporterCities'])
                                                .isNotEmpty);

                                        // Check if user has veterinarian data
                                        final hasVeterinarianData = (data[
                                                        'veterinarianClinicName'] !=
                                                    null &&
                                                data['veterinarianClinicName']
                                                    .toString()
                                                    .isNotEmpty) ||
                                            (data['veterinarianPhone'] !=
                                                    null &&
                                                data['veterinarianPhone']
                                                    .toString()
                                                    .isNotEmpty) ||
                                            (data['veterinarianConsultationFee'] !=
                                                null) ||
                                            (data['veterinarianEmergencyFee'] !=
                                                null) ||
                                            (data['veterinarianDescription'] !=
                                                    null &&
                                                data['veterinarianDescription']
                                                    .toString()
                                                    .isNotEmpty) ||
                                            (_getVeterinarianCities(
                                                    data['veterinarianCities'])
                                                .isNotEmpty);

                                        return Column(
                                          children: [
                                            // Service Provider Cards
                                            if (!hasTransporterData &&
                                                !hasVeterinarianData) ...[
                                              Text(
                                                'Hizmet Sağlayıcısı mısınız?',
                                                style: GoogleFonts.poppins(
                                                  color: textSecondary,
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                              const SizedBox(height: 16),
                                            ],

                                            // Transporter Card
                                            if (!hasTransporterData)
                                              _buildServiceProviderCard(
                                                title: 'Nakliyeci',
                                                subtitle:
                                                    'Hayvan nakliye hizmeti veriyorsanız',
                                                icon: Icons.local_shipping,
                                                gradient: const LinearGradient(
                                                  colors: [
                                                    Color(0xFFFF9800),
                                                    Color(0xFFFF5722)
                                                  ],
                                                  begin: Alignment.topLeft,
                                                  end: Alignment.bottomRight,
                                                ),
                                                onTap: () {
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (context) =>
                                                          TransporterProfileScreen(
                                                        userId: user.uid,
                                                        existingTransporterData:
                                                            userData.cast<
                                                                String,
                                                                dynamic>(),
                                                      ),
                                                    ),
                                                  );
                                                },
                                              ),

                                            if (!hasTransporterData &&
                                                !hasVeterinarianData)
                                              const SizedBox(height: 12),

                                            // Veterinarian Card
                                            if (!hasVeterinarianData)
                                              _buildServiceProviderCard(
                                                title: 'Veteriner',
                                                subtitle:
                                                    'Veteriner hekimlik hizmeti veriyorsanız',
                                                icon: Icons.local_hospital,
                                                gradient: const LinearGradient(
                                                  colors: [
                                                    Color(0xFF2E7D32),
                                                    Color(0xFF1B5E20)
                                                  ],
                                                  begin: Alignment.topLeft,
                                                  end: Alignment.bottomRight,
                                                ),
                                                onTap: () {
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (context) =>
                                                          VeterinarianProfileScreen(
                                                        userId: user.uid,
                                                        existingVeterinarianData:
                                                            userData.cast<
                                                                String,
                                                                dynamic>(),
                                                      ),
                                                    ),
                                                  );
                                                },
                                              ),

                                            if (!hasTransporterData ||
                                                !hasVeterinarianData)
                                              const SizedBox(height: 24),
                                          ],
                                        );
                                      },
                                    ),
                                  ],
                                  // Second row: Other buttons
                                  if (FirebaseAuth.instance.currentUser!.uid ==
                                      widget.uid) ...[
                                    const SizedBox(height: 12),
                                    SizedBox(
                                      width: double.infinity,
                                      child: _buildActionButton(
                                        'Çıkış Yap',
                                        Icons.logout,
                                        errorColor,
                                        () async {
                                          await AuthMethods().signOut();
                                          Navigator.of(context)
                                              .pushAndRemoveUntil(
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  const LoginScreen(),
                                            ),
                                            (Route<dynamic> route) => false,
                                          );
                                        },
                                      ),
                                    ),
                                  ] else if (isBlocked)
                                    SizedBox(
                                      width: double.infinity,
                                      child: _buildActionButton(
                                        'Engeli Kaldır',
                                        Icons.block_outlined,
                                        warningColor,
                                        () async {
                                          await FireStoreMethods().unblockUser(
                                            FirebaseAuth
                                                .instance.currentUser!.uid,
                                            userData['uid'],
                                          );
                                          setState(() {
                                            isBlocked = false;
                                          });
                                        },
                                      ),
                                    )
                                  else
                                    SizedBox(
                                      width: double.infinity,
                                      child: _buildActionButton(
                                        isFollowing
                                            ? 'Takipten Çık'
                                            : 'Takip Et',
                                        isFollowing
                                            ? Icons.person_remove
                                            : Icons.person_add,
                                        isFollowing
                                            ? warningColor
                                            : primaryColor,
                                        () async {
                                          if (isFollowing) {
                                            await FireStoreMethods()
                                                .unfollowUser(
                                              FirebaseAuth
                                                  .instance.currentUser!.uid,
                                              userData['uid'],
                                            );
                                            setState(() {
                                              isFollowing = false;
                                              followers--;
                                            });
                                          } else {
                                            await FireStoreMethods().followUser(
                                              FirebaseAuth
                                                  .instance.currentUser!.uid,
                                              userData['uid'],
                                            );
                                            setState(() {
                                              isFollowing = true;
                                              followers++;
                                            });
                                          }
                                        },
                                      ),
                                    ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 24),

                            // Animals Section
                            if (animalCount > 0)
                              Container(
                                decoration: const BoxDecoration(
                                  color: backgroundColor,
                                  borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(20),
                                    topRight: Radius.circular(20),
                                  ),
                                ),
                                child: TabBar(
                                  controller: _tabController,
                                  indicatorColor: primaryColor,
                                  labelColor: primaryColor,
                                  unselectedLabelColor: textSecondary,
                                  dividerColor: Colors.transparent,
                                  tabs: const [
                                    Tab(
                                      icon: Icon(Icons.list_outlined),
                                      text: 'Liste',
                                    ),
                                    Tab(
                                      icon: Icon(Icons.grid_on_outlined),
                                      text: 'Galeri',
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (animalCount == 0)
                        SliverToBoxAdapter(
                          child: Container(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 16),
                            padding: const EdgeInsets.all(32),
                            decoration: BoxDecoration(
                              color: backgroundColor,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: dividerColor,
                                width: 1,
                              ),
                            ),
                            child: Column(
                              children: [
                                // Hayvan ikonları
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      '🐄',
                                      style: const TextStyle(fontSize: 48),
                                    ),
                                    const SizedBox(width: 16),
                                    Text(
                                      '🐑',
                                      style: const TextStyle(fontSize: 48),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 24),
                                Text(
                                  FirebaseAuth.instance.currentUser!.uid ==
                                          widget.uid
                                      ? 'Henüz ilanınız yok'
                                      : '${userData['username']} henüz ilan yayınlamadı',
                                  style: GoogleFonts.poppins(
                                    color: textPrimary,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  FirebaseAuth.instance.currentUser!.uid ==
                                          widget.uid
                                      ? 'İlanlarınızı buradan yayınlayabilirsiniz'
                                      : 'Bu kullanıcı henüz ilan paylaşmamış',
                                  style: GoogleFonts.poppins(
                                    color: textSecondary,
                                    fontSize: 14,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 24),
                                if (FirebaseAuth.instance.currentUser!.uid ==
                                    widget.uid)
                                  ElevatedButton.icon(
                                    onPressed: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const AddAnimalScreen(),
                                        ),
                                      );
                                    },
                                    icon: const Icon(Icons.add),
                                    label: Text(
                                      'İlk İlanını Ekle',
                                      style: GoogleFonts.poppins(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: primaryColor,
                                      foregroundColor: backgroundColor,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 24, vertical: 16),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      elevation: 0,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        )
                      else
                        SliverToBoxAdapter(
                          child: Container(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 0),
                            decoration: BoxDecoration(
                              color: backgroundColor,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: dividerColor,
                                width: 1,
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.6,
                                child: TabBarView(
                                  controller: _tabController,
                                  physics: const ClampingScrollPhysics(),
                                  children: [
                                    // List View
                                    StreamBuilder<
                                        QuerySnapshot<Map<String, dynamic>>>(
                                      stream: FirebaseFirestore.instance
                                          .collection('animals')
                                          .where('uid', isEqualTo: widget.uid)
                                          .orderBy('datePublished',
                                              descending: true)
                                          .snapshots(),
                                      builder: (context, snapshot) {
                                        if (!snapshot.hasData) {
                                          return const Center(
                                            child: CircularProgressIndicator(
                                              color: primaryColor,
                                            ),
                                          );
                                        }

                                        return ListView.builder(
                                          physics:
                                              const BouncingScrollPhysics(),
                                          padding: const EdgeInsets.all(12),
                                          itemCount: snapshot.data!.docs.length,
                                          itemBuilder: (context, index) {
                                            final animal =
                                                snapshot.data!.docs[index];
                                            return _buildAnimalListItem(animal);
                                          },
                                        );
                                      },
                                    ),

                                    // Grid View
                                    StreamBuilder<
                                        QuerySnapshot<Map<String, dynamic>>>(
                                      stream: FirebaseFirestore.instance
                                          .collection('animals')
                                          .where('uid', isEqualTo: widget.uid)
                                          .orderBy('datePublished',
                                              descending: true)
                                          .snapshots(),
                                      builder: (context, snapshot) {
                                        if (!snapshot.hasData) {
                                          return const Center(
                                            child: CircularProgressIndicator(
                                              color: primaryColor,
                                            ),
                                          );
                                        }

                                        return GridView.builder(
                                          physics:
                                              const BouncingScrollPhysics(),
                                          padding: const EdgeInsets.all(12),
                                          gridDelegate:
                                              const SliverGridDelegateWithFixedCrossAxisCount(
                                            crossAxisCount: 2,
                                            crossAxisSpacing: 12,
                                            mainAxisSpacing: 12,
                                            childAspectRatio: 0.7,
                                          ),
                                          itemCount: snapshot.data!.docs.length,
                                          itemBuilder: (context, index) {
                                            final animal =
                                                snapshot.data!.docs[index];
                                            return _buildAnimalGridItem(animal);
                                          },
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          );
  }

  Widget _buildStatItem(dynamic value, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value.toString(),
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: dividerColor,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: primaryColor, size: 16),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.poppins(
                  color: textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.poppins(
              color: textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureChip(String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: color,
            size: 16,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.poppins(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceCard(
      String value, String label, IconData icon, Color color,
      {String? subtitle}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: dividerColor,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 20,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 10,
              color: textSecondary,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: GoogleFonts.poppins(
                fontSize: 8,
                color: textSecondary,
                fontWeight: FontWeight.w400,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRatingCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: dividerColor,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.star,
            color: warningColor,
            size: 20,
          ),
          const SizedBox(height: 8),
          if (averageRating > 0) ...[
            // Yıldızları göster
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return Icon(
                  index < averageRating.floor()
                      ? Icons.star
                      : index < averageRating
                          ? Icons.star_half
                          : Icons.star_border,
                  color: warningColor,
                  size: 16,
                );
              }),
            ),
            const SizedBox(height: 4),
            Text(
              '${averageRating.toStringAsFixed(1)}/5.0',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: warningColor,
              ),
            ),
          ] else ...[
            Text(
              '0.0',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: textSecondary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Henüz puan yok',
              style: GoogleFonts.poppins(
                fontSize: 8,
                color: textSecondary,
                fontWeight: FontWeight.w400,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 4),
          Text(
            'Ortalama Puan',
            style: GoogleFonts.poppins(
              fontSize: 10,
              color: textSecondary,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildContactInfo(
      IconData icon, String title, String value, Color color) {
    return Row(
      children: [
        Icon(
          icon,
          color: color,
          size: 18,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  color: textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: GoogleFonts.poppins(
                  color: textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _getAnimalDisplayText(String animalType) {
    const animalEmojis = {
      'Süt Sığırı': '🐄 Süt Sığırı',
      'Et Sığırı': '🥩 Et Sığırı',
      'Damızlık Boğa': '🐂 Damızlık Boğa',
      'Düve': '🐄 Düve',
      'Manda': '🐃 Manda',
      'Tosun': '🐂 Tosun',
      'Koyun': '🐑 Koyun',
      'Keçi': '🐐 Keçi',
      'Kuzu': '🐑 Kuzu',
      'Oğlak': '🐐 Oğlak',
      'Koç': '🐏 Koç',
      'Teke': '🐐 Teke',
    };

    return animalEmojis[animalType] ?? '🐾 $animalType';
  }

  Color _getAnimalColor(String animalType) {
    const animalColors = {
      'Süt Sığırı': infoColor,
      'Et Sığırı': primaryColor,
      'Damızlık Boğa': primaryColor,
      'Düve': accentColor,
      'Manda': primaryColor,
      'Tosun': warningColor,
      'Koyun': textSecondary,
      'Keçi': accentColor,
      'Kuzu': infoColor,
      'Oğlak': accentColor,
      'Koç': primaryColor,
      'Teke': accentColor,
    };

    return animalColors[animalType] ?? primaryColor;
  }

  Widget _buildSpecializationChip(String text, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            text,
            style: GoogleFonts.poppins(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              count.toString(),
              style: GoogleFonts.poppins(
                color: backgroundColor,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceProviderCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required LinearGradient gradient,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: gradient.colors.first.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: GoogleFonts.poppins(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(
      String text, IconData icon, Color color, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: backgroundColor,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 0,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 8),
          Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimalGridItem(DocumentSnapshot animal) {
    final data = animal.data() as Map<String, dynamic>;
    final images = data['photoUrls'] as List<dynamic>? ?? [];
    final animalType = data['animalType'] ?? 'Hayvan';
    final price = data['priceInTL'] ?? 0.0;
    final ageInMonths = data['ageInMonths'] ?? 0;
    final weightInKg = data['weightInKg'] ?? 0.0;

    return GestureDetector(
      onTap: () {
        try {
          final animalPost = AnimalPost.fromSnap(animal);
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => AnimalDetailScreen(
                animal: animalPost,
              ),
            ),
          );
        } catch (e) {
          print('Error converting animal data: $e');
          // Hata mesajı göster, yönlendirme yapma
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('İlan detayları yüklenemedi.')),
          );
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: dividerColor,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Animal Image
            Expanded(
              flex: 3,
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(12)),
                child: images.isNotEmpty
                    ? Image.network(
                        images[0],
                        fit: BoxFit.cover,
                        width: double.infinity,
                      )
                    : Container(
                        color: surfaceColor,
                        child: const Icon(
                          Icons.pets,
                          size: 32,
                          color: textSecondary,
                        ),
                      ),
              ),
            ),
            // Animal Info
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      animalType,
                      style: GoogleFonts.poppins(
                        color: textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${(ageInMonths / 12).toStringAsFixed(1)} yaş',
                            style: GoogleFonts.poppins(
                              color: textSecondary,
                              fontSize: 10,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '${weightInKg.toInt()} kg',
                            style: GoogleFonts.poppins(
                              color: textSecondary,
                              fontSize: 10,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${price.toStringAsFixed(0)} ₺',
                      style: GoogleFonts.poppins(
                        color: primaryColor,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimalListItem(DocumentSnapshot animal) {
    final data = animal.data() as Map<String, dynamic>;
    final images = data['photoUrls'] as List<dynamic>? ?? [];
    final animalType = data['animalType'] ?? 'Hayvan';
    final price = data['priceInTL'] ?? 0.0;
    final ageInMonths = data['ageInMonths'] ?? 0;
    final weightInKg = data['weightInKg'] ?? 0.0;
    final description = data['description'] ?? '';

    return GestureDetector(
      onTap: () {
        try {
          final animalPost = AnimalPost.fromSnap(animal);
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => AnimalDetailScreen(
                animal: animalPost,
              ),
            ),
          );
        } catch (e) {
          print('Error converting animal data: $e');
          // Hata mesajı göster, yönlendirme yapma
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('İlan detayları yüklenemedi.')),
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: dividerColor,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Animal Image
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: images.isNotEmpty
                  ? Image.network(
                      images[0],
                      fit: BoxFit.cover,
                      width: 70,
                      height: 70,
                    )
                  : Container(
                      width: 70,
                      height: 70,
                      color: surfaceColor,
                      child: const Icon(
                        Icons.pets,
                        size: 20,
                        color: textSecondary,
                      ),
                    ),
            ),
            const SizedBox(width: 12),
            // Animal Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    animalType,
                    style: GoogleFonts.poppins(
                      color: textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (description.isNotEmpty)
                    Text(
                      description,
                      style: GoogleFonts.poppins(
                        color: textSecondary,
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: surfaceColor,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${(ageInMonths / 12).toStringAsFixed(1)} yaş',
                          style: GoogleFonts.poppins(
                            color: textSecondary,
                            fontSize: 9,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: surfaceColor,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${weightInKg.toInt()} kg',
                          style: GoogleFonts.poppins(
                            color: textSecondary,
                            fontSize: 9,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Price
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${price.toStringAsFixed(0)} ₺',
                  style: GoogleFonts.poppins(
                    color: primaryColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: successColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Satılık',
                    style: GoogleFonts.poppins(
                      color: successColor,
                      fontSize: 9,
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
  }

  Future<void> _refresh() async {
    await getData();
  }

  // Add a helper for price and km formatting
  String _formatPrice(dynamic price) {
    if (price == null) return '';
    num? value;
    if (price is num)
      value = price;
    else if (price is String)
      value = num.tryParse(price.replaceAll('.', '').replaceAll(',', ''));
    if (value == null) return '';
    final formatter = NumberFormat('#,##0', 'tr_TR');
    return '${formatter.format(value)} ₺';
  }

  String _formatKm(dynamic km) {
    if (km == null) return '';
    num? value;
    if (km is num)
      value = km;
    else if (km is String)
      value = num.tryParse(km.replaceAll('.', '').replaceAll(',', ''));
    if (value == null) return '';
    final formatter = NumberFormat('#,##0', 'tr_TR');
    return '${formatter.format(value)} km';
  }

  // Fix: Ensure transporterCities is a List<String> even if stored as comma-separated String
  List<String> _getTransporterCities(dynamic citiesRaw) {
    if (citiesRaw == null) return [];
    if (citiesRaw is List) {
      return citiesRaw
          .map((e) => e.toString())
          .where((e) => e.isNotEmpty)
          .toList();
    }
    if (citiesRaw is String) {
      return citiesRaw
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }
    return [];
  }

  // Fix: Ensure veterinarianCities is a List<String> even if stored as comma-separated String
  List<String> _getVeterinarianCities(dynamic citiesRaw) {
    if (citiesRaw == null) return [];
    if (citiesRaw is List) {
      return citiesRaw
          .map((e) => e.toString())
          .where((e) => e.isNotEmpty)
          .toList();
    }
    if (citiesRaw is String) {
      return citiesRaw
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }
    return [];
  }
}

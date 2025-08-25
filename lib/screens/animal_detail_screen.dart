import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/animal_post.dart';
import '../utils/animal_colors.dart';
import '../services/pricing_service.dart';
import '../widgets/price_tag.dart';
import '../resources/animal_firestore_methods.dart';
import 'add_animal_screen.dart';
import 'message_screen.dart';
import 'profile_screen2.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';
import 'package:shimmer/shimmer.dart';
import '../models/transporter.dart';
import '../services/transporter_service.dart';
import 'transporter_list_screen.dart';
import 'transporter_detail_screen.dart';

class AnimalDetailScreen extends StatefulWidget {
  final AnimalPost animal;

  const AnimalDetailScreen({Key? key, required this.animal}) : super(key: key);

  @override
  State<AnimalDetailScreen> createState() => _AnimalDetailScreenState();
}

class _AnimalDetailScreenState extends State<AnimalDetailScreen> {
  int _currentImageIndex = 0;
  bool _isFavorited = false;
  String? _currentUserId;
  late PageController _pageController;
  Map<String, dynamic>? _sellerData;
  bool _sellerLoading = true;
  List<Transporter> _nearbyTransporters = [];
  bool _transportersLoading = true;

  // ProfileScreen2 renk paleti
  static const Color primaryColor = Color(0xFF2E7D32);
  static const Color warningColor = Color(0xFFFF9800);
  static const Color errorColor = Color(0xFFE53935);
  static const Color backgroundColor = Colors.white;
  static const Color surfaceColor = Color(0xFFFAFAFA);
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color dividerColor = Color(0xFFE0E0E0);
  static const Color successColor = Color(0xFF4CAF50);
  static const Color infoColor = Color(0xFF2196F3);

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _fetchSellerData();
    _fetchNearbyTransporters();
    _currentUserId = FirebaseAuth.instance.currentUser?.uid;
    _initFavoriteState();
  }

  void _initFavoriteState() async {
    if (_currentUserId == null) return;
    final doc = await FirebaseFirestore.instance
        .collection('animals')
        .doc(widget.animal.postId)
        .get();
    if (doc.exists) {
      final data = doc.data() as Map<String, dynamic>;
      final likes = List.from(data['likes'] ?? []);
      setState(() {
        _isFavorited = likes.contains(_currentUserId);
      });
    }
  }

  Future<void> _toggleFavorite() async {
    if (_currentUserId == null) return;
    setState(() {
      _isFavorited = !_isFavorited;
    });
    final docRef = FirebaseFirestore.instance
        .collection('animals')
        .doc(widget.animal.postId);
    try {
      if (_isFavorited) {
        await docRef.update({
          'likes': FieldValue.arrayUnion([_currentUserId])
        });
      } else {
        await docRef.update({
          'likes': FieldValue.arrayRemove([_currentUserId])
        });
      }
    } catch (e) {
      setState(() {
        _isFavorited = !_isFavorited; // revert
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Favori işlemi başarısız: $e')),
      );
    }
  }

  Future<void> _fetchSellerData() async {
    setState(() {
      _sellerLoading = true;
    });
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.animal.uid)
          .get();
      if (doc.exists) {
        setState(() {
          _sellerData = doc.data();
          _sellerLoading = false;
        });
      } else {
        setState(() {
          _sellerLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _sellerLoading = false;
      });
    }
  }

  Future<void> _fetchNearbyTransporters() async {
    setState(() {
      _transportersLoading = true;
    });
    try {
      print(
          'Animal city: ${widget.animal.city}, state: ${widget.animal.state}');

      final transporters = await TransporterService.getNearbyTransporters(
        city: widget.animal.city,
        state: widget.animal.state,
        limit: 3,
      );

      print('Found ${transporters.length} nearby transporters');

      setState(() {
        _nearbyTransporters = transporters;
        _transportersLoading = false;
      });
    } catch (e) {
      print('Error fetching nearby transporters: $e');
      setState(() {
        _transportersLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.animal.animalBreed.isNotEmpty
              ? widget.animal.animalBreed
              : widget.animal.animalSpecies,
          style: GoogleFonts.poppins(
            color: textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              _isFavorited ? Icons.favorite : Icons.favorite_border,
              color: _isFavorited ? errorColor : textPrimary,
            ),
            onPressed: () async {
              await _toggleFavorite();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(_isFavorited
                      ? 'Favorilere eklendi'
                      : 'Favorilerden çıkarıldı'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          _buildImageCarousel(),
          _buildCard(
            icon: null, // Emoji ile gösterilecek
            title: 'Hayvan Bilgileri',
            child: _buildAnimalInfo(),
            emoji: _getAnimalTypeEmoji(
                widget.animal.animalType, widget.animal.animalSpecies),
          ),
          if (widget.animal.description.isNotEmpty)
            _buildCard(
              icon: Icons.description,
              title: 'Açıklama',
              child: _buildDescription(),
            ),
          _buildCard(
            icon: Icons.currency_lira, // TL simgesi, yoksa kaldırılabilir
            title: 'Fiyat Bilgileri',
            child: _buildPriceInfo(),
          ),
          _buildCard(
            icon: Icons.health_and_safety,
            title: 'Sağlık Bilgileri',
            child: _buildHealthInfo(),
          ),
          _buildCard(
            icon: Icons.person,
            title: 'Satıcı Bilgileri',
            child: _buildSellerInfo(),
          ),
          _buildCard(
            icon: Icons.location_on,
            title: 'Konum',
            child: _buildLocationInfo(),
          ),
          _buildCard(
            icon: Icons.local_shipping,
            title: 'Yakındaki Nakliyeciler',
            child: _buildNearbyTransporters(),
          ),
          SizedBox(height: 100),
        ],
      ),
      floatingActionButton: _buildContactButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildCard(
      {String? emoji,
      IconData? icon,
      required String title,
      required Widget child}) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: dividerColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (emoji != null)
                Text(
                  emoji,
                  style: TextStyle(fontSize: 22),
                )
              else if (icon != null)
                Icon(icon, color: primaryColor, size: 20),
              SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.poppins(
                  color: textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildImageCarousel() {
    if (widget.animal.photoUrls.isEmpty) {
      return Container(
        height: 260,
        margin: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: dividerColor, width: 1),
        ),
        child: Center(
          child: Icon(Icons.pets, size: 80, color: textSecondary),
        ),
      );
    }
    return GestureDetector(
      onTap: () {
        _showFullScreenGallery(_currentImageIndex);
      },
      child: Container(
        margin: EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: dividerColor, width: 1),
          color: surfaceColor,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              SizedBox(
                height: 260,
                width: double.infinity,
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentImageIndex = index;
                    });
                  },
                  itemCount: widget.animal.photoUrls.length,
                  itemBuilder: (context, index) {
                    return CachedNetworkImage(
                      imageUrl: widget.animal.photoUrls[index],
                      fit: BoxFit.cover,
                      width: double.infinity,
                      placeholder: (context, url) => Shimmer.fromColors(
                        baseColor: Colors.grey[400]!,
                        highlightColor: Colors.grey[200]!,
                        child: Container(
                          color: Colors.grey[400],
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.pets,
                                  size: 60,
                                  color: Colors.grey[500],
                                ),
                                SizedBox(height: 16),
                                Container(
                                  width: 120,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[500],
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                                SizedBox(height: 8),
                                Container(
                                  width: 80,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[500],
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: surfaceColor,
                        child:
                            Icon(Icons.error, size: 50, color: textSecondary),
                      ),
                    );
                  },
                ),
              ),
              if (widget.animal.photoUrls.length > 1)
                Positioned(
                  bottom: 12,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children:
                        widget.animal.photoUrls.asMap().entries.map((entry) {
                      return Container(
                        width: 8.0,
                        height: 8.0,
                        margin: EdgeInsets.symmetric(horizontal: 4.0),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _currentImageIndex == entry.key
                              ? primaryColor
                              : dividerColor,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              // Fiyat overlay
              Positioned(
                bottom: 16,
                right: 16,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.92),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    '${NumberFormat('#,###', 'tr_TR').format(widget.animal.priceInTL)} ₺'
                        .replaceAll(',', '.'),
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
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

  void _showFullScreenGallery(int initialIndex) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Görseli Kapat',
      transitionDuration: Duration(milliseconds: 200),
      pageBuilder: (context, anim1, anim2) {
        return _FullScreenGallery(
          photoUrls: widget.animal.photoUrls,
          initialIndex: initialIndex,
        );
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return FadeTransition(
          opacity: anim1,
          child: child,
        );
      },
    );
  }

  Widget _buildAnimalInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoRow('Tür', widget.animal.animalType.toUpperCase()),
        _buildInfoRow('Cins', widget.animal.animalSpecies),
        _buildInfoRow('Irk', widget.animal.animalBreed),
        _buildInfoRow('Cinsiyet', widget.animal.gender),
        _buildInfoRow('Yaş', '${widget.animal.ageInMonths} ay'),
        _buildInfoRow(
            'Ağırlık', '${widget.animal.weightInKg.toStringAsFixed(0)} kg'),
        _buildInfoRow('Amaç', widget.animal.purpose),
        if (widget.animal.isPregnant)
          _buildInfoRow('Durum', 'Gebe', color: warningColor),
        if (widget.animal.birthDate != null)
          _buildInfoRow('Doğum Tarihi', _formatDate(widget.animal.birthDate!)),
      ],
    );
  }

  Widget _buildPriceInfo() {
    return Row(
      children: [
        // Icon(Icons.attach_money, color: primaryColor), // KALDIRILDI
        // Fiyat
        Text(
          '${NumberFormat('#,###', 'tr_TR').format(widget.animal.priceInTL)} ₺'
              .replaceAll(',', '.'),
          style: GoogleFonts.poppins(
            color: primaryColor,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (widget.animal.isNegotiable)
          Padding(
            padding: const EdgeInsets.only(left: 12),
            child: _buildBadge('Pazarlık', warningColor),
          ),
        if (widget.animal.isUrgentSale)
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: _buildBadge('Acil', errorColor),
          ),
      ],
    );
  }

  Widget _buildHealthInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoRow('Sağlık Durumu', widget.animal.healthStatus),
        if (widget.animal.vaccinations.isNotEmpty)
          _buildInfoRow('Aşılar', widget.animal.vaccinations.join(', ')),
        if (widget.animal.veterinarianContact != null)
          _buildInfoRow(
              'Veteriner İletişim', widget.animal.veterinarianContact!),
      ],
    );
  }

  Widget _buildSellerInfo() {
    if (_sellerLoading) {
      return Shimmer.fromColors(
        baseColor: Colors.grey[400]!,
        highlightColor: Colors.grey[200]!,
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 16,
                      width: 120,
                      decoration: BoxDecoration(
                        color: Colors.grey[400],
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 12,
                      width: 80,
                      decoration: BoxDecoration(
                        color: Colors.grey[400],
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 10,
                      width: 60,
                      decoration: BoxDecoration(
                        color: Colors.grey[400],
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }
    final data = _sellerData;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProfileScreen2(
              uid: widget.animal.uid,
              snap: data,
              userId: widget.animal.uid,
            ),
          ),
        );
      },
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 20,
            backgroundImage: widget.animal.profImage.isNotEmpty
                ? CachedNetworkImageProvider(widget.animal.profImage)
                : null,
            child: widget.animal.profImage.isEmpty
                ? Icon(Icons.person, size: 20)
                : null,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.animal.username,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  widget.animal.sellerType,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: textSecondary,
                  ),
                ),
                if (data != null) ...[
                  SizedBox(height: 10),
                  Row(
                    children: [
                      // Satış sayısı
                      Icon(Icons.shopping_cart, color: primaryColor, size: 16),
                      SizedBox(width: 4),
                      Text(
                        '${data['totalSales'] ?? 0} satış',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: textPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(width: 16),
                      // Ortalama puan
                      Icon(Icons.star, color: warningColor, size: 16),
                      SizedBox(width: 2),
                      Text(
                        data['averageRating'] != null
                            ? data['averageRating'].toStringAsFixed(1)
                            : '-',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: warningColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '/5.0',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationInfo() {
    return Row(
      children: [
        Icon(Icons.location_on, color: errorColor, size: 18),
        SizedBox(width: 8),
        Text(
          widget.animal.city,
          style: GoogleFonts.poppins(
            fontSize: 13,
            color: textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildDescription() {
    return Text(
      widget.animal.description,
      style: GoogleFonts.poppins(
        fontSize: 14,
        color: textSecondary,
      ),
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? color}) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w500,
                color: textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                color: color ?? textPrimary,
                fontWeight: color != null ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactButton() {
    final currentUser = FirebaseAuth.instance.currentUser;
    final isOwner = currentUser?.uid == widget.animal.uid;

    if (isOwner) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            icon: Icon(Icons.delete, color: Colors.white),
            label: Text('İlanı Sil',
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: errorColor,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 4,
            ),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('İlanı Sil'),
                  content: Text('Bu ilanı silmek istediğinize emin misiniz?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: Text('Vazgeç'),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style:
                          ElevatedButton.styleFrom(backgroundColor: errorColor),
                      child: Text('Sil'),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                try {
                  await FirebaseFirestore.instance
                      .collection('animals')
                      .doc(widget.animal.postId)
                      .delete();
                  Navigator.of(context).pop(); // Detay sayfasını kapat
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('İlan silindi')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Silme işlemi başarısız: $e')),
                  );
                }
              }
            },
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(horizontal: 16),
      child: ElevatedButton(
        onPressed: () {
          _showContactOptions();
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 4,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.message, size: 20),
            SizedBox(width: 8),
            Text(
              'Satıcı ile İletişime Geç',
              style: GoogleFonts.poppins(
                  fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  void _showContactOptions() async {
    final phoneNumber =
        _sellerData != null ? (_sellerData!['phoneNumber'] ?? '') : '';
    final email = _sellerData != null ? (_sellerData!['email'] ?? '') : '';

    print('_showContactOptions - SellerData: $_sellerData');
    print('_showContactOptions - Email: $email');
    print('_showContactOptions - PhoneNumber: $phoneNumber');
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: Colors.white,
      builder: (context) => Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'İletişim Seçenekleri',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            SizedBox(height: 20),
            ListTile(
              leading: Icon(Icons.message, color: primaryColor),
              title: Text('Mesaj Gönder',
                  style: GoogleFonts.poppins(color: Colors.black)),
              subtitle: Text('Uygulama içi mesajlaşma',
                  style: GoogleFonts.poppins(color: Colors.grey[700])),
              onTap: () {
                Navigator.pop(context);
                final currentUser = FirebaseAuth.instance.currentUser;
                if (currentUser != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MessagesPage(
                        currentUserUid: currentUser.uid,
                        recipientUid: widget.animal.uid,
                        postId: widget.animal.postId,
                      ),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Giriş yapmanız gerekiyor')),
                  );
                }
              },
            ),
            if (phoneNumber.isNotEmpty)
              ListTile(
                leading: Icon(Icons.phone, color: Colors.green),
                title: Text('Telefon',
                    style: GoogleFonts.poppins(color: Colors.black)),
                subtitle: GestureDetector(
                  onTap: () async {
                    final uri = Uri(scheme: 'tel', path: phoneNumber);
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Arama başlatılamadı')),
                      );
                    }
                  },
                  onLongPress: () async {
                    await Clipboard.setData(ClipboardData(text: phoneNumber));
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Telefon numarası kopyalandı')),
                    );
                  },
                  child: Text(
                    phoneNumber,
                    style: GoogleFonts.poppins(
                      color: Colors.blue,
                      fontSize: 16,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
                onTap: () async {
                  final uri = Uri(scheme: 'tel', path: phoneNumber);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Arama başlatılamadı')),
                    );
                  }
                },
              ),
            if (email.isNotEmpty)
              ListTile(
                leading: Icon(Icons.email, color: Colors.blue),
                title: Text('E-posta',
                    style: GoogleFonts.poppins(color: Colors.black)),
                subtitle: Text(email,
                    style: GoogleFonts.poppins(color: Colors.grey[700])),
                onTap: () async {
                  print('E-posta butonuna tıklandı - Email: $email');

                  // E-posta adresini panoya kopyala
                  await Clipboard.setData(ClipboardData(text: email));

                  // Kullanıcıya bilgi ver
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('E-posta adresi kopyalandı: $email'),
                      duration: Duration(seconds: 2),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
              )
            else
              ListTile(
                leading: Icon(Icons.email, color: Colors.grey),
                title: Text('E-posta',
                    style: GoogleFonts.poppins(color: Colors.grey)),
                subtitle: Text('E-posta bilgisi mevcut değil',
                    style: GoogleFonts.poppins(color: Colors.grey)),
                enabled: false,
              ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _getAnimalTypeEmoji(String animalType, String animalSpecies) {
    final type = animalType.toLowerCase();
    final species = animalSpecies.toLowerCase();
    // Öncelik: Keçi türleri > Koyun türleri > Büyükbaş > Diğer
    if (species.contains('keçi') ||
        species.contains('oğlak') ||
        species.contains('teke') ||
        type.contains('keçi')) {
      return '🐐';
    } else if (species.contains('koyun') ||
        species.contains('kuzu') ||
        species.contains('koç') ||
        type.contains('koyun')) {
      return '🐑';
    } else if (type.contains('büyükbaş') ||
        species.contains('sığır') ||
        species.contains('manda') ||
        species.contains('boğa') ||
        species.contains('düve') ||
        species.contains('tosun')) {
      return '🐄';
    } else {
      return '🐾';
    }
  }

  Widget _buildNearbyTransporters() {
    if (_transportersLoading) {
      return Column(
        children: [
          _buildTransportersShimmer(),
          SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: Icon(Icons.visibility, size: 16),
              label: Text('Tüm Nakliyecileri Gör'),
              style: OutlinedButton.styleFrom(
                foregroundColor: primaryColor,
                side: BorderSide(color: primaryColor),
                padding: EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TransporterListScreen(
                      city: widget.animal.city,
                      state: widget.animal.state,
                      title: '${widget.animal.city} Nakliyecileri',
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        if (_nearbyTransporters.isEmpty)
          Container(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Text(
              'Bu bölgede henüz nakliyeci bulunmuyor.',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          )
        else
          ..._nearbyTransporters
              .take(3)
              .map((transporter) => _buildTransporterItem(transporter)),
        SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            icon: Icon(Icons.visibility, size: 16),
            label: Text(_nearbyTransporters.isEmpty
                ? 'Nakliyecileri Ara'
                : 'Tüm Nakliyecileri Gör'),
            style: OutlinedButton.styleFrom(
              foregroundColor: primaryColor,
              side: BorderSide(color: primaryColor),
              padding: EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TransporterListScreen(
                    city: widget.animal.city,
                    state: widget.animal.state,
                    title: '${widget.animal.city} Nakliyecileri',
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTransportersShimmer() {
    return Column(
      children: List.generate(
        3,
        (index) => Shimmer.fromColors(
          baseColor: Colors.grey[400]!,
          highlightColor: Colors.grey[200]!,
          child: Container(
            margin: EdgeInsets.only(bottom: 12),
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[400],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    shape: BoxShape.circle,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 14,
                        width: 120,
                        decoration: BoxDecoration(
                          color: Colors.grey[400],
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      SizedBox(height: 8),
                      Container(
                        height: 10,
                        width: 80,
                        decoration: BoxDecoration(
                          color: Colors.grey[400],
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTransporterItem(Transporter transporter) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(12),
      constraints:
          BoxConstraints(maxWidth: MediaQuery.of(context).size.width - 32),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: dividerColor, width: 1),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TransporterDetailScreen(
                transporterData: transporter.toMap(),
              ),
            ),
          );
        },
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundImage: transporter.profileImage != null
                  ? CachedNetworkImageProvider(transporter.profileImage!)
                  : null,
              child: transporter.profileImage == null
                  ? Icon(Icons.local_shipping, size: 20, color: primaryColor)
                  : null,
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transporter.companyName,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.star, color: warningColor, size: 12),
                      SizedBox(width: 2),
                      Text(
                        transporter.rating?.toStringAsFixed(1) ?? '-',
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: warningColor,
                        ),
                      ),
                      Text(
                        '/5',
                        style: GoogleFonts.poppins(
                          fontSize: 9,
                          color: textSecondary,
                        ),
                      ),
                      SizedBox(width: 6),
                      Icon(Icons.local_shipping, color: infoColor, size: 12),
                      SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          '${transporter.totalTrips ?? 0} seyahat',
                          style: GoogleFonts.poppins(
                            fontSize: 9,
                            color: textSecondary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.location_on, color: errorColor, size: 12),
                      SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '${transporter.cities.take(3).join(', ')}${transporter.cities.length > 3 ? '...' : ''}',
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            color: textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (transporter.minPrice != null &&
                      transporter.maxPrice != null)
                    Text(
                      '${NumberFormat('#,###', 'tr_TR').format(transporter.minPrice)}-${NumberFormat('#,###', 'tr_TR').format(transporter.maxPrice)}₺',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: primaryColor,
                      ),
                    )
                  else if (transporter.pricePerKm != null)
                    Text(
                      '${NumberFormat('#,###', 'tr_TR').format(transporter.pricePerKm)}₺/km',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: primaryColor,
                      ),
                    ),
                  SizedBox(height: 4),
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.phone, size: 16, color: successColor),
                        onPressed: () => _callTransporter(transporter),
                        padding: EdgeInsets.zero,
                        constraints: BoxConstraints(),
                      ),
                      SizedBox(width: 2),
                      IconButton(
                        icon:
                            Icon(Icons.message, size: 16, color: primaryColor),
                        onPressed: () => _messageTransporter(transporter),
                        padding: EdgeInsets.zero,
                        constraints: BoxConstraints(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _callTransporter(Transporter transporter) async {
    final uri = Uri(scheme: 'tel', path: transporter.phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Arama başlatılamadı')),
      );
    }
  }

  void _messageTransporter(Transporter transporter) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MessagesPage(
            currentUserUid: currentUser.uid,
            recipientUid: transporter.userId,
            postId: '', // Nakliyeci mesajı olduğu için postId boş
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Giriş yapmanız gerekiyor')),
      );
    }
  }
}

// Tam ekran modern görsel görüntüleyici
class _FullScreenGallery extends StatefulWidget {
  final List<String> photoUrls;
  final int initialIndex;
  const _FullScreenGallery(
      {Key? key, required this.photoUrls, this.initialIndex = 0})
      : super(key: key);

  @override
  State<_FullScreenGallery> createState() => _FullScreenGalleryState();
}

class _FullScreenGalleryState extends State<_FullScreenGallery> {
  late PageController _controller;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _controller = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            PageView.builder(
              controller: _controller,
              itemCount: widget.photoUrls.length,
              onPageChanged: (i) => setState(() => _currentIndex = i),
              itemBuilder: (context, index) {
                return Center(
                  child: Hero(
                    tag: widget.photoUrls[index],
                    child: CachedNetworkImage(
                      imageUrl: widget.photoUrls[index],
                      fit: BoxFit.contain,
                      placeholder: (context, url) => Shimmer.fromColors(
                        baseColor: Colors.grey[600]!,
                        highlightColor: Colors.grey[400]!,
                        child: Container(
                          color: Colors.grey[600],
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.pets,
                                  size: 80,
                                  color: Colors.grey[500],
                                ),
                                SizedBox(height: 24),
                                Container(
                                  width: 160,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[500],
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                ),
                                SizedBox(height: 12),
                                Container(
                                  width: 100,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[500],
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                                SizedBox(height: 12),
                                Container(
                                  width: 140,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[500],
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) =>
                          Icon(Icons.error, color: Colors.white, size: 60),
                    ),
                  ),
                );
              },
            ),
            // Kapatma butonu
            Positioned(
              top: 16,
              right: 16,
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  padding: EdgeInsets.all(8),
                  child: Icon(Icons.close, color: Colors.white, size: 28),
                ),
              ),
            ),
            // Dots göstergesi
            if (widget.photoUrls.length > 1)
              Positioned(
                bottom: 32,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                      widget.photoUrls.length,
                      (i) => Container(
                            width: 10,
                            height: 10,
                            margin: EdgeInsets.symmetric(horizontal: 4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _currentIndex == i
                                  ? Colors.white
                                  : Colors.white24,
                            ),
                          )),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

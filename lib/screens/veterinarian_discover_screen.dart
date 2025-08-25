import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/veterinarian.dart';
import '../widgets/veterinarian_card.dart';
import '../utils/veterinarian_categories.dart';
import '../services/pricing_service.dart';
import 'veterinarian_detail_screen.dart';
import 'package:google_fonts/google_fonts.dart';

class VeterinarianDiscoverScreen extends StatefulWidget {
  const VeterinarianDiscoverScreen({Key? key}) : super(key: key);

  @override
  State<VeterinarianDiscoverScreen> createState() =>
      _VeterinarianDiscoverScreenState();
}

class _VeterinarianDiscoverScreenState
    extends State<VeterinarianDiscoverScreen> {
  bool isGridView = true;
  String selectedCategory = 'Tüm Veterinerler';
  String searchQuery = '';
  RangeValues feeRange = RangeValues(0, 1000);
  RangeValues experienceRange = RangeValues(0, 50);
  String selectedCity = 'Tüm Şehirler';
  bool showFilters = false;
  bool showAvailableOnly = false;
  bool showEmergencyOnly = false;

  final TextEditingController _searchController = TextEditingController();

  static const Color primaryColor = Color(0xFF2E7D32);
  static const Color warningColor = Color(0xFFFF9800);
  static const Color errorColor = Color(0xFFE53935);
  static const Color backgroundColor = Colors.white;
  static const Color surfaceColor = Color(0xFFFAFAFA);
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color dividerColor = Color(0xFFE0E0E0);

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: backgroundColor,
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: Text(
          'Veteriner Bul',
          style: GoogleFonts.poppins(
            color: textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [],
      ),
      body: RefreshIndicator(
        color: primaryColor,
        onRefresh: () async => setState(() {}),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // Arama butonu
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: SizedBox(
                height: 44,
                child: ElevatedButton.icon(
                  onPressed: () => setState(() => showFilters = !showFilters),
                  icon: Icon(Icons.search, color: primaryColor),
                  label: Text(
                    'Veteriner Ara',
                    style: GoogleFonts.poppins(
                      color: textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: surfaceColor,
                    foregroundColor: textPrimary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    side: BorderSide(color: dividerColor),
                    padding: EdgeInsets.symmetric(horizontal: 16),
                  ),
                ),
              ),
            ),
            // Filtreler
            if (showFilters) _buildSearchAndFilters(),
            // Kategoriler
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildQuickFilterChip(
                        'Müsait',
                        showAvailableOnly,
                        () => setState(
                            () => showAvailableOnly = !showAvailableOnly)),
                    SizedBox(width: 8),
                    _buildQuickFilterChip(
                        'Acil Hizmet',
                        showEmergencyOnly,
                        () => setState(
                            () => showEmergencyOnly = !showEmergencyOnly)),
                    SizedBox(width: 16),
                    ...VeterinarianCategories.categories
                        .map((category) => Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: GestureDetector(
                                onTap: () =>
                                    setState(() => selectedCategory = category),
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: selectedCategory == category
                                        ? primaryColor.withOpacity(0.1)
                                        : surfaceColor,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: selectedCategory == category
                                          ? primaryColor.withOpacity(0.3)
                                          : dividerColor,
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        VeterinarianCategories.getCategoryIcon(
                                            category),
                                        size: 16,
                                        color: selectedCategory == category
                                            ? primaryColor
                                            : textSecondary,
                                      ),
                                      SizedBox(width: 6),
                                      Text(
                                        category,
                                        style: GoogleFonts.poppins(
                                          color: selectedCategory == category
                                              ? primaryColor
                                              : textPrimary,
                                          fontWeight:
                                              selectedCategory == category
                                                  ? FontWeight.w600
                                                  : FontWeight.w500,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            )),
                  ],
                ),
              ),
            ),
            // Veteriner listesi
            _buildVeterinarianList(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: primaryColor,
        elevation: 4,
        child: Icon(
          isGridView ? Icons.list : Icons.grid_view,
          color: Colors.white,
          size: 24,
        ),
        onPressed: () => setState(() => isGridView = !isGridView),
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      color: const Color(0xFFF5F7F4),
      margin: EdgeInsets.only(top: 10, left: 16, right: 16, bottom: 0),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.tune, color: primaryColor, size: 16),
                    SizedBox(width: 4),
                    Text('Filtreler',
                        style: GoogleFonts.poppins(
                            color: textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
                TextButton(
                  onPressed: _clearAllFilters,
                  child: Text('Temizle',
                      style: GoogleFonts.poppins(
                          color: warningColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            SizedBox(height: 12),
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Veteriner ara...',
                prefixIcon: Icon(Icons.search, color: primaryColor),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onChanged: (value) => setState(() => searchQuery = value),
            ),
            SizedBox(height: 12),
            Text('Muayene Ücreti (₺)',
                style: GoogleFonts.poppins(
                    color: textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
            RangeSlider(
              values: feeRange,
              min: 0,
              max: 1000,
              divisions: 50,
              labels: RangeLabels(
                PricingService.formatPrice(feeRange.start),
                PricingService.formatPrice(feeRange.end),
              ),
              onChanged: (values) => setState(() => feeRange = values),
            ),
            SizedBox(height: 12),
            Text('Deneyim (yıl)',
                style: GoogleFonts.poppins(
                    color: textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
            RangeSlider(
              values: experienceRange,
              min: 0,
              max: 50,
              divisions: 25,
              labels: RangeLabels(
                '${experienceRange.start.round()} yıl',
                '${experienceRange.end.round()} yıl',
              ),
              onChanged: (values) => setState(() => experienceRange = values),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickFilterChip(
      String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor.withOpacity(0.1) : surfaceColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? primaryColor.withOpacity(0.3) : dividerColor,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected) ...[
              Icon(Icons.check_circle, color: primaryColor, size: 16),
              SizedBox(width: 6),
            ],
            Text(
              label,
              style: GoogleFonts.poppins(
                color: isSelected ? primaryColor : textPrimary,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVeterinarianList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('isVeterinarian', isEqualTo: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Hata: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: primaryColor));
        }

        final allVeterinarians = <Veterinarian>[];
        for (var doc in snapshot.data!.docs) {
          try {
            final veterinarian = Veterinarian.fromSnap(doc);
            allVeterinarians.add(veterinarian);
          } catch (e) {
            print('Hata: ${doc.id} dönüştürülemedi - $e');
          }
        }

        final veterinarians =
            allVeterinarians.where(_filterVeterinarians).toList();

        if (veterinarians.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.local_hospital, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('Veteriner bulunamadı',
                    style: GoogleFonts.poppins(
                        fontSize: 18, fontWeight: FontWeight.w600)),
                SizedBox(height: 8),
                Text('Filtreleri değiştirmeyi deneyin',
                    style: GoogleFonts.poppins(color: textSecondary)),
              ],
            ),
          );
        }

        if (isGridView) {
          return Padding(
            padding: const EdgeInsets.all(8),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: veterinarians
                  .map((veterinarian) => SizedBox(
                        width: MediaQuery.of(context).size.width / 2 - 20,
                        child: VeterinarianCard(
                          veterinarian: veterinarian,
                          isGridView: true,
                          onTap: () =>
                              _navigateToVeterinarianDetail(veterinarian),
                          onCall: () => _callVeterinarian(veterinarian),
                        ),
                      ))
                  .toList(),
            ),
          );
        } else {
          return Column(
            children: veterinarians
                .map((veterinarian) => Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      child: VeterinarianCard(
                        veterinarian: veterinarian,
                        isGridView: false,
                        onTap: () =>
                            _navigateToVeterinarianDetail(veterinarian),
                        onCall: () => _callVeterinarian(veterinarian),
                      ),
                    ))
                .toList(),
          );
        }
      },
    );
  }

  bool _filterVeterinarians(Veterinarian veterinarian) {
    if (!veterinarian.isActive) return false;
    if (showAvailableOnly && !veterinarian.available) return false;
    if (showEmergencyOnly && !veterinarian.emergencyService) return false;

    if (selectedCategory != 'Tüm Veterinerler') {
      if (!VeterinarianCategories.matchesCategory(selectedCategory,
          veterinarian.specializations, veterinarian.services)) {
        return false;
      }
    }

    if (searchQuery.isNotEmpty) {
      final searchLower = searchQuery.toLowerCase();
      if (!(veterinarian.clinicName?.toLowerCase().contains(searchLower) ??
              false) &&
          !veterinarian.specializations
              .any((spec) => spec.toLowerCase().contains(searchLower))) {
        return false;
      }
    }

    if (veterinarian.consultationFee != null) {
      if (veterinarian.consultationFee! < feeRange.start ||
          veterinarian.consultationFee! > feeRange.end) {
        return false;
      }
    }

    if (veterinarian.yearsExperience != null) {
      if (veterinarian.yearsExperience! < experienceRange.start ||
          veterinarian.yearsExperience! > experienceRange.end) {
        return false;
      }
    }

    return true;
  }

  void _navigateToVeterinarianDetail(Veterinarian veterinarian) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VeterinarianDetailScreen(
          veterinarianId: veterinarian.uid,
          veterinarianData: veterinarian.toJson(),
        ),
      ),
    );
  }

  void _callVeterinarian(Veterinarian veterinarian) {
    print('Call ${veterinarian.uid}');
  }

  void _clearAllFilters() {
    setState(() {
      selectedCategory = 'Tüm Veterinerler';
      searchQuery = '';
      feeRange = RangeValues(0, 1000);
      experienceRange = RangeValues(0, 50);
      selectedCity = 'Tüm Şehirler';
      showAvailableOnly = false;
      showEmergencyOnly = false;
      showFilters = false;
      _searchController.clear();
    });
  }
}

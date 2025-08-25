import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/animal_post.dart';
import '../widgets/animal_card.dart';
import '../utils/animal_categories.dart';
import '../services/pricing_service.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'animal_detail_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';

class AnimalDiscoverScreen extends StatefulWidget {
  const AnimalDiscoverScreen({Key? key}) : super(key: key);

  @override
  State<AnimalDiscoverScreen> createState() => _AnimalDiscoverScreenState();
}

class _AnimalDiscoverScreenState extends State<AnimalDiscoverScreen> {
  bool isGridView = true;
  String selectedCategory = 'Tüm Hayvanlar';
  String selectedAnimalType = 'Tümü';
  String searchQuery = '';
  RangeValues priceRange = RangeValues(0, 500000); // Fiyat aralığını artırdık
  RangeValues ageRange = RangeValues(0, 120);
  String selectedGender = 'Tümü';
  String selectedHealthStatus = 'Tümü';
  String selectedCity = 'Tüm Şehirler';
  bool showFilters = false;
  bool showUrgentOnly = false; // Acil satış filtresi
  int filteredResultsCount = 0; // Filtrelenen sonuç sayısı

  // Local state for immediate updates
  List<AnimalPost> _allAnimals = [];
  List<AnimalPost> _filteredAnimals = [];

  // Track if filters have been modified from defaults
  bool _filtersModified = false;

  final TextEditingController _searchController = TextEditingController();

  // Classic color palette - ProfileScreen2'den alındı
  static const Color primaryColor = Color(0xFF2E7D32);
  static const Color warningColor = Color(0xFFFF9800);
  static const Color errorColor = Color(0xFFE53935);
  static const Color backgroundColor = Colors.white;
  static const Color surfaceColor = Color(0xFFFAFAFA);
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color dividerColor = Color(0xFFE0E0E0);

  // Responsive helper methods
  bool get isSmallScreen => MediaQuery.of(context).size.width < 360;
  bool get isMediumScreen =>
      MediaQuery.of(context).size.width >= 360 &&
      MediaQuery.of(context).size.width < 600;
  bool get isLargeScreen => MediaQuery.of(context).size.width >= 600;

  double get filterPanelMaxHeight =>
      MediaQuery.of(context).size.height * (isSmallScreen ? 0.8 : 0.7);
  double get filterPanelMaxWidth =>
      isLargeScreen ? 400.0 : MediaQuery.of(context).size.width * 0.95;

  int get maxVisibleCategories => isSmallScreen
      ? 4
      : isMediumScreen
          ? 6
          : 8;

  // Türkiye şehirleri listesi
  static const List<String> turkishCities = [
    'Tüm Şehirler',
    'Adana',
    'Adıyaman',
    'Afyonkarahisar',
    'Ağrı',
    'Amasya',
    'Ankara',
    'Antalya',
    'Artvin',
    'Aydın',
    'Balıkesir',
    'Bilecik',
    'Bingöl',
    'Bitlis',
    'Bolu',
    'Burdur',
    'Bursa',
    'Çanakkale',
    'Çankırı',
    'Çorum',
    'Denizli',
    'Diyarbakır',
    'Edirne',
    'Elazığ',
    'Erzincan',
    'Erzurum',
    'Eskişehir',
    'Gaziantep',
    'Giresun',
    'Gümüşhane',
    'Hakkari',
    'Hatay',
    'Isparta',
    'Mersin',
    'İstanbul',
    'İzmir',
    'Kars',
    'Kastamonu',
    'Kayseri',
    'Kırklareli',
    'Kırşehir',
    'Kocaeli',
    'Konya',
    'Kütahya',
    'Malatya',
    'Manisa',
    'Kahramanmaraş',
    'Mardin',
    'Muğla',
    'Muş',
    'Nevşehir',
    'Niğde',
    'Ordu',
    'Rize',
    'Sakarya',
    'Samsun',
    'Siirt',
    'Sinop',
    'Sivas',
    'Tekirdağ',
    'Tokat',
    'Trabzon',
    'Tunceli',
    'Şanlıurfa',
    'Uşak',
    'Van',
    'Yozgat',
    'Zonguldak',
    'Aksaray',
    'Bayburt',
    'Karaman',
    'Kırıkkale',
    'Batman',
    'Şırnak',
    'Bartın',
    'Ardahan',
    'Iğdır',
    'Yalova',
    'Karabük',
    'Kilis',
    'Osmaniye',
    'Düzce',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    // Verileri yenile
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: _buildAppBar(),
      body: RefreshIndicator(
        color: primaryColor,
        onRefresh: _refresh,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // Arama butonu
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: SizedBox(
                height: 44,
                child: ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      showFilters = !showFilters;
                    });
                  },
                  icon: Icon(Icons.search, color: primaryColor),
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Hayvan Ara',
                        style: GoogleFonts.poppins(
                          color: textPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (filteredResultsCount > 0 && !showFilters) ...[
                        SizedBox(width: 8),
                        Container(
                          padding:
                              EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: primaryColor,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '$filteredResultsCount',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
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
            // Arama ve filtre paneli (gizli/açık)
            if (showFilters) _buildSearchAndFilters(),
            // Aktif filtreler özeti (filtre paneli kapalıyken)
            if (!showFilters) _buildActiveFiltersSummary(),
            // Kompakt hızlı filtreler ve kategoriler
            Container(
              height: isSmallScreen ? 45 : 50,
              padding: EdgeInsets.symmetric(
                  horizontal: isSmallScreen ? 4 : 8,
                  vertical: isSmallScreen ? 4 : 8),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    // Hızlı filtreler
                    _buildQuickFilterChip(
                      'Büyükbaş',
                      selectedAnimalType == 'Büyükbaş',
                      () {
                        final newValue = selectedAnimalType == 'Büyükbaş'
                            ? 'Tümü'
                            : 'Büyükbaş';
                        setState(() => selectedAnimalType = newValue);
                        _clearConflictingFilters('animalType', newValue);
                        _onFilterChanged();
                      },
                    ),
                    SizedBox(width: isSmallScreen ? 6 : 8),
                    _buildQuickFilterChip(
                      'Küçükbaş',
                      selectedAnimalType == 'Küçükbaş',
                      () {
                        final newValue = selectedAnimalType == 'Küçükbaş'
                            ? 'Tümü'
                            : 'Küçükbaş';
                        setState(() => selectedAnimalType = newValue);
                        _clearConflictingFilters('animalType', newValue);
                        _onFilterChanged();
                      },
                    ),
                    SizedBox(width: isSmallScreen ? 6 : 8),
                    _buildQuickFilterChip(
                      'Kanatlı',
                      selectedAnimalType == 'Kanatlı',
                      () {
                        final newValue = selectedAnimalType == 'Kanatlı'
                            ? 'Tümü'
                            : 'Kanatlı';
                        setState(() => selectedAnimalType = newValue);
                        _clearConflictingFilters('animalType', newValue);
                        _onFilterChanged();
                      },
                    ),
                    SizedBox(width: isSmallScreen ? 6 : 8),
                    _buildQuickFilterChip(
                      'Acil Satış',
                      showUrgentOnly,
                      () {
                        setState(() => showUrgentOnly = !showUrgentOnly);
                        _onFilterChanged();
                      },
                    ),
                    SizedBox(width: isSmallScreen ? 6 : 8),
                    // Şehir hızlı filtresi
                    if (selectedCity != 'Tüm Şehirler')
                      _buildQuickFilterChip(
                        selectedCity,
                        true,
                        () {
                          setState(() => selectedCity = 'Tüm Şehirler');
                          _onFilterChanged();
                        },
                      ),
                    if (selectedCity != 'Tüm Şehirler')
                      SizedBox(width: isSmallScreen ? 6 : 8),
                    SizedBox(width: isSmallScreen ? 12 : 16),
                    // Kategoriler - Responsive tasarım
                    ...AnimalCategories.categories
                        .take(maxVisibleCategories)
                        .map((category) => Padding(
                              padding:
                                  EdgeInsets.only(right: isSmallScreen ? 6 : 8),
                              child: _buildCategoryChip(category),
                            )),
                    // Daha fazla kategori varsa "Daha Fazla" butonu
                    if (AnimalCategories.categories.length >
                        maxVisibleCategories)
                      Padding(
                        padding: EdgeInsets.only(right: isSmallScreen ? 6 : 8),
                        child: _buildMoreCategoriesButton(),
                      ),
                  ],
                ),
              ),
            ),
            // Hayvan listesi
            _buildAnimalListUnified(),
          ],
        ),
      ),
      floatingActionButton: _buildViewToggle(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: backgroundColor,
      automaticallyImplyLeading: false,
      centerTitle: true,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icon(Icons.pets, color: primaryColor, size: 24), // Kaldırıldı
          // SizedBox(width: 8), // Kaldırıldı
          Text(
            'CanlıPazar',
            style: GoogleFonts.poppins(
              color: primaryColor,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
      actions: [
        // Bildirim ve konum butonları kaldırıldı
      ],
    );
  }

  Widget _buildShimmerLoading() {
    return Shimmer.fromColors(
      baseColor: surfaceColor,
      highlightColor: backgroundColor,
      child: isGridView ? _buildGridShimmer() : _buildListShimmer(),
    );
  }

  Widget _buildGridShimmer() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: List.generate(
            6,
            (index) => SizedBox(
                  width: MediaQuery.of(context).size.width / 2 - 20,
                  child: Container(
                    decoration: BoxDecoration(
                      color: surfaceColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: dividerColor),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Resim placeholder
                        Container(
                          height: 120,
                          decoration: BoxDecoration(
                            color: surfaceColor,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(12),
                              topRight: Radius.circular(12),
                            ),
                          ),
                        ),
                        // İçerik placeholder
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Başlık placeholder
                              Container(
                                height: 16,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: surfaceColor,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              const SizedBox(height: 6),
                              // Fiyat placeholder
                              Container(
                                height: 14,
                                width: 80,
                                decoration: BoxDecoration(
                                  color: surfaceColor,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              const SizedBox(height: 6),
                              // Chip placeholder
                              Row(
                                children: [
                                  Container(
                                    height: 20,
                                    width: 50,
                                    decoration: BoxDecoration(
                                      color: surfaceColor,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    height: 20,
                                    width: 40,
                                    decoration: BoxDecoration(
                                      color: surfaceColor,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                )),
      ),
    );
  }

  Widget _buildListShimmer() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      itemCount: 6,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: dividerColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                spreadRadius: 1,
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Resim placeholder
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    bottomLeft: Radius.circular(12),
                  ),
                ),
              ),
              // İçerik placeholder
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Başlık placeholder
                      Container(
                        height: 18,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: surfaceColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Fiyat placeholder
                      Container(
                        height: 16,
                        width: 100,
                        decoration: BoxDecoration(
                          color: surfaceColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Chip placeholder
                      Row(
                        children: [
                          Container(
                            height: 24,
                            width: 60,
                            decoration: BoxDecoration(
                              color: surfaceColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            height: 24,
                            width: 50,
                            decoration: BoxDecoration(
                              color: surfaceColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSearchAndFilters() {
    return Align(
      alignment: Alignment.topCenter,
      child: FractionallySizedBox(
        widthFactor: isLargeScreen ? null : 0.95,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: filterPanelMaxHeight,
            maxWidth: filterPanelMaxWidth,
          ),
          child: Card(
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            color: const Color(0xFFF5F7F4),
            margin: EdgeInsets.only(top: 10, left: 0, right: 0, bottom: 0),
            child: Column(
              children: [
                // Başlık ve Temizle butonu - Sabit üst kısım
                Padding(
                  padding: EdgeInsets.symmetric(
                      horizontal: isSmallScreen ? 8 : 12,
                      vertical: isSmallScreen ? 8 : 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Icon(Icons.tune, color: primaryColor, size: 16),
                            SizedBox(width: 4),
                            Text(
                              'Filtreler',
                              style: GoogleFonts.poppins(
                                color: textPrimary,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: _clearAllFilters,
                        style: TextButton.styleFrom(
                          minimumSize: Size(0, 28),
                          padding: EdgeInsets.symmetric(horizontal: 6),
                        ),
                        child: Text(
                          'Temizle',
                          style: GoogleFonts.poppins(
                            color: warningColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Kaydırılabilir filtre içeriği
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                        horizontal: isSmallScreen ? 8 : 12, vertical: 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Arama çubuğu
                        Container(
                          decoration: BoxDecoration(
                            color: surfaceColor,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: dividerColor,
                              width: 1,
                            ),
                          ),
                          child: TextField(
                            controller: _searchController,
                            style: GoogleFonts.poppins(
                              color: textPrimary,
                              fontSize: 12,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Hayvan ara (tür, yaş, fiyat...)',
                              hintStyle: GoogleFonts.poppins(
                                color: textSecondary,
                                fontSize: 12,
                              ),
                              prefixIcon: Icon(Icons.search,
                                  color: primaryColor, size: 18),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 12,
                              ),
                            ),
                            onChanged: (value) {
                              setState(() {
                                searchQuery = value;
                              });
                              _onFilterChanged();
                            },
                          ),
                        ),
                        SizedBox(height: 12),

                        // Fiyat aralığı
                        _buildFilterSection(
                          title: 'Fiyat',
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Flexible(
                                    child: Text(
                                      PricingService.formatPrice(
                                          priceRange.start),
                                      style: GoogleFonts.poppins(
                                        color: textSecondary,
                                        fontSize: 11,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      PricingService.formatPrice(
                                          priceRange.end),
                                      style: GoogleFonts.poppins(
                                        color: textSecondary,
                                        fontSize: 11,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 4),
                              SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  activeTrackColor: primaryColor,
                                  inactiveTrackColor: dividerColor,
                                  thumbColor: primaryColor,
                                  overlayColor: primaryColor.withOpacity(0.2),
                                  trackHeight: 2,
                                  thumbShape: RoundSliderThumbShape(
                                      enabledThumbRadius: 8),
                                ),
                                child: RangeSlider(
                                  values: priceRange,
                                  min: 0,
                                  max: 500000,
                                  divisions: 100,
                                  labels: RangeLabels(
                                    PricingService.formatPrice(
                                        priceRange.start),
                                    PricingService.formatPrice(priceRange.end),
                                  ),
                                  onChanged: (values) {
                                    setState(() {
                                      priceRange = values;
                                    });
                                    _onFilterChanged();
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Yaş aralığı
                        _buildFilterSection(
                          title: 'Yaş (ay)',
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Flexible(
                                    child: Text(
                                      '${ageRange.start.round()} ay',
                                      style: GoogleFonts.poppins(
                                        color: textSecondary,
                                        fontSize: 11,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      '${ageRange.end.round()} ay',
                                      style: GoogleFonts.poppins(
                                        color: textSecondary,
                                        fontSize: 11,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 4),
                              SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  activeTrackColor: primaryColor,
                                  inactiveTrackColor: dividerColor,
                                  thumbColor: primaryColor,
                                  overlayColor: primaryColor.withOpacity(0.2),
                                  trackHeight: 2,
                                  thumbShape: RoundSliderThumbShape(
                                      enabledThumbRadius: 8),
                                ),
                                child: RangeSlider(
                                  values: ageRange,
                                  min: 0,
                                  max: 120,
                                  divisions: 24,
                                  labels: RangeLabels(
                                    '${ageRange.start.round()} ay',
                                    '${ageRange.end.round()} ay',
                                  ),
                                  onChanged: (values) {
                                    setState(() {
                                      ageRange = values;
                                    });
                                    _onFilterChanged();
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Cinsiyet ve sağlık durumu
                        _buildFilterSection(
                          title: 'Özellikler',
                          child: Column(
                            children: [
                              // Şehir dropdown
                              Container(
                                width: double.infinity,
                                child: InkWell(
                                  onTap: () => _showCitySelectionDialog(),
                                  borderRadius: BorderRadius.circular(7),
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(7),
                                      border: Border.all(color: dividerColor),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.location_city,
                                          color: textSecondary,
                                          size: 16,
                                        ),
                                        SizedBox(width: 8),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Şehir',
                                                style: GoogleFonts.poppins(
                                                  color: textSecondary,
                                                  fontSize: 10,
                                                ),
                                              ),
                                              Text(
                                                selectedCity,
                                                style: GoogleFonts.poppins(
                                                  color: textPrimary,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                        ),
                                        Icon(
                                          Icons.arrow_drop_down,
                                          color: textSecondary,
                                          size: 20,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(height: 8),

                              // Cinsiyet dropdown
                              Container(
                                width: double.infinity,
                                child: Theme(
                                  data: Theme.of(context).copyWith(
                                    canvasColor: Colors.white,
                                  ),
                                  child: DropdownButtonFormField<String>(
                                    value: selectedGender,
                                    style: GoogleFonts.poppins(
                                      color: textPrimary,
                                      fontSize: 12,
                                    ),
                                    decoration: InputDecoration(
                                      labelText: 'Cinsiyet',
                                      labelStyle: GoogleFonts.poppins(
                                        color: textSecondary,
                                        fontSize: 10,
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(7),
                                        borderSide:
                                            BorderSide(color: dividerColor),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(7),
                                        borderSide:
                                            BorderSide(color: dividerColor),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(7),
                                        borderSide:
                                            BorderSide(color: primaryColor),
                                      ),
                                      contentPadding: EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 6),
                                      filled: true,
                                      fillColor: Colors.white,
                                    ),
                                    dropdownColor: Colors.white,
                                    items: ['Tümü', 'Erkek', 'Dişi']
                                        .map((gender) => DropdownMenuItem(
                                              value: gender,
                                              child: Text(
                                                gender,
                                                style: GoogleFonts.poppins(
                                                  color: textPrimary,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ))
                                        .toList(),
                                    onChanged: (value) {
                                      setState(() {
                                        selectedGender = value!;
                                      });
                                      _onFilterChanged();
                                    },
                                  ),
                                ),
                              ),
                              SizedBox(height: 8),

                              // Sağlık durumu dropdown
                              Container(
                                width: double.infinity,
                                child: Theme(
                                  data: Theme.of(context).copyWith(
                                    canvasColor: Colors.white,
                                  ),
                                  child: DropdownButtonFormField<String>(
                                    value: selectedHealthStatus,
                                    style: GoogleFonts.poppins(
                                      color: textPrimary,
                                      fontSize: 12,
                                    ),
                                    decoration: InputDecoration(
                                      labelText: 'Sağlık Durumu',
                                      labelStyle: GoogleFonts.poppins(
                                        color: textSecondary,
                                        fontSize: 10,
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(7),
                                        borderSide:
                                            BorderSide(color: dividerColor),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(7),
                                        borderSide:
                                            BorderSide(color: dividerColor),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(7),
                                        borderSide:
                                            BorderSide(color: primaryColor),
                                      ),
                                      contentPadding: EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 6),
                                      filled: true,
                                      fillColor: Colors.white,
                                    ),
                                    dropdownColor: Colors.white,
                                    items: [
                                      'Tümü',
                                      ...AnimalCategories.healthStatuses
                                    ]
                                        .map((status) => DropdownMenuItem(
                                              value: status,
                                              child: Text(
                                                status,
                                                style: GoogleFonts.poppins(
                                                  color: textPrimary,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ))
                                        .toList(),
                                    onChanged: (value) {
                                      setState(() {
                                        selectedHealthStatus = value!;
                                      });
                                      _onFilterChanged();
                                    },
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

                // Sabit alt kısım - Sonuç sayısı ve buton - sadece filtreler değiştirildiğinde göster
                if (_filtersModified)
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(14),
                        bottomRight: Radius.circular(14),
                      ),
                      border: Border(
                        top: BorderSide(
                          color: primaryColor.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                    ),
                    child: Column(
                      children: [
                        // Sonuç sayısı
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.search,
                              color: primaryColor,
                              size: 16,
                            ),
                            SizedBox(width: 6),
                            Text(
                              '$filteredResultsCount sonuç bulundu',
                              style: GoogleFonts.poppins(
                                color: primaryColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12),
                        // Sonuçları göster butonu
                        SizedBox(
                          width: double.infinity,
                          height: 40,
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() {
                                showFilters = false;
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.visibility, size: 16),
                                SizedBox(width: 6),
                                Text(
                                  'Sonuçları Göster',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
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
      ),
    );
  }

  Widget _buildFilterSection({required String title, required Widget child}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              color: textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 6),
          child,
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String category) {
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedCategory = category;
        });
        _clearConflictingFilters('category', category);
        _onFilterChanged();
      },
      child: Container(
        padding: EdgeInsets.symmetric(
            horizontal: isSmallScreen ? 8 : 12,
            vertical: isSmallScreen ? 4 : 6),
        decoration: BoxDecoration(
          color: selectedCategory == category
              ? primaryColor.withOpacity(0.1)
              : surfaceColor,
          borderRadius: BorderRadius.circular(16),
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
              AnimalCategories.getCategoryIcon(category),
              size: isSmallScreen ? 12 : 14,
              color:
                  selectedCategory == category ? primaryColor : textSecondary,
            ),
            SizedBox(width: isSmallScreen ? 3 : 4),
            Flexible(
              child: Text(
                category,
                style: GoogleFonts.poppins(
                  color:
                      selectedCategory == category ? primaryColor : textPrimary,
                  fontWeight: selectedCategory == category
                      ? FontWeight.w600
                      : FontWeight.w500,
                  fontSize: isSmallScreen ? 10 : 11,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMoreCategoriesButton() {
    return GestureDetector(
      onTap: () {
        // Show all categories in a bottom sheet or dialog
        _showAllCategoriesDialog();
      },
      child: Container(
        padding: EdgeInsets.symmetric(
            horizontal: isSmallScreen ? 8 : 12,
            vertical: isSmallScreen ? 4 : 6),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: dividerColor,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.more_horiz,
              size: isSmallScreen ? 12 : 14,
              color: textSecondary,
            ),
            SizedBox(width: isSmallScreen ? 3 : 4),
            Text(
              'Daha Fazla',
              style: GoogleFonts.poppins(
                color: textPrimary,
                fontWeight: FontWeight.w500,
                fontSize: isSmallScreen ? 10 : 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAllCategoriesDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: EdgeInsets.only(top: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Title
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Tüm Kategoriler',
                style: GoogleFonts.poppins(
                  color: textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            // Categories grid
            Flexible(
              child: GridView.builder(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shrinkWrap: true,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 3,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: AnimalCategories.categories.length,
                itemBuilder: (context, index) {
                  final category = AnimalCategories.categories[index];
                  return GestureDetector(
                    onTap: () {
                      selectedCategory = category;
                      _clearConflictingFilters('category', category);
                      Navigator.pop(context);
                      // Trigger filter update after dialog closes
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        _onFilterChanged();
                      });
                    },
                    child: Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: selectedCategory == category
                            ? primaryColor.withOpacity(0.1)
                            : surfaceColor,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: selectedCategory == category
                              ? primaryColor.withOpacity(0.3)
                              : dividerColor,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            AnimalCategories.getCategoryIcon(category),
                            size: 16,
                            color: selectedCategory == category
                                ? primaryColor
                                : textSecondary,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              category,
                              style: GoogleFonts.poppins(
                                color: selectedCategory == category
                                    ? primaryColor
                                    : textPrimary,
                                fontWeight: selectedCategory == category
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showCitySelectionDialog() {
    String citySearchQuery = '';
    List<String> filteredCities = List.from(turkishCities);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          // Filter cities based on search query
          if (citySearchQuery.isNotEmpty) {
            filteredCities = turkishCities
                .where((city) =>
                    city.toLowerCase().contains(citySearchQuery.toLowerCase()))
                .toList();
          } else {
            filteredCities = List.from(turkishCities);
          }

          return Container(
            height: MediaQuery.of(context).size.height * 0.7,
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Column(
              children: [
                // Handle bar
                Container(
                  margin: EdgeInsets.only(top: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: dividerColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // Title
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Şehir Seçin',
                        style: GoogleFonts.poppins(
                          color: textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          selectedCity = 'Tüm Şehirler';
                          Navigator.pop(context);
                          // Trigger filter update after dialog closes
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            _onFilterChanged();
                          });
                        },
                        child: Text(
                          'Tümü',
                          style: GoogleFonts.poppins(
                            color: primaryColor,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Search bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    decoration: BoxDecoration(
                      color: surfaceColor,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: dividerColor,
                        width: 1,
                      ),
                    ),
                    child: TextField(
                      style: GoogleFonts.poppins(
                        color: textPrimary,
                        fontSize: 14,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Şehir ara...',
                        hintStyle: GoogleFonts.poppins(
                          color: textSecondary,
                          fontSize: 14,
                        ),
                        prefixIcon:
                            Icon(Icons.search, color: primaryColor, size: 20),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                      ),
                      onChanged: (value) {
                        setState(() {
                          citySearchQuery = value;
                        });
                      },
                    ),
                  ),
                ),
                SizedBox(height: 16),
                // Cities list
                Expanded(
                  child: filteredCities.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.search_off,
                                color: textSecondary,
                                size: 48,
                              ),
                              SizedBox(height: 16),
                              Text(
                                'Şehir bulunamadı',
                                style: GoogleFonts.poppins(
                                  color: textPrimary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                '"$citySearchQuery" için sonuç yok',
                                style: GoogleFonts.poppins(
                                  color: textSecondary,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          itemCount: filteredCities.length,
                          itemBuilder: (context, index) {
                            final city = filteredCities[index];
                            return ListTile(
                              title: Text(
                                city,
                                style: GoogleFonts.poppins(
                                  color: textPrimary,
                                  fontSize: 14,
                                  fontWeight: selectedCity == city
                                      ? FontWeight.w600
                                      : FontWeight.w500,
                                ),
                              ),
                              leading: selectedCity == city
                                  ? Icon(Icons.check_circle,
                                      color: primaryColor, size: 20)
                                  : Icon(Icons.location_city,
                                      color: textSecondary, size: 20),
                              onTap: () {
                                selectedCity = city;
                                Navigator.pop(context);
                                // Trigger filter update after dialog closes
                                WidgetsBinding.instance
                                    .addPostFrameCallback((_) {
                                  _onFilterChanged();
                                });
                              },
                              tileColor: selectedCity == city
                                  ? primaryColor.withOpacity(0.1)
                                  : null,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            );
                          },
                        ),
                ),
                SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildQuickFilterChip(
      String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
            horizontal: isSmallScreen ? 8 : 12,
            vertical: isSmallScreen ? 4 : 6),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor.withOpacity(0.1) : surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? primaryColor.withOpacity(0.3) : dividerColor,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: primaryColor,
                size: isSmallScreen ? 12 : 14,
              ),
            if (isSelected) SizedBox(width: isSmallScreen ? 3 : 4),
            Flexible(
              child: Text(
                label,
                style: GoogleFonts.poppins(
                  color: isSelected ? primaryColor : textPrimary,
                  fontSize: isSmallScreen ? 10 : 11,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterPanel() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      padding: EdgeInsets.all(20),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.tune, color: primaryColor, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Gelişmiş Filtreler',
                    style: GoogleFonts.poppins(
                      color: textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: _clearAllFilters,
                child: Text(
                  'Temizle',
                  style: GoogleFonts.poppins(
                    color: warningColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),

          // Fiyat aralığı
          Text(
            'Fiyat Aralığı',
            style: GoogleFonts.poppins(
              color: textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 4),
          Text(
            '${PricingService.formatPriceRange(priceRange.start, priceRange.end)}',
            style: GoogleFonts.poppins(
              color: textSecondary,
              fontSize: 12,
            ),
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: primaryColor,
              inactiveTrackColor: dividerColor,
              thumbColor: primaryColor,
              overlayColor: primaryColor.withOpacity(0.2),
            ),
            child: RangeSlider(
              values: priceRange,
              min: 0,
              max: 500000,
              divisions: 100,
              labels: RangeLabels(
                PricingService.formatPrice(priceRange.start),
                PricingService.formatPrice(priceRange.end),
              ),
              onChanged: (values) {
                setState(() {
                  priceRange = values;
                });
              },
            ),
          ),

          SizedBox(height: 16),

          // Yaş aralığı
          Text(
            'Yaş Aralığı',
            style: GoogleFonts.poppins(
              color: textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 4),
          Text(
            '${ageRange.start.round()}-${ageRange.end.round()} ay',
            style: GoogleFonts.poppins(
              color: textSecondary,
              fontSize: 12,
            ),
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: primaryColor,
              inactiveTrackColor: dividerColor,
              thumbColor: primaryColor,
              overlayColor: primaryColor.withOpacity(0.2),
            ),
            child: RangeSlider(
              values: ageRange,
              min: 0,
              max: 120,
              divisions: 24,
              labels: RangeLabels(
                '${ageRange.start.round()} ay',
                '${ageRange.end.round()} ay',
              ),
              onChanged: (values) {
                setState(() {
                  ageRange = values;
                });
              },
            ),
          ),

          SizedBox(height: 16),

          // Cinsiyet ve sağlık durumu
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: selectedGender,
                  style: GoogleFonts.poppins(
                    color: textPrimary,
                    fontSize: 14,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Cinsiyet',
                    labelStyle: GoogleFonts.poppins(
                      color: textSecondary,
                      fontSize: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: dividerColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: dividerColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: primaryColor),
                    ),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: ['Tümü', 'Erkek', 'Dişi']
                      .map((gender) => DropdownMenuItem(
                            value: gender,
                            child: Text(
                              gender,
                              style: GoogleFonts.poppins(
                                color: textPrimary,
                                fontSize: 14,
                              ),
                            ),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedGender = value!;
                    });
                  },
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: selectedHealthStatus,
                  style: GoogleFonts.poppins(
                    color: textPrimary,
                    fontSize: 14,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Sağlık Durumu',
                    labelStyle: GoogleFonts.poppins(
                      color: textSecondary,
                      fontSize: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: dividerColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: dividerColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: primaryColor),
                    ),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: ['Tümü', ...AnimalCategories.healthStatuses]
                      .map((status) => DropdownMenuItem(
                            value: status,
                            child: Text(
                              status,
                              style: GoogleFonts.poppins(
                                color: textPrimary,
                                fontSize: 14,
                              ),
                            ),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedHealthStatus = value!;
                    });
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTabs() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.category, color: primaryColor, size: 20),
              SizedBox(width: 8),
              Text(
                'Kategoriler',
                style: GoogleFonts.poppins(
                  color: textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Container(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: AnimalCategories.categories.length,
              itemBuilder: (context, index) {
                final category = AnimalCategories.categories[index];
                final isSelected = selectedCategory == category;

                return Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedCategory = category;
                      });
                    },
                    child: Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? primaryColor.withOpacity(0.1)
                            : surfaceColor,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? primaryColor.withOpacity(0.3)
                              : dividerColor,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            AnimalCategories.getCategoryIcon(category),
                            size: 16,
                            color: isSelected ? primaryColor : textSecondary,
                          ),
                          SizedBox(width: 6),
                          Text(
                            category,
                            style: GoogleFonts.poppins(
                              color: isSelected ? primaryColor : textPrimary,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Yeni fonksiyon: Grid ve List görünümünü tek bir widget'ta döndür
  Widget _buildAnimalListUnified() {
    return StreamBuilder<QuerySnapshot>(
      stream: _buildAnimalQuery(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          // Hatayı konsola yazdır ki linke tıklayabilelim
          print('🔥 Firebase Error: ${snapshot.error}');
          print(
              '🔗 Index Link: Bu hatayı çözmek için yukarıdaki linke tıklayın');

          return Center(
            child: Container(
              margin: EdgeInsets.all(16),
              padding: EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: dividerColor,
                  width: 1,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: errorColor),
                  SizedBox(height: 16),
                  Text(
                    'Bir hata oluştu',
                    style: GoogleFonts.poppins(
                      color: textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Lütfen tekrar deneyin',
                    style: GoogleFonts.poppins(
                      color: textSecondary,
                      fontSize: 14,
                    ),
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {});
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      padding:
                          EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Tekrar Dene',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting ||
            snapshot.connectionState == ConnectionState.none) {
          return _buildShimmerLoading();
        }

        print(
            '📊 Firebase\'den ${snapshot.data!.docs.length} hayvan dökümanı geldi');

        final allAnimals = <AnimalPost>[];
        for (var doc in snapshot.data!.docs) {
          print('🐄 Döküman ID: ${doc.id}');
          print('📝 Döküman verisi: ${doc.data()}');
          try {
            final animal = AnimalPost.fromSnap(doc);
            allAnimals.add(animal);
          } catch (e) {
            print('❌ Hata: ${doc.id} dönüştürülemedi - $e');
          }
        }

        print('🔄 AnimalPost\'a dönüştürülen ${allAnimals.length} hayvan');

        // Debug: Log all cities in the data
        final citiesInData =
            allAnimals.map((animal) => animal.city).toSet().toList()..sort();
        print('🏙️ Verilerdeki şehirler: $citiesInData');
        print('🎯 Seçili şehir: $selectedCity');

        // Update local state with new data
        _allAnimals = allAnimals;

        // Calculate filtered results
        _filteredAnimals = allAnimals.where(_filterAnimals).toList();
        filteredResultsCount = _filteredAnimals.length;

        print('✅ Filtrelemeden sonra ${_filteredAnimals.length} hayvan kaldı');

        if (_filteredAnimals.isEmpty) {
          return Center(
            child: Container(
              margin: EdgeInsets.all(16),
              padding: EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: dividerColor,
                  width: 1,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Hayvan ikonları
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '🐄',
                        style: TextStyle(fontSize: 48),
                      ),
                      SizedBox(width: 16),
                      Text(
                        '🐑',
                        style: TextStyle(fontSize: 48),
                      ),
                    ],
                  ),
                  SizedBox(height: 24),
                  Text(
                    'Bu kriterlerde hayvan bulunamadı',
                    style: GoogleFonts.poppins(
                      color: textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Filtreleri değiştirmeyi deneyin',
                    style: GoogleFonts.poppins(
                      color: textSecondary,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _clearAllFilters,
                    icon: Icon(Icons.clear_all, size: 20),
                    label: Text(
                      'Tüm Filtreleri Temizle',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      padding:
                          EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        if (isGridView) {
          // Grid görünümü: Wrap ile responsive grid
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _filteredAnimals
                  .map((animal) => SizedBox(
                        width: MediaQuery.of(context).size.width / 2 - 20,
                        child: AnimalCard(
                          animal: animal,
                          isGridView: true,
                          onTap: () => _navigateToAnimalDetail(animal),
                          onFavorite: () => _toggleFavorite(animal),
                        ),
                      ))
                  .toList(),
            ),
          );
        } else {
          // List görünümü: Column
          return Column(
            children: _filteredAnimals
                .map((animal) => Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      child: AnimalCard(
                        animal: animal,
                        isGridView: false,
                        onTap: () => _navigateToAnimalDetail(animal),
                        onFavorite: () => _toggleFavorite(animal),
                      ),
                    ))
                .toList(),
          );
        }
      },
    );
  }

  Stream<QuerySnapshot> _buildAnimalQuery() {
    // Geçici çözüm: Composite index gerektirebilecek filtreleri kaldır
    Query query = FirebaseFirestore.instance
        .collection('animals')
        .orderBy('datePublished', descending: true);

    // Kategori filtresi
    if (selectedCategory != 'Tüm Hayvanlar') {
      // TODO: Implement category-specific filtering
    }

    return query.snapshots();
  }

  bool _filterAnimals(AnimalPost animal) {
    print(
        '🔍 Filtreleme: ${animal.postId} - ${animal.animalSpecies} - ${animal.animalBreed}');
    print('🔍 isActive değeri: ${animal.isActive}');
    print(
        '🔍 Fiyat: ${animal.priceInTL} (aralık: ${priceRange.start}-${priceRange.end})');
    print(
        '🔍 Yaş: ${animal.ageInMonths} (aralık: ${ageRange.start}-${ageRange.end})');
    print('🔍 Cinsiyet: ${animal.gender} (seçili: $selectedGender)');
    print('🔍 Sağlık: ${animal.healthStatus} (seçili: $selectedHealthStatus)');
    print('🔍 Tür: ${animal.animalType} (seçili: $selectedAnimalType)');
    print('🔍 Kategori: $selectedCategory');
    print('🔍 Şehir: ${animal.city} (seçili: $selectedCity)');
    print(
        '🔍 Acil satış: ${animal.isUrgentSale} (filtre aktif: $showUrgentOnly)');
    print('🔍 Arama sorgusu: "$searchQuery"');

    // Sadece açıkça false olanları filtrele
    if (animal.isActive == false) {
      print('❌ Filtrelendi: isActive = ${animal.isActive}');
      return false;
    }

    // Kategori filtresi
    if (selectedCategory != 'Tüm Hayvanlar') {
      if (!_matchesCategory(animal, selectedCategory)) {
        print('❌ Filtrelendi: Kategori "${selectedCategory}" ile eşleşmedi');
        return false;
      }
    }

    // Arama filtresi
    if (searchQuery.isNotEmpty) {
      final searchLower = searchQuery.toLowerCase();
      if (!animal.animalSpecies.toLowerCase().contains(searchLower) &&
          !animal.animalBreed.toLowerCase().contains(searchLower) &&
          !animal.description.toLowerCase().contains(searchLower)) {
        print('❌ Filtrelendi: Arama "${searchQuery}" ile eşleşmedi');
        return false;
      }
    }

    // Tür filtresi
    if (selectedAnimalType != 'Tümü' &&
        animal.animalType.toLowerCase() != selectedAnimalType.toLowerCase()) {
      print(
          '❌ Filtrelendi: Tür "${animal.animalType}" != "${selectedAnimalType}"');
      return false;
    }

    // Şehir filtresi
    if (selectedCity != 'Tüm Şehirler' && animal.city != selectedCity) {
      print('❌ Filtrelendi: Şehir "${animal.city}" != "${selectedCity}"');
      print(
          '🔍 Şehir karşılaştırması: "${animal.city}" (${animal.city.length} karakter) vs "${selectedCity}" (${selectedCity.length} karakter)');
      print(
          '🔍 Şehir kodları: ${animal.city.codeUnits} vs ${selectedCity.codeUnits}');
      return false;
    }

    // Debug: Log when city filter is applied and animal passes
    if (selectedCity != 'Tüm Şehirler') {
      print('✅ Şehir filtresi geçti: ${animal.city} == ${selectedCity}');
    }

    // Fiyat filtresi
    if (animal.priceInTL < priceRange.start ||
        animal.priceInTL > priceRange.end) {
      print(
          '❌ Filtrelendi: Fiyat ${animal.priceInTL} aralık dışında (${priceRange.start}-${priceRange.end})');
      return false;
    }

    // Yaş filtresi
    if (animal.ageInMonths < ageRange.start ||
        animal.ageInMonths > ageRange.end) {
      print(
          '❌ Filtrelendi: Yaş ${animal.ageInMonths} aralık dışında (${ageRange.start}-${ageRange.end})');
      return false;
    }

    // Cinsiyet filtresi
    if (selectedGender != 'Tümü' && animal.gender != selectedGender) {
      print(
          '❌ Filtrelendi: Cinsiyet "${animal.gender}" != "${selectedGender}"');
      return false;
    }

    // Sağlık durumu filtresi
    if (selectedHealthStatus != 'Tümü' &&
        animal.healthStatus != selectedHealthStatus) {
      print(
          '❌ Filtrelendi: Sağlık durumu "${animal.healthStatus}" != "${selectedHealthStatus}"');
      return false;
    }

    // Acil satış filtresi
    if (showUrgentOnly && !animal.isUrgentSale) {
      print('❌ Filtrelendi: Acil satış değil (${animal.isUrgentSale})');
      return false;
    }

    print(
        '✅ Geçti: ${animal.postId} - ${animal.animalSpecies} - ${animal.animalBreed}');
    return true;
  }

  Widget _buildGridView(List<AnimalPost> animals) {
    return MasonryGridView.count(
      crossAxisCount: 2,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      padding: EdgeInsets.all(8),
      itemCount: animals.length,
      itemBuilder: (context, index) {
        return AnimalCard(
          animal: animals[index],
          isGridView: true,
          onTap: () => _navigateToAnimalDetail(animals[index]),
          onFavorite: () => _toggleFavorite(animals[index]),
          onShare: () => _shareAnimal(animals[index]),
        );
      },
    );
  }

  Widget _buildListView(List<AnimalPost> animals) {
    return ListView.builder(
      padding: EdgeInsets.all(8),
      itemCount: animals.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: EdgeInsets.only(bottom: 8),
          child: AnimalCard(
            animal: animals[index],
            isGridView: false,
            onTap: () => _navigateToAnimalDetail(animals[index]),
            onFavorite: () => _toggleFavorite(animals[index]),
            onShare: () => _shareAnimal(animals[index]),
          ),
        );
      },
    );
  }

  Widget _buildViewToggle() {
    return FloatingActionButton(
      backgroundColor: primaryColor,
      elevation: 4,
      child: Icon(
        isGridView ? Icons.list : Icons.grid_view,
        color: Colors.white,
        size: 24,
      ),
      onPressed: () {
        setState(() {
          isGridView = !isGridView;
        });
      },
    );
  }

  void _navigateToAnimalDetail(AnimalPost animal) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AnimalDetailScreen(animal: animal),
      ),
    );
  }

  void _toggleFavorite(AnimalPost animal) {
    // TODO: Implement favorite functionality
    print('Toggle favorite for ${animal.postId}');
  }

  void _shareAnimal(AnimalPost animal) {
    // TODO: Implement share functionality
    print('Share ${animal.postId}');
  }

  void _clearAllFilters() {
    setState(() {
      selectedCategory = 'Tüm Hayvanlar';
      selectedAnimalType = 'Tümü';
      searchQuery = '';
      priceRange = RangeValues(0, 500000);
      ageRange = RangeValues(0, 120);
      selectedGender = 'Tümü';
      selectedHealthStatus = 'Tümü';
      selectedCity = 'Tüm Şehirler';
      showUrgentOnly = false;
      showFilters = false;
      _searchController.clear();
      _filtersModified = false;
    });
  }

  bool _matchesCategory(AnimalPost animal, String category) {
    switch (category) {
      // Tür bazlı kategoriler
      case 'Süt Sığırı':
        return animal.animalSpecies.toLowerCase() == 'sığır' &&
            (animal.purpose.toLowerCase().contains('süt') ||
                animal.animalBreed.toLowerCase().contains('holstein') ||
                animal.animalBreed.toLowerCase().contains('jersey'));

      case 'Et Sığırı':
        return animal.animalSpecies.toLowerCase() == 'sığır' &&
            (animal.purpose.toLowerCase().contains('et') ||
                animal.animalBreed.toLowerCase().contains('angus') ||
                animal.animalBreed.toLowerCase().contains('charolais'));

      case 'Damızlık Boğa':
        return animal.animalSpecies.toLowerCase() == 'sığır' &&
            animal.gender.toLowerCase() == 'erkek' &&
            animal.purpose.toLowerCase().contains('damızlık');

      case 'Düve':
        return animal.animalSpecies.toLowerCase() == 'sığır' &&
            animal.gender.toLowerCase() == 'dişi' &&
            animal.ageInMonths < 24;

      case 'Manda':
        return animal.animalSpecies.toLowerCase() == 'manda';

      case 'Tosun':
        return animal.animalSpecies.toLowerCase() == 'sığır' &&
            animal.gender.toLowerCase() == 'erkek' &&
            animal.ageInMonths < 24;

      case 'Koyun':
        return animal.animalSpecies.toLowerCase() == 'koyun';

      case 'Keçi':
        return animal.animalSpecies.toLowerCase() == 'keçi';

      case 'Kuzu':
        return animal.animalSpecies.toLowerCase() == 'koyun' &&
            animal.ageInMonths < 12;

      case 'Oğlak':
        return animal.animalSpecies.toLowerCase() == 'keçi' &&
            animal.ageInMonths < 12;

      case 'Koç':
        return animal.animalSpecies.toLowerCase() == 'koyun' &&
            animal.gender.toLowerCase() == 'erkek';

      case 'Teke':
        return animal.animalSpecies.toLowerCase() == 'keçi' &&
            animal.gender.toLowerCase() == 'erkek';

      // Durum bazlı kategoriler
      case 'Gebe Hayvanlar':
        return animal.isPregnant == true;

      case 'Genç Hayvanlar':
        return animal.ageInMonths < 18;

      case 'Damızlık Hayvanlar':
        return animal.purpose.toLowerCase().contains('damızlık');

      case 'Acil Satış':
        return animal.isUrgentSale == true;

      case 'Süt Veren':
        return animal.purpose.toLowerCase().contains('süt');

      case 'Et İçin':
        return animal.purpose.toLowerCase().contains('et');

      case 'Organik Beslenmiş':
        return animal.additionalInfo != null &&
            animal.additionalInfo!.toString().toLowerCase().contains('organik');

      case 'Kanatlı':
        return animal.animalType.toLowerCase() == 'kanatlı' ||
            ['tavuk', 'hindi', 'kaz', 'ördek', 'bıldırcın', 'güvercin']
                .contains(animal.animalSpecies.toLowerCase());
      case 'Adaklık Hayvanlar':
        return (animal.purpose.toLowerCase().contains('adak') ||
            (animal.additionalInfo != null &&
                animal.additionalInfo
                    .toString()
                    .toLowerCase()
                    .contains('adak')));

      default:
        return true; // Bilinmeyen kategoriler için true döndür
    }
  }

  // Filtre değişikliklerinde sonuç sayısını güncelle
  void _onFilterChanged() {
    // Check if filters have been modified
    _filtersModified = _areFiltersModified();

    // Immediately recalculate filtered results from local data
    if (_allAnimals.isNotEmpty) {
      _filteredAnimals = _allAnimals.where(_filterAnimals).toList();
      filteredResultsCount = _filteredAnimals.length;
      print('🔄 Filtre değişti - Yeni sonuç sayısı: $filteredResultsCount');
      print('🔧 Filtreler değiştirildi: $_filtersModified');
    }
    // Trigger a rebuild to update the UI
    setState(() {});
  }

  // Çakışan filtreleri temizle
  void _clearConflictingFilters(String newFilterType, String newValue) {
    switch (newFilterType) {
      case 'animalType':
        // Hayvan türü değiştiğinde kategoriyi temizle
        if (newValue != 'Tümü') {
          selectedCategory = 'Tüm Hayvanlar';
          print('🧹 Hayvan türü değişti, kategori temizlendi');
        }
        break;
      case 'category':
        // Kategori değiştiğinde hayvan türünü temizle
        if (newValue != 'Tüm Hayvanlar') {
          selectedAnimalType = 'Tümü';
          print('🧹 Kategori değişti, hayvan türü temizlendi');
        }
        break;
    }
  }

  // Filtrelerin değiştirilip değiştirilmediğini kontrol et
  bool _areFiltersModified() {
    return selectedCategory != 'Tüm Hayvanlar' ||
        selectedAnimalType != 'Tümü' ||
        searchQuery.isNotEmpty ||
        selectedCity != 'Tüm Şehirler' ||
        selectedGender != 'Tümü' ||
        selectedHealthStatus != 'Tümü' ||
        showUrgentOnly ||
        priceRange.start > 0 ||
        priceRange.end < 500000 ||
        ageRange.start > 0 ||
        ageRange.end < 120;
  }

  // Aktif filtreleri göster
  Widget _buildActiveFiltersSummary() {
    List<String> activeFilters = [];

    if (selectedCategory != 'Tüm Hayvanlar') {
      activeFilters.add(selectedCategory);
    }
    if (selectedAnimalType != 'Tümü') {
      activeFilters.add(selectedAnimalType);
    }
    if (selectedCity != 'Tüm Şehirler') {
      activeFilters.add(selectedCity);
    }
    if (selectedGender != 'Tümü') {
      activeFilters.add(selectedGender);
    }
    if (selectedHealthStatus != 'Tümü') {
      activeFilters.add(selectedHealthStatus);
    }
    if (showUrgentOnly) {
      activeFilters.add('Acil Satış');
    }
    if (searchQuery.isNotEmpty) {
      activeFilters.add('Arama: "$searchQuery"');
    }
    if (priceRange.start > 0 || priceRange.end < 500000) {
      activeFilters.add(
          'Fiyat: ${PricingService.formatPrice(priceRange.start)} - ${PricingService.formatPrice(priceRange.end)}');
    }
    if (ageRange.start > 0 || ageRange.end < 120) {
      activeFilters
          .add('Yaş: ${ageRange.start.round()}-${ageRange.end.round()} ay');
    }

    if (activeFilters.isEmpty) return SizedBox.shrink();

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: primaryColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.filter_list, color: primaryColor, size: 16),
              SizedBox(width: 6),
              Text(
                'Aktif Filtreler ($filteredResultsCount sonuç)',
                style: GoogleFonts.poppins(
                  color: primaryColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Spacer(),
              TextButton(
                onPressed: _clearAllFilters,
                style: TextButton.styleFrom(
                  minimumSize: Size(0, 24),
                  padding: EdgeInsets.symmetric(horizontal: 8),
                ),
                child: Text(
                  'Temizle',
                  style: GoogleFonts.poppins(
                    color: warningColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: activeFilters
                .map((filter) => Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: primaryColor.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        filter,
                        style: GoogleFonts.poppins(
                          color: primaryColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}

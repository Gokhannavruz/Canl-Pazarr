import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'dart:typed_data';
import 'dart:async';
import '../utils/animal_categories.dart';
import '../services/pricing_service.dart';
import '../widgets/price_tag.dart';
import '../resources/animal_firestore_methods.dart';
import '../resources/auth_methods.dart';
import '../models/user.dart' as model;
import 'package:google_fonts/google_fonts.dart';

class AddAnimalScreen extends StatefulWidget {
  const AddAnimalScreen({Key? key}) : super(key: key);

  @override
  State<AddAnimalScreen> createState() => _AddAnimalScreenState();
}

class _AddAnimalScreenState extends State<AddAnimalScreen> {
  final _formKey = GlobalKey<FormState>();
  final PageController _pageController = PageController();
  int _currentStep = 0;
  bool _isLoading = false;

  // Form verileri
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();

  final TextEditingController _transportInfoController =
      TextEditingController();
  final TextEditingController _parentInfoController = TextEditingController();
  final TextEditingController _veterinarianContactController =
      TextEditingController();

  // Stream subscription for location updates
  StreamSubscription<DocumentSnapshot>? _locationSubscription;

  String _selectedAnimalType = AnimalCategories.animalTypes.first;
  String _selectedSpecies = AnimalCategories.animalSpecies.first;
  String _selectedBreed = ''; // Bu initState'de düzgün set edilecek
  String _selectedGender = AnimalCategories.genders.first;
  String _selectedHealthStatus = AnimalCategories.healthStatuses.first;
  String _selectedPurpose = AnimalCategories.purposes.first;
  String _selectedSellerType = AnimalCategories.sellerTypes.first;

  bool _isPregnant = false;
  bool _isNegotiable = false;
  bool _isUrgentSale = false;

  List<File> _selectedImages = [];
  List<String> _selectedVaccinations = [];
  DateTime? _birthDate;

  // Adres bilgileri (mevcut kullanıcıdan alınacak)
  String _country = '';
  String _state = '';
  String _city = '';

  // AnimalDiscoverScreen'den alınan tasarım renkleri
  static const Color primaryColor = Color(0xFF2E7D32);
  static const Color warningColor = Color(0xFFFF9800);
  static const Color errorColor = Color(0xFFE53935);
  static const Color backgroundColor = Colors.white;
  static const Color surfaceColor = Color(0xFFF5F5F5);
  static const Color textPrimary = Color(0xFF000000);
  static const Color textSecondary = Color(0xFF424242);
  static const Color dividerColor = Color(0xFFE0E0E0);

  // Responsive helper methods
  bool get isSmallScreen => MediaQuery.of(context).size.width < 360;
  bool get isMediumScreen =>
      MediaQuery.of(context).size.width >= 360 &&
      MediaQuery.of(context).size.width < 600;
  bool get isLargeScreen => MediaQuery.of(context).size.width >= 600;

  @override
  void initState() {
    super.initState();
    _loadUserLocation();

    // Breed'i doğru şekilde initialize et
    final availableBreeds =
        AnimalCategories.getBreedsForSpecies(_selectedSpecies);
    if (availableBreeds.isNotEmpty) {
      _selectedBreed = availableBreeds.first;
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _priceController.dispose();
    _weightController.dispose();

    _transportInfoController.dispose();
    _parentInfoController.dispose();
    _veterinarianContactController.dispose();
    _pageController.dispose();

    // Cancel location subscription
    _locationSubscription?.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: _isLoading
          ? _buildLoadingWidget()
          : SafeArea(
              child: Column(
                children: [
                  _buildModernAppBar(),
                  _buildModernProgressIndicator(),
                  Expanded(
                    child: Container(
                      margin: EdgeInsets.symmetric(horizontal: 8),
                      child: PageView(
                        controller: _pageController,
                        onPageChanged: (index) {
                          setState(() {
                            _currentStep = index;
                          });
                        },
                        children: [
                          _buildBasicInfoStep(),
                          _buildAnimalDetailsStep(),
                          _buildHealthInfoStep(),
                          _buildPriceAndPhotosStep(),
                          _buildReviewStep(),
                        ],
                      ),
                    ),
                  ),
                  _buildModernNavigationButtons(),
                ],
              ),
            ),
    );
  }

  Widget _buildModernAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: backgroundColor,
      automaticallyImplyLeading: false,
      centerTitle: true,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'İlan Ekle',
            style: GoogleFonts.poppins(
              color: primaryColor,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios_new, color: primaryColor),
        onPressed: () {
          if (Navigator.canPop(context)) {
            Navigator.pop(context);
          } else {
            Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
          }
        },
      ),
    );
  }

  String _getStepTitle(int step) {
    switch (step) {
      case 0:
        return 'Temel Bilgiler';
      case 1:
        return 'Hayvan Detayları';
      case 2:
        return 'Sağlık Bilgileri';
      case 3:
        return 'Fiyat ve Fotoğraflar';
      case 4:
        return 'Önizleme';
      default:
        return '';
    }
  }

  Widget _buildLoadingWidget() {
    return Container(
      color: backgroundColor,
      child: Center(
        child: Container(
          padding: EdgeInsets.all(40),
          margin: EdgeInsets.symmetric(horizontal: 32),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                spreadRadius: 2,
                blurRadius: 15,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Animated loading indicator
              Container(
                width: 80,
                height: 80,
                child: Stack(
                  children: [
                    // Outer circle
                    SizedBox(
                      width: 80,
                      height: 80,
                      child: CircularProgressIndicator(
                        strokeWidth: 6,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          primaryColor.withOpacity(0.3),
                        ),
                      ),
                    ),
                    // Inner circle
                    SizedBox(
                      width: 80,
                      height: 80,
                      child: CircularProgressIndicator(
                        strokeWidth: 4,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          warningColor,
                        ),
                      ),
                    ),
                    // Center icon
                    Center(
                      child: Icon(
                        Icons.pets,
                        color: primaryColor,
                        size: 32,
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 24),

              Text(
                'İlanınız Yayınlanıyor',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),

              SizedBox(height: 8),

              Text(
                'Lütfen bekleyiniz...',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: textSecondary,
                ),
              ),

              SizedBox(height: 16),

              // Progress dots
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (index) {
                  return Container(
                    margin: EdgeInsets.symmetric(horizontal: 4),
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: warningColor.withOpacity(
                        0.3 + (index * 0.2),
                      ),
                      shape: BoxShape.circle,
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernProgressIndicator() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        children: [
          // Step indicators
          Row(
            children: List.generate(5, (index) {
              bool isCompleted = index < _currentStep;
              bool isCurrent = index == _currentStep;

              return Expanded(
                child: Row(
                  children: [
                    // Step circle
                    AnimatedContainer(
                      duration: Duration(milliseconds: 300),
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isCompleted
                            ? warningColor
                            : isCurrent
                                ? primaryColor
                                : dividerColor,
                        border: Border.all(
                          color: isCompleted
                              ? warningColor
                              : isCurrent
                                  ? primaryColor
                                  : dividerColor,
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: isCompleted
                            ? Icon(Icons.check, color: Colors.white, size: 16)
                            : Text(
                                '${index + 1}',
                                style: GoogleFonts.poppins(
                                  color:
                                      isCurrent ? Colors.white : textSecondary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                      ),
                    ),

                    // Progress line
                    if (index < 4)
                      Expanded(
                        child: AnimatedContainer(
                          duration: Duration(milliseconds: 300),
                          height: 2,
                          margin: EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            color: isCompleted ? warningColor : dividerColor,
                            borderRadius: BorderRadius.circular(1),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            }),
          ),

          SizedBox(height: 8),

          // Progress percentage
          Text(
            '${((_currentStep + 1) / 5 * 100).round()}% Tamamlandı',
            style: GoogleFonts.poppins(
              color: textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfoStep() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            // Header card - AnimalDiscoverScreen stilinde
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: primaryColor.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.pets, color: primaryColor, size: 24),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Temel Bilgiler',
                          style: GoogleFonts.poppins(
                            color: textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'Hayvanınızın temel özelliklerini girin',
                          style: GoogleFonts.poppins(
                            color: textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 20),

            // Animal type selection cards - AnimalDiscoverScreen stilinde
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: dividerColor,
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    spreadRadius: 1,
                    blurRadius: 10,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.category, color: primaryColor, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Hayvan Bilgileri',
                        style: GoogleFonts.poppins(
                          color: textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  _buildModernDropdownField(
                    label: 'Hayvan Türü',
                    value: _selectedAnimalType,
                    items: AnimalCategories.animalTypes,
                    icon: Icons.category,
                    onChanged: (value) {
                      setState(() {
                        _selectedAnimalType = value!;
                        final availableSpecies =
                            AnimalCategories.getSpeciesForType(value);
                        if (!availableSpecies.contains(_selectedSpecies)) {
                          _selectedSpecies = availableSpecies.first;
                        }

                        // Breed'i de kontrol et ve gerekirse reset et
                        final availableBreeds =
                            AnimalCategories.getBreedsForSpecies(
                                _selectedSpecies);
                        if (!availableBreeds.contains(_selectedBreed)) {
                          _selectedBreed = availableBreeds.first;
                        }
                      });
                    },
                  ),
                  SizedBox(height: 16),
                  _buildModernDropdownField(
                    label: 'Tür',
                    value: _selectedSpecies,
                    items:
                        AnimalCategories.getSpeciesForType(_selectedAnimalType),
                    icon: Icons.pets,
                    onChanged: (value) {
                      setState(() {
                        _selectedSpecies = value!;
                        final availableBreeds =
                            AnimalCategories.getBreedsForSpecies(value);
                        if (!availableBreeds.contains(_selectedBreed)) {
                          _selectedBreed = availableBreeds.first;
                        }
                      });
                    },
                  ),
                  SizedBox(height: 16),
                  _buildModernDropdownField(
                    label: 'Irk',
                    value: _selectedBreed,
                    items:
                        AnimalCategories.getBreedsForSpecies(_selectedSpecies),
                    icon: Icons.star,
                    onChanged: (value) {
                      print('🔍 Breed changed to: $value');
                      setState(() {
                        _selectedBreed = value!;
                      });
                      print('🔍 Breed set to: $_selectedBreed');
                    },
                  ),
                  SizedBox(height: 16),
                  _buildModernDropdownField(
                    label: 'Cinsiyet',
                    value: _selectedGender,
                    items: AnimalCategories.genders,
                    icon:
                        _selectedGender == 'Erkek' ? Icons.male : Icons.female,
                    onChanged: (value) {
                      setState(() {
                        _selectedGender = value!;
                      });
                    },
                  ),
                ],
              ),
            ),

            SizedBox(height: 20),

            // Description card - AnimalDiscoverScreen stilinde
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: dividerColor,
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    spreadRadius: 1,
                    blurRadius: 10,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.description, color: primaryColor, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Açıklama',
                        style: GoogleFonts.poppins(
                          color: textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  // Description field with character counter
                  StatefulBuilder(
                    builder: (context, setState) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: surfaceColor,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: dividerColor),
                            ),
                            child: TextFormField(
                              controller: _descriptionController,
                              style: GoogleFonts.poppins(
                                color: textPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                              decoration: InputDecoration(
                                labelText: 'Hayvan Açıklaması',
                                labelStyle: GoogleFonts.poppins(
                                  color: textSecondary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                                hintText:
                                    'Hayvanınızın özelliklerini, sağlık durumunu ve diğer önemli detayları paylaşın...',
                                hintStyle: GoogleFonts.poppins(
                                  color: textSecondary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w400,
                                ),
                                prefixIcon: Icon(Icons.description,
                                    color: primaryColor, size: 18),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                              ),
                              maxLines: 4,
                              onChanged: (value) {
                                setState(() {}); // Karakter sayısını güncelle
                              },
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Açıklama gereklidir';
                                }
                                if (value.length < 20) {
                                  return 'Açıklama en az 20 karakter olmalıdır';
                                }
                                return null;
                              },
                            ),
                          ),
                          SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Minimum 20 karakter gerekli',
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  color: textSecondary,
                                ),
                              ),
                              Text(
                                '${_descriptionController.text.length}/20',
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  color:
                                      _descriptionController.text.length >= 20
                                          ? Colors.green
                                          : errorColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),

            SizedBox(height: 80), // Navigation button space
          ],
        ),
      ),
    );
  }

  Widget _buildAnimalDetailsStep() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          // Header card - AnimalDiscoverScreen stilinde
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: primaryColor.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child:
                      Icon(Icons.info_outline, color: primaryColor, size: 24),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hayvan Detayları',
                        style: GoogleFonts.poppins(
                          color: textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Yaş, ağırlık ve diğer detayları girin',
                        style: GoogleFonts.poppins(
                          color: textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 20),

          // Yaş ve doğum tarihi card
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: dividerColor,
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  spreadRadius: 1,
                  blurRadius: 10,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.cake, color: primaryColor, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Yaş Bilgileri',
                      style: GoogleFonts.poppins(
                        color: textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),

                // Yaş gösterimi
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: dividerColor),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.cake, color: textSecondary, size: 20),
                      SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Yaş',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: textSecondary,
                            ),
                          ),
                          Text(
                            _birthDate != null
                                ? '${_calculateAgeInMonths(_birthDate!)} ay'
                                : 'Doğum tarihini seçin',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 12),

                // Doğum tarihi seçici
                InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now().subtract(Duration(days: 365)),
                      firstDate:
                          DateTime.now().subtract(Duration(days: 365 * 20)),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      setState(() {
                        _birthDate = date;
                      });
                    }
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: surfaceColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: dividerColor),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today,
                            color: primaryColor, size: 20),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Doğum Tarihi',
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  color: textSecondary,
                                ),
                              ),
                              Text(
                                _birthDate != null
                                    ? '${_birthDate!.day}/${_birthDate!.month}/${_birthDate!.year}'
                                    : 'Doğum tarihini seçin',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.arrow_forward_ios,
                            color: textSecondary, size: 16),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 20),

          // Ağırlık ve amaç card
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: dividerColor,
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  spreadRadius: 1,
                  blurRadius: 10,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.monitor_weight, color: primaryColor, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Fiziksel Özellikler',
                      style: GoogleFonts.poppins(
                        color: textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),

                // Ağırlık
                Container(
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: dividerColor),
                  ),
                  child: TextFormField(
                    controller: _weightController,
                    style: GoogleFonts.poppins(
                      color: textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Ağırlık (kg)',
                      labelStyle: GoogleFonts.poppins(
                        color: textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                      prefixIcon: Icon(Icons.monitor_weight,
                          color: primaryColor, size: 18),
                      suffixText: 'kg',
                      suffixStyle: GoogleFonts.poppins(
                        color: textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                      border: InputBorder.none,
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Ağırlık gereklidir';
                      }
                      final weight = double.tryParse(value);
                      if (weight == null || weight < 0 || weight > 2000) {
                        return 'Geçerli bir ağırlık girin (0-2000 kg)';
                      }
                      return null;
                    },
                  ),
                ),

                SizedBox(height: 16),

                // Amaç
                _buildModernDropdownField(
                  label: 'Amaç',
                  value: _selectedPurpose,
                  items: AnimalCategories.purposes,
                  icon: Icons.flag,
                  onChanged: (value) {
                    setState(() {
                      _selectedPurpose = value!;
                    });
                  },
                ),

                // Hamilelik durumu (sadece dişi hayvanlar için)
                if (_selectedGender == 'Dişi') ...[
                  SizedBox(height: 16),
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: surfaceColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: dividerColor),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.pregnant_woman,
                            color: primaryColor, size: 20),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Gebe',
                            style: GoogleFonts.poppins(
                              color: textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Switch(
                          value: _isPregnant,
                          onChanged: (value) {
                            setState(() {
                              _isPregnant = value;
                            });
                          },
                          activeColor: primaryColor,
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          SizedBox(height: 20),

          // Ebeveyn bilgisi card
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: dividerColor,
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  spreadRadius: 1,
                  blurRadius: 10,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.family_restroom, color: primaryColor, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Ebeveyn Bilgisi (Opsiyonel)',
                      style: GoogleFonts.poppins(
                        color: textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: dividerColor),
                  ),
                  child: TextFormField(
                    controller: _parentInfoController,
                    style: GoogleFonts.poppins(
                      color: textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Anne/baba ırk bilgileri',
                      labelStyle: GoogleFonts.poppins(
                        color: textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                      hintText: 'Anne/baba ırk bilgileri...',
                      hintStyle: GoogleFonts.poppins(
                        color: textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                      ),
                      prefixIcon: Icon(Icons.family_restroom,
                          color: primaryColor, size: 18),
                      border: InputBorder.none,
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    maxLines: 2,
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 80), // Navigation button space
        ],
      ),
    );
  }

  Widget _buildHealthInfoStep() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          // Header card - AnimalDiscoverScreen stilinde
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: primaryColor.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.health_and_safety,
                      color: primaryColor, size: 24),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sağlık Bilgileri',
                        style: GoogleFonts.poppins(
                          color: textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Sağlık durumu ve aşı bilgilerini girin',
                        style: GoogleFonts.poppins(
                          color: textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 20),

          // Sağlık durumu card
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: dividerColor,
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  spreadRadius: 1,
                  blurRadius: 10,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.health_and_safety,
                        color: primaryColor, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Sağlık Durumu',
                      style: GoogleFonts.poppins(
                        color: textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                _buildModernDropdownField(
                  label: 'Sağlık Durumu',
                  value: _selectedHealthStatus,
                  items: AnimalCategories.healthStatuses,
                  icon: Icons.health_and_safety,
                  onChanged: (value) {
                    setState(() {
                      _selectedHealthStatus = value!;
                    });
                  },
                ),
              ],
            ),
          ),

          SizedBox(height: 20),

          // Aşılar card
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: dividerColor,
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  spreadRadius: 1,
                  blurRadius: 10,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.vaccines, color: primaryColor, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Yapılan Aşılar',
                      style: GoogleFonts.poppins(
                        color: textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: AnimalCategories.vaccineTypes.map((vaccine) {
                    final isSelected = _selectedVaccinations.contains(vaccine);
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          if (isSelected) {
                            _selectedVaccinations.remove(vaccine);
                          } else {
                            _selectedVaccinations.add(vaccine);
                          }
                        });
                      },
                      child: Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? primaryColor : surfaceColor,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected ? primaryColor : dividerColor,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isSelected)
                              Icon(
                                Icons.check_circle,
                                color: Colors.white,
                                size: 16,
                              ),
                            if (isSelected) SizedBox(width: 6),
                            Text(
                              vaccine,
                              style: GoogleFonts.poppins(
                                color: isSelected ? Colors.white : textPrimary,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),

          SizedBox(height: 20),

          // Veteriner iletişim card - Kompakt versiyon
          Container(
            padding: EdgeInsets.all(16),
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
                  spreadRadius: 1,
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
                    Icon(Icons.medical_services, color: primaryColor, size: 18),
                    SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Veteriner İletişim (Opsiyonel)',
                        style: GoogleFonts.poppins(
                          color: textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: dividerColor),
                  ),
                  child: TextFormField(
                    controller: _veterinarianContactController,
                    style: GoogleFonts.poppins(
                      color: textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Veteriner bilgileri',
                      labelStyle: GoogleFonts.poppins(
                        color: textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                      hintText: 'Adı ve telefon numarası...',
                      hintStyle: GoogleFonts.poppins(
                        color: textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                      ),
                      prefixIcon: Icon(Icons.medical_services,
                          color: primaryColor, size: 16),
                      border: InputBorder.none,
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 60), // Navigation button space - azaltıldı
        ],
      ),
    );
  }

  Widget _buildPriceAndPhotosStep() {
    return Padding(
      padding: EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Fiyat ve Fotoğraflar',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
            ),
            SizedBox(height: 20),

            // Fiyat
            Container(
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: dividerColor),
              ),
              child: TextFormField(
                controller: _priceController,
                style: GoogleFonts.poppins(
                  color: textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  labelText: 'Fiyat (TL)',
                  labelStyle: GoogleFonts.poppins(
                    color: textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  prefixIcon:
                      Icon(Icons.attach_money, color: primaryColor, size: 18),
                  prefixText: '₺ ',
                  prefixStyle: GoogleFonts.poppins(
                    color: textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  border: InputBorder.none,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Fiyat gereklidir';
                  }
                  final price = double.tryParse(value);
                  if (price == null || price < 0) {
                    return 'Geçerli bir fiyat girin';
                  }
                  if (!PricingService.validatePrice(
                      price, _selectedAnimalType.toLowerCase())) {
                    return 'Fiyat ${_selectedAnimalType.toLowerCase()} için uygun değil';
                  }
                  return null;
                },
                onChanged: (value) {
                  setState(() {});
                },
              ),
            ),

            // Fiyat önizlemesi
            if (_priceController.text.isNotEmpty) ...[
              SizedBox(height: 8),
              PriceTag(
                price: double.tryParse(_priceController.text) ?? 0,
                isNegotiable: _isNegotiable,
                isUrgent: _isUrgentSale,
              ),
            ],

            SizedBox(height: 16),

            // Pazarlık ve acil satış
            SwitchListTile(
              title: Text('Pazarlık Yapılabilir'),
              value: _isNegotiable,
              onChanged: (value) {
                setState(() {
                  _isNegotiable = value;
                });
              },
              activeColor: primaryColor,
            ),

            SwitchListTile(
              title: Text('Acil Satış'),
              value: _isUrgentSale,
              onChanged: (value) {
                setState(() {
                  _isUrgentSale = value;
                });
              },
              activeColor: warningColor,
            ),

            SizedBox(height: 16),

            // Satıcı tipi
            _buildModernDropdownField(
              label: 'Satıcı Tipi',
              value: _selectedSellerType,
              items: AnimalCategories.sellerTypes,
              icon: Icons.business,
              onChanged: (value) {
                setState(() {
                  _selectedSellerType = value!;
                });
              },
            ),

            SizedBox(height: 16),

            // Nakliye bilgisi
            Container(
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: dividerColor),
              ),
              child: TextFormField(
                controller: _transportInfoController,
                style: GoogleFonts.poppins(
                  color: textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  labelText: 'Nakliye Bilgisi',
                  labelStyle: GoogleFonts.poppins(
                    color: textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  hintText: 'Nakliye şartları ve bilgileri...',
                  hintStyle: GoogleFonts.poppins(
                    color: textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                  prefixIcon:
                      Icon(Icons.local_shipping, color: primaryColor, size: 18),
                  border: InputBorder.none,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                maxLines: 2,
              ),
            ),

            SizedBox(height: 20),

            // Fotoğraf seçimi
            Text(
              'Fotoğraflar (En az 3 adet, en fazla 10)',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            _buildPhotoSelector(),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewStep() {
    return Padding(
      padding: EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Kompakt header
            Row(
              children: [
                Icon(Icons.preview, color: primaryColor, size: 20),
                SizedBox(width: 8),
                Text(
                  'İlan Önizleme',
                  style: GoogleFonts.poppins(
                    color: textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),

            SizedBox(height: 16),

            // İlan önizlemesi - Modern card tasarımı
            Container(
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: dividerColor,
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    spreadRadius: 1,
                    blurRadius: 10,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Başlık bölümü
                  Container(
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: surfaceColor,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(14),
                        topRight: Radius.circular(14),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                '$_selectedBreed $_selectedSpecies',
                                style: GoogleFonts.poppins(
                                  color: textPrimary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            // Fiyat (küçük)
                            if (_priceController.text.isNotEmpty)
                              Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  gradient: _isUrgentSale
                                      ? LinearGradient(
                                          colors: [
                                            Color(0xFFE91E63),
                                            Color(0xFFC2185B)
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        )
                                      : LinearGradient(
                                          colors: [
                                            Color(0xFF2E7D32),
                                            Color(0xFF388E3C)
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  PricingService.formatPrice(
                                      double.tryParse(_priceController.text) ??
                                          0),
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        SizedBox(height: 8),

                        // Temel bilgiler - Kompakt chip'ler
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: primaryColor.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                _selectedAnimalType,
                                style: GoogleFonts.poppins(
                                  color: primaryColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            SizedBox(width: 6),
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: _selectedGender == 'Erkek'
                                    ? Color(0xFF2196F3).withOpacity(0.1)
                                    : Color(0xFFE91E63).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _selectedGender == 'Erkek'
                                      ? Color(0xFF2196F3).withOpacity(0.3)
                                      : Color(0xFFE91E63).withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                _selectedGender,
                                style: GoogleFonts.poppins(
                                  color: _selectedGender == 'Erkek'
                                      ? Color(0xFF2196F3)
                                      : Color(0xFFE91E63),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // İçerik bölümü - Kompakt
                  Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Açıklama - Kompakt
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.description,
                                color: primaryColor, size: 16),
                            SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Açıklama',
                                    style: GoogleFonts.poppins(
                                      color: textPrimary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    _descriptionController.text.isEmpty
                                        ? 'Açıklama girilmemiş'
                                        : _descriptionController.text,
                                    style: GoogleFonts.poppins(
                                      color: _descriptionController.text.isEmpty
                                          ? textSecondary
                                          : textPrimary,
                                      fontSize: 11,
                                    ),
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: 12),

                        // Fotoğraf sayısı - Kompakt
                        Row(
                          children: [
                            Icon(Icons.photo_library,
                                color: primaryColor, size: 16),
                            SizedBox(width: 8),
                            Text(
                              'Fotoğraflar: ',
                              style: GoogleFonts.poppins(
                                color: textPrimary,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: _selectedImages.length >= 3
                                    ? primaryColor.withOpacity(0.1)
                                    : warningColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: _selectedImages.length >= 3
                                      ? primaryColor.withOpacity(0.3)
                                      : warningColor.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                '${_selectedImages.length}/10',
                                style: GoogleFonts.poppins(
                                  color: _selectedImages.length >= 3
                                      ? primaryColor
                                      : warningColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
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

            SizedBox(height: 16),

            // Kompakt uyarı
            if (_selectedImages.length < 3)
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: warningColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: warningColor.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded,
                        color: warningColor, size: 16),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'En az 3 fotoğraf eklemeniz önerilir',
                        style: GoogleFonts.poppins(
                          color: warningColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
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

  Widget _buildPhotoSelector() {
    return Column(
      children: [
        // Seçilen fotoğraflar
        if (_selectedImages.isNotEmpty) ...[
          Container(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _selectedImages.length + 1,
              itemBuilder: (context, index) {
                if (index == _selectedImages.length) {
                  return _buildAddPhotoButton();
                }
                return _buildPhotoItem(_selectedImages[index], index);
              },
            ),
          ),
        ] else ...[
          _buildAddPhotoButton(),
        ],

        SizedBox(height: 8),
        Text(
          'Seçilen: ${_selectedImages.length}/10',
          style: TextStyle(color: textSecondary),
        ),
      ],
    );
  }

  Widget _buildAddPhotoButton() {
    return Container(
      width: 100,
      height: 100,
      margin: EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        border: Border.all(color: dividerColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: InkWell(
        onTap: _pickImages,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_a_photo, color: textSecondary),
            Text('Fotoğraf\nEkle', textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoItem(File photo, int index) {
    return Container(
      width: 100,
      height: 100,
      margin: EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        image: DecorationImage(
          image: FileImage(photo),
          fit: BoxFit.cover,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: () => _removePhoto(index),
              child: Container(
                decoration: BoxDecoration(
                  color: errorColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernNavigationButtons() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            spreadRadius: 1,
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            if (_currentStep > 0)
              Expanded(
                child: Container(
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: _previousStep,
                    icon: Icon(Icons.arrow_back_ios, size: 16),
                    label: Text(
                      'Önceki',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: primaryColor,
                      side: BorderSide(color: primaryColor),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ),
            if (_currentStep > 0) SizedBox(width: 12),
            Expanded(
              flex: _currentStep > 0 ? 1 : 2,
              child: Container(
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _currentStep == 4
                      ? _publishListing
                      : () {
                          print('🔘 Sonraki button pressed!');
                          _nextStep();
                        },
                  icon: Icon(
                    _currentStep == 4
                        ? Icons.publish_rounded
                        : Icons.arrow_forward_ios,
                    size: 16,
                  ),
                  label: Text(
                    _currentStep == 4 ? 'İlanı Yayınla' : 'Sonraki',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        _currentStep == 4 ? warningColor : primaryColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _loadUserLocation() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        _locationSubscription = FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .snapshots()
            .listen((event) {
          if (!mounted) return;

          if (event.exists && event.data() != null) {
            final data = event.data() as Map<String, dynamic>;
            setState(() {
              _country = data['country'] as String? ?? '';
              _state = data['state'] as String? ?? '';
              _city = data['city'] as String? ?? '';
            });
          } else {
            setState(() {
              _country = '';
              _state = '';
              _city = '';
            });
          }
        });
      } catch (e) {
        print('Error loading user location: $e');
        // Hata durumunda varsayılan değerler
        setState(() {
          _country = '';
          _state = '';
          _city = '';
        });
      }
    }
  }

  int _calculateAgeInMonths(DateTime birthDate) {
    final now = DateTime.now();
    int months = (now.year - birthDate.year) * 12;
    months += now.month - birthDate.month;

    // Eğer gün henüz gelmemişse bir ay çıkar
    if (now.day < birthDate.day) {
      months--;
    }

    return months.clamp(0, 240); // 0-240 ay arası sınırla
  }

  void _nextStep() {
    print('🚀 _nextStep called, current step: $_currentStep');
    if (_currentStep < 4) {
      print('🔍 Calling _validateCurrentStep...');
      if (_validateCurrentStep()) {
        print('✅ Validation passed, navigating to next step');
        _pageController.nextPage(
          duration: Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      } else {
        print('❌ Validation failed, staying on current step');
      }
    } else {
      print('⚠️ Already at last step');
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  bool _validateCurrentStep() {
    print('🔍 Validating step $_currentStep');
    print(
        '🔍 Current values - Type: $_selectedAnimalType, Species: $_selectedSpecies, Breed: $_selectedBreed');

    switch (_currentStep) {
      case 0: // Temel bilgiler
        // Description kontrolü
        final description = _descriptionController.text;
        print('🔍 Description length: ${description.length}');
        print('🔍 Description: "$description"');

        if (description.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Hayvan açıklaması gereklidir'),
              backgroundColor: errorColor,
            ),
          );
          return false;
        }

        if (description.length < 20) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Açıklama en az 20 karakter olmalıdır (Şu an: ${description.length} karakter)'),
              backgroundColor: warningColor,
            ),
          );
          return false;
        }

        // Dropdown'ları kontrol et
        if (_selectedBreed.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Lütfen hayvan ırkını seçiniz'),
              backgroundColor: errorColor,
            ),
          );
          return false;
        }

        final isValid = _formKey.currentState?.validate() ?? false;
        print('🔍 Form validation result: $isValid');

        if (isValid) {
          print('✅ All validations passed for step 0');
        } else {
          print('❌ Form validation failed');
        }

        return isValid;

      case 1: // Hayvan detayları
        if (_birthDate == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Doğum tarihi gereklidir')),
          );
          return false;
        }

        if (_weightController.text.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Ağırlık gereklidir')),
          );
          return false;
        }

        final weight = double.tryParse(_weightController.text);
        if (weight == null || weight < 0 || weight > 2000) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Geçerli bir ağırlık girin (0-2000 kg)')),
          );
          return false;
        }

        // Doğum tarihi gelecekte olamaz
        if (_birthDate!.isAfter(DateTime.now())) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Doğum tarihi gelecekte olamaz')),
          );
          return false;
        }

        // Yaş çok büyük olamaz
        final age = _calculateAgeInMonths(_birthDate!);
        if (age > 240) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Hayvan yaşı çok büyük (max 20 yıl)')),
          );
          return false;
        }

        return true;

      case 2: // Sağlık bilgileri
        return true; // Opsiyonel

      case 3: // Fiyat ve fotoğraflar
        if (_priceController.text.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Fiyat gereklidir')),
          );
          return false;
        }

        final price = double.tryParse(_priceController.text);
        if (price == null || price <= 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Geçerli bir fiyat girin')),
          );
          return false;
        }

        if (!PricingService.validatePrice(
            price, _selectedAnimalType.toLowerCase())) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    'Fiyat ${_selectedAnimalType.toLowerCase()} için uygun değil')),
          );
          return false;
        }

        if (_selectedImages.length < 3) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('En az 3 fotoğraf eklemelisiniz')),
          );
          return false;
        }

        return true;

      case 4: // Önizleme
        return true;

      default:
        return true;
    }
  }

  void _pickImages() async {
    if (_selectedImages.length >= 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('En fazla 10 fotoğraf seçebilirsiniz')),
      );
      return;
    }

    final ImagePicker picker = ImagePicker();
    final List<XFile> images = await picker.pickMultiImage();

    for (var image in images) {
      if (_selectedImages.length < 10) {
        setState(() {
          _selectedImages.add(File(image.path));
        });
      }
    }
  }

  void _removePhoto(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  void _publishListing() async {
    if (!_validateCurrentStep()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Fotoğrafları byte'lara çevir
      List<Uint8List> imageBytes = await _convertImagesToBytes();

      // İlan oluştur
      await _createAnimalPost(imageBytes);

      // Loading'i kapat
      setState(() {
        _isLoading = false;
      });

      // Başarı bildirimi göster
      _showSuccessDialog();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      _showErrorDialog(e.toString());
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return _buildSuccessDialog();
      },
    );
  }

  void _showErrorDialog(String error) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return _buildErrorDialog(error);
      },
    );
  }

  Future<List<Uint8List>> _convertImagesToBytes() async {
    List<Uint8List> imageBytes = [];

    for (File image in _selectedImages) {
      final bytes = await image.readAsBytes();
      imageBytes.add(bytes);
    }

    return imageBytes;
  }

  Future<void> _createAnimalPost(List<Uint8List> imageBytes) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Kullanıcı oturum açmamış');

    // Kullanıcı bilgilerini al
    final model.User userData = await AuthMethods().getUserDetails();

    // AnimalFirestoreMethods servisini kullan
    final String result = await AnimalFirestoreMethods().uploadAnimal(
      description: _descriptionController.text,
      files: imageBytes,
      uid: user.uid,
      username: userData.username?.isEmpty == true
          ? 'Bilinmeyen'
          : userData.username ?? 'Bilinmeyen',
      profImage: userData.photoUrl ?? '',
      country: _country,
      state: _state,
      city: _city,
      animalType: _selectedAnimalType.toLowerCase(),
      animalSpecies: _selectedSpecies,
      animalBreed: _selectedBreed,
      ageInMonths: _calculateAgeInMonths(_birthDate!),
      gender: _selectedGender,
      weightInKg: double.parse(_weightController.text),
      priceInTL: double.parse(_priceController.text),
      healthStatus: _selectedHealthStatus,
      vaccinations: _selectedVaccinations,
      purpose: _selectedPurpose,
      isPregnant: _isPregnant,
      birthDate: _birthDate,
      parentInfo: _parentInfoController.text.isEmpty
          ? null
          : _parentInfoController.text,
      certificates: [], // TODO: Implement certificate upload
      isNegotiable: _isNegotiable,
      sellerType: _selectedSellerType,
      transportInfo: _transportInfoController.text,
      isUrgentSale: _isUrgentSale,
      veterinarianContact: _veterinarianContactController.text.isEmpty
          ? null
          : _veterinarianContactController.text,
      additionalInfo: {},
    );

    if (result != "success") {
      throw Exception('Hayvan ilanı kaydedilemedi: $result');
    }
  }

  // Modern UI Helper Methods
  Widget _buildStepHeaderCard({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            primaryColor,
            primaryColor.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
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
        ],
      ),
    );
  }

  Widget _buildModernCard({required Widget child}) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            spreadRadius: 1,
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: primaryColor,
      ),
    );
  }

  Widget _buildModernDropdownField({
    required String label,
    required String value,
    required List<String> items,
    required IconData icon,
    required Function(String?) onChanged,
  }) {
    // Safety check: value items listesinde var mı?
    final safeValue =
        items.contains(value) ? value : (items.isNotEmpty ? items.first : null);
    if (safeValue != value) {
      print(
          '⚠️ Warning: $label dropdown value "$value" not in items list. Using "$safeValue" instead.');
    }
    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: dividerColor),
      ),
      child: DropdownButtonFormField<String>(
        value: safeValue,
        style: GoogleFonts.poppins(
          color: textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.poppins(
            color: textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: Icon(icon, color: primaryColor, size: 18),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        items: items
            .map((item) => DropdownMenuItem(
                  value: item,
                  child: Text(
                    item,
                    style: GoogleFonts.poppins(
                      color: textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ))
            .toList(),
        onChanged: onChanged,
        dropdownColor: surfaceColor,
      ),
    );
  }

  Widget _buildModernTextFormField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: dividerColor),
      ),
      child: TextFormField(
        controller: controller,
        style: GoogleFonts.poppins(
          color: textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.poppins(
            color: textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
          hintText: hint,
          hintStyle: GoogleFonts.poppins(
            color: textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w400,
          ),
          prefixIcon: Icon(icon, color: primaryColor, size: 18),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        maxLines: maxLines,
        validator: validator,
      ),
    );
  }

  Widget _buildSuccessDialog() {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              spreadRadius: 2,
              blurRadius: 15,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Success icon with animation
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: warningColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle,
                color: warningColor,
                size: 50,
              ),
            ),

            SizedBox(height: 20),

            Text(
              'İlan Başarıyla Yayınlandı!',
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
              textAlign: TextAlign.center,
            ),

            SizedBox(height: 12),

            Text(
              'Hayvan ilanınız başarıyla yayınlandı. Ana sayfada görünmeye başlayacak.',
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: textSecondary,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),

            SizedBox(height: 24),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop(); // Dialog'u kapat
                      // Form'u temizle ve başa dön
                      _resetForm();
                    },
                    icon: Icon(Icons.add_circle_outline),
                    label: Text('Yeni İlan'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: primaryColor,
                      side: BorderSide(color: primaryColor),
                      padding: EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop(); // Dialog'u kapat
                    },
                    icon: Icon(Icons.close),
                    label: Text('Kapat'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 12),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
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

  Widget _buildErrorDialog(String error) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              spreadRadius: 2,
              blurRadius: 15,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Error icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: errorColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline,
                color: errorColor,
                size: 50,
              ),
            ),

            SizedBox(height: 20),

            Text(
              'İlan Yayınlanamadı',
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: errorColor,
              ),
              textAlign: TextAlign.center,
            ),

            SizedBox(height: 12),

            Text(
              'Bir hata oluştu: $error',
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: textSecondary,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),

            SizedBox(height: 24),

            // Action button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).pop(); // Dialog'u kapat
                },
                icon: Icon(Icons.refresh),
                label: Text('Tekrar Dene'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: errorColor,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 12),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _resetForm() {
    setState(() {
      _currentStep = 0;
      _descriptionController.clear();
      _priceController.clear();
      _weightController.clear();
      _transportInfoController.clear();
      _parentInfoController.clear();
      _veterinarianContactController.clear();

      _selectedAnimalType = AnimalCategories.animalTypes.first;
      _selectedSpecies = AnimalCategories.animalSpecies.first;
      _selectedBreed = AnimalCategories.animalBreeds.first;
      _selectedGender = AnimalCategories.genders.first;
      _selectedHealthStatus = AnimalCategories.healthStatuses.first;
      _selectedPurpose = AnimalCategories.purposes.first;
      _selectedSellerType = AnimalCategories.sellerTypes.first;

      _isPregnant = false;
      _isNegotiable = false;
      _isUrgentSale = false;

      _selectedImages.clear();
      _selectedVaccinations.clear();
      _birthDate = null;
    });

    _pageController.animateToPage(
      0,
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }
}

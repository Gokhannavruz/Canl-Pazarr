import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/animal_post.dart';
import '../utils/animal_categories.dart';
import '../utils/animal_colors.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class EditAnimalScreen extends StatefulWidget {
  final AnimalPost animal;
  const EditAnimalScreen({Key? key, required this.animal}) : super(key: key);

  @override
  State<EditAnimalScreen> createState() => _EditAnimalScreenState();
}

class _EditAnimalScreenState extends State<EditAnimalScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _descriptionController;
  late TextEditingController _priceController;
  late TextEditingController _weightController;
  late TextEditingController _transportInfoController;
  late TextEditingController _parentInfoController;
  late TextEditingController _veterinarianContactController;
  late TextEditingController _ageController;
  late TextEditingController _certificatesController;
  late TextEditingController _additionalInfoController;
  DateTime _datePublished = DateTime.now();
  late List<String> _photoUrls;

  late String _selectedAnimalType;
  late String _selectedSpecies;
  late String _selectedBreed;
  late String _selectedGender;
  late String _selectedHealthStatus;
  late String _selectedPurpose;
  late bool _isPregnant;
  late bool _isNegotiable;
  late bool _isUrgentSale;
  late List<String> _selectedVaccinations;
  DateTime? _birthDate;
  bool _isLoading = false;

  // Responsive helper methods
  bool get isSmallScreen => MediaQuery.of(context).size.width < 360;
  bool get isMediumScreen =>
      MediaQuery.of(context).size.width >= 360 &&
      MediaQuery.of(context).size.width < 600;
  bool get isLargeScreen => MediaQuery.of(context).size.width >= 600;

  // Safe date formatting method
  String _formatDate(DateTime date) {
    try {
      return DateFormat('dd MMMM yyyy', 'tr_TR').format(date);
    } catch (e) {
      // Fallback to English format if Turkish locale is not available
      return DateFormat('dd MMMM yyyy', 'en_US').format(date);
    }
  }

  @override
  void initState() {
    super.initState();
    final animal = widget.animal;
    _descriptionController = TextEditingController(text: animal.description);
    _priceController = TextEditingController(text: animal.priceInTL.toString());
    _weightController =
        TextEditingController(text: animal.weightInKg.toString());
    _transportInfoController =
        TextEditingController(text: animal.transportInfo);
    _parentInfoController =
        TextEditingController(text: animal.parentInfo ?? '');
    _veterinarianContactController =
        TextEditingController(text: animal.veterinarianContact ?? '');
    _ageController = TextEditingController(text: animal.ageInMonths.toString());
    _certificatesController =
        TextEditingController(text: animal.certificates.join(", "));
    _additionalInfoController = TextEditingController(
        text: animal.additionalInfo != null
            ? animal.additionalInfo.toString()
            : '');
    _selectedAnimalType = animal.animalType;
    _selectedSpecies = animal.animalSpecies;
    _selectedBreed = animal.animalBreed;
    _selectedGender = animal.gender;
    _selectedHealthStatus = animal.healthStatus;
    _selectedPurpose = animal.purpose;
    _isPregnant = animal.isPregnant;
    _isNegotiable = animal.isNegotiable;
    _isUrgentSale = animal.isUrgentSale;
    _selectedVaccinations = List<String>.from(animal.vaccinations);
    _birthDate = animal.birthDate;
    _photoUrls = List<String>.from(animal.photoUrls);
    _datePublished = animal.datePublished;
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _priceController.dispose();
    _weightController.dispose();
    _transportInfoController.dispose();
    _parentInfoController.dispose();
    _veterinarianContactController.dispose();
    _ageController.dispose();
    _certificatesController.dispose();
    _additionalInfoController.dispose();
    super.dispose();
  }

  Future<void> _updateAnimal() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await FirebaseFirestore.instance
          .collection('animals')
          .doc(widget.animal.postId)
          .update({
        // İlan bilgileri - düzenlenebilir
        'description': _descriptionController.text,
        'priceInTL': double.tryParse(_priceController.text) ?? 0,
        'weightInKg': double.tryParse(_weightController.text) ?? 0,
        'ageInMonths': int.tryParse(_ageController.text) ?? 0,
        'transportInfo': _transportInfoController.text,
        'parentInfo': _parentInfoController.text,
        'veterinarianContact': _veterinarianContactController.text,
        'animalType': _selectedAnimalType,
        'animalSpecies': _selectedSpecies,
        'animalBreed': _selectedBreed,
        'gender': _selectedGender,
        'healthStatus': _selectedHealthStatus,
        'purpose': _selectedPurpose,
        'isPregnant': _isPregnant,
        'isNegotiable': _isNegotiable,
        'isUrgentSale': _isUrgentSale,
        'vaccinations': _selectedVaccinations,
        'birthDate': _birthDate,
        'additionalInfo': _additionalInfoController.text,
        'certificates': _certificatesController.text
            .split(',')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList(),
        'photoUrls': _photoUrls,
        'isActive': true,
        // Yayın tarihi değiştirilmez - ilan oluşturulduğunda set edilir
        // 'datePublished' güncellenmez
        // Satıcı bilgileri - değiştirilmez (kullanıcı profilinden güncellenir)
        // 'username', 'profImage', 'sellerType', 'country', 'state', 'city' güncellenmez
      });
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('İlan başarıyla güncellendi'),
          backgroundColor: AnimalColors.success,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Güncelleme başarısız: $e'),
          backgroundColor: AnimalColors.error,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildSectionCard({
    required IconData icon,
    required String title,
    required Widget child,
    Color? iconColor,
  }) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: (iconColor ?? AnimalColors.primary).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: iconColor ?? AnimalColors.primary,
                    size: 24,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AnimalColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    int? maxLines,
    String? Function(String?)? validator,
    bool enabled = true,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines ?? 1,
        enabled: enabled,
        validator: validator,
        style: GoogleFonts.poppins(
          fontSize: 16,
          color: AnimalColors.textPrimary,
        ),
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: AnimalColors.primary),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AnimalColors.dividerColor),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AnimalColors.dividerColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AnimalColors.primary, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AnimalColors.error),
          ),
          filled: true,
          fillColor: Colors.grey[50],
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          labelStyle: GoogleFonts.poppins(
            color: AnimalColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownField({
    required String value,
    required List<String> items,
    required String label,
    required IconData icon,
    required Function(String?) onChanged,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<String>(
        value: value,
        items: items
            .map((item) => DropdownMenuItem(
                  value: item,
                  child: Container(
                    width: double.infinity,
                    child: Text(
                      item,
                      style: GoogleFonts.poppins(fontSize: 16),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                  ),
                ))
            .toList(),
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: AnimalColors.primary),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AnimalColors.dividerColor),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AnimalColors.dividerColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AnimalColors.primary, width: 2),
          ),
          filled: true,
          fillColor: Colors.grey[50],
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          labelStyle: GoogleFonts.poppins(
            color: AnimalColors.textSecondary,
          ),
        ),
        style: GoogleFonts.poppins(
          fontSize: 16,
          color: AnimalColors.textPrimary,
        ),
        isExpanded: true,
        menuMaxHeight: 300,
        dropdownColor: Colors.white,
        icon: Icon(Icons.arrow_drop_down, color: AnimalColors.primary),
        selectedItemBuilder: (BuildContext context) {
          return items.map<Widget>((String item) {
            return Container(
              width: double.infinity,
              child: Text(
                item,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: AnimalColors.textPrimary,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            );
          }).toList();
        },
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
    IconData? icon,
    Color? activeColor,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AnimalColors.dividerColor),
      ),
      child: SwitchListTile(
        title: Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: AnimalColors.textPrimary,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: AnimalColors.textSecondary,
          ),
        ),
        value: value,
        onChanged: onChanged,
        activeColor: activeColor ?? AnimalColors.primary,
        secondary:
            icon != null ? Icon(icon, color: AnimalColors.primary) : null,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isOwner = FirebaseAuth.instance.currentUser?.uid == widget.animal.uid;
    if (!isOwner) {
      return Scaffold(
        backgroundColor: AnimalColors.background,
        appBar: AppBar(
          title: Text(
            'Yetkisiz Erişim',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          ),
          backgroundColor: AnimalColors.error,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.security,
                size: 64,
                color: AnimalColors.error,
              ),
              SizedBox(height: 16),
              Text(
                'Yetkisiz Erişim',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: AnimalColors.textPrimary,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Sadece kendi ilanınızı düzenleyebilirsiniz.',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: AnimalColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AnimalColors.background,
      appBar: AppBar(
        title: Text(
          'İlanı Düzenle',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: AnimalColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          if (_isLoading)
            Padding(
              padding: EdgeInsets.only(right: 16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor:
                        AlwaysStoppedAnimation<Color>(AnimalColors.primary),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'İlan güncelleniyor...',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: AnimalColors.textSecondary,
                    ),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Temel Bilgiler
                    _buildSectionCard(
                      icon: Icons.info_outline,
                      title: 'Temel Bilgiler',
                      child: Column(
                        children: [
                          _buildFormField(
                            controller: _descriptionController,
                            label: 'Açıklama',
                            icon: Icons.description,
                            maxLines: 3,
                            validator: (v) => v == null || v.isEmpty
                                ? 'Açıklama gerekli'
                                : null,
                          ),
                          _buildFormField(
                            controller: _priceController,
                            label: 'Fiyat (TL)',
                            icon: Icons.attach_money,
                            keyboardType: TextInputType.number,
                            validator: (v) =>
                                v == null || v.isEmpty ? 'Fiyat gerekli' : null,
                          ),
                          _buildFormField(
                            controller: _weightController,
                            label: 'Ağırlık (kg)',
                            icon: Icons.monitor_weight,
                            keyboardType: TextInputType.number,
                          ),
                          _buildFormField(
                            controller: _ageController,
                            label: 'Yaş (ay)',
                            icon: Icons.cake,
                            keyboardType: TextInputType.number,
                          ),
                        ],
                      ),
                    ),

                    // Hayvan Bilgileri
                    _buildSectionCard(
                      icon: Icons.pets,
                      title: 'Hayvan Bilgileri',
                      child: Column(
                        children: [
                          _buildDropdownField(
                            value: _selectedAnimalType,
                            items: AnimalCategories.animalTypes,
                            label: 'Hayvan Türü',
                            icon: Icons.category,
                            onChanged: (v) => setState(() =>
                                _selectedAnimalType = v ?? _selectedAnimalType),
                          ),
                          _buildDropdownField(
                            value: _selectedSpecies,
                            items: AnimalCategories.animalSpecies,
                            label: 'Hayvan Cinsi',
                            icon: Icons.pets,
                            onChanged: (v) => setState(
                                () => _selectedSpecies = v ?? _selectedSpecies),
                          ),
                          _buildDropdownField(
                            value: _selectedBreed,
                            items: AnimalCategories.getBreedsForSpecies(
                                _selectedSpecies),
                            label: 'Irk',
                            icon: Icons.emoji_nature,
                            onChanged: (v) => setState(
                                () => _selectedBreed = v ?? _selectedBreed),
                          ),
                          _buildDropdownField(
                            value: _selectedGender,
                            items: AnimalCategories.genders,
                            label: 'Cinsiyet',
                            icon: Icons.wc,
                            onChanged: (v) => setState(
                                () => _selectedGender = v ?? _selectedGender),
                          ),
                          _buildDropdownField(
                            value: _selectedHealthStatus,
                            items: AnimalCategories.healthStatuses,
                            label: 'Sağlık Durumu',
                            icon: Icons.health_and_safety,
                            onChanged: (v) => setState(() =>
                                _selectedHealthStatus =
                                    v ?? _selectedHealthStatus),
                          ),
                          _buildDropdownField(
                            value: _selectedPurpose,
                            items: AnimalCategories.purposes,
                            label: 'Kullanım Amacı',
                            icon: Icons.agriculture,
                            onChanged: (v) => setState(
                                () => _selectedPurpose = v ?? _selectedPurpose),
                          ),
                        ],
                      ),
                    ),

                    // Nakliye Bilgileri
                    _buildSectionCard(
                      icon: Icons.local_shipping,
                      title: 'Nakliye Bilgileri',
                      child: Column(
                        children: [
                          _buildFormField(
                            controller: _transportInfoController,
                            label: 'Nakliye Bilgisi',
                            icon: Icons.local_shipping,
                          ),
                        ],
                      ),
                    ),

                    // Ek Bilgiler
                    _buildSectionCard(
                      icon: Icons.medical_services,
                      title: 'Sağlık ve Ek Bilgiler',
                      child: Column(
                        children: [
                          _buildFormField(
                            controller: _parentInfoController,
                            label: 'Ebeveyn Bilgisi',
                            icon: Icons.family_restroom,
                          ),
                          _buildFormField(
                            controller: _veterinarianContactController,
                            label: 'Veteriner İletişim',
                            icon: Icons.phone,
                          ),
                          _buildFormField(
                            controller: _certificatesController,
                            label: 'Sertifikalar (virgülle ayırın)',
                            icon: Icons.verified,
                          ),
                          _buildFormField(
                            controller: _additionalInfoController,
                            label: 'Ek Bilgiler',
                            icon: Icons.note_add,
                            maxLines: 3,
                          ),
                          SizedBox(height: 16),
                          Container(
                            padding: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(12),
                              border:
                                  Border.all(color: AnimalColors.dividerColor),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.calendar_today,
                                    color: AnimalColors.textSecondary),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Yayın Tarihi',
                                        style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          color: AnimalColors.textSecondary,
                                        ),
                                      ),
                                      Text(
                                        _formatDate(_datePublished),
                                        style: GoogleFonts.poppins(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                          color: AnimalColors.textPrimary,
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
                    ),

                    // Özel Durumlar
                    _buildSectionCard(
                      icon: Icons.settings,
                      title: 'Özel Durumlar',
                      child: Column(
                        children: [
                          _buildSwitchTile(
                            title: 'Pazarlık Yapılabilir',
                            subtitle: 'Fiyatta pazarlık yapılabilir',
                            value: _isNegotiable,
                            onChanged: (v) => setState(() => _isNegotiable = v),
                            icon: Icons.attach_money,
                            activeColor: AnimalColors.negotiable,
                          ),
                          _buildSwitchTile(
                            title: 'Acil Satış',
                            subtitle: 'Bu ilan acil satış kategorisinde',
                            value: _isUrgentSale,
                            onChanged: (v) => setState(() => _isUrgentSale = v),
                            icon: Icons.flash_on,
                            activeColor: AnimalColors.urgent,
                          ),
                          _buildSwitchTile(
                            title: 'Gebe Hayvan',
                            subtitle: 'Hayvan gebe durumda',
                            value: _isPregnant,
                            onChanged: (v) => setState(() => _isPregnant = v),
                            icon: Icons.pregnant_woman,
                            activeColor: AnimalColors.pregnant,
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 32),

                    // Güncelle Butonu
                    Container(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _updateAnimal,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AnimalColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          shadowColor: AnimalColors.primary.withOpacity(0.3),
                        ),
                        child: _isLoading
                            ? Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.white),
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Text(
                                    'Güncelleniyor...',
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.save, size: 20),
                                  SizedBox(width: 8),
                                  Text(
                                    'İlanı Güncelle',
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),

                    SizedBox(height: 16),
                  ],
                ),
              ),
            ),
    );
  }
}

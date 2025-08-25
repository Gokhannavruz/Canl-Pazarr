import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';

class TransporterProfileScreen extends StatefulWidget {
  final String userId;
  final Map<String, dynamic>? existingTransporterData;

  const TransporterProfileScreen({
    Key? key,
    required this.userId,
    this.existingTransporterData,
  }) : super(key: key);

  @override
  State<TransporterProfileScreen> createState() =>
      _TransporterProfileScreenState();
}

class _TransporterProfileScreenState extends State<TransporterProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  // Color palette (from profile_screen2)
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

  // Form fields
  String? companyName;
  String? phone;
  List<String> cities = [];
  double? maxDistanceKm;
  double? pricePerKm;
  int? maxAnimals;
  String? vehicleType;
  String? vehiclePlate;
  bool available = true;
  String? description;
  double? minPrice;
  double? maxPrice;
  int? yearsExperience;
  String? workingHours;
  bool insurance = false;
  List<String> regions = [];
  List<String> animalTypes = [];
  Map<String, dynamic> capacityDetails = {};
  List<String> languages = [];
  List<String> documents = [];
  List<String> photoUrls = [];
  String? notes;

  // Controllers for formatted fields
  final TextEditingController _minPriceController = TextEditingController();
  final TextEditingController _maxPriceController = TextEditingController();
  final TextEditingController _pricePerKmController = TextEditingController();
  final TextEditingController _maxDistanceKmController =
      TextEditingController();

  String _unformatNumber(String value) {
    return value
        .replaceAll('.', '')
        .replaceAll(',', '')
        .replaceAll('₺', '')
        .replaceAll(' ', '');
  }

  String _formatNumber(String value) {
    if (value.isEmpty) return '';
    final num? number = num.tryParse(_unformatNumber(value));
    if (number == null) return '';
    final formatter = NumberFormat('#,##0', 'tr_TR');
    return formatter.format(number);
  }

  // Add static list of Turkish cities
  static const List<String> turkishCities = [
    'Adana',
    'Adıyaman',
    'Afyonkarahisar',
    'Ağrı',
    'Aksaray',
    'Amasya',
    'Ankara',
    'Antalya',
    'Ardahan',
    'Artvin',
    'Aydın',
    'Balıkesir',
    'Bartın',
    'Batman',
    'Bayburt',
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
    'Düzce',
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
    'Iğdır',
    'Isparta',
    'İstanbul',
    'İzmir',
    'Kahramanmaraş',
    'Karabük',
    'Karaman',
    'Kars',
    'Kastamonu',
    'Kayseri',
    'Kırıkkale',
    'Kırklareli',
    'Kırşehir',
    'Kilis',
    'Kocaeli',
    'Konya',
    'Kütahya',
    'Malatya',
    'Manisa',
    'Mardin',
    'Mersin',
    'Muğla',
    'Muş',
    'Nevşehir',
    'Niğde',
    'Ordu',
    'Osmaniye',
    'Rize',
    'Sakarya',
    'Samsun',
    'Şanlıurfa',
    'Siirt',
    'Sinop',
    'Şırnak',
    'Sivas',
    'Tekirdağ',
    'Tokat',
    'Trabzon',
    'Tunceli',
    'Uşak',
    'Van',
    'Yalova',
    'Yozgat',
    'Zonguldak',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.existingTransporterData != null) {
      final d = widget.existingTransporterData!;
      companyName = d['transporterCompanyName'];
      phone = d['transporterPhone'];
      cities = List<String>.from(d['transporterCities'] ?? []);
      maxDistanceKm = (d['transporterMaxDistanceKm'] as num?)?.toDouble();
      pricePerKm = (d['transporterPricePerKm'] as num?)?.toDouble();
      maxAnimals = d['transporterMaxAnimals'];
      vehicleType = d['transporterVehicleType'];
      vehiclePlate = d['transporterVehiclePlate'];
      available = d['transporterAvailable'] ?? true;
      description = d['transporterDescription'];
      minPrice = (d['transporterMinPrice'] as num?)?.toDouble();
      maxPrice = (d['transporterMaxPrice'] as num?)?.toDouble();
      yearsExperience = d['transporterYearsExperience'];
      workingHours = d['transporterWorkingHours'];
      insurance = d['transporterInsurance'] ?? false;
      regions = List<String>.from(d['transporterRegions'] ?? []);
      animalTypes = List<String>.from(d['transporterAnimalTypes'] ?? []);
      capacityDetails =
          Map<String, dynamic>.from(d['transporterCapacityDetails'] ?? {});
      languages = List<String>.from(d['transporterLanguages'] ?? []);
      documents = List<String>.from(d['transporterDocuments'] ?? []);
      photoUrls = List<String>.from(d['transporterPhotoUrls'] ?? []);
      notes = d['transporterNotes'];

      if (minPrice != null)
        _minPriceController.text = _formatNumber(minPrice.toString());
      if (maxPrice != null)
        _maxPriceController.text = _formatNumber(maxPrice.toString());
      if (pricePerKm != null)
        _pricePerKmController.text = _formatNumber(pricePerKm.toString());
      if (maxDistanceKm != null)
        _maxDistanceKmController.text = _formatNumber(maxDistanceKm.toString());
    }
  }

  @override
  void dispose() {
    _minPriceController.dispose();
    _maxPriceController.dispose();
    _pricePerKmController.dispose();
    _maxDistanceKmController.dispose();
    super.dispose();
  }

  void _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      // Debug print for cities before saving
      print('KAYDEDİLEN CITIES: $cities');
      // Firestore update
      final data = {
        'isTransporter': true,
        'transporterCompanyName': companyName,
        'transporterPhone': phone,
        'transporterCities': cities,
        'transporterMaxDistanceKm': maxDistanceKm,
        'transporterPricePerKm': pricePerKm,
        'transporterMaxAnimals': maxAnimals,
        'transporterVehicleType': vehicleType,
        'transporterVehiclePlate': vehiclePlate,
        'transporterAvailable': available,
        'transporterDescription': description,
        'transporterMinPrice': minPrice,
        'transporterMaxPrice': maxPrice,
        'transporterYearsExperience': yearsExperience,
        'transporterWorkingHours': workingHours,
        'transporterInsurance': insurance,
        'transporterRegions': regions,
        'transporterAnimalTypes': animalTypes,
        'transporterCapacityDetails': capacityDetails,
        'transporterLanguages': languages,
        'transporterDocuments': documents,
        'transporterPhotoUrls': photoUrls,
        'transporterNotes': notes,
      };
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .update(data);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nakliyeci profili kaydedildi.')),
      );
      Navigator.pop(context);
    }
  }

  Widget _card(
      {required String title, required List<Widget> children, IconData? icon}) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: dividerColor, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, color: primaryColor, size: 20),
                const SizedBox(width: 8),
              ],
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
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _formField({
    required String label,
    String? initialValue,
    String? hintText,
    int maxLines = 1,
    TextInputType? keyboardType,
    FormFieldSetter<String>? onSaved,
    bool enabled = true,
    TextEditingController? controller,
    ValueChanged<String>? onChanged,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              color: textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          TextFormField(
            initialValue: controller == null ? initialValue : null,
            controller: controller,
            enabled: enabled,
            decoration: InputDecoration(
              hintText: hintText,
              filled: true,
              fillColor: surfaceColor,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: dividerColor, width: 1),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: dividerColor, width: 1),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: primaryColor, width: 2),
              ),
            ),
            style: GoogleFonts.poppins(
              color: textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            maxLines: maxLines,
            keyboardType: keyboardType,
            onChanged: onChanged,
            inputFormatters: inputFormatters,
            onSaved: onSaved,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: surfaceColor,
      appBar: AppBar(
        title: Text(
          'Nakliyeci Profilini Düzenle',
          style: GoogleFonts.poppins(
            color: textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        backgroundColor: backgroundColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: textPrimary),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: dividerColor,
            height: 1,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _card(
                title: 'Genel Bilgiler',
                icon: Icons.info_outline,
                children: [
                  _formField(
                    label: 'Firma Adı (varsa)',
                    initialValue: companyName,
                    hintText: 'Firma adı',
                    onSaved: (v) => companyName = v,
                  ),
                  _formField(
                    label: 'Telefon',
                    initialValue: phone,
                    hintText: 'Telefon numarası',
                    keyboardType: TextInputType.phone,
                    onSaved: (v) => phone = v,
                  ),
                  // Şehir seçimi dropdown
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Hizmet Verilen Şehirler',
                            style: GoogleFonts.poppins(
                              color: textSecondary,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            )),
                        const SizedBox(height: 4),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: textPrimary,
                              elevation: 0,
                              side: BorderSide(color: dividerColor, width: 1),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                              padding: const EdgeInsets.symmetric(
                                  vertical: 14, horizontal: 12),
                            ),
                            onPressed: () async {
                              final List<
                                  String> result = await showModalBottomSheet<
                                      List<String>>(
                                    context: context,
                                    isScrollControlled: true,
                                    backgroundColor: Colors.white,
                                    shape: const RoundedRectangleBorder(
                                      borderRadius: BorderRadius.vertical(
                                          top: Radius.circular(24)),
                                    ),
                                    builder: (context) {
                                      List<String> tempSelected =
                                          List<String>.from(cities);
                                      String search = '';
                                      return StatefulBuilder(
                                        builder: (context, setModalState) {
                                          final filtered = [
                                            ...turkishCities.where((city) =>
                                                city.toLowerCase().startsWith(
                                                    search.toLowerCase())),
                                            ...turkishCities.where((city) =>
                                                !city.toLowerCase().startsWith(
                                                    search.toLowerCase()) &&
                                                city.toLowerCase().contains(
                                                    search.toLowerCase())),
                                          ];
                                          return Padding(
                                            padding: EdgeInsets.only(
                                              top: 60,
                                              bottom: 40 +
                                                  MediaQuery.of(context)
                                                      .viewInsets
                                                      .bottom,
                                              left: 16,
                                              right: 16,
                                            ),
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Container(
                                                  width: 40,
                                                  height: 4,
                                                  margin: const EdgeInsets.only(
                                                      bottom: 16),
                                                  decoration: BoxDecoration(
                                                    color: dividerColor,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            2),
                                                  ),
                                                ),
                                                TextField(
                                                  decoration: InputDecoration(
                                                    hintText: 'Şehir ara',
                                                    prefixIcon: const Icon(
                                                        Icons.search),
                                                    filled: true,
                                                    fillColor: surfaceColor,
                                                    contentPadding:
                                                        const EdgeInsets
                                                            .symmetric(
                                                            horizontal: 12,
                                                            vertical: 12),
                                                    border: OutlineInputBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              8),
                                                      borderSide: BorderSide(
                                                          color: dividerColor,
                                                          width: 1),
                                                    ),
                                                    enabledBorder:
                                                        OutlineInputBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              8),
                                                      borderSide: BorderSide(
                                                          color: dividerColor,
                                                          width: 1),
                                                    ),
                                                    focusedBorder:
                                                        OutlineInputBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              8),
                                                      borderSide: BorderSide(
                                                          color: primaryColor,
                                                          width: 2),
                                                    ),
                                                  ),
                                                  onChanged: (v) =>
                                                      setModalState(
                                                          () => search = v),
                                                ),
                                                const SizedBox(height: 12),
                                                Expanded(
                                                  child: Scrollbar(
                                                    child: ListView.builder(
                                                      itemCount:
                                                          filtered.length,
                                                      itemBuilder:
                                                          (context, i) {
                                                        final city =
                                                            filtered[i];
                                                        final selected =
                                                            tempSelected
                                                                .contains(city);
                                                        return CheckboxListTile(
                                                          value: selected,
                                                          title: Text(city),
                                                          activeColor:
                                                              primaryColor,
                                                          onChanged: (val) {
                                                            setModalState(() {
                                                              if (val == true) {
                                                                tempSelected
                                                                    .add(city);
                                                              } else {
                                                                tempSelected
                                                                    .remove(
                                                                        city);
                                                              }
                                                            });
                                                          },
                                                        );
                                                      },
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(height: 12),
                                                SizedBox(
                                                  width: double.infinity,
                                                  child: ElevatedButton(
                                                    style: ElevatedButton
                                                        .styleFrom(
                                                      backgroundColor:
                                                          primaryColor,
                                                      foregroundColor:
                                                          backgroundColor,
                                                      shape:
                                                          RoundedRectangleBorder(
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          12)),
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                          vertical: 14),
                                                    ),
                                                    onPressed: () {
                                                      Navigator.pop(context,
                                                          tempSelected);
                                                    },
                                                    child: const Text(
                                                        'Seçimi Onayla'),
                                                  ),
                                                ),
                                                const SizedBox(height: 12),
                                              ],
                                            ),
                                          );
                                        },
                                      );
                                    },
                                  ) ??
                                  cities;
                              setState(() {
                                cities = result;
                              });
                            },
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    cities.isEmpty
                                        ? 'Şehir seçin'
                                        : cities.join(', '),
                                    style: GoogleFonts.poppins(
                                      color: cities.isEmpty
                                          ? textSecondary
                                          : textPrimary,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 2,
                                  ),
                                ),
                                const Icon(Icons.keyboard_arrow_down),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: cities
                              .map((city) => Chip(
                                    label: Text(city),
                                    deleteIcon:
                                        const Icon(Icons.close, size: 18),
                                    onDeleted: () {
                                      setState(() {
                                        cities.remove(city);
                                      });
                                    },
                                  ))
                              .toList(),
                        ),
                      ],
                    ),
                  ),
                  _formField(
                    label: 'Çalışma Saatleri',
                    initialValue: workingHours,
                    hintText: 'Örn: 08:00-20:00',
                    onSaved: (v) => workingHours = v,
                  ),
                  _formField(
                    label: 'Deneyim (yıl)',
                    initialValue: yearsExperience?.toString(),
                    hintText: 'Yıl',
                    keyboardType: TextInputType.number,
                    onSaved: (v) => yearsExperience = int.tryParse(v ?? ''),
                  ),
                ],
              ),
              _card(
                title: 'Araç Bilgileri',
                icon: Icons.local_shipping,
                children: [
                  _formField(
                    label: 'Araç Tipi',
                    initialValue: vehicleType,
                    hintText: 'Örn: Kamyon, Tır',
                    onSaved: (v) => vehicleType = v,
                  ),
                  _formField(
                    label: 'Araç Plakası',
                    initialValue: vehiclePlate,
                    hintText: 'Plaka',
                    onSaved: (v) => vehiclePlate = v,
                  ),
                  _formField(
                    label: 'Maks. Hayvan Kapasitesi',
                    initialValue: maxAnimals?.toString(),
                    hintText: 'Örn: 10',
                    keyboardType: TextInputType.number,
                    onSaved: (v) => maxAnimals = int.tryParse(v ?? ''),
                  ),
                  SwitchListTile(
                    value: available,
                    onChanged: (v) => setState(() => available = v),
                    title: Text('Şu an müsaitim',
                        style:
                            GoogleFonts.poppins(fontWeight: FontWeight.w500)),
                    activeColor: primaryColor,
                  ),
                  SwitchListTile(
                    value: insurance,
                    onChanged: (v) => setState(() => insurance = v),
                    title: Text('Taşıma Sigortası Var',
                        style:
                            GoogleFonts.poppins(fontWeight: FontWeight.w500)),
                    activeColor: primaryColor,
                  ),
                ],
              ),
              _card(
                title: 'Fiyat & Kapsam',
                icon: Icons.attach_money,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _formField(
                          label: 'Min. Ücret (₺)',
                          controller: _minPriceController,
                          keyboardType: TextInputType.number,
                          onChanged: (v) {
                            final formatted = _formatNumber(v);
                            if (formatted != _minPriceController.text) {
                              _minPriceController.value = TextEditingValue(
                                text: formatted,
                                selection: TextSelection.collapsed(
                                    offset: formatted.length),
                              );
                            }
                          },
                          onSaved: (v) => minPrice = double.tryParse(
                              _unformatNumber(_minPriceController.text)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _formField(
                          label: 'Max. Ücret (₺)',
                          controller: _maxPriceController,
                          keyboardType: TextInputType.number,
                          onChanged: (v) {
                            final formatted = _formatNumber(v);
                            if (formatted != _maxPriceController.text) {
                              _maxPriceController.value = TextEditingValue(
                                text: formatted,
                                selection: TextSelection.collapsed(
                                    offset: formatted.length),
                              );
                            }
                          },
                          onSaved: (v) => maxPrice = double.tryParse(
                              _unformatNumber(_maxPriceController.text)),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: _formField(
                          label: 'Maks. Mesafe (km)',
                          controller: _maxDistanceKmController,
                          keyboardType: TextInputType.number,
                          onChanged: (v) {
                            final formatted = _formatNumber(v);
                            if (formatted != _maxDistanceKmController.text) {
                              _maxDistanceKmController.value = TextEditingValue(
                                text: formatted,
                                selection: TextSelection.collapsed(
                                    offset: formatted.length),
                              );
                            }
                          },
                          onSaved: (v) => maxDistanceKm = double.tryParse(
                              _unformatNumber(_maxDistanceKmController.text)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _formField(
                          label: 'Km başı ücret (₺)',
                          controller: _pricePerKmController,
                          keyboardType: TextInputType.number,
                          onChanged: (v) {
                            final formatted = _formatNumber(v);
                            if (formatted != _pricePerKmController.text) {
                              _pricePerKmController.value = TextEditingValue(
                                text: formatted,
                                selection: TextSelection.collapsed(
                                    offset: formatted.length),
                              );
                            }
                          },
                          onSaved: (v) => pricePerKm = double.tryParse(
                              _unformatNumber(_pricePerKmController.text)),
                        ),
                      ),
                    ],
                  ),
                  _formField(
                    label: 'Bölgeler',
                    initialValue: regions.join(', '),
                    hintText: 'Örn: İç Anadolu, Ege',
                    onSaved: (v) => regions = v!
                        .split(',')
                        .map((e) => e.trim())
                        .where((e) => e.isNotEmpty)
                        .toList(),
                  ),
                  _formField(
                    label: 'Taşıdığı Hayvan Türleri',
                    initialValue: animalTypes.join(', '),
                    hintText: 'Örn: Sığır, Koyun',
                    onSaved: (v) => animalTypes = v!
                        .split(',')
                        .map((e) => e.trim())
                        .where((e) => e.isNotEmpty)
                        .toList(),
                  ),
                ],
              ),
              _card(
                title: 'Ek Bilgiler',
                icon: Icons.notes,
                children: [
                  _formField(
                    label: 'Açıklama',
                    initialValue: description,
                    hintText: 'Kendinizi ve hizmetinizi tanıtın',
                    maxLines: 2,
                    onSaved: (v) => description = v,
                  ),
                  _formField(
                    label: 'Konuşulan Diller',
                    initialValue: languages.join(', '),
                    hintText: 'Örn: Türkçe, İngilizce',
                    onSaved: (v) => languages = v!
                        .split(',')
                        .map((e) => e.trim())
                        .where((e) => e.isNotEmpty)
                        .toList(),
                  ),
                  _formField(
                    label: 'Ek Notlar',
                    initialValue: notes,
                    hintText: 'Ekstra bilgi',
                    maxLines: 2,
                    onSaved: (v) => notes = v,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.save),
                  label: const Text('Kaydet'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: backgroundColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  onPressed: _saveProfile,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

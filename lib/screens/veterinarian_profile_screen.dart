import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';

class VeterinarianProfileScreen extends StatefulWidget {
  final String userId;
  final Map<String, dynamic>? existingVeterinarianData;

  const VeterinarianProfileScreen({
    Key? key,
    required this.userId,
    this.existingVeterinarianData,
  }) : super(key: key);

  @override
  State<VeterinarianProfileScreen> createState() =>
      _VeterinarianProfileScreenState();
}

class _VeterinarianProfileScreenState extends State<VeterinarianProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;

  // Color palette
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
  String? clinicName;
  String? phone;
  String? email;
  String? address;
  List<String> cities = [];
  String? licenseNumber;
  String? specialization;
  int? yearsExperience;
  String? workingHours;
  bool available = true;
  String? description;
  double? consultationFee;
  double? emergencyFee;
  bool homeVisit = false;
  bool emergencyService = false;
  List<String> animalTypes = [];
  List<String> services = [];
  List<String> certifications = [];
  List<String> languages = [];
  List<String> documents = [];
  List<String> photoUrls = [];
  String? notes;
  String? emergencyPhone;
  bool insurance = false;
  List<String> regions = [];
  Map<String, dynamic> serviceDetails = {};
  String? clinicType;
  String? education;
  String? university;
  int? graduationYear;
  List<String> specializations = [];
  bool hasLaboratory = false;
  bool hasSurgery = false;
  bool hasXRay = false;
  bool hasUltrasound = false;
  String? equipmentList;
  String? emergencyProtocol;

  // Controllers for formatted fields
  final TextEditingController _consultationFeeController =
      TextEditingController();
  final TextEditingController _emergencyFeeController = TextEditingController();

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

  // Fotoğraf yükleme fonksiyonları
  Future<void> _pickImage(ImageSource source) async {
    try {
      final List<XFile> images = await _picker.pickMultiImage(
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );

      if (images.isNotEmpty) {
        setState(() {
          _isUploading = true;
        });

        // Maksimum 6 fotoğraf kontrolü
        final remainingSlots = 6 - photoUrls.length;
        final imagesToUpload = images.take(remainingSlots).toList();

        if (imagesToUpload.length < images.length) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'En fazla 6 fotoğraf ekleyebilirsiniz. Fazla fotoğraflar atlandı.'),
            ),
          );
        }

        // Fotoğrafları sırayla yükle
        for (int i = 0; i < imagesToUpload.length; i++) {
          await _uploadImage(imagesToUpload[i]);

          // Son fotoğraf değilse kısa bir bekleme
          if (i < imagesToUpload.length - 1) {
            await Future.delayed(const Duration(milliseconds: 500));
          }
        }

        setState(() {
          _isUploading = false;
        });

        if (imagesToUpload.length > 1) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text('${imagesToUpload.length} fotoğraf başarıyla yüklendi'),
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isUploading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fotoğraf seçilirken hata oluştu: $e')),
      );
    }
  }

  Future<void> _uploadImage(XFile image) async {
    try {
      final file = File(image.path);
      final fileName =
          'veterinarian_${widget.userId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref =
          FirebaseStorage.instance.ref().child('veterinarian_photos/$fileName');

      final uploadTask = ref.putFile(file);
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      setState(() {
        photoUrls.add(downloadUrl);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fotoğraf yüklenirken hata oluştu: $e')),
      );
    }
  }

  Future<void> _removeImage(int index) async {
    try {
      final url = photoUrls[index];
      final ref = FirebaseStorage.instance.refFromURL(url);
      await ref.delete();

      setState(() {
        photoUrls.removeAt(index);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fotoğraf silindi')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fotoğraf silinirken hata oluştu: $e')),
      );
    }
  }

  void _showImageSourceDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Fotoğraf Ekle', style: GoogleFonts.poppins()),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: Text('Kamera', style: GoogleFonts.poppins()),
                subtitle: Text('Tek fotoğraf çek',
                    style: GoogleFonts.poppins(fontSize: 12)),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: Text('Galeri', style: GoogleFonts.poppins()),
                subtitle: Text('Birden fazla fotoğraf seçebilirsiniz',
                    style: GoogleFonts.poppins(fontSize: 12)),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPhotoGallery() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Açıklama
        Text(
          'Klinik fotoğraflarınızı ekleyin. Bu fotoğraflar veteriner keşfet sayfasında görünecektir.',
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: textSecondary,
          ),
        ),
        const SizedBox(height: 12),

        // Fotoğraf galerisi
        if (photoUrls.isNotEmpty)
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1,
            ),
            itemCount: photoUrls.length,
            itemBuilder: (context, index) {
              return Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(
                      imageUrl: photoUrls[index],
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                      placeholder: (context, url) => Container(
                        color: surfaceColor,
                        child: const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: surfaceColor,
                        child: const Icon(Icons.error),
                      ),
                    ),
                  ),
                  // Silme butonu
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () => _removeImage(index),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.8),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),

        const SizedBox(height: 12),

        // Fotoğraf ekleme butonu
        if (_isUploading)
          Container(
            width: double.infinity,
            height: 100,
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: dividerColor),
            ),
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 8),
                  Text('Yükleniyor...'),
                ],
              ),
            ),
          )
        else if (photoUrls.length >= 6)
          Container(
            width: double.infinity,
            height: 100,
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: dividerColor),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.check_circle,
                  size: 32,
                  color: Colors.green,
                ),
                const SizedBox(height: 8),
                Text(
                  'Maksimum fotoğraf sayısına ulaştınız',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          )
        else
          GestureDetector(
            onTap: _showImageSourceDialog,
            child: Container(
              width: double.infinity,
              height: 100,
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(8),
                border:
                    Border.all(color: dividerColor, style: BorderStyle.solid),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_photo_alternate,
                    size: 32,
                    color: primaryColor,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Fotoğraf Ekle (${photoUrls.length}/6)',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: primaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),

        const SizedBox(height: 8),

        // Bilgi metni
        Text(
          'En fazla 6 fotoğraf ekleyebilirsiniz. Fotoğraflar otomatik olarak optimize edilecektir.',
          style: GoogleFonts.poppins(
            fontSize: 11,
            color: textSecondary,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  // Turkish cities list
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

  // Veterinarian specializations
  static const List<String> veterinarianSpecializations = [
    'Büyükbaş Hayvan Hekimliği',
    'Küçükbaş Hayvan Hekimliği',
    'Süt Sığırı Hekimliği',
    'Et Sığırı Hekimliği',
    'Damızlık Hayvan Hekimliği',
    'Sürü Sağlığı',
    'Üreme Hekimliği',
    'Cerrahi',
    'İç Hastalıkları',
    'Dış Hastalıkları',
    'Mikrobiyoloji',
    'Parazitoloji',
    'Farmakoloji',
    'Beslenme',
    'Zoonoz Hastalıklar',
    'Aşı ve İmmunoloji',
    'Laboratuvar Teşhis',
    'Radyoloji',
    'Ultrasonografi',
    'Patoloji',
    'Toksikoloji',
    'Halk Sağlığı',
    'Gıda Güvenliği',
    'Çevre Sağlığı',
  ];

  // Veterinarian services
  static const List<String> veterinarianServices = [
    'Genel Muayene',
    'Aşı Uygulaması',
    'Cerrahi Müdahale',
    'Doğum Yardımı',
    'Suni Tohumlama',
    'Gebelik Teşhisi',
    'Soy Kütüğü Belgesi',
    'Sağlık Raporu',
    'Kan Tahlili',
    'Dışkı Tahlili',
    'İdrar Tahlili',
    'Radyografi (X-Ray)',
    'Ultrasonografi',
    'Mikroskopik İnceleme',
    'Parazit Tedavisi',
    'Antibiyotik Tedavisi',
    'Vitamin Takviyesi',
    'Beslenme Danışmanlığı',
    'Sürü Sağlığı Planı',
    'Acil Müdahale',
    'Ev Ziyareti',
    'Çiftlik Ziyareti',
    'Eğitim ve Danışmanlık',
    'Sertifika Düzenleme',
    'İlaç Reçetesi',
    'Kontrol Muayenesi',
  ];

  // Animal types
  static const List<String> animalTypesList = [
    'Sığır',
    'Koyun',
    'Keçi',
    'Manda',
    'At',
    'Eşek',
    'Tavuk',
    'Hindi',
    'Ördek',
    'Kaz',
    'Domuz',
    'Tavşan',
    'Köpek',
    'Kedi',
    'Kümes Hayvanları',
    'Arı',
    'Balık',
    'Diğer',
  ];

  @override
  void initState() {
    super.initState();

    // Kullanıcı yetkisini kontrol et
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser?.uid != widget.userId) {
      // Yetkisiz erişim - kullanıcıyı geri yönlendir
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bu sayfaya erişim yetkiniz yok.'),
            backgroundColor: Colors.red,
          ),
        );
        Navigator.pop(context);
      });
      return;
    }

    if (widget.existingVeterinarianData != null) {
      final d = widget.existingVeterinarianData!;
      clinicName = d['veterinarianClinicName'];
      phone = d['veterinarianPhone'];
      email = d['veterinarianEmail'];
      address = d['veterinarianAddress'];
      cities = List<String>.from(d['veterinarianCities'] ?? []);
      licenseNumber = d['veterinarianLicenseNumber'];
      specialization = d['veterinarianSpecialization'];
      yearsExperience = d['veterinarianYearsExperience'];
      workingHours = d['veterinarianWorkingHours'];
      available = d['veterinarianAvailable'] ?? true;
      description = d['veterinarianDescription'];
      consultationFee = (d['veterinarianConsultationFee'] as num?)?.toDouble();
      emergencyFee = (d['veterinarianEmergencyFee'] as num?)?.toDouble();
      homeVisit = d['veterinarianHomeVisit'] ?? false;
      emergencyService = d['veterinarianEmergencyService'] ?? false;
      animalTypes = List<String>.from(d['veterinarianAnimalTypes'] ?? []);
      services = List<String>.from(d['veterinarianServices'] ?? []);
      certifications = List<String>.from(d['veterinarianCertifications'] ?? []);
      languages = List<String>.from(d['veterinarianLanguages'] ?? []);
      documents = List<String>.from(d['veterinarianDocuments'] ?? []);
      photoUrls = List<String>.from(d['veterinarianPhotoUrls'] ?? []);
      notes = d['veterinarianNotes'];
      emergencyPhone = d['veterinarianEmergencyPhone'];
      insurance = d['veterinarianInsurance'] ?? false;
      regions = List<String>.from(d['veterinarianRegions'] ?? []);
      serviceDetails =
          Map<String, dynamic>.from(d['veterinarianServiceDetails'] ?? {});
      clinicType = d['veterinarianClinicType'];
      education = d['veterinarianEducation'];
      university = d['veterinarianUniversity'];
      graduationYear = d['veterinarianGraduationYear'];
      specializations =
          List<String>.from(d['veterinarianSpecializations'] ?? []);
      hasLaboratory = d['veterinarianHasLaboratory'] ?? false;
      hasSurgery = d['veterinarianHasSurgery'] ?? false;
      hasXRay = d['veterinarianHasXRay'] ?? false;
      hasUltrasound = d['veterinarianHasUltrasound'] ?? false;
      equipmentList = d['veterinarianEquipmentList'];
      emergencyProtocol = d['veterinarianEmergencyProtocol'];

      if (consultationFee != null)
        _consultationFeeController.text =
            _formatNumber(consultationFee.toString());
      if (emergencyFee != null)
        _emergencyFeeController.text = _formatNumber(emergencyFee.toString());
    }
  }

  @override
  void dispose() {
    _consultationFeeController.dispose();
    _emergencyFeeController.dispose();
    super.dispose();
  }

  void _saveProfile() async {
    // Kullanıcı yetkisini tekrar kontrol et
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser?.uid != widget.userId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bu işlem için yetkiniz yok.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      final data = {
        'isVeterinarian': true,
        'veterinarianClinicName': clinicName,
        'veterinarianPhone': phone,
        'veterinarianEmail': email,
        'veterinarianAddress': address,
        'veterinarianCities': cities,
        'veterinarianLicenseNumber': licenseNumber,
        'veterinarianSpecialization': specialization,
        'veterinarianYearsExperience': yearsExperience,
        'veterinarianWorkingHours': workingHours,
        'veterinarianAvailable': available,
        'veterinarianDescription': description,
        'veterinarianConsultationFee': consultationFee,
        'veterinarianEmergencyFee': emergencyFee,
        'veterinarianHomeVisit': homeVisit,
        'veterinarianEmergencyService': emergencyService,
        'veterinarianAnimalTypes': animalTypes,
        'veterinarianServices': services,
        'veterinarianCertifications': certifications,
        'veterinarianLanguages': languages,
        'veterinarianDocuments': documents,
        'veterinarianPhotoUrls': photoUrls,
        'veterinarianNotes': notes,
        'veterinarianEmergencyPhone': emergencyPhone,
        'veterinarianInsurance': insurance,
        'veterinarianRegions': regions,
        'veterinarianServiceDetails': serviceDetails,
        'veterinarianClinicType': clinicType,
        'veterinarianEducation': education,
        'veterinarianUniversity': university,
        'veterinarianGraduationYear': graduationYear,
        'veterinarianSpecializations': specializations,
        'veterinarianHasLaboratory': hasLaboratory,
        'veterinarianHasSurgery': hasSurgery,
        'veterinarianHasXRay': hasXRay,
        'veterinarianHasUltrasound': hasUltrasound,
        'veterinarianEquipmentList': equipmentList,
        'veterinarianEmergencyProtocol': emergencyProtocol,
      };
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .update(data);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veteriner profili kaydedildi.')),
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

  Widget _multiSelectField({
    required String label,
    required List<String> options,
    required List<String> selectedItems,
    required Function(List<String>) onSelectionChanged,
    String? hintText,
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
                padding:
                    const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
              ),
              onPressed: () async {
                final List<String> result = await showModalBottomSheet<
                        List<String>>(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.white,
                      shape: const RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.vertical(top: Radius.circular(24)),
                      ),
                      builder: (context) {
                        List<String> tempSelected =
                            List<String>.from(selectedItems);
                        String search = '';
                        return StatefulBuilder(
                          builder: (context, setModalState) {
                            final filtered = options
                                .where((option) => option
                                    .toLowerCase()
                                    .contains(search.toLowerCase()))
                                .toList();
                            return Padding(
                              padding: EdgeInsets.only(
                                top: 60,
                                bottom: 40 +
                                    MediaQuery.of(context).viewInsets.bottom,
                                left: 16,
                                right: 16,
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 40,
                                    height: 4,
                                    margin: const EdgeInsets.only(bottom: 16),
                                    decoration: BoxDecoration(
                                      color: dividerColor,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                  TextField(
                                    decoration: InputDecoration(
                                      hintText: hintText ?? 'Ara',
                                      prefixIcon: const Icon(Icons.search),
                                      filled: true,
                                      fillColor: surfaceColor,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 12),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: BorderSide(
                                            color: dividerColor, width: 1),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: BorderSide(
                                            color: dividerColor, width: 1),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: BorderSide(
                                            color: primaryColor, width: 2),
                                      ),
                                    ),
                                    onChanged: (v) =>
                                        setModalState(() => search = v),
                                  ),
                                  const SizedBox(height: 12),
                                  Expanded(
                                    child: Scrollbar(
                                      child: ListView.builder(
                                        itemCount: filtered.length,
                                        itemBuilder: (context, i) {
                                          final option = filtered[i];
                                          final selected =
                                              tempSelected.contains(option);
                                          return CheckboxListTile(
                                            value: selected,
                                            title: Text(option),
                                            activeColor: primaryColor,
                                            onChanged: (val) {
                                              setModalState(() {
                                                if (val == true) {
                                                  tempSelected.add(option);
                                                } else {
                                                  tempSelected.remove(option);
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
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: primaryColor,
                                        foregroundColor: backgroundColor,
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12)),
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 14),
                                      ),
                                      onPressed: () {
                                        Navigator.pop(context, tempSelected);
                                      },
                                      child: const Text('Seçimi Onayla'),
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
                    selectedItems;
                onSelectionChanged(result);
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      selectedItems.isEmpty
                          ? 'Seçin'
                          : selectedItems.join(', '),
                      style: GoogleFonts.poppins(
                        color:
                            selectedItems.isEmpty ? textSecondary : textPrimary,
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
            children: selectedItems
                .map((item) => Chip(
                      label: Text(item),
                      deleteIcon: const Icon(Icons.close, size: 18),
                      onDeleted: () {
                        final newList = List<String>.from(selectedItems);
                        newList.remove(item);
                        onSelectionChanged(newList);
                      },
                    ))
                .toList(),
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
          'Veteriner Profilini Düzenle',
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
                title: 'Klinik Bilgileri',
                icon: Icons.local_hospital,
                children: [
                  _formField(
                    label: 'Klinik Adı',
                    initialValue: clinicName,
                    hintText: 'Klinik adı',
                    onSaved: (v) => clinicName = v,
                  ),
                  _formField(
                    label: 'Telefon',
                    initialValue: phone,
                    hintText: 'Telefon numarası',
                    keyboardType: TextInputType.phone,
                    onSaved: (v) => phone = v,
                  ),
                  _formField(
                    label: 'E-posta',
                    initialValue: email,
                    hintText: 'E-posta adresi',
                    keyboardType: TextInputType.emailAddress,
                    onSaved: (v) => email = v,
                  ),
                  _formField(
                    label: 'Acil Telefon',
                    initialValue: emergencyPhone,
                    hintText: 'Acil durum telefonu',
                    keyboardType: TextInputType.phone,
                    onSaved: (v) => emergencyPhone = v,
                  ),
                  _formField(
                    label: 'Adres',
                    initialValue: address,
                    hintText: 'Klinik adresi',
                    maxLines: 2,
                    onSaved: (v) => address = v,
                  ),
                  _formField(
                    label: 'Klinik Tipi',
                    initialValue: clinicType,
                    hintText: 'Örn: Özel Klinik, Devlet Kliniği',
                    onSaved: (v) => clinicType = v,
                  ),
                  _formField(
                    label: 'Çalışma Saatleri',
                    initialValue: workingHours,
                    hintText: 'Örn: 08:00-20:00',
                    onSaved: (v) => workingHours = v,
                  ),
                ],
              ),
              _card(
                title: 'Eğitim ve Uzmanlık',
                icon: Icons.school,
                children: [
                  _formField(
                    label: 'Üniversite',
                    initialValue: university,
                    hintText: 'Mezun olduğunuz üniversite',
                    onSaved: (v) => university = v,
                  ),
                  _formField(
                    label: 'Mezuniyet Yılı',
                    initialValue: graduationYear?.toString(),
                    hintText: 'Yıl',
                    keyboardType: TextInputType.number,
                    onSaved: (v) => graduationYear = int.tryParse(v ?? ''),
                  ),
                  _formField(
                    label: 'Deneyim (yıl)',
                    initialValue: yearsExperience?.toString(),
                    hintText: 'Yıl',
                    keyboardType: TextInputType.number,
                    onSaved: (v) => yearsExperience = int.tryParse(v ?? ''),
                  ),
                  _formField(
                    label: 'Ruhsat Numarası',
                    initialValue: licenseNumber,
                    hintText: 'Veteriner hekim ruhsat numarası',
                    onSaved: (v) => licenseNumber = v,
                  ),
                  _multiSelectField(
                    label: 'Uzmanlık Alanları',
                    options: veterinarianSpecializations,
                    selectedItems: specializations,
                    onSelectionChanged: (value) =>
                        setState(() => specializations = value),
                    hintText: 'Uzmanlık alanı ara',
                  ),
                ],
              ),
              _card(
                title: 'Hizmet Bölgesi',
                icon: Icons.location_on,
                children: [
                  _multiSelectField(
                    label: 'Hizmet Verilen Şehirler',
                    options: turkishCities,
                    selectedItems: cities,
                    onSelectionChanged: (value) =>
                        setState(() => cities = value),
                    hintText: 'Şehir ara',
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
                ],
              ),
              _card(
                title: 'Hizmetler ve Hayvan Türleri',
                icon: Icons.pets,
                children: [
                  _multiSelectField(
                    label: 'Hizmet Verdiği Hayvan Türleri',
                    options: animalTypesList,
                    selectedItems: animalTypes,
                    onSelectionChanged: (value) =>
                        setState(() => animalTypes = value),
                    hintText: 'Hayvan türü ara',
                  ),
                  _multiSelectField(
                    label: 'Sunulan Hizmetler',
                    options: veterinarianServices,
                    selectedItems: services,
                    onSelectionChanged: (value) =>
                        setState(() => services = value),
                    hintText: 'Hizmet ara',
                  ),
                ],
              ),
              _card(
                title: 'Fiyatlandırma',
                icon: Icons.attach_money,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _formField(
                          label: 'Muayene Ücreti (₺)',
                          controller: _consultationFeeController,
                          keyboardType: TextInputType.number,
                          onChanged: (v) {
                            final formatted = _formatNumber(v);
                            if (formatted != _consultationFeeController.text) {
                              _consultationFeeController.value =
                                  TextEditingValue(
                                text: formatted,
                                selection: TextSelection.collapsed(
                                    offset: formatted.length),
                              );
                            }
                          },
                          onSaved: (v) => consultationFee = double.tryParse(
                              _unformatNumber(_consultationFeeController.text)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _formField(
                          label: 'Acil Ücret (₺)',
                          controller: _emergencyFeeController,
                          keyboardType: TextInputType.number,
                          onChanged: (v) {
                            final formatted = _formatNumber(v);
                            if (formatted != _emergencyFeeController.text) {
                              _emergencyFeeController.value = TextEditingValue(
                                text: formatted,
                                selection: TextSelection.collapsed(
                                    offset: formatted.length),
                              );
                            }
                          },
                          onSaved: (v) => emergencyFee = double.tryParse(
                              _unformatNumber(_emergencyFeeController.text)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              _card(
                title: 'Klinik Özellikleri',
                icon: Icons.medical_services,
                children: [
                  SwitchListTile(
                    value: available,
                    onChanged: (v) => setState(() => available = v),
                    title: Text('Şu an müsaitim',
                        style:
                            GoogleFonts.poppins(fontWeight: FontWeight.w500)),
                    activeColor: primaryColor,
                  ),
                  SwitchListTile(
                    value: homeVisit,
                    onChanged: (v) => setState(() => homeVisit = v),
                    title: Text('Ev Ziyareti Yapıyorum',
                        style:
                            GoogleFonts.poppins(fontWeight: FontWeight.w500)),
                    activeColor: primaryColor,
                  ),
                  SwitchListTile(
                    value: emergencyService,
                    onChanged: (v) => setState(() => emergencyService = v),
                    title: Text('Acil Hizmet Veriyorum',
                        style:
                            GoogleFonts.poppins(fontWeight: FontWeight.w500)),
                    activeColor: primaryColor,
                  ),
                  SwitchListTile(
                    value: hasLaboratory,
                    onChanged: (v) => setState(() => hasLaboratory = v),
                    title: Text('Laboratuvar Hizmeti',
                        style:
                            GoogleFonts.poppins(fontWeight: FontWeight.w500)),
                    activeColor: primaryColor,
                  ),
                  SwitchListTile(
                    value: hasSurgery,
                    onChanged: (v) => setState(() => hasSurgery = v),
                    title: Text('Cerrahi Müdahale',
                        style:
                            GoogleFonts.poppins(fontWeight: FontWeight.w500)),
                    activeColor: primaryColor,
                  ),
                  SwitchListTile(
                    value: hasXRay,
                    onChanged: (v) => setState(() => hasXRay = v),
                    title: Text('Radyografi (X-Ray)',
                        style:
                            GoogleFonts.poppins(fontWeight: FontWeight.w500)),
                    activeColor: primaryColor,
                  ),
                  SwitchListTile(
                    value: hasUltrasound,
                    onChanged: (v) => setState(() => hasUltrasound = v),
                    title: Text('Ultrasonografi',
                        style:
                            GoogleFonts.poppins(fontWeight: FontWeight.w500)),
                    activeColor: primaryColor,
                  ),
                  SwitchListTile(
                    value: insurance,
                    onChanged: (v) => setState(() => insurance = v),
                    title: Text('Mesleki Sorumluluk Sigortası',
                        style:
                            GoogleFonts.poppins(fontWeight: FontWeight.w500)),
                    activeColor: primaryColor,
                  ),
                ],
              ),
              _card(
                title: 'Klinik Fotoğrafları',
                icon: Icons.photo_library,
                children: [
                  _buildPhotoGallery(),
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
                    maxLines: 3,
                    onSaved: (v) => description = v,
                  ),
                  _formField(
                    label: 'Ekipman Listesi',
                    initialValue: equipmentList,
                    hintText: 'Klinikte bulunan ekipmanlar',
                    maxLines: 2,
                    onSaved: (v) => equipmentList = v,
                  ),
                  _formField(
                    label: 'Acil Durum Protokolü',
                    initialValue: emergencyProtocol,
                    hintText: 'Acil durumlarda izlenen prosedürler',
                    maxLines: 2,
                    onSaved: (v) => emergencyProtocol = v,
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
                    label: 'Sertifikalar',
                    initialValue: certifications.join(', '),
                    hintText: 'Örn: ISO 9001, Kalite Belgesi',
                    onSaved: (v) => certifications = v!
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

// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:io' as io;
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animal_trade/screens/profile_screen2.dart';

const String defaultProfilePicture =
    "https://firebasestorage.googleapis.com/v0/b/canlipazar-b3697.firebasestorage.app/o/defaulprofilephoto%2FdefaultProfilePhoto.png?alt=media&token=f2500621-2916-4601-bcbe-93c63d7fa802";

class EditProfileScreen extends StatefulWidget {
  final String userId;

  const EditProfileScreen({
    Key? key,
    required this.userId,
  }) : super(key: key);

  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _workingHoursController = TextEditingController();
  final TextEditingController _farmAddressController = TextEditingController();
  final TextEditingController _experienceController = TextEditingController();

  XFile? _imageFile;
  bool _isLoading = false;
  String? _photoUrl;
  Uint8List? _webImage;

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

  // Dropdown değerleri
  String? _selectedFarmerType;
  String? _selectedTransportAvailable;
  String? _selectedFarmSize;
  bool _hasVeterinarySupport = false;
  bool _hasHealthCertificate = false;

  // Multi-select listeler
  Map<String, int> _animalCounts = {};

  // Dropdown seçenekleri
  final List<String> _farmerTypes = [
    'Bireysel',
    'Çiftlik',
    'Kooperatif',
    'Ticari',
  ];

  final List<String> _transportOptions = [
    'Mevcut',
    'Mevcut değil',
    'Ücreti karşılığında',
  ];

  final List<String> _farmSizes = [
    'Küçük (1-10 hayvan)',
    'Orta (11-50 hayvan)',
    'Büyük (50+ hayvan)',
  ];

  final List<String> _animalTypes = [
    'Süt Sığırı',
    'Et Sığırı',
    'Damızlık Boğa',
    'Düve',
    'Manda',
    'Tosun',
    'Koyun',
    'Keçi',
    'Kuzu',
    'Oğlak',
    'Koç',
    'Teke',
  ];

  @override
  void initState() {
    super.initState();
    _initializeUserData();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _bioController.dispose();
    _phoneController.dispose();
    _workingHoursController.dispose();
    _farmAddressController.dispose();
    _experienceController.dispose();
    super.dispose();
  }

  Future<void> _initializeUserData() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .get();

      if (!mounted) return;

      // Güvenli veri okuma
      final data = userDoc.data() ?? {};

      setState(() {
        _usernameController.text = data['username'] ?? '';
        _bioController.text = data['bio'] ?? '';
        _photoUrl = data['photoUrl'];

        // Çiftçi bilgilerini yükle
        _phoneController.text = data['phoneNumber'] ?? '';
        _workingHoursController.text = data['workingHours'] ?? '';
        _farmAddressController.text = data['farmAddress'] ?? '';
        _experienceController.text = data['experienceYears']?.toString() ?? '';

        _selectedFarmerType = data['farmerType'];
        _selectedTransportAvailable = data['transportAvailable'];
        _selectedFarmSize = data['farmSize'];
        _hasVeterinarySupport = data['hasVeterinarySupport'] ?? false;
        _hasHealthCertificate = data['hasHealthCertificate'] ?? false;

        // List alanlarını yükle
        final animalCounts = data['animalCounts'];
        _animalCounts = animalCounts is Map
            ? Map<String, int>.from(animalCounts.map((k, v) => MapEntry(
                k.toString(),
                (v is int) ? v : int.tryParse(v.toString()) ?? 0)))
            : {};

        _isLoading = false;
      });

      // Eksik alanları Firestore'a ekle
      await _ensureAllFieldsExist(data);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      _showError('Error loading profile: $e');
    }
  }

  Future<void> _ensureAllFieldsExist(Map<String, dynamic> data) async {
    try {
      Map<String, dynamic> updates = {};

      // Eksik alanları tespit et ve varsayılan değerler ekle
      if (!data.containsKey('hasHealthCertificate')) {
        updates['hasHealthCertificate'] = false;
      }
      if (!data.containsKey('hasVeterinarySupport')) {
        updates['hasVeterinarySupport'] = false;
      }
      if (!data.containsKey('animalCounts')) {
        updates['animalCounts'] = <String, int>{};
      }
      if (!data.containsKey('certifications')) {
        updates['certifications'] = <String>[];
      }
      if (!data.containsKey('phoneNumber')) {
        updates['phoneNumber'] = '';
      }
      if (!data.containsKey('workingHours')) {
        updates['workingHours'] = '';
      }
      if (!data.containsKey('farmAddress')) {
        updates['farmAddress'] = '';
      }
      if (!data.containsKey('experienceYears')) {
        updates['experienceYears'] = 0;
      }

      // Eğer eksik alanlar varsa Firestore'u güncelle
      if (updates.isNotEmpty) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.userId)
            .update(updates);
        print('Missing fields added to user document: ${updates.keys}');
      }
    } catch (e) {
      print('Error ensuring fields exist: $e');
      // Bu hata kritik değil, sessizce devam et
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _handleImageSelection(ImageSource source) async {
    if (!mounted) return;

    Navigator.pop(context);
    try {
      // Web platformu için farklı davranış
      if (kIsWeb) {
        if (source == ImageSource.camera) {
          _showError(
              'Camera is not supported on web. Please choose from gallery instead.');
          return;
        }

        final XFile? imageFile =
            await ImagePicker().pickImage(source: ImageSource.gallery);
        if (imageFile != null && mounted) {
          final imageBytes = await imageFile.readAsBytes();
          setState(() {
            _webImage = imageBytes;
            _imageFile = imageFile;
            _photoUrl = null;
          });
        }
      } else {
        // Mobil platformlar için normal davranış
        final XFile? imageFile = await ImagePicker().pickImage(source: source);
        if (imageFile != null && mounted) {
          setState(() {
            _imageFile = imageFile;
            _photoUrl = null;
          });
        }
      }
    } catch (e) {
      _showError('Error selecting image: $e');
    }
  }

  Future<void> _saveChanges() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      if (_usernameController.text.trim().isEmpty) {
        throw 'Username cannot be empty';
      }

      String imageUrl = _photoUrl ?? defaultProfilePicture;

      if (_imageFile != null) {
        final Reference storageRef = FirebaseStorage.instance
            .ref()
            .child('profile_images')
            .child('${widget.userId}.jpg');

        UploadTask? uploadTask;

        if (kIsWeb) {
          // Web için sadece bytes kullanarak yükleme yapıyoruz
          if (_webImage != null) {
            // Web platformu için metadata
            SettableMetadata metadata = SettableMetadata(
              contentType: 'image/jpeg',
              customMetadata: {'uploaded-from': 'web'},
            );
            uploadTask = storageRef.putData(_webImage!, metadata);
          } else {
            throw 'Web image data is missing';
          }
        } else {
          // Mobil için File kullanıyoruz
          uploadTask = storageRef.putFile(io.File(_imageFile!.path));
        }

        if (uploadTask != null) {
          final TaskSnapshot downloadUrl = await uploadTask;
          imageUrl = await downloadUrl.ref.getDownloadURL();
        }
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .update({
        'username': _usernameController.text.trim(),
        'bio': _bioController.text.trim(),
        'photoUrl': imageUrl,

        // Çiftçi bilgilerini kaydet
        'phoneNumber': _phoneController.text.trim(),
        'workingHours': _workingHoursController.text.trim(),
        'farmAddress': _farmAddressController.text.trim(),
        'experienceYears': int.tryParse(_experienceController.text) ?? 0,

        'farmerType': _selectedFarmerType,
        'transportAvailable': _selectedTransportAvailable,
        'farmSize': _selectedFarmSize,
        'hasVeterinarySupport': _hasVeterinarySupport,
        'hasHealthCertificate': _hasHealthCertificate,

        'animalCounts': _animalCounts,
      });

      if (!mounted) return;

      // Profil sayfasına yönlendir
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => ProfileScreen2(
            uid: widget.userId,
            snap: {},
            userId: widget.userId,
          ),
        ),
      );

      // Başarı mesajı göster
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Profil bilgileriniz başarıyla güncellendi',
            style: GoogleFonts.poppins(
              color: backgroundColor,
            ),
          ),
          backgroundColor: successColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      _showError(e.toString());
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildImageSelectionDialog() {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: dividerColor,
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Profil Fotoğrafını Değiştir',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 20),
            if (!kIsWeb)
              _buildImageOption(
                icon: Icons.camera_alt_rounded,
                label: 'Fotoğraf Çek',
                onTap: () => _handleImageSelection(ImageSource.camera),
              ),
            if (!kIsWeb) Divider(color: dividerColor),
            _buildImageOption(
              icon: Icons.photo_library_rounded,
              label: 'Galeriden Seç',
              onTap: () => _handleImageSelection(ImageSource.gallery),
            ),
            if (_photoUrl != defaultProfilePicture) ...[
              Divider(color: dividerColor),
              _buildImageOption(
                icon: Icons.delete_outline_rounded,
                label: 'Mevcut Fotoğrafı Kaldır',
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _imageFile = null;
                    _webImage = null;
                    _photoUrl = defaultProfilePicture;
                  });
                },
                isDestructive: true,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildImageOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Row(
          children: [
            Icon(
              icon,
              color: isDestructive ? errorColor : textPrimary,
              size: 24,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: isDestructive ? errorColor : textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileImage() {
    return Stack(
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: dividerColor,
              width: 3,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(60),
            child: _photoUrl != null
                ? Image.network(
                    _photoUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      print('Error loading profile image: $error');
                      return Image.network(
                        defaultProfilePicture,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: surfaceColor,
                            child: Icon(
                              Icons.person,
                              color: textSecondary,
                              size: 60.0,
                            ),
                          );
                        },
                      );
                    },
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        color: surfaceColor,
                        child: Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                            color: primaryColor,
                          ),
                        ),
                      );
                    },
                  )
                : kIsWeb
                    ? _webImage != null
                        ? Image.memory(
                            _webImage!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              print('Error loading web image: $error');
                              return Container(
                                color: surfaceColor,
                                child: Icon(
                                  Icons.person,
                                  color: textSecondary,
                                  size: 60.0,
                                ),
                              );
                            },
                          )
                        : Image.network(
                            defaultProfilePicture,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: surfaceColor,
                                child: Icon(
                                  Icons.person,
                                  color: textSecondary,
                                  size: 60.0,
                                ),
                              );
                            },
                          )
                    : _imageFile != null
                        ? kIsWeb
                            ? Container(
                                color: surfaceColor,
                                child: Icon(
                                  Icons.person,
                                  color: textSecondary,
                                  size: 60.0,
                                ),
                              )
                            : Image.file(
                                io.File(_imageFile!.path),
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  print('Error loading file image: $error');
                                  return Container(
                                    color: surfaceColor,
                                    child: Icon(
                                      Icons.person,
                                      color: textSecondary,
                                      size: 60.0,
                                    ),
                                  );
                                },
                              )
                        : Image.network(
                            defaultProfilePicture,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: surfaceColor,
                                child: Icon(
                                  Icons.person,
                                  color: textSecondary,
                                  size: 60.0,
                                ),
                              );
                            },
                          ),
          ),
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: GestureDetector(
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => _buildImageSelectionDialog(),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: primaryColor,
                shape: BoxShape.circle,
                border: Border.all(
                  color: backgroundColor,
                  width: 2,
                ),
              ),
              child: const Icon(
                Icons.camera_alt,
                color: backgroundColor,
                size: 20,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileImageSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(24),
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
          Text(
            'Profil Fotoğrafı',
            style: GoogleFonts.poppins(
              color: textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20),
          _buildProfileImage(),
          const SizedBox(height: 16),
          Text(
            'Fotoğrafınızı güncellemek için üzerine dokunun',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              color: textSecondary,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: backgroundColor,
        title: Text(
          'Profili Düzenle',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: textPrimary,
          ),
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: textPrimary,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (!_isLoading)
            TextButton(
              onPressed: _saveChanges,
              child: Text(
                'Kaydet',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: primaryColor,
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: primaryColor,
              ),
            )
          : SafeArea(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 20),
                      // Profile Image Section
                      _buildProfileImageSection(),
                      const SizedBox(height: 32),

                      // Basic Info Card
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: backgroundColor,
                          borderRadius: BorderRadius.circular(16),
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
                                const Icon(
                                  Icons.person,
                                  color: primaryColor,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Temel Bilgiler',
                                  style: GoogleFonts.poppins(
                                    color: textPrimary,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            _buildTextField(
                              controller: _usernameController,
                              label: 'Kullanıcı Adı',
                              maxLength: 25,
                            ),
                            const SizedBox(height: 16),
                            _buildTextField(
                              controller: _bioController,
                              label: 'Hakkımda',
                              maxLength: 100,
                              maxLines: 3,
                            ),
                            const SizedBox(height: 16),
                            _buildTextField(
                              controller: _phoneController,
                              label: 'Telefon Numarası',
                              maxLength: 15,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Farmer Info Card
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: backgroundColor,
                          borderRadius: BorderRadius.circular(16),
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
                            const SizedBox(height: 20),
                            _buildDropdownField(
                              label: 'Çiftçi Tipi',
                              value: _selectedFarmerType,
                              items: _farmerTypes,
                              onChanged: (value) =>
                                  setState(() => _selectedFarmerType = value),
                            ),
                            const SizedBox(height: 16),
                            _buildTextField(
                              controller: _workingHoursController,
                              label: 'Çalışma Saatleri (örn: 09:00-18:00)',
                              maxLength: 20,
                            ),
                            const SizedBox(height: 16),
                            _buildTextField(
                              controller: _experienceController,
                              label: 'Deneyim (Yıl)',
                              maxLength: 2,
                            ),
                            const SizedBox(height: 16),
                            _buildDropdownField(
                              label: 'Nakliye Durumu',
                              value: _selectedTransportAvailable,
                              items: _transportOptions,
                              onChanged: (value) => setState(
                                  () => _selectedTransportAvailable = value),
                            ),
                            const SizedBox(height: 16),
                            _buildDropdownField(
                              label: 'Çiftlik Büyüklüğü',
                              value: _selectedFarmSize,
                              items: _farmSizes,
                              onChanged: (value) =>
                                  setState(() => _selectedFarmSize = value),
                            ),
                            const SizedBox(height: 16),
                            _buildTextField(
                              controller: _farmAddressController,
                              label: 'Çiftlik Adresi',
                              maxLength: 200,
                              maxLines: 2,
                            ),
                            const SizedBox(height: 16),

                            // Veteriner Desteği ve Sağlık Belgesi Switch'leri
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: dividerColor,
                                ),
                                color: surfaceColor,
                              ),
                              child: Column(
                                children: [
                                  SwitchListTile(
                                    title: Text(
                                      'Veteriner Desteği Mevcut',
                                      style: GoogleFonts.poppins(
                                        color: textPrimary,
                                        fontSize: 14,
                                      ),
                                    ),
                                    value: _hasVeterinarySupport,
                                    onChanged: (value) => setState(
                                        () => _hasVeterinarySupport = value),
                                    activeColor: successColor,
                                  ),
                                  Divider(height: 1, color: dividerColor),
                                  SwitchListTile(
                                    title: Text(
                                      'Sağlık Belgesi Mevcut',
                                      style: GoogleFonts.poppins(
                                        color: textPrimary,
                                        fontSize: 14,
                                      ),
                                    ),
                                    value: _hasHealthCertificate,
                                    onChanged: (value) => setState(
                                        () => _hasHealthCertificate = value),
                                    activeColor: successColor,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Animal Counts Card
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: backgroundColor,
                          borderRadius: BorderRadius.circular(16),
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
                                const Icon(
                                  Icons.pets,
                                  color: primaryColor,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Hayvan Sayıları',
                                  style: GoogleFonts.poppins(
                                    color: textPrimary,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            _buildAnimalCountsField(),
                          ],
                        ),
                      ),

                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildBasicInfoCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(color: dividerColor),
      ),
      color: backgroundColor,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Temel Bilgiler',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 20),
            _buildTextField(
              controller: _usernameController,
              label: 'Kullanıcı Adı',
              maxLength: 25,
            ),
            const SizedBox(height: 20),
            _buildTextField(
              controller: _bioController,
              label: 'Bio',
              maxLength: 100,
              maxLines: 3,
            ),
            const SizedBox(height: 20),
            _buildTextField(
              controller: _phoneController,
              label: 'Telefon Numarası',
              maxLength: 15,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFarmerInfoCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(color: dividerColor),
      ),
      color: backgroundColor,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Çiftçi Bilgileri',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 20),
            _buildTextField(
              controller: _workingHoursController,
              label: 'Çalışma Saatleri (örn: 09:00-18:00)',
              maxLength: 20,
            ),
            const SizedBox(height: 20),
            _buildTextField(
              controller: _experienceController,
              label: 'Deneyim (Yıl)',
              maxLength: 2,
            ),
            const SizedBox(height: 20),
            _buildDropdownField(
              label: 'Nakliye Durumu',
              value: _selectedTransportAvailable,
              items: _transportOptions,
              onChanged: (value) =>
                  setState(() => _selectedTransportAvailable = value),
            ),
            const SizedBox(height: 20),
            _buildDropdownField(
              label: 'Çiftlik Büyüklüğü',
              value: _selectedFarmSize,
              items: _farmSizes,
              onChanged: (value) => setState(() => _selectedFarmSize = value),
            ),
            const SizedBox(height: 20),
            _buildTextField(
              controller: _farmAddressController,
              label: 'Çiftlik Adresi',
              maxLength: 200,
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimalCountsField() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: dividerColor,
        ),
        color: surfaceColor,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Mevcut hayvan sayıları
            if (_animalCounts.isNotEmpty) ...[
              ..._animalCounts.entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: primaryColor.withOpacity(0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.pets,
                          color: primaryColor,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${entry.key}: ${entry.value} adet',
                            style: GoogleFonts.poppins(
                              color: primaryColor,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => _editAnimalCount(entry.key, entry.value),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            child: Icon(
                              Icons.edit,
                              color: primaryColor.withOpacity(0.7),
                              size: 16,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _animalCounts.remove(entry.key);
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            child: Icon(
                              Icons.delete_outline,
                              color: errorColor.withOpacity(0.7),
                              size: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
              const SizedBox(height: 12),
            ],
            // + Butonu
            GestureDetector(
              onTap: _showAddAnimalDialog,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: primaryColor.withOpacity(0.3),
                    style: BorderStyle.solid,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.add_circle_outline,
                      color: primaryColor,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Hayvan Türü Ekle',
                      style: GoogleFonts.poppins(
                        color: primaryColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
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

  void _showAddAnimalDialog() {
    // Henüz eklenmemiş hayvan türlerini filtrele
    final availableAnimals = _animalTypes
        .where((animal) => !_animalCounts.containsKey(animal))
        .toList();

    if (availableAnimals.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Tüm hayvan türleri zaten eklenmiş',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: warningColor,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: dividerColor,
                width: 1,
              ),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.pets,
                        color: primaryColor,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Hayvan Türü Seçin',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Container(
                    constraints: const BoxConstraints(maxHeight: 300),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: dividerColor,
                      ),
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        children: availableAnimals.map((animalType) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8.0,
                              vertical: 4.0,
                            ),
                            child: ListTile(
                              leading: const Icon(
                                Icons.pets,
                                color: accentColor,
                                size: 20,
                              ),
                              title: Text(
                                animalType,
                                style: GoogleFonts.poppins(
                                  color: textPrimary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              trailing: Icon(
                                Icons.arrow_forward_ios,
                                color: textSecondary,
                                size: 16,
                              ),
                              onTap: () {
                                Navigator.pop(context);
                                _showCountDialog(animalType);
                              },
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              tileColor: surfaceColor,
                              hoverColor: primaryColor.withOpacity(0.1),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                        child: Text(
                          'İptal',
                          style: GoogleFonts.poppins(
                            color: textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showCountDialog(String animalType, {int? currentCount}) {
    final TextEditingController countController = TextEditingController(
      text: currentCount?.toString() ?? '',
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: dividerColor,
                width: 1,
              ),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.pets,
                      color: primaryColor,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    animalType,
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Kaç adet ${animalType.toLowerCase()} bulunuyor?',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: primaryColor.withOpacity(0.3),
                        width: 2,
                      ),
                      color: backgroundColor,
                    ),
                    child: TextFormField(
                      controller: countController,
                      keyboardType: TextInputType.number,
                      style: GoogleFonts.poppins(
                        color: textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                        hintText: 'Adet sayısını girin',
                        hintStyle: GoogleFonts.poppins(
                          color: textSecondary,
                          fontSize: 14,
                        ),
                      ),
                      autofocus: true,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: BorderSide(
                                color: dividerColor,
                              ),
                            ),
                          ),
                          child: Text(
                            'İptal',
                            style: GoogleFonts.poppins(
                              color: textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            final count =
                                int.tryParse(countController.text) ?? 0;
                            if (count > 0) {
                              setState(() {
                                _animalCounts[animalType] = count;
                              });
                              Navigator.pop(context);
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Lütfen geçerli bir sayı girin',
                                    style: GoogleFonts.poppins(
                                      color: backgroundColor,
                                    ),
                                  ),
                                  backgroundColor: errorColor,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: backgroundColor,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            currentCount != null ? 'Güncelle' : 'Ekle',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _editAnimalCount(String animalType, int currentCount) {
    _showCountDialog(animalType, currentCount: currentCount);
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required int maxLength,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLength: maxLength,
      maxLines: maxLines,
      style: GoogleFonts.poppins(
        color: textPrimary,
        fontSize: 16,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.poppins(
          color: textSecondary,
          fontSize: 14,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: dividerColor,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: primaryColor,
            width: 2,
          ),
        ),
        filled: true,
        fillColor: surfaceColor,
        counterStyle: GoogleFonts.poppins(
          color: textSecondary,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            color: textSecondary,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: dividerColor,
            ),
            color: surfaceColor,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: DropdownButtonFormField<String>(
              value: value,
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: 'Seçiniz...',
                hintStyle: GoogleFonts.poppins(
                  color: textSecondary,
                ),
              ),
              items: items.map((String item) {
                return DropdownMenuItem<String>(
                  value: item,
                  child: Text(
                    item,
                    style: GoogleFonts.poppins(
                      color: textPrimary,
                      fontSize: 16,
                    ),
                  ),
                );
              }).toList(),
              onChanged: onChanged,
              style: GoogleFonts.poppins(
                color: textPrimary,
                fontSize: 16,
              ),
              dropdownColor: backgroundColor,
              icon: const Icon(
                Icons.arrow_drop_down,
                color: primaryColor,
              ),
              iconEnabledColor: primaryColor,
              iconDisabledColor: textSecondary,
              isExpanded: true,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }
}

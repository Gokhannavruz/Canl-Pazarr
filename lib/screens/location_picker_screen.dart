import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:permission_handler/permission_handler.dart';
import '../utils/animal_colors.dart';

import 'package:google_fonts/google_fonts.dart';

class LocationPickerScreen extends StatefulWidget {
  final VoidCallback? onLocationSelected;
  final bool isFromSettings;

  const LocationPickerScreen({
    Key? key,
    this.onLocationSelected,
    this.isFromSettings = false,
  }) : super(key: key);

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class SimpleLocation {
  final double latitude;
  final double longitude;

  const SimpleLocation(this.latitude, this.longitude);

  @override
  String toString() => 'SimpleLocation($latitude, $longitude)';
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  SimpleLocation? _selectedLocation;
  SimpleLocation? _currentLocation;
  bool _isLoading = false;
  bool _isLocationServiceEnabled = false;
  bool _hasLocationPermission = false;
  String _selectedAddress = '';

  // Konum bilgileri
  String _neighborhood = '';
  String _district = '';
  String _city = '';
  String _province = '';
  String _country = '';

  @override
  void initState() {
    super.initState();
    // Sayfa açıldıktan 2 saniye sonra konum izni iste
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        _checkLocationStatus();
      }
    });
  }

  Future<void> _checkLocationStatus() async {
    try {
      if (mounted) {
        setState(() {
          _isLoading = true;
        });
      }

      // Önce konum izni durumunu kontrol et
      LocationPermission permission = await Geolocator.checkPermission();
      bool hasPermission = permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always;

      if (mounted) {
        setState(() {
          _hasLocationPermission = hasPermission;
        });
      }

      // İzin yoksa önce izin iste
      if (!hasPermission) {
        await _requestLocationPermission();
        return; // _requestLocationPermission içinde konum servisi kontrolü yapılacak
      }

      // İzin varsa konum servisini kontrol et
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();

      if (mounted) {
        setState(() {
          _isLocationServiceEnabled = serviceEnabled;
        });
      }

      // Konum servisi kapalıysa dialog göster
      if (!serviceEnabled) {
        _showLocationServiceDialog();
        return;
      }

      // Her şey tamam ise konumu al
      if (serviceEnabled && hasPermission) {
        await _getCurrentLocation();
      }
    } catch (e) {
      debugPrint('Konum durumu kontrol hatası: $e');
      // Hata durumunda kullanıcıya mesaj gösterme, sadece log
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showLocationWarning() {
    if (!_isLocationServiceEnabled && !_hasLocationPermission) {
      _showLocationAndPermissionDialog();
    } else if (!_isLocationServiceEnabled) {
      _showLocationServiceDialog();
    } else if (!_hasLocationPermission) {
      _showPermissionDialog();
    }
  }

  String _getLocationWarningMessage() {
    if (!_isLocationServiceEnabled && !_hasLocationPermission) {
      return 'Konumunuzu otomatik olarak belirlemek için konum servisini açın ve uygulama iznini verin.';
    } else if (!_isLocationServiceEnabled) {
      return 'Konumunuzu otomatik olarak belirlemek için konum servisini açın.';
    } else if (!_hasLocationPermission) {
      return 'Konumunuzu otomatik olarak belirlemek için konum iznini verin.';
    }
    return '';
  }

  Future<void> _handleLocationFix() async {
    try {
      // Önce konum servisini kontrol et ve gerekirse aç
      if (!_isLocationServiceEnabled) {
        await _enableLocationService();
        return; // _enableLocationService içinde zaten _requestLocationPermission çağrılacak
      }

      // Konum servisi açık ama izin yoksa izin iste
      if (!_hasLocationPermission) {
        await _requestLocationPermission();
        return;
      }

      // Her şey tamam ise konumu al
      if (_isLocationServiceEnabled && _hasLocationPermission) {
        await _getCurrentLocation();
      }
    } catch (e) {
      debugPrint('Konum düzeltme hatası: $e');
      // Hata durumunda kullanıcıya bilgi ver
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Konum ayarları yapılırken hata oluştu.'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _requestLocationPermission() async {
    try {
      // Önce Geolocator ile izin iste
      LocationPermission permission = await Geolocator.requestPermission();

      if (permission == LocationPermission.denied) {
        // Permission handler ile de dene
        var permissionStatus = await Permission.location.request();

        if (permissionStatus.isGranted) {
          permission = LocationPermission.whileInUse;
        }
      }

      if (mounted) {
        setState(() {
          _hasLocationPermission =
              permission == LocationPermission.whileInUse ||
                  permission == LocationPermission.always;
        });
      }

      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        // İzin alındı, şimdi konum servisini kontrol et
        bool serviceEnabled = await Geolocator.isLocationServiceEnabled();

        if (mounted) {
          setState(() {
            _isLocationServiceEnabled = serviceEnabled;
          });
        }

        if (!serviceEnabled) {
          // Konum servisi kapalıysa dialog göster
          _showLocationServiceDialog();
          return;
        }

        // Her şey tamam ise konumu al
        await _getCurrentLocation();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Konum izni verildi ve konumunuz belirlendi'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else if (permission == LocationPermission.deniedForever) {
        _showPermissionDeniedForeverDialog();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Konum izni verilmedi'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('İzin isteme hatası: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Konum izni istenirken hata oluştu'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _refreshLocation() async {
    // Mevcut konumu yeniden al
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      // Önce mevcut konum durumunu kontrol et
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      LocationPermission permission = await Geolocator.checkPermission();

      if (!serviceEnabled) {
        _showLocationServiceDialog();
        return;
      }

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _showPermissionDialog();
        return;
      }

      // Yeni konum al (yüksek doğruluk ile)
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      if (mounted) {
        setState(() {
          _currentLocation =
              SimpleLocation(position.latitude, position.longitude);
          _selectedLocation = _currentLocation;
        });
      }

      // Yeni adres bilgisini al
      await _getAddressFromSimpleLocation(_currentLocation!);

      // Başarı mesajı göster
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Konumunuz yeniden belirlendi'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('Konum yenileme hatası: $e');

      // LateInitializationError'ı özel olarak yakala
      if (e.toString().contains('LateInitializationError') ||
          e.toString().contains('_internalController')) {
        debugPrint(
            'FlutterMap initialization error caught and handled silently');
        // Bu hatayı kullanıcıya gösterme, sessizce devam et
        return;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Konum yenilenemedi, lütfen tekrar deneyin'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return _buildLocationSelector();
  }

  Widget _buildSafeFlutterMap() {
    // LateInitializationError'ı önlemek için FlutterMap'i kaldırıp
    // GPS tabanlı konum seçimi kullanıyoruz
    return _buildLocationSelector();
  }

  Widget _buildLocationSelector() {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFF1F8E9),
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Modern App Bar
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF2E7D32).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        icon: const Icon(
                          Icons.arrow_back_ios_new,
                          color: Color(0xFF2E7D32),
                          size: 20,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        'Konum Seçimi',
                        style: GoogleFonts.poppins(
                          color: const Color(0xFF212121),
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF2E7D32).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        icon: const Icon(
                          Icons.refresh,
                          color: Color(0xFF2E7D32),
                          size: 20,
                        ),
                        onPressed: () async {
                          await _checkLocationStatus();
                        },
                      ),
                    ),
                  ],
                ),
              ),

              // Ana İçerik
              Expanded(
                child: RefreshIndicator(
                  color: const Color(0xFF2E7D32),
                  onRefresh: () async {
                    await _checkLocationStatus();
                  },
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        const SizedBox(height: 20),

                        // Ana başlık kartı
                        Container(
                          padding: const EdgeInsets.all(28),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 20,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              // Animasyonlu İkon
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF2E7D32),
                                      Color(0xFF4CAF50),
                                    ],
                                  ),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF2E7D32)
                                          .withOpacity(0.3),
                                      blurRadius: 15,
                                      offset: const Offset(0, 5),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.location_on,
                                  size: 48,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 24),

                              // Başlık
                              Text(
                                'Konumunuzu Belirleyin',
                                style: GoogleFonts.poppins(
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF212121),
                                ),
                                textAlign: TextAlign.center,
                              ),

                              const SizedBox(height: 16),

                              // Açıklama
                              Text(
                                'Size en yakın hayvan ilanlarını gösterebilmek için konum bilginize ihtiyacımız var',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  color: const Color(0xFF757575),
                                  height: 1.5,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Mevcut konum gösterimi (eğer varsa)
                        if (_selectedLocation != null ||
                            _currentLocation != null ||
                            _isLoading)
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.08),
                                  blurRadius: 20,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Başlık
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF2E7D32)
                                            .withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Icon(
                                        Icons.my_location,
                                        color: Color(0xFF2E7D32),
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      'Mevcut Konum',
                                      style: GoogleFonts.poppins(
                                        color: const Color(0xFF212121),
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),

                                // Konum belirleniyor durumu
                                if (_isLoading)
                                  Container(
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF8F9FA),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: const Color(0xFFE9ECEF),
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        const SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.5,
                                            color: Color(0xFF2E7D32),
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Text(
                                            'Konum belirleniyor...',
                                            style: GoogleFonts.poppins(
                                              fontSize: 16,
                                              color: const Color(0xFF495057),
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                // Konum bilgileri
                                else if (_selectedAddress.isNotEmpty)
                                  Container(
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF8F9FA),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: const Color(0xFFE9ECEF),
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.location_on,
                                          color: Color(0xFF2E7D32),
                                          size: 20,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            _selectedAddress,
                                            style: GoogleFonts.poppins(
                                              fontSize: 16,
                                              color: const Color(0xFF212121),
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),

                        const SizedBox(height: 24),

                        // Seçenekler kartı
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 20,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF2E7D32)
                                          .withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(
                                      Icons.settings,
                                      color: Color(0xFF2E7D32),
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Konum Seçenekleri',
                                    style: GoogleFonts.poppins(
                                      color: const Color(0xFF212121),
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              _buildModernOptionCard(
                                title: _isLocationServiceEnabled &&
                                        _hasLocationPermission
                                    ? 'GPS ile Belirle'
                                    : 'GPS İzni Ver',
                                subtitle: _isLocationServiceEnabled &&
                                        _hasLocationPermission
                                    ? 'Mevcut konumunuzu otomatik olarak belirleyin'
                                    : 'Konum izni vererek otomatik konum belirleme',
                                icon: _isLocationServiceEnabled &&
                                        _hasLocationPermission
                                    ? Icons.my_location
                                    : Icons.location_disabled,
                                iconColor: _isLocationServiceEnabled &&
                                        _hasLocationPermission
                                    ? const Color(0xFF2E7D32)
                                    : const Color(0xFFFF9800),
                                backgroundColor: _isLocationServiceEnabled &&
                                        _hasLocationPermission
                                    ? const Color(0xFF2E7D32).withOpacity(0.1)
                                    : const Color(0xFFFF9800).withOpacity(0.1),
                                onTap: _isLocationServiceEnabled &&
                                        _hasLocationPermission
                                    ? _getCurrentLocation
                                    : _handleLocationFix,
                              ),
                              if (_selectedLocation != null) ...[
                                const SizedBox(height: 16),
                                _buildModernOptionCard(
                                  title: 'Yeniden Belirle',
                                  subtitle: 'Konumunuzu yeniden belirleyin',
                                  icon: Icons.refresh,
                                  iconColor: const Color(0xFF2196F3),
                                  backgroundColor:
                                      const Color(0xFF2196F3).withOpacity(0.1),
                                  onTap: _refreshLocation,
                                ),
                              ],
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Bilgi kartı
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2196F3).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: const Color(0xFF2196F3).withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color:
                                      const Color(0xFF2196F3).withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.info_outline,
                                  color: Color(0xFF2196F3),
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  'Konum bilginiz sadece size yakın ilanları göstermek için kullanılır ve gizliliğiniz korunur.',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: const Color(0xFF2196F3),
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Konum seç butonu (eğer konum varsa)
                        if (_selectedLocation != null)
                          Container(
                            width: double.infinity,
                            height: 60,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFF2E7D32),
                                  Color(0xFF4CAF50),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      const Color(0xFF2E7D32).withOpacity(0.3),
                                  blurRadius: 15,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: _saveLocation,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                foregroundColor: Colors.white,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 0,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.check_circle_outline,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Bu Konumu Seç',
                                    style: GoogleFonts.poppins(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                        const SizedBox(height: 24),
                      ],
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

  Widget _buildOptionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required Color backgroundColor,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFFE0E0E0),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // İkon
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    size: 24,
                    color: iconColor,
                  ),
                ),
                const SizedBox(width: 16),

                // Metin
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF212121),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: const Color(0xFF757575),
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),

                // Ok ikonu
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Color(0xFF757575),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModernOptionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required Color backgroundColor,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFE0E0E0),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // İkon
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    size: 24,
                    color: iconColor,
                  ),
                ),
                const SizedBox(width: 16),

                // Metin
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF212121),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: const Color(0xFF757575),
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),

                // Ok ikonu
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Color(0xFF757575),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFallbackMap() {
    return Container(
      color: Colors.grey[100],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            margin: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.3),
                  spreadRadius: 2,
                  blurRadius: 5,
                ),
              ],
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.location_on,
                  size: 64,
                  color: AnimalColors.primary,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Harita Yüklenemiyor',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Konum belirleme için GPS kullanılacak',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                if (_selectedLocation != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green[200]!),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_circle,
                                color: Colors.green[600], size: 20),
                            const SizedBox(width: 8),
                            const Text(
                              'Konum Belirlendi',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                        if (_selectedAddress.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            _selectedAddress,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.green[700],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ],
                    ),
                  ),
                ] else ...[
                  ElevatedButton.icon(
                    onPressed: _getCurrentLocation,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AnimalColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: const Icon(Icons.my_location),
                    label: const Text('Konumumu Belirle'),
                  ),
                ],
              ],
            ),
          ),
          if (_selectedAddress.isNotEmpty) ...[
            const SizedBox(height: 20),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _refreshLocation,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange[600],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: const Icon(Icons.refresh, size: 20),
                      label: const Text('Yeniden Bul'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _saveLocation,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AnimalColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Bu Konumu Seç'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _getCurrentLocation() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      // Konum izni kontrol et
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _hasLocationPermission = false;
          });
        }
        _showPermissionDialog();
        return;
      }

      if (permission == LocationPermission.denied) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _hasLocationPermission = false;
          });
        }
        _showPermissionDialog();
        return;
      }

      // Konum servisinin açık olup olmadığını kontrol et
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _isLocationServiceEnabled = false;
          });
        }
        _showLocationServiceDialog();
        return;
      }

      // Durumları güncelle
      if (mounted) {
        setState(() {
          _hasLocationPermission = true;
          _isLocationServiceEnabled = true;
        });
      }

      // Mevcut konumu al
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (mounted) {
        setState(() {
          _currentLocation =
              SimpleLocation(position.latitude, position.longitude);
          _selectedLocation = _currentLocation;
        });
      }

      // Adres bilgisini al
      await _getAddressFromSimpleLocation(_currentLocation!);

      // Başarı mesajı göster
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Konumunuz başarıyla belirlendi'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('Konum alınırken hata: $e');

      // LateInitializationError'ı özel olarak yakala
      if (e.toString().contains('LateInitializationError') ||
          e.toString().contains('_internalController')) {
        debugPrint(
            'FlutterMap initialization error caught and handled silently');
        // Bu hatayı kullanıcıya gösterme, sessizce devam et
        return;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Konum alınamadı, lütfen tekrar deneyin'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _selectLocation(SimpleLocation location) async {
    if (mounted) {
      setState(() {
        _selectedLocation = location;
        _isLoading = true;
      });
    }

    try {
      await _getAddressFromSimpleLocation(location);
    } catch (e) {
      debugPrint('Adres alınırken hata: $e');

      // LateInitializationError'ı özel olarak yakala
      if (e.toString().contains('LateInitializationError') ||
          e.toString().contains('_internalController')) {
        debugPrint(
            'FlutterMap initialization error caught and handled silently');
        // Bu hatayı kullanıcıya gösterme, sessizce devam et
        return;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Adres alınamadı, lütfen tekrar deneyin'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _getAddressFromSimpleLocation(SimpleLocation location) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        location.latitude,
        location.longitude,
        localeIdentifier: 'tr_TR',
      );

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;

        if (mounted) {
          setState(() {
            _neighborhood = place.subLocality ?? '';
            _district = place.locality ?? '';
            _city = place.administrativeArea ?? '';
            // Türkiye'de şehir ve il aynı olduğu için province'ı boş bırak
            _province = '';
            _country = place.country ?? '';

            // Daha temiz adres string'i oluştur
            List<String> addressParts = [];

            // Önce mahalle varsa ekle
            if (_neighborhood.isNotEmpty) {
              addressParts.add(_neighborhood);
            }

            // Sonra ilçe varsa ekle (mahalle ile aynı değilse)
            if (_district.isNotEmpty && _district != _neighborhood) {
              addressParts.add(_district);
            }

            // Son olarak şehir varsa ekle (ilçe ile aynı değilse)
            if (_city.isNotEmpty && _city != _district) {
              addressParts.add(_city);
            }

            _selectedAddress = addressParts.join(', ');
          });
        }
      }
    } catch (e) {
      debugPrint('Reverse geocoding hatası: $e');
      // Geocoding hatası durumunda varsayılan adres
      if (mounted) {
        setState(() {
          _selectedAddress =
              'Konum: ${location.latitude.toStringAsFixed(6)}, ${location.longitude.toStringAsFixed(6)}';
          _neighborhood = '';
          _district = '';
          _city = '';
          _province = '';
          _country = '';
        });
      }
    }
  }

  Future<void> _saveLocation() async {
    if (_selectedLocation == null) return;

    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _showErrorDialog('Kullanıcı oturumu bulunamadı');
        return;
      }

      // Firebase'e konum bilgilerini kaydet
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'neighborhood': _neighborhood,
        'district': _district,
        'city': _city,
        'state': _province,
        'country': _country,
        'latitude': _selectedLocation!.latitude,
        'longitude': _selectedLocation!.longitude,
        'address': _selectedAddress,
        'locationUpdatedAt': FieldValue.serverTimestamp(),
      });

      // Başarı mesajı göster
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Konum başarıyla kaydedildi'),
            backgroundColor: Colors.green,
          ),
        );
      }

      // Ayarlar sayfasından geldiyse geri dön, değilse anasayfaya yönlendir
      if (mounted) {
        if (widget.isFromSettings) {
          Navigator.pop(context);
        } else {
          Navigator.of(context).pushNamedAndRemoveUntil(
            '/',
            (Route<dynamic> route) => false,
          );
        }
      }

      // Callback'i çağır
      widget.onLocationSelected?.call();
    } catch (e) {
      debugPrint('Konum kaydedilirken hata: $e');
      _showErrorDialog('Konum kaydedilemedi. Lütfen tekrar deneyin.');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showLocationAndPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text(
          'Konum Erişimi Gerekli',
          style: GoogleFonts.poppins(
            color: const Color(0xFF212121),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Konumunuzu otomatik olarak belirlemek için konum servisini açın ve uygulama iznini verin.',
          style: GoogleFonts.poppins(
            color: const Color(0xFF757575),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'İptal',
              style: GoogleFonts.poppins(
                color: const Color(0xFF757575),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _handleLocationFix();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
              foregroundColor: Colors.white,
            ),
            child: Text(
              'Otomatik Düzelt',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text(
          'Konum İzni Gerekli',
          style: GoogleFonts.poppins(
            color: const Color(0xFF212121),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Konum seçmek için konum izni gereklidir.',
          style: GoogleFonts.poppins(
            color: const Color(0xFF757575),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'İptal',
              style: GoogleFonts.poppins(
                color: const Color(0xFF757575),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _requestLocationPermission();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
              foregroundColor: Colors.white,
            ),
            child: Text(
              'İzin Ver',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showPermissionDeniedForeverDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text(
          'Konum İzni Reddedildi',
          style: GoogleFonts.poppins(
            color: const Color(0xFF212121),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Konum izni kalıcı olarak reddedildi. Ayarlardan manuel olarak açmanız gerekir.',
          style: GoogleFonts.poppins(
            color: const Color(0xFF757575),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'İptal',
              style: GoogleFonts.poppins(
                color: const Color(0xFF757575),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF9800),
              foregroundColor: Colors.white,
            ),
            child: Text(
              'Ayarlar',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showLocationServiceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text(
          'Konum Servisi Kapalı',
          style: GoogleFonts.poppins(
            color: const Color(0xFF212121),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Konum seçmek için konum servisini açmanız gerekir.',
          style: GoogleFonts.poppins(
            color: const Color(0xFF757575),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'İptal',
              style: GoogleFonts.poppins(
                color: const Color(0xFF757575),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _enableLocationService();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
              foregroundColor: Colors.white,
            ),
            child: Text(
              'Konum Servisini Aç',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _enableLocationService() async {
    try {
      // Konum servisini açmaya çalış
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        // Kullanıcıya bilgi ver
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Konum servisi açılıyor...'),
              backgroundColor: Colors.blue,
              duration: Duration(seconds: 2),
            ),
          );
        }

        // Konum servisini açmaya çalış
        await Geolocator.openLocationSettings();

        // Kısa bir süre bekle ve tekrar kontrol et
        await Future.delayed(const Duration(seconds: 3));
        serviceEnabled = await Geolocator.isLocationServiceEnabled();
      }

      if (serviceEnabled) {
        // Konum servisi açıldı, state'i güncelle
        if (mounted) {
          setState(() {
            _isLocationServiceEnabled = true;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Konum servisi açıldı!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }

        // İzin zaten varsa doğrudan konumu al
        if (_hasLocationPermission) {
          await _getCurrentLocation();
        } else {
          // İzin yoksa izin iste
          await _requestLocationPermission();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content:
                  Text('Konum servisi açılamadı. Lütfen manuel olarak açın.'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Konum servisi açma hatası: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Konum servisi açılırken hata oluştu.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hata'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }
}

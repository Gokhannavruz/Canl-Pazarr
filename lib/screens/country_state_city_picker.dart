import 'package:animal_trade/responsive/mobile_screen_layout.dart';
import 'package:animal_trade/responsive/responsive_layout_screen.dart';
import 'package:animal_trade/responsive/web_screen_layout.dart';
import 'package:animal_trade/screens/login_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:permission_handler/permission_handler.dart';
import '../utils/animal_colors.dart';

class CountryStateCityForFirstSelect extends StatefulWidget {
  const CountryStateCityForFirstSelect({
    Key? key,
  }) : super(key: key);

  @override
  _CountryStateCityForFirstSelectState createState() =>
      _CountryStateCityForFirstSelectState();
}

class _CountryStateCityForFirstSelectState
    extends State<CountryStateCityForFirstSelect> {
  MapController? _mapController;
  LatLng? _selectedLocation;
  LatLng? _currentLocation;
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

  User? currentUser;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _initializeData();
  }

  Future<void> _initializeData() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser == null) {
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const LoginScreen(),
          ),
        );
        return;
      }

      // Check location status
      await _checkLocationStatus();
    } catch (e) {
      print('Error initializing data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _checkLocationStatus() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Konum servis durumunu kontrol et
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();

      // Konum izni durumunu kontrol et
      LocationPermission permission = await Geolocator.checkPermission();
      bool hasPermission = permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always;

      setState(() {
        _isLocationServiceEnabled = serviceEnabled;
        _hasLocationPermission = hasPermission;
      });

      // Eğer her şey tamam ise konumu al
      if (serviceEnabled && hasPermission) {
        await _getCurrentLocation();
      } else {
        // Konum servisi veya izin yoksa uyarı göster
        _showLocationWarning();
      }
    } catch (e) {
      print('Konum durumu kontrol hatası: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
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

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Konum izni kontrol et
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _isLoading = false;
          _hasLocationPermission = false;
        });
        _showPermissionDialog();
        return;
      }

      if (permission == LocationPermission.denied) {
        setState(() {
          _isLoading = false;
          _hasLocationPermission = false;
        });
        _showPermissionDialog();
        return;
      }

      // Konum servisinin açık olup olmadığını kontrol et
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _isLoading = false;
          _isLocationServiceEnabled = false;
        });
        _showLocationServiceDialog();
        return;
      }

      // Durumları güncelle
      setState(() {
        _hasLocationPermission = true;
        _isLocationServiceEnabled = true;
      });

      // Mevcut konumu al
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
        _selectedLocation = _currentLocation;
      });

      // Harita kamerasını mevcut konuma taşı
      if (_mapController != null && _currentLocation != null) {
        _mapController!.move(_currentLocation!, 15.0);
      }

      // Adres bilgisini al
      await _getAddressFromLatLng(_currentLocation!);

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
      print('Konum alınırken hata: $e');
      _showErrorDialog('Konum alınırken bir hata oluştu: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _selectLocation(LatLng location) async {
    setState(() {
      _selectedLocation = location;
      _isLoading = true;
    });

    try {
      await _getAddressFromLatLng(location);
    } catch (e) {
      print('Adres alınırken hata: $e');
      _showErrorDialog('Adres alınırken bir hata oluştu: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _getAddressFromLatLng(LatLng location) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        location.latitude,
        location.longitude,
        localeIdentifier: 'tr_TR',
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];

        setState(() {
          _neighborhood = place.subLocality ?? '';
          _district = place.locality ?? '';
          _city = place.administrativeArea ?? '';
          _province = place.administrativeArea ?? '';
          _country = place.country ?? '';

          // Türkiye için address formatı
          List<String> addressParts = [];
          if (_neighborhood.isNotEmpty) addressParts.add(_neighborhood);
          if (_district.isNotEmpty) addressParts.add(_district);
          if (_city.isNotEmpty) addressParts.add(_city);
          if (_country.isNotEmpty) addressParts.add(_country);

          _selectedAddress = addressParts.join(', ');
        });
      }
    } catch (e) {
      print('Reverse geocoding hatası: $e');
      setState(() {
        _selectedAddress = 'Adres bulunamadı';
      });
    }
  }

  Future<void> _saveLocation() async {
    if (_selectedLocation == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Firebase'e konum bilgilerini kaydet
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
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

      // firstLaunch değerini güncelle
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('firstLaunch', false);
      await prefs.setBool('locationSelected', true);

      if (!mounted) return;

      // Başarı mesajı göster
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Konum başarıyla kaydedildi',
            style: GoogleFonts.poppins(fontSize: 14),
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );

      // Ana sayfaya yönlendir
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const ResponsiveLayout(
            mobileScreenLayout: MobileScreenLayout(),
            webScreenLayout: WebScreenLayout(),
          ),
        ),
      );
    } catch (e) {
      print('Konum kaydedilirken hata: $e');
      _showErrorDialog('Konum kaydedilirken bir hata oluştu: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
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
    if (!_isLocationServiceEnabled) {
      _showLocationServiceDialog();
    } else if (!_hasLocationPermission) {
      _showPermissionDialog();
    } else {
      // Her şey tamam ise konumu al
      await _getCurrentLocation();
    }
  }

  Future<void> _refreshLocation() async {
    // Mevcut konumu yeniden al
    setState(() {
      _isLoading = true;
    });

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

      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
        _selectedLocation = _currentLocation;
      });

      // Harita kamerasını yeni konuma taşı
      if (_mapController != null && _currentLocation != null) {
        _mapController!.move(_currentLocation!, 15.0);
      }

      // Yeni adres bilgisini al
      await _getAddressFromLatLng(_currentLocation!);

      // Başarı mesajı göster
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Konumunuz yeniden belirlendi',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('Konum yenileme hatası: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Konum yenilenemedi: ${e.toString()}',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showLocationAndPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text(
          'Konum Erişimi Gerekli',
          style: GoogleFonts.poppins(color: Colors.white),
        ),
        content: Text(
          'Konumunuzu otomatik olarak belirlemek için konum servisini açın ve uygulama iznini verin.',
          style: GoogleFonts.poppins(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'İptal',
              style: GoogleFonts.poppins(color: Colors.white70),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Geolocator.openLocationSettings();
              openAppSettings();
            },
            child: Text(
              'Ayarlar',
              style: GoogleFonts.poppins(color: AnimalColors.primary),
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
        backgroundColor: Colors.grey[900],
        title: Text(
          'Konum İzni Gerekli',
          style: GoogleFonts.poppins(color: Colors.white),
        ),
        content: Text(
          'Konum seçmek için konum izni gereklidir. Lütfen ayarlardan konum iznini açın.',
          style: GoogleFonts.poppins(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'İptal',
              style: GoogleFonts.poppins(color: Colors.white70),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: Text(
              'Ayarlar',
              style: GoogleFonts.poppins(color: AnimalColors.primary),
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
        backgroundColor: Colors.grey[900],
        title: Text(
          'Konum Servisi Kapalı',
          style: GoogleFonts.poppins(color: Colors.white),
        ),
        content: Text(
          'Konum seçmek için konum servisini açmanız gerekir.',
          style: GoogleFonts.poppins(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'İptal',
              style: GoogleFonts.poppins(color: Colors.white70),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Geolocator.openLocationSettings();
            },
            child: Text(
              'Ayarlar',
              style: GoogleFonts.poppins(color: AnimalColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text(
          'Hata',
          style: GoogleFonts.poppins(color: Colors.white),
        ),
        content: Text(
          message,
          style: GoogleFonts.poppins(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Tamam',
              style: GoogleFonts.poppins(color: AnimalColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.height < 700;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_rounded,
            color: Colors.white,
            size: 20,
          ),
          onPressed: () {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => const ResponsiveLayout(
                  mobileScreenLayout: MobileScreenLayout(),
                  webScreenLayout: WebScreenLayout(),
                ),
              ),
            );
          },
        ),
        title: Text(
          "Konum Seç",
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AnimalColors.primary),
              ),
            )
          : Stack(
              children: [
                // Flutter Map (OpenStreetMap)
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    center: _selectedLocation ??
                        _currentLocation ??
                        LatLng(39.9334, 32.8597), // Ankara varsayılan
                    zoom: 15.0,
                    onTap: (tapPosition, point) {
                      _selectLocation(point);
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.freecycle.animal_trade',
                    ),
                    if (_selectedLocation != null)
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: _selectedLocation!,
                            width: 40,
                            height: 40,
                            child: Container(
                              decoration: BoxDecoration(
                                color: AnimalColors.primary,
                                shape: BoxShape.circle,
                                border:
                                    Border.all(color: Colors.white, width: 2),
                              ),
                              child: Icon(
                                Icons.location_on,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),

                // Konum uyarı kartı (konum kapalıysa)
                if (!_isLocationServiceEnabled || !_hasLocationPermission)
                  Positioned(
                    top: 20,
                    left: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.orange[900]?.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(16),
                        border:
                            Border.all(color: Colors.orange.withOpacity(0.5)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.warning,
                                color: Colors.orange[300],
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Konum Erişimi Gerekli',
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _getLocationWarningMessage(),
                            style: GoogleFonts.poppins(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _handleLocationFix,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange[600],
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8),
                              ),
                              icon: const Icon(Icons.settings, size: 16),
                              label: Text(
                                'Ayarları Düzelt',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Adres bilgisi kartı
                if (_selectedAddress.isNotEmpty)
                  Positioned(
                    top: 20,
                    left: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(16),
                        border:
                            Border.all(color: Colors.white.withOpacity(0.2)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Seçilen Konum',
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              // Konumumu Yeniden Bul butonu
                              TextButton.icon(
                                onPressed: _refreshLocation,
                                style: TextButton.styleFrom(
                                  foregroundColor: AnimalColors.primary,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                ),
                                icon: const Icon(
                                  Icons.refresh,
                                  size: 14,
                                ),
                                label: Text(
                                  'Yeniden Bul',
                                  style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Text(
                            _selectedAddress,
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Yanlış konum uyarısı
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.blue[900]?.withOpacity(0.8),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color: Colors.blue[300]!.withOpacity(0.5)),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  size: 14,
                                  color: Colors.blue[300],
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'Konum yanlışsa "Yeniden Bul" butonuna basın',
                                    style: GoogleFonts.poppins(
                                      fontSize: 10,
                                      color: Colors.blue[200],
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

                // Konumumu Bul butonu
                Positioned(
                  bottom: 140,
                  right: 16,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Konumumu Bul butonu
                      FloatingActionButton.extended(
                        onPressed:
                            _isLocationServiceEnabled && _hasLocationPermission
                                ? _getCurrentLocation
                                : _handleLocationFix,
                        backgroundColor:
                            _isLocationServiceEnabled && _hasLocationPermission
                                ? AnimalColors.primary
                                : Colors.orange[600],
                        foregroundColor: Colors.white,
                        label: Text(
                          'Konumumu Bul',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                        icon: Icon(
                          _isLocationServiceEnabled && _hasLocationPermission
                              ? Icons.my_location
                              : Icons.location_disabled,
                          size: 20,
                        ),
                      ),

                      // Mevcut konuma git butonu (sadece konum varsa)
                      if (_currentLocation != null) ...[
                        const SizedBox(height: 8),
                        FloatingActionButton(
                          onPressed: () {
                            setState(() {
                              _selectedLocation = _currentLocation;
                            });
                            if (_currentLocation != null &&
                                _mapController != null) {
                              _mapController!.move(_currentLocation!, 15.0);
                              _getAddressFromLatLng(_currentLocation!);
                            }
                          },
                          backgroundColor: AnimalColors.secondary,
                          foregroundColor: Colors.white,
                          mini: true,
                          child: const Icon(
                            Icons.center_focus_strong,
                            size: 20,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Konum seç butonu
                Positioned(
                  bottom: 32,
                  left: 16,
                  right: 16,
                  child: Column(
                    children: [
                      // Daha sonra butonu
                      Container(
                        width: double.infinity,
                        height: 48,
                        margin: const EdgeInsets.only(bottom: 12),
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(
                                builder: (context) => const ResponsiveLayout(
                                  mobileScreenLayout: MobileScreenLayout(),
                                  webScreenLayout: WebScreenLayout(),
                                ),
                              ),
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: BorderSide(
                                color: Colors.white.withOpacity(0.5)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Daha Sonra',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                      // Ana buton
                      Container(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed:
                              _selectedLocation != null ? _saveLocation : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AnimalColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 4,
                          ),
                          child: Text(
                            'Bu Konumu Seç',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
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
}

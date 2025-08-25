import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
// import 'package:google_mobile_ads/google_mobile_ads.dart'; // Temporarily disabled
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/animal_colors.dart';

class CountryStateCity extends StatefulWidget {
  const CountryStateCity({
    Key? key,
  }) : super(key: key);

  @override
  _CountryStateCityState createState() => _CountryStateCityState();
}

class _CountryStateCityState extends State<CountryStateCity> {
  MapController? _mapController;
  LatLng? _selectedLocation;
  LatLng? _currentLocation;
  bool _isLoading = false;
  String _selectedAddress = '';

  // Konum bilgileri
  String _neighborhood = '';
  String _district = '';
  String _city = '';
  String _province = '';
  String _country = '';

  bool isAdLoaded = false;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _loadUserData();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (doc.exists) {
          final data = doc.data()!;
          setState(() {
            _neighborhood = data['neighborhood'] ?? '';
            _district = data['district'] ?? '';
            _city = data['city'] ?? '';
            _province = data['state'] ?? '';
            _country = data['country'] ?? '';

            // Eğer önceki konum varsa haritayı oraya konumlandır
            if (data['latitude'] != null && data['longitude'] != null) {
              _selectedLocation = LatLng(data['latitude'], data['longitude']);
              _currentLocation = _selectedLocation;

              // Adres bilgisini oluştur
              List<String> addressParts = [];
              if (_neighborhood.isNotEmpty) addressParts.add(_neighborhood);
              if (_district.isNotEmpty) addressParts.add(_district);
              if (_city.isNotEmpty) addressParts.add(_city);
              if (_country.isNotEmpty) addressParts.add(_country);
              _selectedAddress = addressParts.join(', ');
            }
          });
        }
      }
    } catch (e) {
      print('Error loading user data: $e');
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
        _showPermissionDialog();
        return;
      }

      if (permission == LocationPermission.denied) {
        _showPermissionDialog();
        return;
      }

      // Konum servisinin açık olup olmadığını kontrol et
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showLocationServiceDialog();
        return;
      }

      // Mevcut konumu al (sadece önceki konum yoksa)
      if (_selectedLocation == null) {
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );

        setState(() {
          _currentLocation = LatLng(position.latitude, position.longitude);
          _selectedLocation = _currentLocation;
        });

        // Adres bilgisini al
        await _getAddressFromLatLng(_currentLocation!);
      }

      // Harita varsa ve konum seçilmişse kamerayı o konuma götür
      if (_mapController != null && _selectedLocation != null) {
        _mapController!.move(_selectedLocation!, 15.0);
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
          // Türkiye'de şehir ve il aynı olduğu için province'ı boş bırak
          _province = '';
          _country = place.country ?? '';

          // Türkiye için address formatı - tekrarlanan değerleri önle
          List<String> addressParts = [];
          if (_neighborhood.isNotEmpty) addressParts.add(_neighborhood);
          if (_district.isNotEmpty && _district != _neighborhood)
            addressParts.add(_district);
          if (_city.isNotEmpty && _city != _district) addressParts.add(_city);
          if (_country.isNotEmpty && _country != _city)
            addressParts.add(_country);

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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Konum başarıyla güncellendi',
            style: GoogleFonts.poppins(fontSize: 14),
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );

      // Geri dön
      Navigator.pop(context);
    } catch (e) {
      print('Konum kaydedilirken hata: $e');
      _showErrorDialog('Konum kaydedilirken bir hata oluştu: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
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
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Konum Değiştir",
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
                          Text(
                            'Seçilen Konum',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _selectedAddress,
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Konum kaydet butonu
                Positioned(
                  bottom: 32,
                  left: 16,
                  right: 16,
                  child: Container(
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
                        'Konumu Kaydet',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

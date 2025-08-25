import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:permission_handler/permission_handler.dart';
import '../utils/animal_colors.dart';

class LocationPickerWebView extends StatefulWidget {
  const LocationPickerWebView({super.key});

  @override
  State<LocationPickerWebView> createState() => _LocationPickerWebViewState();
}

class SimpleLocation {
  final double latitude;
  final double longitude;

  const SimpleLocation(this.latitude, this.longitude);

  @override
  String toString() => 'SimpleLocation($latitude, $longitude)';
}

class _LocationPickerWebViewState extends State<LocationPickerWebView> {
  late WebViewController _webViewController;
  SimpleLocation? _selectedLocation;
  SimpleLocation? _currentLocation;
  bool _isLoading = false;
  bool _isLocationServiceEnabled = false;
  bool _hasLocationPermission = false;
  String _selectedAddress = '';
  String _neighborhood = '';
  String _district = '';
  String _city = '';
  String _province = '';
  String _country = '';

  final User? currentUser = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
    _checkLocationStatus();
  }

  void _initializeWebView() {
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            // Yükleme ilerlemesi
          },
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
            });
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
          },
        ),
      )
      ..loadHtmlString(_getLeafletHtml());
  }

  String _getLeafletHtml() {
    return '''
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Konum Seçici</title>
    <link rel="stylesheet" href="https://unpkg.com/leaflet@1.9.4/dist/leaflet.css" />
    <script src="https://unpkg.com/leaflet@1.9.4/dist/leaflet.js"></script>
    <style>
        body { 
            padding: 0; 
            margin: 0; 
            font-family: Arial, sans-serif;
        }
        html, body, #map {
            height: 100%;
            width: 100%;
        }
        .info-panel {
            position: absolute;
            top: 10px;
            left: 10px;
            right: 10px;
            background: white;
            padding: 10px;
            border-radius: 8px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
            z-index: 1000;
            font-size: 14px;
        }
        .location-info {
            margin-top: 10px;
            padding: 8px;
            background: #f0f8ff;
            border-radius: 4px;
            border-left: 4px solid #2E7D32;
        }
        .button {
            background: #2E7D32;
            color: white;
            border: none;
            padding: 8px 16px;
            border-radius: 4px;
            cursor: pointer;
            margin: 5px 5px 5px 0;
            font-size: 12px;
        }
        .button:hover {
            background: #1B5E20;
        }
        .button:disabled {
            background: #ccc;
            cursor: not-allowed;
        }
    </style>
</head>
<body>
    <div id="map"></div>
    <div class="info-panel">
        <div><strong>🗺️ Konum Seçici</strong></div>
        <div>Haritaya tıklayarak konum seçin veya GPS ile mevcut konumunuzu alın</div>
        <div class="location-info" id="locationInfo" style="display: none;">
            <div><strong>Seçilen Konum:</strong></div>
            <div id="coordinates"></div>
            <div id="address"></div>
        </div>
        <div style="margin-top: 10px;">
            <button class="button" onclick="getCurrentLocation()">📍 Mevcut Konum</button>
            <button class="button" onclick="clearLocation()">🗑️ Temizle</button>
            <button class="button" onclick="selectLocation()" id="selectBtn" disabled>✅ Bu Konumu Seç</button>
        </div>
    </div>

    <script>
        var map = L.map('map').setView([39.9334, 32.8597], 10); // Ankara
        var marker = null;
        var selectedLat = null;
        var selectedLng = null;

        L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
            attribution: '© OpenStreetMap contributors'
        }).addTo(map);

        map.on('click', function(e) {
            var lat = e.latlng.lat;
            var lng = e.latlng.lng;
            
            if (marker) {
                map.removeLayer(marker);
            }
            
            marker = L.marker([lat, lng]).addTo(map);
            selectedLat = lat;
            selectedLng = lng;
            
            updateLocationInfo(lat, lng);
            document.getElementById('selectBtn').disabled = false;
        });

        function getCurrentLocation() {
            if (navigator.geolocation) {
                navigator.geolocation.getCurrentPosition(
                    function(position) {
                        var lat = position.coords.latitude;
                        var lng = position.coords.longitude;
                        
                        if (marker) {
                            map.removeLayer(marker);
                        }
                        
                        marker = L.marker([lat, lng]).addTo(map);
                        map.setView([lat, lng], 15);
                        selectedLat = lat;
                        selectedLng = lng;
                        
                        updateLocationInfo(lat, lng);
                        document.getElementById('selectBtn').disabled = false;
                    },
                    function(error) {
                        alert('Konum alınamadı: ' + error.message);
                    }
                );
            } else {
                alert('Tarayıcınız konum servisini desteklemiyor');
            }
        }

        function updateLocationInfo(lat, lng) {
            document.getElementById('coordinates').innerHTML = 
                'Enlem: ' + lat.toFixed(6) + ', Boylam: ' + lng.toFixed(6);
            document.getElementById('locationInfo').style.display = 'block';
            
            // Reverse geocoding
            fetch('https://nominatim.openstreetmap.org/reverse?format=json&lat=' + lat + '&lon=' + lng + '&zoom=18&addressdetails=1')
                .then(response => response.json())
                .then(data => {
                    var address = data.display_name || 'Adres bulunamadı';
                    document.getElementById('address').innerHTML = '<strong>Adres:</strong> ' + address;
                })
                .catch(error => {
                    document.getElementById('address').innerHTML = '<strong>Adres:</strong> Adres alınamadı';
                });
        }

        function clearLocation() {
            if (marker) {
                map.removeLayer(marker);
                marker = null;
            }
            selectedLat = null;
            selectedLng = null;
            document.getElementById('locationInfo').style.display = 'none';
            document.getElementById('selectBtn').disabled = true;
        }

        function selectLocation() {
            if (selectedLat && selectedLng) {
                // Flutter'a veri gönder
                window.flutter_inappwebview.callHandler('locationSelected', selectedLat, selectedLng);
            }
        }

        // Flutter'dan gelen mesajları dinle
        window.addEventListener('flutterInAppWebViewPlatformReady', function(event) {
            console.log('Flutter WebView hazır');
        });
    </script>
</body>
</html>
    ''';
  }

  Future<void> _checkLocationStatus() async {
    try {
      bool isLocationServiceEnabled =
          await Geolocator.isLocationServiceEnabled();
      LocationPermission permission = await Geolocator.checkPermission();

      if (mounted) {
        setState(() {
          _isLocationServiceEnabled = isLocationServiceEnabled;
          _hasLocationPermission =
              permission == LocationPermission.whileInUse ||
                  permission == LocationPermission.always;
        });
      }

      if (isLocationServiceEnabled &&
          (permission == LocationPermission.whileInUse ||
              permission == LocationPermission.always)) {
        await _getCurrentLocation();
      } else {
        _showLocationWarning();
      }
    } catch (e) {
      debugPrint('Konum durumu kontrol hatası: $e');
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
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (mounted) {
        setState(() {
          _currentLocation =
              SimpleLocation(position.latitude, position.longitude);
          _selectedLocation = _currentLocation;
          _isLocationServiceEnabled = true;
          _hasLocationPermission = true;
        });
      }

      await _getAddressFromSimpleLocation(_currentLocation!);

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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Konum alınamadı: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
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
            _province = place.administrativeArea ?? '';
            _country = place.country ?? '';

            List<String> addressParts = [];
            if (_neighborhood.isNotEmpty) addressParts.add(_neighborhood);
            if (_district.isNotEmpty) addressParts.add(_district);
            if (_city.isNotEmpty) addressParts.add(_city);
            if (_country.isNotEmpty) addressParts.add(_country);

            _selectedAddress = addressParts.join(', ');
          });
        }
      }
    } catch (e) {
      debugPrint('Adres alınırken hata: $e');
    }
  }

  Future<void> _saveLocation() async {
    if (_selectedLocation == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
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

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Konum başarıyla kaydedildi'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('Konum kaydedilirken hata: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Konum kaydedilemedi: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
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

  void _showLocationAndPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konum Erişimi Gerekli'),
        content: const Text(
          'Konumunuzu otomatik olarak belirlemek için konum servisini açın ve uygulama iznini verin.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Geolocator.openLocationSettings();
              openAppSettings();
            },
            child: const Text('Ayarlar'),
          ),
        ],
      ),
    );
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konum İzni Gerekli'),
        content: const Text(
          'Konum seçmek için konum izni gereklidir.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _requestLocationPermission();
            },
            child: const Text('İzin Ver'),
          ),
        ],
      ),
    );
  }

  void _showLocationServiceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konum Servisi Kapalı'),
        content: const Text(
          'Konumunuzu belirlemek için konum servisini açmanız gereklidir.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Geolocator.openLocationSettings();
            },
            child: const Text('Ayarlar'),
          ),
        ],
      ),
    );
  }

  Future<void> _requestLocationPermission() async {
    try {
      LocationPermission permission = await Geolocator.requestPermission();

      if (permission == LocationPermission.denied) {
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
        await _getCurrentLocation();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Konum izni verildi'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
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
            content: Text('İzin istenemedi'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Konum Seçici'),
        backgroundColor: AnimalColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          // WebView Harita
          WebViewWidget(controller: _webViewController),

          // Yükleme göstergesi
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: CircularProgressIndicator(
                  color: AnimalColors.primary,
                ),
              ),
            ),

          // Konum bilgisi kartı
          if (_selectedLocation != null && _selectedAddress.isNotEmpty)
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.3),
                      spreadRadius: 2,
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.location_on, color: AnimalColors.primary),
                        const SizedBox(width: 8),
                        const Text(
                          'Seçilen Konum',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _selectedAddress,
                      style: const TextStyle(fontSize: 14),
                    ),
                    if (_neighborhood.isNotEmpty ||
                        _district.isNotEmpty ||
                        _city.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      if (_neighborhood.isNotEmpty)
                        Text('Mahalle: $_neighborhood',
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey[600])),
                      if (_district.isNotEmpty)
                        Text('İlçe: $_district',
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey[600])),
                      if (_city.isNotEmpty)
                        Text('İl: $_city',
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey[600])),
                    ],
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
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
            ),
        ],
      ),
    );
  }
}

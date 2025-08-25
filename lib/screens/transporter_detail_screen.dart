import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class TransporterDetailScreen extends StatelessWidget {
  final Map<String, dynamic> transporterData;
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

  const TransporterDetailScreen({Key? key, required this.transporterData})
      : super(key: key);

  String _formatPrice(num? price) {
    if (price == null) return '';
    final formatter = NumberFormat('#,##0', 'tr_TR');
    return '${formatter.format(price)} ₺';
  }

  String _formatKm(num? km) {
    if (km == null) return '';
    final formatter = NumberFormat('#,##0', 'tr_TR');
    return '${formatter.format(km)} km';
  }

  Widget _sectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: primaryColor, size: 20),
        const SizedBox(width: 8),
        Text(title,
            style: GoogleFonts.poppins(
              color: textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            )),
      ],
    );
  }

  Widget _infoRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: infoColor, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: GoogleFonts.poppins(
                      color: textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    )),
                Text(value,
                    style: GoogleFonts.poppins(
                      color: textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionCard(
      {required String title,
      required IconData icon,
      required List<Widget> children}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: dividerColor, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: primaryColor, size: 22),
              const SizedBox(width: 10),
              Text(title,
                  style: GoogleFonts.poppins(
                    color: textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  )),
            ],
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }

  Widget _infoRow2(String label, String value, {bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label,
                style: GoogleFonts.poppins(
                  color: textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                )),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(value,
                style: GoogleFonts.poppins(
                  color: highlight ? primaryColor : textPrimary,
                  fontSize: highlight ? 15 : 14,
                  fontWeight: highlight ? FontWeight.bold : FontWeight.w600,
                )),
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
        title: Text('Nakliyeci Detayları',
            style: GoogleFonts.poppins(
              color: textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 18,
            )),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionCard(
              title: 'Genel Bilgiler',
              icon: Icons.info_outline,
              children: [
                if (transporterData['transporterCompanyName'] != null &&
                    transporterData['transporterCompanyName']
                        .toString()
                        .isNotEmpty)
                  _infoRow2('Firma', transporterData['transporterCompanyName']),
                if (transporterData['transporterPhone'] != null &&
                    transporterData['transporterPhone'].toString().isNotEmpty)
                  _infoRow2('Telefon', transporterData['transporterPhone'],
                      highlight: true),
                if (transporterData['transporterCities'] != null &&
                    (transporterData['transporterCities'] as List).isNotEmpty)
                  _infoRow2('Şehirler',
                      (transporterData['transporterCities'] as List).join(', '),
                      highlight: true),
                if (transporterData['transporterRegions'] != null &&
                    (transporterData['transporterRegions'] as List).isNotEmpty)
                  _infoRow2(
                      'Bölgeler',
                      (transporterData['transporterRegions'] as List)
                          .join(', ')),
                if (transporterData['transporterWorkingHours'] != null &&
                    transporterData['transporterWorkingHours']
                        .toString()
                        .isNotEmpty)
                  _infoRow2('Çalışma Saatleri',
                      transporterData['transporterWorkingHours']),
                if (transporterData['transporterYearsExperience'] != null)
                  _infoRow2('Deneyim',
                      '${transporterData['transporterYearsExperience']} yıl'),
              ],
            ),
            _sectionCard(
              title: 'Araç & Kapasite',
              icon: Icons.local_shipping,
              children: [
                if (transporterData['transporterVehicleType'] != null &&
                    transporterData['transporterVehicleType']
                        .toString()
                        .isNotEmpty)
                  _infoRow2(
                      'Araç Tipi', transporterData['transporterVehicleType']),
                if (transporterData['transporterVehiclePlate'] != null &&
                    transporterData['transporterVehiclePlate']
                        .toString()
                        .isNotEmpty)
                  _infoRow2(
                      'Plaka', transporterData['transporterVehiclePlate']),
                if (transporterData['transporterMaxAnimals'] != null)
                  _infoRow2('Kapasite',
                      transporterData['transporterMaxAnimals'].toString()),
                if (transporterData['transporterAnimalTypes'] != null &&
                    (transporterData['transporterAnimalTypes'] as List)
                        .isNotEmpty)
                  _infoRow2(
                      'Hayvan Türleri',
                      (transporterData['transporterAnimalTypes'] as List)
                          .join(', ')),
                if (transporterData['transporterInsurance'] == true)
                  _infoRow2('Sigorta', 'Var'),
              ],
            ),
            _sectionCard(
              title: 'Fiyatlandırma',
              icon: Icons.attach_money,
              children: [
                if (transporterData['transporterMinPrice'] != null &&
                    transporterData['transporterMaxPrice'] != null)
                  _infoRow2('Fiyat Aralığı',
                      '${_formatPrice(transporterData['transporterMinPrice'])} - ${_formatPrice(transporterData['transporterMaxPrice'])}',
                      highlight: true),
                if (transporterData['transporterPricePerKm'] != null)
                  _infoRow2('Km Başı Ücret',
                      _formatPrice(transporterData['transporterPricePerKm'])),
                if (transporterData['transporterMaxDistanceKm'] != null)
                  _infoRow2('Maks. Mesafe',
                      _formatKm(transporterData['transporterMaxDistanceKm'])),
              ],
            ),
            _sectionCard(
              title: 'Ek Bilgiler',
              icon: Icons.notes,
              children: [
                if (transporterData['transporterDescription'] != null &&
                    transporterData['transporterDescription']
                        .toString()
                        .isNotEmpty)
                  _infoRow2(
                      'Açıklama', transporterData['transporterDescription']),
                if (transporterData['transporterLanguages'] != null &&
                    (transporterData['transporterLanguages'] as List)
                        .isNotEmpty)
                  _infoRow2(
                      'Diller',
                      (transporterData['transporterLanguages'] as List)
                          .join(', ')),
                if (transporterData['transporterNotes'] != null &&
                    transporterData['transporterNotes'].toString().isNotEmpty)
                  _infoRow2('Ek Notlar', transporterData['transporterNotes']),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

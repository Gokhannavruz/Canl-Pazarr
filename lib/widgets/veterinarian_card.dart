import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/veterinarian.dart';
import '../services/pricing_service.dart';

class VeterinarianCard extends StatelessWidget {
  final Veterinarian veterinarian;
  final bool isGridView;
  final VoidCallback? onTap;
  final VoidCallback? onShare;
  final VoidCallback? onCall;

  // Color palette - Animal card ile aynı
  static const Color primaryColor = Color(0xFF2E7D32);
  static const Color warningColor = Color(0xFFFF9800);
  static const Color errorColor = Color(0xFFE53935);
  static const Color backgroundColor = Colors.white;
  static const Color surfaceColor = Color(0xFFFAFAFA);
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color dividerColor = Color(0xFFE0E0E0);

  const VeterinarianCard({
    Key? key,
    required this.veterinarian,
    required this.isGridView,
    this.onTap,
    this.onShare,
    this.onCall,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: VeterinarianCard.backgroundColor,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: VeterinarianCard.backgroundColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: VeterinarianCard.dividerColor, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Fotoğraf bölümü
              Stack(
                children: [
                  ClipRRect(
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(16)),
                    child: veterinarian.photoUrls.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: veterinarian.photoUrls[0],
                            height: isGridView ? 140 : 180,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              height: isGridView ? 140 : 180,
                              color: VeterinarianCard.surfaceColor,
                              child: const Center(
                                child: CircularProgressIndicator(),
                              ),
                            ),
                            errorWidget: (context, url, error) => Container(
                              height: isGridView ? 140 : 180,
                              color: VeterinarianCard.surfaceColor,
                              child: const Center(
                                child: Icon(Icons.local_hospital, size: 40),
                              ),
                            ),
                          )
                        : Container(
                            height: isGridView ? 140 : 180,
                            color: VeterinarianCard.surfaceColor,
                            child: const Center(
                              child: Icon(Icons.local_hospital, size: 40),
                            ),
                          ),
                  ),
                  // Müsaitlik durumu
                  if (veterinarian.available)
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Müsait',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  // Acil hizmet rozeti
                  if (veterinarian.emergencyService)
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: VeterinarianCard.warningColor.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Acil',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              // Bilgi alanı
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Başlık ve fiyat satırı
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            veterinarian.clinicName ?? veterinarian.username,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: VeterinarianCard.textPrimary,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (veterinarian.consultationFee != null)
                          Container(
                            margin: EdgeInsets.only(left: 8),
                            padding: EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: VeterinarianCard.primaryColor,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              PricingService.formatPrice(
                                  veterinarian.consultationFee!),
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),

                    SizedBox(height: 8),
                    // Uzmanlık alanları
                    if (veterinarian.specializations.isNotEmpty)
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children:
                            veterinarian.specializations.take(2).map((spec) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.green[50],
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Colors.green[200]!),
                            ),
                            child: Text(
                              spec,
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                color: Colors.green[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    SizedBox(height: 8),
                    // Özellik rozetleri
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        if (veterinarian.homeVisit)
                          _buildInfoChip('Ev Ziyareti', '', Icons.home),
                        if (veterinarian.hasLaboratory)
                          _buildInfoChip('Laboratuvar', '', Icons.science),
                        if (veterinarian.hasSurgery)
                          _buildInfoChip('Cerrahi', '', Icons.medical_services),
                        if (veterinarian.hasXRay)
                          _buildInfoChip('X-Ray', '', Icons.medical_services),
                        if (veterinarian.hasUltrasound)
                          _buildInfoChip(
                              'Ultrason', '', Icons.medical_services),
                      ],
                    ),
                    SizedBox(height: 8),
                    // Deneyim ve konum
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (veterinarian.yearsExperience != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Row(
                              children: [
                                Icon(Icons.work,
                                    size: 14,
                                    color: VeterinarianCard.textSecondary),
                                SizedBox(width: 4),
                                Text(
                                  '${veterinarian.yearsExperience} yıl deneyim',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: VeterinarianCard.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (veterinarian.cities.isNotEmpty)
                          Row(
                            children: [
                              Icon(Icons.location_on,
                                  size: 14,
                                  color: VeterinarianCard.textSecondary),
                              SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  veterinarian.cities.first,
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: VeterinarianCard.textSecondary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                    SizedBox(height: 8),
                    // Veteriner profili
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 12,
                          backgroundColor: Colors.grey[200],
                          backgroundImage: veterinarian.photoUrl != null
                              ? CachedNetworkImageProvider(
                                  veterinarian.photoUrl!)
                              : null,
                          child: veterinarian.photoUrl == null
                              ? Icon(Icons.person, size: 16)
                              : null,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            veterinarian.username,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: VeterinarianCard.textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
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
      ),
    );
  }

  Widget _buildInfoChip(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: VeterinarianCard.surfaceColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: VeterinarianCard.dividerColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: VeterinarianCard.textSecondary),
          SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 10,
              color: VeterinarianCard.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

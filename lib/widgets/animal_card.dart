import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/animal_post.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

class AnimalCard extends StatelessWidget {
  final AnimalPost animal;
  final bool isGridView;
  final VoidCallback? onTap;
  final VoidCallback? onFavorite;
  final VoidCallback? onShare;

  static const Color primaryColor = Color(0xFF2E7D32);
  static const Color warningColor = Color(0xFFFF9800);
  static const Color errorColor = Color(0xFFE53935);
  static const Color backgroundColor = Colors.white;
  static const Color surfaceColor = Color(0xFFFAFAFA);
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color dividerColor = Color(0xFFE0E0E0);

  const AnimalCard({
    Key? key,
    required this.animal,
    this.isGridView = false,
    this.onTap,
    this.onFavorite,
    this.onShare,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
    final isLiked = animal.likes.contains(currentUserId);
    return Material(
      color: AnimalCard.backgroundColor,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: AnimalCard.backgroundColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AnimalCard.dividerColor, width: 1),
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
              Stack(
                children: [
                  ClipRRect(
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(16)),
                    child: animal.photoUrls.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: animal.photoUrls[0],
                            height: isGridView ? 140 : 180,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Shimmer.fromColors(
                              baseColor: Colors.grey[300]!,
                              highlightColor: Colors.grey[100]!,
                              child: Container(
                                height: isGridView ? 140 : 180,
                                color: Colors.grey[300],
                                child: Center(
                                  child: Icon(
                                    Icons.pets,
                                    size: 40,
                                    color: Colors.grey[400],
                                  ),
                                ),
                              ),
                            ),
                            errorWidget: (context, url, error) => Container(
                              height: isGridView ? 140 : 180,
                              color: AnimalCard.surfaceColor,
                              child: const Center(
                                  child: Icon(Icons.pets, size: 40)),
                            ),
                          )
                        : Container(
                            height: isGridView ? 140 : 180,
                            color: AnimalCard.surfaceColor,
                            child:
                                const Center(child: Icon(Icons.pets, size: 40)),
                          ),
                  ),
                  // Fiyat etiketi - sağ üst köşe
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AnimalCard.primaryColor,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        '${NumberFormat('#,###', 'tr_TR').format(animal.priceInTL)} ₺',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  // Favori butonu - sağ alt köşe
                  Positioned(
                    bottom: 12,
                    right: 12,
                    child: _buildIconButton(
                      icon: isLiked ? Icons.favorite : Icons.favorite_border,
                      iconColor: isLiked ? Colors.red : AnimalCard.primaryColor,
                      onTap: () async {
                        final docRef = FirebaseFirestore.instance
                            .collection('animals')
                            .doc(animal.postId);
                        try {
                          if (isLiked) {
                            await docRef.update({
                              'likes': FieldValue.arrayRemove([currentUserId])
                            });
                          } else {
                            await docRef.update({
                              'likes': FieldValue.arrayUnion([currentUserId])
                            });
                          }
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text('Favori işlemi başarısız: $e')),
                          );
                        }
                        if (onFavorite != null) onFavorite!();
                      },
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
                    // Hayvan cinsi - tam genişlik
                    Text(
                      (animal.animalBreed.isNotEmpty
                          ? animal.animalBreed
                          : animal.animalSpecies),
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AnimalCard.textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 8),
                    // İlan tarihi
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0, bottom: 2.0),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today,
                              size: 14, color: AnimalCard.textSecondary),
                          SizedBox(width: 4),
                          Text(
                            _getFormattedDate(animal.datePublished),
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: AnimalCard.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (animal.isUrgentSale || animal.isNegotiable)
                      Padding(
                        padding: const EdgeInsets.only(top: 8, bottom: 4),
                        child: Wrap(
                          spacing: 8,
                          children: [
                            if (animal.isUrgentSale)
                              _buildBadge('Acil', AnimalCard.errorColor),
                            if (animal.isNegotiable)
                              _buildBadge('Pazarlık', AnimalCard.warningColor),
                          ],
                        ),
                      ),
                    SizedBox(height: 8),
                    // Chipler: yaş, ağırlık, cinsiyet, gebe
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        _buildInfoChip(
                            'Yaş', '${animal.ageInMonths} ay', Icons.cake),
                        _buildInfoChip(
                            'Ağırlık',
                            '${animal.weightInKg.toStringAsFixed(0)} kg',
                            Icons.monitor_weight),
                        if (animal.isPregnant)
                          _buildInfoChip('Gebe', '', Icons.pregnant_woman),
                      ],
                    ),
                    SizedBox(height: 8),
                    // Konum
                    Row(
                      children: [
                        Icon(Icons.location_on,
                            size: 16, color: AnimalCard.textSecondary),
                        SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            animal.city,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: AnimalCard.textSecondary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    // Satıcı
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 12,
                          backgroundImage: animal.profImage.isNotEmpty
                              ? CachedNetworkImageProvider(animal.profImage)
                              : null,
                          child: animal.profImage.isEmpty
                              ? Icon(Icons.person, size: 16)
                              : null,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            animal.username,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: AnimalCard.textPrimary,
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

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildInfoChip(String label, String value, IconData icon) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AnimalCard.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AnimalCard.primaryColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: AnimalCard.primaryColor,
          ),
          SizedBox(width: 4),
          Text(
            value.isNotEmpty ? value : label,
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: AnimalCard.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIconButton(
      {required IconData icon, Color? iconColor, VoidCallback? onTap}) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 1,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child:
              Icon(icon, size: 18, color: iconColor ?? AnimalCard.primaryColor),
        ),
      ),
    );
  }

  String _getFormattedDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays < 1) {
      final hours = diff.inHours;
      if (hours < 1) {
        final mins = diff.inMinutes;
        if (mins < 1) return 'Şimdi';
        return '$mins dakika önce';
      }
      return '$hours saat önce';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} gün önce';
    } else {
      return DateFormat('dd.MM.yyyy').format(date);
    }
  }
}

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import '../models/animal_post.dart';
import '../models/sale_rating.dart';
import '../services/sale_rating_service.dart';
import '../utils/animal_colors.dart';

class SaleRatingDialog extends StatefulWidget {
  final AnimalPost animal;
  final String sellerId;
  final String buyerId;
  final String saleId;
  final VoidCallback? onRatingSubmitted;

  const SaleRatingDialog({
    Key? key,
    required this.animal,
    required this.sellerId,
    required this.buyerId,
    required this.saleId,
    this.onRatingSubmitted,
  }) : super(key: key);

  @override
  State<SaleRatingDialog> createState() => _SaleRatingDialogState();
}

class _SaleRatingDialogState extends State<SaleRatingDialog> {
  double _rating = 5.0;
  final TextEditingController _commentController = TextEditingController();
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Column(
        children: [
          Icon(
            Icons.star_rate_rounded,
            color: AnimalColors.accent,
            size: 32,
          ),
          SizedBox(height: 8),
          Text(
            "Satışı Değerlendirin",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Hayvan bilgisi
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      widget.animal.photoUrls.isNotEmpty
                          ? widget.animal.photoUrls.first
                          : '',
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 50,
                          height: 50,
                          color: Colors.grey[800],
                          child: Icon(
                            Icons.pets,
                            color: Colors.white54,
                          ),
                        );
                      },
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.animal.animalSpecies,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          "${widget.animal.priceInTL.toStringAsFixed(0)} ₺",
                          style: TextStyle(
                            color: AnimalColors.accent,
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 20),

            // Değerlendirme yıldızları
            Text(
              "Satıcıyı değerlendirin:",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
                fontSize: 16,
              ),
            ),
            SizedBox(height: 12),

            RatingBar.builder(
              initialRating: _rating,
              minRating: 1,
              direction: Axis.horizontal,
              allowHalfRating: true,
              itemCount: 5,
              itemPadding: EdgeInsets.symmetric(horizontal: 4.0),
              itemBuilder: (context, _) => Icon(
                Icons.star,
                color: AnimalColors.accent,
              ),
              onRatingUpdate: (rating) {
                setState(() {
                  _rating = rating;
                });
              },
            ),

            SizedBox(height: 8),

            // Puanın açıklaması
            Text(
              _getRatingDescription(_rating),
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 12,
              ),
            ),

            SizedBox(height: 20),

            // Yorum alanı
            TextField(
              controller: _commentController,
              maxLines: 3,
              maxLength: 200,
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "İsteğe bağlı yorum yazın...",
                hintStyle: TextStyle(color: Colors.grey[400]),
                filled: true,
                fillColor: Colors.grey[900],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AnimalColors.primary),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
          style: TextButton.styleFrom(
            foregroundColor: Colors.grey,
          ),
          child: Text(
            "İptal",
            style: TextStyle(
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submitRating,
          style: ElevatedButton.styleFrom(
            backgroundColor: AnimalColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
          child: _isSubmitting
              ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(
                  "Değerlendir",
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
      ],
    );
  }

  String _getRatingDescription(double rating) {
    if (rating >= 4.5) return "Mükemmel";
    if (rating >= 4.0) return "Çok iyi";
    if (rating >= 3.5) return "İyi";
    if (rating >= 3.0) return "Orta";
    if (rating >= 2.5) return "Vasat";
    if (rating >= 2.0) return "Kötü";
    return "Çok kötü";
  }

  void _submitRating() async {
    if (_isSubmitting) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final result = await SaleRatingService().submitRating(
        saleId: widget.saleId,
        sellerId: widget.sellerId,
        buyerId: widget.buyerId,
        rating: _rating,
        comment: _commentController.text.trim(),
      );

      if (result == "success") {
        Navigator.pop(context);
        if (widget.onRatingSubmitted != null) {
          widget.onRatingSubmitted!();
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Değerlendirmeniz başarıyla kaydedildi"),
            backgroundColor: AnimalColors.success,
          ),
        );
      } else {
        throw Exception(result);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Değerlendirme kaydedilemedi: $e"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }
}

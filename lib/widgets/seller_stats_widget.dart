import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/animal_colors.dart';
import '../services/sale_rating_service.dart';

class SellerStatsWidget extends StatefulWidget {
  final String userId;
  final bool showFullStats;

  const SellerStatsWidget({
    Key? key,
    required this.userId,
    this.showFullStats = false,
  }) : super(key: key);

  @override
  State<SellerStatsWidget> createState() => _SellerStatsWidgetState();
}

class _SellerStatsWidgetState extends State<SellerStatsWidget> {
  double averageRating = 0.0;
  int totalRatings = 0;
  int totalSales = 0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final ratingService = SaleRatingService();

      // Paralel olarak istatistikleri yükle
      final results = await Future.wait([
        ratingService.getUserAverageRating(widget.userId),
        ratingService.getUserTotalRatings(widget.userId),
        _getTotalSales(),
      ]);

      if (mounted) {
        setState(() {
          averageRating = results[0] as double;
          totalRatings = results[1] as int;
          totalSales = results[2] as int;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<int> _getTotalSales() async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .get();

      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>;
        return data['totalSales'] as int? ?? 0;
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return SizedBox(
        height: widget.showFullStats ? 60 : 30,
        child: Center(
          child: SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(AnimalColors.primary),
            ),
          ),
        ),
      );
    }

    if (widget.showFullStats) {
      return _buildFullStats();
    } else {
      return _buildCompactStats();
    }
  }

  Widget _buildFullStats() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AnimalColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AnimalColors.primary.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Satıcı İstatistikleri",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AnimalColors.primary,
            ),
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  "Ortalama Puan",
                  averageRating?.toStringAsFixed(1) ?? '0.0',
                  Icons.star,
                  Colors.amber,
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: _buildStatCard(
                  "Toplam Satış",
                  totalSales.toString(),
                  Icons.shopping_cart,
                  Colors.green,
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: _buildStatCard(
                  "Değerlendirme",
                  totalRatings?.toString() ?? '0',
                  Icons.rate_review,
                  Colors.blue,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompactStats() {
    return Row(
      children: [
        if (averageRating != null && averageRating > 0) ...[
          Icon(
            Icons.star,
            color: Colors.amber,
            size: 16,
          ),
          SizedBox(width: 4),
          Text(
            averageRating?.toStringAsFixed(1) ?? '0.0',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.amber,
            ),
          ),
          SizedBox(width: 12),
        ],
        if (totalSales != null && totalSales > 0) ...[
          Icon(
            Icons.shopping_cart,
            color: Colors.green,
            size: 16,
          ),
          SizedBox(width: 4),
          Text(
            "$totalSales satış",
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.green,
            ),
          ),
        ],
        if ((averageRating == null || averageRating == 0) &&
            (totalSales == null || totalSales == 0)) ...[
          Text(
            "Yeni satıcı",
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 20,
          ),
          SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          SizedBox(height: 2),
          Text(
            title,
            style: TextStyle(
              fontSize: 10,
              color: color.withOpacity(0.8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

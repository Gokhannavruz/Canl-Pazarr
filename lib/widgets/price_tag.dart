import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/animal_colors.dart';
import '../services/pricing_service.dart';

class PriceTag extends StatelessWidget {
  final double price;
  final bool isNegotiable;
  final bool isUrgent;
  final bool showAnimation;
  final double fontSize;

  const PriceTag({
    Key? key,
    required this.price,
    this.isNegotiable = false,
    this.isUrgent = false,
    this.showAnimation = true,
    this.fontSize = 14,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: Duration(milliseconds: showAnimation ? 300 : 0),
      padding: EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        gradient: isUrgent
            ? LinearGradient(
                colors: [Color(0xFFE91E63), Color(0xFFC2185B)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : LinearGradient(
                colors: [Color(0xFF2E7D32), Color(0xFF388E3C)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 6,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Fiyat animasyonu
          if (isUrgent && showAnimation)
            _buildUrgentAnimation()
          else
            _buildPriceText(),

          // Pazarlık ikonu
          if (isNegotiable) ...[
            SizedBox(width: 6),
            Icon(
              Icons.handshake,
              color: Colors.white,
              size: fontSize - 1,
            ),
          ],

          // Acil satış ikonu
          if (isUrgent) ...[
            SizedBox(width: 6),
            Icon(
              Icons.flash_on,
              color: Colors.white,
              size: fontSize - 1,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPriceText() {
    return Text(
      PricingService.formatPrice(price),
      style: GoogleFonts.poppins(
        color: Colors.white,
        fontWeight: FontWeight.w600,
        fontSize: fontSize,
      ),
    );
  }

  Widget _buildUrgentAnimation() {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0.8, end: 1.2),
      duration: Duration(milliseconds: 500),
      builder: (context, double scale, child) {
        return Transform.scale(
          scale: scale,
          child: _buildPriceText(),
        );
      },
    );
  }
}

// Büyük fiyat etiketi variant'ı
class LargePriceTag extends StatelessWidget {
  final double price;
  final bool isNegotiable;
  final bool isUrgent;
  final String? priceCategory;

  const LargePriceTag({
    Key? key,
    required this.price,
    this.isNegotiable = false,
    this.isUrgent = false,
    this.priceCategory,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: isUrgent
            ? LinearGradient(
                colors: [Color(0xFFE91E63), Color(0xFFC2185B)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : LinearGradient(
                colors: [Color(0xFF2E7D32), Color(0xFF388E3C)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ana fiyat
          Row(
            children: [
              Text(
                PricingService.formatPrice(price),
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 28,
                ),
              ),
              if (isUrgent) ...[
                SizedBox(width: 12),
                Icon(
                  Icons.flash_on,
                  color: Colors.white,
                  size: 24,
                ),
              ],
            ],
          ),

          SizedBox(height: 8),

          // Alt bilgiler
          Row(
            children: [
              if (isNegotiable) ...[
                Icon(
                  Icons.handshake,
                  color: Colors.white.withOpacity(0.9),
                  size: 18,
                ),
                SizedBox(width: 6),
                Text(
                  'Pazarlık Yapılabilir',
                  style: GoogleFonts.poppins(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
              if (priceCategory != null) ...[
                if (isNegotiable) SizedBox(width: 12),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    priceCategory!,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

// Kompakt fiyat etiketi (liste görünümü için)
class CompactPriceTag extends StatelessWidget {
  final double price;
  final bool isNegotiable;
  final bool isUrgent;

  const CompactPriceTag({
    Key? key,
    required this.price,
    this.isNegotiable = false,
    this.isUrgent = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AnimalColors.getPriceColor(isNegotiable, isUrgent),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            PricingService.formatPrice(price),
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          if (isNegotiable) ...[
            SizedBox(width: 2),
            Icon(
              Icons.handshake,
              color: Colors.white,
              size: 10,
            ),
          ],
          if (isUrgent) ...[
            SizedBox(width: 2),
            Icon(
              Icons.flash_on,
              color: Colors.white,
              size: 10,
            ),
          ],
        ],
      ),
    );
  }
}

// Fiyat karşılaştırma widget'ı
class PriceComparison extends StatelessWidget {
  final double currentPrice;
  final double averagePrice;
  final double minPrice;
  final double maxPrice;

  const PriceComparison({
    Key? key,
    required this.currentPrice,
    required this.averagePrice,
    required this.minPrice,
    required this.maxPrice,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isAboveAverage = currentPrice > averagePrice;
    final isWithinRange = currentPrice >= minPrice && currentPrice <= maxPrice;

    return Card(
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Fiyat Karşılaştırması',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),

            // Mevcut fiyat
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Mevcut Fiyat:'),
                Text(
                  PricingService.formatPrice(currentPrice),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isAboveAverage ? Colors.red : Colors.green,
                  ),
                ),
              ],
            ),

            // Ortalama fiyat
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Ortalama:'),
                Text(PricingService.formatPrice(averagePrice)),
              ],
            ),

            // Fiyat aralığı
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Aralık:'),
                Text(PricingService.formatPriceRange(minPrice, maxPrice)),
              ],
            ),

            SizedBox(height: 8),

            // Durum göstergesi
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isWithinRange
                    ? Colors.green.withOpacity(0.1)
                    : Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    isWithinRange ? Icons.check_circle : Icons.warning,
                    color: isWithinRange ? Colors.green : Colors.orange,
                    size: 16,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isWithinRange
                          ? 'Fiyat makul aralıkta'
                          : 'Fiyat ${isAboveAverage ? 'ortalamanın üstünde' : 'ortalamanın altında'}',
                      style: TextStyle(
                        color: isWithinRange ? Colors.green : Colors.orange,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

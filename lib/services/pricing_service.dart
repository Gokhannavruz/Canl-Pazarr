import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PricingService {
  static String formatPrice(double price) {
    final formatter = NumberFormat('#,###', 'tr_TR');
    return '${formatter.format(price)} ₺';
  }

  static bool validatePrice(double price, String animalType) {
    if (animalType == 'büyükbaş') {
      return price >= 5000 && price <= 200000;
    } else if (animalType == 'küçükbaş') {
      return price >= 500 && price <= 20000;
    }
    return false;
  }

  static Future<Map<String, double>> getAveragePrices(
      String animalType, String breed, String location) async {
    try {
      // Firebase'den geçmiş satış verilerini al
      final query = await FirebaseFirestore.instance
          .collection('animals')
          .where('animalType', isEqualTo: animalType)
          .where('animalBreed', isEqualTo: breed)
          .where('isActive', isEqualTo: false)
          .where('soldDate', isNotEqualTo: null)
          .where('city', isEqualTo: location)
          .get();

      List<double> prices = [];
      for (var doc in query.docs) {
        final data = doc.data();
        if (data['priceInTL'] != null) {
          prices.add(data['priceInTL'].toDouble());
        }
      }

      if (prices.isEmpty) {
        return {
          'average': 0.0,
          'min': 0.0,
          'max': 0.0,
        };
      }

      prices.sort();
      double sum = prices.reduce((a, b) => a + b);
      double average = sum / prices.length;

      return {
        'average': average,
        'min': prices.first,
        'max': prices.last,
      };
    } catch (e) {
      return {
        'average': 0.0,
        'min': 0.0,
        'max': 0.0,
      };
    }
  }

  static String formatPriceRange(double minPrice, double maxPrice) {
    return '${formatPrice(minPrice)} - ${formatPrice(maxPrice)}';
  }

  static double calculatePricePerKg(double totalPrice, double weightInKg) {
    if (weightInKg == 0) return 0;
    return totalPrice / weightInKg;
  }

  static String formatPricePerKg(double pricePerKg) {
    final formatter = NumberFormat('#,###.##', 'tr_TR');
    return '${formatter.format(pricePerKg)} ₺/kg';
  }

  static String getPriceCategory(double price, String animalType) {
    if (animalType == 'büyükbaş') {
      if (price < 15000) return 'Düşük';
      if (price < 30000) return 'Orta';
      if (price < 50000) return 'Yüksek';
      return 'Çok Yüksek';
    } else if (animalType == 'küçükbaş') {
      if (price < 2000) return 'Düşük';
      if (price < 5000) return 'Orta';
      if (price < 10000) return 'Yüksek';
      return 'Çok Yüksek';
    }
    return 'Bilinmiyor';
  }

  static bool isPriceReasonable(
      double price, String animalType, String breed, int ageInMonths) {
    // Yaş faktörü
    double ageFactor = 1.0;
    if (ageInMonths < 6) {
      ageFactor = 0.6; // Genç hayvanlar daha ucuz
    } else if (ageInMonths > 60) {
      ageFactor = 0.8; // Yaşlı hayvanlar daha ucuz
    }

    // Irk faktörü
    double breedFactor = 1.0;
    if (breed == 'Holstein' || breed == 'Angus') {
      breedFactor = 1.2; // Değerli ırklar daha pahalı
    } else if (breed == 'Yerli' || breed == 'Kırma') {
      breedFactor = 0.8; // Yerli ırklar daha ucuz
    }

    // Tip faktörü
    double basePrice = animalType == 'büyükbaş' ? 20000 : 3000;
    double expectedPrice = basePrice * ageFactor * breedFactor;

    // %50 tolerans
    return price >= expectedPrice * 0.5 && price <= expectedPrice * 1.5;
  }

  static Map<String, dynamic> getPriceAnalysis(
      double price, String animalType, String breed, int ageInMonths) {
    return {
      'isReasonable': isPriceReasonable(price, animalType, breed, ageInMonths),
      'category': getPriceCategory(price, animalType),
      'formattedPrice': formatPrice(price),
      'recommendation':
          _getPriceRecommendation(price, animalType, breed, ageInMonths),
    };
  }

  static String _getPriceRecommendation(
      double price, String animalType, String breed, int ageInMonths) {
    if (isPriceReasonable(price, animalType, breed, ageInMonths)) {
      return 'Fiyat makul görünüyor';
    }

    String category = getPriceCategory(price, animalType);
    if (category == 'Çok Yüksek') {
      return 'Fiyat piyasa ortalamasının üzerinde, pazarlık yapabilirsiniz';
    } else if (category == 'Düşük') {
      return 'Fiyat piyasa ortalamasının altında, dikkatli olun';
    }

    return 'Fiyat değerlendirmesi yapılamadı';
  }

  static Future<List<Map<String, dynamic>>> getPriceHistory(
      String animalType, String breed, int days) async {
    try {
      DateTime since = DateTime.now().subtract(Duration(days: days));

      final query = await FirebaseFirestore.instance
          .collection('animals')
          .where('animalType', isEqualTo: animalType)
          .where('animalBreed', isEqualTo: breed)
          .where('soldDate', isGreaterThan: since)
          .orderBy('soldDate', descending: false)
          .get();

      List<Map<String, dynamic>> priceHistory = [];
      for (var doc in query.docs) {
        final data = doc.data();
        if (data['priceInTL'] != null && data['soldDate'] != null) {
          priceHistory.add({
            'date': data['soldDate'].toDate(),
            'price': data['priceInTL'].toDouble(),
            'weightInKg': data['weightInKg']?.toDouble() ?? 0,
            'ageInMonths': data['ageInMonths'] ?? 0,
            'city': data['city'] ?? '',
          });
        }
      }

      return priceHistory;
    } catch (e) {
      return [];
    }
  }

  static double calculateInstallmentAmount(
      double totalPrice, int installmentCount) {
    if (installmentCount <= 0) return totalPrice;
    return totalPrice / installmentCount;
  }

  static String formatInstallment(double totalPrice, int installmentCount) {
    double installmentAmount =
        calculateInstallmentAmount(totalPrice, installmentCount);
    return '$installmentCount x ${formatPrice(installmentAmount)}';
  }
}

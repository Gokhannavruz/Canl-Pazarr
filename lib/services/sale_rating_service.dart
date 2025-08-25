import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import '../models/sale_rating.dart';

class SaleRatingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Satış değerlendirmesi gönder
  Future<String> submitRating({
    required String saleId,
    required String sellerId,
    required String buyerId,
    required double rating,
    required String comment,
  }) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        return "Kullanıcı oturum açmamış";
      }

      if (currentUser.uid != buyerId) {
        return "Sadece alıcı değerlendirme yapabilir";
      }

      final ratingId = const Uuid().v1();
      final now = DateTime.now();

      // Değerlendirme kaydını oluştur
      final saleRating = SaleRating(
        ratingId: ratingId,
        saleId: saleId,
        sellerId: sellerId,
        buyerId: buyerId,
        rating: rating,
        comment: comment,
        dateRated: now,
        isVerified: true,
      );

      // Firestore'a kaydet
      await _firestore
          .collection('sale_ratings')
          .doc(ratingId)
          .set(saleRating.toJson());

      // Hayvan ilanının değerlendirme durumunu güncelle
      await _firestore.collection('animals').doc(saleId).update({
        'hasRating': true,
        'ratingId': ratingId,
        'canBeRated': false,
      });

      // Satıcının ortalama puanını güncelle
      await _updateSellerRating(sellerId);

      return "success";
    } catch (e) {
      print("Error submitting rating: $e");
      return e.toString();
    }
  }

  // Satıcının ortalama puanını güncelle
  Future<void> _updateSellerRating(String sellerId) async {
    try {
      final ratingsQuery = await _firestore
          .collection('sale_ratings')
          .where('sellerId', isEqualTo: sellerId)
          .get();

      if (ratingsQuery.docs.isNotEmpty) {
        double totalRating = 0;
        int ratingCount = ratingsQuery.docs.length;

        for (var doc in ratingsQuery.docs) {
          final data = doc.data();
          totalRating += (data['rating'] as num).toDouble();
        }

        double averageRating = totalRating / ratingCount;

        // 5 üzerinden puan olarak sınırla
        averageRating = double.parse(averageRating.toStringAsFixed(2));

        print('📊 Updating seller rating:');
        print('  - Seller ID: $sellerId');
        print('  - Average Rating: $averageRating');
        print('  - Total Ratings: $ratingCount');

        // Mevcut satış sayısını al
        final userDoc =
            await _firestore.collection('users').doc(sellerId).get();
        int currentSales = 0;
        if (userDoc.exists) {
          final userData = userDoc.data() as Map<String, dynamic>? ?? {};
          currentSales = (userData['totalSales'] as int?) ?? 0;
        }

        // Kullanıcının profil bilgilerini güncelle
        await _firestore.collection('users').doc(sellerId).update({
          'averageRating': averageRating,
          'totalRatings': ratingCount,
          'totalSales': currentSales + 1, // Satış sayısını +1 artır
        });

        print('✅ Seller rating updated successfully');
        print('  - New total sales: ${currentSales + 1}');
      }
    } catch (e) {
      print("Error updating seller rating: $e");
    }
  }

  // Kullanıcının değerlendirmelerini getir
  Future<List<SaleRating>> getUserRatings(String userId) async {
    try {
      final ratingsQuery = await _firestore
          .collection('sale_ratings')
          .where('sellerId', isEqualTo: userId)
          .orderBy('dateRated', descending: true)
          .get();

      return ratingsQuery.docs.map((doc) => SaleRating.fromSnap(doc)).toList();
    } catch (e) {
      print("Error getting user ratings: $e");
      return [];
    }
  }

  // Belirli bir satış için değerlendirme var mı kontrol et
  Future<bool> hasRatingForSale(String saleId) async {
    try {
      final ratingQuery = await _firestore
          .collection('sale_ratings')
          .where('saleId', isEqualTo: saleId)
          .limit(1)
          .get();

      return ratingQuery.docs.isNotEmpty;
    } catch (e) {
      print("Error checking rating existence: $e");
      return false;
    }
  }

  // Satış için değerlendirme getirir
  Future<SaleRating?> getRatingForSale(String saleId) async {
    try {
      final ratingQuery = await _firestore
          .collection('sale_ratings')
          .where('saleId', isEqualTo: saleId)
          .limit(1)
          .get();

      if (ratingQuery.docs.isNotEmpty) {
        return SaleRating.fromSnap(ratingQuery.docs.first);
      }
      return null;
    } catch (e) {
      print("Error getting rating for sale: $e");
      return null;
    }
  }

  // Kullanıcının ortalama puanını getir
  Future<double> getUserAverageRating(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>;
        return (data['averageRating'] as num?)?.toDouble() ?? 0.0;
      }
      return 0.0;
    } catch (e) {
      print("Error getting user average rating: $e");
      return 0.0;
    }
  }

  // Kullanıcının toplam değerlendirme sayısını getir
  Future<int> getUserTotalRatings(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>;
        return data['totalRatings'] as int? ?? 0;
      }
      return 0;
    } catch (e) {
      print("Error getting user total ratings: $e");
      return 0;
    }
  }
}

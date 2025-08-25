import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/animal_post.dart';

class AnimalSaleService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Hayvanı satıldı olarak işaretle
  Future<String> markAnimalAsSold({
    required String animalId,
    required String sellerId,
    required String buyerId,
  }) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        return "Kullanıcı oturum açmamış";
      }

      if (currentUser.uid != sellerId) {
        return "Sadece satıcı hayvanı satıldı olarak işaretleyebilir";
      }

      final now = DateTime.now();

      // Hayvan ilanını güncelle
      await _firestore.collection('animals').doc(animalId).update({
        'saleStatus': 'sold',
        'soldDate': now,
        'buyerUid': buyerId,
        'canBeRated': true,
        'isActive': false,
      });

      // Satıcının satış sayısını artır
      await _updateSellerStats(sellerId);

      return "success";
    } catch (e) {
      print("Error marking animal as sold: $e");
      return e.toString();
    }
  }

  // Satıcının istatistiklerini güncelle
  Future<void> _updateSellerStats(String sellerId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(sellerId).get();
      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>;
        final totalSales = (data['totalSales'] as int? ?? 0) + 1;

        await _firestore.collection('users').doc(sellerId).update({
          'totalSales': totalSales,
        });
      }
    } catch (e) {
      print("Error updating seller stats: $e");
    }
  }

  // Satış durumunu kontrol et
  Future<bool> canMarkAsSold(String animalId, String sellerId) async {
    try {
      final animalDoc =
          await _firestore.collection('animals').doc(animalId).get();
      if (animalDoc.exists) {
        final data = animalDoc.data() as Map<String, dynamic>;
        final saleStatus = data['saleStatus'] as String? ?? 'active';
        final animalSellerId = data['uid'] as String? ?? '';

        return saleStatus == 'active' && animalSellerId == sellerId;
      }
      return false;
    } catch (e) {
      print("Error checking if can mark as sold: $e");
      return false;
    }
  }

  // Hayvan satış bilgilerini getir
  Future<Map<String, dynamic>?> getAnimalSaleInfo(String animalId) async {
    try {
      final animalDoc =
          await _firestore.collection('animals').doc(animalId).get();
      if (animalDoc.exists) {
        final data = animalDoc.data() as Map<String, dynamic>;
        return {
          'saleStatus': data['saleStatus'] ?? 'active',
          'soldDate': data['soldDate']?.toDate(),
          'buyerUid': data['buyerUid'],
          'canBeRated': data['canBeRated'] ?? false,
          'hasRating': data['hasRating'] ?? false,
          'sellerId': data['uid'],
        };
      }
      return null;
    } catch (e) {
      print("Error getting animal sale info: $e");
      return null;
    }
  }

  // Alıcının değerlendirme yapması gereken satışları getir
  Future<List<AnimalPost>> getPendingRatings(String buyerId) async {
    try {
      final animalsQuery = await _firestore
          .collection('animals')
          .where('buyerUid', isEqualTo: buyerId)
          .where('saleStatus', isEqualTo: 'sold')
          .where('canBeRated', isEqualTo: true)
          .where('hasRating', isEqualTo: false)
          .get();

      return animalsQuery.docs.map((doc) => AnimalPost.fromSnap(doc)).toList();
    } catch (e) {
      print("Error getting pending ratings: $e");
      return [];
    }
  }

  // Kullanıcının satışlarını getir
  Future<List<AnimalPost>> getUserSales(String userId) async {
    try {
      final animalsQuery = await _firestore
          .collection('animals')
          .where('uid', isEqualTo: userId)
          .where('saleStatus', isEqualTo: 'sold')
          .orderBy('soldDate', descending: true)
          .get();

      return animalsQuery.docs.map((doc) => AnimalPost.fromSnap(doc)).toList();
    } catch (e) {
      print("Error getting user sales: $e");
      return [];
    }
  }

  // Kullanıcının satın alımlarını getir
  Future<List<AnimalPost>> getUserPurchases(String userId) async {
    try {
      final animalsQuery = await _firestore
          .collection('animals')
          .where('buyerUid', isEqualTo: userId)
          .where('saleStatus', isEqualTo: 'sold')
          .orderBy('soldDate', descending: true)
          .get();

      return animalsQuery.docs.map((doc) => AnimalPost.fromSnap(doc)).toList();
    } catch (e) {
      print("Error getting user purchases: $e");
      return [];
    }
  }

  // Satış işlemini iptal et (sadece henüz değerlendirme yapılmamışsa)
  Future<String> cancelSale(String animalId, String sellerId) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        return "Kullanıcı oturum açmamış";
      }

      if (currentUser.uid != sellerId) {
        return "Sadece satıcı satış işlemini iptal edebilir";
      }

      final animalDoc =
          await _firestore.collection('animals').doc(animalId).get();
      if (!animalDoc.exists) {
        return "Hayvan bulunamadı";
      }

      final data = animalDoc.data() as Map<String, dynamic>;
      final hasRating = data['hasRating'] as bool? ?? false;

      if (hasRating) {
        return "Değerlendirme yapılmış satış iptal edilemez";
      }

      // Satış durumunu sıfırla
      await _firestore.collection('animals').doc(animalId).update({
        'saleStatus': 'active',
        'soldDate': FieldValue.delete(),
        'buyerUid': FieldValue.delete(),
        'canBeRated': false,
        'isActive': true,
      });

      // Satıcının satış sayısını azalt
      await _decreaseSellerStats(sellerId);

      return "success";
    } catch (e) {
      print("Error canceling sale: $e");
      return e.toString();
    }
  }

  // Satıcının istatistiklerini azalt
  Future<void> _decreaseSellerStats(String sellerId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(sellerId).get();
      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>;
        final totalSales = (data['totalSales'] as int? ?? 0) - 1;

        await _firestore.collection('users').doc(sellerId).update({
          'totalSales': totalSales < 0 ? 0 : totalSales,
        });
      }
    } catch (e) {
      print("Error decreasing seller stats: $e");
    }
  }
}

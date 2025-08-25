import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/transporter.dart';

class TransporterService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'users'; // users koleksiyonunu kullan

  // Yakındaki nakliyecileri getir
  static Future<List<Transporter>> getNearbyTransporters({
    required String city,
    String? state,
    int limit = 10,
  }) async {
    try {
      print('Searching for transporters in city: $city, state: $state');

      // Önce bu şehirde çalışan nakliyecileri getir (available kontrolü olmadan)
      Query query = _firestore
          .collection(_collection)
          .where('isTransporter', isEqualTo: true)
          .where('transporterCities', arrayContains: city);

      final QuerySnapshot snapshot = await query.get();

      print('Found ${snapshot.docs.length} transporters in city $city');

      List<Transporter> transporters = snapshot.docs.map((doc) {
        return Transporter.fromMap(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }).toList();

      // Available olanları filtrele ve rating'e göre sırala
      transporters = transporters.where((t) => t.available).toList()
        ..sort((a, b) => (b.rating ?? 0).compareTo(a.rating ?? 0));

      // Limit'e göre kes
      if (transporters.length > limit) {
        transporters = transporters.take(limit).toList();
      }

      print('After filtering available: ${transporters.length} transporters');

      // Eğer yeterli nakliyeci bulunamadıysa, bölge/il bazında da ara
      if (transporters.length < limit && state != null) {
        print('Searching in region: $state');

        Query regionQuery = _firestore
            .collection(_collection)
            .where('isTransporter', isEqualTo: true)
            .where('transporterRegions', arrayContains: state);

        final QuerySnapshot regionSnapshot = await regionQuery.get();

        print(
            'Found ${regionSnapshot.docs.length} transporters in region $state');

        List<Transporter> regionTransporters = regionSnapshot.docs.map((doc) {
          return Transporter.fromMap(
            doc.data() as Map<String, dynamic>,
            doc.id,
          );
        }).toList();

        // Available olanları filtrele ve rating'e göre sırala
        regionTransporters = regionTransporters
            .where((t) => t.available)
            .toList()
          ..sort((a, b) => (b.rating ?? 0).compareTo(a.rating ?? 0));

        // Duplicate'leri önle
        Set<String> existingIds =
            transporters.map((t) => t.transporterId).toSet();
        for (var transporter in regionTransporters) {
          if (!existingIds.contains(transporter.transporterId) &&
              transporters.length < limit) {
            transporters.add(transporter);
            existingIds.add(transporter.transporterId);
          }
        }
      }

      print('Final result: ${transporters.length} transporters');
      return transporters;
    } catch (e) {
      print('Error getting nearby transporters: $e');
      return [];
    }
  }

  // Şehirdeki tüm nakliyecileri getir
  static Future<List<Transporter>> getTransportersByCity({
    required String city,
    String? state,
    int limit = 50,
  }) async {
    try {
      print('Getting all transporters in city: $city');

      Query query = _firestore
          .collection(_collection)
          .where('isTransporter', isEqualTo: true)
          .where('transporterCities', arrayContains: city);

      final QuerySnapshot snapshot = await query.get();

      print('Found ${snapshot.docs.length} transporters in city $city');

      List<Transporter> transporters = snapshot.docs.map((doc) {
        return Transporter.fromMap(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }).toList();

      // Rating'e göre sırala
      transporters.sort((a, b) => (b.rating ?? 0).compareTo(a.rating ?? 0));

      // Limit'e göre kes
      if (transporters.length > limit) {
        transporters = transporters.take(limit).toList();
      }

      print('Final result: ${transporters.length} transporters');
      return transporters;
    } catch (e) {
      print('Error getting transporters by city: $e');
      return [];
    }
  }

  // Nakliyeci detayını getir
  static Future<Transporter?> getTransporterById(String transporterId) async {
    try {
      final DocumentSnapshot doc =
          await _firestore.collection(_collection).doc(transporterId).get();

      if (doc.exists) {
        return Transporter.fromMap(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }
      return null;
    } catch (e) {
      print('Error getting transporter by id: $e');
      return null;
    }
  }

  // Kullanıcının nakliyeci profilini getir
  static Future<Transporter?> getTransporterByUserId(String userId) async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return Transporter.fromMap(
          snapshot.docs.first.data() as Map<String, dynamic>,
          snapshot.docs.first.id,
        );
      }
      return null;
    } catch (e) {
      print('Error getting transporter by user id: $e');
      return null;
    }
  }

  // Nakliyeci profili oluştur/güncelle
  static Future<String?> createOrUpdateTransporter(
      Transporter transporter) async {
    try {
      final data = transporter.toMap();
      data['updatedAt'] = FieldValue.serverTimestamp();

      if (transporter.transporterId.isEmpty) {
        // Yeni nakliyeci oluştur
        data['createdAt'] = FieldValue.serverTimestamp();
        final docRef = await _firestore.collection(_collection).add(data);
        return docRef.id;
      } else {
        // Mevcut nakliyeciyi güncelle
        await _firestore
            .collection(_collection)
            .doc(transporter.transporterId)
            .update(data);
        return transporter.transporterId;
      }
    } catch (e) {
      print('Error creating/updating transporter: $e');
      return null;
    }
  }

  // Nakliyeciyi sil
  static Future<bool> deleteTransporter(String transporterId) async {
    try {
      await _firestore.collection(_collection).doc(transporterId).delete();
      return true;
    } catch (e) {
      print('Error deleting transporter: $e');
      return false;
    }
  }

  // Nakliyeci müsaitlik durumunu güncelle
  static Future<bool> updateAvailability(
      String transporterId, bool available) async {
    try {
      await _firestore.collection(_collection).doc(transporterId).update({
        'available': available,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      print('Error updating transporter availability: $e');
      return false;
    }
  }

  // Nakliyeci puanını güncelle
  static Future<bool> updateRating(String transporterId, double rating) async {
    try {
      await _firestore.collection(_collection).doc(transporterId).update({
        'rating': rating,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      print('Error updating transporter rating: $e');
      return false;
    }
  }

  // Nakliyeci seyahat sayısını artır
  static Future<bool> incrementTotalTrips(String transporterId) async {
    try {
      await _firestore.collection(_collection).doc(transporterId).update({
        'totalTrips': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      print('Error incrementing transporter total trips: $e');
      return false;
    }
  }

  // Arama yap
  static Future<List<Transporter>> searchTransporters({
    String? city,
    String? vehicleType,
    List<String>? animalTypes,
    double? minPrice,
    double? maxPrice,
    bool? insurance,
    int limit = 20,
  }) async {
    try {
      Query query = _firestore.collection(_collection);

      if (city != null) {
        query = query.where('cities', arrayContains: city);
      }

      if (vehicleType != null) {
        query = query.where('vehicleType', isEqualTo: vehicleType);
      }

      if (animalTypes != null && animalTypes.isNotEmpty) {
        query = query.where('animalTypes', arrayContainsAny: animalTypes);
      }

      if (insurance != null) {
        query = query.where('insurance', isEqualTo: insurance);
      }

      query = query.orderBy('rating', descending: true).limit(limit);

      final QuerySnapshot snapshot = await query.get();

      List<Transporter> transporters = snapshot.docs.map((doc) {
        return Transporter.fromMap(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }).toList();

      // Fiyat filtresi (Firestore'da range query yapamadığımız için client-side)
      if (minPrice != null || maxPrice != null) {
        transporters = transporters.where((transporter) {
          if (minPrice != null &&
              transporter.minPrice != null &&
              transporter.minPrice! < minPrice) {
            return false;
          }
          if (maxPrice != null &&
              transporter.maxPrice != null &&
              transporter.maxPrice! > maxPrice) {
            return false;
          }
          return true;
        }).toList();
      }

      return transporters;
    } catch (e) {
      print('Error searching transporters: $e');
      return [];
    }
  }
}

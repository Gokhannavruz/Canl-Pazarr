import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:animal_trade/resources/storage_methods.dart';
import 'package:uuid/uuid.dart';
import '../models/animal_post.dart';

class AnimalFirestoreMethods {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Hayvan ilanı yükleme
  Future<String> uploadAnimal({
    required String description,
    required List<Uint8List> files,
    required String uid,
    required String username,
    required String profImage,
    required String country,
    required String state,
    required String city,
    required String animalType,
    required String animalSpecies,
    required String animalBreed,
    required int ageInMonths,
    required String gender,
    required double weightInKg,
    required double priceInTL,
    required String healthStatus,
    required List<String> vaccinations,
    required String purpose,
    required bool isPregnant,
    required DateTime? birthDate,
    required String? parentInfo,
    required List<String> certificates,
    required bool isNegotiable,
    required String sellerType,
    required String transportInfo,
    required bool isUrgentSale,
    required String? veterinarianContact,
    required Map<String, dynamic>? additionalInfo,
  }) async {
    String res = "Some error occurred";
    try {
      // Resim sayısını 10 ile sınırla
      List<Uint8List> limitedFiles =
          files.length > 10 ? files.sublist(0, 10) : files;

      List<String> photoUrls = [];
      // Her resmi yükle ve URL'leri al
      for (var file in limitedFiles) {
        String photoUrl =
            await StorageMethods().uploadImageToStorage('animals', file, true);
        photoUrls.add(photoUrl);
      }

      String animalId = const Uuid().v1();
      AnimalPost animal = AnimalPost(
        description: description,
        uid: uid,
        username: username,
        postId: animalId,
        datePublished: DateTime.now(),
        photoUrls: photoUrls,
        profImage: profImage,
        country: country,
        state: state,
        city: city,
        animalType: animalType,
        animalSpecies: animalSpecies,
        animalBreed: animalBreed,
        ageInMonths: ageInMonths,
        gender: gender,
        weightInKg: weightInKg,
        priceInTL: priceInTL,
        healthStatus: healthStatus,
        vaccinations: vaccinations,
        purpose: purpose,
        isPregnant: isPregnant,
        birthDate: birthDate,
        parentInfo: parentInfo,
        certificates: certificates,
        isNegotiable: isNegotiable,
        sellerType: sellerType,
        transportInfo: transportInfo,
        isUrgentSale: isUrgentSale,
        veterinarianContact: veterinarianContact,
        additionalInfo: additionalInfo,
        likes: [],
        saved: [],
        isActive: true,
        soldDate: null,
        buyerUid: null,
        saleStatus: "active",
        salePrice: null,
        hasRating: false,
        ratingId: null,
        canBeRated: false,
      );

      // Animals koleksiyonuna kaydet
      await _firestore
          .collection('animals')
          .doc(animalId)
          .set({"random": FieldValue.serverTimestamp(), ...animal.toJson()});

      // Kullanıcının animals array'ine ekle
      await _firestore.collection('users').doc(uid).update({
        'animals': FieldValue.arrayUnion([animalId])
      });

      res = "success";
    } catch (err) {
      res = err.toString();
    }
    return res;
  }

  // Hayvan ilanını beğenme
  Future<String> likeAnimal(String animalId, String uid, List likes) async {
    String res = "Some error occurred";
    try {
      if (likes.contains(uid)) {
        // Beğeniyi kaldır
        await _firestore.collection('animals').doc(animalId).update({
          'likes': FieldValue.arrayRemove([uid])
        });
      } else {
        // Beğeni ekle
        await _firestore.collection('animals').doc(animalId).update({
          'likes': FieldValue.arrayUnion([uid])
        });
      }
      res = 'success';
    } catch (err) {
      res = err.toString();
    }
    return res;
  }

  // Hayvan ilanını kaydetme
  Future<String> saveAnimal(String animalId, String uid, List saved) async {
    String res = "Some error occurred";
    try {
      if (saved.contains(uid)) {
        // Kaydetmekten çıkar
        await _firestore.collection('animals').doc(animalId).update({
          'saved': FieldValue.arrayRemove([uid])
        });
      } else {
        // Kaydet
        await _firestore.collection('animals').doc(animalId).update({
          'saved': FieldValue.arrayUnion([uid])
        });
      }
      res = 'success';
    } catch (err) {
      res = err.toString();
    }
    return res;
  }

  // Hayvan ilanını silme
  Future<String> deleteAnimal(String animalId) async {
    String res = "Some error occurred";
    try {
      // Önce hayvan dokümanını al
      DocumentSnapshot animalDoc =
          await _firestore.collection('animals').doc(animalId).get();
      if (!animalDoc.exists) {
        return "Animal does not exist";
      }

      Map<String, dynamic> animalData =
          animalDoc.data() as Map<String, dynamic>;
      String uid = animalData['uid'];

      // Batch işlem başlat
      WriteBatch batch = _firestore.batch();

      // Hayvan ile ilgili yorumları sil
      QuerySnapshot commentsSnapshot = await _firestore
          .collection('animals')
          .doc(animalId)
          .collection('comments')
          .get();

      for (var doc in commentsSnapshot.docs) {
        batch.delete(doc.reference);
      }

      // Hayvan ile ilgili bildirimleri sil
      QuerySnapshot notificationsSnapshot = await _firestore
          .collection('notifications')
          .where('postId', isEqualTo: animalId)
          .get();

      for (var doc in notificationsSnapshot.docs) {
        batch.delete(doc.reference);
      }

      // Kullanıcının animals array'inden kaldır
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(uid).get();
      if (userDoc.exists) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        if (userData.containsKey('animals') && userData['animals'] is List) {
          batch.update(_firestore.collection('users').doc(uid), {
            'animals': FieldValue.arrayRemove([animalId])
          });
        }
      }

      // Hayvan dokümanını sil
      batch.delete(_firestore.collection('animals').doc(animalId));

      // Batch'i commit et
      await batch.commit();

      res = "success";
    } catch (err) {
      res = err.toString();
    }
    return res;
  }

  // Hayvan ilanını satıldı olarak işaretle
  Future<String> markAnimalAsSold(String animalId, String? buyerUid) async {
    String res = "Some error occurred";
    try {
      await _firestore.collection('animals').doc(animalId).update({
        'isActive': false,
        'soldDate': DateTime.now(),
        'buyerUid': buyerUid,
      });
      res = 'success';
    } catch (err) {
      res = err.toString();
    }
    return res;
  }

  // Hayvan ilanını güncelleme
  Future<String> updateAnimal(
      String animalId, Map<String, dynamic> updates) async {
    String res = "Some error occurred";
    try {
      await _firestore.collection('animals').doc(animalId).update(updates);
      res = 'success';
    } catch (err) {
      res = err.toString();
    }
    return res;
  }

  // Hayvan ilanı yorumu ekleme
  Future<String> postAnimalComment(String animalId, String text, String uid,
      String name, String profilePic) async {
    String res = "Some error occurred";
    try {
      if (text.isNotEmpty) {
        String commentId = const Uuid().v1();
        await _firestore
            .collection('animals')
            .doc(animalId)
            .collection('comments')
            .doc(commentId)
            .set({
          'profilePic': profilePic,
          'name': name,
          'uid': uid,
          'text': text,
          'commentId': commentId,
          'datePublished': DateTime.now(),
        });
        res = 'success';
      } else {
        res = "Please enter text";
      }
    } catch (err) {
      res = err.toString();
    }
    return res;
  }

  // Hayvan ilanı yorumu silme
  Future<void> deleteAnimalComment(String animalId, String commentId) async {
    try {
      await _firestore
          .collection('animals')
          .doc(animalId)
          .collection('comments')
          .doc(commentId)
          .delete();
    } catch (e) {
      print(e.toString());
    }
  }

  // Hayvan ilanı bildirim ekleme
  Future<String> addAnimalNotification(
      String type,
      String animalId,
      String animalOwnerId,
      String userId,
      String userName,
      String notificationText) async {
    String res = "Some error occurred";
    try {
      String notificationId = const Uuid().v1();
      await _firestore.collection('notifications').doc(notificationId).set({
        'type': type,
        'postId': animalId,
        'postOwnerId': animalOwnerId,
        'userId': userId,
        'userName': userName,
        'notificationText': notificationText,
        'date': DateTime.now()
      });
      res = 'success';
    } catch (err) {
      res = err.toString();
    }
    return res;
  }

  // Hayvan ilanını rapor etme
  Future<void> reportAnimal(String uid, String animalId, String reason) async {
    try {
      await _firestore.collection('animal_reports').add({
        'reporterId': uid,
        'animalId': animalId,
        'reason': reason,
        'timestamp': DateTime.now(),
      });
    } catch (e) {
      print(e.toString());
    }
  }

  // Hayvan ilanını gizleme
  Future<void> hideAnimal(String uid, String animalId) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'hiddenAnimals': FieldValue.arrayUnion([animalId])
      });
    } catch (e) {
      print(e.toString());
    }
  }
}

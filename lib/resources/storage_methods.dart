import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';

class StorageMethods {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // adding image to firebase storage
  Future<String> uploadImageToStorage(
      String childName, Uint8List file, bool isPost) async {
    // creating location to our firebase storage
    try {
      Reference ref =
          _storage.ref().child(childName).child(_auth.currentUser!.uid);
      if (isPost) {
        String id = const Uuid().v1();
        ref = ref.child(id);
      }

      // Web ve mobil için farklı metadata ayarları
      SettableMetadata metadata;
      if (kIsWeb) {
        // Web için gerekli metadata
        metadata = SettableMetadata(
          contentType: 'image/jpeg', // Varsayılan olarak JPEG formatı
          customMetadata: {'uploaded-from': 'web'},
        );
      } else {
        // Mobil için metadata
        metadata = SettableMetadata(
          contentType: 'image/jpeg',
        );
      }

      // Upload işlemi
      UploadTask uploadTask = ref.putData(file, metadata);

      // Upload tamamlanana kadar bekle
      TaskSnapshot snapshot = await uploadTask;

      // Download URL'sini al
      String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('Error uploading image: $e');
      throw Exception('Failed to upload image: $e');
    }
  }
}

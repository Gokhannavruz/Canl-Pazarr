import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';

// for picking up image from gallery or camera - web compatible
Future<Uint8List?> pickImage(ImageSource source) async {
  final ImagePicker imagePicker = ImagePicker();
  XFile? file;

  try {
    if (kIsWeb && source == ImageSource.camera) {
      // Web'de kamera ile fotoğraf çekme doğrudan desteklenmediğinden
      // kullanıcıya uyarı gösterelim ve galeri seçeneğine yönlendirelim
      print(
          'Camera is not directly supported on web. Using gallery picker instead.');
      file = await imagePicker.pickImage(source: ImageSource.gallery);
    } else {
      file = await imagePicker.pickImage(source: source);
    }

    if (file != null) {
      return await file.readAsBytes();
    }
  } catch (e) {
    print('Error picking image: $e');
  }

  print('No Image Selected');
  return null;
}

// Basit sıkıştırma fonksiyonu - web için bypass
Future<Uint8List> compressImage(Uint8List imageBytes) async {
  // Web için basit bir çözüm: orijinal resmi döndür
  // İleride daha gelişmiş web sıkıştırma yöntemleri eklenebilir
  return imageBytes;
}

// for displaying snackbars
void showSnackBar(BuildContext? context, String text) {
  if (context == null) return;

  // Try/catch to handle cases where the scaffold messenger might not be available
  try {
    // Check if there's a valid scaffold messenger and if it's mounted
    final scaffoldMessenger = ScaffoldMessenger.maybeOf(context);
    if (scaffoldMessenger != null) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(text),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  } catch (e) {
    // Silently ignore errors related to showing snackbars
    print('Error showing snackbar: $e');
  }
}

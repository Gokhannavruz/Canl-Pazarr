import 'package:flutter/material.dart';

class AnimalColors {
  // Ana renkler
  static const Color primary = Color(0xFF2E7D32); // Koyu yeşil (tarım)
  static const Color secondary = Color(0xFF8BC34A); // Açık yeşil
  static const Color accent = Color(0xFFFF9800); // Turuncu (fiyat)
  static const Color background = Color(0xFFF1F8E9); // Açık yeşil arka plan

  // Durum renkleri
  static const Color success = Color(0xFF4CAF50); // Başarı
  static const Color error = Color(0xFFD32F2F); // Hata
  static const Color warning = Color(0xFFFFA000); // Uyarı
  static const Color info = Color(0xFF2196F3); // Bilgi

  // Hayvan türü renkleri
  static const Color bigAnimal = Color(0xFF6D4C41); // Büyükbaş (kahverengi)
  static const Color smallAnimal = Color(0xFF9E9E9E); // Küçükbaş (gri)
  static const Color urgent = Color(0xFFE91E63); // Acil satış
  static const Color pregnant = Color(0xFFE1BEE7); // Gebe
  static const Color young = Color(0xFFBBDEFB); // Genç
  static const Color breeding = Color(0xFFF8BBD9); // Damızlık

  // Ek renkler
  static const Color healthyGreen = Color(0xFF66BB6A); // Sağlıklı
  static const Color sickRed = Color(0xFFEF5350); // Hasta
  static const Color vaccinated = Color(0xFF42A5F5); // Aşılı
  static const Color negotiable = Color(0xFFFFB74D); // Pazarlık yapılabilir

  // Metin renkleri
  static const Color textPrimary = Color(0xFF212121); // Ana metin rengi
  static const Color textSecondary = Color(0xFF757575); // İkincil metin rengi
  static const Color dividerColor = Color(0xFFE0E0E0); // Ayırıcı çizgi rengi

  // Gradient renkler
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, secondary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient priceGradient = LinearGradient(
    colors: [accent, Colors.deepOrange],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient healthGradient = LinearGradient(
    colors: [success, healthyGreen],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Hayvan türüne göre renk döndürme
  static Color getAnimalTypeColor(String animalType) {
    switch (animalType.toLowerCase()) {
      case 'büyükbaş':
        return bigAnimal;
      case 'küçükbaş':
        return smallAnimal;
      default:
        return primary;
    }
  }

  // Sağlık durumuna göre renk döndürme
  static Color getHealthStatusColor(String healthStatus) {
    switch (healthStatus.toLowerCase()) {
      case 'sağlıklı':
        return healthyGreen;
      case 'aşılı':
        return vaccinated;
      case 'hasta':
        return sickRed;
      case 'tedavi gören':
        return warning;
      case 'karantinada':
        return error;
      default:
        return info;
    }
  }

  // Fiyat durumuna göre renk döndürme
  static Color getPriceColor(bool isNegotiable, bool isUrgent) {
    if (isUrgent) return urgent;
    if (isNegotiable) return negotiable;
    return accent;
  }

  // Özel durumlar için renk döndürme
  static Color getSpecialStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'gebe':
        return pregnant;
      case 'genç':
        return young;
      case 'damızlık':
        return breeding;
      case 'acil satış':
        return urgent;
      default:
        return primary;
    }
  }

  // Tema renkleri
  static ThemeData getAnimalTheme() {
    return ThemeData(
      primarySwatch: Colors.green,
      primaryColor: primary,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        primary: primary,
        secondary: secondary,
        background: background,
        surface: background,
      ),
      scaffoldBackgroundColor: background,
      appBarTheme: AppBarTheme(
        backgroundColor: primary,
        foregroundColor: Colors.white,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: accent,
        foregroundColor: Colors.white,
      ),
      cardTheme: CardTheme(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: primary, width: 2),
        ),
      ),
    );
  }
}

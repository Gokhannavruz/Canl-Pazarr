import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// PostCard bileşeni için text stilleri.
/// Google Fonts kullanarak daha modern bir görünüm sağlar.
class PostCardTextStyles {
  // Kullanıcı adı stili
  static TextStyle username = GoogleFonts.poppins(
    color: Colors.white,
    fontSize: 15,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.2,
  );

  // Konum metni stili
  static TextStyle location = GoogleFonts.poppins(
    color: Colors.grey.shade400,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.1,
  );

  // Post açıklama stili
  static TextStyle description = GoogleFonts.poppins(
    color: Colors.white.withOpacity(0.9),
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.4,
  );

  // Hata mesajları stili
  static TextStyle errorMessage = GoogleFonts.poppins(
    color: Colors.white,
    fontSize: 14,
    fontWeight: FontWeight.w500,
  );

  // Kredi gösterimi stili
  static TextStyle creditBadge = GoogleFonts.poppins(
    color: Colors.white,
    fontWeight: FontWeight.w600,
    fontSize: 12,
  );

  // Wanted badgeleri için stil
  static TextStyle wantedBadge = GoogleFonts.poppins(
    color: Colors.white,
    fontWeight: FontWeight.w600,
    fontSize: 12,
  );

  // Premium bilgi başlığı
  static TextStyle premiumInfoTitle = GoogleFonts.poppins(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: Colors.white,
  );

  // Premium bilgi açıklaması
  static TextStyle premiumInfoDescription = GoogleFonts.poppins(
    fontSize: 14,
    color: Colors.white.withOpacity(0.8),
    height: 1.4,
  );

  // İletişim butonu ve diğer etkileşimli butonlar
  static TextStyle actionButton = GoogleFonts.poppins(
    color: Colors.white,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.3,
  );

  // Dialog başlık stili
  static TextStyle dialogTitle = GoogleFonts.poppins(
    color: Colors.white,
    fontSize: 18,
    fontWeight: FontWeight.bold,
  );

  // Dialog içerik stili
  static TextStyle dialogContent = GoogleFonts.poppins(
    color: Colors.white.withOpacity(0.8),
    fontSize: 14,
    height: 1.5,
  );

  // Menü öğesi başlık stili
  static TextStyle menuItemTitle = GoogleFonts.poppins(
    color: Colors.white,
    fontSize: 15,
    fontWeight: FontWeight.w500,
  );

  // Dialog buton metni (Olumlu aksiyon)
  static TextStyle dialogPositiveButton = GoogleFonts.poppins(
    color: Colors.blue,
    fontWeight: FontWeight.bold,
  );

  // Dialog buton metni (Olumsuz / Uyarı aksiyon)
  static TextStyle dialogNegativeButton = GoogleFonts.poppins(
    color: Colors.red,
    fontWeight: FontWeight.bold,
  );

  // Dialog buton metni (Nötr aksiyon)
  static TextStyle dialogNeutralButton = GoogleFonts.poppins(
    color: Colors.white70,
    fontWeight: FontWeight.w500,
  );
}

/// Tasarım için ilgili sabitler
class PostCardDesign {
  // Renkler
  static Color premiumGreen = const Color(0xFF36B37E);
  static Color itemBadgeColor = Colors.green.shade600;
  static Color dialogBackground = Colors.black;
  static Color menuItemBackgroundHover = Colors.grey[800]!;
  static Color menuItemBackground = Colors.grey[900]!;
  static Color deleteActionColor = Colors.red.shade800;
  static Color deleteActionBackgroundColor = Colors.red.withOpacity(0.1);

  // Kenar yuvarlaklıkları
  static BorderRadius badgeRadius = BorderRadius.circular(20);
  static BorderRadius cardRadius = BorderRadius.circular(16);
  static BorderRadius dialogRadius = BorderRadius.circular(16);
  static BorderRadius menuRadius = const BorderRadius.vertical(
    top: Radius.circular(20),
  );
  static BorderRadius buttonRadius = BorderRadius.circular(8);

  // Gölge efektleri
  static List<BoxShadow> badgeShadow = [
    BoxShadow(
      color: Colors.black.withOpacity(0.2),
      blurRadius: 4,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> dialogShadow = [
    BoxShadow(
      color: Colors.black.withOpacity(0.2),
      blurRadius: 10,
      spreadRadius: 1,
    ),
  ];

  // Padding değerleri
  static EdgeInsets dialogPadding = const EdgeInsets.fromLTRB(24, 12, 24, 16);
  static EdgeInsets dialogTitlePadding = const EdgeInsets.only(bottom: 12);
  static EdgeInsets dialogContentPadding =
      const EdgeInsets.symmetric(vertical: 8);
  static EdgeInsets dialogActionsPadding = const EdgeInsets.only(top: 16);
  static EdgeInsets menuItemPadding =
      const EdgeInsets.symmetric(horizontal: 16, vertical: 14);
}

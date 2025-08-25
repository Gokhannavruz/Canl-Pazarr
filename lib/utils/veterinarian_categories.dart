import 'package:flutter/material.dart';

class VeterinarianCategories {
  static const List<String> categories = [
    'Tüm Veterinerler',
    'Büyükbaş Uzmanı',
    'Küçükbaş Uzmanı',
    'Süt Sığırı Uzmanı',
    'Et Sığırı Uzmanı',
    'Damızlık Uzmanı',
    'Sürü Sağlığı',
    'Üreme Hekimliği',
    'Cerrahi',
    'İç Hastalıkları',
    'Dış Hastalıkları',
    'Laboratuvar',
    'Radyoloji',
    'Ultrasonografi',
    'Acil Hizmet',
    'Ev Ziyareti',
    'Çiftlik Ziyareti',
    'Doğum Yardımı',
    'Suni Tohumlama',
    'Gebelik Teşhisi',
    'Aşı Uygulaması',
    'Parazit Tedavisi',
    'Beslenme Danışmanlığı',
    'Sertifika Düzenleme',
  ];

  static const Map<String, IconData> categoryIcons = {
    'Tüm Veterinerler': Icons.local_hospital,
    'Büyükbaş Uzmanı': Icons.pets,
    'Küçükbaş Uzmanı': Icons.pets,
    'Süt Sığırı Uzmanı': Icons.local_drink,
    'Et Sığırı Uzmanı': Icons.restaurant,
    'Damızlık Uzmanı': Icons.favorite,
    'Sürü Sağlığı': Icons.health_and_safety,
    'Üreme Hekimliği': Icons.family_restroom,
    'Cerrahi': Icons.medical_services,
    'İç Hastalıkları': Icons.healing,
    'Dış Hastalıkları': Icons.medical_information,
    'Laboratuvar': Icons.science,
    'Radyoloji': Icons.medical_services,
    'Ultrasonografi': Icons.medical_services,
    'Acil Hizmet': Icons.emergency,
    'Ev Ziyareti': Icons.home,
    'Çiftlik Ziyareti': Icons.agriculture,
    'Doğum Yardımı': Icons.child_care,
    'Suni Tohumlama': Icons.favorite,
    'Gebelik Teşhisi': Icons.pregnant_woman,
    'Aşı Uygulaması': Icons.medical_services,
    'Parazit Tedavisi': Icons.bug_report,
    'Beslenme Danışmanlığı': Icons.restaurant_menu,
    'Sertifika Düzenleme': Icons.description,
  };

  static const Map<String, Color> categoryColors = {
    'Tüm Veterinerler': Color(0xFF2E7D32),
    'Büyükbaş Uzmanı': Color(0xFF6D4C41),
    'Küçükbaş Uzmanı': Color(0xFF9E9E9E),
    'Süt Sığırı Uzmanı': Color(0xFF2196F3),
    'Et Sığırı Uzmanı': Color(0xFFE53935),
    'Damızlık Uzmanı': Color(0xFFE91E63),
    'Sürü Sağlığı': Color(0xFF4CAF50),
    'Üreme Hekimliği': Color(0xFF9C27B0),
    'Cerrahi': Color(0xFFFF5722),
    'İç Hastalıkları': Color(0xFF607D8B),
    'Dış Hastalıkları': Color(0xFF795548),
    'Laboratuvar': Color(0xFF3F51B5),
    'Radyoloji': Color(0xFF009688),
    'Ultrasonografi': Color(0xFF00BCD4),
    'Acil Hizmet': Color(0xFFFF9800),
    'Ev Ziyareti': Color(0xFF8BC34A),
    'Çiftlik Ziyareti': Color(0xFF795548),
    'Doğum Yardımı': Color(0xFFE1BEE7),
    'Suni Tohumlama': Color(0xFFF8BBD9),
    'Gebelik Teşhisi': Color(0xFFE1BEE7),
    'Aşı Uygulaması': Color(0xFFBBDEFB),
    'Parazit Tedavisi': Color(0xFFC8E6C9),
    'Beslenme Danışmanlığı': Color(0xFFFFCC02),
    'Sertifika Düzenleme': Color(0xFFD7CCC8),
  };

  static const List<String> specializations = [
    'Büyükbaş Hayvan Hekimliği',
    'Küçükbaş Hayvan Hekimliği',
    'Süt Sığırı Hekimliği',
    'Et Sığırı Hekimliği',
    'Damızlık Hayvan Hekimliği',
    'Sürü Sağlığı',
    'Üreme Hekimliği',
    'Cerrahi',
    'İç Hastalıkları',
    'Dış Hastalıkları',
    'Mikrobiyoloji',
    'Parazitoloji',
    'Farmakoloji',
    'Beslenme',
    'Zoonoz Hastalıklar',
    'Aşı ve İmmunoloji',
    'Laboratuvar Teşhis',
    'Radyoloji',
    'Ultrasonografi',
    'Patoloji',
    'Toksikoloji',
    'Halk Sağlığı',
    'Gıda Güvenliği',
    'Çevre Sağlığı',
  ];

  static const List<String> services = [
    'Genel Muayene',
    'Aşı Uygulaması',
    'Cerrahi Müdahale',
    'Doğum Yardımı',
    'Suni Tohumlama',
    'Gebelik Teşhisi',
    'Soy Kütüğü Belgesi',
    'Sağlık Raporu',
    'Kan Tahlili',
    'Dışkı Tahlili',
    'İdrar Tahlili',
    'Radyografi (X-Ray)',
    'Ultrasonografi',
    'Mikroskopik İnceleme',
    'Parazit Tedavisi',
    'Antibiyotik Tedavisi',
    'Vitamin Takviyesi',
    'Beslenme Danışmanlığı',
    'Sürü Sağlığı Planı',
    'Acil Müdahale',
    'Ev Ziyareti',
    'Çiftlik Ziyareti',
    'Eğitim ve Danışmanlık',
    'Sertifika Düzenleme',
    'İlaç Reçetesi',
    'Kontrol Muayenesi',
  ];

  static const List<String> animalTypes = [
    'Sığır',
    'Koyun',
    'Keçi',
    'Manda',
    'At',
    'Eşek',
    'Tavuk',
    'Hindi',
    'Ördek',
    'Kaz',
    'Domuz',
    'Tavşan',
    'Köpek',
    'Kedi',
    'Kümes Hayvanları',
    'Arı',
    'Balık',
    'Diğer',
  ];

  static const List<String> turkishCities = [
    'Adana',
    'Adıyaman',
    'Afyonkarahisar',
    'Ağrı',
    'Aksaray',
    'Amasya',
    'Ankara',
    'Antalya',
    'Ardahan',
    'Artvin',
    'Aydın',
    'Balıkesir',
    'Bartın',
    'Batman',
    'Bayburt',
    'Bilecik',
    'Bingöl',
    'Bitlis',
    'Bolu',
    'Burdur',
    'Bursa',
    'Çanakkale',
    'Çankırı',
    'Çorum',
    'Denizli',
    'Diyarbakır',
    'Düzce',
    'Edirne',
    'Elazığ',
    'Erzincan',
    'Erzurum',
    'Eskişehir',
    'Gaziantep',
    'Giresun',
    'Gümüşhane',
    'Hakkari',
    'Hatay',
    'Iğdır',
    'Isparta',
    'İstanbul',
    'İzmir',
    'Kahramanmaraş',
    'Karabük',
    'Karaman',
    'Kars',
    'Kastamonu',
    'Kayseri',
    'Kırıkkale',
    'Kırklareli',
    'Kırşehir',
    'Kilis',
    'Kocaeli',
    'Konya',
    'Kütahya',
    'Malatya',
    'Manisa',
    'Mardin',
    'Mersin',
    'Muğla',
    'Muş',
    'Nevşehir',
    'Niğde',
    'Ordu',
    'Osmaniye',
    'Rize',
    'Sakarya',
    'Samsun',
    'Şanlıurfa',
    'Siirt',
    'Sinop',
    'Şırnak',
    'Sivas',
    'Tekirdağ',
    'Tokat',
    'Trabzon',
    'Tunceli',
    'Uşak',
    'Van',
    'Yalova',
    'Yozgat',
    'Zonguldak',
  ];

  static IconData getCategoryIcon(String category) {
    return categoryIcons[category] ?? Icons.local_hospital;
  }

  static Color getCategoryColor(String category) {
    return categoryColors[category] ?? const Color(0xFF2E7D32);
  }

  static bool matchesCategory(
      String category, List<String> specializations, List<String> services) {
    switch (category) {
      case 'Büyükbaş Uzmanı':
        return specializations
            .any((spec) => spec.toLowerCase().contains('büyükbaş'));
      case 'Küçükbaş Uzmanı':
        return specializations
            .any((spec) => spec.toLowerCase().contains('küçükbaş'));
      case 'Süt Sığırı Uzmanı':
        return specializations
            .any((spec) => spec.toLowerCase().contains('süt sığırı'));
      case 'Et Sığırı Uzmanı':
        return specializations
            .any((spec) => spec.toLowerCase().contains('et sığırı'));
      case 'Damızlık Uzmanı':
        return specializations
            .any((spec) => spec.toLowerCase().contains('damızlık'));
      case 'Sürü Sağlığı':
        return specializations
            .any((spec) => spec.toLowerCase().contains('sürü sağlığı'));
      case 'Üreme Hekimliği':
        return specializations
            .any((spec) => spec.toLowerCase().contains('üreme'));
      case 'Cerrahi':
        return specializations
            .any((spec) => spec.toLowerCase().contains('cerrahi'));
      case 'İç Hastalıkları':
        return specializations
            .any((spec) => spec.toLowerCase().contains('iç hastalıkları'));
      case 'Dış Hastalıkları':
        return specializations
            .any((spec) => spec.toLowerCase().contains('dış hastalıkları'));
      case 'Laboratuvar':
        return specializations
            .any((spec) => spec.toLowerCase().contains('laboratuvar'));
      case 'Radyoloji':
        return specializations
            .any((spec) => spec.toLowerCase().contains('radyoloji'));
      case 'Ultrasonografi':
        return specializations
            .any((spec) => spec.toLowerCase().contains('ultrasonografi'));
      case 'Acil Hizmet':
        return true; // Bu özellik ayrı bir alan olarak tutuluyor
      case 'Ev Ziyareti':
        return true; // Bu özellik ayrı bir alan olarak tutuluyor
      case 'Çiftlik Ziyareti':
        return services
            .any((service) => service.toLowerCase().contains('çiftlik'));
      case 'Doğum Yardımı':
        return services
            .any((service) => service.toLowerCase().contains('doğum'));
      case 'Suni Tohumlama':
        return services
            .any((service) => service.toLowerCase().contains('suni tohumlama'));
      case 'Gebelik Teşhisi':
        return services
            .any((service) => service.toLowerCase().contains('gebelik'));
      case 'Aşı Uygulaması':
        return services.any((service) => service.toLowerCase().contains('aşı'));
      case 'Parazit Tedavisi':
        return services
            .any((service) => service.toLowerCase().contains('parazit'));
      case 'Beslenme Danışmanlığı':
        return services
            .any((service) => service.toLowerCase().contains('beslenme'));
      case 'Sertifika Düzenleme':
        return services
            .any((service) => service.toLowerCase().contains('sertifika'));
      default:
        return true;
    }
  }
}

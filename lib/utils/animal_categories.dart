import 'package:flutter/material.dart';

class AnimalCategories {
  static const List<String> categories = [
    'Tüm Hayvanlar',

    // Büyükbaş Kategoriler
    'Süt Sığırı',
    'Et Sığırı',
    'Damızlık Boğa',
    'Düve',
    'Manda',
    'Tosun',

    // Küçükbaş Kategoriler
    'Koyun',
    'Keçi',
    'Kuzu',
    'Oğlak',
    'Koç',
    'Teke',
    'Kurbanlık',

    // Kanatlı ve Adaklık
    'Kanatlı',
    'Adaklık Hayvanlar',

    // Özel Kategoriler
    'Gebe Hayvanlar',
    'Genç Hayvanlar',
    'Damızlık Hayvanlar',
    'Acil Satış',
    'Süt Veren',
    'Et İçin',
    'Organik Beslenmiş',
  ];

  static const Map<String, IconData> categoryIcons = {
    'Süt Sığırı': Icons.local_drink,
    'Et Sığırı': Icons.restaurant,
    'Damızlık Boğa': Icons.pets,
    'Düve': Icons.pets,
    'Manda': Icons.pets,
    'Tosun': Icons.pets,
    'Koyun': Icons.pets,
    'Keçi': Icons.pets,
    'Kuzu': Icons.child_care,
    'Oğlak': Icons.child_care,
    'Koç': Icons.pets,
    'Teke': Icons.pets,
    'Kurbanlık': Icons.favorite,
    'Kanatlı': Icons.egg,
    'Adaklık Hayvanlar': Icons.volunteer_activism,
    'Gebe Hayvanlar': Icons.pregnant_woman,
    'Genç Hayvanlar': Icons.child_care,
    'Damızlık Hayvanlar': Icons.favorite,
    'Acil Satış': Icons.flash_on,
    'Süt Veren': Icons.local_drink,
    'Et İçin': Icons.restaurant,
    'Organik Beslenmiş': Icons.eco,
  };

  static const Map<String, Color> categoryColors = {
    'Süt Sığırı': Colors.blue,
    'Et Sığırı': Colors.red,
    'Damızlık Boğa': Colors.purple,
    'Düve': Colors.pink,
    'Manda': Colors.brown,
    'Tosun': Colors.orange,
    'Koyun': Colors.grey,
    'Keçi': Colors.green,
    'Kuzu': Colors.lightBlue,
    'Oğlak': Colors.lightGreen,
    'Koç': Colors.blueGrey,
    'Teke': Colors.teal,
    'Kurbanlık': Colors.red,
    'Kanatlı': Colors.amber,
    'Adaklık Hayvanlar': Colors.deepOrange,
    'Gebe Hayvanlar': Colors.purple,
    'Genç Hayvanlar': Colors.lightBlue,
    'Damızlık Hayvanlar': Colors.pink,
    'Acil Satış': Colors.red,
    'Süt Veren': Colors.blue,
    'Et İçin': Colors.red,
    'Organik Beslenmiş': Colors.green,
  };

  static const List<String> animalTypes = [
    'büyükbaş',
    'küçükbaş',
    'kanatlı',
  ];

  static const List<String> animalSpecies = [
    'Sığır',
    'Koyun',
    'Keçi',
    'Manda',
    // Kanatlı türleri
    'Tavuk',
    'Hindi',
    'Kaz',
    'Ördek',
    'Bıldırcın',
    'Güvercin',
  ];

  static const List<String> animalBreeds = [
    // Sığır ırkları
    'Holstein',
    'Angus',
    'Simmental',
    'Jersey',
    'Charolais',
    'Limousin',
    'Hereford',
    'Montofon',
    'Boz Irk',
    'Yerli Kara',

    // Koyun ırkları
    'Merinos',
    'Akkaraman',
    'Morkaraman',
    'Kıvırcık',
    'Karakul',
    'İvesi',
    'Dağlıç',
    'Kangal',
    'Hemşin',
    'Çine Çapari',

    // Keçi ırkları
    'Saanen',
    'Kıl Keçisi',
    'Angora',
    'Kilis',
    'Malta',
    'Halep',
    'Norduz',
    'Honamli',
    'Gökçeada',
    'Çanakkale',

    // Manda ırkları
    'Anadolu Mandası',
    'Karabük Mandası',
    'Afyon Mandası',
    'Murrah',
    'Nili Ravi',

    // Kanatlı ırkları
    'Ligorin',
    'Ataks',
    'Brahma',
    'Plymouth Rock',
    'Rhode Island',
    'Sussex',
    'Ameraucana',
    'Sasso',
    'Melez',
    'Beyaz Hindi',
    'Bronz Hindi',
    'Pekin Ördeği',
    'Rouen',
    'Toulouse',
    'Çin Kazı',
    'Macar Kazı',
    'Jumbo Bıldırcın',
    'Japon Bıldırcın',
    'Posta Güvercini',
    'Taklacı',
    'Miro',
  ];

  static const List<String> healthStatuses = [
    'Sağlıklı',
    'Aşılı',
    'Hasta',
    'Tedavi Gören',
    'Karantinada',
    'Veteriner Kontrolü Gerekli',
  ];

  static const List<String> vaccineTypes = [
    'Şap',
    'Brucella',
    'Tuberculin',
    'Antraks',
    'Enterotoksemi',
    'Bluetongue',
    'Tetanos',
    'Viral Diyare',
    'Rhinotracheitis',
    'Parainfluenza',
    'RSV',
    'Pasteurella',
    'Salmonella',
    'E. Coli',
    'Rotavirus',
    'Coronavirus',
  ];

  static const List<String> purposes = [
    'Süt',
    'Et',
    'Damızlık',
    'Yün',
    'Yapağı',
    'Tiftik',
    'Kıl',
    'Deri',
    'Gübre',
    'Çift Gücü',
    'Hobi',
    'Çiftlik Süsü',
    'Adaklık',
  ];

  static const List<String> sellerTypes = [
    'Bireysel',
    'Çiftlik',
    'Kooperatif',
    'Tarım İşletmesi',
    'Hayvancılık Şirketi',
    'Veteriner Hekim',
    'Ziraat Mühendisi',
    'Gıda Mühendisi',
    'Hayvan Bakım Uzmanı',
  ];

  static const List<String> genders = [
    'Erkek',
    'Dişi',
  ];

  static const List<String> farmTypes = [
    'Süt Çiftliği',
    'Et Çiftliği',
    'Damızlık Çiftliği',
    'Organik Çiftlik',
    'Entegre Çiftlik',
    'Hobi Çiftliği',
    'Aile Çiftliği',
    'Ticari Çiftlik',
    'Kooperatif Çiftlik',
    'Devlet Çiftliği',
  ];

  static IconData getCategoryIcon(String category) {
    return categoryIcons[category] ?? Icons.pets;
  }

  static Color getCategoryColor(String category) {
    return categoryColors[category] ?? Colors.grey;
  }

  static bool isBigAnimal(String animalType) {
    return animalType.toLowerCase() == 'büyükbaş';
  }

  static bool isSmallAnimal(String animalType) {
    return animalType.toLowerCase() == 'küçükbaş';
  }

  static List<String> getSpeciesForType(String animalType) {
    if (isBigAnimal(animalType)) {
      return ['Sığır', 'Manda'];
    } else if (isSmallAnimal(animalType)) {
      return ['Koyun', 'Keçi'];
    } else if (animalType.toLowerCase() == 'kanatlı') {
      return ['Tavuk', 'Hindi', 'Kaz', 'Ördek', 'Bıldırcın', 'Güvercin'];
    }
    return animalSpecies;
  }

  static List<String> getBreedsForSpecies(String species) {
    switch (species.toLowerCase()) {
      case 'sığır':
        return animalBreeds
            .where((breed) => [
                  'Holstein',
                  'Angus',
                  'Simmental',
                  'Jersey',
                  'Charolais',
                  'Limousin',
                  'Hereford',
                  'Montofon',
                  'Boz Irk',
                  'Yerli Kara'
                ].contains(breed))
            .toList();
      case 'koyun':
        return animalBreeds
            .where((breed) => [
                  'Merinos',
                  'Akkaraman',
                  'Morkaraman',
                  'Kıvırcık',
                  'Karakul',
                  'İvesi',
                  'Dağlıç',
                  'Kangal',
                  'Hemşin',
                  'Çine Çapari'
                ].contains(breed))
            .toList();
      case 'keçi':
        return animalBreeds
            .where((breed) => [
                  'Saanen',
                  'Kıl Keçisi',
                  'Angora',
                  'Kilis',
                  'Malta',
                  'Halep',
                  'Norduz',
                  'Honamli',
                  'Gökçeada',
                  'Çanakkale'
                ].contains(breed))
            .toList();
      case 'manda':
        return animalBreeds
            .where((breed) => [
                  'Anadolu Mandası',
                  'Karabük Mandası',
                  'Afyon Mandası',
                  'Murrah',
                  'Nili Ravi'
                ].contains(breed))
            .toList();
      case 'tavuk':
        return [
          'Ligorin',
          'Ataks',
          'Brahma',
          'Plymouth Rock',
          'Rhode Island',
          'Sussex',
          'Ameraucana',
          'Sasso',
          'Melez',
        ];
      case 'hindi':
        return [
          'Beyaz Hindi',
          'Bronz Hindi',
        ];
      case 'kaz':
        return [
          'Çin Kazı',
          'Macar Kazı',
        ];
      case 'ördek':
        return [
          'Pekin Ördeği',
          'Rouen',
          'Toulouse',
        ];
      case 'bıldırcın':
        return [
          'Jumbo Bıldırcın',
          'Japon Bıldırcın',
        ];
      case 'güvercin':
        return [
          'Posta Güvercini',
          'Taklacı',
          'Miro',
        ];
      default:
        return animalBreeds;
    }
  }
}

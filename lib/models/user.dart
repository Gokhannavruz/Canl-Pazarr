import 'package:cloud_firestore/cloud_firestore.dart';

class User {
  final String? email;
  final String? uid;
  String? photoUrl;
  String? username;
  final String? bio;
  final List<dynamic>? followers;
  final List<dynamic>? following;
  final List<dynamic>? blocked;
  final List<dynamic>? blockedBy;
  String? matchedWith;
  String? country;
  String? state;
  String? city;
  String? neighborhood;
  String? district;
  double? latitude;
  double? longitude;
  int? numberOfSentGifts;
  int? numberOfUnsentGifts;
  String? giftSendingRate;
  double? giftPoint;
  int? matchCount;
  int? rateCount;
  bool? isRated;
  bool? isPremium;
  bool? isVerified;
  bool? isConfirmed;
  int? credit;
  String? fcmToken;
  String? referralCode;
  String? referredBy;
  double? averageRating;
  int? totalRatings;
  int? totalSales;

  // Çiftçi/Satıcı bilgileri
  String? farmerType; // "Bireysel", "Çiftlik", "Kooperatif", "Ticari"
  String? workingHours; // "09:00-18:00"
  String? transportAvailable; // "Mevcut", "Mevcut değil", "Ücreti karşılığında"
  int? experienceYears; // Deneyim yılı
  String? phoneNumber; // İletişim telefonu
  List<String>? specializations; // ["Süt sığırı", "Et sığırı", "Küçükbaş"]
  String? farmAddress; // Detaylı çiftlik adresi
  String? farmSize; // "Küçük", "Orta", "Büyük"
  bool? hasVeterinarySupport; // Veteriner desteği var mı
  bool? hasHealthCertificate; // Sağlık belgesi var mı
  Map<String, int>? animalCounts; // {"Süt Sığırı": 5, "Koyun": 12, "Keçi": 3}
  List<String>? certifications; // ["Organik", "Helal", "ISO"] vb.

  // Nakliyeci/Transporter bilgileri
  bool? isTransporter; // Kullanıcı nakliyeci mi?
  String? transporterCompanyName;
  String? transporterPhone;
  List<String>? transporterCities; // Hangi şehirlere gidiyor
  double? transporterMaxDistanceKm; // Maksimum mesafe (km)
  double? transporterPricePerKm; // Km başına ücret
  int? transporterMaxAnimals; // En fazla kaç hayvan taşıyabilir
  String? transporterVehicleType; // Araç tipi
  String? transporterVehiclePlate; // Plaka
  bool? transporterAvailable; // Şu an müsait mi
  String? transporterDescription; // Açıklama
  double? transporterRating; // Ortalama puan
  int? transporterTotalTransports; // Toplam taşıma
  List<String>? transporterDocuments; // Belgeler (URL)
  bool? transporterInsurance; // Sigorta var mı
  int? transporterYearsExperience; // Deneyim yılı
  String? transporterWorkingHours; // Çalışma saatleri
  List<String>? transporterPhotoUrls; // Araç/firma fotoğrafları
  bool? transporterVerified; // Doğrulanmış nakliyeci mi
  List<String>? transporterLanguages; // Konuşulan diller
  double? transporterMinPrice; // Minimum taşıma ücreti
  double? transporterMaxPrice; // Maksimum taşıma ücreti
  List<String>? transporterRegions; // Bölge bazlı hizmet
  List<String>? transporterAnimalTypes; // Taşıdığı hayvan türleri
  Map<String, dynamic>? transporterCapacityDetails; // Detaylı kapasite
  String? transporterNotes; // Notlar

  User({
    this.username,
    this.uid,
    this.photoUrl,
    this.email,
    this.bio,
    this.followers,
    this.following,
    this.blocked,
    this.blockedBy,
    this.matchedWith,
    this.country,
    this.state,
    this.city,
    this.neighborhood,
    this.district,
    this.latitude,
    this.longitude,
    this.matchCount,
    this.isPremium,
    this.numberOfSentGifts,
    this.numberOfUnsentGifts,
    this.giftSendingRate,
    this.isVerified,
    this.isConfirmed,
    this.giftPoint,
    this.isRated,
    this.rateCount,
    this.fcmToken,
    this.credit,
    this.referralCode,
    this.referredBy,
    this.averageRating,
    this.totalRatings,
    this.totalSales,
    this.farmerType,
    this.workingHours,
    this.transportAvailable,
    this.experienceYears,
    this.phoneNumber,
    this.specializations,
    this.farmAddress,
    this.farmSize,
    this.hasVeterinarySupport,
    this.hasHealthCertificate,
    this.animalCounts,
    this.certifications,
    this.isTransporter,
    this.transporterCompanyName,
    this.transporterPhone,
    this.transporterCities,
    this.transporterMaxDistanceKm,
    this.transporterPricePerKm,
    this.transporterMaxAnimals,
    this.transporterVehicleType,
    this.transporterVehiclePlate,
    this.transporterAvailable,
    this.transporterDescription,
    this.transporterRating,
    this.transporterTotalTransports,
    this.transporterDocuments,
    this.transporterInsurance,
    this.transporterYearsExperience,
    this.transporterWorkingHours,
    this.transporterPhotoUrls,
    this.transporterVerified,
    this.transporterLanguages,
    this.transporterMinPrice,
    this.transporterMaxPrice,
    this.transporterRegions,
    this.transporterAnimalTypes,
    this.transporterCapacityDetails,
    this.transporterNotes,
  });

  List<dynamic>? get blockedUsers => blocked ?? [];

  static User fromSnap(DocumentSnapshot snap) {
    try {
      var snapshot = snap.data() as Map<String, dynamic>? ?? {};

      return User(
        username: _safeGetString(snapshot, 'username'),
        uid: _safeGetString(snapshot, 'uid'),
        email: _safeGetString(snapshot, 'email'),
        photoUrl: _safeGetString(snapshot, 'photoUrl'),
        bio: _safeGetString(snapshot, 'bio'),
        followers: _convertToList(snapshot['followers']),
        following: _convertToList(snapshot['following']),
        blocked: _convertToList(snapshot['blocked']),
        blockedBy: _convertToList(snapshot['blockedBy']),
        matchedWith: _safeGetString(snapshot, 'matched_with'),
        city: _safeGetString(snapshot, 'city'),
        country: _safeGetString(snapshot, 'country'),
        state: _safeGetString(snapshot, 'state'),
        neighborhood: _safeGetString(snapshot, 'neighborhood'),
        district: _safeGetString(snapshot, 'district'),
        latitude: _safeGetDouble(snapshot, 'latitude'),
        longitude: _safeGetDouble(snapshot, 'longitude'),
        matchCount: _safeGetInt(snapshot, 'match_count'),
        isPremium: _safeGetBool(snapshot, 'is_premium'),
        numberOfSentGifts: _safeGetInt(snapshot, 'number_of_sent_gifts'),
        numberOfUnsentGifts: _safeGetInt(snapshot, 'number_of_unsent_gifts'),
        giftSendingRate: _safeGetString(snapshot, 'gift_sending_rate'),
        isVerified: _safeGetBool(snapshot, 'isVerified'),
        isConfirmed: _safeGetBool(snapshot, 'isConfirmed'),
        giftPoint: _safeGetDouble(snapshot, 'gift_point'),
        isRated: _safeGetBool(snapshot, 'isRated'),
        rateCount: _safeGetInt(snapshot, 'rateCount'),
        fcmToken: _safeGetString(snapshot, 'fcmToken'),
        credit: _safeGetInt(snapshot, 'credit'),
        referralCode: _safeGetString(snapshot, 'referralCode'),
        referredBy: _safeGetString(snapshot, 'referredBy'),
        averageRating: _safeGetDouble(snapshot, 'averageRating'),
        totalRatings: _safeGetInt(snapshot, 'totalRatings'),
        totalSales: _safeGetInt(snapshot, 'totalSales'),
        farmerType: _safeGetString(snapshot, 'farmerType'),
        workingHours: _safeGetString(snapshot, 'workingHours'),
        transportAvailable: _safeGetString(snapshot, 'transportAvailable'),
        experienceYears: _safeGetInt(snapshot, 'experienceYears'),
        phoneNumber: _safeGetString(snapshot, 'phoneNumber'),
        specializations: _safeGetStringList(snapshot, 'specializations'),
        farmAddress: _safeGetString(snapshot, 'farmAddress'),
        farmSize: _safeGetString(snapshot, 'farmSize'),
        hasVeterinarySupport: _safeGetBool(snapshot, 'hasVeterinarySupport'),
        hasHealthCertificate: _safeGetBool(snapshot, 'hasHealthCertificate'),
        animalCounts: _safeGetStringIntMap(snapshot, 'animalCounts'),
        certifications: _safeGetStringList(snapshot, 'certifications'),
        isTransporter: _safeGetBool(snapshot, 'isTransporter'),
        transporterCompanyName:
            _safeGetString(snapshot, 'transporterCompanyName'),
        transporterPhone: _safeGetString(snapshot, 'transporterPhone'),
        transporterCities: _safeGetStringList(snapshot, 'transporterCities'),
        transporterMaxDistanceKm:
            _safeGetDouble(snapshot, 'transporterMaxDistanceKm'),
        transporterPricePerKm:
            _safeGetDouble(snapshot, 'transporterPricePerKm'),
        transporterMaxAnimals: _safeGetInt(snapshot, 'transporterMaxAnimals'),
        transporterVehicleType:
            _safeGetString(snapshot, 'transporterVehicleType'),
        transporterVehiclePlate:
            _safeGetString(snapshot, 'transporterVehiclePlate'),
        transporterAvailable: _safeGetBool(snapshot, 'transporterAvailable'),
        transporterDescription:
            _safeGetString(snapshot, 'transporterDescription'),
        transporterRating: _safeGetDouble(snapshot, 'transporterRating'),
        transporterTotalTransports:
            _safeGetInt(snapshot, 'transporterTotalTransports'),
        transporterDocuments:
            _safeGetStringList(snapshot, 'transporterDocuments'),
        transporterInsurance: _safeGetBool(snapshot, 'transporterInsurance'),
        transporterYearsExperience:
            _safeGetInt(snapshot, 'transporterYearsExperience'),
        transporterWorkingHours:
            _safeGetString(snapshot, 'transporterWorkingHours'),
        transporterPhotoUrls:
            _safeGetStringList(snapshot, 'transporterPhotoUrls'),
        transporterVerified: _safeGetBool(snapshot, 'transporterVerified'),
        transporterLanguages:
            _safeGetStringList(snapshot, 'transporterLanguages'),
        transporterMinPrice: _safeGetDouble(snapshot, 'transporterMinPrice'),
        transporterMaxPrice: _safeGetDouble(snapshot, 'transporterMaxPrice'),
        transporterRegions: _safeGetStringList(snapshot, 'transporterRegions'),
        transporterAnimalTypes:
            _safeGetStringList(snapshot, 'transporterAnimalTypes'),
        transporterCapacityDetails: snapshot['transporterCapacityDetails'],
        transporterNotes: _safeGetString(snapshot, 'transporterNotes'),
      );
    } catch (e) {
      print("Error in fromSnap: $e");
      // Return a minimal valid user on error
      return User(
        uid: snap.id,
        followers: [],
        following: [],
        blocked: [],
        blockedBy: [],
      );
    }
  }

  // Safe getters for different types
  static String? _safeGetString(Map<String, dynamic> map, String key) {
    try {
      final value = map[key];
      if (value is String) return value;
      if (value == null) return null;
      return value.toString();
    } catch (e) {
      print("Error converting to String for key $key: $e");
      return null;
    }
  }

  static int? _safeGetInt(Map<String, dynamic> map, String key) {
    try {
      final value = map[key];
      if (value is int) return value;
      if (value is num) return value.toInt();
      if (value is String && value.isNotEmpty) {
        return int.tryParse(value);
      }
      return null;
    } catch (e) {
      print("Error converting to int for key $key: $e");
      return null;
    }
  }

  static bool? _safeGetBool(Map<String, dynamic> map, String key) {
    try {
      final value = map[key];
      if (value is bool) return value;
      if (value is String) {
        if (value.toLowerCase() == 'true') return true;
        if (value.toLowerCase() == 'false') return false;
      }
      if (value is int) return value != 0;
      return null;
    } catch (e) {
      print("Error converting to bool for key $key: $e");
      return null;
    }
  }

  static double? _safeGetDouble(Map<String, dynamic> map, String key) {
    try {
      final value = map[key];
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is num) return value.toDouble();
      if (value is String && value.isNotEmpty) {
        return double.tryParse(value);
      }
      return null;
    } catch (e) {
      print("Error converting to double for key $key: $e");
      return null;
    }
  }

  static List<String>? _safeGetStringList(
      Map<String, dynamic> map, String key) {
    try {
      final value = map[key];
      if (value == null) return null;
      if (value is List) {
        return value.map((e) => e.toString()).toList();
      }
      if (value is String) {
        // Eğer virgülle ayrılmış string ise
        return value.split(',').map((e) => e.trim()).toList();
      }
      return null;
    } catch (e) {
      print("Error converting to List<String> for key $key: $e");
      return null;
    }
  }

  static Map<String, int>? _safeGetStringIntMap(
      Map<String, dynamic> map, String key) {
    try {
      final value = map[key];
      if (value == null) return null;
      if (value is Map) {
        Map<String, int> result = {};
        value.forEach((k, v) {
          if (k is String) {
            if (v is int) {
              result[k] = v;
            } else if (v is num) {
              result[k] = v.toInt();
            } else if (v is String) {
              final intValue = int.tryParse(v);
              if (intValue != null) {
                result[k] = intValue;
              }
            }
          }
        });
        return result;
      }
      return null;
    } catch (e) {
      print("Error converting to Map<String, int> for key $key: $e");
      return null;
    }
  }

  // Helper method to safely convert any value to List<dynamic>
  static List<dynamic>? _convertToList(dynamic value) {
    try {
      if (value == null) return [];
      if (value is List) return value;
      // If someone accidentally stored a single item instead of a list
      if (value is Map || value is String || value is num || value is bool) {
        return [value];
      }
      return [];
    } catch (e) {
      print("Error converting to List: $e");
      return [];
    }
  }

  Map<String, dynamic> toJson() {
    // Ensure all lists are properly initialized to avoid null issues
    final List<dynamic> safeFollowers = followers ?? [];
    final List<dynamic> safeFollowing = following ?? [];
    final List<dynamic> safeBlocked = blocked ?? [];
    final List<dynamic> safeBlockedBy = blockedBy ?? [];

    return {
      'username': username,
      'uid': uid,
      'email': email,
      'photoUrl': photoUrl,
      'bio': bio,
      'followers': safeFollowers,
      'following': safeFollowing,
      'blocked': safeBlocked,
      'blockedBy': safeBlockedBy,
      'matched_with': matchedWith,
      'country': country,
      'state': state,
      'city': city,
      'match_count': matchCount,
      'is_premium': isPremium,
      'number_of_sent_gifts': numberOfSentGifts,
      'number_of_unsent_gifts': numberOfUnsentGifts,
      'gift_sending_rate': giftSendingRate,
      'isVerified': isVerified,
      'isConfirmed': isConfirmed,
      'gift_point': giftPoint,
      'isRated': isRated,
      'rateCount': rateCount,
      'fcmToken': fcmToken,
      'credit': credit,
      'referralCode': referralCode,
      'referredBy': referredBy,
      'averageRating': averageRating,
      'totalRatings': totalRatings,
      'totalSales': totalSales,
      'farmerType': farmerType,
      'workingHours': workingHours,
      'transportAvailable': transportAvailable,
      'experienceYears': experienceYears,
      'phoneNumber': phoneNumber,
      'specializations': specializations,
      'farmAddress': farmAddress,
      'farmSize': farmSize,
      'hasVeterinarySupport': hasVeterinarySupport,
      'hasHealthCertificate': hasHealthCertificate,
      'animalCounts': animalCounts,
      'certifications': certifications,
      'isTransporter': isTransporter,
      'transporterCompanyName': transporterCompanyName,
      'transporterPhone': transporterPhone,
      'transporterCities': transporterCities,
      'transporterMaxDistanceKm': transporterMaxDistanceKm,
      'transporterPricePerKm': transporterPricePerKm,
      'transporterMaxAnimals': transporterMaxAnimals,
      'transporterVehicleType': transporterVehicleType,
      'transporterVehiclePlate': transporterVehiclePlate,
      'transporterAvailable': transporterAvailable,
      'transporterDescription': transporterDescription,
      'transporterRating': transporterRating,
      'transporterTotalTransports': transporterTotalTransports,
      'transporterDocuments': transporterDocuments,
      'transporterInsurance': transporterInsurance,
      'transporterYearsExperience': transporterYearsExperience,
      'transporterWorkingHours': transporterWorkingHours,
      'transporterPhotoUrls': transporterPhotoUrls,
      'transporterVerified': transporterVerified,
      'transporterLanguages': transporterLanguages,
      'transporterMinPrice': transporterMinPrice,
      'transporterMaxPrice': transporterMaxPrice,
      'transporterRegions': transporterRegions,
      'transporterAnimalTypes': transporterAnimalTypes,
      'transporterCapacityDetails': transporterCapacityDetails,
      'transporterNotes': transporterNotes,
    };
  }

  static User fromJson(Map<String, dynamic> json) {
    try {
      return User(
        email: _safeGetString(json, 'email'),
        uid: _safeGetString(json, 'uid'),
        photoUrl: _safeGetString(json, 'photoUrl'),
        username: _safeGetString(json, 'username'),
        bio: _safeGetString(json, 'bio'),
        followers: _convertToList(json['followers']),
        following: _convertToList(json['following']),
        blocked: _convertToList(json['blocked']),
        blockedBy: _convertToList(json['blockedBy']),
        matchedWith: _safeGetString(json, 'matched_with'),
        country: _safeGetString(json, 'country'),
        state: _safeGetString(json, 'state'),
        city: _safeGetString(json, 'city'),
        neighborhood: _safeGetString(json, 'neighborhood'),
        district: _safeGetString(json, 'district'),
        latitude: _safeGetDouble(json, 'latitude'),
        longitude: _safeGetDouble(json, 'longitude'),
        matchCount: _safeGetInt(json, 'match_count'),
        isPremium: _safeGetBool(json, 'is_premium'),
        numberOfSentGifts: _safeGetInt(json, 'number_of_sent_gifts'),
        numberOfUnsentGifts: _safeGetInt(json, 'number_of_unsent_gifts'),
        giftSendingRate: _safeGetString(json, 'gift_sending_rate'),
        isVerified: _safeGetBool(json, 'isVerified'),
        isConfirmed: _safeGetBool(json, 'isConfirmed'),
        giftPoint: _safeGetDouble(json, 'gift_point'),
        isRated: _safeGetBool(json, 'isRated'),
        rateCount: _safeGetInt(json, 'rateCount'),
        fcmToken: _safeGetString(json, 'fcmToken'),
        credit: _safeGetInt(json, 'credit'),
        referralCode: _safeGetString(json, 'referralCode'),
        referredBy: _safeGetString(json, 'referredBy'),
        averageRating: _safeGetDouble(json, 'averageRating'),
        totalRatings: _safeGetInt(json, 'totalRatings'),
        totalSales: _safeGetInt(json, 'totalSales'),
        farmerType: _safeGetString(json, 'farmerType'),
        workingHours: _safeGetString(json, 'workingHours'),
        transportAvailable: _safeGetString(json, 'transportAvailable'),
        experienceYears: _safeGetInt(json, 'experienceYears'),
        phoneNumber: _safeGetString(json, 'phoneNumber'),
        specializations: _safeGetStringList(json, 'specializations'),
        farmAddress: _safeGetString(json, 'farmAddress'),
        farmSize: _safeGetString(json, 'farmSize'),
        hasVeterinarySupport: _safeGetBool(json, 'hasVeterinarySupport'),
        hasHealthCertificate: _safeGetBool(json, 'hasHealthCertificate'),
        animalCounts: _safeGetStringIntMap(json, 'animalCounts'),
        certifications: _safeGetStringList(json, 'certifications'),
        isTransporter: _safeGetBool(json, 'isTransporter'),
        transporterCompanyName: _safeGetString(json, 'transporterCompanyName'),
        transporterPhone: _safeGetString(json, 'transporterPhone'),
        transporterCities: _safeGetStringList(json, 'transporterCities'),
        transporterMaxDistanceKm:
            _safeGetDouble(json, 'transporterMaxDistanceKm'),
        transporterPricePerKm: _safeGetDouble(json, 'transporterPricePerKm'),
        transporterMaxAnimals: _safeGetInt(json, 'transporterMaxAnimals'),
        transporterVehicleType: _safeGetString(json, 'transporterVehicleType'),
        transporterVehiclePlate:
            _safeGetString(json, 'transporterVehiclePlate'),
        transporterAvailable: _safeGetBool(json, 'transporterAvailable'),
        transporterDescription: _safeGetString(json, 'transporterDescription'),
        transporterRating: _safeGetDouble(json, 'transporterRating'),
        transporterTotalTransports:
            _safeGetInt(json, 'transporterTotalTransports'),
        transporterDocuments: _safeGetStringList(json, 'transporterDocuments'),
        transporterInsurance: _safeGetBool(json, 'transporterInsurance'),
        transporterYearsExperience:
            _safeGetInt(json, 'transporterYearsExperience'),
        transporterWorkingHours:
            _safeGetString(json, 'transporterWorkingHours'),
        transporterPhotoUrls: _safeGetStringList(json, 'transporterPhotoUrls'),
        transporterVerified: _safeGetBool(json, 'transporterVerified'),
        transporterLanguages: _safeGetStringList(json, 'transporterLanguages'),
        transporterMinPrice: _safeGetDouble(json, 'transporterMinPrice'),
        transporterMaxPrice: _safeGetDouble(json, 'transporterMaxPrice'),
        transporterRegions: _safeGetStringList(json, 'transporterRegions'),
        transporterAnimalTypes:
            _safeGetStringList(json, 'transporterAnimalTypes'),
        transporterCapacityDetails: json['transporterCapacityDetails'],
        transporterNotes: _safeGetString(json, 'transporterNotes'),
      );
    } catch (e) {
      print("Error in fromJson: $e");
      // Return a minimal valid user on error
      return User(
        followers: [],
        following: [],
        blocked: [],
        blockedBy: [],
      );
    }
  }
}

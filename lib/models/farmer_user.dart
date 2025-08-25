import 'package:cloud_firestore/cloud_firestore.dart';
import 'user.dart';

class FarmerUser extends User {
  // Çiftçi-specific alanlar
  final String? farmerLicense;      // çiftçi belgesi no
  final String? farmName;           // çiftlik adı
  final String? farmAddress;        // çiftlik adresi
  final int? experienceYears;       // deneyim yılı
  final List<String>? specializations; // ["süt sığırı", "et sığırı"]
  final bool isVerifiedFarmer;      // doğrulanmış çiftçi
  final String? businessNumber;     // vergi/ticaret sicil no
  final List<String>? pastSales;    // geçmiş satış ID'leri
  final double? averageRating;      // ortalama puan
  final int? totalSales;            // toplam satış sayısı
  final int? totalAnimals;          // toplam hayvan sayısı
  final String? farmType;           // "süt çiftliği", "et çiftliği"
  final Map<String, int>? animalCounts; // hayvan türü sayıları
  final List<String>? certifications; // sertifikalar
  final String? farmSize;           // çiftlik büyüklüğü
  final bool? hasVeterinarySupport; // veteriner desteği
  final String? contactHours;       // ulaşılabilir saatler

  FarmerUser({
    // User'dan inherit edilen alanlar
    super.username,
    super.uid,
    super.photoUrl,
    super.email,
    super.bio,
    super.followers,
    super.following,
    super.blocked,
    super.blockedBy,
    super.matchedWith,
    super.country,
    super.state,
    super.city,
    super.matchCount,
    super.isPremium,
    super.numberOfSentGifts,
    super.numberOfUnsentGifts,
    super.giftSendingRate,
    super.giftPoint,
    super.rateCount,
    super.isRated,
    super.isVerified,
    super.isConfirmed,
    super.credit,
    super.fcmToken,
    super.referralCode,
    super.referredBy,
    
    // Çiftçi-specific alanlar
    this.farmerLicense,
    this.farmName,
    this.farmAddress,
    this.experienceYears,
    this.specializations,
    this.isVerifiedFarmer = false,
    this.businessNumber,
    this.pastSales,
    this.averageRating,
    this.totalSales,
    this.totalAnimals,
    this.farmType,
    this.animalCounts,
    this.certifications,
    this.farmSize,
    this.hasVeterinarySupport,
    this.contactHours,
  });

  static FarmerUser fromSnap(DocumentSnapshot snap) {
    var snapshot = snap.data() as Map<String, dynamic>;

    return FarmerUser(
      username: snapshot["username"],
      uid: snapshot["uid"],
      photoUrl: snapshot["photoUrl"],
      email: snapshot["email"],
      bio: snapshot["bio"],
      followers: snapshot["followers"],
      following: snapshot["following"],
      blocked: snapshot["blocked"],
      blockedBy: snapshot["blockedBy"],
      matchedWith: snapshot["matchedWith"],
      country: snapshot["country"],
      state: snapshot["state"],
      city: snapshot["city"],
      matchCount: snapshot["matchCount"],
      isPremium: snapshot["isPremium"],
      numberOfSentGifts: snapshot["numberOfSentGifts"],
      numberOfUnsentGifts: snapshot["numberOfUnsentGifts"],
      giftSendingRate: snapshot["giftSendingRate"],
      giftPoint: snapshot["giftPoint"],
      rateCount: snapshot["rateCount"],
      isRated: snapshot["isRated"],
      isVerified: snapshot["isVerified"],
      isConfirmed: snapshot["isConfirmed"],
      credit: snapshot["credit"],
      fcmToken: snapshot["fcmToken"],
      referralCode: snapshot["referralCode"],
      referredBy: snapshot["referredBy"],
      
      // Çiftçi-specific alanlar
      farmerLicense: snapshot["farmerLicense"],
      farmName: snapshot["farmName"],
      farmAddress: snapshot["farmAddress"],
      experienceYears: snapshot["experienceYears"],
      specializations: List<String>.from(snapshot["specializations"] ?? []),
      isVerifiedFarmer: snapshot["isVerifiedFarmer"] ?? false,
      businessNumber: snapshot["businessNumber"],
      pastSales: List<String>.from(snapshot["pastSales"] ?? []),
      averageRating: snapshot["averageRating"]?.toDouble(),
      totalSales: snapshot["totalSales"],
      totalAnimals: snapshot["totalAnimals"],
      farmType: snapshot["farmType"],
      animalCounts: snapshot["animalCounts"] != null 
          ? Map<String, int>.from(snapshot["animalCounts"]) 
          : null,
      certifications: List<String>.from(snapshot["certifications"] ?? []),
      farmSize: snapshot["farmSize"],
      hasVeterinarySupport: snapshot["hasVeterinarySupport"],
      contactHours: snapshot["contactHours"],
    );
  }

  Map<String, dynamic> toJson() => {
    // User'dan inherit edilen alanlar
    "username": username,
    "uid": uid,
    "photoUrl": photoUrl,
    "email": email,
    "bio": bio,
    "followers": followers,
    "following": following,
    "blocked": blocked,
    "blockedBy": blockedBy,
    "matchedWith": matchedWith,
    "country": country,
    "state": state,
    "city": city,
    "matchCount": matchCount,
    "isPremium": isPremium,
    "numberOfSentGifts": numberOfSentGifts,
    "numberOfUnsentGifts": numberOfUnsentGifts,
    "giftSendingRate": giftSendingRate,
    "giftPoint": giftPoint,
    "rateCount": rateCount,
    "isRated": isRated,
    "isVerified": isVerified,
    "isConfirmed": isConfirmed,
    "credit": credit,
    "fcmToken": fcmToken,
    "referralCode": referralCode,
    "referredBy": referredBy,
    
    // Çiftçi-specific alanlar
    "farmerLicense": farmerLicense,
    "farmName": farmName,
    "farmAddress": farmAddress,
    "experienceYears": experienceYears,
    "specializations": specializations,
    "isVerifiedFarmer": isVerifiedFarmer,
    "businessNumber": businessNumber,
    "pastSales": pastSales,
    "averageRating": averageRating,
    "totalSales": totalSales,
    "totalAnimals": totalAnimals,
    "farmType": farmType,
    "animalCounts": animalCounts,
    "certifications": certifications,
    "farmSize": farmSize,
    "hasVeterinarySupport": hasVeterinarySupport,
    "contactHours": contactHours,
  };
} 
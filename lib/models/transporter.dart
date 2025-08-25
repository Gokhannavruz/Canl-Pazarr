import 'package:cloud_firestore/cloud_firestore.dart';

class Transporter {
  final String transporterId;
  final String userId;
  final String companyName;
  final String phone;
  final List<String> cities;
  final double? maxDistanceKm;
  final double? pricePerKm;
  final int? maxAnimals;
  final String? vehicleType;
  final String? vehiclePlate;
  final bool available;
  final String? description;
  final double? minPrice;
  final double? maxPrice;
  final int? yearsExperience;
  final String? workingHours;
  final bool insurance;
  final List<String> regions;
  final List<String> animalTypes;
  final Map<String, dynamic> capacityDetails;
  final List<String> languages;
  final List<String> documents;
  final List<String> photoUrls;
  final String? notes;
  final String? profileImage;
  final String? address;
  final String? email;
  final double? rating;
  final int? totalTrips;
  final bool isVerified;
  final DateTime createdAt;
  final DateTime updatedAt;

  Transporter({
    required this.transporterId,
    required this.userId,
    required this.companyName,
    required this.phone,
    required this.cities,
    this.maxDistanceKm,
    this.pricePerKm,
    this.maxAnimals,
    this.vehicleType,
    this.vehiclePlate,
    required this.available,
    this.description,
    this.minPrice,
    this.maxPrice,
    this.yearsExperience,
    this.workingHours,
    required this.insurance,
    required this.regions,
    required this.animalTypes,
    required this.capacityDetails,
    required this.languages,
    required this.documents,
    required this.photoUrls,
    this.notes,
    this.profileImage,
    this.address,
    this.email,
    this.rating,
    this.totalTrips,
    required this.isVerified,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Transporter.fromMap(Map<String, dynamic> map, String id) {
    return Transporter(
      transporterId: id,
      userId: id, // users koleksiyonunda id = userId
      companyName: map['transporterCompanyName'] ?? '',
      phone: map['transporterPhone'] ?? '',
      cities: List<String>.from(map['transporterCities'] ?? []),
      maxDistanceKm: map['transporterMaxDistanceKm']?.toDouble(),
      pricePerKm: map['transporterPricePerKm']?.toDouble(),
      maxAnimals: map['transporterMaxAnimals'],
      vehicleType: map['transporterVehicleType'],
      vehiclePlate: map['transporterVehiclePlate'],
      available: map['transporterAvailable'] ?? false,
      description: map['transporterDescription'],
      minPrice: map['transporterMinPrice']?.toDouble(),
      maxPrice: map['transporterMaxPrice']?.toDouble(),
      yearsExperience: map['transporterYearsExperience'],
      workingHours: map['transporterWorkingHours'],
      insurance: map['transporterInsurance'] ?? false,
      regions: List<String>.from(map['transporterRegions'] ?? []),
      animalTypes: List<String>.from(map['transporterAnimalTypes'] ?? []),
      capacityDetails:
          Map<String, dynamic>.from(map['transporterCapacityDetails'] ?? {}),
      languages: List<String>.from(map['transporterLanguages'] ?? []),
      documents: List<String>.from(map['transporterDocuments'] ?? []),
      photoUrls: List<String>.from(map['transporterPhotoUrls'] ?? []),
      notes: map['transporterNotes'],
      profileImage: map['photoUrl'], // users koleksiyonunda photoUrl
      address: map['address'],
      email: map['email'],
      rating: map['averageRating']
          ?.toDouble(), // users koleksiyonunda averageRating
      totalTrips: map['totalTrips'],
      isVerified: map['isVerified'] ?? false,
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? (map['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'transporterCompanyName': companyName,
      'transporterPhone': phone,
      'transporterCities': cities,
      'transporterMaxDistanceKm': maxDistanceKm,
      'transporterPricePerKm': pricePerKm,
      'transporterMaxAnimals': maxAnimals,
      'transporterVehicleType': vehicleType,
      'transporterVehiclePlate': vehiclePlate,
      'transporterAvailable': available,
      'transporterDescription': description,
      'transporterMinPrice': minPrice,
      'transporterMaxPrice': maxPrice,
      'transporterYearsExperience': yearsExperience,
      'transporterWorkingHours': workingHours,
      'transporterInsurance': insurance,
      'transporterRegions': regions,
      'transporterAnimalTypes': animalTypes,
      'transporterCapacityDetails': capacityDetails,
      'transporterLanguages': languages,
      'transporterDocuments': documents,
      'transporterPhotoUrls': photoUrls,
      'transporterNotes': notes,
      'photoUrl': profileImage,
      'address': address,
      'email': email,
      'averageRating': rating,
      'totalTrips': totalTrips,
      'isVerified': isVerified,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  Transporter copyWith({
    String? transporterId,
    String? userId,
    String? companyName,
    String? phone,
    List<String>? cities,
    double? maxDistanceKm,
    double? pricePerKm,
    int? maxAnimals,
    String? vehicleType,
    String? vehiclePlate,
    bool? available,
    String? description,
    double? minPrice,
    double? maxPrice,
    int? yearsExperience,
    String? workingHours,
    bool? insurance,
    List<String>? regions,
    List<String>? animalTypes,
    Map<String, dynamic>? capacityDetails,
    List<String>? languages,
    List<String>? documents,
    List<String>? photoUrls,
    String? notes,
    String? profileImage,
    String? address,
    String? email,
    double? rating,
    int? totalTrips,
    bool? isVerified,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Transporter(
      transporterId: transporterId ?? this.transporterId,
      userId: userId ?? this.userId,
      companyName: companyName ?? this.companyName,
      phone: phone ?? this.phone,
      cities: cities ?? this.cities,
      maxDistanceKm: maxDistanceKm ?? this.maxDistanceKm,
      pricePerKm: pricePerKm ?? this.pricePerKm,
      maxAnimals: maxAnimals ?? this.maxAnimals,
      vehicleType: vehicleType ?? this.vehicleType,
      vehiclePlate: vehiclePlate ?? this.vehiclePlate,
      available: available ?? this.available,
      description: description ?? this.description,
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      yearsExperience: yearsExperience ?? this.yearsExperience,
      workingHours: workingHours ?? this.workingHours,
      insurance: insurance ?? this.insurance,
      regions: regions ?? this.regions,
      animalTypes: animalTypes ?? this.animalTypes,
      capacityDetails: capacityDetails ?? this.capacityDetails,
      languages: languages ?? this.languages,
      documents: documents ?? this.documents,
      photoUrls: photoUrls ?? this.photoUrls,
      notes: notes ?? this.notes,
      profileImage: profileImage ?? this.profileImage,
      address: address ?? this.address,
      email: email ?? this.email,
      rating: rating ?? this.rating,
      totalTrips: totalTrips ?? this.totalTrips,
      isVerified: isVerified ?? this.isVerified,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

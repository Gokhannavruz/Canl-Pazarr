import 'package:cloud_firestore/cloud_firestore.dart';

class Veterinarian {
  final String uid;
  final String username;
  final String? photoUrl; // Kullanıcı profil fotoğrafı
  final String? email;
  final String? bio;
  final String? clinicName;
  final String? phone;
  final String? address;
  final List<String> cities;
  final String? licenseNumber;
  final String? specialization;
  final int? yearsExperience;
  final String? workingHours;
  final bool available;
  final String? description;
  final double? consultationFee;
  final double? emergencyFee;
  final bool homeVisit;
  final bool emergencyService;
  final List<String> animalTypes;
  final List<String> services;
  final List<String> certifications;
  final List<String> languages;
  final List<String> documents;
  final List<String> photoUrls;
  final String? notes;
  final String? emergencyPhone;
  final bool insurance;
  final List<String> regions;
  final Map<String, dynamic> serviceDetails;
  final String? clinicType;
  final String? education;
  final String? university;
  final int? graduationYear;
  final List<String> specializations;
  final bool hasLaboratory;
  final bool hasSurgery;
  final bool hasXRay;
  final bool hasUltrasound;
  final String? equipmentList;
  final String? emergencyProtocol;
  final double? averageRating;
  final int? totalRatings;
  final int? totalPatients;
  final bool isVerified;
  final bool isActive;

  Veterinarian({
    required this.uid,
    required this.username,
    this.photoUrl,
    this.email,
    this.bio,
    this.clinicName,
    this.phone,
    this.address,
    required this.cities,
    this.licenseNumber,
    this.specialization,
    this.yearsExperience,
    this.workingHours,
    required this.available,
    this.description,
    this.consultationFee,
    this.emergencyFee,
    required this.homeVisit,
    required this.emergencyService,
    required this.animalTypes,
    required this.services,
    required this.certifications,
    required this.languages,
    required this.documents,
    required this.photoUrls,
    this.notes,
    this.emergencyPhone,
    required this.insurance,
    required this.regions,
    required this.serviceDetails,
    this.clinicType,
    this.education,
    this.university,
    this.graduationYear,
    required this.specializations,
    required this.hasLaboratory,
    required this.hasSurgery,
    required this.hasXRay,
    required this.hasUltrasound,
    this.equipmentList,
    this.emergencyProtocol,
    this.averageRating,
    this.totalRatings,
    this.totalPatients,
    required this.isVerified,
    required this.isActive,
  });

  static Veterinarian fromSnap(DocumentSnapshot snap) {
    var snapshot = snap.data() as Map<String, dynamic>;

    return Veterinarian(
      uid: snap.id,
      username: snapshot['username'] ?? '',
      photoUrl: snapshot['photoUrl'], // Kullanıcı profil fotoğrafı
      email: snapshot['veterinarianEmail'],
      bio: snapshot['bio'],
      clinicName: snapshot['veterinarianClinicName'],
      phone: snapshot['veterinarianPhone'],
      address: snapshot['veterinarianAddress'],
      cities: List<String>.from(snapshot['veterinarianCities'] ?? []),
      licenseNumber: snapshot['veterinarianLicenseNumber'],
      specialization: snapshot['veterinarianSpecialization'],
      yearsExperience: snapshot['veterinarianYearsExperience'],
      workingHours: snapshot['veterinarianWorkingHours'],
      available: snapshot['veterinarianAvailable'] ?? true,
      description: snapshot['veterinarianDescription'],
      consultationFee:
          (snapshot['veterinarianConsultationFee'] as num?)?.toDouble(),
      emergencyFee: (snapshot['veterinarianEmergencyFee'] as num?)?.toDouble(),
      homeVisit: snapshot['veterinarianHomeVisit'] ?? false,
      emergencyService: snapshot['veterinarianEmergencyService'] ?? false,
      animalTypes: List<String>.from(snapshot['veterinarianAnimalTypes'] ?? []),
      services: List<String>.from(snapshot['veterinarianServices'] ?? []),
      certifications:
          List<String>.from(snapshot['veterinarianCertifications'] ?? []),
      languages: List<String>.from(snapshot['veterinarianLanguages'] ?? []),
      documents: List<String>.from(snapshot['veterinarianDocuments'] ?? []),
      photoUrls: List<String>.from(snapshot['veterinarianPhotoUrls'] ?? []),
      notes: snapshot['veterinarianNotes'],
      emergencyPhone: snapshot['veterinarianEmergencyPhone'],
      insurance: snapshot['veterinarianInsurance'] ?? false,
      regions: List<String>.from(snapshot['veterinarianRegions'] ?? []),
      serviceDetails: Map<String, dynamic>.from(
          snapshot['veterinarianServiceDetails'] ?? {}),
      clinicType: snapshot['veterinarianClinicType'],
      education: snapshot['veterinarianEducation'],
      university: snapshot['veterinarianUniversity'],
      graduationYear: snapshot['veterinarianGraduationYear'],
      specializations:
          List<String>.from(snapshot['veterinarianSpecializations'] ?? []),
      hasLaboratory: snapshot['veterinarianHasLaboratory'] ?? false,
      hasSurgery: snapshot['veterinarianHasSurgery'] ?? false,
      hasXRay: snapshot['veterinarianHasXRay'] ?? false,
      hasUltrasound: snapshot['veterinarianHasUltrasound'] ?? false,
      equipmentList: snapshot['veterinarianEquipmentList'],
      emergencyProtocol: snapshot['veterinarianEmergencyProtocol'],
      averageRating: (snapshot['averageRating'] as num?)?.toDouble(),
      totalRatings: snapshot['totalRatings'],
      totalPatients: snapshot['totalPatients'],
      isVerified: snapshot['isVerified'] ?? false,
      isActive: snapshot['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'username': username,
      'photoUrl': photoUrl,
      'email': email,
      'bio': bio,
      'veterinarianClinicName': clinicName,
      'veterinarianPhone': phone,
      'veterinarianAddress': address,
      'veterinarianCities': cities,
      'veterinarianLicenseNumber': licenseNumber,
      'veterinarianSpecialization': specialization,
      'veterinarianYearsExperience': yearsExperience,
      'veterinarianWorkingHours': workingHours,
      'veterinarianAvailable': available,
      'veterinarianDescription': description,
      'veterinarianConsultationFee': consultationFee,
      'veterinarianEmergencyFee': emergencyFee,
      'veterinarianHomeVisit': homeVisit,
      'veterinarianEmergencyService': emergencyService,
      'veterinarianAnimalTypes': animalTypes,
      'veterinarianServices': services,
      'veterinarianCertifications': certifications,
      'veterinarianLanguages': languages,
      'veterinarianDocuments': documents,
      'veterinarianPhotoUrls': photoUrls,
      'veterinarianNotes': notes,
      'veterinarianEmergencyPhone': emergencyPhone,
      'veterinarianInsurance': insurance,
      'veterinarianRegions': regions,
      'veterinarianServiceDetails': serviceDetails,
      'veterinarianClinicType': clinicType,
      'veterinarianEducation': education,
      'veterinarianUniversity': university,
      'veterinarianGraduationYear': graduationYear,
      'veterinarianSpecializations': specializations,
      'veterinarianHasLaboratory': hasLaboratory,
      'veterinarianHasSurgery': hasSurgery,
      'veterinarianHasXRay': hasXRay,
      'veterinarianHasUltrasound': hasUltrasound,
      'veterinarianEquipmentList': equipmentList,
      'veterinarianEmergencyProtocol': emergencyProtocol,
      'averageRating': averageRating,
      'totalRatings': totalRatings,
      'totalPatients': totalPatients,
      'isVerified': isVerified,
      'isActive': isActive,
    };
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';

class HealthRecord {
  final String recordId;
  final String animalId;
  final String animalPostId;
  final String veterinarianName;
  final String veterinarianLicense;
  final DateTime checkupDate;
  final String overallHealth;
  final List<Vaccination> vaccinations;
  final List<String> healthIssues;
  final List<String> certificateUrls;
  final String notes;
  final bool isVerified;
  final DateTime createdAt;
  final DateTime updatedAt;

  HealthRecord({
    required this.recordId,
    required this.animalId,
    required this.animalPostId,
    required this.veterinarianName,
    required this.veterinarianLicense,
    required this.checkupDate,
    required this.overallHealth,
    required this.vaccinations,
    required this.healthIssues,
    required this.certificateUrls,
    required this.notes,
    required this.isVerified,
    required this.createdAt,
    required this.updatedAt,
  });

  static HealthRecord fromSnap(DocumentSnapshot snap) {
    var snapshot = snap.data() as Map<String, dynamic>;

    return HealthRecord(
      recordId: snapshot["recordId"],
      animalId: snapshot["animalId"],
      animalPostId: snapshot["animalPostId"],
      veterinarianName: snapshot["veterinarianName"],
      veterinarianLicense: snapshot["veterinarianLicense"],
      checkupDate: snapshot["checkupDate"].toDate(),
      overallHealth: snapshot["overallHealth"],
      vaccinations: (snapshot["vaccinations"] as List<dynamic>)
          .map((vaccine) => Vaccination.fromJson(vaccine))
          .toList(),
      healthIssues: List<String>.from(snapshot["healthIssues"] ?? []),
      certificateUrls: List<String>.from(snapshot["certificateUrls"] ?? []),
      notes: snapshot["notes"],
      isVerified: snapshot["isVerified"],
      createdAt: snapshot["createdAt"].toDate(),
      updatedAt: snapshot["updatedAt"].toDate(),
    );
  }

  Map<String, dynamic> toJson() => {
        "recordId": recordId,
        "animalId": animalId,
        "animalPostId": animalPostId,
        "veterinarianName": veterinarianName,
        "veterinarianLicense": veterinarianLicense,
        "checkupDate": checkupDate,
        "overallHealth": overallHealth,
        "vaccinations":
            vaccinations.map((vaccine) => vaccine.toJson()).toList(),
        "healthIssues": healthIssues,
        "certificateUrls": certificateUrls,
        "notes": notes,
        "isVerified": isVerified,
        "createdAt": createdAt,
        "updatedAt": updatedAt,
      };
}

class Vaccination {
  final String vaccineId;
  final String vaccineName;
  final String vaccineType;
  final DateTime administeredDate;
  final DateTime expiryDate;
  final String veterinarianName;
  final String batchNumber;
  final String manufacturer;
  final String certificateUrl;
  final bool isValid;

  Vaccination({
    required this.vaccineId,
    required this.vaccineName,
    required this.vaccineType,
    required this.administeredDate,
    required this.expiryDate,
    required this.veterinarianName,
    required this.batchNumber,
    required this.manufacturer,
    required this.certificateUrl,
    required this.isValid,
  });

  static Vaccination fromJson(Map<String, dynamic> json) {
    return Vaccination(
      vaccineId: json["vaccineId"],
      vaccineName: json["vaccineName"],
      vaccineType: json["vaccineType"],
      administeredDate: json["administeredDate"].toDate(),
      expiryDate: json["expiryDate"].toDate(),
      veterinarianName: json["veterinarianName"],
      batchNumber: json["batchNumber"],
      manufacturer: json["manufacturer"],
      certificateUrl: json["certificateUrl"],
      isValid: json["isValid"],
    );
  }

  Map<String, dynamic> toJson() => {
        "vaccineId": vaccineId,
        "vaccineName": vaccineName,
        "vaccineType": vaccineType,
        "administeredDate": administeredDate,
        "expiryDate": expiryDate,
        "veterinarianName": veterinarianName,
        "batchNumber": batchNumber,
        "manufacturer": manufacturer,
        "certificateUrl": certificateUrl,
        "isValid": isValid,
      };
}

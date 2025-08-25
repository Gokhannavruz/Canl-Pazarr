import 'package:cloud_firestore/cloud_firestore.dart';

class SaleRating {
  final String ratingId;
  final String saleId; // AnimalPost postId
  final String sellerId; // Satıcı uid
  final String buyerId; // Alıcı uid
  final double rating; // 1-5 arası puan
  final String comment; // İsteğe bağlı yorum
  final DateTime dateRated; // Değerlendirme tarihi
  final bool isVerified; // Doğrulanmış satış mı
  final Map<String, dynamic>? additionalInfo; // Ek bilgiler

  SaleRating({
    required this.ratingId,
    required this.saleId,
    required this.sellerId,
    required this.buyerId,
    required this.rating,
    required this.comment,
    required this.dateRated,
    required this.isVerified,
    this.additionalInfo,
  });

  static SaleRating fromSnap(DocumentSnapshot snap) {
    var snapshot = snap.data() as Map<String, dynamic>? ?? {};

    return SaleRating(
      ratingId: snap.id,
      saleId: snapshot["saleId"] ?? '',
      sellerId: snapshot["sellerId"] ?? '',
      buyerId: snapshot["buyerId"] ?? '',
      rating: _safeGetDouble(snapshot["rating"]),
      comment: snapshot["comment"] ?? '',
      dateRated: snapshot["dateRated"]?.toDate() ?? DateTime.now(),
      isVerified: snapshot["isVerified"] ?? false,
      additionalInfo: snapshot["additionalInfo"],
    );
  }

  static SaleRating fromMap(Map<String, dynamic> data) {
    return SaleRating(
      ratingId: data["ratingId"] ?? '',
      saleId: data["saleId"] ?? '',
      sellerId: data["sellerId"] ?? '',
      buyerId: data["buyerId"] ?? '',
      rating: _safeGetDouble(data["rating"]),
      comment: data["comment"] ?? '',
      dateRated: data["dateRated"]?.toDate() ?? DateTime.now(),
      isVerified: data["isVerified"] ?? false,
      additionalInfo: data["additionalInfo"],
    );
  }

  static double _safeGetDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  Map<String, dynamic> toJson() => {
        "ratingId": ratingId,
        "saleId": saleId,
        "sellerId": sellerId,
        "buyerId": buyerId,
        "rating": rating,
        "comment": comment,
        "dateRated": dateRated,
        "isVerified": isVerified,
        "additionalInfo": additionalInfo,
      };
}

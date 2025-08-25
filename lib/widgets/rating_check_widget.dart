import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/animal_post.dart';
import '../services/animal_sale_service.dart';
import '../widgets/sale_rating_dialog.dart';

class RatingCheckWidget extends StatefulWidget {
  final Widget child;

  const RatingCheckWidget({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  State<RatingCheckWidget> createState() => _RatingCheckWidgetState();
}

class _RatingCheckWidgetState extends State<RatingCheckWidget> {
  final AnimalSaleService _animalSaleService = AnimalSaleService();
  bool _hasCheckedRatings = false;

  @override
  void initState() {
    super.initState();
    _checkForPendingRatings();
  }

  Future<void> _checkForPendingRatings() async {
    if (_hasCheckedRatings) return;

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    // Bir kere kontrol edilmiş olarak işaretle
    setState(() {
      _hasCheckedRatings = true;
    });

    try {
      // Biraz bekle ki UI tam yüklensin
      await Future.delayed(Duration(seconds: 1));

      // Değerlendirme yapılması gereken satışları getir
      final pendingRatings =
          await _animalSaleService.getPendingRatings(currentUser.uid);

      if (pendingRatings.isNotEmpty && mounted) {
        // İlk satış için değerlendirme diyalogunu göster
        _showRatingDialog(pendingRatings.first);
      }
    } catch (e) {
      print("Error checking pending ratings: $e");
    }
  }

  void _showRatingDialog(AnimalPost animal) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => SaleRatingDialog(
        animal: animal,
        sellerId: animal.uid,
        buyerId: FirebaseAuth.instance.currentUser!.uid,
        saleId: animal.postId,
        onRatingSubmitted: () {
          // Değerlendirme yapıldıktan sonra tekrar kontrol et
          _checkForMoreRatings();
        },
      ),
    );
  }

  Future<void> _checkForMoreRatings() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    try {
      // Biraz bekle
      await Future.delayed(Duration(milliseconds: 500));

      // Hala değerlendirme yapılması gereken satışlar var mı kontrol et
      final pendingRatings =
          await _animalSaleService.getPendingRatings(currentUser.uid);

      if (pendingRatings.isNotEmpty && mounted) {
        // Diğer satış için değerlendirme diyalogunu göster
        _showRatingDialog(pendingRatings.first);
      }
    } catch (e) {
      print("Error checking for more ratings: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

// Ana sayfa widget'ını saran extension
class RatingCheckWrapper extends StatelessWidget {
  final Widget child;

  const RatingCheckWrapper({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return RatingCheckWidget(child: child);
  }
}

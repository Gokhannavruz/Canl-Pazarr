import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../widgets/animal_card.dart';
import '../models/animal_post.dart';
import 'animal_detail_screen.dart';

class LikedPostsScreen extends StatefulWidget {
  final String userId;

  const LikedPostsScreen({Key? key, required this.userId}) : super(key: key);

  @override
  _LikedPostsScreenState createState() => _LikedPostsScreenState();
}

class _LikedPostsScreenState extends State<LikedPostsScreen> {
  late List<String> likedList;
  bool isLoading = true;

  // Classic color palette - matching the app's design system
  static const Color primaryColor = Color(0xFF2E7D32);
  static const Color accentColor = Color(0xFF4CAF50);
  static const Color warningColor = Color(0xFFFF9800);
  static const Color errorColor = Color(0xFFE53935);
  static const Color successColor = Color(0xFF4CAF50);
  static const Color infoColor = Color(0xFF2196F3);
  static const Color backgroundColor = Colors.white;
  static const Color surfaceColor = Color(0xFFFAFAFA);
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color dividerColor = Color(0xFFE0E0E0);

  @override
  void initState() {
    super.initState();
    likedList = [];
    getLikedList();
  }

  // get liked list from Firestore animals collection and add to likes list
  Future<void> getLikedList() async {
    final query = await FirebaseFirestore.instance
        .collection('animals')
        .where('likes', arrayContains: widget.userId)
        .get();
    setState(() {
      likedList = query.docs.map((e) => e.id).toList();
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: backgroundColor,
        title: Text(
          'Beğenilen İlanlar',
          style: GoogleFonts.poppins(
            color: textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: textPrimary,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: primaryColor,
              ),
            )
          : likedList.isEmpty
              ? _buildEmptyState()
              : _buildLikedPostsList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animal icons with better styling
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(50),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '🐄',
                    style: const TextStyle(fontSize: 40),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '🐑',
                    style: const TextStyle(fontSize: 40),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '🐐',
                    style: const TextStyle(fontSize: 40),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Henüz beğendiğiniz ilan yok',
              style: GoogleFonts.poppins(
                color: textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Hayvan ilanlarını beğenerek burada takip edebilirsiniz',
              style: GoogleFonts.poppins(
                color: textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w400,
                letterSpacing: 0.3,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: dividerColor,
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.favorite_border,
                      color: primaryColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Flexible(
                    child: Text(
                      'Beğendiğiniz ilanlar burada görünecek',
                      style: GoogleFonts.poppins(
                        color: textSecondary,
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        letterSpacing: 0.3,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLikedPostsList() {
    return RefreshIndicator(
      color: primaryColor,
      onRefresh: getLikedList,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: likedList.length,
        itemBuilder: (context, index) {
          return StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('animals')
                .doc(likedList[index])
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasData && snapshot.data!.exists) {
                final animal = AnimalPost.fromSnap(snapshot.data!);
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: dividerColor,
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: AnimalCard(
                    animal: animal,
                    isGridView: false,
                    onTap: () {
                      // Navigate to animal detail screen directly
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              AnimalDetailScreen(animal: animal),
                        ),
                      );
                    },
                    onFavorite: () {
                      // Remove from favorites
                      _removeFromFavorites(animal.postId);
                    },
                    onShare: () {
                      // Share animal post
                      _shareAnimalPost(animal);
                    },
                  ),
                );
              } else if (snapshot.connectionState == ConnectionState.waiting) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: dividerColor,
                      width: 1,
                    ),
                  ),
                  child: const Center(
                    child: CircularProgressIndicator(
                      color: primaryColor,
                    ),
                  ),
                );
              } else {
                return const SizedBox.shrink();
              }
            },
          );
        },
      ),
    );
  }

  // Remove animal from favorites
  Future<void> _removeFromFavorites(String postId) async {
    try {
      // Remove from user's liked list in Firestore
      await FirebaseFirestore.instance
          .collection('animals')
          .doc(postId)
          .update({
        'likes': FieldValue.arrayRemove([widget.userId]),
      });

      // Update local state
      setState(() {
        likedList.remove(postId);
      });

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'İlan favorilerden kaldırıldı',
            style: GoogleFonts.poppins(
              color: backgroundColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          backgroundColor: successColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    } catch (e) {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Bir hata oluştu',
            style: GoogleFonts.poppins(
              color: backgroundColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          backgroundColor: errorColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    }
  }

  // Share animal post
  void _shareAnimalPost(AnimalPost animal) {
    // TODO: Implement share functionality
    // This would typically use a package like share_plus
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Paylaşım özelliği yakında eklenecek',
          style: GoogleFonts.poppins(
            color: backgroundColor,
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: infoColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}

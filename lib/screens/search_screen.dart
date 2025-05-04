import 'package:freecycle/screens/post_screen.dart';
import 'package:freecycle/widgets/post_card.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:freecycle/ad_helper/ad_helper.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:freecycle/src/rvncat_constant.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' if (dart.library.html) 'package:freecycle/utils/web_stub.dart'
    as io;
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({Key? key}) : super(key: key);

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchTerm = '';
  String country = '';
  List<DocumentSnapshot>? _allPosts;
  bool _isLoading = true;
  InterstitialAd? _interstitialAd;
  bool _isInterstitialAdReady = false;
  bool _isPremium = false;
  final ScrollController _scrollController = ScrollController();
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _limit = 15;
  DocumentSnapshot? _lastDocument;

  // App color palette
  final Color _primaryColor = Colors.grey[900]!;
  final Color _secondaryColor = Colors.grey[850]!;
  final Color _accentColor = Colors.blue[700]!;
  final Color _textColor = Colors.white;
  final Color _hintColor = Colors.grey[400]!;

  String get _searchInterstitialAdUnitId {
    if (kIsWeb) {
      return 'ca-app-pub-8445989958080180/dummy-web-unit-id'; // Web için dummy id
    } else if (io.Platform.isAndroid) {
      return 'ca-app-pub-8445989958080180/2692776828'; // Replace with your actual Android ad unit ID for search screen
    } else if (io.Platform.isIOS) {
      return 'ca-app-pub-8445989958080180/7898908020'; // Replace with your actual iOS ad unit ID for search screen
    } else {
      return 'ca-app-pub-8445989958080180/dummy-unit-id'; // Diğer platformlar için dummy id
    }
  }

  @override
  void initState() {
    super.initState();
    _checkPremiumStatus();
    _getUserLocationAndPosts();
    _scrollController.addListener(_onScroll);
  }

  void _checkPremiumStatus() async {
    try {
      if (!kIsWeb) {
        CustomerInfo customerInfo = await Purchases.getCustomerInfo();
        setState(() {
          _isPremium =
              customerInfo.entitlements.all[entitlementID]?.isActive ?? false;
        });
        if (!_isPremium) {
          _loadInterstitialAd();
        }
      }
    } catch (e) {
      print("Error checking premium status: $e");
    }
  }

  void _loadInterstitialAd() {
    if (kIsWeb) {
      print("Skipping interstitial ad loading on web platform");
      return;
    }

    InterstitialAd.load(
      adUnitId: _searchInterstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (InterstitialAd ad) {
          _interstitialAd = ad;
          _isInterstitialAdReady = true;
          _setFullScreenContentCallback(ad);
        },
        onAdFailedToLoad: (LoadAdError error) {
          print(
              "Failed to load Search Screen Interstitial Ad: ${error.message}");
          _isInterstitialAdReady = false;
          _loadInterstitialAd();
        },
      ),
    );
  }

  void _setFullScreenContentCallback(InterstitialAd ad) {
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (InterstitialAd ad) {
        ad.dispose();
        _loadInterstitialAd();
      },
      onAdFailedToShowFullScreenContent: (InterstitialAd ad, AdError error) {
        print('$ad failed to show with error $error');
        ad.dispose();
        _loadInterstitialAd();
      },
    );
  }

  void _showInterstitialAd() {
    if (kIsWeb || _isPremium) return;

    if (_interstitialAd != null && _isInterstitialAdReady) {
      _interstitialAd!.show();
      _isInterstitialAdReady = false;
    }
  }

  void _getUserLocationAndPosts() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userData = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      setState(() {
        country = userData['country'];
      });
      _loadMorePosts();
    }
  }

  Future<void> _loadMorePosts() async {
    if (_isLoadingMore || !_hasMore) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      final snapshots = await FirebaseFirestore.instance
          .collection('posts')
          .where('country', isEqualTo: country)
          .limit(50)
          .get();

      if (snapshots.docs.isEmpty) {
        setState(() {
          _hasMore = false;
          _isLoadingMore = false;
        });
        return;
      }

      final allDocs = snapshots.docs.toList()..shuffle();

      setState(() {
        _allPosts = allDocs;
        _isLoading = false;
        _isLoadingMore = false;
        _hasMore = false;
      });
    } catch (e) {
      print("Error loading posts: $e");
      setState(() {
        _isLoading = false;
        _isLoadingMore = false;
      });
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >
            _scrollController.position.maxScrollExtent - 500 &&
        !_isLoadingMore) {
      _loadMorePosts();
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    if (!kIsWeb) {
      _interstitialAd?.dispose();
    }
    super.dispose();
  }

  List<String> _generateSearchTerms(String searchTerm) {
    return searchTerm.toLowerCase().split(' ');
  }

  List<DocumentSnapshot> _filterPosts() {
    if (_searchTerm.isEmpty) return _allPosts ?? [];

    List<String> searchTerms = _generateSearchTerms(_searchTerm);
    return _allPosts?.where((post) {
          String description = post['description'].toLowerCase();
          String category = post['category'].toLowerCase();
          return searchTerms.every(
              (term) => description.contains(term) || category.contains(term));
        }).toList() ??
        [];
  }

  @override
  Widget build(BuildContext context) {
    // Ekran genişliğini al
    double screenWidth = MediaQuery.of(context).size.width;

    // Responsive tasarım için gerekli değişkenler
    int crossAxisCount = 2; // Mobil için varsayılan değer
    double padding = 16.0;
    double spacing = 16.0;
    double aspectRatio = 0.75;

    // Web platformu için ekran genişliğine göre ayarlamalar
    if (kIsWeb) {
      if (screenWidth > 1200) {
        crossAxisCount = 5; // Çok geniş ekranlar
        padding = 32.0;
      } else if (screenWidth > 900) {
        crossAxisCount = 4; // Geniş ekranlar
        padding = 24.0;
      } else if (screenWidth > 600) {
        crossAxisCount = 3; // Orta ekranlar
        padding = 20.0;
      }
      // Aspect ratio'yu da web için ayarla
      aspectRatio = 0.8;
    }

    return Scaffold(
      backgroundColor: _primaryColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: _secondaryColor,
        title: Container(
          height: 40,
          width: kIsWeb
              ? screenWidth * 0.4
              : double.infinity, // Web için daha dar bir arama kutusu
          decoration: BoxDecoration(
            color: Colors.grey[800],
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: _textColor,
              fontWeight: FontWeight.w400,
            ),
            controller: _searchController,
            cursorColor: _textColor,
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: 'Search posts...',
              hintStyle: GoogleFonts.poppins(
                color: _hintColor,
                fontSize: 14,
                fontWeight: FontWeight.w300,
              ),
              prefixIcon: Icon(Icons.search, color: _hintColor, size: 20),
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
              isDense: true,
            ),
            onChanged: (value) {
              setState(() {
                _searchTerm = value;
              });
            },
          ),
        ),
        titleSpacing: 10,
        centerTitle: kIsWeb, // Web'de başlığı ortala
      ),
      body: _isLoading
          ? _buildShimmerEffect(crossAxisCount, padding, spacing, aspectRatio)
          : _buildPostGrid(crossAxisCount, padding, spacing, aspectRatio),
    );
  }

  Widget _buildShimmerEffect(
      int crossAxisCount, double padding, double spacing, double aspectRatio) {
    return GridView.builder(
      padding: EdgeInsets.all(padding),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: spacing,
        mainAxisSpacing: spacing,
        childAspectRatio: aspectRatio,
      ),
      itemCount: 10, // Shimmer efekti için gösterilecek öğe sayısı
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey[850]!,
          highlightColor: Colors.grey[700]!,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPostGrid(
      int crossAxisCount, double padding, double spacing, double aspectRatio) {
    List<DocumentSnapshot> filteredPosts = _filterPosts();

    if (filteredPosts.isEmpty) {
      return Center(
        child: Text(
          'No matching posts found.',
          style: GoogleFonts.poppins(
            color: Colors.grey[400],
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }

    return GridView.builder(
      controller: _scrollController,
      padding: EdgeInsets.all(padding),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: spacing,
        mainAxisSpacing: spacing,
        childAspectRatio: aspectRatio,
      ),
      itemCount: filteredPosts.length,
      itemBuilder: (context, index) {
        final post = filteredPosts[index];
        return GestureDetector(
          onTap: () {
            if (!_isPremium && !kIsWeb) {
              _showInterstitialAd();
            }
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    PostScreen(postId: post.id, uid: post['uid']),
              ),
            );
          },
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  spreadRadius: 1,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: post['postUrl'],
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Shimmer.fromColors(
                      baseColor: Colors.grey[850]!,
                      highlightColor: Colors.grey[700]!,
                      child: Container(color: Colors.white),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: Colors.grey[800],
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error, color: Colors.red),
                          SizedBox(height: 8),
                          Text(
                            'Image Error',
                            style: GoogleFonts.poppins(color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(12.0),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.black.withOpacity(0.9),
                            Colors.transparent,
                          ],
                          stops: const [0.0, 0.8],
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            post['description'],
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 12.0, // Daha küçük font boyutu
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.1,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: _accentColor.withOpacity(0.85),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              post['category'],
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize:
                                    10.0, // Kategoriler için daha küçük font
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

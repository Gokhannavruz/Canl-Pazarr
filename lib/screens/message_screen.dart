import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:animal_trade/screens/profile_screen2.dart';

import 'package:intl/intl.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import 'package:shimmer/shimmer.dart';

import '../models/user.dart';
import '../models/animal_post.dart';
import '../screens/animal_detail_screen.dart';
import '../utils/animal_colors.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/pricing_service.dart';
import '../services/animal_sale_service.dart';
import '../widgets/sale_rating_dialog.dart';
import 'dart:ui';

// NOT: Firebase artık FCM Server Key kullanımını desteklemiyor (Haziran 2023'ten beri deprecated)
// Bunun yerine FCM HTTP v1 API ve Firebase Cloud Functions kullanılmalıdır
// Detaylı bilgi: https://firebase.google.com/docs/cloud-messaging/migrate-v1

class MessagesPage extends StatefulWidget {
  final String currentUserUid;
  final String recipientUid;
  final String postId;

  const MessagesPage({
    Key? key,
    required this.currentUserUid,
    required this.recipientUid,
    required this.postId,
  }) : super(key: key);

  @override
  _MessagesPageState createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  late Key _listKey = UniqueKey();
  User? recipientUser;
  late bool _isListViewRendered;
  String currentUserUid = "";
  String PostUid = "";
  String? _senderToken;
  String? _recipientToken;
  String _userCountry = "";

  // Lokal bildirimler için plugin
  late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;

  late String conversationId =
      widget.currentUserUid.hashCode <= widget.recipientUid.hashCode
          ? "${widget.currentUserUid}-${widget.recipientUid}"
          : "${widget.recipientUid}-${widget.currentUserUid}";

  // Veteriner kontrolü için
  bool _isVeterinarianConversation = false;
  Map<String, dynamic>? _veterinarianData;

  // Klavye durumu için
  bool _isKeyboardVisible = false;

  @override
  void initState() {
    super.initState();
    print(
        "MessagesPage initState - currentUser: ${widget.currentUserUid}, recipient: ${widget.recipientUid}");

    _initializeFCM();
    _updateCurrentUserToken();
    _validateTokens();
    _initializeLocalNotifications();
    _isListViewRendered = false;
    currentUserUid = widget.currentUserUid;

    getUserProfile();
    getCurrentUserUid();
    _getUserCountry();

    // If a postId was provided, get post info safely
    if (widget.postId.isNotEmpty) {
      getPostUid(widget.postId).then((uid) {
        if (mounted && uid.isNotEmpty) {
          setState(() {
            PostUid = uid;
          });
        }
      });
    }

    // Veteriner kontrolü yap
    _checkIfVeterinarian();

    // Klavye durumunu takip et
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupKeyboardListener();
    });
  }

  Future<void> _checkIfVeterinarian() async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.recipientUid)
          .get();

      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        final isVeterinarian = userData['isVeterinarian'] ?? false;

        if (mounted) {
          setState(() {
            _isVeterinarianConversation = isVeterinarian;
            if (isVeterinarian) {
              _veterinarianData = userData;
            }
          });
        }

        print('Veteriner kontrolü: $isVeterinarian');
      }
    } catch (e) {
      print('Veteriner kontrolü hatası: $e');
    }
  }

  void _initializeLocalNotifications() {
    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    // Android için başlat
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    // iOS için başlat
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    // Başlatma ayarları
    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Bildirime tıklandığında yapılacak işlem
        if (response.payload != null) {
          print('Bildirim yükleme: ${response.payload}');

          // Payload'dan konuşma bilgilerini çıkar
          Map<String, dynamic> data = jsonDecode(response.payload!);
          _navigateToMessageScreen(data);
        }
      },
    );
  }

  Future<void> _initializeFCM() async {
    try {
      print("FCM başlatılıyor - currentUser: ${widget.currentUserUid}");

      // İOS için özel izin ayarları
      NotificationSettings settings;
      if (Platform.isIOS) {
        print("iOS için özel bildirim izinleri isteniyor");

        // iOS için daha kapsamlı izin ayarları
        settings = await FirebaseMessaging.instance.requestPermission(
          alert: true,
          badge: true,
          sound: true,
          provisional: true, // Önemli: iOS'te geçici izin modu
          criticalAlert: false,
          announcement: false,
          carPlay: false,
        );

        // iOS'te APNs token'ı manuel olarak güncelle
        await FirebaseMessaging.instance
            .setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );

        print(
            "iOS bildirim ayarları tamamlandı: ${settings.authorizationStatus}");
      } else {
        // Android için standart izinler
        settings = await FirebaseMessaging.instance.requestPermission(
          alert: true,
          badge: true,
          sound: true,
        );
      }

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        print("✅ Bildirim izni: ${settings.authorizationStatus}");

        // Token yenileme dinleyicisi
        FirebaseMessaging.instance.onTokenRefresh.listen((String token) {
          print('FCM token yenilendi: $token');
          _updateToken(widget.currentUserUid, token);
        }).onError((error) {
          print('Token yenileme hatası: $error');
        });

        // ÖN PLANDA MESAJ ALMA (bildirim gösterme)
        FirebaseMessaging.onMessage.listen((RemoteMessage message) {
          try {
            print(
                '🔔 FCM mesajı alındı (ön plan): ${message.notification?.title}');
            print('📋 Bildirim verileri: ${message.data}');

            // ÖNEMLİ KONTROL: Bildirim verilerinde sender_id var mı?
            if (!message.data.containsKey('sender_id')) {
              print('⚠️ Bildirim verisinde sender_id alanı yok!');
              return;
            }

            // Kimin gönderdiğine bak
            String senderId = message.data['sender_id'] ?? '';

            // Kritik kontrol: Eğer mesajı gönderen şu anki kullanıcı ise bildirim gösterme
            if (senderId.isNotEmpty && senderId == widget.currentUserUid) {
              print(
                  '⛔ KENDİ MESAJIM İÇİN BİLDİRİM ALMIYORUM: sender_id=$senderId, currentUser=${widget.currentUserUid}');
              return;
            }

            print(
                '✅ BAŞKASININ MESAJI İÇİN BİLDİRİM GÖSTERİYORUM: sender_id=$senderId, currentUser=${widget.currentUserUid}');

            // Bildirimi göster
            RemoteNotification? notification = message.notification;
            if (notification != null) {
              flutterLocalNotificationsPlugin.show(
                notification.hashCode,
                notification.title ?? "Yeni mesaj",
                notification.body ?? "",
                NotificationDetails(
                  android: AndroidNotificationDetails(
                    'messages_channel',
                    'Mesajlar',
                    channelDescription: 'Mesaj bildirimlerini gösterir',
                    importance: Importance.max,
                    priority: Priority.high,
                  ),
                  iOS: const DarwinNotificationDetails(
                    presentAlert: true,
                    presentBadge: true,
                    presentSound: true,
                  ),
                ),
                payload: jsonEncode(message.data),
              );
            }
          } catch (e) {
            print('❌ Bildirim işleme hatası: $e');
          }
        });

        // ARKA PLANDA MESAJ TIKLANDIĞINDA
        FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
          print('Bildirim tıklandı (arka plan): ${message.data}');
          _navigateToMessageScreen(message.data);
        });

        // UYGULAMA KAPALI İKEN GELDİĞİNDE
        RemoteMessage? initialMessage =
            await FirebaseMessaging.instance.getInitialMessage();
        if (initialMessage != null) {
          print('Uygulama bildirimden başlatıldı: ${initialMessage.data}');
          Future.delayed(Duration(seconds: 1), () {
            _navigateToMessageScreen(initialMessage.data);
          });
        }
      } else {
        print('⚠️ Bildirim izni reddedildi: ${settings.authorizationStatus}');
      }
    } catch (e) {
      print('❌ FCM başlatma hatası: $e');
    }
  }

  Future<void> _loadTokens() async {
    try {
      bool hasInternet = await _checkInternetConnection();
      if (!hasInternet) {
        print('No internet connection');
        return;
      }

      try {
        _senderToken = await _getAndUpdateToken(widget.currentUserUid);
        _recipientToken = await _getAndUpdateToken(widget.recipientUid);
      } catch (e) {
        print('Error loading tokens: $e');
      }
    } catch (e) {
      print('Error in _loadTokens: $e');
    }
  }

  Future<String?> _getAndUpdateToken(String uid) async {
    try {
      bool hasInternet = await _checkInternetConnection();
      if (!hasInternet) {
        print('No internet connection');
        return null;
      }

      NotificationSettings settings =
          await FirebaseMessaging.instance.requestPermission();
      if (settings.authorizationStatus != AuthorizationStatus.authorized) {
        print('Push notifications not authorized');
        return null;
      }

      String? token = await FirebaseMessaging.instance.getToken().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          print('Token request timed out');
          return null;
        },
      );

      if (token != null && token.isNotEmpty) {
        try {
          DocumentSnapshot doc = await FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .get();

          if (!doc.exists) {
            print('User document does not exist');
            return null;
          }

          String currentToken = doc.get('fcmToken') ?? "";

          if (currentToken.isEmpty || currentToken != token) {
            await FirebaseFirestore.instance
                .collection('users')
                .doc(uid)
                .update({'fcmToken': token});
            print('Updated token for $uid: $token');
          } else {
            print('Token for $uid is up to date');
          }
          return token;
        } catch (e) {
          print('Error accessing Firestore: $e');
          return null;
        }
      }
    } catch (e) {
      print('Error getting/updating FCM token: $e');
      return null;
    }
    return null;
  }

  Future<void> _updateToken(String uid, String token) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .update({'fcmToken': token});
      print('Token updated for $uid: $token');
    } catch (e) {
      print('Error updating token: $e');
    }
  }

  Future<bool> _checkInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    }
  }

  Future<void> reduceCredit() async {
    DocumentSnapshot doc = await FirebaseFirestore.instance
        .collection("users")
        .doc(widget.currentUserUid)
        .get();
    int credit = doc["credit"];
    if (doc["credit"] >= 30) {
      FirebaseFirestore.instance
          .collection("users")
          .doc(widget.currentUserUid)
          .update({
        "credit": credit - 30,
      });
    } else if (doc["credit"] >= 20) {
      FirebaseFirestore.instance
          .collection("users")
          .doc(widget.currentUserUid)
          .update({
        "credit": credit - 20,
      });
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _setupKeyboardListener() {
    // Bu metod artık gerekli değil, MediaQuery kullanacağız
  }

  Future<User> getUser(String uid) async {
    DocumentSnapshot doc =
        await FirebaseFirestore.instance.collection("users").doc(uid).get();
    return User.fromSnap(doc);
  }

  Future<User> getCurrentUser() async {
    DocumentSnapshot doc = await FirebaseFirestore.instance
        .collection("users")
        .doc(widget.currentUserUid)
        .get();
    return User.fromSnap(doc);
  }

  Future<void> getUserProfile() async {
    recipientUser = await getUser(widget.recipientUid);
    setState(() {});
  }

  Future<void> getCurrentUserUid() async {
    currentUserUid = await getCurrentUser().then((value) => value.uid!);
    setState(() {
      currentUserUid = currentUserUid;
    });
  }

  Future<String> getPostUid(String postId) async {
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection("posts")
          .doc(postId)
          .get();

      if (!mounted) return PostUid;

      if (doc.exists) {
        setState(() {
          PostUid = doc["uid"] as String;
        });
        return PostUid;
      } else {
        print("Post document does not exist: $postId");
        return "";
      }
    } catch (e) {
      print("Error getting post UID: $e");
      return "";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AnimalColors.background,
      appBar: AppBar(
        toolbarHeight: 70,
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AnimalColors.primary,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: recipientUser != null
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: AnimalColors.secondary.withOpacity(0.2),
                            width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: AnimalColors.primary.withOpacity(0.08),
                            blurRadius: 10,
                            spreadRadius: 0,
                          )
                        ]),
                    child: CircleAvatar(
                      radius: 20,
                      backgroundImage:
                          NetworkImage(recipientUser!.photoUrl ?? ''),
                      backgroundColor: AnimalColors.secondary.withOpacity(0.2),
                      child: recipientUser!.photoUrl == null ||
                              recipientUser!.photoUrl!.isEmpty
                          ? Icon(Icons.person,
                              color: AnimalColors.primary, size: 24)
                          : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Flexible(
                    child: InkWell(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProfileScreen2(
                            snap: null,
                            uid: widget.recipientUid,
                            userId: widget.currentUserUid,
                          ),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(
                                child: Text(
                                  recipientUser!.username ?? "User",
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF212121),
                                  ),
                                ),
                              ),
                              if (recipientUser!.isPremium == true)
                                Padding(
                                  padding: const EdgeInsets.only(left: 6),
                                  child: Icon(
                                    Icons.verified_rounded,
                                    size: 16,
                                    color: AnimalColors.primary,
                                  ),
                                ),
                            ],
                          ),
                          Text(
                            recipientUser!.isPremium == true
                                ? "Premium User"
                                : "Online",
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Color(0xFF757575),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              )
            : null,
        actions: widget.postId.isNotEmpty && !_isVeterinarianConversation
            ? [
                _buildSaleButton(),
              ]
            : null,
      ),
      body: Container(
        color: Colors.white,
        child: Column(
          children: [
            // Klavye açık değilse hayvan detay bilgilerini göster
            if (MediaQuery.of(context).viewInsets.bottom == 0) ...[
              if (widget.postId.isNotEmpty && !_isVeterinarianConversation)
                _buildProductCard(),
              if (_isVeterinarianConversation) _buildVeterinarianInfoCard(),
            ],
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection("conversations")
                    .where("messagesId", isEqualTo: conversationId)
                    .orderBy("timestamp", descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  // İlk yükleme sırasında sadece loading göster, klavye değişimlerinde gösterme
                  if (snapshot.connectionState == ConnectionState.waiting &&
                      !snapshot.hasData &&
                      MediaQuery.of(context).viewInsets.bottom == 0) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: AnimalColors.primary,
                      ),
                    );
                  }

                  // Klavye açılıp kapanırken mevcut veriyi göster
                  if (snapshot.connectionState == ConnectionState.waiting &&
                      snapshot.hasData) {
                    // Mevcut veriyi göster, loading gösterme
                    List messages = snapshot.data!.docs
                        .map((doc) => Message.fromSnapshot(doc))
                        .toList();
                    return ListView.builder(
                      key: _listKey,
                      itemCount: messages.length,
                      reverse: true,
                      padding: const EdgeInsets.only(bottom: 8),
                      physics: const BouncingScrollPhysics(),
                      itemBuilder: (context, index) {
                        final message = messages[index];
                        final isCurrentUser =
                            message.sender == widget.currentUserUid;
                        final isFirstMessage = index == messages.length - 1 ||
                            messages[index + 1].sender != message.sender;
                        final showDateHeader = index == messages.length - 1 ||
                            !_isSameDay(messages[index].timestamp,
                                messages[index + 1].timestamp);

                        return Column(
                          children: [
                            if (showDateHeader)
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16.0),
                                child: Center(
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[200],
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      _formatMessageDate(message.timestamp),
                                      style: GoogleFonts.poppins(
                                        color: Color(0xFF757575),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            Padding(
                              padding: EdgeInsets.only(
                                top: isFirstMessage ? 8 : 4,
                                bottom: 4,
                                left: 8,
                                right: 8,
                              ),
                              child: Align(
                                alignment: isCurrentUser
                                    ? Alignment.centerRight
                                    : Alignment.centerLeft,
                                child: Container(
                                  constraints: BoxConstraints(
                                    maxWidth:
                                        MediaQuery.of(context).size.width *
                                            0.75,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isCurrentUser
                                        ? AnimalColors.primary.withOpacity(0.18)
                                        : Colors.blueGrey.withOpacity(0.10),
                                    borderRadius: BorderRadius.only(
                                      topLeft: Radius.circular(
                                          isCurrentUser ? 16 : 4),
                                      topRight: Radius.circular(
                                          isCurrentUser ? 4 : 16),
                                      bottomLeft: Radius.circular(16),
                                      bottomRight: Radius.circular(16),
                                    ),
                                    border: Border.all(
                                      color: isCurrentUser
                                          ? AnimalColors.primary
                                              .withOpacity(0.35)
                                          : Colors.blueGrey.withOpacity(0.18),
                                      width: 1.2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: isCurrentUser
                                            ? AnimalColors.primary
                                                .withOpacity(0.08)
                                            : Colors.blueGrey.withOpacity(0.08),
                                        blurRadius: 8,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  child: Text(
                                    message.text,
                                    style: GoogleFonts.poppins(
                                      color: isCurrentUser
                                          ? Colors.white
                                          : Color(0xFF212121),
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    // Klavye açıksa hiçbir şey gösterme
                    if (MediaQuery.of(context).viewInsets.bottom > 0) {
                      return SizedBox.shrink();
                    }

                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AnimalColors.primary.withOpacity(0.08),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AnimalColors.primary.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Icon(
                              Icons.chat_bubble_outline_rounded,
                              color: AnimalColors.primary,
                              size: 24,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            "Henüz mesaj yok",
                            style: GoogleFonts.poppins(
                              color: Color(0xFF212121),
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  List messages = snapshot.data!.docs
                      .map((doc) => Message.fromSnapshot(doc))
                      .toList();
                  return ListView.builder(
                    key: _listKey,
                    itemCount: messages.length,
                    reverse: true,
                    padding: const EdgeInsets.only(bottom: 8),
                    physics: const BouncingScrollPhysics(),
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      final isCurrentUser =
                          message.sender == widget.currentUserUid;
                      final isFirstMessage = index == messages.length - 1 ||
                          messages[index + 1].sender != message.sender;
                      final showDateHeader = index == messages.length - 1 ||
                          !_isSameDay(messages[index].timestamp,
                              messages[index + 1].timestamp);

                      return Column(
                        children: [
                          if (showDateHeader)
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 16.0),
                              child: Center(
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[200],
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    _formatMessageDate(message.timestamp),
                                    style: GoogleFonts.poppins(
                                      color: Color(0xFF757575),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          Padding(
                            padding: EdgeInsets.only(
                              top: isFirstMessage ? 8 : 4,
                              bottom: 4,
                              left: 8,
                              right: 8,
                            ),
                            child: Align(
                              alignment: isCurrentUser
                                  ? Alignment.centerRight
                                  : Alignment.centerLeft,
                              child: Container(
                                constraints: BoxConstraints(
                                  maxWidth:
                                      MediaQuery.of(context).size.width * 0.75,
                                ),
                                decoration: BoxDecoration(
                                  color: isCurrentUser
                                      ? AnimalColors.primary.withOpacity(0.18)
                                      : Colors.blueGrey.withOpacity(0.10),
                                  borderRadius: BorderRadius.only(
                                    topLeft:
                                        Radius.circular(isCurrentUser ? 16 : 4),
                                    topRight:
                                        Radius.circular(isCurrentUser ? 4 : 16),
                                    bottomLeft: Radius.circular(16),
                                    bottomRight: Radius.circular(16),
                                  ),
                                  border: Border.all(
                                    color: isCurrentUser
                                        ? AnimalColors.primary.withOpacity(0.35)
                                        : Colors.blueGrey.withOpacity(0.18),
                                    width: 1.2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: isCurrentUser
                                          ? AnimalColors.primary
                                              .withOpacity(0.08)
                                          : Colors.blueGrey.withOpacity(0.08),
                                      blurRadius: 8,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      message.text,
                                      style: GoogleFonts.poppins(
                                        color: Color(0xFF212121),
                                        fontSize: 15,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          DateFormat('HH:mm').format(
                                              message.timestamp.toDate()),
                                          style: GoogleFonts.poppins(
                                            color: Color(0xFF757575),
                                            fontSize: 11,
                                          ),
                                        ),
                                        if (isCurrentUser) ...[
                                          SizedBox(width: 4),
                                          Icon(
                                            Icons.check_circle,
                                            size: 11,
                                            color: AnimalColors.primary
                                                .withOpacity(0.7),
                                          ),
                                        ]
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0xFFE9ECEF),
                          Color(0xFFF5F6FA),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(
                        color: Colors.grey.shade300,
                        width: 1.3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.12),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _textController,
                            textCapitalization: TextCapitalization.sentences,
                            cursorColor: AnimalColors.primary,
                            style:
                                GoogleFonts.poppins(color: Color(0xFF212121)),
                            decoration: InputDecoration(
                              hintText: "Mesaj yaz...",
                              hintStyle:
                                  GoogleFonts.poppins(color: Color(0xFF757575)),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.all(16),
                            ),
                          ),
                        ),
                        Material(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(25),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(25),
                            onTap: () {
                              if (_textController.text.isNotEmpty) {
                                _handleSubmitted(_textController.text);
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              margin: const EdgeInsets.only(right: 6),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    AnimalColors.primary,
                                    AnimalColors.secondary,
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.send_rounded,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _isSameDay(Timestamp timestamp1, Timestamp timestamp2) {
    final date1 = timestamp1.toDate();
    final date2 = timestamp2.toDate();
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  String _formatMessageDate(Timestamp timestamp) {
    final DateTime date = timestamp.toDate();
    final DateTime now = DateTime.now();
    final DateTime yesterday = DateTime.now().subtract(const Duration(days: 1));

    if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day) {
      return 'Today';
    } else if (date.year == yesterday.year &&
        date.month == yesterday.month &&
        date.day == yesterday.day) {
      return 'Yesterday';
    } else if (now.difference(date).inDays < 7) {
      switch (date.weekday) {
        case 1:
          return 'Monday';
        case 2:
          return 'Tuesday';
        case 3:
          return 'Wednesday';
        case 4:
          return 'Thursday';
        case 5:
          return 'Friday';
        case 6:
          return 'Saturday';
        case 7:
          return 'Sunday';
        default:
          return '';
      }
    } else {
      return DateFormat('dd MMMM, yyyy').format(date);
    }
  }

  void _handleSubmitted(String text) async {
    if (text.trim().isEmpty) return;

    _textController.clear();

    try {
      // 1. İnternet bağlantısını kontrol et
      bool hasInternet = await _checkInternetConnection();
      if (!hasInternet) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('İnternet bağlantısı yok. Mesaj gönderilemedi.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // 2. Gönderici bilgilerini logla
      String senderId = widget.currentUserUid;
      String recipientId = widget.recipientUid;

      print('💬 MESAJ GÖNDERİLİYOR:');
      print('→ Gönderen (sender): $senderId');
      print('→ Alıcı (recipient): $recipientId');

      // İOS için önemli: Alıcı token'ını kontrol et
      String? recipientToken = await _refreshAndGetRecipientToken(recipientId);
      if (recipientToken == null || recipientToken.isEmpty) {
        print('⚠️ Alıcı token bulunamadı. Bildirim gönderilmeyebilir.');
      } else {
        print('📱 Alıcı token: ${recipientToken.substring(0, 20)}...');
      }

      // 3. Kullanıcı adını al (bildirim için)
      String senderUsername = await _getSenderUsername();

      // 4. Mesajı Firestore'a ekle - timestamp'i server side oluştur
      DocumentReference messageRef =
          await FirebaseFirestore.instance.collection("conversations").add({
        "text": text,
        "sender": senderId,
        "recipient": recipientId,
        "timestamp": FieldValue.serverTimestamp(),
        "messagesId": conversationId,
        "users": [widget.currentUserUid, widget.recipientUid],
        "postId": widget.postId,
        "isRead": false, // Okunma durumu ekleyin
        "senderName": senderUsername, // iOS bildirimleri için önemli
        "notificationTitle": "$senderUsername", // iOS bildirimleri için önemli
        "notificationBody": text, // iOS bildirimleri için önemli
      });

      print('✅ Mesaj Firestore\'a eklendi: ${messageRef.id}');
      print(
          '✅ Cloud Function tetiklenmeli: bildirim $recipientId kullanıcısına gönderilecek');

      // 5. Mevcut kullanıcı token'ını güncelle
      await _updateCurrentUserToken();

      // 6. Ek işlemleri yap
      if (Platform.isAndroid) {
        reduceCredit();
      }

      // 7. Liste görünümünü güncelle
      setState(() {
        _listKey = UniqueKey();
      });

      // 8. İsteğe bağlı: Bildirim durumunu kontrol et
      Future.delayed(
          Duration(seconds: 5), () => _checkNotificationStatus(messageRef.id));
    } catch (e) {
      print('❌ Mesaj gönderme hatası: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Mesaj gönderilirken hata oluştu. Lütfen tekrar deneyin.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<String?> _refreshAndGetRecipientToken(String recipientId) async {
    try {
      // Alıcının belgesini al
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(recipientId)
          .get();

      if (!userDoc.exists) {
        print('⚠️ Alıcı kullanıcı bulunamadı!');
        return null;
      }

      // Alıcının mevcut token'ını al
      String? token = userDoc.get('fcmToken');

      if (token == null || token.isEmpty) {
        print(
            '⚠️ Alıcının token\'ı boş! Bu kullanıcı bildirimleri almayabilir.');
      }

      return token;
    } catch (e) {
      print('❌ Alıcı token yenileme hatası: $e');
      return null;
    }
  }

  // İsteğe bağlı: Bildirim durumunu kontrol et
  Future<void> _checkNotificationStatus(String messageId) async {
    try {
      // Firebase Functions log'larını kontrol etmeniz gerekecek
      print('📋 Bildirim durumu kontrol ediliyor: $messageId');
      // Bu kısımda Firebase Functions loglarını kontrol eden özel bir API kullanabilirsiniz
    } catch (e) {
      print('❌ Bildirim durumu kontrol hatası: $e');
    }
  }

  Future<String?> _loadUserToken(String uid) async {
    try {
      DocumentSnapshot userDoc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();

      if (userDoc.exists) {
        String? token = userDoc.get('fcmToken');
        print('Loaded token for user $uid: $token');
        return token;
      } else {
        print('User document does not exist');
      }
    } catch (e) {
      print('Error loading user token: $e');
    }
    return null;
  }

  Future<String> _getSenderUsername() async {
    try {
      DocumentSnapshot senderDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.currentUserUid)
          .get();

      if (senderDoc.exists) {
        return senderDoc.get('username') ?? "User";
      }
    } catch (e) {
      print('Error getting sender username: $e');
    }
    return "User";
  }

  // create conversation id if users is same doesnt matter who is first or second
  String getConversationId(String uid1, String uid2) {
    if (uid1.compareTo(uid2) > 0) {
      return uid1 + uid2;
    } else {
      return uid2 + uid1;
    }
  }

  // create conversation if it doesnt exist
  Future<void> createConversation(String conversationId) async {
    await FirebaseFirestore.instance
        .collection("conversations")
        .doc(conversationId)
        .set({
      "messagesId": conversationId,
    });
  }

  // add +1 to current user's credit, add -1 to recipient user's credit
  Future<void> updateCredit() async {
    // get current user's credit
    DocumentSnapshot doc = await FirebaseFirestore.instance
        .collection("users")
        .doc(widget.currentUserUid)
        .get();
    int credit = doc["credit"];
    // update current user's credit
    FirebaseFirestore.instance
        .collection("users")
        .doc(widget.currentUserUid)
        .update({
      "credit": credit + 1,
    });
    // get recipient user's credit
    DocumentSnapshot doc2 = await FirebaseFirestore.instance
        .collection("users")
        .doc(widget.recipientUid)
        .get();
    int credit2 = doc2["credit"];
    // update recipient user's credit
    FirebaseFirestore.instance
        .collection("users")
        .doc(widget.recipientUid)
        .update({
      "credit": credit2 - 1,
    });
  }

  void _showLocalNotification(
      String title, String body, Map<String, dynamic> data) {
    // Eğer bildirim GÖNDEREN şu anki kullanıcı ise, BİLDİRİM GÖSTERME
    if (data['sender_id'] == widget.currentUserUid) {
      print(
          'Bu bildirimi ben gönderdim, göstermiyorum: sender_id=${data['sender_id']}');
      return;
    }

    print('Lokal bildirim gösteriliyor: title=$title, body=$body');

    flutterLocalNotificationsPlugin.show(
      data.hashCode,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'messages_channel',
          'Mesajlar',
          channelDescription: 'Mesaj bildirimlerini gösterir',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: jsonEncode(data),
    );
  }

  void _navigateToMessageScreen(Map<String, dynamic> data) {
    try {
      // Veriyi çıkar
      String senderId = data['sender_id'] ?? '';
      String recipientId = data['recipient_id'] ?? '';
      String postId = data['post_id'] ?? '';

      // Geçerli kullanıcı alıcı ise, göndereni karşı taraf olarak ayarla
      String currentUid = widget.currentUserUid;
      String targetUid = currentUid == senderId ? recipientId : senderId;

      // Eğer zaten aynı konuşma ekranındaysak, yönlendirme yapma
      if (widget.recipientUid == targetUid && widget.postId == postId) {
        print('Already in the same conversation screen');
        return;
      }

      // Yeni mesaj ekranına yönlendir
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MessagesPage(
            currentUserUid: currentUid,
            recipientUid: targetUid,
            postId: postId,
          ),
        ),
      );
    } catch (e) {
      print('Error navigating to message screen: $e');
    }
  }

  void _getUserCountry() async {
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.currentUserUid)
          .get();

      if (userDoc.exists && mounted) {
        final data = userDoc.data() as Map<String, dynamic>?;
        setState(() {
          _userCountry = data?['country'] as String? ?? '';
        });
      }
    } catch (e) {
      print('Error getting user country: $e');
    }
  }

  Future<void> _updateCurrentUserToken() async {
    try {
      // 1. Internet kontrolü
      bool hasInternet = await _checkInternetConnection();
      if (!hasInternet) {
        print('⚠️ Internet bağlantısı yok, token güncellenemedi');
        return;
      }

      // 2. FCM Token al
      String? token = await FirebaseMessaging.instance.getToken();
      if (token == null || token.isEmpty) {
        print('⚠️ Geçerli FCM token alınamadı');
        return;
      }

      print('📱 Alınan FCM token: $token');

      // 3. Her durumda token'ı güncelle (değişmiş olmasa bile)
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.currentUserUid)
          .update({'fcmToken': token});

      print('✅ Token güncellendi: $token');
    } catch (e) {
      print('❌ Token güncelleme hatası: $e');
    }
  }

  Future<void> _validateTokens() async {
    try {
      DocumentSnapshot currentUserDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.currentUserUid)
          .get();

      DocumentSnapshot recipientUserDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.recipientUid)
          .get();

      String? currentUserToken = currentUserDoc.get('fcmToken');
      String? recipientUserToken = recipientUserDoc.get('fcmToken');

      print('🔍 Token Kontrolü:');
      print('→ Current User Token: ${currentUserToken?.substring(0, 20)}...');
      print(
          '→ Recipient User Token: ${recipientUserToken?.substring(0, 20)}...');

      if (currentUserToken == null || currentUserToken.isEmpty) {
        print('⚠️ UYARI: Mevcut kullanıcının token\'ı yok veya boş!');
        // Token'ı yenile
        await _forceUpdateToken(widget.currentUserUid);
      }

      if (recipientUserToken == null || recipientUserToken.isEmpty) {
        print('⚠️ UYARI: Alıcı kullanıcının token\'ı yok veya boş!');
      }
    } catch (e) {
      print('❌ Token doğrulama hatası: $e');
    }
  }

  Future<void> _forceUpdateToken(String uid) async {
    try {
      String? token = await FirebaseMessaging.instance.getToken();
      if (token != null && token.isNotEmpty) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .update({'fcmToken': token});
        print('✅ Token zorla güncellendi: $token');
      }
    } catch (e) {
      print('❌ Token zorla güncelleme hatası: $e');
    }
  }

  Future<void> _testNotification() async {
    try {
      DocumentSnapshot recipientDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.recipientUid)
          .get();

      if (!recipientDoc.exists) {
        print('❌ Alıcı kullanıcı bulunamadı');
        return;
      }

      String? recipientToken = recipientDoc.get('fcmToken');
      if (recipientToken == null || recipientToken.isEmpty) {
        print('❌ Alıcı token\'ı bulunamadı');
        return;
      }

      // Test mesajını Firestore'a ekleyin
      await FirebaseFirestore.instance.collection("conversations").add({
        "text": "Bu bir test mesajıdır",
        "sender": widget.currentUserUid,
        "recipient": widget.recipientUid,
        "timestamp": FieldValue.serverTimestamp(),
        "messagesId": conversationId,
        "users": [widget.currentUserUid, widget.recipientUid],
        "postId": widget.postId,
        "isTestMessage": true // Test mesajı olduğunu belirtin
      });

      print('✅ Test mesajı başarıyla gönderildi. Cloud Function tetiklenmeli.');
    } catch (e) {
      print('❌ Test bildirimi gönderme hatası: $e');
    }
  }

  Future<void> _sendTestNotification() async {
    try {
      print('📣 Test bildirimi gönderiliyor...');

      final functions = FirebaseFunctions.instance;
      final callable = functions.httpsCallable('sendTestNotification');

      final result = await callable.call({
        'recipientId': widget.recipientUid,
      });

      if (result.data['success'] == true) {
        print('✅ Test bildirimi başarıyla gönderildi!');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Test bildirimi gönderildi'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        print('❌ Test bildirimi başarısız: ${result.data['error']}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Test bildirimi başarısız: ${result.data['error']}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('❌ Test bildirimi gönderme hatası: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Hata: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildProductCard() {
    // Veteriner konuşması ise hayvan kartı gösterme
    if (_isVeterinarianConversation) {
      return const SizedBox.shrink();
    }

    return FutureBuilder<DocumentSnapshot>(
      future: _getProductData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Stack(
              children: [
                // Glassmorphism arka plan
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.white.withOpacity(0.9),
                            AnimalColors.primary.withOpacity(0.05),
                            AnimalColors.secondary.withOpacity(0.05),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AnimalColors.primary.withOpacity(0.06),
                            blurRadius: 12,
                            offset: Offset(0, 4),
                          ),
                        ],
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 12, horizontal: 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Fotoğraf shimmer
                            Shimmer.fromColors(
                              baseColor: Colors.grey[300]!,
                              highlightColor: Colors.grey[100]!,
                              child: Container(
                                width: 70,
                                height: 70,
                                decoration: BoxDecoration(
                                  color: Colors.grey[300],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Bilgiler shimmer
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Kategori shimmer
                                  Shimmer.fromColors(
                                    baseColor: Colors.grey[300]!,
                                    highlightColor: Colors.grey[100]!,
                                    child: Container(
                                      width: 80,
                                      height: 20,
                                      decoration: BoxDecoration(
                                        color: Colors.grey[300],
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  // Başlık shimmer
                                  Shimmer.fromColors(
                                    baseColor: Colors.grey[300]!,
                                    highlightColor: Colors.grey[100]!,
                                    child: Container(
                                      width: 120,
                                      height: 16,
                                      decoration: BoxDecoration(
                                        color: Colors.grey[300],
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: 3),
                                  // Fiyat shimmer
                                  Shimmer.fromColors(
                                    baseColor: Colors.grey[300]!,
                                    highlightColor: Colors.grey[100]!,
                                    child: Container(
                                      width: 60,
                                      height: 18,
                                      decoration: BoxDecoration(
                                        color: Colors.grey[300],
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: 3),
                                  // Alt bilgi shimmer
                                  Row(
                                    children: [
                                      Shimmer.fromColors(
                                        baseColor: Colors.grey[300]!,
                                        highlightColor: Colors.grey[100]!,
                                        child: Container(
                                          width: 50,
                                          height: 16,
                                          decoration: BoxDecoration(
                                            color: Colors.grey[300],
                                            borderRadius:
                                                BorderRadius.circular(6),
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: 4),
                                      Shimmer.fromColors(
                                        baseColor: Colors.grey[300]!,
                                        highlightColor: Colors.grey[100]!,
                                        child: Container(
                                          width: 40,
                                          height: 16,
                                          decoration: BoxDecoration(
                                            color: Colors.grey[300],
                                            borderRadius:
                                                BorderRadius.circular(6),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                // Favori butonu shimmer
                Positioned(
                  top: 8,
                  right: 8,
                  child: Shimmer.fromColors(
                    baseColor: Colors.grey[300]!,
                    highlightColor: Colors.grey[100]!,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
                // Detay butonu shimmer
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: Shimmer.fromColors(
                    baseColor: Colors.grey[300]!,
                    highlightColor: Colors.grey[100]!,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
          return Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.red.withOpacity(0.3),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withOpacity(0.10),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, color: Colors.red, size: 22),
                SizedBox(width: 12),
                Flexible(
                  child: Text(
                    "Bu ilan kaldırılmış veya mevcut değil",
                    style: GoogleFonts.poppins(
                        color: Colors.red,
                        fontSize: 15,
                        fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          );
        }

        final data = snapshot.data!.data() as Map<String, dynamic>;
        final isAnimal = data.containsKey('animalType');
        final List likes = data['likes'] ?? [];
        final bool isLikedInitial = likes.contains(widget.currentUserUid);
        // Favori butonu için local state
        ValueNotifier<bool> isLikedNotifier = ValueNotifier(isLikedInitial);
        ValueNotifier<bool> likeError = ValueNotifier(false);

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Stack(
            children: [
              // Glassmorphism arka plan
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withOpacity(0.9),
                          AnimalColors.primary.withOpacity(0.05),
                          AnimalColors.secondary.withOpacity(0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AnimalColors.primary.withOpacity(0.06),
                          blurRadius: 12,
                          offset: Offset(0, 4),
                        ),
                      ],
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Fotoğraf
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              _getImageUrl(data, isAnimal),
                              width: 70,
                              height: 70,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  width: 70,
                                  height: 70,
                                  color: Colors.grey[200],
                                  child: Icon(
                                    isAnimal
                                        ? Icons.pets
                                        : Icons.image_not_supported,
                                    color: Colors.grey[400],
                                    size: 24,
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Bilgiler
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Kategori chip
                                Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color:
                                        AnimalColors.primary.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.pets,
                                          size: 12,
                                          color: AnimalColors.primary),
                                      SizedBox(width: 3),
                                      Text(_getCategory(data, isAnimal),
                                          style: GoogleFonts.poppins(
                                              fontSize: 10,
                                              color: AnimalColors.primary)),
                                    ],
                                  ),
                                ),
                                SizedBox(height: 4),
                                // Başlık
                                Text(
                                  _getTitle(data, isAnimal),
                                  style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF212121)),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                SizedBox(height: 3),
                                // Fiyat
                                Row(
                                  children: [
                                    Text(
                                      isAnimal && data['priceInTL'] != null
                                          ? PricingService.formatPrice(
                                              data['priceInTL'].toDouble())
                                          : '',
                                      style: GoogleFonts.poppins(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: AnimalColors.primary),
                                    ),
                                    if (isAnimal &&
                                        (data['isNegotiable'] ?? false))
                                      Container(
                                        margin: EdgeInsets.only(left: 6),
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AnimalColors.accent
                                              .withOpacity(0.25),
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: Text('Pazarlık',
                                            style: GoogleFonts.poppins(
                                                fontSize: 9,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.black)),
                                      ),
                                  ],
                                ),
                                SizedBox(height: 3),
                                // Alt bilgi chipleri
                                Wrap(
                                  spacing: 4,
                                  runSpacing: 2,
                                  children: [
                                    if (data['city'] != null &&
                                        data['city'].toString().isNotEmpty)
                                      _infoChip(Icons.location_on,
                                          _getLocation(data)),
                                    if (isAnimal && data['ageInMonths'] != null)
                                      _infoChip(Icons.cake,
                                          '${data['ageInMonths']} ay'),
                                    if (isAnimal && data['weightInKg'] != null)
                                      _infoChip(Icons.monitor_weight,
                                          '${data['weightInKg']} kg'),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              // Favori butonu
              Positioned(
                top: 8,
                right: 8,
                child: ValueListenableBuilder<bool>(
                  valueListenable: isLikedNotifier,
                  builder: (context, isLiked, _) {
                    return Material(
                      color: Colors.white,
                      shape: CircleBorder(),
                      elevation: 1,
                      child: IconButton(
                        icon: Icon(
                          isLiked ? Icons.favorite : Icons.favorite_border,
                          color: isLiked ? Colors.red : AnimalColors.primary,
                          size: 18,
                        ),
                        onPressed: () async {
                          final prev = isLikedNotifier.value;
                          isLikedNotifier.value = !prev; // Optimistic update
                          try {
                            print(
                                'Favori işlemi başlatıldı - PostId: ${widget.postId}');

                            // Önce animals koleksiyonunda dene
                            DocumentReference docRef = FirebaseFirestore
                                .instance
                                .collection('animals')
                                .doc(widget.postId);

                            // Eğer animals'da yoksa posts koleksiyonunda dene
                            final animalDoc = await docRef.get();
                            if (!animalDoc.exists) {
                              print(
                                  'Animals koleksiyonunda bulunamadı, posts koleksiyonunda aranıyor');
                              docRef = FirebaseFirestore.instance
                                  .collection('posts')
                                  .doc(widget.postId);
                            } else {
                              print('Animals koleksiyonunda bulundu');
                            }

                            if (prev) {
                              print('Favorilerden çıkarılıyor');
                              await docRef.update({
                                'likes': FieldValue.arrayRemove(
                                    [widget.currentUserUid])
                              });
                            } else {
                              print('Favorilere ekleniyor');
                              await docRef.update({
                                'likes': FieldValue.arrayUnion(
                                    [widget.currentUserUid])
                              });
                            }

                            print('Favori işlemi başarılı');
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(prev
                                    ? 'Favorilerden çıkarıldı'
                                    : 'Favorilere eklendi'),
                                backgroundColor: Colors.green,
                                duration: Duration(seconds: 1),
                              ),
                            );
                          } catch (e) {
                            print('Favori işlemi hatası: $e');
                            isLikedNotifier.value = prev; // Revert on error
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Favori işlemi başarısız: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                      ),
                    );
                  },
                ),
              ),
              // Detay butonu
              Positioned(
                bottom: 8,
                right: 8,
                child: FloatingActionButton(
                  mini: true,
                  backgroundColor: AnimalColors.primary,
                  child:
                      Icon(Icons.arrow_forward, color: Colors.white, size: 16),
                  onPressed: () => _navigateToDetailScreen(isAnimal, data),
                  elevation: 2,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<DocumentSnapshot> _getProductData() async {
    // Veteriner konuşması ise null döndür
    if (_isVeterinarianConversation) {
      throw Exception('Veteriner konuşması - hayvan bilgisi gerekmez');
    }

    try {
      // First try to get from animals collection
      final animalDoc = await FirebaseFirestore.instance
          .collection('animals')
          .doc(widget.postId)
          .get();

      if (animalDoc.exists) {
        return animalDoc;
      }

      // If not found in animals, try posts collection
      final postDoc = await FirebaseFirestore.instance
          .collection('posts')
          .doc(widget.postId)
          .get();

      return postDoc;
    } catch (e) {
      print('Error getting product data: $e');
      rethrow;
    }
  }

  String _getImageUrl(Map<String, dynamic> data, bool isAnimal) {
    if (isAnimal) {
      final photoUrls = data['photoUrls'] as List<dynamic>?;
      if (photoUrls != null && photoUrls.isNotEmpty) {
        return photoUrls[0];
      }
    } else {
      final postUrl = data['postUrl'] as String?;
      if (postUrl != null && postUrl.isNotEmpty) {
        return postUrl;
      }
    }
    return '';
  }

  String _getTitle(Map<String, dynamic> data, bool isAnimal) {
    if (isAnimal) {
      final species = data['animalSpecies'] ?? '';
      final breed = data['animalBreed'] ?? '';
      if (species.isNotEmpty && breed.isNotEmpty) {
        return '$species - $breed';
      }
      return species.isNotEmpty ? species : 'Hayvan';
    } else {
      return data['title'] ?? data['category'] ?? 'Unknown Item';
    }
  }

  String _getCategory(Map<String, dynamic> data, bool isAnimal) {
    if (isAnimal) {
      final animalType = data['animalType'] ?? '';
      final purpose = data['purpose'] ?? '';
      if (animalType.isNotEmpty && purpose.isNotEmpty) {
        return '$animalType - $purpose';
      }
      return animalType.isNotEmpty ? animalType : 'Hayvan';
    } else {
      return data['category'] ?? 'Item';
    }
  }

  String _getLocation(Map<String, dynamic> data) {
    final itemCountry = data['country'] as String? ?? '';
    final itemState = data['state'] as String? ?? '';
    final itemCity = data['city'] as String? ?? '';

    // Eğer kullanıcının ülkesi ile ilanın ülkesi aynıysa
    if (_userCountry.isNotEmpty && _userCountry == itemCountry) {
      // Şehir varsa sadece şehir göster
      if (itemCity.isNotEmpty) {
        return itemCity;
      }
      // Şehir yoksa il göster
      else if (itemState.isNotEmpty) {
        return itemState;
      }
      // İkisi de yoksa ülke göster
      else {
        return itemCountry;
      }
    }
    // Eğer ülkeler farklıysa veya kullanıcının ülkesi bilinmiyorsa
    else {
      return [
        if (itemCity.isNotEmpty) itemCity,
        if (itemState.isNotEmpty) itemState,
        if (itemCountry.isNotEmpty) itemCountry,
      ].where((e) => e.isNotEmpty).join(", ");
    }
  }

  void _navigateToDetailScreen(bool isAnimal, Map<String, dynamic> data) {
    if (isAnimal) {
      try {
        final animal = AnimalPost.fromMap(data);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AnimalDetailScreen(animal: animal),
          ),
        );
      } catch (e) {
        print('Error creating AnimalPost: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error opening animal details')),
        );
      }
    }
    // Post screen kaldırıldı, sadece hayvan detayları gösteriliyor
  }

  Widget _buildSaleButton() {
    // Veteriner konuşması ise hayvan satış butonu gösterme
    if (_isVeterinarianConversation) {
      return const SizedBox.shrink();
    }

    // Sadece animals koleksiyonunu kontrol et
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('animals')
          .doc(widget.postId)
          .snapshots(),
      builder: (context, animalSnapshot) {
        print('🔍 Animal Sale Button Debug:');
        print('  - Post ID: ${widget.postId}');
        print('  - Current User: ${widget.currentUserUid}');
        print('  - Has Data: ${animalSnapshot.hasData}');
        print(
            '  - Document Exists: ${animalSnapshot.hasData ? animalSnapshot.data!.exists : 'No data'}');

        if (!animalSnapshot.hasData || !animalSnapshot.data!.exists) {
          print('  - No animal data found, hiding button');
          return const SizedBox.shrink();
        }

        final data = animalSnapshot.data!.data() as Map<String, dynamic>?;
        if (data == null) {
          print('  - Animal data is null, hiding button');
          return const SizedBox.shrink();
        }

        final String sellerId = data['uid'] ?? '';
        final String saleStatus = data['saleStatus'] ?? 'active';
        final bool isCurrentUserSeller = sellerId == widget.currentUserUid;

        print('  - Seller ID: $sellerId');
        print('  - Sale Status: $saleStatus');
        print('  - Is Current User Seller: $isCurrentUserSeller');

        // Sadece satıcı için göster ve hayvan aktif durumda olmalı
        if (!isCurrentUserSeller || saleStatus != 'active') {
          print('  - Not seller or not active, hiding button');
          return const SizedBox.shrink();
        }

        print('  - Showing sale button');
        return _buildSaleButtonUI();
      },
    );
  }

  Widget _buildVeterinarianInfoCard() {
    if (!_isVeterinarianConversation || _veterinarianData == null) {
      return const SizedBox.shrink();
    }

    final clinicName = _veterinarianData!['veterinarianClinicName'] ?? '';
    final phone = _veterinarianData!['veterinarianPhone'] ?? '';
    final emergencyPhone =
        _veterinarianData!['veterinarianEmergencyPhone'] ?? '';
    final consultationFee = _veterinarianData!['veterinarianConsultationFee'];
    final specializations = List<String>.from(
        _veterinarianData!['veterinarianSpecializations'] ?? []);
    final cities =
        List<String>.from(_veterinarianData!['veterinarianCities'] ?? []);
    final available = _veterinarianData!['veterinarianAvailable'] ?? false;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.local_hospital, color: Colors.green, size: 24),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  clinicName.isNotEmpty ? clinicName : 'Veteriner Klinik',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                  maxLines: 2,
                  softWrap: true,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: available ? Colors.green : Colors.grey,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  available ? 'Müsait' : 'Meşgul',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (consultationFee != null)
            Row(
              children: [
                Icon(Icons.attach_money, color: Colors.orange, size: 16),
                const SizedBox(width: 4),
                Text(
                  'Muayene: ${PricingService.formatPrice(consultationFee.toDouble())}',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          if (specializations.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.medical_services, color: Colors.blue, size: 16),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Uzmanlık: ${specializations.take(4).join(', ')}',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                    maxLines: 3,
                    softWrap: true,
                  ),
                ),
              ],
            ),
          ],
          if (cities.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.location_on, color: Colors.red, size: 16),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Hizmet: ${cities.take(4).join(', ')}',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                    maxLines: 3,
                    softWrap: true,
                  ),
                ),
              ],
            ),
          ],
          if (phone.isNotEmpty || emergencyPhone.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                if (phone.isNotEmpty)
                  Expanded(
                    child: GestureDetector(
                      onTap: () async {
                        final phoneUrl = 'tel:$phone';
                        try {
                          if (await canLaunchUrl(Uri.parse(phoneUrl))) {
                            await launchUrl(Uri.parse(phoneUrl));
                          } else {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                      'Telefon arama başlatılamadı: $phone'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content:
                                    Text('Arama sırasında hata oluştu: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.phone, color: Colors.white, size: 16),
                            const SizedBox(width: 8),
                            Text(
                              'Ara',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                if (phone.isNotEmpty && emergencyPhone.isNotEmpty)
                  const SizedBox(width: 8),
                if (emergencyPhone.isNotEmpty)
                  Expanded(
                    child: GestureDetector(
                      onTap: () async {
                        final phoneUrl = 'tel:$emergencyPhone';
                        try {
                          if (await canLaunchUrl(Uri.parse(phoneUrl))) {
                            await launchUrl(Uri.parse(phoneUrl));
                          } else {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                      'Acil telefon arama başlatılamadı: $emergencyPhone'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                    'Acil arama sırasında hata oluştu: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.emergency,
                                color: Colors.white, size: 16),
                            const SizedBox(width: 8),
                            Text(
                              'Acil Ara',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSaleButtonUI() {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: PopupMenuButton<String>(
        icon: Icon(
          Icons.more_vert,
          color: Colors.white,
        ),
        color: Color(0xFF2A2A2A),
        onSelected: (value) {
          if (value == 'mark_sold') {
            _showMarkAsSoldDialog();
          }
        },
        itemBuilder: (context) => [
          PopupMenuItem(
            value: 'mark_sold',
            child: Row(
              children: [
                Icon(
                  Icons.check_circle_outline,
                  color: Colors.green[400],
                  size: 20,
                ),
                SizedBox(width: 8),
                Text(
                  'Satıldı Olarak İşaretle',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDebugButton() {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: IconButton(
        icon: Icon(
          Icons.bug_report,
          color: Colors.orange,
        ),
        onPressed: () async {
          await _createTestAnimalPost();
        },
      ),
    );
  }

  void _showMarkAsSoldDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(
              Icons.check_circle_outline,
              color: Colors.green[400],
              size: 24,
            ),
            SizedBox(width: 8),
            Text(
              "Satış Onayı",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Hayvanınızı ${recipientUser?.username ?? 'Bu kullanıcı'} adlı kişiye sattığınızı onaylıyor musunuz?",
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.orange.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.orange,
                    size: 16,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Bu işlem sonrasında alıcı sizin hakkınızda değerlendirme yapabilecek.",
                      style: TextStyle(
                        color: Colors.orange,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey,
            ),
            child: Text(
              "İptal",
              style: TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _markAnimalAsSold();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[600],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 10,
              ),
            ),
            child: Text(
              "Onayla",
              style: TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _markAnimalAsSold() async {
    try {
      print('🔄 Marking animal as sold...');
      print('  - Animal ID: ${widget.postId}');
      print('  - Seller ID: ${widget.currentUserUid}');
      print('  - Buyer ID: ${widget.recipientUid}');

      // Sadece animals koleksiyonunu kullan
      final result = await AnimalSaleService().markAnimalAsSold(
        animalId: widget.postId,
        sellerId: widget.currentUserUid,
        buyerId: widget.recipientUid,
      );

      print('  - Result: $result');

      if (result == "success") {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: Colors.white,
                ),
                SizedBox(width: 8),
                Text("Hayvan satıldı olarak işaretlendi"),
              ],
            ),
            backgroundColor: Colors.green[600],
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        throw Exception(result);
      }
    } catch (e) {
      print('❌ Error marking animal as sold: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                Icons.error_outline,
                color: Colors.white,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text("Hata: $e"),
              ),
            ],
          ),
          backgroundColor: Colors.red[600],
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _createTestAnimalPost() async {
    try {
      print('🔧 Creating test animal post...');

      // Test animal post'u oluştur
      final testAnimal = {
        'animalId': widget.postId,
        'description': 'Test hayvan ilanı',
        'uid': widget.currentUserUid,
        'username': 'Test User',
        'datePublished': FieldValue.serverTimestamp(),
        'photoUrls': ['https://example.com/test.jpg'],
        'profImage': '',
        'country': 'Türkiye',
        'state': 'İstanbul',
        'city': 'İstanbul',
        'animalType': 'büyükbaş',
        'animalSpecies': 'Sığır',
        'animalBreed': 'Holstein',
        'ageInMonths': 24,
        'gender': 'Dişi',
        'weightInKg': 450.0,
        'priceInTL': 15000.0,
        'healthStatus': 'Sağlıklı',
        'vaccinations': ['Şap', 'Brucellla'],
        'purpose': 'Süt',
        'isPregnant': false,
        'birthDate': DateTime.now().subtract(Duration(days: 365 * 2)),
        'parentInfo': null,
        'certificates': [],
        'isNegotiable': true,
        'sellerType': 'Bireysel',
        'transportInfo': 'Nakliye mevcut',
        'isUrgentSale': false,
        'veterinarianContact': null,
        'additionalInfo': {},
        'likes': [],
        'saved': [],
        'isActive': true,
        'saleStatus': 'active',
        'buyerUid': null,
        'soldDate': null,
        'hasRating': false,
        'canBeRated': false,
      };

      // Firestore'a kaydet
      await FirebaseFirestore.instance
          .collection('animals')
          .doc(widget.postId)
          .set(testAnimal);

      print('✅ Test animal post created successfully');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Test hayvan ilanı oluşturuldu'),
          backgroundColor: Colors.green[600],
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      print('❌ Error creating test animal post: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Test hayvan ilanı oluşturulamadı: $e'),
          backgroundColor: Colors.red[600],
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

class Message {
  String text;
  String sender;
  String recipient;
  Timestamp timestamp;
  String messagesId;
  List<String> users = [];
  String postId;
  Message(
      {required this.text,
      required this.sender,
      required this.recipient,
      required this.timestamp,
      required this.messagesId,
      required this.users,
      required this.postId});

  Message.fromSnapshot(DocumentSnapshot snapshot)
      : text = (snapshot.data() as Map<String, dynamic>?)?["text"] ?? "",
        postId = (snapshot.data() as Map<String, dynamic>?)?["postId"] ?? "",
        sender = (snapshot.data() as Map<String, dynamic>?)?["sender"] ?? "",
        recipient =
            (snapshot.data() as Map<String, dynamic>?)?["recipient"] ?? "",
        timestamp = (snapshot.data() as Map<String, dynamic>?)?["timestamp"] ??
            Timestamp.now(),
        messagesId =
            (snapshot.data() as Map<String, dynamic>?)?["messagesId"] ?? "",
        users = (snapshot.data() as Map<String, dynamic>?)?["users"] != null
            ? List<String>.from(
                (snapshot.data() as Map<String, dynamic>)["users"])
            : [];

  Map<String, dynamic> toMap() {
    return {
      "text": text,
      "sender": sender,
      "recipient": recipient,
      "timestamp": timestamp,
      "messagesId": messagesId,
      "users": users,
      postId: postId,
    };
  }

  // json
  Map<String, dynamic> toJson() => {
        "text": text,
        "sender": sender,
        "recipient": recipient,
        "timestamp": timestamp,
        "messagesId": messagesId,
        "users": users,
        "postId": postId,
      };
}

// Ekstra: Alt bilgi chip fonksiyonu
Widget _infoChip(IconData icon, String text) {
  return Container(
    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(
      color: Colors.grey[100],
      borderRadius: BorderRadius.circular(6),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 11, color: AnimalColors.primary),
        SizedBox(width: 2),
        Text(text,
            style: GoogleFonts.poppins(fontSize: 10, color: Color(0xFF212121))),
      ],
    ),
  );
}

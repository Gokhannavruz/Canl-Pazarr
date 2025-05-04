import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:freecycle/screens/profile_screen2.dart';
import 'package:freecycle/screens/post_screen.dart';
import 'package:intl/intl.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:freecycle/utils/store_review_helper.dart';

import '../models/user.dart';

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

  // Lokal bildirimler için plugin
  late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;

  late String conversationId =
      widget.currentUserUid.hashCode <= widget.recipientUid.hashCode
          ? "${widget.currentUserUid}-${widget.recipientUid}"
          : "${widget.recipientUid}-${widget.currentUserUid}";

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
      backgroundColor: Colors.black,
      appBar: AppBar(
        toolbarHeight: 70,
        elevation: 0,
        backgroundColor: Color(0xFF1A1A1A),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
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
                            color: Colors.white.withOpacity(0.2), width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.shade900.withOpacity(0.2),
                            blurRadius: 10,
                            spreadRadius: 0,
                          )
                        ]),
                    child: CircleAvatar(
                      radius: 20,
                      backgroundImage:
                          NetworkImage(recipientUser!.photoUrl ?? ''),
                      backgroundColor: Colors.grey[900],
                      onBackgroundImageError: (exception, stackTrace) {
                        // Handle image loading error
                      },
                      child: recipientUser!.photoUrl == null ||
                              recipientUser!.photoUrl!.isEmpty
                          ? Icon(Icons.person, color: Colors.white, size: 24)
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
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              if (recipientUser!.isPremium == true)
                                Padding(
                                  padding: const EdgeInsets.only(left: 6),
                                  child: Icon(
                                    Icons.verified_rounded,
                                    size: 16,
                                    color: Colors.blue[400],
                                  ),
                                ),
                            ],
                          ),
                          Text(
                            recipientUser!.isPremium == true
                                ? "Premium User"
                                : "Online",
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[400],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              )
            : null,
      ),
      body: Container(
        decoration: BoxDecoration(
          color: Colors.black,
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1A1A1A),
              Colors.black,
            ],
          ),
        ),
        child: Column(
          children: [
            if (widget.postId.isNotEmpty)
              StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('posts')
                    .doc(widget.postId)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return Container(
                      margin: const EdgeInsets.all(12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.orange.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.info_outline,
                              color: Colors.orange, size: 20),
                          SizedBox(width: 12),
                          Flexible(
                            child: Text(
                              "Loading post information...",
                              style:
                                  TextStyle(color: Colors.orange, fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  if (!snapshot.data!.exists) {
                    return Container(
                      margin: const EdgeInsets.all(12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.red.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.error_outline,
                              color: Colors.red, size: 20),
                          SizedBox(width: 12),
                          Flexible(
                            child: Text(
                              "This product has been removed or is no longer available",
                              style: TextStyle(color: Colors.red, fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  final data = snapshot.data!.data() as Map<String, dynamic>?;

                  // Check if data is null or if required fields are missing
                  if (data == null ||
                      !data.containsKey('postUrl') ||
                      !data.containsKey('category')) {
                    return Container(
                      margin: const EdgeInsets.all(12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.red.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.error_outline,
                              color: Colors.red, size: 20),
                          SizedBox(width: 12),
                          Flexible(
                            child: Text(
                              "This product has been removed or is no longer available",
                              style: TextStyle(color: Colors.red, fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return Container(
                    margin: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.blue.withOpacity(0.08),
                          Colors.purple.withOpacity(0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.1),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Product Image with improved presentation
                              Hero(
                                tag: 'product-${widget.postId}',
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => PostScreen(
                                            postId: widget.postId,
                                            uid: PostUid,
                                          ),
                                        ),
                                      );
                                    },
                                    borderRadius: BorderRadius.circular(12),
                                    child: Container(
                                      height: 80,
                                      width: 80,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow: [
                                          BoxShadow(
                                            color:
                                                Colors.black.withOpacity(0.2),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Image.network(
                                          data['postUrl'],
                                          height: 80,
                                          width: 80,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) {
                                            return Container(
                                              height: 80,
                                              width: 80,
                                              color: Colors.grey[800],
                                              child: const Icon(
                                                  Icons.image_not_supported,
                                                  color: Colors.white54),
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              // Product Information with better organization
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // Add title if available, otherwise use category
                                    Text(
                                      data['title'] ??
                                          data['category'] ??
                                          'Unknown Item',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: -0.3,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 2,
                                    ),
                                    const SizedBox(height: 4),
                                    // Category as a tag if title was used
                                    if (data['title'] != null &&
                                        data['category'] != null)
                                      Container(
                                        margin:
                                            EdgeInsets.only(top: 2, bottom: 6),
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: Colors.blue.withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(6),
                                          border: Border.all(
                                            color: Colors.blue.withOpacity(0.2),
                                            width: 1,
                                          ),
                                        ),
                                        child: Text(
                                          data['category'],
                                          style: TextStyle(
                                            color: Colors.blue[300],
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    // Location with icon
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.location_on_rounded,
                                          size: 12,
                                          color: Colors.white.withOpacity(0.5),
                                        ),
                                        SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            [
                                              if (data['city']?.isNotEmpty ??
                                                  false)
                                                data['city'],
                                              if (data['state']?.isNotEmpty ??
                                                  false)
                                                data['state'],
                                              if (data['country']?.isNotEmpty ??
                                                  false)
                                                data['country'],
                                            ]
                                                .where((e) =>
                                                    e != null && e.isNotEmpty)
                                                .join(", "),
                                            style: TextStyle(
                                              color:
                                                  Colors.white.withOpacity(0.6),
                                              fontSize: 13,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1,
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
                        // View Product button
                        Padding(
                          padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                          child: Row(
                            children: [
                              const Spacer(),
                              Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => PostScreen(
                                          postId: widget.postId,
                                          uid: PostUid,
                                        ),
                                      ),
                                    );
                                  },
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.transparent,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.2),
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.visibility_outlined,
                                          size: 14,
                                          color: Colors.white.withOpacity(0.8),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          "View Item",
                                          style: TextStyle(
                                            color:
                                                Colors.white.withOpacity(0.8),
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            if (PostUid == currentUserUid)
              StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('posts')
                    .doc(widget.postId)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const SizedBox.shrink();

                  final data = snapshot.data!.data() as Map<String, dynamic>?;
                  if (data == null) return const SizedBox.shrink();

                  final bool isGiven = data['isGiven'] ?? false;

                  return Container(
                    width: MediaQuery.of(context).size.width - 24,
                    margin:
                        const EdgeInsets.only(left: 12, right: 12, bottom: 12),
                    child: isGiven
                        ? Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.green.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.check_circle_outline,
                                  color: Colors.green,
                                  size: 16,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  "Item Given",
                                  style: TextStyle(
                                    color: Colors.green,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : Container(
                            width: MediaQuery.of(context).size.width - 24,
                            alignment: Alignment.center,
                            child: TextButton(
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    backgroundColor: Color(0xFF1E1E1E),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    title: const Text(
                                      "Confirm Item Transfer",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    content: const Text(
                                      "Are you sure you want to mark this item as given?",
                                      style: TextStyle(color: Colors.white70),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        style: TextButton.styleFrom(
                                          foregroundColor: Colors.grey,
                                        ),
                                        child: const Text(
                                          "Cancel",
                                          style: TextStyle(
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.green,
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 10,
                                          ),
                                        ),
                                        onPressed: () {
                                          Navigator.pop(context);
                                          FirebaseFirestore.instance
                                              .collection("posts")
                                              .doc(widget.postId)
                                              .update({"isGiven": true});
                                          updateCredit();
                                        },
                                        child: const Text(
                                          "Confirm",
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                backgroundColor: Colors.blue.withOpacity(0.1),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(
                                    color: Colors.blue.withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.check_circle_outline,
                                    color: Colors.blue[400],
                                    size: 16,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    "Mark as Given",
                                    style: TextStyle(
                                      color: Colors.blue[400],
                                      fontWeight: FontWeight.w500,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                  );
                },
              ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection("conversations")
                      .where("messagesId", isEqualTo: conversationId)
                      .orderBy("timestamp", descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: Colors.white54,
                        ),
                      );
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.1),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.blue.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Icon(
                                Icons.chat_bubble_outline_rounded,
                                color: Colors.blue[400],
                                size: 40,
                              ),
                            ),
                            SizedBox(height: 16),
                            Text(
                              "No messages yet",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              "Send a message to start the conversation",
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 14,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
                    }

                    List<Message> messages = snapshot.data!.docs
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
                                      color: Colors.grey[900],
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      _formatMessageDate(message.timestamp),
                                      style: TextStyle(
                                        color: Colors.grey[400],
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
                                        ? Colors.blue[700]
                                        : Colors.grey[850],
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
                                          ? Colors.blue.withOpacity(0.3)
                                          : Colors.grey[800]!,
                                      width: 1,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        message.text,
                                        style: TextStyle(
                                          color: Colors.white,
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
                                            style: TextStyle(
                                              color: isCurrentUser
                                                  ? Colors.white
                                                      .withOpacity(0.7)
                                                  : Colors.grey[400],
                                              fontSize: 11,
                                            ),
                                          ),
                                          if (isCurrentUser) ...[
                                            SizedBox(width: 4),
                                            Icon(
                                              Icons.check_circle,
                                              size: 11,
                                              color:
                                                  Colors.white.withOpacity(0.7),
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
            ),
            Container(
              margin: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: Colors.white.withOpacity(0.1),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 8,
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
                      cursorColor: Colors.white,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: "Type a message...",
                        hintStyle: TextStyle(color: Colors.grey[400]),
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
                              Colors.blue[700]!,
                              Colors.blue[400]!,
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

      // Check if this is the first message in the conversation and show review if appropriate
      if (Platform.isIOS) {
        _checkAndShowReview();
      }
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

  Future<void> _checkAndShowReview() async {
    // Wait for 3 seconds after sending the message
    await Future.delayed(const Duration(seconds: 3));

    // Check if we should show a review prompt after messaging
    bool shouldShow = await StoreReviewHelper.shouldRequestReviewAfterMessage();
    if (shouldShow) {
      // Request a review using Apple's SKStoreReviewController
      await StoreReviewHelper.requestReview();

      // Mark that we've shown the review request
      await StoreReviewHelper.markMessageReviewRequested();
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

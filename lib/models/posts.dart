import 'package:cloud_firestore/cloud_firestore.dart';

class Post {
  final String description;
  final String uid;
  final String username;
  final likes;
  final String postId;
  final DateTime datePublished;
  final String postUrl;
  final String profImage;
  final String? recipient;
  final List saved;
  final String whoSent;
  double giftPoint = 0;
  final String country;
  final String state;
  final String city;
  final String category;
  bool isGiven = false;
  bool isWanted = false;

  Post({
    this.recipient,
    required this.description,
    required this.uid,
    required this.username,
    required this.likes,
    required this.postId,
    required this.datePublished,
    required this.postUrl,
    required this.profImage,
    required this.saved,
    required this.whoSent,
    required this.giftPoint,
    required this.country,
    required this.state,
    required this.city,
    required this.category,
    required this.isGiven,
    required this.isWanted,
  });

  static Post fromSnap(DocumentSnapshot snap) {
    var snapshot = snap.data() as Map<String, dynamic>;

    return Post(
      description: snapshot["description"],
      uid: snapshot["uid"],
      likes: snapshot["likes"],
      postId: snapshot["postId"],
      datePublished: snapshot["datePublished"],
      username: snapshot["username"],
      postUrl: snapshot['postUrl'],
      profImage: snapshot['profImage'],
      recipient: snapshot['recipient'],
      saved: snapshot['saved'],
      whoSent: snapshot['whoSent'],
      giftPoint: snapshot['giftPoint'],
      country: snapshot['country'],
      state: snapshot['state'],
      city: snapshot['city'],
      category: snapshot['category'],
      isGiven: snapshot['isGiven'],
      isWanted: snapshot['isWanted'],
    );
  }

  Map<String, dynamic> toJson() => {
        "description": description,
        "uid": uid,
        "likes": likes,
        "username": username,
        "postId": postId,
        "datePublished": datePublished,
        'postUrl': postUrl,
        'profImage': profImage,
        'recipient': recipient,
        'saved': saved,
        'whoSent': whoSent,
        'giftPoint': giftPoint,
        'country': country,
        'state': state,
        'city': city,
        'category': category,
        'isGiven': isGiven,
        'isWanted': isWanted,
      };
}

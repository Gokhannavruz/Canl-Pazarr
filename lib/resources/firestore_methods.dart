import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:animal_trade/resources/storage_methods.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/posts.dart';

class FireStoreMethods {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String usedReferralCodesKey = 'used_referral_codes';

  // Cihazda kullanılan referral kodlarını kontrol et
  Future<bool> _hasUsedReferralCodeOnDevice(String referralCode) async {
    final prefs = await SharedPreferences.getInstance();
    final usedCodes = prefs.getStringList(usedReferralCodesKey) ?? [];
    return usedCodes.contains(referralCode);
  }

  // Cihazda kullanılan referral kodunu kaydet
  Future<void> _saveReferralCodeToDevice(String referralCode) async {
    final prefs = await SharedPreferences.getInstance();
    final usedCodes = prefs.getStringList(usedReferralCodesKey) ?? [];
    usedCodes.add(referralCode);
    await prefs.setStringList(usedReferralCodesKey, usedCodes);
  }

  // listen user changes
  Future<String> uploadPost(String description, List<Uint8List> files,
      String uid, String username, String profImage,
      {required String recipient,
      required city,
      required country,
      required String state,
      required bool isWanted,
      required String category}) async {
    String res = "Some error occurred";
    try {
      // Limit the number of images to 5
      List<Uint8List> limitedFiles =
          files.length > 5 ? files.sublist(0, 5) : files;

      List<String> photoUrls = [];
      // Upload each image and get URLs
      for (var file in limitedFiles) {
        String photoUrl =
            await StorageMethods().uploadImageToStorage('posts', file, true);
        photoUrls.add(photoUrl);
      }

      String postId = const Uuid().v1();
      Post post = Post(
        description: description,
        uid: uid,
        username: username,
        likes: [],
        postId: postId,
        datePublished: DateTime.now(),
        postUrl: photoUrls[0], // Main image
        postUrls: photoUrls, // All images
        profImage: profImage,
        recipient: recipient,
        saved: [],
        whoSent: '',
        giftPoint: 0,
        country: country,
        state: state,
        city: city,
        category: category,
        isGiven: false,
        isWanted: isWanted,
      );

      _firestore
          .collection('posts')
          .doc(postId)
          .set({"random": FieldValue.serverTimestamp(), ...post.toJson()});
      res = "success";
    } catch (err) {
      res = err.toString();
    }
    return res;
  }

  // listen user changes
  Future<String> uploadJob(String description, Uint8List file, String uid,
      String username, String profImage,
      {required String recipient,
      required city,
      required country,
      required String state,
      required bool isWanted,
      required String category}) async {
    // asking uid here because we dont want to make extra calls to firebase auth when we can just get from our state management
    String res = "Some error occurred";
    try {
      String photoUrl =
          await StorageMethods().uploadImageToStorage('jobs', file, true);
      String postId = const Uuid().v1(); // creates unique id based on time
      Post post = Post(
        description: description,
        uid: uid,
        username: username,
        likes: [],
        postId: postId,
        datePublished: DateTime.now(),
        postUrl: photoUrl,
        profImage: profImage,
        recipient: recipient,
        saved: [],
        whoSent: '',
        giftPoint: 0,
        country: country,
        state: state,
        city: city,
        category: category,
        isGiven: false,
        isWanted: isWanted,
      );
      _firestore
          .collection('jobs')
          .doc(postId)
          .set({"random": FieldValue.serverTimestamp(), ...post.toJson()});
      res = "success";
    } catch (err) {
      res = err.toString();
    }
    return res;
  }

  Future<String> likePost(String postId, String uid, List likes) async {
    String res = "Some error occurred";
    try {
      if (likes.contains(uid)) {
        // if the likes list contains the user uid, we need to remove it
        _firestore.collection('posts').doc(postId).update({
          'likes': FieldValue.arrayRemove([uid])
        });
      } else {
        // else we need to add uid to the likes array
        _firestore.collection('posts').doc(postId).update({
          'likes': FieldValue.arrayUnion([uid])
        });
      }
      res = 'success';
    } catch (err) {
      res = err.toString();
    }
    return res;
  }

  Future<String> likeJobPost(String postId, String uid, List likes) async {
    String res = "Some error occurred";
    try {
      if (likes.contains(uid)) {
        // if the likes list contains the user uid, we need to remove it
        _firestore.collection('jobs').doc(postId).update({
          'likes': FieldValue.arrayRemove([uid])
        });
      } else {
        // else we need to add uid to the likes array
        _firestore.collection('jobs').doc(postId).update({
          'likes': FieldValue.arrayUnion([uid])
        });
      }
      res = 'success';
    } catch (err) {
      res = err.toString();
    }
    return res;
  }

  // Post comment
  Future<String> postComment(String postId, String text, String uid,
      String name, String profilePic) async {
    String res = "Some error occurred";
    try {
      if (text.isNotEmpty) {
        // if the likes list contains the user uid, we need to remove it
        String commentId = const Uuid().v1();
        _firestore
            .collection('posts')
            .doc(postId)
            .collection('comments')
            .doc(commentId)
            .set({
          'profilePic': profilePic,
          'name': name,
          'uid': uid,
          'text': text,
          'commentId': commentId,
          'datePublished': DateTime.now(),
        });
        res = 'success';
      } else {
        res = "Please enter text";
      }
    } catch (err) {
      res = err.toString();
    }
    return res;
  }

  // Delete Post
  Future<String> deletePost(String postId) async {
    String res = "Some error occurred";
    try {
      // Get post data before deleting it
      DocumentSnapshot postDoc =
          await _firestore.collection('posts').doc(postId).get();
      if (!postDoc.exists) {
        return "Post does not exist";
      }

      Map<String, dynamic> postData = postDoc.data() as Map<String, dynamic>;
      String uid = postData['uid'];

      // Start a batch write operation for better atomicity and performance
      WriteBatch batch = _firestore.batch();

      // 1. First delete all comments for this post since they're a subcollection
      QuerySnapshot commentsSnapshot = await _firestore
          .collection('posts')
          .doc(postId)
          .collection('comments')
          .get();

      for (var doc in commentsSnapshot.docs) {
        batch.delete(doc.reference);
      }

      // 2. Delete all notifications related to this post
      QuerySnapshot notificationsSnapshot = await _firestore
          .collection('notifications')
          .where('postId', isEqualTo: postId)
          .get();

      for (var doc in notificationsSnapshot.docs) {
        batch.delete(doc.reference);
      }

      // 3. Find and delete any saved references to this post
      try {
        // Owner's saved post (if exists)
        DocumentReference userSavedPostRef = _firestore
            .collection('users')
            .doc(uid)
            .collection('savedPosts')
            .doc(postId);

        DocumentSnapshot savedPostDoc = await userSavedPostRef.get();
        if (savedPostDoc.exists) {
          batch.delete(userSavedPostRef);
        }
      } catch (e) {
        print('Error removing user saved post: $e');
        // Continue with deletion even if there's an error with saved posts
      }

      // 4. Update user's posts array to remove this post ID if it exists
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(uid).get();
      if (userDoc.exists) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;

        // posts field var mı ve array mi kontrol et
        if (userData.containsKey('posts') && userData['posts'] is List) {
          batch.update(_firestore.collection('users').doc(uid), {
            'posts': FieldValue.arrayRemove([postId])
          });
        }
      }

      // 5. Add a decrement update if postCount field exists
      if (userDoc.exists) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;

        if (userData.containsKey('postCount')) {
          batch.update(_firestore.collection('users').doc(uid),
              {'postCount': FieldValue.increment(-1)});
        }
      }

      // 6. Finally delete the actual post document
      batch.delete(_firestore.collection('posts').doc(postId));

      // Commit all the operations as a single atomic batch
      await batch.commit();

      // Handle other users' savedPosts without collectionGroup
      // Instead of using collectionGroup, we can get all users and check their savedPosts collection
      try {
        // Get all users (this might not be optimal for large user bases, but it's a workaround)
        QuerySnapshot usersSnapshot =
            await _firestore.collection('users').get();

        for (var userDoc in usersSnapshot.docs) {
          String docId = userDoc.id;
          if (docId != uid) {
            // Skip the post owner as we already handled their savedPosts
            DocumentReference savedPostRef = _firestore
                .collection('users')
                .doc(docId)
                .collection('savedPosts')
                .doc(postId);

            // Check if this user has the post saved
            DocumentSnapshot savedDoc = await savedPostRef.get();
            if (savedDoc.exists) {
              await savedPostRef.delete();
            }
          }
        }
      } catch (e) {
        print('Error cleaning up other users saved posts: $e');
        // This is a cleanup operation, so we don't need to throw an error
      }

      res = "success";
    } catch (err) {
      print("Error deleting post: $err");
      res = err.toString();
    }
    return res;
  }

  // Delete Job Post
  Future<String> deleteJobPost(String postId) async {
    String res = "Some error occurred";
    try {
      // Önce job post dokümanını alalım
      DocumentSnapshot jobDoc =
          await _firestore.collection('jobs').doc(postId).get();

      if (jobDoc.exists) {
        // Kullanıcı ID'sini alıyoruz
        String uid = jobDoc.get('uid');

        // İlgili tüm bildirimleri siliyoruz
        await deleteNotification(postId);

        // Job postu siliyoruz
        await _firestore.collection('jobs').doc(postId).delete();

        // Kullanıcının dokümanını kontrol edip jobs dizisinden post ID'yi kaldırma
        DocumentSnapshot userDoc =
            await _firestore.collection('users').doc(uid).get();
        if (userDoc.exists) {
          Map<String, dynamic> userData =
              userDoc.data() as Map<String, dynamic>;

          if (userData.containsKey('jobs') && userData['jobs'] is List) {
            // Kullanıcının jobs dizisinden de siliyoruz
            await _firestore.collection('users').doc(uid).update({
              'jobs': FieldValue.arrayRemove([postId])
            });
          }
        }
      }

      res = 'success';
    } catch (err) {
      res = err.toString();
    }
    return res;
  }

  // delete notification from notifications collection with postId
  Future<void> deleteNotification(String postId) async {
    try {
      await _firestore
          .collection('notifications')
          .where('postId', isEqualTo: postId)
          .get()
          .then((snapshot) {
        for (DocumentSnapshot doc in snapshot.docs) {
          doc.reference.delete();
        }
      });
    } catch (e) {
      print(e.toString());
    }
  }

  // delete comment from comments collection with commentId
  Future<void> deleteComment(String postId, String commentId) async {
    try {
      await _firestore
          .collection('posts')
          .doc(postId)
          .collection('comments')
          .doc(commentId)
          .delete();
    } catch (e) {
      print(e.toString());
    }
  }

  Future<void> followUser(String uid, String followId) async {
    bool isBlocked = false;
    try {
      DocumentSnapshot snap =
          await _firestore.collection('users').doc(uid).get();
      List following = (snap.data()! as dynamic)['following'];
      DocumentSnapshot snap2 =
          await _firestore.collection('users').doc(followId).get();
      List blockedBy = (snap2.data()! as dynamic)['blockedBy'];
      if (blockedBy.contains(uid)) {
        isBlocked = true;
      }
      if (following.contains(followId)) {
        // remove the followed user from the following user's followers list
        await _firestore.collection('users').doc(followId).update({
          'followers': FieldValue.arrayRemove([uid])
        });

        // remove the followed user from the following user's following list
        await _firestore.collection('users').doc(uid).update({
          'following': FieldValue.arrayRemove([followId])
        });
        if (isBlocked) {
          // remove the blocking user from the blocked user's blockedBy list
          await _firestore.collection('users').doc(followId).update({
            'blockedBy': FieldValue.arrayRemove([uid])
          });

          // remove the blocked user from the blocking user's blocked list
          await _firestore.collection('users').doc(uid).update({
            'blocked': FieldValue.arrayRemove([followId])
          });
        }
      } else {
        // add the followed user to the following user's followers list
        await _firestore.collection('users').doc(followId).update({
          'followers': FieldValue.arrayUnion([uid])
        });

        // add the followed user to the following user's following list
        await _firestore.collection('users').doc(uid).update({
          'following': FieldValue.arrayUnion([followId])
        });
        if (isBlocked) {
          // add the blocking user to the blocked user's blockedBy list
          await _firestore.collection('users').doc(followId).update({
            'blockedBy': FieldValue.arrayUnion([uid])
          });

          // add the blocked user to the blocking user's blocked list
          await _firestore.collection('users').doc(uid).update({
            'blocked': FieldValue.arrayUnion([followId])
          });
        }
      }
    } catch (e) {
      print(e.toString());
    }
  }

// unfollow user
  Future<void> unfollowUser(String uid, String followId) async {
    bool isBlocked = false;
    try {
      DocumentSnapshot snap2 =
          await _firestore.collection('users').doc(followId).get();
      List blockedBy = (snap2.data()! as dynamic)['blockedBy'];
      if (blockedBy.contains(uid)) {
        isBlocked = true;
      }
      // remove the followed user from the following user's followers list
      await _firestore.collection('users').doc(followId).update({
        'followers': FieldValue.arrayRemove([uid])
      });

      // remove the followed user from the following user's following list
      await _firestore.collection('users').doc(uid).update({
        'following': FieldValue.arrayRemove([followId])
      });
      if (isBlocked) {
        // remove the blocking user from the blocked user's blockedBy list
        await _firestore.collection('users').doc(followId).update({
          'blockedBy': FieldValue.arrayRemove([uid])
        });

        // remove the blocked user from the blocking user's blocked list
        await _firestore.collection('users').doc(uid).update({
          'blocked': FieldValue.arrayRemove([followId])
        });
      }
    } catch (e) {
      print(e.toString());
    }
  }

  // Save Post
  Future<String> savePost(
    Post post,
    String uid,
    snap,
  ) async {
    String res = "Some error occurred";
    try {
      await _firestore
          .collection('saved_posts')
          .doc(post.postId)
          .set(post.toJson());
      res = "success";
    } catch (err) {
      res = err.toString();
    }
    return res;
  }

  //block user
  Future<void> blockUser(String uid, String blockId) async {
    try {
      // update the blockedBy field in the blocked user's document
      await _firestore.collection('users').doc(blockId).update({
        'blockedBy': FieldValue.arrayUnion([uid])
      });

      // update the blocked field in the blocking user's document
      await _firestore.collection('users').doc(uid).update({
        'blocked': FieldValue.arrayUnion([blockId])
      });

      // get the blocking user's document
      final blockingUserDoc =
          await _firestore.collection('users').doc(uid).get();

      // check if the blocked user is in the blocking user's following list
      if (blockingUserDoc.data()!['following'].contains(blockId)) {
        // remove the blocked user from the blocking user's following list
        await _firestore.collection('users').doc(uid).update({
          'following': FieldValue.arrayRemove([blockId])
        });
      }

      // check if the blocked user is in the blocking user's followers list
      if (blockingUserDoc.data()!['followers'].contains(blockId)) {
        // remove the blocked user from the blocking user's followers list
        await _firestore.collection('users').doc(uid).update({
          'followers': FieldValue.arrayRemove([blockId])
        });
      }
    } catch (e) {
      print(e.toString());
    }
  }

  //unblock user
  Future<void> unblockUser(String uid, String blockId) async {
    try {
      await _firestore.collection('users').doc(blockId).update({
        'blockedBy': FieldValue.arrayRemove([uid])
      });

      await _firestore.collection('users').doc(uid).update({
        'blocked': FieldValue.arrayRemove([blockId])
      });
    } catch (e) {
      print(e.toString());
    }
  }

  //report user
  Future<void> reportUser(String uid, String reportId) async {
    try {
      await _firestore.collection('users').doc(reportId).update({
        'reportedBy': FieldValue.arrayUnion([uid])
      });

      await _firestore.collection('users').doc(uid).update({
        'reported': FieldValue.arrayUnion([reportId])
      });
    } catch (e) {
      print(e.toString());
    }
  }

  //don't show this post again
  Future<void> dontShowPost(String uid, String postId) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'dontShow': FieldValue.arrayUnion([postId])
      });
    } catch (e) {
      print(e.toString());
    }
  }

  // tag user
  Future<void> tagUser(String uid, String postId, String taggedId) async {
    try {
      await _firestore.collection('users').doc(taggedId).update({
        'tagged': FieldValue.arrayUnion([postId])
      });

      await _firestore.collection('users').doc(uid).update({
        'tagged': FieldValue.arrayUnion([postId])
      });
    } catch (e) {
      print(e.toString());
    }
  }

  Future<String> addNotification(String type, String postId, String postOwnerId,
      String userId, String userName, String notificationText) async {
    String res = "Some error occurred";
    try {
      String notificationId = const Uuid().v1();
      await FirebaseFirestore.instance
          .collection('notifications')
          .doc(notificationId)
          .set({
        'type': type,
        'postId': postId,
        'postOwnerId': postOwnerId,
        'userId': userId,
        'userName': userName,
        'notificationText': notificationText,
        'date': DateTime.now()
      });
      res = 'success';
    } catch (err) {
      res = err.toString();
    }
    return res;
  }

  // ad comment notification to notification collection with comment text
  Future<String> addCommentNotification(
      String type,
      String postId,
      String postOwnerId,
      String userId,
      String userName,
      String commentText) async {
    String res = "Some error occurred";
    try {
      String notificationId = const Uuid().v1();
      await FirebaseFirestore.instance
          .collection('notifications')
          .doc(notificationId)
          .set({
        'type': type,
        'postId': postId,
        'postOwnerId': postOwnerId,
        'userId': userId,
        'userName': userName,
        'commentText': commentText,
        'date': DateTime.now()
      });
      res = 'success';
    } catch (err) {
      res = err.toString();
    }
    return res;
  }

  // save last_match_timestamp for current user
  Future<void> saveLastMatchTimestamp(String uid) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'last_match_timestamp': DateTime.now(),
      });
    } catch (e) {
      print(e.toString());
    }
  }
}

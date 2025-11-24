// services/notification_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Create a notification when moderator posts something
  static Future<void> createModeratorPostNotification({
    required String moderatorName,
    required String postType,
    required String postTitle,
    required String moderatorId,
  }) async {
    try {
      // Get current user (moderator)
      final user = _auth.currentUser;
      if (user == null) return;

      // Create notification data
      final notificationData = {
        'title': 'New Post by Moderator',
        'message': '$moderatorName posted a new $postType: "$postTitle"',
        'type': 'moderator_post',
        'senderId': moderatorId,
        'senderName': moderatorName,
        'postType': postType,
        'postTitle': postTitle,
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
        'targetUser': 'admin', // This notification is for admin only
      };

      // Store in Firestore
      await _firestore.collection('notifications').add(notificationData);

      print('Notification created for moderator post');
    } catch (e) {
      print('Error creating notification: $e');
    }
  }

  // Create a notification for user registration
  static Future<void> createUserRegistrationNotification({
    required String userName,
    required String userEmail,
    required String userId,
  }) async {
    try {
      final notificationData = {
        'title': 'New User Registration',
        'message':
            '$userName ($userEmail) has registered and needs verification.',
        'type': 'user_registration',
        'userId': userId,
        'userName': userName,
        'userEmail': userEmail,
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
        'targetUser': 'admin', // For admin only
      };

      await _firestore.collection('notifications').add(notificationData);
    } catch (e) {
      print('Error creating user registration notification: $e');
    }
  }

  // Create a notification for document requests
  static Future<void> createDocumentRequestNotification({
    required String userName,
    required String documentType,
    required String requestId,
  }) async {
    try {
      final notificationData = {
        'title': 'Document Request',
        'message': '$userName requested a $documentType. Needs approval.',
        'type': 'document_request',
        'userName': userName,
        'documentType': documentType,
        'requestId': requestId,
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
        'targetUser': 'admin', // For admin only
      };

      await _firestore.collection('notifications').add(notificationData);
    } catch (e) {
      print('Error creating document request notification: $e');
    }
  }

  // Get all notifications for admin
  static Stream<QuerySnapshot> getAdminNotifications() {
    return _firestore
        .collection('notifications')
        .where('targetUser', isEqualTo: 'admin')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // Mark notification as read
  static Future<void> markAsRead(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).update({
        'read': true,
      });
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  // Mark all notifications as read
  static Future<void> markAllAsRead() async {
    try {
      final snapshot = await _firestore
          .collection('notifications')
          .where('targetUser', isEqualTo: 'admin')
          .where('read', isEqualTo: false)
          .get();

      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.update(doc.reference, {'read': true});
      }
      await batch.commit();
    } catch (e) {
      print('Error marking all notifications as read: $e');
    }
  }

  // Delete notification
  static Future<void> deleteNotification(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).delete();
    } catch (e) {
      print('Error deleting notification: $e');
    }
  }
}

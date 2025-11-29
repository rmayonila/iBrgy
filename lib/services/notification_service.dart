// services/notification_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Create notification for moderator actions (add, edit, delete)
  static Future<void> createModeratorActionNotification({
    required String moderatorName,
    required String moderatorId,
    required String action, // 'added', 'edited', 'deleted'
    required String page, // 'services', 'emergency', 'updates', 'officials'
    required String
    postType, // 'announcement', 'hotline', 'service', 'official'
    required String postTitle,
    String? postId,
    String? previousTitle, // For edit actions
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Determine notification type based on action
      String notificationType = 'moderator_${action}';

      // Create appropriate message based on action
      String message = '';
      String title = '';

      switch (action) {
        case 'added':
          title = 'New $postType Added';
          message =
              '$moderatorName added a new $postType in $page: "$postTitle"';
          break;
        case 'edited':
          title = '$postType Updated';
          final previousText = previousTitle != null
              ? ' from "$previousTitle"'
              : '';
          message =
              '$moderatorName edited a $postType in $page$previousText to "$postTitle"';
          break;
        case 'deleted':
          title = '$postType Removed';
          message =
              '$moderatorName deleted a $postType from $page: "$postTitle"';
          break;
      }

      final notificationData = {
        'title': title,
        'message': message,
        'type': notificationType,
        'action': action, // added, edited, deleted
        'page': page, // services, emergency, updates, officials
        'postType': postType,
        'postTitle': postTitle,
        'postId': postId,
        'previousTitle': previousTitle,
        'senderId': moderatorId,
        'senderName': moderatorName,
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
        'targetUser': 'admin',
      };

      await _firestore.collection('notifications').add(notificationData);
      print('Notification created for moderator $action action');
    } catch (e) {
      print('Error creating moderator action notification: $e');
    }
  }

  // Specific methods for different pages for easier integration
  static Future<void> notifyAnnouncementAdded({
    required String moderatorName,
    required String moderatorId,
    required String announcementTitle,
    required String announcementId,
  }) async {
    await createModeratorActionNotification(
      moderatorName: moderatorName,
      moderatorId: moderatorId,
      action: 'added',
      page: 'updates',
      postType: 'announcement',
      postTitle: announcementTitle,
      postId: announcementId,
    );
  }

  static Future<void> notifyAnnouncementEdited({
    required String moderatorName,
    required String moderatorId,
    required String newTitle,
    required String previousTitle,
    required String announcementId,
  }) async {
    await createModeratorActionNotification(
      moderatorName: moderatorName,
      moderatorId: moderatorId,
      action: 'edited',
      page: 'updates',
      postType: 'announcement',
      postTitle: newTitle,
      postId: announcementId,
      previousTitle: previousTitle,
    );
  }

  static Future<void> notifyAnnouncementDeleted({
    required String moderatorName,
    required String moderatorId,
    required String announcementTitle,
    required String announcementId,
  }) async {
    await createModeratorActionNotification(
      moderatorName: moderatorName,
      moderatorId: moderatorId,
      action: 'deleted',
      page: 'updates',
      postType: 'announcement',
      postTitle: announcementTitle,
      postId: announcementId,
    );
  }

  static Future<void> notifyEmergencyAdded({
    required String moderatorName,
    required String moderatorId,
    required String emergencyTitle,
    required String emergencyId,
  }) async {
    await createModeratorActionNotification(
      moderatorName: moderatorName,
      moderatorId: moderatorId,
      action: 'added',
      page: 'emergency',
      postType: 'hotline',
      postTitle: emergencyTitle,
      postId: emergencyId,
    );
  }

  static Future<void> notifyEmergencyEdited({
    required String moderatorName,
    required String moderatorId,
    required String newTitle,
    required String previousTitle,
    required String emergencyId,
  }) async {
    await createModeratorActionNotification(
      moderatorName: moderatorName,
      moderatorId: moderatorId,
      action: 'edited',
      page: 'emergency',
      postType: 'hotline',
      postTitle: newTitle,
      postId: emergencyId,
      previousTitle: previousTitle,
    );
  }

  static Future<void> notifyEmergencyDeleted({
    required String moderatorName,
    required String moderatorId,
    required String emergencyTitle,
    required String emergencyId,
  }) async {
    await createModeratorActionNotification(
      moderatorName: moderatorName,
      moderatorId: moderatorId,
      action: 'deleted',
      page: 'emergency',
      postType: 'hotline',
      postTitle: emergencyTitle,
      postId: emergencyId,
    );
  }

  static Future<void> notifyServiceAdded({
    required String moderatorName,
    required String moderatorId,
    required String serviceTitle,
    required String serviceId,
  }) async {
    await createModeratorActionNotification(
      moderatorName: moderatorName,
      moderatorId: moderatorId,
      action: 'added',
      page: 'services',
      postType: 'service',
      postTitle: serviceTitle,
      postId: serviceId,
    );
  }

  static Future<void> notifyServiceEdited({
    required String moderatorName,
    required String moderatorId,
    required String newTitle,
    required String previousTitle,
    required String serviceId,
  }) async {
    await createModeratorActionNotification(
      moderatorName: moderatorName,
      moderatorId: moderatorId,
      action: 'edited',
      page: 'services',
      postType: 'service',
      postTitle: newTitle,
      postId: serviceId,
      previousTitle: previousTitle,
    );
  }

  static Future<void> notifyServiceDeleted({
    required String moderatorName,
    required String moderatorId,
    required String serviceTitle,
    required String serviceId,
  }) async {
    await createModeratorActionNotification(
      moderatorName: moderatorName,
      moderatorId: moderatorId,
      action: 'deleted',
      page: 'services',
      postType: 'service',
      postTitle: serviceTitle,
      postId: serviceId,
    );
  }

  static Future<void> notifyOfficialAdded({
    required String moderatorName,
    required String moderatorId,
    required String officialTitle,
    required String officialId,
  }) async {
    await createModeratorActionNotification(
      moderatorName: moderatorName,
      moderatorId: moderatorId,
      action: 'added',
      page: 'officials',
      postType: 'official',
      postTitle: officialTitle,
      postId: officialId,
    );
  }

  static Future<void> notifyOfficialEdited({
    required String moderatorName,
    required String moderatorId,
    required String newTitle,
    required String previousTitle,
    required String officialId,
  }) async {
    await createModeratorActionNotification(
      moderatorName: moderatorName,
      moderatorId: moderatorId,
      action: 'edited',
      page: 'officials',
      postType: 'official',
      postTitle: newTitle,
      postId: officialId,
      previousTitle: previousTitle,
    );
  }

  static Future<void> notifyOfficialDeleted({
    required String moderatorName,
    required String moderatorId,
    required String officialTitle,
    required String officialId,
  }) async {
    await createModeratorActionNotification(
      moderatorName: moderatorName,
      moderatorId: moderatorId,
      action: 'deleted',
      page: 'officials',
      postType: 'official',
      postTitle: officialTitle,
      postId: officialId,
    );
  }

  // Keep existing methods for backward compatibility
  static Future<void> createModeratorPostNotification({
    required String moderatorName,
    required String postType,
    required String postTitle,
    required String moderatorId,
  }) async {
    await createModeratorActionNotification(
      moderatorName: moderatorName,
      moderatorId: moderatorId,
      action: 'added',
      page: 'updates',
      postType: postType,
      postTitle: postTitle,
    );
  }

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
        'targetUser': 'admin',
      };
      await _firestore.collection('notifications').add(notificationData);
    } catch (e) {
      print('Error creating user registration notification: $e');
    }
  }

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
        'targetUser': 'admin',
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

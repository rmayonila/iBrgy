import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuditLogService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // 1. CHANGED: Match the collection name used in NotificationService
  static const String collectionName = 'notifications';

  static Future<void> logActivity({
    required String action, // 'added', 'edited', 'deleted'
    required String page, // 'services', 'emergency', 'updates', 'officials'
    required String title,
    required String message,
  }) async {
    try {
      final user = _auth.currentUser;
      String moderatorName = "Moderator";

      if (user != null) {
        moderatorName = user.displayName ?? user.email ?? "Moderator";
      }

      await _db.collection(collectionName).add({
        // Data required by TrackActivityPage
        'type': 'moderator_$action',
        'action': action,
        'page': page,
        'title': '${action.toUpperCase()} in ${page.toUpperCase()}',
        'message': '$message: "$title"',
        'senderName': moderatorName,
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,

        // 2. ADDED: This field is REQUIRED for the Admin Page to see it
        // (Your NotificationService filters by targetUser == 'admin')
        'targetUser': 'admin',
      });
    } catch (e) {
      // print("Error logging activity: $e");
    }
  }
}

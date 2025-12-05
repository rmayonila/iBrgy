import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ActivityService {
  final String collectionName = 'activity_logs';

  Future<void> logActivity(
    BuildContext context, {
    required String actionTitle,
    required String details,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        print("Logger Error: No user logged in.");
        return;
      }

      // --- NEW NAME FETCHING LOGIC ---

      // 1. Try to get the name from the Login Token (Auth)
      String moderatorName = user.displayName ?? '';

      // 2. If Auth name is empty, fetch it from the 'users' database
      if (moderatorName.isEmpty) {
        try {
          final userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();

          if (userDoc.exists) {
            // We assume your user field is called 'name'
            moderatorName = userDoc.data()?['name'] ?? 'Unknown Moderator';
          }
        } catch (e) {
          print("Error fetching name from DB: $e");
        }
      }

      // 3. Final fallback if both fail
      if (moderatorName.isEmpty) {
        moderatorName = 'Unknown Moderator';
      }

      // --- END NEW LOGIC ---

      // Save to Firestore
      await FirebaseFirestore.instance.collection(collectionName).add({
        'action': actionTitle,
        'details': details,
        'moderatorId': user.uid,
        'moderatorName': moderatorName,
        'timestamp': FieldValue.serverTimestamp(),
      });

      print("Activity Logged: $actionTitle by $moderatorName");
    } catch (e) {
      print("Failed to log activity: $e");

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("LOGGER ERROR: $e"),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }
}

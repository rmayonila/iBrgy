import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/subscription_tier.dart';

class SubscriptionService {
  static final SubscriptionService _instance = SubscriptionService._internal();
  factory SubscriptionService() => _instance;
  SubscriptionService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current subscription status
  Future<SubscriptionStatus> getCurrentSubscription() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return const SubscriptionStatus(tierId: 'free', isActive: true);
      }

      // Get user's barangay ID (assuming it's stored in user document)
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final barangayId = userDoc.data()?['barangayId'] ?? user.uid;

      // Get subscription from barangay_subscriptions collection
      final subDoc = await _firestore
          .collection('barangay_subscriptions')
          .doc(barangayId)
          .get();

      if (!subDoc.exists) {
        // Create default free subscription
        await _createDefaultSubscription(barangayId);
        return const SubscriptionStatus(tierId: 'free', isActive: true);
      }

      return SubscriptionStatus.fromMap(subDoc.data()!);
    } catch (e) {
      return const SubscriptionStatus(tierId: 'free', isActive: true);
    }
  }

  // Create default free subscription
  Future<void> _createDefaultSubscription(String barangayId) async {
    await _firestore.collection('barangay_subscriptions').doc(barangayId).set({
      'tierId': 'free',
      'startDate': FieldValue.serverTimestamp(),
      'endDate': null,
      'isActive': true,
      'paymentMethod': 'none',
      'transactionId': null,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Mock payment processing (Demo mode)
  Future<Map<String, dynamic>> processMockPayment({
    required String tierId,
    required String paymentMethod,
    required double amount,
  }) async {
    // Simulate payment processing delay
    await Future.delayed(const Duration(seconds: 2));

    // Generate mock transaction ID
    final transactionId = 'MOCK-${DateTime.now().millisecondsSinceEpoch}';

    return {
      'success': true,
      'transactionId': transactionId,
      'amount': amount,
      'paymentMethod': paymentMethod,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  // Upgrade subscription (with mock payment)
  Future<bool> upgradeSubscription({
    required String tierId,
    required String paymentMethod,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final barangayId = userDoc.data()?['barangayId'] ?? user.uid;

      final tier = SubscriptionTier.getById(tierId);

      // Process mock payment
      final paymentResult = await processMockPayment(
        tierId: tierId,
        paymentMethod: paymentMethod,
        amount: tier.price,
      );

      if (!paymentResult['success']) return false;

      // Calculate end date (30 days from now)
      final startDate = DateTime.now();
      final endDate = startDate.add(const Duration(days: 30));

      // Update subscription
      await _firestore
          .collection('barangay_subscriptions')
          .doc(barangayId)
          .set({
            'tierId': tierId,
            'startDate': Timestamp.fromDate(startDate),
            'endDate': Timestamp.fromDate(endDate),
            'isActive': true,
            'paymentMethod': paymentMethod,
            'transactionId': paymentResult['transactionId'],
            'amount': tier.price,
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

      // Log the subscription change
      await _logSubscriptionActivity(
        barangayId: barangayId,
        action: 'Subscription Upgraded',
        details: 'Upgraded to ${tier.name} (${tier.priceLabel})',
        transactionId: paymentResult['transactionId'],
      );

      return true;
    } catch (e) {
      return false;
    }
  }

  // Cancel subscription (downgrade to free)
  Future<bool> cancelSubscription() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final barangayId = userDoc.data()?['barangayId'] ?? user.uid;

      await _firestore
          .collection('barangay_subscriptions')
          .doc(barangayId)
          .set({
            'tierId': 'free',
            'startDate': FieldValue.serverTimestamp(),
            'endDate': null,
            'isActive': true,
            'paymentMethod': 'none',
            'transactionId': null,
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

      await _logSubscriptionActivity(
        barangayId: barangayId,
        action: 'Subscription Cancelled',
        details: 'Downgraded to Free tier',
      );

      return true;
    } catch (e) {
      return false;
    }
  }

  // Get current usage statistics
  Future<Map<String, int>> getCurrentUsage() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return {};

      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final barangayId = userDoc.data()?['barangayId'] ?? user.uid;

      // Count moderators
      final moderatorsSnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'moderator')
          .where('barangayId', isEqualTo: barangayId)
          .get();

      // Count announcements
      final announcementsSnapshot = await _firestore
          .collection('announcements')
          .where('barangayId', isEqualTo: barangayId)
          .get();

      // Count services
      final servicesSnapshot = await _firestore
          .collection('barangay_services')
          .where('barangayId', isEqualTo: barangayId)
          .get();

      // Count hotlines
      final hotlinesSnapshot = await _firestore
          .collection('emergency_hotlines')
          .where('barangayId', isEqualTo: barangayId)
          .get();

      return {
        'moderators': moderatorsSnapshot.docs.length,
        'announcements': announcementsSnapshot.docs.length,
        'services': servicesSnapshot.docs.length,
        'hotlines': hotlinesSnapshot.docs.length,
      };
    } catch (e) {
      return {};
    }
  }

  // Check if action is allowed based on current subscription
  Future<bool> canPerformAction(String action, {int currentCount = 0}) async {
    final subscription = await getCurrentSubscription();
    final tier = subscription.tier;

    switch (action) {
      case 'add_moderator':
        final limit = tier.limits['maxModerators'];
        return limit == -1 || currentCount < limit;
      case 'add_announcement':
        final limit = tier.limits['maxAnnouncements'];
        return limit == -1 || currentCount < limit;
      case 'add_service':
        final limit = tier.limits['maxServices'];
        return limit == -1 || currentCount < limit;
      case 'add_hotline':
        final limit = tier.limits['maxHotlines'];
        return limit == -1 || currentCount < limit;
      case 'upload_image':
        return tier.limits['announcementImageAllowed'] ?? false;
      case 'export_data':
        return tier.limits['canExport'] ?? false;
      default:
        return true;
    }
  }

  // Log subscription activity
  Future<void> _logSubscriptionActivity({
    required String barangayId,
    required String action,
    required String details,
    String? transactionId,
  }) async {
    await _firestore.collection('subscription_logs').add({
      'barangayId': barangayId,
      'action': action,
      'details': details,
      'transactionId': transactionId,
      'timestamp': FieldValue.serverTimestamp(),
      'userId': _auth.currentUser?.uid,
    });
  }

  // Get subscription history
  Future<List<Map<String, dynamic>>> getSubscriptionHistory() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final barangayId = userDoc.data()?['barangayId'] ?? user.uid;

      final snapshot = await _firestore
          .collection('subscription_logs')
          .where('barangayId', isEqualTo: barangayId)
          .orderBy('timestamp', descending: true)
          .limit(20)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'action': data['action'],
          'details': data['details'],
          'timestamp': data['timestamp'],
          'transactionId': data['transactionId'],
        };
      }).toList();
    } catch (e) {
      return [];
    }
  }
}

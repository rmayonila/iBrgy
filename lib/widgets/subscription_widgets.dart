import 'package:flutter/material.dart';
import '../models/subscription_tier.dart';
import '../services/subscription_service.dart';
import '../admin/subscription_management_page.dart';

/// Widget to display subscription limit warnings
class SubscriptionLimitWarning extends StatelessWidget {
  final String limitType;
  final int currentCount;
  final SubscriptionTier tier;

  const SubscriptionLimitWarning({
    super.key,
    required this.limitType,
    required this.currentCount,
    required this.tier,
  });

  @override
  Widget build(BuildContext context) {
    final limit = tier.limits[limitType];
    if (limit == null || limit == -1) return const SizedBox.shrink();

    final isNearLimit = currentCount >= (limit * 0.8);
    final isAtLimit = currentCount >= limit;

    if (!isNearLimit) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isAtLimit ? Colors.red.shade50 : Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isAtLimit ? Colors.red.shade200 : Colors.orange.shade200,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isAtLimit ? Icons.error_outline : Icons.warning_amber,
            color: isAtLimit ? Colors.red.shade700 : Colors.orange.shade700,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isAtLimit ? 'Limit Reached' : 'Approaching Limit',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: isAtLimit ? Colors.red.shade900 : Colors.orange.shade900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isAtLimit
                      ? 'You have reached the maximum limit ($limit) for your ${tier.name} plan.'
                      : 'You are using $currentCount of $limit available.',
                  style: TextStyle(
                    fontSize: 12,
                    color: isAtLimit ? Colors.red.shade800 : Colors.orange.shade800,
                  ),
                ),
              ],
            ),
          ),
          if (tier.id != 'premium')
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SubscriptionManagementPage(),
                  ),
                );
              },
              child: const Text(
                'Upgrade',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
    );
  }
}

/// Dialog to show when user tries to exceed subscription limits
class SubscriptionLimitDialog {
  static Future<void> show({
    required BuildContext context,
    required String feature,
    required SubscriptionTier currentTier,
  }) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(Icons.lock_outline, color: Colors.orange.shade700, size: 28),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Upgrade Required',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'You have reached the limit for $feature on your ${currentTier.name} plan.',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.lightbulb_outline, color: Colors.blue.shade700),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Upgrade to unlock more features',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
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
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SubscriptionManagementPage(),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('View Plans'),
          ),
        ],
      ),
    );
  }
}

/// Badge to show current subscription tier
class SubscriptionBadge extends StatelessWidget {
  final SubscriptionTier tier;
  final bool compact;

  const SubscriptionBadge({
    super.key,
    required this.tier,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    Color badgeColor;
    IconData badgeIcon;

    switch (tier.id) {
      case 'premium':
        badgeColor = Colors.purple;
        badgeIcon = Icons.workspace_premium;
        break;
      case 'standard':
        badgeColor = Colors.blue;
        badgeIcon = Icons.star;
        break;
      default:
        badgeColor = Colors.grey;
        badgeIcon = Icons.person;
    }

    if (compact) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: badgeColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: badgeColor.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(badgeIcon, color: badgeColor, size: 14),
            const SizedBox(width: 4),
            Text(
              tier.name,
              style: TextStyle(
                color: badgeColor,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [badgeColor, badgeColor.withOpacity(0.7)],
        ),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: badgeColor.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(badgeIcon, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Text(
            tier.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

/// Helper function to check and show limit dialog if needed
Future<bool> checkSubscriptionLimit({
  required BuildContext context,
  required String action,
  required int currentCount,
}) async {
  final subscriptionService = SubscriptionService();
  final canPerform = await subscriptionService.canPerformAction(
    action,
    currentCount: currentCount,
  );

  if (!canPerform) {
    final subscription = await subscriptionService.getCurrentSubscription();
    await SubscriptionLimitDialog.show(
      context: context,
      feature: _getFeatureName(action),
      currentTier: subscription.tier,
    );
    return false;
  }

  return true;
}

String _getFeatureName(String action) {
  switch (action) {
    case 'add_moderator':
      return 'Moderators';
    case 'add_announcement':
      return 'Announcements';
    case 'add_service':
      return 'Services';
    case 'add_hotline':
      return 'Emergency Hotlines';
    case 'upload_image':
      return 'Image Uploads';
    case 'export_data':
      return 'Data Export';
    default:
      return 'this feature';
  }
}

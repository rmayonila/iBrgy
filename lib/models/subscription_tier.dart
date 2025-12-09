// Subscription Tier Model
class SubscriptionTier {
  final String id;
  final String name;
  final String description;
  final double price; // 0 for free tier
  final String priceLabel;
  final Map<String, dynamic> limits;
  final List<String> features;
  final bool isPopular;

  const SubscriptionTier({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.priceLabel,
    required this.limits,
    required this.features,
    this.isPopular = false,
  });

  // Predefined Tiers
  static const SubscriptionTier free = SubscriptionTier(
    id: 'free',
    name: 'Barangay Starter',
    description: 'Perfect for small barangays or trial users',
    price: 0,
    priceLabel: 'Free',
    limits: {
      'maxModerators': 1,
      'maxAnnouncements': 5,
      'announcementImageAllowed': false,
      'maxServices': 3,
      'maxHotlines': 5,
      'activityLogDays': 1, // 24 hours
      'canExport': false,
      'customBranding': false,
      'prioritySupport': false,
    },
    features: [
      '1 Admin + 1 Moderator',
      '5 Active Announcements (Text only)',
      '3 Barangay Services',
      '5 Emergency Hotlines',
      '24-hour Activity Logs',
      'No Export Features',
    ],
  );

  static const SubscriptionTier standard = SubscriptionTier(
    id: 'standard',
    name: 'Barangay Essential',
    description: 'For average-sized barangays with daily operations',
    price: 249,
    priceLabel: '₱249/month',
    limits: {
      'maxModerators': 5,
      'maxAnnouncements': 200,
      'announcementImageAllowed': true,
      'maxServices': 8,
      'maxHotlines': 25,
      'activityLogDays': 30,
      'canExport': false,
      'customBranding': false,
      'prioritySupport': false,
    },
    features: [
      'Up to 5 Moderators',
      '200 Announcements with Images',
      '8 Barangay Services',
      '25 Emergency Hotlines',
      '30-day Activity Logs',
      'Basic Reporting Dashboard',
    ],
    isPopular: true,
  );

  static const SubscriptionTier premium = SubscriptionTier(
    id: 'premium',
    name: 'Smart Barangay',
    description: 'For large, tech-forward barangays',
    price: 499,
    priceLabel: '₱499/month',
    limits: {
      'maxModerators': -1, // -1 means unlimited
      'maxAnnouncements': -1,
      'announcementImageAllowed': true,
      'maxServices': -1,
      'maxHotlines': -1,
      'activityLogDays': -1, // unlimited
      'canExport': true,
      'customBranding': true,
      'prioritySupport': true,
    },
    features: [
      'Unlimited Moderators',
      'Unlimited Announcements with Images',
      'Unlimited Barangay Services',
      'Unlimited Emergency Hotlines',
      'Unlimited Activity Logs',
      'Advanced Analytics & Reports',
      'Data Export (Excel/CSV)',
      'Custom Branding',
      'Priority Support',
    ],
  );

  static List<SubscriptionTier> get allTiers => [free, standard, premium];

  static SubscriptionTier getById(String id) {
    return allTiers.firstWhere(
      (tier) => tier.id == id,
      orElse: () => free,
    );
  }

  // Check if a specific limit is reached
  bool isLimitReached(String limitKey, int currentValue) {
    final limit = limits[limitKey];
    if (limit == null || limit == -1) return false; // unlimited
    return currentValue >= limit;
  }

  // Get remaining quota
  int getRemainingQuota(String limitKey, int currentValue) {
    final limit = limits[limitKey];
    if (limit == null || limit == -1) return -1; // unlimited
    return (limit - currentValue).clamp(0, limit);
  }
}

// Subscription Status Model
class SubscriptionStatus {
  final String tierId;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool isActive;
  final String paymentMethod;
  final String? transactionId;

  const SubscriptionStatus({
    required this.tierId,
    this.startDate,
    this.endDate,
    required this.isActive,
    this.paymentMethod = 'none',
    this.transactionId,
  });

  factory SubscriptionStatus.fromMap(Map<String, dynamic> map) {
    return SubscriptionStatus(
      tierId: map['tierId'] ?? 'free',
      startDate: map['startDate']?.toDate(),
      endDate: map['endDate']?.toDate(),
      isActive: map['isActive'] ?? false,
      paymentMethod: map['paymentMethod'] ?? 'none',
      transactionId: map['transactionId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'tierId': tierId,
      'startDate': startDate,
      'endDate': endDate,
      'isActive': isActive,
      'paymentMethod': paymentMethod,
      'transactionId': transactionId,
    };
  }

  SubscriptionTier get tier => SubscriptionTier.getById(tierId);

  bool get isExpired {
    if (endDate == null) return false;
    return DateTime.now().isAfter(endDate!);
  }

  int get daysRemaining {
    if (endDate == null) return -1;
    final diff = endDate!.difference(DateTime.now());
    return diff.inDays;
  }
}

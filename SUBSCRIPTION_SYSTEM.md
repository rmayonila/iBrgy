# Subscription System Documentation

## Overview

The iBrgy subscription system provides three tiers of service for barangay management, with a complete mock/demo payment flow that runs entirely locally without real payment processing.

## Subscription Tiers

### 1. **Barangay Starter** (Free / Trial)
**Price:** Free  
**Best for:** Small barangays or trial users testing the system

**Limits:**
- 👥 **Staff Accounts:** 1 Admin + 1 Moderator only
- 📝 **Activity Logs:** Last 24 hours only
- 📢 **Announcements:** 5 active announcements (text only, no images)
- 📂 **Services:** 3 defined services
- 📞 **Hotlines:** 5 emergency numbers
- ❌ **No Export:** Cannot download reports

---

### 2. **Barangay Essential** (Standard)
**Price:** ₱249/month  
**Best for:** Average-sized barangays with day-to-day operations

**Limits:**
- 👥 **Staff Accounts:** Up to 5 Moderators
- 📝 **Activity Logs:** Last 30 days
- 📢 **Announcements:** 200 posts with image uploads (standard resolution)
- 📂 **Services:** 8 services
- 📞 **Hotlines:** 25 hotlines
- 📊 **Basic Reporting:** Summary dashboards (30 days)

---

### 3. **Smart Barangay** (Premium)
**Price:** ₱499/month  
**Best for:** Large, tech-forward barangays or cities

**Features:**
- 👥 **Staff Accounts:** Unlimited Moderators
- 📝 **Activity Logs:** Unlimited history (audit everything forever)
- 📢 **Announcements:** Unlimited with images
- 📂 **Services:** Unlimited
- 📞 **Hotlines:** Unlimited
- ✨ **Advanced Features:**
  - Priority Support
  - Custom Branding (remove "Powered by iBrgy")
  - Data Export (Excel/CSV)
  - Advanced Analytics (90 days)

---

## Mock Payment System

### How It Works

The subscription system includes a **complete mock payment flow** that simulates real payment processing without charging actual money. This is perfect for:
- Development and testing
- Demonstrations to stakeholders
- User training
- Feature validation

### Payment Flow

1. **Select Plan** → User browses available subscription tiers
2. **Choose Payment Method** → Select from GCash, PayMaya, Credit Card, or Bank Transfer
3. **Processing Animation** → Realistic 2-second payment processing with loading indicator
4. **Success Confirmation** → Shows transaction ID, plan details, and validity period
5. **Subscription Activated** → Features immediately unlocked

### Mock Payment Methods

- 💳 **GCash** - Mobile wallet simulation
- 💳 **PayMaya** - Mobile wallet simulation
- 💳 **Credit/Debit Card** - Card payment simulation
- 🏦 **Bank Transfer** - Bank transfer simulation

All methods generate a mock transaction ID in the format: `MOCK-{timestamp}`

---

## Implementation Details

### File Structure

```
lib/
├── models/
│   └── subscription_tier.dart          # Tier definitions and limits
├── services/
│   └── subscription_service.dart       # Subscription logic and mock payment
├── admin/
│   └── subscription_management_page.dart  # Main subscription UI
└── widgets/
    └── subscription_widgets.dart       # Reusable subscription widgets
```

### Firestore Collections

#### `barangay_subscriptions`
Stores subscription status for each barangay:
```javascript
{
  tierId: "standard",
  startDate: Timestamp,
  endDate: Timestamp,
  isActive: true,
  paymentMethod: "gcash",
  transactionId: "MOCK-1234567890",
  amount: 249,
  updatedAt: Timestamp
}
```

#### `subscription_logs`
Tracks subscription changes and transactions:
```javascript
{
  barangayId: "brgy_001",
  action: "Subscription Upgraded",
  details: "Upgraded to Barangay Essential (₱249/month)",
  transactionId: "MOCK-1234567890",
  timestamp: Timestamp,
  userId: "admin_uid"
}
```

---

## Usage Guide

### For Administrators

#### Accessing Subscription Management

1. Navigate to **Profile** (bottom navigation)
2. Tap **Subscription** in the Account section
3. View current plan and usage statistics

#### Upgrading a Plan

1. In Subscription Management, browse available plans
2. Tap **Upgrade Now** on desired plan
3. Select payment method from the bottom sheet
4. Tap **Confirm Payment**
5. Wait for processing (2 seconds)
6. View success confirmation

#### Downgrading to Free

1. In Subscription Management, find the Free tier
2. Tap **Downgrade to Free**
3. Confirm the action
4. Data is preserved but features are limited

### For Developers

#### Checking Subscription Limits

```dart
import 'package:your_app/widgets/subscription_widgets.dart';

// Before adding a moderator
final canAdd = await checkSubscriptionLimit(
  context: context,
  action: 'add_moderator',
  currentCount: currentModeratorCount,
);

if (canAdd) {
  // Proceed with adding moderator
} else {
  // Limit dialog already shown
}
```

#### Displaying Usage Warnings

```dart
import 'package:your_app/widgets/subscription_widgets.dart';

// Show warning when approaching limit
SubscriptionLimitWarning(
  limitType: 'maxModerators',
  currentCount: 4,
  tier: currentTier,
)
```

#### Showing Subscription Badge

```dart
import 'package:your_app/widgets/subscription_widgets.dart';

// Display current tier badge
SubscriptionBadge(
  tier: currentTier,
  compact: true, // or false for full badge
)
```

---

## Testing the System

### Test Scenarios

1. **Free Tier Limits**
   - Try adding 2+ moderators (should block)
   - Try adding 6+ announcements (should block)
   - Try uploading images in announcements (should block)

2. **Upgrade Flow**
   - Upgrade from Free to Standard
   - Verify limits are increased
   - Check transaction log

3. **Payment Methods**
   - Test each payment method (GCash, PayMaya, etc.)
   - Verify transaction IDs are generated
   - Check success dialogs

4. **Downgrade Flow**
   - Downgrade from Standard to Free
   - Verify features are restricted
   - Ensure data is preserved

---

## Demo Mode Notice

The system displays a prominent notice that this is a **demo/mock payment system**:

> 🔔 **Demo Mode**  
> This is a demonstration. No real payment will be processed. All transactions are simulated locally.

This ensures users understand no actual charges will occur.

---

## Future Enhancements

When ready to implement real payments:

1. **Replace Mock Payment Service**
   - Integrate with real payment gateway (PayMongo, Xendit, etc.)
   - Update `SubscriptionService.processMockPayment()` method

2. **Add Webhooks**
   - Listen for payment confirmations
   - Handle subscription renewals
   - Process refunds

3. **Add Subscription Reminders**
   - Email/SMS notifications before expiry
   - Auto-renewal options
   - Grace period handling

4. **Add Analytics**
   - Track conversion rates
   - Monitor churn
   - Revenue reporting

---

## Security Considerations

- ✅ Only **Admin role** can manage subscriptions
- ✅ Subscription checks are server-side (Firestore rules)
- ✅ Transaction logs for audit trail
- ✅ Graceful handling of expired subscriptions
- ⚠️ Mock payments are clearly labeled
- ⚠️ No sensitive payment data is stored

---

## Support

For questions or issues with the subscription system:
- Check the implementation in `lib/admin/subscription_management_page.dart`
- Review subscription limits in `lib/models/subscription_tier.dart`
- Test with mock payments before going live

---

**Last Updated:** December 2025  
**Version:** 1.0.0 (Demo/Mock)

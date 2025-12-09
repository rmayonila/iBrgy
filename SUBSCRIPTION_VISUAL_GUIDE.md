# Subscription System - Visual Flow Guide

## 🎯 User Journey

### Step 1: Access Subscription Management
```
Admin Profile → Subscription (with premium icon)
```
**What User Sees:**
- Premium icon (⭐) next to "Subscription"
- Located in Account section
- Between "Account" and "Track Activity"

---

### Step 2: View Current Plan
```
Subscription Management Page
```
**Current Plan Card (Gradient Blue):**
- 🏆 Icon + Plan Name
- Price badge (if paid plan)
- Expiry date (if applicable)
- Warning if expiring soon (< 7 days)

**Usage Statistics Card:**
- Moderators: [Progress Bar] 1/1
- Announcements: [Progress Bar] 3/5
- Services: [Progress Bar] 2/3
- Hotlines: [Progress Bar] 4/5

**Color Coding:**
- Blue: Normal usage
- Orange: 80%+ usage (warning)
- Green: Unlimited

---

### Step 3: Browse Available Plans

#### Free Tier Card
```
┌─────────────────────────────────┐
│ 🆓 Barangay Starter             │
│ Perfect for small barangays     │
│                                 │
│ Free                            │
│                                 │
│ ✓ 1 Admin + 1 Moderator        │
│ ✓ 5 Announcements (Text only)  │
│ ✓ 3 Services                   │
│ ✓ 5 Hotlines                   │
│ ✓ 24-hour Activity Logs        │
│                                 │
│ [CURRENT] (if active)           │
└─────────────────────────────────┘
```

#### Standard Tier Card (Popular)
```
┌─────────────────────────────────┐
│ ⭐ Barangay Essential [POPULAR] │
│ For average-sized barangays     │
│                                 │
│ ₱249 /month                     │
│                                 │
│ ✓ Up to 5 Moderators           │
│ ✓ 200 Announcements + Images   │
│ ✓ 8 Services                   │
│ ✓ 25 Hotlines                  │
│ ✓ 30-day Activity Logs         │
│ ✓ Basic Reporting              │
│                                 │
│ [Upgrade Now] (Blue Button)     │
└─────────────────────────────────┘
```

#### Premium Tier Card
```
┌─────────────────────────────────┐
│ 👑 Smart Barangay               │
│ For tech-forward barangays      │
│                                 │
│ ₱499 /month                     │
│                                 │
│ ✓ Unlimited Moderators         │
│ ✓ Unlimited Announcements      │
│ ✓ Unlimited Services           │
│ ✓ Unlimited Hotlines           │
│ ✓ Unlimited Activity Logs      │
│ ✓ Advanced Analytics           │
│ ✓ Data Export (Excel/CSV)      │
│ ✓ Custom Branding              │
│ ✓ Priority Support             │
│                                 │
│ [Upgrade Now] (Blue Button)     │
└─────────────────────────────────┘
```

---

### Step 4: Select Payment Method

**Bottom Sheet Appears:**
```
┌─────────────────────────────────┐
│ Choose Payment Method           │
│ Select how you want to pay      │
│                                 │
│ ┌─────────────────────────────┐ │
│ │ Total Amount        ₱249    │ │
│ └─────────────────────────────┘ │
│                                 │
│ ○ 💳 GCash                      │
│ ● 💳 PayMaya        [Selected]  │
│ ○ 💳 Credit/Debit Card          │
│ ○ 🏦 Bank Transfer              │
│                                 │
│ ⚠️ Demo: No real payment       │
│                                 │
│ [Confirm Payment] (Blue)        │
└─────────────────────────────────┘
```

**Payment Methods:**
- GCash (Blue)
- PayMaya (Green)
- Credit/Debit Card (Purple)
- Bank Transfer (Orange)

---

### Step 5: Processing Payment

**Processing Dialog:**
```
┌─────────────────────────────────┐
│                                 │
│        [Spinner Animation]      │
│                                 │
│     Processing Payment          │
│     Please wait...              │
│                                 │
└─────────────────────────────────┘
```
**Duration:** 2 seconds (simulated)

---

### Step 6: Success Confirmation

**Success Dialog:**
```
┌─────────────────────────────────┐
│                                 │
│     [✓ Green Circle Icon]       │
│                                 │
│   Payment Successful!           │
│                                 │
│ You have successfully upgraded  │
│ to Barangay Essential           │
│                                 │
│ ┌─────────────────────────────┐ │
│ │ Plan: Barangay Essential    │ │
│ │ Valid Until: 1/10/2026      │ │
│ └─────────────────────────────┘ │
│                                 │
│        [Done] (Blue)            │
│                                 │
└─────────────────────────────────┘
```

**Transaction Details:**
- Plan name
- Validity period (30 days)
- Transaction ID (in logs)

---

### Step 7: Features Unlocked

**Updated Current Plan Card:**
```
┌─────────────────────────────────┐
│ 🏆 Barangay Essential  [₱249/mo]│
│                                 │
│ Valid until 1/10/2026           │
│ (30 days remaining)             │
└─────────────────────────────────┘
```

**Updated Usage:**
```
Moderators: [▓▓░░░] 1/5
Announcements: [▓░░░░] 3/200
Services: [▓░░░░] 2/8
Hotlines: [▓░░░░] 4/25
```

---

## 🚫 Limit Enforcement Flow

### When User Tries to Exceed Limit

**Example: Adding 2nd Moderator on Free Plan**

1. User taps "Add New Moderator"
2. System checks current count (1) vs limit (1)
3. Limit reached! Dialog appears:

```
┌─────────────────────────────────┐
│ 🔒 Upgrade Required             │
│                                 │
│ You have reached the limit for  │
│ Moderators on your Barangay     │
│ Starter plan.                   │
│                                 │
│ 💡 Upgrade to unlock more       │
│    features                     │
│                                 │
│ [Cancel]      [View Plans]      │
└─────────────────────────────────┘
```

4. User taps "View Plans" → Goes to Subscription page
5. User upgrades → Limit increased → Can add moderator

---

## 🎨 Color Scheme

### Plan Cards
- **Free:** Grey tones
- **Standard:** Blue (Popular badge)
- **Premium:** Purple/Gold gradient

### Status Indicators
- **Active:** Green badge
- **Expiring Soon:** Orange warning
- **Expired:** Red alert

### Progress Bars
- **Normal (0-79%):** Blue
- **Warning (80-99%):** Orange
- **Full (100%):** Red
- **Unlimited:** Green text

---

## 📱 Responsive Design

### Mobile (Default)
- Full-width cards
- Stacked layout
- Bottom sheet for payments

### Web (Phone Frame)
- 375x812 container
- Centered on screen
- Rounded corners (40px)
- Drop shadow

---

## ⚡ Animations

1. **Payment Processing**
   - Circular progress indicator
   - 2-second delay
   - Smooth transition

2. **Success Dialog**
   - Fade in animation
   - Green checkmark icon
   - Confetti-style design

3. **Progress Bars**
   - Animated fill
   - Color transitions
   - Smooth updates

4. **Bottom Sheet**
   - Slide up animation
   - Drag handle
   - Backdrop blur

---

## 🔔 Notifications & Warnings

### Demo Mode Notice (Always Visible)
```
┌─────────────────────────────────┐
│ ⚠️ Demo Mode                    │
│                                 │
│ This is a demonstration. No     │
│ real payment will be processed. │
│ All transactions are simulated. │
└─────────────────────────────────┘
```

### Expiring Soon Warning
```
┌─────────────────────────────────┐
│ ⚠️ Expires in 5 days            │
└─────────────────────────────────┘
```

### Approaching Limit Warning
```
┌─────────────────────────────────┐
│ ⚠️ Approaching Limit            │
│                                 │
│ You are using 4 of 5 available. │
│                                 │
│              [Upgrade]          │
└─────────────────────────────────┘
```

---

## 🎯 Key UI Elements

### Icons Used
- 🏆 `Icons.workspace_premium` - Subscription
- ⭐ `Icons.star` - Popular badge
- ✓ `Icons.check_circle` - Features included
- 🔒 `Icons.lock_outline` - Upgrade required
- 💳 `Icons.account_balance_wallet` - GCash
- 💳 `Icons.payment` - PayMaya
- 💳 `Icons.credit_card` - Card
- 🏦 `Icons.account_balance` - Bank
- ⚠️ `Icons.warning_amber` - Warnings
- 📊 `Icons.bar_chart` - Analytics

### Button Styles
- **Primary (Upgrade):** Blue, bold, rounded
- **Secondary (Cancel):** Grey text, no fill
- **Danger (Downgrade):** Orange/Red
- **Success (Done):** Green

---

**This visual guide helps understand the complete user experience!**

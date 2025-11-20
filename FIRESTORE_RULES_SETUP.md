# Firestore Rules Deployment

The `firestore.rules` file contains the security rules for your Firestore database. These rules must be deployed to Firebase Console for the app to work properly.

## How to Deploy Firestore Rules

### Option 1: Using Firebase CLI (Recommended)

1. **Install Firebase CLI** (if not already installed):

   ```bash
   npm install -g firebase-tools
   ```

2. **Login to Firebase**:

   ```bash
   firebase login
   ```

3. **Initialize Firebase in your project** (if not already done):

   ```bash
   firebase init
   ```

   - Select your project: `ibrgy-mobile-app-services`
   - Select "Firestore" feature

4. **Deploy the rules**:
   ```bash
   firebase deploy --only firestore:rules
   ```

### Option 2: Manual Deployment via Firebase Console

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: `ibrgy-mobile-app-services`
3. Navigate to **Firestore Database** → **Rules**
4. Copy the entire contents of `firestore.rules`
5. Paste into the Firebase Console editor
6. Click **Publish**

## Rules Overview

The rules in `firestore.rules` allow:

- **Authenticated users** can read and write to the database (basic access)
- **Only admins** can create new user documents (staff account creation)
- **Users** can read/write their own profile document at `users/{uid}`
- **Admins** can read all user documents to manage staff
- **Collections**: `announcements`, `hotlines`, `officials`, `info` - only admins can write, all authenticated users can read

## Troubleshooting

If you still see "PERMISSION-DENIED" errors:

1. Make sure the **admin account exists** in Firestore at `users/{admin-uid}` with `role: 'admin'`
2. Verify the rules are **published** in Firebase Console (not just in the editor)
3. Check your **Firebase project ID** matches in `lib/firebase_options.dart`
4. Clear browser cache and restart the app

## Creating an Admin User (Development)

Once logged in, create an admin document manually:

1. Go to Firebase Console → Firestore Database
2. Click **Start Collection** → name it `users`
3. Add document with ID = your Firebase Auth UID (visible in Authentication tab)
4. Add fields:
   - `role` (string) = `admin`
   - `email` (string) = `admin@ibrgy.com`
   - `name` (string) = `Administrator`
   - `createdAt` (timestamp) = current date

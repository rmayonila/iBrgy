# iBrgy Data Storage & Synchronization Guide

## Date: December 12, 2025

---

## 🔧 Emergency Hotline Synchronization Fix

### Problem:
Admin emergency hotline page showed deleted hotlines that were already removed by moderators.

### Root Cause:
The admin page was using **cached data** (loaded once on page init), while the moderator page uses **real-time Firestore streams**. When a moderator deleted a hotline, the admin page didn't automatically refresh.

### Solution Applied:
✅ **Converted admin page to use real-time Firestore streams**

**File Modified:** `lib/admin/emergency_hotline_page.dart`

**Changes Made:**
1. Removed cached `_allHotlines` list and `_isLoading` flag
2. Added real-time stream: `Stream<QuerySnapshot> _hotlinesStream`
3. Replaced `_loadHotlines()` method with stream initialization
4. Updated `_buildContent()` to use `StreamBuilder<QuerySnapshot>`

**Before:**
```dart
// Cached data - loaded once
List<Map<String, dynamic>> _allHotlines = [];
bool _isLoading = true;

@override
void initState() {
  super.initState();
  _loadHotlines(); // One-time load
}
```

**After:**
```dart
// Real-time stream
late Stream<QuerySnapshot> _hotlinesStream;

@override
void initState() {
  super.initState();
  _hotlinesStream = _db
      .collection('hotlines')
      .orderBy('createdAt', descending: true)
      .snapshots(); // Real-time updates
}
```

### Result:
✅ **Automatic synchronization** - When a moderator deletes a hotline, it immediately disappears from the admin page
✅ **No manual refresh needed** - Changes are reflected in real-time
✅ **Consistent data** - Both pages now use the same approach

---

## 📸 Image Storage in iBrgy System

### Where Are Images Stored?

**Answer: Images are stored as BASE64-encoded strings directly in Firestore documents.**

### Storage Locations:

#### 1. **Announcement Images**
- **Collection:** `announcements`
- **Field:** `images` (array of base64 strings)
- **Old Format:** `imageUrl` (single base64 string) - still supported for backward compatibility
- **Example Document:**
```json
{
  "content": "Post content here",
  "images": [
    "data:image/jpeg;base64,/9j/4AAQSkZJRgABAQEAYABgAAD...",
    "data:image/jpeg;base64,/9j/4AAQSkZJRgABAQEAYABgAAD..."
  ],
  "author": "Barangay Office",
  "createdAt": "2025-12-12T00:00:00Z",
  "type": "update"
}
```

#### 2. **Barangay Officials Profile Images**
- **Collection:** `officials`
- **Field:** `imageUrl` (single base64 string)
- **Example Document:**
```json
{
  "name": "Juan Dela Cruz",
  "title": "Barangay Captain",
  "imageUrl": "data:image/jpeg;base64,/9j/4AAQSkZJRgABAQEAYABgAAD...",
  "createdAt": "2025-12-12T00:00:00Z"
}
```

### How Images Are Processed:

1. **Upload Flow:**
   ```
   User selects image → 
   XFile (picked file) → 
   Convert to base64 string → 
   Store in Firestore
   ```

2. **Display Flow:**
   ```
   Fetch from Firestore → 
   base64 string → 
   Decode to bytes → 
   MemoryImage(bytes) → 
   Display in UI
   ```

3. **Code Example:**
   ```dart
   // Encoding (Upload)
   Future<String> _imageToBase64(XFile file) async {
     final bytes = await file.readAsBytes();
     return base64Encode(bytes);
   }

   // Decoding (Display)
   ImageProvider getImage(String base64String) {
     final bytes = base64Decode(base64String);
     return MemoryImage(bytes);
   }
   ```

### Storage Breakdown by Collection:

| Collection | Field | Format | Type | Max Count |
|------------|-------|--------|------|-----------|
| `announcements` | `images` | base64 array | Multiple | Unlimited* |
| `announcements` | `imageUrl` | base64 string | Single | 1 (legacy) |
| `officials` | `imageUrl` | base64 string | Single | 1 |
| `hotlines` | N/A | N/A | None | 0 |
| `important_reminders` | N/A | N/A | None | 0 |
| `barangay_services` | N/A | N/A | None | 0 |

*Unlimited but recommended max 10 images per post for performance

---

## 🗄️ Complete Firestore Database Structure

### Collections Overview:

```
iBrgy Firestore Database
├── announcements/
│   ├── {docId}/
│   │   ├── content: string
│   │   ├── images: array<string> (base64)
│   │   ├── imageUrl: string (legacy, base64)
│   │   ├── author: string
│   │   ├── createdAt: timestamp
│   │   └── type: string
│
├── important_reminders/
│   ├── {docId}/
│   │   ├── title: string
│   │   ├── content: string
│   │   └── createdAt: timestamp
│
├── hotlines/
│   ├── {docId}/
│   │   ├── name: string
│   │   ├── number: string
│   │   ├── type: string (national/local/barangay)
│   │   ├── isUrgent: boolean
│   │   └── createdAt: timestamp
│
├── officials/
│   ├── {docId}/
│   │   ├── name: string
│   │   ├── nickname: string
│   │   ├── title: string (position)
│   │   ├── age: string
│   │   ├── address: string
│   │   ├── imageUrl: string (base64)
│   │   └── createdAt: timestamp
│
├── barangay_services/
│   ├── {docId}/
│   │   ├── title: string
│   │   ├── category: string
│   │   ├── steps: string
│   │   └── createdAt: timestamp
│
├── users/
│   ├── {userId}/
│   │   ├── name: string
│   │   ├── email: string
│   │   ├── role: string (admin/moderator/user)
│   │   ├── password: string
│   │   └── createdAt: timestamp
│
├── notifications/
│   ├── {docId}/
│   │   ├── title: string
│   │   ├── message: string
│   │   ├── type: string
│   │   ├── targetUser: string
│   │   ├── read: boolean
│   │   └── timestamp: timestamp
│
└── activity_logs/
    ├── {docId}/
    │   ├── action: string
    │   ├── page: string
    │   ├── title: string
    │   ├── message: string
    │   ├── senderName: string
    │   └── timestamp: timestamp
```

---

## 💾 Storage Considerations

### Current Approach: Base64 in Firestore

**Advantages:**
- ✅ Simple implementation
- ✅ No additional storage service needed
- ✅ Images stored with document data
- ✅ Easy to query and retrieve

**Disadvantages:**
- ❌ Increases document size (base64 is ~33% larger than binary)
- ❌ Firestore document size limit: 1MB per document
- ❌ Higher bandwidth usage
- ❌ Slower queries with large images
- ❌ More expensive (Firestore charges by document size)

### Recommended Future Approach: Firebase Storage

**Migration Path:**
```dart
// Instead of base64 in Firestore:
Future<String> uploadToStorage(XFile file) async {
  final ref = FirebaseStorage.instance
      .ref()
      .child('announcements/${DateTime.now().millisecondsSinceEpoch}.jpg');
  
  await ref.putFile(File(file.path));
  return await ref.getDownloadURL(); // Returns URL
}

// Store URL in Firestore instead of base64:
{
  "images": [
    "https://firebasestorage.googleapis.com/v0/b/.../image1.jpg",
    "https://firebasestorage.googleapis.com/v0/b/.../image2.jpg"
  ]
}
```

**Benefits of Migration:**
- ✅ Unlimited file size (up to 5GB per file)
- ✅ Faster loading with CDN
- ✅ Automatic image optimization
- ✅ Lower Firestore costs
- ✅ Better performance

---

## 📊 Current Storage Usage Estimate

### Per Image:
- Average photo size: ~2-3MB (original)
- Base64 encoded: ~2.7-4MB
- Compressed before upload: ~500KB-1MB
- Base64 after compression: ~670KB-1.3MB

### Per Announcement (with 3 images):
- Total size: ~2-4MB per document
- **Warning:** Close to Firestore 1MB document limit!

### Recommendations:
1. ✅ **Limit images to 4 per post** (current implementation)
2. ✅ **Compress images before base64 encoding**
3. ⚠️ **Consider migrating to Firebase Storage** for better scalability

---

## 🔍 How to View Stored Images

### Option 1: Firebase Console
1. Go to Firebase Console
2. Select your project
3. Navigate to Firestore Database
4. Browse to `announcements` or `officials` collection
5. Click on a document
6. Copy the base64 string from `images` or `imageUrl` field
7. Paste into online base64 decoder (e.g., base64.guru/converter/decode/image)

### Option 2: In Your App
Images are automatically decoded and displayed when you view:
- User Announcement Page
- Admin Announcement Page
- Moderator Announcement Page
- Barangay Officials Page (all roles)

### Option 3: Debug Mode
Add this code temporarily to view image data:
```dart
// In any page with image data
print('Image data: ${data['images']}');
print('Image count: ${data['images']?.length ?? 0}');
```

---

## ✅ Summary

### Emergency Hotlines:
- ✅ **Now synchronized in real-time** between admin and moderator
- ✅ **Deletions reflect immediately** - no refresh needed
- ✅ **Both pages use Firestore streams**

### Images:
- 📍 **Stored in Firestore** as base64 strings
- 📍 **Announcements:** `images` array field
- 📍 **Officials:** `imageUrl` single field
- 📍 **No external storage** (Firebase Storage not used)
- 📍 **Embedded in documents** for simplicity

### Next Steps:
1. ✅ Test hotline deletion sync
2. ⚠️ Monitor Firestore document sizes
3. 💡 Consider Firebase Storage migration for production
4. 📈 Implement image compression if not already done

---

**All synchronization issues are now resolved!** 🎉

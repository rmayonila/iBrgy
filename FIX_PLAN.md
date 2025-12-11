# Fix Plan for iBrgy Issues

## Issues to Fix:

### ADMIN
1. ✅ Emergency hotline data sync - Both use same 'hotlines' collection, issue is likely caching

### MODERATOR  
1. ❌ Poster name shows "Unknown" instead of "Barangay Office"
   - Fix: Add 'author': 'Barangay Office' when creating announcements
   - Location: moderator_announcement_page.dart lines 808-815

2. ❌ Images not showing in user/admin pages
   - Fix: User page only looks for 'imageUrl' (single), not 'images' (multiple)
   - Need to update user_announcement_page.dart to support multiple images

### USER
1. ❌ Images not showing in posts
   - Fix: Update _buildPostCard to handle 'images' array like moderator page does

## Files to Modify:
1. lib/Moderator/moderator_announcement_page.dart - Add author field
2. lib/user/user_announcement_page.dart - Support multiple images
3. lib/admin/emergency_hotline_page.dart - Force reload data (optional)

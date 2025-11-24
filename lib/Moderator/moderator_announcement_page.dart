import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'moderator_nav.dart';

class ModeratorAnnouncementPage extends StatefulWidget {
  const ModeratorAnnouncementPage({super.key});

  @override
  State<ModeratorAnnouncementPage> createState() =>
      _ModeratorAnnouncementPageState();
}

class _ModeratorAnnouncementPageState extends State<ModeratorAnnouncementPage> {
  int _selectedIndex = 2;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // --- STATIC PINNED POSTS (Always Visible) ---
  final List<Map<String, dynamic>> _staticPosts = [
    {
      'author': 'Barangay Admin',
      'time': 'Always Pinned',
      'title': 'Office Hours',
      'content':
          'Barangay Hall is open Monday to Friday, from 8:00 AM to 5:00 PM. Closed on Holidays.',
      'type': 'pinned',
    },
    {
      'author': 'Sanitation Dept',
      'time': 'Weekly Schedule',
      'title': 'Garbage Collection',
      'content':
          'Garbage collection is scheduled every Tuesday and Friday morning. Please segregate your waste properly.',
      'type': 'pinned',
    },
    {
      'author': 'Security',
      'time': 'Daily',
      'title': 'Curfew Hours',
      'content':
          'Curfew hours for minors are strictly observed from 10:00 PM to 4:00 AM.',
      'type': 'pinned',
    },
  ];

  // Dynamic Data from Firestore
  List<Map<String, dynamic>> _dynamicPosts = [];

  // Filtered Data
  List<Map<String, dynamic>> _filteredStatic = [];
  List<Map<String, dynamic>> _filteredDynamic = [];

  @override
  void initState() {
    super.initState();
    _filteredStatic = List.from(_staticPosts);
    _loadAnnouncements();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    navigateModeratorIndex(
      context,
      index,
      currentIndex: _selectedIndex,
      onSamePage: (i) => setState(() => _selectedIndex = i),
    );
  }

  Future<void> _ensureSignedIn() async {
    try {
      if (_auth.currentUser == null) {
        await _auth.signInAnonymously();
      }
    } catch (e) {
      // ignore sign-in errors
    }
  }

  Future<void> _loadAnnouncements() async {
    try {
      final snap = await _db
          .collection('announcements')
          .orderBy('createdAt', descending: true)
          .get();
      if (!mounted) return;
      final items = snap.docs.map((d) {
        final data = d.data();
        return {
          'id': d.id,
          'author': (data['author'] ?? 'Barangay Office').toString(),
          'time': data['createdAt'] != null
              ? _formatTimestamp(data['createdAt'])
              : 'recently',
          'content': (data['content'] ?? '').toString(),
          'type': 'dynamic',
        };
      }).toList();

      setState(() {
        _dynamicPosts = items;
        _filteredDynamic = items;
      });
    } catch (e) {
      // ignore load errors
    }
  }

  void _filterPosts(String query) {
    if (query.isEmpty) {
      setState(() {
        _filteredStatic = List.from(_staticPosts);
        _filteredDynamic = List.from(_dynamicPosts);
      });
      return;
    }

    final lowerQuery = query.toLowerCase();

    setState(() {
      // Filter Static
      _filteredStatic = _staticPosts.where((post) {
        return (post['title'] ?? '').toLowerCase().contains(lowerQuery) ||
            (post['content'] ?? '').toLowerCase().contains(lowerQuery);
      }).toList();

      // Filter Dynamic
      _filteredDynamic = _dynamicPosts.where((post) {
        return (post['content'] ?? '').toLowerCase().contains(lowerQuery) ||
            (post['author'] ?? '').toLowerCase().contains(lowerQuery);
      }).toList();
    });
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp is Timestamp) {
      final date = timestamp.toDate();
      return "${date.month}/${date.day}/${date.year}";
    }
    return 'recently';
  }

  // --- CRUD OPERATIONS ---

  // ADD Announcement
  Future<void> _showAddAnnouncementDialog() async {
    final contentController = TextEditingController();

    final entered = await showDialog<Map<String, String>>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Create Announcement'),
        content: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: contentController,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    labelText: 'Announcement Content',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(null),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop({'content': contentController.text.trim()});
            },
            child: const Text('Post'),
          ),
        ],
      ),
    );

    contentController.dispose();

    if (entered != null) {
      if (!mounted) return;
      final scaffold = ScaffoldMessenger.of(context);
      final content = entered['content'] ?? '';

      if (content.isEmpty) {
        scaffold.showSnackBar(
          const SnackBar(content: Text('Please write something')),
        );
        return;
      }

      try {
        await _ensureSignedIn();
        final docRef = await _db.collection('announcements').add({
          'author': 'Barangay Office',
          'content': content,
          'createdAt': FieldValue.serverTimestamp(),
        });

        if (!mounted) return;
        setState(() {
          _dynamicPosts.insert(0, {
            'id': docRef.id,
            'author': 'Barangay Office',
            'time': 'Just now',
            'content': content,
            'type': 'dynamic',
          });
          _filteredDynamic = List.from(_dynamicPosts);
        });
        scaffold.showSnackBar(
          const SnackBar(content: Text('Announcement posted')),
        );
      } catch (e) {
        scaffold.showSnackBar(
          SnackBar(content: Text('Failed to post announcement: $e')),
        );
      }
    }
  }

  // EDIT Announcement
  Future<void> _showEditAnnouncementDialog(Map<String, dynamic> post) async {
    final contentController = TextEditingController(text: post['content']);

    final entered = await showDialog<Map<String, String>>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Announcement'),
        content: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: contentController,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    labelText: 'Announcement Content',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(null),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop({'content': contentController.text.trim()});
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    contentController.dispose();

    if (entered != null) {
      if (!mounted) return;
      final scaffold = ScaffoldMessenger.of(context);
      final newContent = entered['content'] ?? '';

      if (newContent.isEmpty) {
        scaffold.showSnackBar(
          const SnackBar(content: Text('Please write something')),
        );
        return;
      }

      try {
        final postId = post['id'];
        await _db.collection('announcements').doc(postId).update({
          'content': newContent,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        if (!mounted) return;
        setState(() {
          final index = _dynamicPosts.indexWhere((p) => p['id'] == postId);
          if (index != -1) {
            _dynamicPosts[index]['content'] = newContent;
            _filteredDynamic = List.from(_dynamicPosts);
          }
        });
        scaffold.showSnackBar(
          const SnackBar(content: Text('Announcement updated')),
        );
      } catch (e) {
        scaffold.showSnackBar(
          SnackBar(content: Text('Failed to update announcement: $e')),
        );
      }
    }
  }

  // DELETE Announcement
  Future<void> _deleteAnnouncement(Map<String, dynamic> post) async {
    final postId = post['id'];
    final scaffold = ScaffoldMessenger.of(context);

    final confirmDelete = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Deletion'),
        content: const Text(
          'Are you sure you want to delete this announcement?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmDelete == true && postId != null) {
      try {
        await _db.collection('announcements').doc(postId).delete();

        if (!mounted) return;
        setState(() {
          _dynamicPosts.removeWhere((p) => p['id'] == postId);
          _filteredDynamic = List.from(_dynamicPosts);
        });
        scaffold.showSnackBar(
          const SnackBar(content: Text('Announcement deleted')),
        );
      } catch (e) {
        scaffold.showSnackBar(
          SnackBar(content: Text('Failed to delete announcement: $e')),
        );
      }
    }
  }

  // --- WIDGET BUILDERS ---

  Widget _buildHeader() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.campaign_rounded,
              color: Colors.blue,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          RichText(
            text: TextSpan(
              children: [
                const TextSpan(
                  text: 'iB',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Colors.blue,
                    letterSpacing: -0.5,
                  ),
                ),
                TextSpan(
                  text: 'rgy',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Colors.blue.shade900,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: () {},
            icon: const Icon(
              Icons.notifications_none_rounded,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: _filterPosts,
        decoration: InputDecoration(
          hintText: "Search updates...",
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
          prefixIcon: Icon(Icons.search, color: Colors.grey.shade400),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12, top: 8),
      child: Row(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
              letterSpacing: 0.5,
            ),
          ),
          const Spacer(),
          if (title == "RECENT UPDATES")
            IconButton(
              onPressed: _showAddAnnouncementDialog,
              icon: const Icon(Icons.add, size: 20),
              color: Colors.blue,
              tooltip: 'Add Announcement',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
        ],
      ),
    );
  }

  Widget _buildPostCard(Map<String, dynamic> post) {
    final isPinned = post['type'] == 'pinned';
    final isDynamic = post['type'] == 'dynamic';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isPinned ? const Color(0xFFFFFDF5) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isPinned ? Border.all(color: Colors.amber.shade200) : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isPinned
                        ? Colors.amber.shade100
                        : Colors.blue.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: isPinned
                        ? Icon(
                            Icons.push_pin_rounded,
                            color: Colors.amber.shade800,
                            size: 20,
                          )
                        : Text(
                            (post['author'] ?? 'U')
                                .substring(0, 1)
                                .toUpperCase(),
                            style: const TextStyle(
                              color: Colors.blue,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isPinned
                            ? (post['title'] ?? 'Reminder')
                            : (post['author'] ?? 'Unknown'),
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: isPinned
                              ? Colors.amber.shade900
                              : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        post['time'] ?? '',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isDynamic)
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') {
                        _showEditAnnouncementDialog(post);
                      } else if (value == 'delete') {
                        _deleteAnnouncement(post);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 20),
                            SizedBox(width: 8),
                            Text('Edit'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 20, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Delete', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                    icon: Icon(
                      Icons.more_horiz_rounded,
                      color: Colors.grey.shade300,
                    ),
                  )
                else
                  Icon(Icons.more_horiz_rounded, color: Colors.grey.shade300),
              ],
            ),

            const SizedBox(height: 12),

            // Content Text
            Text(
              post['content'] ?? '',
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: Colors.black87.withOpacity(0.8),
              ),
            ),

            // Only show image placeholder for dynamic posts
            if (isDynamic) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                height: 140,
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade100),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.image_outlined,
                      color: Colors.grey.shade300,
                      size: 32,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "No Image Attached",
                      style: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: 2,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey.shade400,
        backgroundColor: Colors.white,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        selectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
        elevation: 0,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.phone_rounded),
            label: 'Emergency',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.campaign_rounded),
            label: 'Updates',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_alt_rounded),
            label: 'People',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSearchBar(),
                    const SizedBox(height: 24),
                    const Text(
                      'Barangay Updates',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // IMPORTANT REMINDERS (Static Pinned Posts)
                    if (_filteredStatic.isNotEmpty) ...[
                      _buildSectionTitle("IMPORTANT REMINDERS"),
                      Column(
                        children: [
                          for (var post in _filteredStatic)
                            _buildPostCard(post),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],

                    // RECENT UPDATES (Dynamic Posts - Moderator can CRUD)
                    _buildSectionTitle("RECENT UPDATES"),

                    if (_filteredDynamic.isEmpty && _searchQuery.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.campaign_outlined,
                              size: 40,
                              color: Colors.grey.shade300,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              "No recent updates",
                              style: TextStyle(
                                color: Colors.grey.shade500,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Tap + to add new announcement",
                              style: TextStyle(
                                color: Colors.grey.shade400,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      )
                    else if (_filteredDynamic.isEmpty &&
                        _searchQuery.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Center(
                          child: Text(
                            "No matching updates found",
                            style: TextStyle(color: Colors.grey[500]),
                          ),
                        ),
                      )
                    else
                      Column(
                        children: [
                          for (var post in _filteredDynamic)
                            _buildPostCard(post),
                        ],
                      ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }
}

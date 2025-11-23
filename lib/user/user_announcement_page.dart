// ignore_for_file: use_build_context_synchronously
import 'package:flutter/foundation.dart'; // For web check
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // For logout
import 'package:cloud_firestore/cloud_firestore.dart';
import '../splash_screen.dart'; // Import your splash screen

class UserAnnouncementPage extends StatefulWidget {
  const UserAnnouncementPage({super.key});

  @override
  State<UserAnnouncementPage> createState() => _UserAnnouncementPageState();
}

class _UserAnnouncementPageState extends State<UserAnnouncementPage> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // --- STATIC PINNED POSTS (Always Visible) ---
  final List<Map<String, String>> _staticPosts = [
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

  // Dynamic Data
  List<Map<String, String>> _dynamicPosts = [];

  // Filtered Data
  List<Map<String, String>> _filteredStatic = [];
  List<Map<String, String>> _filteredDynamic = [];

  final TextEditingController _searchController = TextEditingController();

  // Navigation for User
  void _onItemTapped(BuildContext context, int index) {
    if (index == 0) {
      Navigator.pushReplacementNamed(context, '/user-home');
    } else if (index == 1) {
      Navigator.pushReplacementNamed(context, '/user-emergency-hotline');
    } else if (index == 3) {
      Navigator.pushReplacementNamed(context, '/user-brgy-officials');
    }
  }

  @override
  void initState() {
    super.initState();
    // Initialize filtered lists
    _filteredStatic = List.from(_staticPosts);
    _loadAnnouncements();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAnnouncements() async {
    try {
      final snap = await _db
          .collection('announcements')
          .orderBy('createdAt', descending: true)
          .get();
      final items = snap.docs.map((d) {
        final data = d.data();
        return {
          'id': d.id,
          'author': (data['author'] ?? '').toString(),
          'time': data['createdAt'] != null
              ? _formatTimestamp(data['createdAt'])
              : 'recently',
          'content': (data['content'] ?? '').toString(),
          'type': 'dynamic',
        };
      }).toList();

      if (!mounted) return;
      setState(() {
        _dynamicPosts = items;
        _filteredDynamic = items; // Initial state
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

  // --- EXIT / LOGOUT FUNCTION ---
  Future<void> _handleBackOrLogout() async {
    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        elevation: 10,
        insetPadding: const EdgeInsets.symmetric(horizontal: 60),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),

        title: const Text(
          'Exit',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        content: const Text(
          'Are you sure you want to exit?',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.black87, fontSize: 14),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actionsPadding: const EdgeInsets.only(bottom: 16, left: 8, right: 8),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Exit',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (shouldExit == true) {
      try {
        await FirebaseAuth.instance.signOut();
      } catch (_) {}

      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const SplashScreen()),
        (r) => false,
      );
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

          // --- EXIT / BACK ICON ---
          IconButton(
            onPressed: _handleBackOrLogout,
            icon: const Icon(
              Icons.logout, // Visual "Exit" icon
              color: Colors.red,
            ),
            tooltip: "Exit",
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
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.grey.shade600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildPostCard(Map<String, String> post) {
    final isPinned = post['type'] == 'pinned';

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
                if (!isPinned)
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

            if (!isPinned) ...[
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
        currentIndex: 2, // Highlight 'Updates'
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
        onTap: (index) => _onItemTapped(context, index),
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
            icon: ContainerIcon(icon: Icons.campaign_rounded),
            label: 'Updates',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_alt_rounded),
            label: 'People',
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget mobileContent = Scaffold(
      backgroundColor: const Color(0xFFF8F9FA), // Matches Admin Home bg
      body: SafeArea(
        child: Column(
          children: [
            // --- HEADER ---
            _buildHeader(),

            // --- SCROLLABLE BODY ---
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Search Bar
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

                    // 2. Pinned Posts (Static)
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

                    // 3. Dynamic Posts (From Firestore)
                    _buildSectionTitle("RECENT UPDATES"),

                    if (_filteredDynamic.isEmpty &&
                        _searchController.text.isEmpty)
                      // Empty State (No Search, No Data)
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
                              "Check the reminders above for info",
                              style: TextStyle(
                                color: Colors.grey.shade400,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      )
                    else if (_filteredDynamic.isEmpty &&
                        _searchController.text.isNotEmpty)
                      // Empty State (Search Active)
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
                      // Data Exists
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

    if (kIsWeb) {
      return PhoneFrame(child: mobileContent);
    }
    return mobileContent;
  }
}

// --- HELPER CLASS FOR CUSTOM ICON ---
class ContainerIcon extends StatelessWidget {
  final IconData icon;
  const ContainerIcon({super.key, required this.icon});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 24, color: Colors.blue),
    );
  }
}

// --- PHONE FRAME ---
class PhoneFrame extends StatelessWidget {
  final Widget child;
  const PhoneFrame({super.key, required this.child});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      body: Center(
        child: Container(
          width: 375,
          height: 812,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(40),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 30,
                spreadRadius: 5,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(40),
            child: child,
          ),
        ),
      ),
    );
  }
}

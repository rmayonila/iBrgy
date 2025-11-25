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
  // 🔑 Real-time stream for announcements
  final Stream<QuerySnapshot> _announcementsStream = FirebaseFirestore.instance
      .collection('announcements')
      .orderBy('createdAt', descending: true)
      .snapshots();

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

  List<Map<String, dynamic>> _filteredStatic = [];
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
    _filteredStatic = List.from(_staticPosts);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterPosts(String query) {
    final lowerQuery = query.toLowerCase();
    setState(() {
      _filteredStatic = _staticPosts.where((post) {
        return (post['title']?.toString() ?? '').toLowerCase().contains(
              lowerQuery,
            ) ||
            (post['content']?.toString() ?? '').toLowerCase().contains(
              lowerQuery,
            );
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
          IconButton(
            onPressed: _handleBackOrLogout,
            icon: const Icon(Icons.logout, color: Colors.red),
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

  Widget _buildPostCard(Map<String, dynamic> post) {
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
                            (post['author']?.toString() ?? 'U')
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
                            ? (post['title']?.toString() ?? 'Reminder')
                            : (post['author']?.toString() ?? 'Unknown'),
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
                        post['time']?.toString() ?? '',
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
            Text(
              post['content']?.toString() ?? '',
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
                    // Pinned Posts (Static)
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
                    // Dynamic Posts - Real-time with StreamBuilder
                    _buildSectionTitle("RECENT UPDATES"),
                    StreamBuilder<QuerySnapshot>(
                      stream: _announcementsStream,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(32.0),
                              child: CircularProgressIndicator(),
                            ),
                          );
                        }
                        if (snapshot.hasError) {
                          return Center(
                            child: Text(
                              'Error loading data: ${snapshot.error}',
                            ),
                          );
                        }

                        final documents = snapshot.data?.docs ?? [];
                        final dynamicPosts = documents.map((d) {
                          final data = d.data() as Map<String, dynamic>;
                          return <String, dynamic>{
                            'id': d.id,
                            'author': (data['author'] ?? 'Moderator')
                                .toString(),
                            'time': data['createdAt'] != null
                                ? _formatTimestamp(data['createdAt'])
                                : 'recently',
                            'content': (data['content'] ?? 'No content')
                                .toString(),
                            'type': 'dynamic',
                          };
                        }).toList();

                        // Apply search filter
                        final currentQuery = _searchController.text
                            .toLowerCase();
                        final filteredDynamicPosts = dynamicPosts.where((post) {
                          return (post['content']?.toString() ?? '')
                                  .toLowerCase()
                                  .contains(currentQuery) ||
                              (post['author']?.toString() ?? '')
                                  .toLowerCase()
                                  .contains(currentQuery);
                        }).toList();

                        // Empty states
                        if (filteredDynamicPosts.isEmpty) {
                          if (currentQuery.isNotEmpty) {
                            return Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Center(
                                child: Text(
                                  "No matching updates found",
                                  style: TextStyle(color: Colors.grey[500]),
                                ),
                              ),
                            );
                          } else {
                            return Container(
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
                            );
                          }
                        }

                        // Display posts
                        return Column(
                          children: [
                            for (var post in filteredDynamicPosts)
                              _buildPostCard(post),
                          ],
                        );
                      },
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

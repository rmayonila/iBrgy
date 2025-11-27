// ignore_for_file: use_build_context_synchronously
import 'dart:convert'; // Required for image decoding
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
  // 1. Stream for Regular Announcements (Same as Moderator)
  final Stream<QuerySnapshot> _announcementsStream = FirebaseFirestore.instance
      .collection('announcements')
      .orderBy('createdAt', descending: true)
      .snapshots();

  // 2. Stream for Important Reminders (Same as Moderator)
  final Stream<QuerySnapshot> _remindersStream = FirebaseFirestore.instance
      .collection('important_reminders')
      .orderBy('createdAt', descending: true)
      .snapshots();

  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

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

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp is Timestamp) {
      final date = timestamp.toDate();
      return "${date.month}/${date.day}/${date.year}";
    }
    return 'recently';
  }

  // --- EXIT / LOGOUT FUNCTION (Kept from User Page) ---
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
          // EXIT BUTTON (Kept as requested)
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
        // We will trigger a rebuild when text changes to filter the lists
        onChanged: (val) => setState(() {}),
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

  // --- SECTION HEADER (Simplified for User - No Add Button) ---
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

  // --- IMPORTANT REMINDER CARD (View Only) ---
  Widget _buildImportantReminderCard(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBE6), // Yellowish background
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFE58F), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFECB3),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.push_pin_rounded,
                    color: Colors.orange.shade900,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data['title'] ?? 'Reminder',
                        style: TextStyle(
                          color: Colors.orange.shade900,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Important Reminder',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                // REMOVED: PopupMenuButton (Edit/Delete)
              ],
            ),
            const SizedBox(height: 12),
            Text(
              data['content'] ?? '',
              style: TextStyle(
                color: Colors.grey.shade800,
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyRemindersPlaceholder() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(
            Icons.notifications_off_outlined,
            size: 40,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 8),
          Text(
            'No important reminders yet.',
            style: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // --- RECENT UPDATE CARD (View Only - With Image Support) ---
  Widget _buildPostCard(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final imageUrl = data['imageUrl']?.toString() ?? '';

    // Helper to decode image string
    ImageProvider? getPostImage() {
      if (imageUrl.isEmpty) return null;
      try {
        return MemoryImage(base64Decode(imageUrl));
      } catch (e) {
        return null;
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
                    color: Colors.blue.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      (data['author']?.toString() ?? 'U')
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
                        data['author']?.toString() ?? 'Barangay Office',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        data['createdAt'] != null
                            ? _formatTimestamp(data['createdAt'])
                            : 'recently',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                // REMOVED: PopupMenuButton (Edit/Delete)
              ],
            ),
            const SizedBox(height: 12),
            Text(
              data['content']?.toString() ?? '',
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: Colors.black87.withOpacity(0.8),
              ),
            ),
            // Display Image if available
            if (getPostImage() != null) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                height: 180,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.grey.shade100,
                  image: DecorationImage(
                    image: getPostImage()!,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // --- USER NAVBAR (Kept as requested) ---
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

                    // --- SECTION 1: IMPORTANT REMINDERS (Dynamic Stream) ---
                    _buildSectionTitle("IMPORTANT REMINDERS"),
                    StreamBuilder<QuerySnapshot>(
                      stream: _remindersStream,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(8.0),
                              child: CircularProgressIndicator(),
                            ),
                          );
                        }
                        if (snapshot.hasError) {
                          return const Text('Something went wrong');
                        }

                        final docs = snapshot.data?.docs ?? [];
                        if (docs.isEmpty) {
                          return _buildEmptyRemindersPlaceholder();
                        }

                        // Filter by search query
                        final searchQuery = _searchController.text
                            .toLowerCase();
                        final filteredDocs = docs.where((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          final title = (data['title'] ?? '')
                              .toString()
                              .toLowerCase();
                          final content = (data['content'] ?? '')
                              .toString()
                              .toLowerCase();
                          return title.contains(searchQuery) ||
                              content.contains(searchQuery);
                        }).toList();

                        if (filteredDocs.isEmpty && searchQuery.isNotEmpty) {
                          return const Center(
                            child: Text(
                              "No reminders found",
                              style: TextStyle(color: Colors.grey),
                            ),
                          );
                        }

                        return Column(
                          children: filteredDocs
                              .map((doc) => _buildImportantReminderCard(doc))
                              .toList(),
                        );
                      },
                    ),

                    const SizedBox(height: 24),

                    // --- SECTION 2: RECENT UPDATES (Dynamic Stream) ---
                    _buildSectionTitle("RECENT UPDATES"),
                    StreamBuilder<QuerySnapshot>(
                      stream: _announcementsStream,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Padding(
                            padding: EdgeInsets.all(20),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                        final docs = snapshot.data?.docs ?? [];
                        if (docs.isEmpty) {
                          return const Center(
                            child: Text(
                              "No recent updates",
                              style: TextStyle(color: Colors.grey),
                            ),
                          );
                        }

                        // Filter by search query
                        final searchQuery = _searchController.text
                            .toLowerCase();
                        final filteredDocs = docs.where((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          final content = (data['content'] ?? '')
                              .toString()
                              .toLowerCase();
                          return content.contains(searchQuery);
                        }).toList();

                        if (filteredDocs.isEmpty && searchQuery.isNotEmpty) {
                          return const Center(
                            child: Text(
                              "No updates found",
                              style: TextStyle(color: Colors.grey),
                            ),
                          );
                        }

                        return Column(
                          children: filteredDocs.map((doc) {
                            return _buildPostCard(doc);
                          }).toList(),
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

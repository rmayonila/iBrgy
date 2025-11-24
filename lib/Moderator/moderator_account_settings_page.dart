import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'moderator_nav.dart';
import '../splash_screen.dart';
import 'moderator_help_support_page.dart';
import 'moderator_activity_report_page.dart';
import 'moderator_my_post_page.dart';
import 'moderator_schedule_content_page.dart';

class ModeratorAccountSettingsPage extends StatefulWidget {
  const ModeratorAccountSettingsPage({super.key});

  @override
  State<ModeratorAccountSettingsPage> createState() =>
      _ModeratorAccountSettingsPageState();
}

class _ModeratorAccountSettingsPageState
    extends State<ModeratorAccountSettingsPage> {
  int _selectedIndex = 4; // Profile tab
  String moderatorName = 'MODERATOR';
  String moderatorEmail = 'Loading...';
  String moderatorRole = 'Content Moderator';

  @override
  void initState() {
    super.initState();
    _loadModeratorProfile();
  }

  Future<void> _loadModeratorProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        moderatorName = 'Moderator';
        moderatorEmail = 'moderator@ibrgy.com';
      });
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (doc.exists) {
        final data = doc.data();
        setState(() {
          moderatorName =
              (data?['name'] as String?) ?? user.displayName ?? 'Moderator';
          moderatorEmail = (data?['email'] as String?) ?? user.email ?? '';
          moderatorRole = (data?['role'] as String?) ?? 'Content Moderator';
        });
        return;
      }
    } catch (_) {}

    setState(() {
      moderatorName = user.displayName ?? 'Moderator';
      moderatorEmail = user.email ?? '';
    });
  }

  void _onItemTapped(int index) {
    navigateModeratorIndex(
      context,
      index,
      currentIndex: _selectedIndex,
      onSamePage: (i) => setState(() => _selectedIndex = i),
    );
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
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 30.0),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor:
                Colors.green.shade50, // Different color for moderator
            child: const Icon(
              Icons.verified_user,
              color: Colors.green,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  moderatorName,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  moderatorEmail,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    moderatorRole,
                    style: TextStyle(
                      color: Colors.green.shade800,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0, left: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupContainer(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? textColor,
    Color? iconColor,
    bool showDivider = true,
  }) {
    return Column(
      children: [
        ListTile(
          onTap: onTap,
          leading: Icon(icon, color: iconColor ?? Colors.black87),
          title: Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 15,
              color: textColor ?? Colors.black87,
            ),
          ),
          trailing: const Icon(Icons.chevron_right, color: Colors.grey),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 4,
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            thickness: 0.5,
            color: Colors.grey.shade300,
            indent: 60,
          ),
      ],
    );
  }

  // --- ENHANCED NAVBAR BUILDER ---
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
        currentIndex: _selectedIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.green, // Different color for moderator
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
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // 1. Custom Header
            _buildHeader(),

            // 2. Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- SECTION 1: PROFILE & CONTENT MANAGEMENT ---
                    _buildSectionHeader(
                      "Profile & Content",
                      "Manage your profile and content responsibilities",
                    ),
                    _buildGroupContainer([
                      _buildListTile(
                        icon: Icons.analytics_outlined,
                        title: 'My Activity Report',
                        showDivider: false,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const ModeratorActivityReportPage(),
                            ),
                          );
                        },
                      ),
                    ]),

                    const SizedBox(height: 30),

                    // --- SECTION 2: CONTENT MANAGEMENT TOOLS ---
                    _buildSectionHeader(
                      "Content Tools",
                      "Tools for managing announcements and posts",
                    ),
                    // In the Content Tools section:
                    _buildGroupContainer([
                      _buildListTile(
                        icon: Icons.post_add,
                        title: 'My Posts & Announcements',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ModeratorMyPostPage(),
                            ),
                          );
                        },
                      ),
                      _buildListTile(
                        icon: Icons.schedule,
                        title: 'Scheduled Content',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const ModeratorScheduledContentPage(),
                            ),
                          );
                        },
                      ),
                    ]),
                    const SizedBox(height: 30),

                    // --- SECTION 3: ACCOUNT & SUPPORT ---
                    _buildSectionHeader(
                      "Account & Support",
                      "Manage your account and get help",
                    ),
                    _buildGroupContainer([
                      _buildListTile(
                        icon: Icons.help_outline,
                        title: 'Help & Support',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const ModeratorHelpSupportPage(),
                            ),
                          );
                        },
                      ),

                      _buildListTile(
                        icon: Icons.logout,
                        title: 'Log Out',
                        textColor: Colors.red,
                        iconColor: Colors.red,
                        showDivider: false,
                        onTap: () => _handleLogout(),
                      ),
                    ]),
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

  Future<void> _handleLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text(
          'Log out',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        content: const Text(
          'Are you sure you want to log out?',
          style: TextStyle(color: Colors.black87, fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Cancel',
              style: TextStyle(
                color: Colors.blue,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Log out',
              style: TextStyle(
                color: Colors.red,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      await FirebaseAuth.instance.signOut();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const SplashScreen()),
        (r) => false,
      );
    }
  }
}

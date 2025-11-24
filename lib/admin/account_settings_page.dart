// ignore_for_file: use_build_context_synchronously
import 'package:flutter/foundation.dart'; // Required for kIsWeb
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../splash_screen.dart';
import 'admin_notifications_page.dart';
import 'edit_profile_page.dart';
import 'manage_moderators_page.dart';
import 'change_password_page.dart'; // Import the separated file
import 'help_support_page.dart'; // Import the separated file

class AccountSettingsPage extends StatefulWidget {
  const AccountSettingsPage({super.key});

  @override
  State<AccountSettingsPage> createState() => _AccountSettingsPageState();
}

class _AccountSettingsPageState extends State<AccountSettingsPage> {
  String adminName = 'ADMIN';
  String adminEmail = 'Loading...';

  @override
  void initState() {
    super.initState();
    _loadAdminProfile();
  }

  Future<void> _loadAdminProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        adminName = 'Admin';
        adminEmail = 'admin@ibrgy.com';
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
          adminName = (data?['name'] as String?) ?? user.displayName ?? 'Admin';
          adminEmail = (data?['email'] as String?) ?? user.email ?? '';
        });
        return;
      }
    } catch (_) {}

    setState(() {
      adminName = user.displayName ?? 'Admin';
      adminEmail = user.email ?? '';
    });
  }

  void _onItemTapped(BuildContext context, int index) {
    if (index == 0) {
      Navigator.pushReplacementNamed(context, '/admin-home');
    } else if (index == 1) {
      Navigator.pushReplacementNamed(context, '/emergency-hotline');
    } else if (index == 2) {
      Navigator.pushReplacementNamed(context, '/announcement');
    } else if (index == 3) {
      Navigator.pushReplacementNamed(context, '/brgy-officials');
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
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 30.0),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: Colors.blue.shade50,
            child: const Icon(Icons.person, color: Colors.blue, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  adminName,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  adminEmail,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
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
        color: const Color(0xFFF8F9FA), // Very light grey
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
        currentIndex: 4, // Highlight 'Profile'
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
    Widget mobileContent = Scaffold(
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
                    // --- SECTION 1: ACCOUNT ---
                    _buildSectionHeader(
                      "Account",
                      "Update your info to keep your account",
                    ),
                    _buildGroupContainer([
                      _buildListTile(
                        icon: Icons.person_outline,
                        title: 'Edit Profile',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EditProfilePage(
                                initialName: adminName,
                                initialEmail: adminEmail,
                              ),
                            ),
                          );
                        },
                      ),
                      _buildListTile(
                        icon: Icons.notifications_none,
                        title: 'Notifications',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const AdminNotificationsPage(),
                            ),
                          );
                        },
                      ),
                      _buildListTile(
                        icon: Icons.supervisor_account_outlined,
                        title: 'Manage Moderators',
                        showDivider: false, // Last item in group
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const ManageModeratorsPage(),
                            ),
                          );
                        },
                      ),
                    ]),

                    const SizedBox(height: 30),

                    // --- SECTION 2: PRIVACY & SUPPORT ---
                    _buildSectionHeader(
                      "Support & Privacy",
                      "Customize your experience",
                    ),
                    _buildGroupContainer([
                      _buildListTile(
                        icon: Icons.help_outline,
                        title: 'Help & Support',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const HelpSupportPage(),
                            ),
                          );
                        },
                      ),
                      _buildListTile(
                        icon: Icons.lock_outline,
                        title: 'Change Password',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ChangePasswordPage(),
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

    if (kIsWeb) {
      return PhoneFrame(child: mobileContent);
    }

    return mobileContent;
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

// --- PHONE FRAME ---
class PhoneFrame extends StatelessWidget {
  final Widget child;

  const PhoneFrame({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7), // Background behind phone
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

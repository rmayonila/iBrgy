// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../splash_screen.dart';
import 'admin_notifications_page.dart';
import 'add_staff_account_page.dart';
import 'edit_profile_page.dart';

class AccountSettingsPage extends StatefulWidget {
  const AccountSettingsPage({super.key});

  @override
  State<AccountSettingsPage> createState() => _AccountSettingsPageState();
}

class _AccountSettingsPageState extends State<AccountSettingsPage> {
  String adminName = 'ADMIN';
  String adminEmail = 'Administrator';
  @override
  void initState() {
    super.initState();
    _loadAdminProfile();
  }

  Future<void> _loadAdminProfile() async {
    final user = FirebaseAuth.instance.currentUser;

    // Development fallback: if no Firebase user (dev shortcut login), show default admin
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
    } catch (_) {
      // ignore and fallback to auth user
    }

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

  // Removed unused helper: _showAddStaffDialog
  // The application currently navigates to a dedicated `AddStaffAccountPage` instead.

  Widget _buildProfileSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: const BoxDecoration(
              color: Colors.grey,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person, size: 40, color: Colors.white),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  adminName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                Text(
                  adminEmail,
                  style: const TextStyle(fontSize: 14, color: Colors.black),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsButton({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(icon, color: iconColor ?? Colors.grey),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                ),
                const Spacer(),
                Icon(Icons.chevron_right, color: Colors.grey.shade400),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(0),
        child: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: Colors.white,
          elevation: 0,
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProfileSection(),
              const SizedBox(height: 24),
              _buildSettingsButton(
                title: 'Edit Profile',
                icon: Icons.edit,
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
              _buildSettingsButton(
                title: 'Add Account for Moderator',
                icon: Icons.person_add,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AddStaffAccountPage(),
                    ),
                  );
                },
              ),
              _buildSettingsButton(
                title: 'Notifications',
                icon: Icons.notifications_outlined,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AdminNotificationsPage(),
                    ),
                  );
                },
              ),

              // Simple notifications page for demonstration
              _buildSettingsButton(
                title: 'Help & Support',
                icon: Icons.help_outline,
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      backgroundColor: Colors.white,
                      title: const Text(
                        'Help & Support',
                        style: TextStyle(color: Colors.black),
                      ),
                      content: const Text(
                        'For assistance, please contact our support team at:\n\nEmail: support@ibrgy.com\nPhone: (123) 456-7890\n\nOr visit our website for FAQs and more help.',
                        style: TextStyle(color: Colors.black),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text(
                            'Close',
                            style: TextStyle(color: Colors.blue),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              _buildSettingsButton(
                title: 'Log Out',
                icon: Icons.logout,
                iconColor: Colors.red,
                onTap: () async {
                  // Confirm logout with the user before signing out
                  final parentContext = context;
                  final shouldLogout = await showDialog<bool>(
                    context: parentContext,
                    builder: (context) => AlertDialog(
                      backgroundColor: Colors.white,
                      title: const Text(
                        'Log out',
                        style: TextStyle(color: Colors.black),
                      ),
                      content: const Text(
                        'Are you sure you want to log out?',
                        style: TextStyle(color: Colors.black),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(color: Colors.blue),
                          ),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          child: const Text(
                            'Log out',
                            style: TextStyle(color: Colors.blue),
                          ),
                        ),
                      ],
                    ),
                  );

                  if (!mounted) return;
                  if (shouldLogout == true) {
                    // Sign out from Firebase Auth (if signed in) and navigate to login
                    try {
                      await FirebaseAuth.instance.signOut();
                    } catch (e) {
                      debugPrint('Sign out error: $e');
                    }

                    if (!mounted) return;
                    // Remove all routes and go to login
                    Navigator.pushAndRemoveUntil(
                      parentContext,
                      MaterialPageRoute(builder: (_) => const SplashScreen()),
                      (r) => false,
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 4, // Profile icon selected
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.white,
        showSelectedLabels: true,
        elevation: 8,
        onTap: (index) => _onItemTapped(context, index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.phone), label: 'Emergency'),
          BottomNavigationBarItem(
            icon: Icon(Icons.announcement, size: 30),
            label: 'Updates',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'People'),
          BottomNavigationBarItem(
            icon: Icon(Icons.person, color: Colors.blue),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

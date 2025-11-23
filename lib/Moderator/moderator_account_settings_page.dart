// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'moderator_notifications_page.dart';
// 1. Import the new edit page
import 'moderator_edit_profile_page.dart';
import 'moderator_nav.dart';
import '../splash_screen.dart';

class ModeratorAccountSettingsPage extends StatefulWidget {
  const ModeratorAccountSettingsPage({super.key});

  @override
  State<ModeratorAccountSettingsPage> createState() =>
      _StaffAccountSettingsPageState();
}

class _StaffAccountSettingsPageState
    extends State<ModeratorAccountSettingsPage> {
  int _selectedIndex = 4; // Profile tab

  void _onItemTapped(int index) {
    navigateModeratorIndex(
      context,
      index,
      currentIndex: _selectedIndex,
      onSamePage: (i) => setState(() => _selectedIndex = i),
    );
  }

  Widget _buildProfileSection() {
    final user = FirebaseAuth.instance.currentUser;
    // Display actual name if available, otherwise 'MODERATOR'
    final displayName = user?.displayName ?? 'MODERATOR';
    final email = user?.email ?? '';

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
                  displayName.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                if (email.isNotEmpty)
                  Text(
                    email,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
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
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Color.fromARGB(255, 33, 32, 32),
                    ),
                    overflow: TextOverflow.visible,
                    softWrap: true,
                  ),
                ),
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
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProfileSection(),
                const SizedBox(height: 24),

                // 2. Updated Action for Edit Profile
                _buildSettingsButton(
                  title: 'Edit Profile',
                  icon: Icons.edit,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ModeratorEditProfilePage(),
                      ),
                    );
                  },
                ),

                _buildSettingsButton(
                  title: 'Notifications',
                  icon: Icons.notifications_outlined,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (ctx) => const ModeratorNotificationsPage(),
                      ),
                    );
                  },
                ),

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
                          'For assistance, please contact our support team at:\n\n'
                          'Email: support@ibrgy.com\n'
                          'Phone: (123) 456-7890\n\n'
                          'Or visit our website for FAQs and more help.',
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
                      try {
                        await FirebaseAuth.instance.signOut();
                      } catch (e) {
                        debugPrint('Sign out error: $e');
                      }
                      if (!mounted) return;
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
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.white,
        elevation: 8,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.phone), label: 'Emergency'),
          BottomNavigationBarItem(
            icon: Icon(Icons.announcement, size: 30),
            label: 'Updates',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'People'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

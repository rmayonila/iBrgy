// ignore_for_file: use_build_context_synchronously
import 'dart:convert'; // Required for Base64 images
import 'package:flutter/foundation.dart'; // For web check
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // For logout
import 'package:cloud_firestore/cloud_firestore.dart';
import '../splash_screen.dart'; // Import your splash screen

class UserBrgyOfficialsPage extends StatefulWidget {
  const UserBrgyOfficialsPage({super.key});

  @override
  State<UserBrgyOfficialsPage> createState() => _UserBrgyOfficialsPageState();
}

class _UserBrgyOfficialsPageState extends State<UserBrgyOfficialsPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  int _selectedIndex = 3; // People tab

  // 1. Streams (Same as Moderator to ensure sync)
  final Stream<QuerySnapshot> _officialsStream = FirebaseFirestore.instance
      .collection('officials')
      .orderBy('createdAt', descending: true)
      .snapshots();

  final Stream<QuerySnapshot> _contactsStream = FirebaseFirestore.instance
      .collection('official_contacts')
      .snapshots();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Navigation for User
  void _onItemTapped(int index) {
    if (index == 0) {
      Navigator.pushReplacementNamed(context, '/user-home');
    } else if (index == 1) {
      Navigator.pushReplacementNamed(context, '/user-emergency-hotline');
    } else if (index == 2) {
      Navigator.pushReplacementNamed(context, '/user-announcement');
    } else if (index == 3) {
      // Current page
    }
  }

  void _updateSearch(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
    });
  }

  // --- EXIT / BACK FUNCTION ---
  Future<void> _handleBackOrLogout() async {
    final shouldExit = await showDialog<bool>(
      context: context,
      useRootNavigator: false, // Ensure it stays in frame
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

  // --- SHOW DETAILS MODAL (Read-Only Version) ---
  void _showOfficialDetails(Map<String, dynamic> data) {
    final title = data['title']?.toString() ?? '';
    final name = data['name']?.toString() ?? '';
    final nickname = data['nickname']?.toString() ?? '';
    final age = data['age']?.toString() ?? ''; // Added Age
    final address = data['address']?.toString() ?? '';
    final category = data['category']?.toString() ?? '';
    final imageUrl = data['imageUrl']?.toString() ?? '';

    // Create Combined Position Title (CATEGORY + TITLE)
    String combinedPosition = title;
    if (category.isNotEmpty) {
      combinedPosition = "$category $title";
    }

    // Helper for image in modal
    ImageProvider? getProfileImage() {
      if (imageUrl.isEmpty) return null;
      try {
        if (imageUrl.startsWith('http')) {
          return NetworkImage(imageUrl);
        } else {
          return MemoryImage(base64Decode(imageUrl));
        }
      } catch (e) {
        return null;
      }
    }

    showDialog(
      context: context,
      useRootNavigator: false, // CRITICAL: Keeps modal inside the "phone frame"
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 30, vertical: 24),
        child: Container(
          clipBehavior: Clip.antiAlias,
          constraints: const BoxConstraints(maxWidth: 340),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.25),
                blurRadius: 25,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Stack(
            children: [
              // MAIN CONTENT
              SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 40, 24, 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Large Image
                    Container(
                      width: 130,
                      height: 130,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.blue.shade50,
                        border: Border.all(
                          color: Colors.blue.shade100,
                          width: 4,
                        ),
                        image: getProfileImage() != null
                            ? DecorationImage(
                                image: getProfileImage()!,
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: getProfileImage() == null
                          ? Icon(
                              Icons.person,
                              size: 65,
                              color: Colors.blue.shade200,
                            )
                          : null,
                    ),
                    const SizedBox(height: 20),

                    // Name & Nickname
                    Text(
                      name,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                        letterSpacing: -0.5,
                      ),
                    ),
                    if (nickname.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 6.0),
                        child: Text(
                          '"$nickname"',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 18,
                            fontStyle: FontStyle.italic,
                            color: Colors.blue.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),

                    const SizedBox(height: 24),
                    const Divider(height: 1, thickness: 0.5),
                    const SizedBox(height: 24),

                    // Details List
                    // Showing Combined Position
                    _buildDetailRow(
                      Icons.work_outline_rounded,
                      "Position",
                      combinedPosition.toUpperCase(),
                    ),
                    // 2. Added Age Row
                    if (age.isNotEmpty)
                      _buildDetailRow(
                        Icons.calendar_today_rounded,
                        "Age",
                        "$age years old",
                      ),
                    if (address.isNotEmpty)
                      _buildDetailRow(
                        Icons.location_on_outlined,
                        "Address",
                        address,
                      ),
                  ],
                ),
              ),

              // CLOSE BUTTON ("X" at Upper Right)
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.grey.shade100,
                    highlightColor: Colors.grey.shade200,
                  ),
                  icon: Icon(Icons.close, color: Colors.grey.shade600),
                  tooltip: 'Close',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper widget for the details modal
  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: Colors.blue.shade700),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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
              Icons.people_alt_rounded,
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
          // --- EXIT ICON ---
          IconButton(
            onPressed: _handleBackOrLogout,
            icon: const Icon(Icons.logout, color: Colors.red),
            tooltip: "Exit",
          ),
        ],
      ),
    );
  }

  Widget _buildBanner() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade700, Colors.blue.shade500],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Meet Your Leaders",
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Dedicated to serving the community with integrity and transparency.",
            style: TextStyle(color: Colors.blue.shade50, fontSize: 14),
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
        onChanged: _updateSearch,
        decoration: InputDecoration(
          hintText: "Search official...",
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

  // --- READ-ONLY OFFICIAL CARD (Clickable for Details) ---
  Widget _buildOfficialCard(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final title = data['title']?.toString() ?? '';
    final name = data['name']?.toString() ?? '';
    final imageUrl = data['imageUrl']?.toString() ?? '';

    // Helper to decode image string
    ImageProvider? getProfileImage() {
      if (imageUrl.isEmpty) return null;
      try {
        if (imageUrl.startsWith('http')) {
          return NetworkImage(imageUrl);
        } else {
          return MemoryImage(base64Decode(imageUrl));
        }
      } catch (e) {
        return null;
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            // View Only - Show Details Modal
            _showOfficialDetails(data);
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Profile Image
                CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.blue.shade50,
                  backgroundImage: getProfileImage(),
                  child: getProfileImage() == null
                      ? Text(
                          name.isNotEmpty
                              ? name.substring(0, 1).toUpperCase()
                              : '?',
                          style: TextStyle(
                            color: Colors.blue.shade700,
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 16),

                // Info Column
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          title.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Colors.blue.shade800,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),

                      // Full Name
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
                // REMOVED: Edit/Delete Menu (User is Read-Only)
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- READ-ONLY CONTACT CARD ---
  Widget _buildContactInfoCard(String category, Map<String, dynamic> contacts) {
    final address = contacts['address']?.toString() ?? '';
    final hours = contacts['hours']?.toString() ?? '';
    final phone = contacts['contacts']?.toString() ?? '';

    if (address.isEmpty && hours.isEmpty && phone.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(top: 4, bottom: 20),
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F7FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (address.isNotEmpty) ...[
            _buildContactRow(Icons.location_on_outlined, 'Address', address),
            const SizedBox(height: 12),
          ],
          if (hours.isNotEmpty) ...[
            _buildContactRow(Icons.access_time, 'Office Hours', hours),
            const SizedBox(height: 12),
          ],
          if (phone.isNotEmpty) ...[
            _buildContactRow(Icons.phone_outlined, 'Contact', phone),
          ],
        ],
      ),
    );
  }

  // Simple Row for Contact Info (No Edit Button)
  Widget _buildContactRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.blue.shade400),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(fontSize: 13, color: Colors.black87),
              ),
            ],
          ),
        ),
      ],
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
        currentIndex: _selectedIndex,
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
        onTap: (index) => _onItemTapped(index),
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
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Mobile Content
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
                    _buildBanner(),
                    const Padding(
                      padding: EdgeInsets.only(bottom: 16.0),
                      child: Text(
                        "Barangay Officials",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),

                    // --- OFFICIALS STREAM ---
                    StreamBuilder<QuerySnapshot>(
                      stream: _officialsStream,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(40),
                              child: CircularProgressIndicator(),
                            ),
                          );
                        }

                        final officialDocs = snapshot.data?.docs ?? [];

                        if (officialDocs.isEmpty) {
                          if (_searchQuery.isNotEmpty) {
                            return Center(
                              child: Padding(
                                padding: const EdgeInsets.only(top: 20),
                                child: Text(
                                  "No matching officials found",
                                  style: TextStyle(color: Colors.grey[500]),
                                ),
                              ),
                            );
                          }
                          // Empty Placeholder
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
                                  Icons.people_outline,
                                  size: 40,
                                  color: Colors.grey.shade300,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  "No officials added yet",
                                  style: TextStyle(
                                    color: Colors.grey.shade500,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        // Filter and Group Data
                        final Map<String, List<DocumentSnapshot>> grouped = {};
                        for (var doc in officialDocs) {
                          final data = doc.data() as Map<String, dynamic>;
                          final name = (data['name'] ?? '')
                              .toString()
                              .toLowerCase();
                          final title = (data['title'] ?? '')
                              .toString()
                              .toLowerCase();
                          final category = (data['category'] ?? 'Uncategorized')
                              .toString();

                          if (_searchQuery.isEmpty ||
                              name.contains(_searchQuery) ||
                              title.contains(_searchQuery)) {
                            if (!grouped.containsKey(category)) {
                              grouped[category] = [];
                            }
                            grouped[category]!.add(doc);
                          }
                        }

                        if (grouped.isEmpty) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.only(top: 20),
                              child: Text(
                                "No matching officials found",
                                style: TextStyle(color: Colors.grey[500]),
                              ),
                            ),
                          );
                        }

                        // --- CONTACTS STREAM (Nested) ---
                        return StreamBuilder<QuerySnapshot>(
                          stream: _contactsStream,
                          builder: (ctx, contactSnap) {
                            final contactDocs = contactSnap.data?.docs ?? [];
                            final Map<String, Map<String, dynamic>> contacts =
                                {};
                            for (var d in contactDocs) {
                              contacts[d.id] = d.data() as Map<String, dynamic>;
                            }

                            return Column(
                              children: grouped.entries.map((entry) {
                                final category = entry.key;
                                final docs = entry.value;
                                final categoryContacts =
                                    contacts[category] ?? {};

                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 12.0,
                                        left: 4,
                                      ),
                                      child: Text(
                                        category,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.grey.shade600,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ),
                                    ...docs.map(
                                      (doc) => _buildOfficialCard(doc),
                                    ),
                                    _buildContactInfoCard(
                                      category,
                                      categoryContacts,
                                    ),
                                  ],
                                );
                              }).toList(),
                            );
                          },
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

    // WRAP FOR WEB: Keeps Exit Dialog inside the phone frame
    if (kIsWeb) {
      return PhoneFrame(
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            scaffoldBackgroundColor: const Color(0xFFF8F9FA),
            primarySwatch: Colors.blue,
            useMaterial3: true,
          ),
          home: mobileContent,
        ),
      );
    }

    return mobileContent;
  }
}

// --- PHONE FRAME (Reusable) ---
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

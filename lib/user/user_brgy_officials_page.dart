// ignore_for_file: use_build_context_synchronously
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
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Data State
  Map<String, List<Map<String, String>>> _allOfficials = {};
  Map<String, List<Map<String, String>>> _filteredOfficials = {};
  Map<String, Map<String, String>> _contacts = {};

  // Search State
  final TextEditingController _searchController = TextEditingController();

  // --- STATIC STRUCTURE (For Empty State) ---
  final Map<String, List<Map<String, String>>> _staticStructure = {
    'Punong Barangay': [
      {'title': 'Barangay Captain', 'name': 'To be updated...'},
    ],
    'Sangguniang Barangay': [
      {'title': 'Barangay Kagawad 1', 'name': 'To be updated...'},
      {'title': 'Barangay Kagawad 2', 'name': 'To be updated...'},
      {'title': 'Barangay Kagawad 3', 'name': 'To be updated...'},
      {'title': 'Barangay Kagawad 4', 'name': 'To be updated...'},
      {'title': 'Barangay Kagawad 5', 'name': 'To be updated...'},
      {'title': 'Barangay Kagawad 6', 'name': 'To be updated...'},
      {'title': 'Barangay Kagawad 7', 'name': 'To be updated...'},
    ],
    'Sangguniang Kabataan': [
      {'title': 'SK Chairperson', 'name': 'To be updated...'},
    ],
    'Appointed Officials': [
      {'title': 'Barangay Secretary', 'name': 'To be updated...'},
      {'title': 'Barangay Treasurer', 'name': 'To be updated...'},
    ],
  };

  // Navigation for User
  void _onItemTapped(BuildContext context, int index) {
    if (index == 0) {
      Navigator.pushReplacementNamed(context, '/user-home');
    } else if (index == 1) {
      Navigator.pushReplacementNamed(context, '/user-emergency-hotline');
    } else if (index == 2) {
      Navigator.pushReplacementNamed(context, '/user-announcement');
    }
  }

  @override
  void initState() {
    super.initState();
    _loadOfficialsAndContacts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadOfficialsAndContacts() async {
    try {
      // Load Officials
      final snap = await _db
          .collection('officials')
          .orderBy('createdAt', descending: true)
          .get();
      final Map<String, List<Map<String, String>>> loaded = {};
      for (var d in snap.docs) {
        final data = d.data();
        final category = (data['category'] ?? 'Uncategorized').toString();
        final title = (data['title'] ?? '').toString();
        final name = (data['name'] ?? '').toString();
        if (!loaded.containsKey(category)) loaded[category] = [];
        loaded[category]!.add({'id': d.id, 'title': title, 'name': name});
      }

      // Load Contacts
      final contactsSnap = await _db.collection('official_contacts').get();
      final Map<String, Map<String, String>> contacts = {};
      for (var d in contactsSnap.docs) {
        final data = d.data();
        contacts[d.id] = {
          'address': (data['address'] ?? '').toString(),
          'hours': (data['hours'] ?? '').toString(),
          'contacts': (data['contacts'] ?? '').toString(),
        };
      }

      if (!mounted) return;
      setState(() {
        _allOfficials = loaded;
        _filteredOfficials = loaded;
        _contacts = contacts;
      });
    } catch (e) {
      // ignore
    }
  }

  void _filterOfficials(String query) {
    if (query.isEmpty) {
      setState(() {
        _filteredOfficials = Map.from(_allOfficials);
      });
      return;
    }

    final lowerQuery = query.toLowerCase();
    final Map<String, List<Map<String, String>>> temp = {};
    final sourceMap = _allOfficials.isEmpty ? _staticStructure : _allOfficials;

    sourceMap.forEach((category, officialsList) {
      final filteredList = officialsList.where((o) {
        final title = (o['title'] ?? '').toLowerCase();
        final name = (o['name'] ?? '').toLowerCase();
        return title.contains(lowerQuery) || name.contains(lowerQuery);
      }).toList();

      if (filteredList.isNotEmpty) {
        temp[category] = filteredList;
      }
    });

    setState(() {
      _filteredOfficials = temp;
    });
  }

  bool _hasContactInfo(String category) {
    final c = _contacts[category];
    if (c == null) return false;
    return (c['address']?.trim().isNotEmpty ?? false) ||
        (c['hours']?.trim().isNotEmpty ?? false) ||
        (c['contacts']?.trim().isNotEmpty ?? false);
  }

  // --- EXIT / BACK FUNCTION ---
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

          // --- EXIT / BACK ICON ---
          IconButton(
            onPressed: _handleBackOrLogout,
            icon: const Icon(
              Icons.logout, // Visual "Exit" icon (looks like ➜])
              color: Colors.red,
            ),
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
        onChanged: _filterOfficials,
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

  Widget _buildOfficialCard(
    Map<String, String> official, {
    bool isPlaceholder = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
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
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: isPlaceholder
                ? Colors.grey.shade100
                : Colors.blue.shade50,
            child: isPlaceholder
                ? Icon(Icons.person_outline, color: Colors.grey.shade400)
                : Text(
                    (official['name'] ?? 'O').substring(0, 1).toUpperCase(),
                    style: TextStyle(
                      color: Colors.blue.shade700,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  official['title'] ?? '',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue.shade700,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  official['name'] ?? '',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isPlaceholder
                        ? Colors.grey.shade400
                        : Colors.black87,
                    fontStyle: isPlaceholder
                        ? FontStyle.italic
                        : FontStyle.normal,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactInfoCard(String category) {
    if (!_hasContactInfo(category)) return const SizedBox.shrink();

    final contact = _contacts[category]!;

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
          if ((contact['address'] ?? '').isNotEmpty) ...[
            _buildContactRow(
              Icons.location_on_outlined,
              'Address',
              contact['address']!,
            ),
            const SizedBox(height: 12),
          ],
          if ((contact['hours'] ?? '').isNotEmpty) ...[
            _buildContactRow(
              Icons.access_time,
              'Office Hours',
              contact['hours']!,
            ),
            const SizedBox(height: 12),
          ],
          if ((contact['contacts'] ?? '').isNotEmpty) ...[
            _buildContactRow(
              Icons.phone_outlined,
              'Contact',
              contact['contacts']!,
            ),
          ],
        ],
      ),
    );
  }

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
        currentIndex: 3, // Highlight 'People'
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

                    // 2. Hero Banner
                    _buildBanner(),

                    // 3. Logic: Data vs Placeholder
                    if (_allOfficials.isEmpty &&
                        _searchController.text.isEmpty) ...[
                      // EMPTY STATE: Show Static Structure
                      const Padding(
                        padding: EdgeInsets.only(bottom: 16.0),
                        child: Text(
                          "Organizational Structure",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      ..._staticStructure.entries.map((entry) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(
                                bottom: 12.0,
                                left: 4,
                              ),
                              child: Text(
                                entry.key,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey.shade600,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            ...entry.value.map(
                              (o) => _buildOfficialCard(o, isPlaceholder: true),
                            ),
                            const SizedBox(height: 12),
                          ],
                        );
                      }),
                    ] else if (_filteredOfficials.isEmpty &&
                        _searchController.text.isNotEmpty) ...[
                      // SEARCHING BUT NO RESULTS
                      Padding(
                        padding: const EdgeInsets.only(top: 20),
                        child: Center(
                          child: Text(
                            "No matching officials found",
                            style: TextStyle(color: Colors.grey[500]),
                          ),
                        ),
                      ),
                    ] else ...[
                      // DATA EXISTS
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
                      ..._filteredOfficials.entries.map((entry) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(
                                bottom: 12.0,
                                left: 4,
                              ),
                              child: Text(
                                entry.key,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey.shade600,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            ...entry.value.map((o) => _buildOfficialCard(o)),
                            _buildContactInfoCard(entry.key),
                          ],
                        );
                      }),
                    ],

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

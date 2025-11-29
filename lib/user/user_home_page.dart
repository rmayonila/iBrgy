import 'package:flutter/foundation.dart'; // For web check
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../splash_screen.dart';

// --- CONFIG: Synced with Moderator Page ---
const Map<String, Map<String, dynamic>> categoryConfig = {
  'Health & Welfare': {'color': Color(0xFF4CAF50), 'icon': Icons.favorite},
  'Brgy Clearance/Permit Process': {
    'color': Color(0xFFFFA726),
    'icon': Icons.assignment,
  },
  'Cedula': {'color': Color(0xFF29B6F6), 'icon': Icons.schedule},
  'Community Programs': {'color': Color(0xFF26A69A), 'icon': Icons.groups},
  'Other': {'color': Color(0xFF9E9E9E), 'icon': Icons.info},
};

class UserHomePage extends StatefulWidget {
  const UserHomePage({super.key});

  @override
  State<UserHomePage> createState() => _UserHomePageState();
}

class _UserHomePageState extends State<UserHomePage> {
  int _selectedIndex = 0;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Search State
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Track expanded states
  final Map<String, bool> _expandedStates = {};

  // Stream
  final Stream<QuerySnapshot> _servicesStream = FirebaseFirestore.instance
      .collection('barangay_services')
      .orderBy('createdAt', descending: true)
      .snapshots();

  @override
  void initState() {
    super.initState();
    _ensureSignedIn();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _ensureSignedIn() async {
    try {
      if (_auth.currentUser == null) {
        await _auth.signInAnonymously();
      }
    } catch (_) {
      // ignore auth errors
    }
  }

  void _updateSearch(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
    });
  }

  void _onItemTapped(BuildContext context, int index) {
    if (index == 1) {
      Navigator.pushReplacementNamed(context, '/user-emergency-hotline');
      return;
    }
    if (index == 2) {
      Navigator.pushReplacementNamed(context, '/user-announcement');
      return;
    }
    if (index == 3) {
      Navigator.pushReplacementNamed(context, '/user-brgy-officials');
      return;
    }

    setState(() {
      _selectedIndex = index;
    });
  }

  // --- EXIT MODAL ---
  Future<void> _handleBackOrLogout() async {
    final shouldExit = await showDialog<bool>(
      context: context,
      useRootNavigator: false, // Keep inside phone frame
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
            color: Color.fromRGBO(0, 0, 0, 0.05), // FIXED: withOpacity replaced
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
            child: Icon(
              Icons.home_rounded,
              color: Colors.blue.shade700,
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
            color: Color.fromRGBO(0, 0, 0, 0.03), // FIXED: withOpacity replaced
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: _updateSearch,
        style: const TextStyle(color: Colors.black),
        decoration: InputDecoration(
          hintText: "Search services...",
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

  // --- SERVICE CARD (Read-Only) ---
  Widget _buildServiceCard(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final docId = doc.id;
    final title = data['title'] ?? 'Service';
    final category = data['category'] ?? 'Other';
    final steps = data['steps'] ?? '';

    // Config Lookup
    final config =
        categoryConfig[category] ??
        {'color': const Color(0xFF9E9E9E), 'icon': Icons.info};

    final isExpanded = _expandedStates[docId] ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.05), // FIXED: withOpacity replaced
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header Tile
          ListTile(
            leading: Container(
              height: 40,
              width: 40,
              decoration: BoxDecoration(
                color: Color.fromRGBO(
                  ((config['color'] as Color).value >> 16) &
                      0xFF, // FIXED: .red replaced
                  ((config['color'] as Color).value >> 8) &
                      0xFF, // FIXED: .green replaced
                  (config['color'] as Color).value &
                      0xFF, // FIXED: .blue replaced
                  0.1,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                config['icon'] as IconData,
                color: config['color'] as Color,
                size: 20,
              ),
            ),
            title: Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            subtitle: Text(
              category,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
            trailing: Icon(
              isExpanded ? Icons.expand_less : Icons.expand_more,
              color: Colors.grey.shade600,
            ),
            onTap: () {
              setState(() {
                _expandedStates[docId] = !isExpanded;
              });
            },
          ),

          // Expanded Content
          if (isExpanded)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Steps / Requirements:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    steps,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.assignment_outlined,
            size: 48,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 12),
          Text(
            'No services found',
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
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
                      "Barangay Services",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16),
                    StreamBuilder<QuerySnapshot>(
                      stream: _servicesStream,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(20),
                              child: CircularProgressIndicator(),
                            ),
                          );
                        }
                        if (snapshot.hasError) {
                          return const Text("Error loading services");
                        }

                        final docs = snapshot.data?.docs ?? [];
                        final filteredDocs = _searchQuery.isEmpty
                            ? docs
                            : docs.where((doc) {
                                final data = doc.data() as Map<String, dynamic>;
                                final t = (data['title'] ?? '')
                                    .toString()
                                    .toLowerCase();
                                final c = (data['category'] ?? '')
                                    .toString()
                                    .toLowerCase();
                                return t.contains(_searchQuery) ||
                                    c.contains(_searchQuery);
                              }).toList();

                        if (filteredDocs.isEmpty) {
                          return _buildEmptyState();
                        }

                        return Column(
                          children: filteredDocs
                              .map((doc) => _buildServiceCard(doc))
                              .toList(),
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
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Color.fromRGBO(
                0,
                0,
                0,
                0.05,
              ), // FIXED: withOpacity replaced
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
      ),
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
                color: Color.fromRGBO(
                  0,
                  0,
                  0,
                  0.1,
                ), // FIXED: withOpacity replaced
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

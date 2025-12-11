// ignore_for_file: use_build_context_synchronously
import 'package:flutter/foundation.dart'; // For web check
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Required for Clipboard
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // For logout/exit logic
import '../splash_screen.dart'; // Import your splash screen

class UserEmergencyHotlinePage extends StatefulWidget {
  const UserEmergencyHotlinePage({super.key});

  @override
  State<UserEmergencyHotlinePage> createState() =>
      _UserEmergencyHotlinePageState();
}

class _UserEmergencyHotlinePageState extends State<UserEmergencyHotlinePage> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // --- TOAST STATE ---
  bool _showToast = false;
  String _copiedNumber = '';

  // --- SEARCH STATE ---
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  // --- CACHE HOTLINE DATA ---
  List<Map<String, dynamic>> _allHotlines = [];

  void _onItemTapped(BuildContext context, int index) {
    if (index == 0) {
      Navigator.pushReplacementNamed(context, '/user-home');
    } else if (index == 2) {
      Navigator.pushReplacementNamed(context, '/user-announcement');
    } else if (index == 3) {
      Navigator.pushReplacementNamed(context, '/user-brgy-officials');
    }
  }

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'national':
        return Icons.warning_amber_rounded;
      case 'barangay':
        return Icons.account_balance_rounded;
      case 'police':
        return Icons.local_police_outlined;
      case 'fire':
        return Icons.fire_truck_outlined;
      case 'medical':
        return Icons.medical_services_outlined;
      default:
        return Icons.call_rounded;
    }
  }

  // --- FUNCTION TO COPY NUMBER ---
  Future<void> _copyToClipboard(String number) async {
    await Clipboard.setData(ClipboardData(text: number));

    if (!mounted) return;

    setState(() {
      _showToast = true;
      _copiedNumber = number;
    });

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _showToast = false;
        });
      }
    });
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

  // --- MINIMALIST TOAST WIDGET ---
  Widget _buildToast() {
    if (!_showToast) return const SizedBox.shrink();

    return Positioned(
      top: 100, // Position toast at top to avoid frame blinking
      left: 0,
      right: 0,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutBack,
        builder: (context, value, child) {
          return Transform.scale(
            scale: value,
            child: Opacity(opacity: value.clamp(0.0, 1.0), child: child),
          );
        },
        child: Align(
          alignment: Alignment.topCenter,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 30),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(50),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF000000).withValues(alpha: 0.15),
                  blurRadius: 20,
                  spreadRadius: 2,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  color: Colors.green,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: Text(
                    "Copied: $_copiedNumber",
                    style: const TextStyle(
                      color: Colors.black87,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
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
            color: const Color(0xFF000000).withValues(alpha: 0.05),
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
              color: Colors.red.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.phone_in_talk_rounded,
              color: Colors.red.shade400,
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
            color: const Color(0xFF000000).withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(color: Colors.black),
        decoration: InputDecoration(
          hintText: "Search hotline...",
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

  Widget _buildHotlineCard(Map<String, dynamic> item) {
    bool isUrgent = item['isUrgent'] == true;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isUrgent ? const Color(0xFFD32F2F) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isUrgent
                ? const Color(0xFFD32F2F).withValues(alpha: 0.3)
                : const Color(0xFF000000).withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isUrgent
                ? Colors.white.withValues(alpha: 0.2)
                : Colors.red.shade50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            item['icon'],
            color: isUrgent ? Colors.white : Colors.red.shade400,
            size: 24,
          ),
        ),
        title: Text(
          item['name'],
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 16,
            color: isUrgent ? Colors.white : Colors.black87,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Text(
            item['number'],
            style: TextStyle(
              color: isUrgent
                  ? Colors.white.withValues(alpha: 0.9)
                  : Colors.grey.shade600,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        trailing: GestureDetector(
          onTap: () => _copyToClipboard(item['number']),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isUrgent ? Colors.white : Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.content_copy_rounded,
              color: isUrgent ? const Color(0xFFD32F2F) : Colors.grey.shade600,
              size: 20,
            ),
          ),
        ),
        onTap: () => _copyToClipboard(item['number']),
      ),
    );
  }

  Widget _buildEmptyState(String sectionName) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.shade200,
          style: BorderStyle.solid,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.add_ic_call_rounded,
            size: 40,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 12),
          Text(
            "No $sectionName hotlines added yet",
            style: TextStyle(
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Tap + to add new number",
            style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF000000).withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: 1,
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

  // New Widget: Description Note
  Widget _buildDescriptionNote() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.blue.shade100,
          style: BorderStyle.solid,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
              const SizedBox(width: 8),
              Text(
                "Quick Guide",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.blue.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            "Emergency Hotline provides ESSENTIAL EMERGENCY HOTLINE NUMBERS. Tap on any number to IMMEDIATELY COPY IT to your clipboard for quick pasting into your phone dialer. Your safety is our priority.",
            style: TextStyle(fontSize: 13, color: Colors.black87, height: 1.4),
          ),
        ],
      ),
    );
  }

  // New Widget: Quote
  Widget _buildSafetyQuote() {
    return Align(
      alignment: Alignment.centerRight,
      child: Padding(
        padding: const EdgeInsets.only(top: 10, bottom: 20, right: 4),
        child: Text(
          "\"Keep safe and be vigilant\"",
          style: TextStyle(
            fontStyle: FontStyle.italic,
            fontSize: 14,
            color: Colors.grey.shade500,
          ),
        ),
      ),
    );
  }

  // --- FILTER HOTLINES BY SEARCH ---
  List<Map<String, dynamic>> _filterHotlines(
    List<Map<String, dynamic>> hotlines,
    String type,
  ) {
    final filtered = hotlines.where((item) {
      final matchesType = item['type'] == type;
      final matchesSearch =
          _searchQuery.isEmpty ||
          item['name'].toString().toLowerCase().contains(_searchQuery) ||
          item['number'].toString().toLowerCase().contains(_searchQuery);
      return matchesType && matchesSearch;
    }).toList();

    return filtered;
  }

  // --- CHECK IF ANY HOTLINES MATCH SEARCH ---
  bool _hasAnyMatchingHotlines() {
    if (_searchQuery.isEmpty) return true;

    return _allHotlines.any(
      (item) =>
          item['name'].toString().toLowerCase().contains(_searchQuery) ||
          item['number'].toString().toLowerCase().contains(_searchQuery),
    );
  }

  Widget _buildNoHotlineFound() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.shade200,
          style: BorderStyle.solid,
        ),
      ),
      child: Column(
        children: [
          Icon(Icons.search_off_rounded, size: 50, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            "NO HOTLINE FOUND",
            style: TextStyle(
              color: Colors.grey.shade600,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "No hotlines match your search for \"$_searchQuery\"",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              _searchController.clear();
              setState(() {
                _searchQuery = '';
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Clear Search'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    // If search has text but no matches, show "NO HOTLINE FOUND"
    if (_searchQuery.isNotEmpty && !_hasAnyMatchingHotlines()) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildSearchBar(),
            const SizedBox(height: 24),
            _buildNoHotlineFound(),
          ],
        ),
      );
    }

    // Filter hotlines based on search query
    final nationalItems = _filterHotlines(_allHotlines, 'national');
    final localItems = _filterHotlines(_allHotlines, 'local');
    final barangayItems = _filterHotlines(_allHotlines, 'barangay');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Search Bar
          _buildSearchBar(),
          const SizedBox(height: 24),

          // 2. Quick Guide Note (MOVED HERE)
          _buildDescriptionNote(),

          // 3. Safety Quote (MOVED HERE: Immediately after Quick Guide)
          _buildSafetyQuote(),
          // Note: The original image structure has this quote followed by the
          // main title and then the first section.

          // 4. Page Title (Emergency Hotlines) - MOVED HERE, below Quick Guide and Quote
          const Text(
            "Emergency Hotlines",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16), // Space before the first section header
          // NATIONAL
          _buildSectionTitle("NATIONAL EMERGENCY"),
          if (nationalItems.isEmpty && _searchQuery.isEmpty)
            _buildEmptyState("national")
          else if (nationalItems.isEmpty && _searchQuery.isNotEmpty)
            const SizedBox.shrink() // Don't show section if no matches during search
          else
            ...nationalItems.map((h) => _buildHotlineCard(h)),

          const SizedBox(height: 20),

          // LOCAL - Only show if there are items or no search
          if (localItems.isNotEmpty || _searchQuery.isEmpty) ...[
            _buildSectionTitle("LOCAL HOTLINES"),
            if (localItems.isEmpty && _searchQuery.isEmpty)
              _buildEmptyState("local")
            else if (localItems.isEmpty && _searchQuery.isNotEmpty)
              const SizedBox.shrink()
            else
              ...localItems.map((h) => _buildHotlineCard(h)),
            const SizedBox(height: 20),
          ],

          // BARANGAY - Only show if there are items or no search
          if (barangayItems.isNotEmpty || _searchQuery.isEmpty) ...[
            _buildSectionTitle("BARANGAY HOTLINES"),
            if (barangayItems.isEmpty && _searchQuery.isEmpty)
              _buildEmptyState("barangay")
            else if (barangayItems.isEmpty && _searchQuery.isNotEmpty)
              const SizedBox.shrink()
            else
              ...barangayItems.map((h) => _buildHotlineCard(h)),
            const SizedBox(height: 20),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget mobileContent = Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Stack(
          children: [
            // Content Layer
            Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: _db
                        .collection('hotlines')
                        .orderBy('createdAt', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        // Cache the data and process it once
                        final docs = snapshot.data!.docs;
                        _allHotlines = docs.map((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          return {
                            'id': doc.id,
                            'name': (data['name'] ?? '').toString(),
                            'number': (data['number'] ?? '').toString(),
                            'type': (data['type'] ?? 'local').toString(),
                            'isUrgent': data['isUrgent'] == true,
                            'icon': _getIconForType(
                              (data['type'] ?? 'local').toString(),
                            ),
                          };
                        }).toList();
                      }

                      // Always return the content widget that uses the cached data
                      return _buildContent();
                    },
                  ),
                ),
              ],
            ),

            // Toast Layer (Overlays content) - Fixed position
            _buildToast(),
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
                color: const Color(0xFF000000).withValues(alpha: 0.1),
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

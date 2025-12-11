// ignore_for_file: use_build_context_synchronously
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async'; // Required for Timer

import '../widgets/subscription_widgets.dart';

class EmergencyHotlinePage extends StatefulWidget {
  const EmergencyHotlinePage({super.key});

  @override
  State<EmergencyHotlinePage> createState() => _EmergencyHotlinePageState();
}

class _EmergencyHotlinePageState extends State<EmergencyHotlinePage> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // --- DEBOUNCING FIELDS ---
  Timer? _debounce;
  final Duration _debounceDuration = const Duration(
    milliseconds: 300,
  ); // 0.3 seconds delay

  // --- SEARCH STATE ---
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  // --- STREAM FOR REAL-TIME SYNC ---
  late Stream<QuerySnapshot> _hotlinesStream;

  @override
  void initState() {
    super.initState();
    // Use real-time stream instead of one-time load for automatic sync
    _hotlinesStream = _db
        .collection('hotlines')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // --- ADMIN NAVIGATION LOGIC ---
  void _onItemTapped(BuildContext context, int index) {
    if (index == 0) {
      Navigator.pushReplacementNamed(context, '/admin-home');
    } else if (index == 2) {
      Navigator.pushReplacementNamed(context, '/announcement');
    } else if (index == 3) {
      Navigator.pushReplacementNamed(context, '/brgy-officials');
    } else if (index == 4) {
      Navigator.pushReplacementNamed(context, '/account-settings');
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel(); // Cancel the timer when the widget is disposed
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

  // --- MODIFIED SEARCH FUNCTION WITH DEBOUNCING ---
  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) {
      _debounce!.cancel();
    }

    _debounce = Timer(_debounceDuration, () {
      if (!mounted) return;
      setState(() {
        _searchQuery = query.trim().toLowerCase();
      });
    });
  }

  // --- HANDLE SEARCH SUBMIT ---
  void _onSearchSubmitted(String value) {
    // Cancel any pending debounce
    _debounce?.cancel();

    if (!mounted) return;
    setState(() {
      _searchQuery = value.trim().toLowerCase();
    });

    // Unfocus to hide keyboard
    FocusScope.of(context).unfocus();
  }

  Future<void> _copyToClipboard(String number) async {
    await Clipboard.setData(ClipboardData(text: number));

    if (!mounted) return;

    // Show centered overlay toast
    _showCenteredOverlayToast(number);
  }

  // --- CENTERED OVERLAY TOAST METHOD ---
  void _showCenteredOverlayToast(String number) {
    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned.fill(
        child: IgnorePointer(
          child: Material(
            color: Colors.transparent,
            child: Center(child: _buildToastContent(number)),
          ),
        ),
      ),
    );

    // Insert the overlay
    overlay.insert(overlayEntry);

    // Remove the overlay after 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      overlayEntry.remove();
    });
  }

  // --- TOAST CONTENT WIDGET ---
  Widget _buildToastContent(String number) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Opacity(opacity: value.clamp(0.0, 1.0), child: child),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 40),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 25,
              spreadRadius: 2,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.check_circle_rounded,
              color: Colors.green,
              size: 24,
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                "Copied: $number",
                style: const TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
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
            color: Colors.black.withValues(alpha: 0.05),
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
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: _onSearchChanged,
        onSubmitted: _onSearchSubmitted,
        style: const TextStyle(color: Colors.black, fontSize: 16),
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
                ? Colors.red.withValues(alpha: 0.3)
                : Colors.black.withValues(alpha: 0.03),
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
            "These hotlines are managed in Firestore",
            style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildNoSearchResults() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      margin: const EdgeInsets.only(top: 16),
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
          Icon(Icons.search_off_rounded, size: 48, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            "No hotlines found",
            style: TextStyle(
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "No results for \"$_searchQuery\"",
            style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            "Try searching with different keywords",
            style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
            textAlign: TextAlign.center,
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
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: 1, // Highlight 'Emergency'
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

  // --- BUILD CONTENT BASED ON SEARCH ---
  Widget _buildContent() {
    return StreamBuilder<QuerySnapshot>(
      stream: _hotlinesStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        // Convert snapshot to list of hotlines
        final List<Map<String, dynamic>> allHotlines = [];
        if (snapshot.hasData) {
          for (final doc in snapshot.data!.docs) {
            final data = doc.data() as Map<String, dynamic>;
            final hotline = {
              'id': doc.id,
              'name': (data['name'] ?? '').toString(),
              'number': (data['number'] ?? '').toString(),
              'type': (data['type'] ?? 'local').toString(),
              'isUrgent': data['isUrgent'] == true,
              'icon': _getIconForType((data['type'] ?? 'local').toString()),
            };
            allHotlines.add(hotline);
          }
        }

        final List<Map<String, dynamic>> nationalItems = [];
        final List<Map<String, dynamic>> localItems = [];
        final List<Map<String, dynamic>> barangayItems = [];

        for (final hotline in allHotlines) {
          // Filter by search query
          final search = _searchQuery;
          final matchesSearch =
              search.isEmpty ||
              hotline['name'].toString().toLowerCase().contains(search) ||
              hotline['number'].toString().toLowerCase().contains(search);

          if (matchesSearch) {
            if (hotline['type'] == 'national') {
              nationalItems.add(hotline);
            } else if (hotline['type'] == 'barangay') {
              barangayItems.add(hotline);
            } else {
              localItems.add(hotline);
            }
          }
        }

        // Check if there are any results across all categories
        final bool hasSearchResults =
            nationalItems.isNotEmpty ||
            localItems.isNotEmpty ||
            barangayItems.isNotEmpty;
        final bool isSearching = _searchQuery.isNotEmpty;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Search Bar
              _buildSearchBar(),
              const SizedBox(height: 24),

              // 2. Description Note (Quick Guide) - MOVED HERE
              _buildDescriptionNote(),

              // 3. Safety Quote - MOVED HERE
              _buildSafetyQuote(),

              // 4. Page Title (Emergency Hotlines)
              const Text(
                "Emergency Hotlines",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              // Retaining the original admin subtitle below the title
              const SizedBox(height: 4),
              Text(
                "Tap to copy the number",
                style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
              ),
              const SizedBox(height: 16),

              // Show "No results" message when searching with no results
              if (isSearching && !hasSearchResults) _buildNoSearchResults(),

              // Show content only if we have results or not searching
              if (!isSearching || hasSearchResults) ...[
                // NATIONAL
                if (nationalItems.isNotEmpty || !isSearching)
                  _buildSectionTitle("NATIONAL EMERGENCY"),

                if (nationalItems.isEmpty && !isSearching)
                  _buildEmptyState("national")
                else if (nationalItems.isNotEmpty)
                  ...nationalItems.map((h) => _buildHotlineCard(h)),

                const SizedBox(height: 20),

                // LOCAL
                if (localItems.isNotEmpty || !isSearching)
                  _buildSectionTitle("LOCAL HOTLINES"),

                if (localItems.isEmpty && !isSearching)
                  _buildEmptyState("local")
                else if (localItems.isNotEmpty)
                  ...localItems.map((h) => _buildHotlineCard(h)),

                const SizedBox(height: 20),

                // BARANGAY
                if (barangayItems.isNotEmpty || !isSearching)
                  _buildSectionTitle("BARANGAY HOTLINES"),

                if (barangayItems.isEmpty && !isSearching)
                  _buildEmptyState("barangay")
                else if (barangayItems.isNotEmpty)
                  ...barangayItems.map((h) => _buildHotlineCard(h)),
              ],

              const SizedBox(height: 80),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget mobileContent = Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final snapshot = await FirebaseFirestore.instance
              .collection('hotlines')
              .get();
          final currentCount = snapshot.docs.length;

          if (context.mounted) {
            final canAdd = await checkSubscriptionLimit(
              context: context,
              action: 'add_hotline',
              currentCount: currentCount,
            );

            if (canAdd && context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Add Hotline functionality coming soon'),
                ),
              );
            }
          }
        },
        label: const Text('New Hotline'),
        icon: const Icon(
          Icons.add,
        ), // Changed to generic Add, Phone was specific
        backgroundColor: Colors.red.shade400, // Match theme
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(child: _buildContent()),
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
                color: Colors.black.withValues(alpha: 0.1),
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

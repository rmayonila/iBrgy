// ignore_for_file: use_build_context_synchronously
import 'package:flutter/foundation.dart'; // For web check
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Required for Clipboard
import 'package:cloud_firestore/cloud_firestore.dart';

class EmergencyHotlinePage extends StatefulWidget {
  const EmergencyHotlinePage({super.key});

  @override
  State<EmergencyHotlinePage> createState() => _EmergencyHotlinePageState();
}

class _EmergencyHotlinePageState extends State<EmergencyHotlinePage> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // --- TOAST STATE ---
  bool _showToast = false;
  String _copiedNumber = '';

  // --- STATIC NATIONAL NUMBERS ---
  final List<Map<String, dynamic>> _nationalHotlines = [
    {
      'name': 'National Emergency',
      'number': '911',
      'type': 'national',
      'isUrgent': true,
      'icon': Icons.warning_amber_rounded,
    },
    {
      'name': 'Philippine Red Cross',
      'number': '143',
      'type': 'national',
      'isUrgent': false,
      'icon': Icons.medical_services_outlined,
    },
    {
      'name': 'Police (PNP)',
      'number': '117',
      'type': 'national',
      'isUrgent': false,
      'icon': Icons.local_police_outlined,
    },
    {
      'name': 'Fire Protection (BFP)',
      'number': '(02) 8426-0219',
      'type': 'national',
      'isUrgent': false,
      'icon': Icons.fire_truck_outlined,
    },
  ];

  List<Map<String, dynamic>> _localHotlines = [];
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

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
  void initState() {
    super.initState();
    _loadLocalHotlines();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadLocalHotlines() async {
    try {
      final snap = await _db
          .collection('hotlines')
          .orderBy('createdAt', descending: true)
          .get();
      final items = snap.docs.map((d) {
        final data = d.data();
        return {
          'id': d.id,
          'name': (data['name'] ?? '').toString(),
          'number': (data['number'] ?? '').toString(),
          'type': 'local',
          'isUrgent': false,
          'icon': Icons.call_rounded,
        };
      }).toList();

      if (!mounted) return;
      setState(() {
        _localHotlines = items;
      });
    } catch (e) {
      // ignore
    }
  }

  void _updateSearch(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
    });
  }

  // --- HELPERS TO FILTER LISTS ---
  List<Map<String, dynamic>> get _filteredNational {
    if (_searchQuery.isEmpty) return _nationalHotlines;
    return _nationalHotlines.where((h) {
      return h['name'].toLowerCase().contains(_searchQuery) ||
          h['number'].toLowerCase().contains(_searchQuery);
    }).toList();
  }

  List<Map<String, dynamic>> get _filteredLocal {
    if (_searchQuery.isEmpty) return _localHotlines;
    return _localHotlines.where((h) {
      return h['name'].toLowerCase().contains(_searchQuery) ||
          h['number'].toLowerCase().contains(_searchQuery);
    }).toList();
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

  // --- MINIMALIST TOAST WIDGET ---
  Widget _buildToast() {
    if (!_showToast) return const SizedBox.shrink();

    return Center(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutBack,
        builder: (context, value, child) {
          return Transform.scale(
            scale: value,
            // FIX: Added clamp to prevent crash if value > 1.0 due to bounce curve
            child: Opacity(opacity: value.clamp(0.0, 1.0), child: child),
          );
        },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 30),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(50),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
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
            onPressed: () {},
            icon: const Icon(
              Icons.notifications_none_rounded,
              color: Colors.black87,
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
                ? Colors.red.withOpacity(0.3)
                : Colors.black.withOpacity(0.03),
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
                ? Colors.white.withOpacity(0.2)
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
                  ? Colors.white.withOpacity(0.9)
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
          // FIX: Changed from ContainerIcon (Blue) to Icon (Grey)
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
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Stack(
          children: [
            // Content Layer
            Column(
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
                          "Emergency Hotlines",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Tap to copy the number",
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 20),
                        if (_filteredNational.isNotEmpty) ...[
                          _buildSectionTitle("NATIONAL EMERGENCY"),
                          ..._filteredNational.map((h) => _buildHotlineCard(h)),
                          const SizedBox(height: 20),
                        ],
                        _buildSectionTitle("BARANGAY LOCAL HOTLINES"),
                        if (_filteredLocal.isEmpty && _searchQuery.isEmpty)
                          Container(
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
                                  "No local hotlines added yet",
                                  style: TextStyle(
                                    color: Colors.grey.shade500,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "Only Admin can add new numbers",
                                  style: TextStyle(
                                    color: Colors.grey.shade400,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          )
                        else if (_filteredLocal.isEmpty &&
                            _searchQuery.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Center(
                              child: Text(
                                "No matching local numbers",
                                style: TextStyle(color: Colors.grey.shade400),
                              ),
                            ),
                          )
                        else
                          ..._filteredLocal.map((h) => _buildHotlineCard(h)),
                        const SizedBox(
                          height: 80,
                        ), // Padding for toast visibility
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // Notification Layer (Fixed Minimalist Toast)
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

// ignore_for_file: use_build_context_synchronously
import 'package:flutter/foundation.dart'; // For web check
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'moderator_nav.dart'; // Assuming you have this for moderator specific routing

// Category colors and icons mapping
const Map<String, Map<String, dynamic>> categoryConfig = {
  'Health & Welfare': {'color': Color(0xFF4CAF50), 'icon': Icons.favorite},
  'Brgy Clearance/Permit Process': {
    'color': Color(0xFFFFA726),
    'icon': Icons.assignment,
  },
  'Brgy Hall Schedule': {'color': Color(0xFF29B6F6), 'icon': Icons.schedule},
  'Emergency Services': {'color': Color(0xFFEF5350), 'icon': Icons.emergency},
  'Events & Announcements': {'color': Color(0xFF7E57C2), 'icon': Icons.event},
  'Community Programs': {'color': Color(0xFF26A69A), 'icon': Icons.groups},
};

class ModeratorHomePage extends StatefulWidget {
  const ModeratorHomePage({super.key});

  @override
  State<ModeratorHomePage> createState() => _ModeratorHomePageState();
}

class _ModeratorHomePageState extends State<ModeratorHomePage> {
  // Start with no seeded items — show placeholder for empty state
  List<Map<String, String>> infoItems = [];
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  int _selectedIndex = 0;

  // track expanded indices for inline post expansion
  final Set<int> _expanded = {};

  Future<void> _ensureSignedIn() async {
    try {
      if (_auth.currentUser == null) {
        await _auth.signInAnonymously();
      }
    } catch (_) {
      // ignore auth errors here
    }
  }

  @override
  void initState() {
    super.initState();
    _loadInfoItems();
  }

  Future<void> _loadInfoItems() async {
    try {
      final snap = await _db
          .collection('infoItems')
          .orderBy('createdAt', descending: true)
          .get();
      if (!mounted) return;
      final items = snap.docs.map((d) {
        final data = d.data();
        return {
          'id': d.id,
          'title': (data['title'] ?? '').toString(),
          'category': (data['category'] ?? '').toString(),
          'description': (data['description'] ?? '').toString(),
          'lastUpdated': data['createdAt'] != null
              ? _formatTimestamp(data['createdAt'])
              : 'recently',
        };
      }).toList();
      setState(() {
        infoItems = items;
      });
    } catch (e) {
      // ignore load errors for now
    }
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp is Timestamp) {
      final date = timestamp.toDate();
      return "${date.month}/${date.day}/${date.year}";
    }
    return 'recently';
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

          // MODERATOR FEATURE: ADD BUTTON
          IconButton(
            onPressed: () => _showAddInfoDialog(),
            icon: const Icon(
              Icons.add_circle_outline_rounded,
              color: Colors.blue,
              size: 28,
            ),
            tooltip: "Add Service",
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
        decoration: InputDecoration(
          hintText: "Search services, forms...",
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
          prefixIcon: Icon(Icons.search, color: Colors.grey.shade400),
          suffixIcon: Icon(Icons.qr_code_scanner, color: Colors.blue.shade700),
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
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  // Grid for standard categories (Static for UI demo, can be dynamic)
  Widget _buildServicesGrid() {
    final services = [
      {
        'icon': Icons.description_outlined,
        'label': 'Clearance',
        'color': 0xFFFFE0B2,
      },
      {
        'icon': Icons.badge_outlined,
        'label': 'Barangay ID',
        'color': 0xFFBBDEFB,
      },
      {
        'icon': Icons.storefront_outlined,
        'label': 'Business',
        'color': 0xFFC8E6C9,
      },
      {
        'icon': Icons.gavel_outlined,
        'label': 'Complaints',
        'color': 0xFFE1BEE7,
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 0.8,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: services.length,
      itemBuilder: (context, index) {
        final item = services[index];
        return Column(
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: Container(
                    height: 45,
                    width: 45,
                    decoration: BoxDecoration(
                      color: Color(item['color'] as int).withOpacity(0.4),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      item['icon'] as IconData,
                      color: Colors.black87,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              item['label'] as String,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        );
      },
    );
  }

  // This list displays the actual items added by the moderator via Firestore
  Widget _buildAddedServicesList() {
    if (infoItems.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              Icon(Icons.post_add, size: 48, color: Colors.grey.shade300),
              const SizedBox(height: 8),
              Text(
                "No services added yet",
                style: TextStyle(color: Colors.grey.shade400),
              ),
              const SizedBox(height: 4),
              Text(
                "Tap the + button to add your first service",
                style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: infoItems.length,
      itemBuilder: (context, index) {
        return _buildEnhancedInfoCard(context, infoItems[index], index: index);
      },
    );
  }

  Widget _buildEnhancedInfoCard(
    BuildContext context,
    Map<String, String> info, {
    int? index,
  }) {
    final category = info['category'] ?? 'Community Info';
    final config =
        categoryConfig[category] ?? {'color': Colors.grey, 'icon': Icons.info};

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: (config['color'] as Color).withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    config['icon'] as IconData,
                    color: config['color'] as Color,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        info['title'] ?? '',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        'Updated ${info['lastUpdated']}',
                        style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                // Edit/Delete for Moderator
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert, color: Colors.grey.shade400),
                  onSelected: (value) {
                    if (value == 'delete') {
                      _deleteItem(info['id']!);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'delete', child: Text('Delete')),
                  ],
                ),
              ],
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  info['description'] ?? '',
                  maxLines: (index != null && _expanded.contains(index))
                      ? null
                      : 3,
                  overflow: (index != null && _expanded.contains(index))
                      ? TextOverflow.visible
                      : TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[700],
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 12),
                if ((info['description']?.length ?? 0) > 100)
                  GestureDetector(
                    onTap: () {
                      if (index != null) {
                        setState(() {
                          if (_expanded.contains(index)) {
                            _expanded.remove(index);
                          } else {
                            _expanded.add(index);
                          }
                        });
                      }
                    },
                    child: Text(
                      _expanded.contains(index) ? "Show Less" : "Read More",
                      style: TextStyle(
                        color: config['color'] as Color,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
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

  Future<void> _deleteItem(String id) async {
    try {
      await _db.collection('infoItems').doc(id).delete();
      // Remove from local list immediately for instant UI update
      setState(() {
        infoItems.removeWhere((item) => item['id'] == id);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Service deleted successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to delete service'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // --- ADD DIALOG LOGIC ---
  void _showAddInfoDialog() {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String selectedCategory = categoryConfig.keys.first;

    showDialog<void>(
      context: context,
      builder: (ctx) {
        return MediaQuery(
          data: MediaQuery.of(ctx).copyWith(viewInsets: EdgeInsets.zero),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Add Service Information',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: titleCtrl,
                        decoration: InputDecoration(
                          labelText: 'Title',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: selectedCategory,
                        items: categoryConfig.keys
                            .map(
                              (k) => DropdownMenuItem(value: k, child: Text(k)),
                            )
                            .toList(),
                        onChanged: (v) {
                          if (v != null) selectedCategory = v;
                        },
                        decoration: InputDecoration(
                          labelText: 'Category',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: descCtrl,
                        maxLines: 4,
                        decoration: InputDecoration(
                          labelText: 'Description',
                          alignLabelWithHint: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(),
                            child: const Text(
                              'Cancel',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () async {
                              final title = titleCtrl.text.trim();
                              final desc = descCtrl.text.trim();
                              if (title.isEmpty) return;
                              try {
                                await _ensureSignedIn();
                                final docRef = await _db
                                    .collection('infoItems')
                                    .add({
                                      'title': title,
                                      'category': selectedCategory,
                                      'description': desc,
                                      'createdAt': FieldValue.serverTimestamp(),
                                    });
                                if (!mounted) return;

                                // Add to local list immediately for instant UI update
                                final newItem = {
                                  'id': docRef.id,
                                  'title': title,
                                  'category': selectedCategory,
                                  'description': desc,
                                  'lastUpdated': 'just now',
                                };

                                setState(() {
                                  infoItems.insert(0, newItem);
                                });

                                Navigator.of(ctx).pop();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Service added successfully'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Failed to add service'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text(
                              'Post',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
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
                    _buildSectionTitle("Barangay Services"),
                    const SizedBox(height: 16),
                    _buildServicesGrid(),
                    const SizedBox(height: 24),
                    _buildSectionTitle("Added Services (Manage)"),
                    const SizedBox(height: 16),
                    _buildAddedServicesList(),
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

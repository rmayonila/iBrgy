import 'package:flutter/foundation.dart'; // For web check
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'moderator_nav.dart';
import '../audit_log_service.dart';

// --- 1. UPDATED CATEGORY CONFIGURATION ---
const Map<String, Map<String, dynamic>> categoryConfig = {
  'Health & Welfare': {'color': Color(0xFF4CAF50), 'icon': Icons.favorite},
  'Brgy Clearance/Permit Process': {
    'color': Color(0xFFFFA726),
    'icon': Icons.assignment,
  },
  'Cedula': {'color': Color(0xFF29B6F6), 'icon': Icons.schedule},
  'Community Programs': {'color': Color(0xFF26A69A), 'icon': Icons.groups},
  'Other': {'color': Color.fromARGB(255, 224, 18, 18), 'icon': Icons.info},
};

class ModeratorHomePage extends StatefulWidget {
  const ModeratorHomePage({super.key});

  @override
  State<ModeratorHomePage> createState() => _ModeratorHomePageState();
}

class _ModeratorHomePageState extends State<ModeratorHomePage> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  int _selectedIndex = 0;

  // Search State
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Track expanded state
  final Map<String, bool> _expandedStates = {};

  // Global Key for Snackbars to ensure they show inside the PhoneFrame
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  // Stream
  final Stream<QuerySnapshot> _servicesStream = FirebaseFirestore.instance
      .collection('barangay_services')
      .orderBy('createdAt', descending: true)
      .snapshots();

  Future<void> _ensureSignedIn() async {
    try {
      if (_auth.currentUser == null) {
        await _auth.signInAnonymously();
      }
    } catch (_) {
      // ignore auth errors
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    navigateModeratorIndex(
      context,
      index,
      currentIndex: _selectedIndex,
      onSamePage: (i) => setState(() => _selectedIndex = i),
    );
  }

  void _updateSearch(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
    });
  }

  // --- HELPER: Show Snackbar inside Frame ---
  void _showSnackBar(String message, Color color) {
    _scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  // --- CRUD LOGIC ---

  Future<void> _addService(String title, String category, String steps) async {
    await _ensureSignedIn();
    await _db.collection('barangay_services').add({
      'title': title,
      'category': category,
      'steps': steps,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // ADD THIS LINE:
    await AuditLogService.logActivity(
      action: 'added',
      page: 'services',
      title: title,
      message: 'New service posted',
    );
  }

  Future<void> _updateService(
    String docId,
    String title,
    String category,
    String steps,
  ) async {
    await _db.collection('barangay_services').doc(docId).update({
      'title': title,
      'category': category,
      'steps': steps,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // ADD THIS LINE:
    await AuditLogService.logActivity(
      action: 'edited',
      page: 'services',
      title: title,
      message: 'Service details updated',
    );
  }

  Future<void> _deleteService(String docId) async {
    await _db.collection('barangay_services').doc(docId).delete();

    // ADD THIS LINE:
    await AuditLogService.logActivity(
      action: 'deleted',
      page: 'services',
      title: 'Service',
      message: 'A service was removed',
    );
  }

  // --- DIALOGS ---

  void _showAddServiceDialog() {
    final titleCtrl = TextEditingController();
    final stepsCtrl = TextEditingController();
    String selectedCategory = categoryConfig.keys.first;

    showDialog(
      context: context,
      useRootNavigator: false, // Keep inside PhoneFrame
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: _buildDialogTitle(
                Icons.post_add_rounded,
                'Add Service',
                Colors.blue,
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildTextField(
                      controller: titleCtrl,
                      label: 'Service Title',
                      hint: 'e.g. Barangay Clearance',
                      icon: Icons.title_rounded,
                    ),
                    const SizedBox(height: 16),
                    _buildCategoryDropdown(
                      initialValue: selectedCategory,
                      onChanged: (val) {
                        setStateDialog(() => selectedCategory = val!);
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: stepsCtrl,
                      label: 'Steps / Requirements',
                      hint: '1. Bring valid ID\n2. Fill out form...',
                      icon: Icons.format_list_numbered_rounded,
                      maxLines: 6,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (titleCtrl.text.isEmpty || stepsCtrl.text.isEmpty) {
                      return;
                    }
                    await _addService(
                      titleCtrl.text,
                      selectedCategory,
                      stepsCtrl.text,
                    );
                    if (mounted) {
                      Navigator.of(ctx).pop();
                    }
                    _showSnackBar('Service Added Successfully', Colors.green);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showEditServiceDialog(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final titleCtrl = TextEditingController(text: data['title']);
    final stepsCtrl = TextEditingController(text: data['steps']);

    String currentCat = data['category'] ?? '';
    if (!categoryConfig.containsKey(currentCat)) {
      currentCat = categoryConfig.keys.first;
    }
    String selectedCategory = currentCat;

    showDialog(
      context: context,
      useRootNavigator: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: _buildDialogTitle(
                Icons.edit_rounded,
                'Edit Service',
                Colors.orange,
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildTextField(
                      controller: titleCtrl,
                      label: 'Service Title',
                      hint: 'e.g. Barangay Clearance',
                      icon: Icons.title_rounded,
                    ),
                    const SizedBox(height: 16),
                    _buildCategoryDropdown(
                      initialValue: selectedCategory,
                      onChanged: (val) {
                        setStateDialog(() => selectedCategory = val!);
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: stepsCtrl,
                      label: 'Steps / Requirements',
                      hint: '1. Bring valid ID...',
                      icon: Icons.format_list_numbered_rounded,
                      maxLines: 6,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    await _updateService(
                      doc.id,
                      titleCtrl.text,
                      selectedCategory,
                      stepsCtrl.text,
                    );
                    if (mounted) {
                      Navigator.of(ctx).pop();
                    }
                    _showSnackBar('Service Updated Successfully', Colors.green);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Update'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showDeleteConfirmDialog(String docId) {
    showDialog(
      context: context,
      useRootNavigator: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Delete Service',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
        ),
        // Fixed: Visible black text
        content: const Text(
          'Are you sure you want to delete this service?',
          style: TextStyle(color: Colors.black87),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              _deleteService(docId);
              if (mounted) {
                Navigator.of(ctx).pop();
              }
              _showSnackBar('Service Deleted', Colors.red);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  // --- HELPER WIDGETS ---

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.black87),
      maxLines: maxLines,
      minLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        filled: true,
        fillColor: Colors.grey.shade50,
        prefixIcon: Icon(icon, color: Colors.blue.shade700),
        labelStyle: TextStyle(color: Colors.grey.shade700),
        hintStyle: TextStyle(color: Colors.grey.shade400),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 20,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.blue.shade700, width: 2),
        ),
      ),
    );
  }

  Widget _buildCategoryDropdown({
    required String initialValue,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: initialValue,
      items: categoryConfig.keys.map((k) {
        return DropdownMenuItem(
          value: k,
          // Fixed: Explicit black color for visibility
          child: Text(k, style: const TextStyle(color: Colors.black87)),
        );
      }).toList(),
      onChanged: onChanged,
      // Fixed: Added contentPadding to align border with text fields
      decoration: InputDecoration(
        labelText: 'Category',
        filled: true,
        fillColor: Colors.grey.shade50,
        prefixIcon: Icon(Icons.category_outlined, color: Colors.blue.shade700),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 20,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      dropdownColor: Colors.white,
    );
  }

  Widget _buildDialogTitle(IconData icon, String title, MaterialColor color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color.shade700, size: 28),
        ),
        const SizedBox(width: 16),
        Text(
          title,
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  // --- MAIN UI BUILDERS ---

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

  // --- NEW WIDGET: Instructional Note ---
  Widget _buildInstructionalNote() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Quick Guide',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.blue.shade900,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Home contains the complete steps and requirements for all available Barangay services. Review the details first to save time and ensure you have everything needed before visiting the office.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.black87,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceCard(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final docId = doc.id;
    final title = data['title'] ?? 'Service';
    final category = data['category'] ?? 'Other';
    final steps = data['steps'] ?? '';

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
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          ListTile(
            leading: Container(
              height: 40,
              width: 40,
              decoration: BoxDecoration(
                color: (config['color'] as Color).withValues(alpha: 0.1),
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
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: () => _showEditServiceDialog(doc),
                  icon: const Icon(
                    Icons.edit_outlined,
                    color: Colors.grey,
                    size: 20,
                  ),
                  tooltip: "Edit",
                ),
                IconButton(
                  onPressed: () => _showDeleteConfirmDialog(docId),
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Colors.redAccent,
                    size: 20,
                  ),
                  tooltip: "Delete",
                ),
                InkWell(
                  onTap: () {
                    setState(() {
                      _expandedStates[docId] = !isExpanded;
                    });
                  },
                  child: Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
            onTap: () {
              setState(() {
                _expandedStates[docId] = !isExpanded;
              });
            },
          ),
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

  @override
  Widget build(BuildContext context) {
    // 1. Define the Mobile Content
    // Wrapped in ScaffoldMessenger to ensure snackbars show inside the layout
    Widget mobileContent = ScaffoldMessenger(
      key: _scaffoldMessengerKey,
      child: Scaffold(
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
                      const SizedBox(height: 20), // Adjusted spacing
                      _buildInstructionalNote(), // <<< NEW INSTRUCTIONAL NOTE
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          const Text(
                            "Barangay Services",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const Spacer(),
                          // Fixed: Tooltip styling (White background, black text)
                          Tooltip(
                            message: "Add Service",
                            textStyle: const TextStyle(
                              color: Colors.black,
                              fontSize: 12,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                            child: IconButton(
                              onPressed: _showAddServiceDialog,
                              icon: const Icon(
                                Icons.add,
                                color: Colors.blue,
                                size: 28,
                              ),
                            ),
                          ),
                        ],
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
                          final docs = snapshot.data?.docs ?? [];
                          final filteredDocs = _searchQuery.isEmpty
                              ? docs
                              : docs.where((doc) {
                                  final data =
                                      doc.data() as Map<String, dynamic>;
                                  final t = (data['title'] ?? '')
                                      .toString()
                                      .toLowerCase();
                                  return t.contains(_searchQuery);
                                }).toList();

                          if (filteredDocs.isEmpty) {
                            return Center(
                              child: Padding(
                                padding: const EdgeInsets.only(top: 40),
                                child: Text(
                                  "No services found",
                                  style: TextStyle(color: Colors.grey.shade500),
                                ),
                              ),
                            );
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
                color: Colors.black.withValues(alpha: 0.05),
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
        ),
      ),
    );

    // 2. Wrap for Web to constrain Dialogs/Overlays inside Phone Frame
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

// --- PHONE FRAME (For Web Preview) ---
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
          // ClipRRect ensures everything (including Dialogs via nested MaterialApp) stays inside
          child: ClipRRect(
            borderRadius: BorderRadius.circular(40),
            child: child,
          ),
        ),
      ),
    );
  }
}

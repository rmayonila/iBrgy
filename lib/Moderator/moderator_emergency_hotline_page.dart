// ignore_for_file: use_build_context_synchronously
import 'package:flutter/foundation.dart'; // For web check
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'moderator_nav.dart';

// ▼▼▼ CHANGED: Imported the correct service ▼▼▼
import '../services/activity_service.dart';
// ▲▲▲ END CHANGE ▲▲▲

class ModeratorEmergencyHotlinePage extends StatefulWidget {
  const ModeratorEmergencyHotlinePage({super.key});

  @override
  State<ModeratorEmergencyHotlinePage> createState() =>
      _ModeratorEmergencyHotlinePageState();
}

class _ModeratorEmergencyHotlinePageState
    extends State<ModeratorEmergencyHotlinePage> {
  int _selectedIndex = 1;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Global Key for Snackbars to ensure they show inside the PhoneFrame
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  // Stream to listen to changes in real-time
  final Stream<QuerySnapshot> _hotlinesStream = FirebaseFirestore.instance
      .collection('hotlines')
      .orderBy('createdAt', descending: true)
      .snapshots();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  IconData _getIconForType(String type) {
    switch (type.toLowerCase()) {
      case 'police':
        return Icons.local_police_rounded;
      case 'hospital':
      case 'ambulance':
        return Icons.medical_services_rounded;
      case 'fire':
        return Icons.local_fire_department_rounded;
      case 'disaster':
        return Icons.warning_amber_rounded;
      default:
        return Icons.phone_in_talk_rounded;
    }
  }

  Color _getColorForType(String type) {
    switch (type.toLowerCase()) {
      case 'police':
        return Colors.blue.shade700;
      case 'hospital':
      case 'ambulance':
        return Colors.red.shade600;
      case 'fire':
        return Colors.orange.shade700;
      case 'disaster':
        return Colors.amber.shade800;
      default:
        return Colors.grey.shade700;
    }
  }

  void _onItemTapped(int index) {
    // Navigate using the centralized logic
    navigateModeratorIndex(
      context,
      index,
      currentIndex: _selectedIndex,
      onSamePage: (i) => setState(() => _selectedIndex = i),
    );
  }

  Future<void> _ensureSignedIn() async {
    try {
      if (_auth.currentUser == null) {
        await _auth.signInAnonymously();
      }
    } catch (e) {
      // ignore sign-in errors
    }
  }

  // --- HELPER: SHOW SNACKBAR INSIDE FRAME ---
  void _showSnackBar(String message, {bool isError = false}) {
    _scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // --- ADD / EDIT DIALOG ---
  Future<void> _showAddEditDialog({DocumentSnapshot? existingDoc}) async {
    final isEditing = existingDoc != null;
    final data = isEditing ? existingDoc.data() as Map<String, dynamic> : {};

    final nameController = TextEditingController(text: data['name'] ?? '');
    final numberController = TextEditingController(text: data['number'] ?? '');
    String selectedType = data['type'] ?? 'Police';

    final types = ['Police', 'Fire', 'Hospital', 'Disaster', 'Other'];

    InputDecoration buildDecoration(String label, IconData icon) {
      return InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.blue.shade700),
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
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
      );
    }

    await showDialog(
      context: context,
      useRootNavigator: false, // Ensures dialog stays in phone frame
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    isEditing ? Icons.edit_rounded : Icons.add_call,
                    color: Colors.blue.shade700,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  isEditing ? 'Edit Hotline' : 'Add Hotline',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    style: const TextStyle(color: Colors.black87),
                    decoration: buildDecoration(
                      'Name (e.g., Police Station)',
                      Icons.business_rounded,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: numberController,
                    keyboardType: TextInputType.phone,
                    style: const TextStyle(color: Colors.black87),
                    decoration: buildDecoration(
                      'Phone Number',
                      Icons.phone_rounded,
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedType,
                    style: const TextStyle(color: Colors.black87, fontSize: 16),
                    dropdownColor: Colors.white,
                    decoration: buildDecoration(
                      'Category',
                      Icons.category_rounded,
                    ),
                    items: types
                        .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() => selectedType = val);
                      }
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text(
                  'Cancel',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  final name = nameController.text.trim();
                  final number = numberController.text.trim();

                  if (name.isEmpty || number.isEmpty) {
                    _showSnackBar('Please fill all fields', isError: true);
                    return;
                  }

                  Navigator.of(ctx).pop();

                  try {
                    await _ensureSignedIn();
                    if (isEditing) {
                      await _db
                          .collection('hotlines')
                          .doc(existingDoc!.id)
                          .update({
                            'name': name,
                            'number': number,
                            'type': selectedType,
                            'updatedAt': FieldValue.serverTimestamp(),
                          });

                      // ▼▼▼ TRACKING: EDIT HOTLINE ▼▼▼
                      await ActivityService().logActivity(
                        context,
                        actionTitle: 'Edited Hotline',
                        details: 'Updated hotline: $name',
                      );
                      // ▲▲▲ END TRACKING ▲▲▲

                      _showSnackBar('Hotline updated successfully');
                    } else {
                      await _db.collection('hotlines').add({
                        'name': name,
                        'number': number,
                        'type': selectedType,
                        'createdAt': FieldValue.serverTimestamp(),
                      });

                      // ▼▼▼ TRACKING: ADD HOTLINE ▼▼▼
                      await ActivityService().logActivity(
                        context,
                        actionTitle: 'Added Hotline',
                        details: 'Added hotline: $name ($number)',
                      );
                      // ▲▲▲ END TRACKING ▲▲▲

                      _showSnackBar('Hotline added successfully');
                    }
                  } catch (e) {
                    _showSnackBar('Error: $e', isError: true);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade700,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(isEditing ? 'Save' : 'Add'),
              ),
            ],
          );
        },
      ),
    );
  }

  // --- DELETE DIALOG ---
  Future<void> _deleteHotline(String docId, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      useRootNavigator: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Delete Hotline',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to delete "$name"?',
          style: const TextStyle(color: Colors.black87),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _db.collection('hotlines').doc(docId).delete();

        // ▼▼▼ TRACKING: DELETE HOTLINE ▼▼▼
        await ActivityService().logActivity(
          context,
          actionTitle: 'Deleted Hotline',
          details: 'Deleted hotline: $name',
        );
        // ▲▲▲ END TRACKING ▲▲▲

        _showSnackBar('Hotline deleted successfully');
      } catch (e) {
        _showSnackBar('Error deleting: $e', isError: true);
      }
    }
  }

  // --- WIDGETS ---

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
            color: Colors.black.withOpacity(0.05), // Fixed Opacity
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
              Icons.emergency_rounded,
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

  Widget _buildEmergencyBanner() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.red.shade600, Colors.red.shade400],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.3), // Fixed Opacity
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Emergency Hotlines",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Manage critical contact numbers for barangay emergencies.",
                  style: TextStyle(color: Colors.red.shade50, fontSize: 13),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.phone_in_talk_rounded,
              color: Colors.white,
              size: 28,
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
            color: Colors.black.withOpacity(0.03), // Fixed Opacity
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (value) =>
            setState(() => _searchQuery = value.toLowerCase()),
        style: const TextStyle(color: Colors.black87),
        decoration: InputDecoration(
          hintText: "Search hotlines...",
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

  Widget _buildHotlineCard(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final name = data['name'] ?? 'Unknown';
    final number = data['number'] ?? '';
    final type = data['type'] ?? 'Other';
    final icon = _getIconForType(type);
    final color = _getColorForType(type);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02), // Fixed Opacity
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        title: Text(
          name,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Colors.black87,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.phone_rounded,
                  size: 14,
                  color: Colors.grey.shade500,
                ),
                const SizedBox(width: 4),
                Text(
                  number,
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          color: Colors.white,
          icon: Icon(Icons.more_vert, color: Colors.grey.shade400),
          onSelected: (value) {
            if (value == 'edit') {
              _showAddEditDialog(existingDoc: doc);
            } else if (value == 'delete') {
              _deleteHotline(doc.id, name);
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit_rounded, size: 20, color: Colors.black87),
                  SizedBox(width: 8),
                  Text('Edit', style: TextStyle(color: Colors.black87)),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(
                    Icons.delete_outline_rounded,
                    size: 20,
                    color: Colors.red,
                  ),
                  SizedBox(width: 8),
                  Text('Delete', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05), // Fixed Opacity
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

  @override
  Widget build(BuildContext context) {
    // 1. Prepare Content Widget
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
                    children: [
                      _buildSearchBar(),
                      const SizedBox(height: 24),
                      _buildEmergencyBanner(),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "Hotline Numbers",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            IconButton(
                              onPressed: () => _showAddEditDialog(),
                              icon: const Icon(Icons.add_circle_rounded),
                              color: Colors.blue.shade700,
                              iconSize: 28,
                              tooltip: 'Add Hotline',
                            ),
                          ],
                        ),
                      ),
                      StreamBuilder<QuerySnapshot>(
                        stream: _hotlinesStream,
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
                          final filtered = docs.where((doc) {
                            final data = doc.data() as Map<String, dynamic>;
                            final name = (data['name'] ?? '')
                                .toString()
                                .toLowerCase();
                            final number = (data['number'] ?? '')
                                .toString()
                                .toLowerCase();
                            return name.contains(_searchQuery) ||
                                number.contains(_searchQuery);
                          }).toList();

                          if (filtered.isEmpty) {
                            return Center(
                              child: Padding(
                                padding: const EdgeInsets.only(top: 40),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.search_off_rounded,
                                      size: 48,
                                      color: Colors.grey.shade300,
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      "No hotlines found",
                                      style: TextStyle(
                                        color: Colors.grey.shade500,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }

                          return Column(
                            children: filtered
                                .map((doc) => _buildHotlineCard(doc))
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
        bottomNavigationBar: _buildBottomNavBar(),
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
                color: Colors.black.withOpacity(0.1), // FIXED
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

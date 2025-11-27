import 'package:flutter/foundation.dart'; // For web check
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'moderator_nav.dart';

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
    switch (type) {
      case 'national':
        return Icons.warning_amber_rounded;
      case 'local':
        return Icons.medical_services_outlined;
      case 'barangay':
        return Icons.local_police_outlined;
      default:
        return Icons.call_rounded;
    }
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

  // --- DIALOGS ---

  // Enhanced Add Hotline Dialog
  Future<void> _showAddHotlineDialog({String? presetType}) async {
    final nameController = TextEditingController();
    final numberController = TextEditingController();
    String selectedType = presetType ?? 'national';
    bool isUrgent = false;

    await showDialog(
      context: context,
      useRootNavigator: false, // Keep inside Phone Frame
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: _buildDialogTitle(
              Icons.add_call,
              'Add Hotline',
              Colors.blue,
            ),
            content: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(ctx).viewInsets.bottom,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTextField(
                      controller: nameController,
                      label: 'Name / Service',
                      icon: Icons.label_outline,
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: numberController,
                      label: 'Phone Number',
                      icon: Icons.phone_outlined,
                      inputType: TextInputType.phone,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Hotline Type:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: ['national', 'local', 'barangay'].map((type) {
                        final isSelected = selectedType == type;
                        return ChoiceChip(
                          label: Text(
                            type[0].toUpperCase() + type.substring(1),
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.black87,
                            ),
                          ),
                          selected: isSelected,
                          selectedColor: Colors.blue,
                          backgroundColor: Colors.grey.shade100,
                          onSelected: (selected) {
                            setDialogState(() {
                              selectedType = type;
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Checkbox(
                          value: isUrgent,
                          activeColor: Colors.red,
                          onChanged: (value) {
                            setDialogState(() {
                              isUrgent = value ?? false;
                            });
                          },
                        ),
                        const Text(
                          'Mark as urgent',
                          style: TextStyle(color: Colors.black87),
                        ),
                      ],
                    ),
                  ],
                ),
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
                  if (nameController.text.isEmpty ||
                      numberController.text.isEmpty) {
                    return;
                  }
                  await _addHotline(
                    nameController.text,
                    numberController.text,
                    selectedType,
                    isUrgent,
                  );
                  Navigator.of(ctx).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _addHotline(
    String name,
    String number,
    String type,
    bool isUrgent,
  ) async {
    try {
      await _db.collection('hotlines').add({
        'name': name.trim(),
        'number': number.trim(),
        'type': type,
        'isUrgent': isUrgent,
        'createdAt': FieldValue.serverTimestamp(),
      });
      _showSnackBar('Hotline Added Successfully', Colors.green);
    } catch (e) {
      _showSnackBar('Failed to add hotline: $e', Colors.red);
    }
  }

  // Edit Hotline Dialog
  Future<void> _showEditHotlineDialog(Map<String, dynamic> hotline) async {
    final nameController = TextEditingController(text: hotline['name']);
    final numberController = TextEditingController(text: hotline['number']);
    String selectedType = hotline['type'] ?? 'national';
    bool isUrgent = hotline['isUrgent'] == true;
    final hotlineId = hotline['id'];

    await showDialog(
      context: context,
      useRootNavigator: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: _buildDialogTitle(
              Icons.edit_rounded,
              'Edit Hotline',
              Colors.orange,
            ),
            content: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(ctx).viewInsets.bottom,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTextField(
                      controller: nameController,
                      label: 'Name / Service',
                      icon: Icons.label_outline,
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: numberController,
                      label: 'Phone Number',
                      icon: Icons.phone_outlined,
                      inputType: TextInputType.phone,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Hotline Type:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: ['national', 'local', 'barangay'].map((type) {
                        final isSelected = selectedType == type;
                        return ChoiceChip(
                          label: Text(
                            type[0].toUpperCase() + type.substring(1),
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.black87,
                            ),
                          ),
                          selected: isSelected,
                          selectedColor: Colors.orange,
                          backgroundColor: Colors.grey.shade100,
                          onSelected: (selected) {
                            setDialogState(() {
                              selectedType = type;
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Checkbox(
                          value: isUrgent,
                          activeColor: Colors.red,
                          onChanged: (value) {
                            setDialogState(() {
                              isUrgent = value ?? false;
                            });
                          },
                        ),
                        const Text(
                          'Mark as urgent',
                          style: TextStyle(color: Colors.black87),
                        ),
                      ],
                    ),
                  ],
                ),
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
                  if (nameController.text.isEmpty ||
                      numberController.text.isEmpty) {
                    return;
                  }
                  await _updateHotline(
                    hotlineId,
                    nameController.text,
                    numberController.text,
                    selectedType,
                    isUrgent,
                  );
                  Navigator.of(ctx).pop();
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
      ),
    );
  }

  Future<void> _updateHotline(
    String id,
    String name,
    String number,
    String type,
    bool isUrgent,
  ) async {
    try {
      await _db.collection('hotlines').doc(id).update({
        'name': name.trim(),
        'number': number.trim(),
        'type': type,
        'isUrgent': isUrgent,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      _showSnackBar('Hotline Updated Successfully', Colors.green);
    } catch (e) {
      _showSnackBar('Failed to update: $e', Colors.red);
    }
  }

  // Delete Hotline
  Future<void> _deleteHotline(Map<String, dynamic> hotline) async {
    final id = hotline['id'];

    final confirmDelete = await showDialog<bool>(
      context: context,
      useRootNavigator: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Confirm Deletion',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to delete "${hotline['name']}"?',
          style: const TextStyle(color: Colors.black87),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmDelete == true && id != null) {
      try {
        await _db.collection('hotlines').doc(id).delete();
        _showSnackBar('Hotline Deleted', Colors.red);
      } catch (e) {
        _showSnackBar('Failed to delete: $e', Colors.red);
      }
    }
  }

  // --- WIDGET BUILDERS ---

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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    IconData? icon,
    TextInputType inputType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.black87),
      keyboardType: inputType,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.grey.shade50,
        prefixIcon: icon != null
            ? Icon(icon, color: Colors.blue.shade700)
            : null,
        labelStyle: TextStyle(color: Colors.grey.shade700),
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
        // Fixed: Black text color
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

  Widget _buildSectionTitle(
    String title, {
    String? addTooltip,
    String? presetType,
  }) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12, top: 8),
      child: Row(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
              letterSpacing: 0.5,
            ),
          ),
          const Spacer(),
          // Fixed: Tooltip inside frame with white background and black text
          Tooltip(
            message: addTooltip ?? "Add",
            textStyle: const TextStyle(color: Colors.black, fontSize: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4),
              ],
            ),
            child: IconButton(
              onPressed: () => _showAddHotlineDialog(presetType: presetType),
              icon: const Icon(Icons.add, size: 20),
              color: Colors.blue,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ),
        ],
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
        trailing: PopupMenuButton<String>(
          color: Colors.white, // Fixed: White background
          onSelected: (value) {
            if (value == 'edit') {
              _showEditHotlineDialog(item);
            } else if (value == 'delete') {
              _deleteHotline(item);
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit, size: 20, color: Colors.grey),
                  SizedBox(width: 8),
                  // Fixed: Black text for Edit
                  Text('Edit', style: TextStyle(color: Colors.black)),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, size: 20, color: Colors.red),
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

  Widget _buildEmptyState(String message, String type) {
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
            message,
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

  @override
  Widget build(BuildContext context) {
    // 1. Mobile Content Wrapped in ScaffoldMessenger for Snackbars
    Widget mobileContent = ScaffoldMessenger(
      key: _scaffoldMessengerKey,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: _hotlinesStream,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(40.0),
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }
                    if (snapshot.hasError) {
                      return Center(child: Text("Error: ${snapshot.error}"));
                    }

                    final docs = snapshot.data?.docs ?? [];
                    final allItems = docs.map((d) {
                      final data = d.data() as Map<String, dynamic>;
                      return {
                        'id': d.id,
                        'name': (data['name'] ?? '').toString(),
                        'number': (data['number'] ?? '').toString(),
                        'type': (data['type'] ?? 'national').toString(),
                        'isUrgent': data['isUrgent'] == true,
                        'icon': _getIconForType(
                          (data['type'] ?? 'national').toString(),
                        ),
                      };
                    }).toList();

                    // Apply Search Filter
                    final filteredItems = _searchQuery.isEmpty
                        ? allItems
                        : allItems.where((h) {
                            final name = h['name'].toString().toLowerCase();
                            final num = h['number'].toString().toLowerCase();
                            return name.contains(_searchQuery) ||
                                num.contains(_searchQuery);
                          }).toList();

                    final nationalHotlines = filteredItems
                        .where((i) => i['type'] == 'national')
                        .toList();
                    final localHotlines = filteredItems
                        .where((i) => i['type'] == 'local')
                        .toList();
                    final barangayHotlines = filteredItems
                        .where((i) => i['type'] == 'barangay')
                        .toList();

                    // If searching and everything is empty, show "No results"
                    if (_searchQuery.isNotEmpty && filteredItems.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.search_off,
                              size: 50,
                              color: Colors.grey.shade300,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              "No hotlines found for \"$_searchQuery\"",
                              style: TextStyle(color: Colors.grey.shade500),
                            ),
                          ],
                        ),
                      );
                    }

                    // Build UI
                    return SingleChildScrollView(
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
                            "Manage emergency contact numbers",
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Sections (Hide header if searching and empty)
                          if (_searchQuery.isEmpty ||
                              nationalHotlines.isNotEmpty) ...[
                            _buildSectionTitle(
                              "NATIONAL EMERGENCY",
                              addTooltip: "Add National Hotline",
                              presetType: "national",
                            ),
                            if (nationalHotlines.isEmpty)
                              _buildEmptyState(
                                "No national hotlines added yet",
                                "national",
                              )
                            else
                              ...nationalHotlines.map(
                                (h) => _buildHotlineCard(h),
                              ),
                            const SizedBox(height: 20),
                          ],

                          if (_searchQuery.isEmpty ||
                              localHotlines.isNotEmpty) ...[
                            _buildSectionTitle(
                              "LOCAL HOTLINES",
                              addTooltip: "Add Local Hotline",
                              presetType: "local",
                            ),
                            if (localHotlines.isEmpty)
                              _buildEmptyState(
                                "No local hotlines added yet",
                                "local",
                              )
                            else
                              ...localHotlines.map((h) => _buildHotlineCard(h)),
                            const SizedBox(height: 20),
                          ],

                          if (_searchQuery.isEmpty ||
                              barangayHotlines.isNotEmpty) ...[
                            _buildSectionTitle(
                              "BARANGAY HOTLINES",
                              addTooltip: "Add Barangay Hotline",
                              presetType: "barangay",
                            ),
                            if (barangayHotlines.isEmpty)
                              _buildEmptyState(
                                "No barangay hotlines added yet",
                                "barangay",
                              )
                            else
                              ...barangayHotlines.map(
                                (h) => _buildHotlineCard(h),
                              ),
                            const SizedBox(height: 20),
                          ],
                        ],
                      ),
                    );
                  },
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
                color: Colors.black.withOpacity(0.05),
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

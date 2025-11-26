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

  // All hotlines will be loaded from Firestore
  List<Map<String, dynamic>> _nationalHotlines = [];
  List<Map<String, dynamic>> _localHotlines = [];
  List<Map<String, dynamic>> _barangayHotlines = [];

  @override
  void initState() {
    super.initState();
    _loadHotlines();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadHotlines() async {
    try {
      final snap = await _db
          .collection('hotlines')
          .orderBy('createdAt', descending: true)
          .get();

      if (!mounted) return;

      final items = snap.docs.map((d) {
        final data = d.data();
        return {
          'id': d.id,
          'name': (data['name'] ?? '').toString(),
          'number': (data['number'] ?? '').toString(),
          'type': (data['type'] ?? 'national').toString(),
          'isUrgent': data['isUrgent'] == true,
          'icon': _getIconForType((data['type'] ?? 'national').toString()),
        };
      }).toList();

      setState(() {
        _nationalHotlines = items
            .where((item) => item['type'] == 'national')
            .toList();
        _localHotlines = items
            .where((item) => item['type'] == 'local')
            .toList();
        _barangayHotlines = items
            .where((item) => item['type'] == 'barangay')
            .toList();
      });
    } catch (e) {
      // ignore
    }
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

  // Filter hotlines based on search query
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

  List<Map<String, dynamic>> get _filteredBarangay {
    if (_searchQuery.isEmpty) return _barangayHotlines;
    return _barangayHotlines.where((h) {
      return h['name'].toLowerCase().contains(_searchQuery) ||
          h['number'].toLowerCase().contains(_searchQuery);
    }).toList();
  }

  // Enhanced Add Hotline Dialog with type selection
  Future<void> _showAddHotlineDialog({String? presetType}) async {
    final nameController = TextEditingController();
    final numberController = TextEditingController();
    String selectedType = presetType ?? 'national';
    bool isUrgent = false;

    final entered = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Add Emergency Hotline'),
            content: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(ctx).viewInsets.bottom,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Name / Service',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: numberController,
                      decoration: const InputDecoration(
                        labelText: 'Phone Number',
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Select Hotline Type:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: ['national', 'local', 'barangay'].map((type) {
                        return ChoiceChip(
                          label: Text(
                            type[0].toUpperCase() + type.substring(1),
                          ),
                          selected: selectedType == type,
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
                          onChanged: (value) {
                            setDialogState(() {
                              isUrgent = value ?? false;
                            });
                          },
                        ),
                        const Text('Mark as urgent'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(null),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(ctx).pop({
                    'name': nameController.text.trim(),
                    'number': numberController.text.trim(),
                    'type': selectedType,
                    'isUrgent': isUrgent,
                  });
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );

    nameController.dispose();
    numberController.dispose();

    if (entered != null) {
      if (!mounted) return;
      final scaffold = ScaffoldMessenger.of(context);
      final name = entered['name']?.toString().trim() ?? '';
      final number = entered['number']?.toString().trim() ?? '';
      final type = entered['type']?.toString() ?? 'national';
      final isUrgentValue = entered['isUrgent'] == true;

      if (name.isEmpty || number.isEmpty) {
        scaffold.showSnackBar(
          const SnackBar(content: Text('Please fill all fields')),
        );
        return;
      }

      try {
        final docRef = await _db.collection('hotlines').add({
          'name': name,
          'number': number,
          'type': type,
          'isUrgent': isUrgentValue,
          'createdAt': FieldValue.serverTimestamp(),
        });

        if (!mounted) return;

        final newHotline = {
          'id': docRef.id,
          'name': name,
          'number': number,
          'type': type,
          'isUrgent': isUrgentValue,
          'icon': _getIconForType(type),
        };

        setState(() {
          if (type == 'national') {
            _nationalHotlines.insert(0, newHotline);
          } else if (type == 'local') {
            _localHotlines.insert(0, newHotline);
          } else if (type == 'barangay') {
            _barangayHotlines.insert(0, newHotline);
          }
        });

        scaffold.showSnackBar(const SnackBar(content: Text('Hotline added')));
      } catch (e) {
        scaffold.showSnackBar(
          SnackBar(content: Text('Failed to add hotline: $e')),
        );
      }
    }
  }

  // Edit Hotline Dialog
  Future<void> _showEditHotlineDialog(Map<String, dynamic> hotline) async {
    final nameController = TextEditingController(text: hotline['name']);
    final numberController = TextEditingController(text: hotline['number']);
    String selectedType = hotline['type'] ?? 'national';
    bool isUrgent = hotline['isUrgent'] == true;

    final entered = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Edit Hotline'),
            content: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(ctx).viewInsets.bottom,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Name / Service',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: numberController,
                      decoration: const InputDecoration(
                        labelText: 'Phone Number',
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Hotline Type:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: ['national', 'local', 'barangay'].map((type) {
                        return ChoiceChip(
                          label: Text(
                            type[0].toUpperCase() + type.substring(1),
                          ),
                          selected: selectedType == type,
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
                          onChanged: (value) {
                            setDialogState(() {
                              isUrgent = value ?? false;
                            });
                          },
                        ),
                        const Text('Mark as urgent'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(null),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(ctx).pop({
                    'name': nameController.text.trim(),
                    'number': numberController.text.trim(),
                    'type': selectedType,
                    'isUrgent': isUrgent,
                  });
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );

    nameController.dispose();
    numberController.dispose();

    if (entered != null) {
      if (!mounted) return;
      final scaffold = ScaffoldMessenger.of(context);
      final newName = entered['name']?.toString().trim() ?? '';
      final newNumber = entered['number']?.toString().trim() ?? '';
      final newType = entered['type']?.toString() ?? 'national';
      final newIsUrgent = entered['isUrgent'] == true;
      final hotlineId = hotline['id'];

      if (newName.isEmpty || newNumber.isEmpty) {
        scaffold.showSnackBar(
          const SnackBar(content: Text('Please fill all fields')),
        );
        return;
      }

      try {
        await _db.collection('hotlines').doc(hotlineId).update({
          'name': newName,
          'number': newNumber,
          'type': newType,
          'isUrgent': newIsUrgent,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        if (!mounted) return;

        setState(() {
          // Remove from all lists
          _nationalHotlines.removeWhere((item) => item['id'] == hotlineId);
          _localHotlines.removeWhere((item) => item['id'] == hotlineId);
          _barangayHotlines.removeWhere((item) => item['id'] == hotlineId);

          // Add to appropriate list based on new type
          final updatedHotline = {
            ...hotline,
            'name': newName,
            'number': newNumber,
            'type': newType,
            'isUrgent': newIsUrgent,
            'icon': _getIconForType(newType),
          };

          if (newType == 'national') {
            _nationalHotlines.insert(0, updatedHotline);
          } else if (newType == 'local') {
            _localHotlines.insert(0, updatedHotline);
          } else if (newType == 'barangay') {
            _barangayHotlines.insert(0, updatedHotline);
          }
        });

        scaffold.showSnackBar(const SnackBar(content: Text('Hotline updated')));
      } catch (e) {
        scaffold.showSnackBar(
          SnackBar(content: Text('Failed to update hotline: $e')),
        );
      }
    }
  }

  // Delete Hotline
  Future<void> _deleteHotline(Map<String, dynamic> hotline) async {
    final id = hotline['id'];
    final scaffold = ScaffoldMessenger.of(context);

    final confirmDelete = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Deletion'),
        content: Text('Are you sure you want to delete "${hotline['name']}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmDelete == true && id != null) {
      try {
        await _db.collection('hotlines').doc(id).delete();

        if (!mounted) return;

        setState(() {
          _nationalHotlines.removeWhere((item) => item['id'] == id);
          _localHotlines.removeWhere((item) => item['id'] == id);
          _barangayHotlines.removeWhere((item) => item['id'] == id);
        });

        scaffold.showSnackBar(const SnackBar(content: Text('Hotline deleted')));
      } catch (e) {
        scaffold.showSnackBar(SnackBar(content: Text('Failed to delete: $e')));
      }
    }
  }

  // Widget Builders
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
          IconButton(
            onPressed: () => _showAddHotlineDialog(presetType: presetType),
            icon: const Icon(Icons.add, size: 20),
            color: Colors.blue,
            tooltip: addTooltip,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
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
                  Icon(Icons.edit, size: 20),
                  SizedBox(width: 8),
                  Text('Edit'),
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
    return Scaffold(
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

                    // NATIONAL EMERGENCY SECTION (Editable)
                    _buildSectionTitle(
                      "NATIONAL EMERGENCY",
                      addTooltip: "Add National Hotline",
                      presetType: "national",
                    ),
                    if (_filteredNational.isEmpty)
                      _buildEmptyState(
                        "No national hotlines added yet",
                        "national",
                      )
                    else
                      ..._filteredNational.map((h) => _buildHotlineCard(h)),
                    const SizedBox(height: 20),

                    // LOCAL HOTLINES SECTION (Editable)
                    _buildSectionTitle(
                      "LOCAL HOTLINES",
                      addTooltip: "Add Local Hotline",
                      presetType: "local",
                    ),
                    if (_filteredLocal.isEmpty)
                      _buildEmptyState("No local hotlines added yet", "local")
                    else
                      ..._filteredLocal.map((h) => _buildHotlineCard(h)),
                    const SizedBox(height: 20),

                    // BARANGAY HOTLINES SECTION (Editable)
                    _buildSectionTitle(
                      "BARANGAY HOTLINES",
                      addTooltip: "Add Barangay Hotline",
                      presetType: "barangay",
                    ),
                    if (_filteredBarangay.isEmpty)
                      _buildEmptyState(
                        "No barangay hotlines added yet",
                        "barangay",
                      )
                    else
                      ..._filteredBarangay.map((h) => _buildHotlineCard(h)),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }
}

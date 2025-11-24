import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'moderator_nav.dart';

class ModeratorBrgyOfficialsPage extends StatefulWidget {
  const ModeratorBrgyOfficialsPage({super.key});

  @override
  State<ModeratorBrgyOfficialsPage> createState() =>
      _ModeratorBrgyOfficialsPageState();
}

class _ModeratorBrgyOfficialsPageState
    extends State<ModeratorBrgyOfficialsPage> {
  int _selectedIndex = 3; // People tab
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Data State
  Map<String, List<Map<String, String>>> _allOfficials = {};
  Map<String, List<Map<String, String>>> _filteredOfficials = {};
  Map<String, Map<String, String>> _contacts = {};

  // Search State
  final TextEditingController _searchController = TextEditingController();

  // Editing State
  final Map<String, List<TextEditingController>> _nameControllers = {};
  final Map<String, List<bool>> _isEditing = {};
  final Map<String, List<FocusNode>> _focusNodes = {};
  final Map<String, Map<String, TextEditingController>>
  _contactControllersPerCategory = {};

  @override
  void initState() {
    super.initState();
    _loadOfficialsAndContacts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    // Dispose all editing controllers
    for (var list in _nameControllers.values) {
      for (var controller in list) {
        controller.dispose();
      }
    }
    for (var list in _focusNodes.values) {
      for (var focusNode in list) {
        focusNode.dispose();
      }
    }
    for (var map in _contactControllersPerCategory.values) {
      for (var controller in map.values) {
        controller.dispose();
      }
    }
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

  Future<void> _loadOfficialsAndContacts() async {
    try {
      // Load officials
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

      // Load contact docs
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

        // Initialize editing controllers
        _initializeEditingControllers();
      });
    } catch (e) {
      // ignore load errors
    }
  }

  void _initializeEditingControllers() {
    _nameControllers.clear();
    _isEditing.clear();
    _focusNodes.clear();
    _contactControllersPerCategory.clear();

    for (var entry in _allOfficials.entries) {
      _nameControllers[entry.key] = entry.value
          .map((e) => TextEditingController(text: e['name']))
          .toList();
      _isEditing[entry.key] = List.generate(entry.value.length, (_) => false);
      _focusNodes[entry.key] = List.generate(
        entry.value.length,
        (_) => FocusNode(),
      );
    }

    for (var entry in _contacts.entries) {
      _contactControllersPerCategory[entry.key] = {
        'address': TextEditingController(text: entry.value['address']),
        'hours': TextEditingController(text: entry.value['hours']),
        'contacts': TextEditingController(text: entry.value['contacts']),
      };
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

    _allOfficials.forEach((category, officialsList) {
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

  // --- CRUD OPERATIONS ---

  // ADD Official Dialog
  Future<void> _showAddOfficialDialog() async {
    final titleController = TextEditingController();
    final nameController = TextEditingController();
    final categoryController = TextEditingController();

    final entered = await showDialog<Map<String, String>>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Barangay Official'),
        content: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: categoryController,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    hintText: 'e.g., Punong Barangay',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Position Title',
                    hintText: 'e.g., Barangay Captain',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    hintText: 'e.g., Juan Dela Cruz',
                  ),
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
                'category': categoryController.text.trim(),
                'title': titleController.text.trim(),
                'name': nameController.text.trim(),
              });
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    titleController.dispose();
    nameController.dispose();
    categoryController.dispose();

    if (entered != null) {
      final scaffold = ScaffoldMessenger.of(context);
      final category = entered['category'] ?? '';
      final title = entered['title'] ?? '';
      final name = entered['name'] ?? '';

      if (category.isEmpty || title.isEmpty || name.isEmpty) {
        scaffold.showSnackBar(
          const SnackBar(content: Text('Please fill all fields')),
        );
        return;
      }

      try {
        final docRef = await _db.collection('officials').add({
          'category': category,
          'title': title,
          'name': name,
          'createdAt': FieldValue.serverTimestamp(),
        });

        if (!mounted) return;
        setState(() {
          if (!_allOfficials.containsKey(category)) {
            _allOfficials[category] = [];
          }
          _allOfficials[category]!.add({
            'id': docRef.id,
            'title': title,
            'name': name,
          });
          _filteredOfficials = Map.from(_allOfficials);
          _initializeEditingControllers();
        });

        scaffold.showSnackBar(const SnackBar(content: Text('Official added')));
      } catch (e) {
        scaffold.showSnackBar(
          SnackBar(content: Text('Failed to add official: $e')),
        );
      }
    }
  }

  // EDIT Official
  Future<void> _editOfficial(String category, int index) async {
    final official = _allOfficials[category]![index];
    final controller = _nameControllers[category]![index];

    if (_isEditing[category]![index]) {
      // Save changes
      final newName = controller.text.trim();
      if (newName.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Name cannot be empty')));
        return;
      }

      try {
        final id = official['id'];
        if (id != null) {
          await _db.collection('officials').doc(id).update({
            'name': newName,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }

        setState(() {
          _allOfficials[category]![index]['name'] = newName;
          _isEditing[category]![index] = false;
          _filteredOfficials = Map.from(_allOfficials);
        });

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Official updated')));
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to update: $e')));
      }
    } else {
      // Start editing
      setState(() {
        _isEditing[category]![index] = true;
      });
      Future.delayed(const Duration(milliseconds: 100), () {
        _focusNodes[category]![index].requestFocus();
      });
    }
  }

  // DELETE Official
  Future<void> _deleteOfficial(String category, int index) async {
    final official = _allOfficials[category]![index];
    final scaffold = ScaffoldMessenger.of(context);

    final confirmDelete = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Deletion'),
        content: Text(
          'Are you sure you want to delete "${official['title']}"?',
        ),
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

    if (confirmDelete == true) {
      final id = official['id'];
      if (id != null) {
        try {
          await _db.collection('officials').doc(id).delete();
        } catch (e) {
          scaffold.showSnackBar(
            SnackBar(content: Text('Failed to delete: $e')),
          );
          return;
        }
      }

      if (!mounted) return;
      setState(() {
        // Clean up controllers
        _nameControllers[category]![index].dispose();
        _focusNodes[category]![index].dispose();

        // Remove from lists
        _allOfficials[category]!.removeAt(index);
        _nameControllers[category]!.removeAt(index);
        _isEditing[category]!.removeAt(index);
        _focusNodes[category]!.removeAt(index);

        _filteredOfficials = Map.from(_allOfficials);
      });

      scaffold.showSnackBar(const SnackBar(content: Text('Official deleted')));
    }
  }

  // EDIT Contact Info
  Future<void> _editContactInfo(
    String category,
    String field,
    String label,
  ) async {
    final controllers = _contactControllersPerCategory[category];
    if (controllers == null) return;

    final currentController = controllers[field]!;
    final inputController = TextEditingController(text: currentController.text);

    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Edit $label'),
        content: TextField(
          controller: inputController,
          decoration: InputDecoration(hintText: 'Enter $label'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(null),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(inputController.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    inputController.dispose();

    if (result != null) {
      final scaffold = ScaffoldMessenger.of(context);
      try {
        await _db.collection('official_contacts').doc(category).set({
          field: result,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        setState(() {
          currentController.text = result;
          _contacts[category] ??= {};
          _contacts[category]![field] = result;
        });

        scaffold.showSnackBar(
          const SnackBar(content: Text('Contact info updated')),
        );
      } catch (e) {
        scaffold.showSnackBar(
          SnackBar(content: Text('Failed to update contact info: $e')),
        );
      }
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

  Widget _buildOfficialCard(String category, int index) {
    final official = _filteredOfficials[category]![index];
    final isEditing = _isEditing[category]?[index] ?? false;
    final controller = _nameControllers[category]?[index];
    final focusNode = _focusNodes[category]?[index];

    if (controller == null || focusNode == null) {
      return const SizedBox.shrink();
    }

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
            backgroundColor: Colors.blue.shade50,
            child: Text(
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
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: controller,
                        focusNode: focusNode,
                        readOnly: !isEditing,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'edit') {
                          _editOfficial(category, index);
                        } else if (value == 'delete') {
                          _deleteOfficial(category, index);
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(
                                Icons.edit,
                                size: 20,
                                color: Colors.blue.shade700,
                              ),
                              const SizedBox(width: 8),
                              Text(isEditing ? 'Save' : 'Edit'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, size: 20, color: Colors.red),
                              const SizedBox(width: 8),
                              const Text(
                                'Delete',
                                style: TextStyle(color: Colors.red),
                              ),
                            ],
                          ),
                        ),
                      ],
                      icon: Icon(Icons.more_vert, color: Colors.grey.shade400),
                    ),
                  ],
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
    final controllers = _contactControllersPerCategory[category];

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
              onEdit: () => _editContactInfo(category, 'address', 'Address'),
            ),
            const SizedBox(height: 12),
          ],
          if ((contact['hours'] ?? '').isNotEmpty) ...[
            _buildContactRow(
              Icons.access_time,
              'Office Hours',
              contact['hours']!,
              onEdit: () => _editContactInfo(category, 'hours', 'Office Hours'),
            ),
            const SizedBox(height: 12),
          ],
          if ((contact['contacts'] ?? '').isNotEmpty) ...[
            _buildContactRow(
              Icons.phone_outlined,
              'Contact',
              contact['contacts']!,
              onEdit: () =>
                  _editContactInfo(category, 'contacts', 'Contact Numbers'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildContactRow(
    IconData icon,
    String label,
    String value, {
    VoidCallback? onEdit,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.blue.shade400),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade800,
                    ),
                  ),
                  const Spacer(),
                  if (onEdit != null)
                    IconButton(
                      onPressed: onEdit,
                      icon: Icon(
                        Icons.edit,
                        size: 16,
                        color: Colors.blue.shade600,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                ],
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
        currentIndex: 3,
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
                    // Search Bar
                    _buildSearchBar(),
                    const SizedBox(height: 24),

                    // Hero Banner
                    _buildBanner(),

                    // Section Title with Add Button
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Barangay Officials",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          IconButton(
                            onPressed: _showAddOfficialDialog,
                            icon: const Icon(Icons.add, size: 24),
                            color: Colors.blue,
                            tooltip: 'Add Official',
                          ),
                        ],
                      ),
                    ),

                    // Officials List
                    if (_filteredOfficials.isEmpty &&
                        _searchController.text.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.people_outline,
                              size: 40,
                              color: Colors.grey.shade300,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              "No officials added yet",
                              style: TextStyle(
                                color: Colors.grey.shade500,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Tap + to add new officials",
                              style: TextStyle(
                                color: Colors.grey.shade400,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      )
                    else if (_filteredOfficials.isEmpty &&
                        _searchController.text.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 20),
                        child: Center(
                          child: Text(
                            "No matching officials found",
                            style: TextStyle(color: Colors.grey[500]),
                          ),
                        ),
                      )
                    else
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
                            ...List.generate(
                              entry.value.length,
                              (index) => _buildOfficialCard(entry.key, index),
                            ),
                            _buildContactInfoCard(entry.key),
                          ],
                        );
                      }),

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
  }
}

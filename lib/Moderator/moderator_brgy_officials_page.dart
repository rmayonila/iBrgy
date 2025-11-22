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
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();
  final Map<String, List<TextEditingController>> _nameControllers = {};
  final Map<String, List<bool>> _isEditing = {};
  final Map<String, List<FocusNode>> _focusNodes = {};
  Map<String, dynamic>? _lastDeleted; // holds last deleted item's info for undo
  // Per-category contact controllers (address / hours / contacts)
  final Map<String, Map<String, TextEditingController>>
  _contactControllersPerCategory = {};
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Officials data (start empty — add entries via the + button)
  Map<String, List<Map<String, String>>> officials = {};
  void _onItemTapped(int index) {
    navigateModeratorIndex(
      context,
      index,
      currentIndex: _selectedIndex,
      onSamePage: (i) => setState(() => _selectedIndex = i),
    );
  }

  void _showAddOfficialDialog() {
    final titleController = TextEditingController();
    final nameController = TextEditingController();
    final categoryController = TextEditingController();
    // controllers for contact-info mode
    final addressController = TextEditingController();
    final hoursController = TextEditingController();
    final phoneController = TextEditingController();

    // Reusable decoration for consistent look
    InputDecoration buildInputDecoration({
      required String label,
      required String hint,
      required IconData icon,
    }) {
      return InputDecoration(
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
      );
    }

    showDialog(
      context: context,
      builder: (context) {
        var isContactMode = false;
        return StatefulBuilder(
          builder: (ctx, setStateDialog) {
            return AlertDialog(
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
              actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.person_add_alt_1_rounded,
                      color: Colors.blue.shade700,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Text(
                      'Add Official',
                      style: TextStyle(
                        color: Colors.black87,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: categoryController,
                      style: const TextStyle(color: Colors.black87),
                      decoration:
                          buildInputDecoration(
                            label: 'Category',
                            hint: 'e.g., EXECUTIVE OFFICERS',
                            icon: Icons.category_outlined,
                          ).copyWith(
                            // Use suffixIcon so the toggle is vertically centered
                            suffixIcon: GestureDetector(
                              onTap: () => setStateDialog(
                                () => isContactMode = !isContactMode,
                              ),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: 46,
                                height: 26,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: isContactMode
                                      ? const Color(0xFF2F3438)
                                      : Colors.grey.shade300,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isContactMode
                                        ? Colors.grey.shade600
                                        : Colors.grey.shade500,
                                  ),
                                ),
                                child: Stack(
                                  children: [
                                    AnimatedAlign(
                                      duration: const Duration(
                                        milliseconds: 200,
                                      ),
                                      alignment: isContactMode
                                          ? Alignment.centerRight
                                          : Alignment.centerLeft,
                                      curve: Curves.easeInOut,
                                      child: Container(
                                        width: 18,
                                        height: 18,
                                        decoration: BoxDecoration(
                                          color: isContactMode
                                              ? const Color(0xFFBFC6CC)
                                              : Colors.white,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            suffixIconConstraints: const BoxConstraints(
                              minWidth: 45,
                              minHeight: 26,
                            ),
                          ),
                    ),
                    const SizedBox(height: 12),
                    if (!isContactMode) ...[
                      TextField(
                        controller: titleController,
                        style: const TextStyle(color: Colors.black87),
                        decoration: buildInputDecoration(
                          label: 'Position Title',
                          hint: 'e.g., BRGY CAPTAIN',
                          icon: Icons.work_outline_rounded,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: nameController,
                        style: const TextStyle(color: Colors.black87),
                        decoration: buildInputDecoration(
                          label: 'Full Name',
                          hint: 'e.g., JUAN DELA CRUZ',
                          icon: Icons.person_outline_rounded,
                        ),
                      ),
                    ] else ...[
                      TextField(
                        controller: addressController,
                        style: const TextStyle(color: Colors.black87),
                        decoration: buildInputDecoration(
                          label: 'Office Address',
                          hint: 'e.g., 123 Barangay St.',
                          icon: Icons.location_on_outlined,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: hoursController,
                        style: const TextStyle(color: Colors.black87),
                        decoration: buildInputDecoration(
                          label: 'Office Hours',
                          hint: 'e.g., 8:00 AM - 5:00 PM',
                          icon: Icons.access_time_outlined,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: phoneController,
                        style: const TextStyle(color: Colors.black87),
                        decoration: buildInputDecoration(
                          label: 'Office Phone Number',
                          hint: 'e.g., (02) 1234-5678',
                          icon: Icons.phone_outlined,
                        ),
                        keyboardType: TextInputType.phone,
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    // dispose temporary controllers
                    titleController.dispose();
                    nameController.dispose();
                    categoryController.dispose();
                    addressController.dispose();
                    hoursController.dispose();
                    phoneController.dispose();
                    Navigator.of(ctx).pop();
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey.shade700,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () async {
                    final category = categoryController.text.trim();

                    if (category.isEmpty) {
                      _scaffoldMessengerKey.currentState?.showSnackBar(
                        const SnackBar(
                          content: Text('Please enter a category'),
                          backgroundColor: Colors.redAccent,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                      return;
                    }

                    if (!isContactMode) {
                      final title = titleController.text.trim();
                      final name = nameController.text.trim();
                      if (title.isEmpty || name.isEmpty) {
                        _scaffoldMessengerKey.currentState?.showSnackBar(
                          const SnackBar(
                            content: Text('Please fill all fields'),
                            backgroundColor: Colors.redAccent,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                        return;
                      }

                      try {
                        final navigator = Navigator.of(ctx);
                        final docRef = await _db.collection('officials').add({
                          'category': category,
                          'title': title,
                          'name': name,
                          'createdAt': FieldValue.serverTimestamp(),
                        });
                        if (!mounted) return;
                        setState(() {
                          if (!officials.containsKey(category)) {
                            officials[category] = [];
                          }
                          officials[category]!.add({
                            'id': docRef.id,
                            'title': title,
                            'name': name,
                          });

                          // Keep controller list in sync
                          if (!_nameControllers.containsKey(category)) {
                            _nameControllers[category] = [
                              TextEditingController(text: name),
                            ];
                            _isEditing[category] = [false];
                            _focusNodes[category] = [FocusNode()];
                          } else {
                            _nameControllers[category]!.add(
                              TextEditingController(text: name),
                            );
                            _isEditing[category]!.add(false);

                            if (!_focusNodes.containsKey(category)) {
                              _focusNodes[category] = [];
                            }
                            while (_focusNodes[category]!.length <
                                _nameControllers[category]!.length - 1) {
                              _focusNodes[category]!.add(FocusNode());
                            }
                            _focusNodes[category]!.add(FocusNode());
                          }
                        });

                        navigator.pop();

                        // dispose temp controllers
                        titleController.dispose();
                        nameController.dispose();
                        categoryController.dispose();
                        addressController.dispose();
                        hoursController.dispose();
                        phoneController.dispose();

                        _scaffoldMessengerKey.currentState?.showSnackBar(
                          SnackBar(
                            content: const Text('Official added successfully'),
                            backgroundColor: Colors.green.shade600,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      } catch (e) {
                        _scaffoldMessengerKey.currentState?.showSnackBar(
                          SnackBar(content: Text('Failed to add official: $e')),
                        );
                      }
                    } else {
                      // contact mode: save contact info into per-category controllers
                      final a = addressController.text.trim();
                      final h = hoursController.text.trim();
                      final p = phoneController.text.trim();
                      setState(() {
                        if (!officials.containsKey(category)) {
                          officials[category] = [];
                        }

                        // Only create or update controllers if at least one field is non-empty
                        if (a.isNotEmpty || h.isNotEmpty || p.isNotEmpty) {
                          if (!_contactControllersPerCategory.containsKey(
                            category,
                          )) {
                            _contactControllersPerCategory[category] = {
                              'address': TextEditingController(text: a),
                              'hours': TextEditingController(text: h),
                              'contacts': TextEditingController(text: p),
                            };
                          } else {
                            final ctrls =
                                _contactControllersPerCategory[category]!;
                            ctrls['address']!.text = a;
                            ctrls['hours']!.text = h;
                            ctrls['contacts']!.text = p;
                          }
                        }
                      });

                      final navigator = Navigator.of(ctx);
                      try {
                        // persist contact info keyed by category so it can be
                        // updated later via the same doc id (category as doc)
                        await _db
                            .collection('official_contacts')
                            .doc(category)
                            .set({
                              'address': a,
                              'hours': h,
                              'contacts': p,
                              'updatedAt': FieldValue.serverTimestamp(),
                            });
                      } catch (e) {
                        _scaffoldMessengerKey.currentState?.showSnackBar(
                          SnackBar(
                            content: Text('Failed to save contacts: $e'),
                          ),
                        );
                      }

                      navigator.pop();

                      // dispose temp controllers
                      titleController.dispose();
                      nameController.dispose();
                      categoryController.dispose();
                      addressController.dispose();
                      hoursController.dispose();
                      phoneController.dispose();

                      _scaffoldMessengerKey.currentState?.showSnackBar(
                        SnackBar(
                          content: const Text('Contact information saved'),
                          backgroundColor: Colors.green.shade600,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade700,
                    foregroundColor: Colors.white,
                    elevation: 2,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: const StadiumBorder(),
                  ),
                  icon: const Icon(Icons.check_rounded, size: 20),
                  label: const Text(
                    'Add',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showEditCategoryFieldDialog(
    String category,
    String fieldKey,
    String fieldLabel,
  ) async {
    final controllers = _contactControllersPerCategory[category];
    if (controllers == null) return;
    final currentController = controllers[fieldKey]!;

    final inputController = TextEditingController(text: currentController.text);

    final result = await showDialog<String>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text('Edit $fieldLabel'),
          content: TextField(
            controller: inputController,
            decoration: InputDecoration(hintText: 'Enter $fieldLabel'),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(null),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () =>
                  Navigator.of(ctx).pop(inputController.text.trim()),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (result != null) {
      setState(() {
        currentController.text = result;
      });
      try {
        await _db.collection('official_contacts').doc(category).update({
          fieldKey: result,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } catch (e) {
        // If update fails (e.g., doc doesn't exist), attempt to set it.
        await _db.collection('official_contacts').doc(category).set({
          fieldKey: result,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
      _scaffoldMessengerKey.currentState?.showSnackBar(
        const SnackBar(content: Text('Saved')),
      );
    }
  }

  Widget _buildOfficialFieldEditable(String category, int index) {
    final official = officials[category]![index];
    // ensure controller exists
    if (!_nameControllers.containsKey(category)) {
      _nameControllers[category] = officials[category]!
          .map((e) => TextEditingController(text: e['name']))
          .toList();
    }
    if (!_isEditing.containsKey(category)) {
      _isEditing[category] = List.generate(
        officials[category]!.length,
        (_) => false,
      );
    }
    final controller = _nameControllers[category]![index];
    final isEditing = _isEditing[category]![index];
    final focusNode = _focusNodes[category]![index];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                official['title'] ?? '',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color.fromARGB(221, 5, 5, 5),
                ),
              ),
            ),
            PopupMenuButton<String>(
              padding: EdgeInsets.zero,
              color: Colors.white,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.more_horiz,
                  color: Color.fromARGB(255, 132, 129, 129),
                ),
              ),
              onSelected: (value) async {
                if (value == 'edit') {
                  if (isEditing) {
                    final newName = controller.text.trim();
                    setState(() {
                      officials[category]![index]['name'] = newName;
                      _isEditing[category]![index] = false;
                    });
                    // update Firestore if this official has an id
                    final id = officials[category]![index]['id'];
                    if (id != null) {
                      try {
                        await _db.collection('officials').doc(id).update({
                          'name': newName,
                        });
                      } catch (e) {
                        _scaffoldMessengerKey.currentState?.showSnackBar(
                          SnackBar(content: Text('Failed to update: $e')),
                        );
                      }
                    }
                    _scaffoldMessengerKey.currentState?.showSnackBar(
                      const SnackBar(content: Text('Saved')),
                    );
                  } else {
                    setState(() {
                      _isEditing[category]![index] = true;
                    });
                    Future.delayed(const Duration(milliseconds: 80), () {
                      focusNode.requestFocus();
                    });
                  }
                } else if (value == 'delete') {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (c) => AlertDialog(
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      title: const Text(
                        'Delete Official',
                        style: TextStyle(color: Colors.black),
                      ),
                      content: const Text(
                        'Are you sure you want to delete this official?',
                        style: TextStyle(color: Colors.black),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(c).pop(false),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(
                              color: Color.fromARGB(255, 54, 168, 244),
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(c).pop(true),
                          child: const Text(
                            'Delete',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    final previousName = controller.text;
                    _lastDeleted = {
                      'category': category,
                      'index': index,
                      'previousName': previousName,
                    };
                    setState(() {
                      controller.clear();
                      officials[category]![index]['name'] = '';
                      if (_isEditing.containsKey(category) &&
                          _isEditing[category]!.length > index) {
                        _isEditing[category]![index] = false;
                      }
                    });

                    // Update Firestore if this official has an id
                    final id = officials[category]![index]['id'];
                    if (id != null) {
                      try {
                        await _db.collection('officials').doc(id).update({
                          'name': '',
                        });
                      } catch (e) {
                        // ignore failures for now but show feedback
                        _scaffoldMessengerKey.currentState?.showSnackBar(
                          SnackBar(
                            content: Text('Failed to update remote: $e'),
                          ),
                        );
                      }
                    }

                    _scaffoldMessengerKey.currentState?.showSnackBar(
                      SnackBar(
                        content: const Text('Name cleared'),
                        action: SnackBarAction(
                          label: 'Undo',
                          onPressed: () {
                            final info = _lastDeleted;
                            if (info == null) return;
                            final cat = info['category'] as String;
                            final idx = info['index'] as int;
                            final prev = info['previousName'] as String;
                            setState(() {
                              if (officials.containsKey(cat) &&
                                  officials[cat]!.length > idx) {
                                officials[cat]![idx]['name'] = prev;
                                _nameControllers[cat]![idx].text = prev;
                              }
                            });
                            _lastDeleted = null;
                          },
                        ),
                      ),
                    );
                  }
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'edit',
                  child: Text(
                    isEditing ? 'Save' : 'Edit',
                    style: const TextStyle(color: Colors.black),
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Text('Delete', style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: isEditing ? Colors.blue : Colors.grey.shade300,
                    width: isEditing ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  readOnly: !isEditing,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Name',
                  ),
                  style: const TextStyle(fontSize: 16, color: Colors.black),
                  onChanged: (val) {
                    officials[category]![index]['name'] = val;
                  },
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  @override
  void initState() {
    super.initState();
    _loadOfficialsAndContacts();
  }

  Future<void> _loadOfficialsAndContacts() async {
    try {
      // load officials
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

      // load contact docs
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
        officials = loaded;
        // initialize controllers from loaded officials
        for (var entry in officials.entries) {
          _nameControllers[entry.key] = entry.value
              .map((e) => TextEditingController(text: e['name']))
              .toList();
          _isEditing[entry.key] = List.generate(
            entry.value.length,
            (_) => false,
          );
          _focusNodes[entry.key] = List.generate(
            entry.value.length,
            (_) => FocusNode(),
          );
        }

        // initialize contact controllers
        _contactControllersPerCategory.clear();
        for (var e in contacts.entries) {
          _contactControllersPerCategory[e.key] = {
            'address': TextEditingController(text: e.value['address']),
            'hours': TextEditingController(text: e.value['hours']),
            'contacts': TextEditingController(text: e.value['contacts']),
          };
        }
      });
    } catch (e) {
      // ignore load errors
    }
  }

  @override
  void dispose() {
    for (var list in _nameControllers.values) {
      for (var c in list) {
        c.dispose();
      }
    }
    for (var list in _focusNodes.values) {
      for (var f in list) {
        f.dispose();
      }
    }
    // dispose per-category contact controllers
    for (var map in _contactControllersPerCategory.values) {
      for (var c in map.values) {
        c.dispose();
      }
    }
    // Contact controllers removed (contact section deleted)
    super.dispose();
  }

  bool _hasContactInfo(String category) {
    final ctrls = _contactControllersPerCategory[category];
    if (ctrls == null) return false;
    return (ctrls['address']?.text.trim().isNotEmpty ?? false) ||
        (ctrls['hours']?.text.trim().isNotEmpty ?? false) ||
        (ctrls['contacts']?.text.trim().isNotEmpty ?? false);
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldMessenger(
      key: _scaffoldMessengerKey,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              // Header with iBrgy logo and ADD BRGY OFFICIALS button
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 5,
                      ),

                      child: RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: 'iB',
                              style: TextStyle(
                                fontSize: 25,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                            TextSpan(
                              text: 'rgy',
                              style: TextStyle(
                                fontSize: 25,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Add',
                      onPressed: _showAddOfficialDialog,
                      icon: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.add, color: Colors.blue),
                      ),
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Build sections dynamically
                      for (var entry in officials.entries)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              entry.key,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                            const SizedBox(height: 16),
                            for (int i = 0; i < entry.value.length; i++)
                              _buildOfficialFieldEditable(entry.key, i),

                            // Per-category Contact Information card (matches requested UI)
                            if (_hasContactInfo(entry.key))
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: Colors.grey.shade300,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                    color: Colors.white,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Padding(
                                        padding: EdgeInsets.only(
                                          left: 4.0,
                                          bottom: 8.0,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Builder(
                                        builder: (ctx) {
                                          final ctrls =
                                              _contactControllersPerCategory[entry
                                                  .key]!;
                                          return Column(
                                            children: [
                                              // Office Address (label above value)
                                              Row(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  const Icon(
                                                    Icons.location_on,
                                                    color: Colors.blue,
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        const Text(
                                                          'Office Address',
                                                          style: TextStyle(
                                                            fontSize: 14,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                            color:
                                                                Colors.black87,
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                          height: 6,
                                                        ),
                                                        ctrls['address']!
                                                                .text
                                                                .isEmpty
                                                            ? const SizedBox.shrink()
                                                            : Text(
                                                                ctrls['address']!
                                                                    .text,
                                                                style: const TextStyle(
                                                                  fontSize: 14,
                                                                  color: Colors
                                                                      .black87,
                                                                ),
                                                              ),
                                                      ],
                                                    ),
                                                  ),
                                                  PopupMenuButton<String>(
                                                    padding: EdgeInsets.zero,
                                                    color: Colors.white,
                                                    child: Container(
                                                      width: 36,
                                                      height: 36,
                                                      decoration: BoxDecoration(
                                                        color:
                                                            Colors.transparent,
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              8,
                                                            ),
                                                      ),
                                                      child: const Icon(
                                                        Icons.more_horiz,
                                                        color: Colors.black,
                                                      ),
                                                    ),
                                                    onSelected: (value) async {
                                                      if (value == 'edit') {
                                                        await _showEditCategoryFieldDialog(
                                                          entry.key,
                                                          'address',
                                                          'Office Address',
                                                        );
                                                      } else if (value ==
                                                          'delete') {
                                                        final prev =
                                                            ctrls['address']!
                                                                .text;
                                                        setState(() {
                                                          ctrls['address']!
                                                                  .text =
                                                              '';
                                                        });
                                                        _scaffoldMessengerKey
                                                            .currentState
                                                            ?.showSnackBar(
                                                              SnackBar(
                                                                content: const Text(
                                                                  'Address cleared',
                                                                ),
                                                                action: SnackBarAction(
                                                                  label: 'Undo',
                                                                  onPressed: () {
                                                                    setState(() {
                                                                      ctrls['address']!
                                                                              .text =
                                                                          prev;
                                                                    });
                                                                  },
                                                                ),
                                                              ),
                                                            );
                                                      }
                                                    },
                                                    itemBuilder: (context) => [
                                                      PopupMenuItem(
                                                        value: 'edit',
                                                        child: Text(
                                                          'Edit',
                                                          style:
                                                              const TextStyle(
                                                                color: Colors
                                                                    .black,
                                                              ),
                                                        ),
                                                      ),
                                                      const PopupMenuItem(
                                                        value: 'delete',
                                                        child: Text(
                                                          'Delete',
                                                          style: TextStyle(
                                                            color: Colors.red,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 12),

                                              // Office Hours
                                              Row(
                                                children: [
                                                  const Icon(
                                                    Icons.access_time,
                                                    color: Colors.blue,
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        const Text(
                                                          'Office Hours',
                                                          style: TextStyle(
                                                            fontSize: 14,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                            color:
                                                                Colors.black87,
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                          height: 6,
                                                        ),
                                                        ctrls['hours']!
                                                                .text
                                                                .isEmpty
                                                            ? const SizedBox.shrink()
                                                            : Text(
                                                                ctrls['hours']!
                                                                    .text,
                                                                style: const TextStyle(
                                                                  fontSize: 14,
                                                                  color: Colors
                                                                      .black87,
                                                                ),
                                                              ),
                                                      ],
                                                    ),
                                                  ),
                                                  PopupMenuButton<String>(
                                                    padding: EdgeInsets.zero,
                                                    color: Colors.white,
                                                    child: Container(
                                                      width: 36,
                                                      height: 36,
                                                      decoration: BoxDecoration(
                                                        color:
                                                            Colors.transparent,
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              8,
                                                            ),
                                                      ),
                                                      child: const Icon(
                                                        Icons.more_horiz,
                                                        color: Colors.black,
                                                      ),
                                                    ),
                                                    onSelected: (value) async {
                                                      if (value == 'edit') {
                                                        await _showEditCategoryFieldDialog(
                                                          entry.key,
                                                          'hours',
                                                          'Office Hours',
                                                        );
                                                      } else if (value ==
                                                          'delete') {
                                                        final prev =
                                                            ctrls['hours']!
                                                                .text;
                                                        setState(() {
                                                          ctrls['hours']!.text =
                                                              '';
                                                        });
                                                        _scaffoldMessengerKey
                                                            .currentState
                                                            ?.showSnackBar(
                                                              SnackBar(
                                                                content: const Text(
                                                                  'Office hours cleared',
                                                                ),
                                                                action: SnackBarAction(
                                                                  label: 'Undo',
                                                                  onPressed: () {
                                                                    setState(() {
                                                                      ctrls['hours']!
                                                                              .text =
                                                                          prev;
                                                                    });
                                                                  },
                                                                ),
                                                              ),
                                                            );
                                                      }
                                                    },
                                                    itemBuilder: (context) => [
                                                      PopupMenuItem(
                                                        value: 'edit',
                                                        child: Text(
                                                          'Edit',
                                                          style:
                                                              const TextStyle(
                                                                color: Colors
                                                                    .black,
                                                              ),
                                                        ),
                                                      ),
                                                      const PopupMenuItem(
                                                        value: 'delete',
                                                        child: Text(
                                                          'Delete',
                                                          style: TextStyle(
                                                            color: Colors.red,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 12),

                                              // Contact Numbers
                                              Row(
                                                children: [
                                                  const Icon(
                                                    Icons.phone,
                                                    color: Colors.blue,
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        const Text(
                                                          'Office Telephone Number',
                                                          style: TextStyle(
                                                            fontSize: 14,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                            color:
                                                                Colors.black87,
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                          height: 6,
                                                        ),
                                                        ctrls['contacts']!
                                                                .text
                                                                .isEmpty
                                                            ? const SizedBox.shrink()
                                                            : Text(
                                                                ctrls['contacts']!
                                                                    .text,
                                                                style: const TextStyle(
                                                                  fontSize: 14,
                                                                  color: Colors
                                                                      .black87,
                                                                ),
                                                              ),
                                                      ],
                                                    ),
                                                  ),
                                                  PopupMenuButton<String>(
                                                    padding: EdgeInsets.zero,
                                                    color: Colors.white,
                                                    child: Container(
                                                      width: 36,
                                                      height: 36,
                                                      decoration: BoxDecoration(
                                                        color:
                                                            Colors.transparent,
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              8,
                                                            ),
                                                      ),
                                                      child: const Icon(
                                                        Icons.more_horiz,
                                                        color: Colors.black,
                                                      ),
                                                    ),
                                                    onSelected: (value) async {
                                                      if (value == 'edit') {
                                                        await _showEditCategoryFieldDialog(
                                                          entry.key,
                                                          'contacts',
                                                          'Contact Numbers',
                                                        );
                                                      } else if (value ==
                                                          'delete') {
                                                        final prev =
                                                            ctrls['contacts']!
                                                                .text;
                                                        setState(() {
                                                          ctrls['contacts']!
                                                                  .text =
                                                              '';
                                                        });
                                                        _scaffoldMessengerKey
                                                            .currentState
                                                            ?.showSnackBar(
                                                              SnackBar(
                                                                content: const Text(
                                                                  'Contact numbers cleared',
                                                                ),
                                                                action: SnackBarAction(
                                                                  label: 'Undo',
                                                                  onPressed: () {
                                                                    setState(() {
                                                                      ctrls['contacts']!
                                                                              .text =
                                                                          prev;
                                                                    });
                                                                  },
                                                                ),
                                                              ),
                                                            );
                                                      }
                                                    },
                                                    itemBuilder: (context) => [
                                                      PopupMenuItem(
                                                        value: 'edit',
                                                        child: Text(
                                                          'Edit',
                                                          style:
                                                              const TextStyle(
                                                                color: Colors
                                                                    .black,
                                                              ),
                                                        ),
                                                      ),
                                                      const PopupMenuItem(
                                                        value: 'delete',
                                                        child: Text(
                                                          'Delete',
                                                          style: TextStyle(
                                                            color: Colors.red,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ],
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                            const SizedBox(height: 24),
                          ],
                        ),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedIndex,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: Colors.blue,
          unselectedItemColor: Colors.grey,
          backgroundColor: Colors.white,
          showSelectedLabels: true,
          elevation: 8,
          onTap: _onItemTapped,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
            BottomNavigationBarItem(
              icon: Icon(Icons.phone),
              label: 'Emergency',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.announcement, size: 30),
              label: 'Updates',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.people, color: Colors.blue),
              label: 'People',
            ),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          ],
        ),
      ),
    );
  }
}

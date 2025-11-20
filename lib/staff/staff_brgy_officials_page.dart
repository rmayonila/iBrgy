import 'package:flutter/material.dart';

class StaffBrgyOfficialsPage extends StatefulWidget {
  const StaffBrgyOfficialsPage({super.key});

  @override
  State<StaffBrgyOfficialsPage> createState() => _StaffBrgyOfficialsPageState();
}

class _StaffBrgyOfficialsPageState extends State<StaffBrgyOfficialsPage> {
  int _selectedIndex = 3; // People tab
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();
  final Map<String, List<TextEditingController>> _nameControllers = {};
  final Map<String, List<bool>> _isEditing = {};
  final Map<String, List<FocusNode>> _focusNodes = {};
  Map<String, dynamic>? _lastDeleted; // holds last deleted item's info for undo
  late TextEditingController _addressController;
  late TextEditingController _hoursController;
  late TextEditingController _contactNumbersController;
  bool _isEditingAddress = false;
  bool _isEditingHours = false;
  bool _isEditingContacts = false;

  // Sample officials data
  Map<String, List<Map<String, String>>> officials = {
    'EXECUTIVE OFFICERS': [
      {'title': 'BRGY CAPTAIN', 'name': ''},
      {'title': 'BRGY SECRETARY', 'name': ''},
      {'title': 'BRGY TREASURER', 'name': ''},
    ],
    'KAGAWAD (COUNCILORS)': [
      {'title': 'Committee on Peace & Order', 'name': ''},
      {'title': 'Committee on Health & Sanitation', 'name': ''},
      {'title': 'Committee on Education', 'name': ''},
      {'title': 'Committee on Infrastructure', 'name': ''},
      {'title': 'Committee on Youth & Sports', 'name': ''},
      {'title': 'Committee on Environment', 'name': ''},
      {'title': 'Committee on Budget & Finance', 'name': ''},
    ],
    'MANDATORY POSITIONS': [
      {'title': 'SK CHAIRMAN', 'name': ''},
      {'title': 'BRGY CLERK', 'name': ''},
    ],
  };
  void _onItemTapped(int index) {
    if (index == 0) {
      Navigator.pushReplacementNamed(context, '/staff-home');
    } else if (index == 1) {
      Navigator.pushReplacementNamed(context, '/staff-emergency-hotline');
    } else if (index == 2) {
      Navigator.pushReplacementNamed(context, '/staff-announcement');
    } else if (index == 4) {
      // Profile -> Staff Account Settings
      Navigator.pushReplacementNamed(context, '/staff-account-settings');
    } else {
      setState(() => _selectedIndex = index);
    }
  }

  void _showAddOfficialDialog() {
    final titleController = TextEditingController();
    final nameController = TextEditingController();
    final categoryController = TextEditingController();

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
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white, // Ensures it stays white on Material 3
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
                decoration: buildInputDecoration(
                  label: 'Category',
                  hint: 'e.g., EXECUTIVE OFFICERS',
                  icon: Icons.category_outlined,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: titleController,
                style: const TextStyle(color: Colors.black87),
                decoration: buildInputDecoration(
                  label: 'Position Title',
                  hint: 'e.g., BRGY CAPTAIN',
                  icon: Icons.work_outline_rounded,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameController,
                style: const TextStyle(color: Colors.black87),
                decoration: buildInputDecoration(
                  label: 'Full Name',
                  hint: 'e.g., JUAN DELA CRUZ',
                  icon: Icons.person_outline_rounded,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey.shade700,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            child: const Text(
              'Cancel',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {
              final category = categoryController.text.trim();
              final title = titleController.text.trim();
              final name = nameController.text.trim();

              if (category.isEmpty || title.isEmpty || name.isEmpty) {
                _scaffoldMessengerKey.currentState?.showSnackBar(
                  const SnackBar(
                    content: Text('Please fill all fields'),
                    backgroundColor: Colors.redAccent,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
                return;
              }

              setState(() {
                if (!officials.containsKey(category)) {
                  officials[category] = [];
                }
                officials[category]!.add({'title': title, 'name': name});

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

                  // Safely add focus node
                  if (!_focusNodes.containsKey(category)) {
                    _focusNodes[category] = [];
                  }
                  // Ensure the list is long enough before adding the new one
                  while (_focusNodes[category]!.length <
                      _nameControllers[category]!.length - 1) {
                    _focusNodes[category]!.add(FocusNode());
                  }
                  _focusNodes[category]!.add(FocusNode());
                }
              });

              Navigator.of(context).pop();

              _scaffoldMessengerKey.currentState?.showSnackBar(
                SnackBar(
                  content: const Text('Official added successfully'),
                  backgroundColor: Colors.green.shade600,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade700,
              foregroundColor: Colors.white,
              elevation: 2,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: const StadiumBorder(), // Rounded button
            ),
            icon: const Icon(Icons.check_rounded, size: 20),
            label: const Text(
              'Add Official',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        ],
      ),
    );
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
                  setState(() {
                    if (isEditing) {
                      officials[category]![index]['name'] = controller.text
                          .trim();
                      _isEditing[category]![index] = false;
                      _scaffoldMessengerKey.currentState?.showSnackBar(
                        const SnackBar(content: Text('Saved')),
                      );
                    } else {
                      _isEditing[category]![index] = true;
                      Future.delayed(const Duration(milliseconds: 80), () {
                        focusNode.requestFocus();
                      });
                    }
                  });
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
    // initialize controllers from officials map
    for (var entry in officials.entries) {
      _nameControllers[entry.key] = entry.value
          .map((e) => TextEditingController(text: e['name']))
          .toList();
      _isEditing[entry.key] = List.generate(entry.value.length, (_) => false);
      _focusNodes[entry.key] = List.generate(
        entry.value.length,
        (_) => FocusNode(),
      );
    }
    // initialize contact info controllers with current defaults
    _addressController = TextEditingController(text: '');
    _hoursController = TextEditingController(text: '');
    _contactNumbersController = TextEditingController(text: '');
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
    _addressController.dispose();
    _hoursController.dispose();
    _contactNumbersController.dispose();
    super.dispose();
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
                      tooltip: 'Add Official',
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
                            const SizedBox(height: 24),
                          ],
                        ),

                      // Contact Information
                      const Text(
                        'CONTACT INFORMATION',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.location_on,
                                  color: Colors.blue,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: const Text(
                                    'Office Address',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: Color.fromARGB(255, 33, 32, 32),
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
                                      color: Colors.transparent,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.more_horiz,
                                      color: Colors.black,
                                    ),
                                  ),
                                  onSelected: (value) async {
                                    if (value == 'edit') {
                                      setState(() {
                                        if (_isEditingAddress) {
                                          _isEditingAddress = false;
                                          _scaffoldMessengerKey.currentState
                                              ?.showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                    'Address saved',
                                                  ),
                                                ),
                                              );
                                        } else {
                                          _isEditingAddress = true;
                                        }
                                      });
                                    } else if (value == 'delete') {
                                      final confirm = await showDialog<bool>(
                                        context: context,
                                        builder: (c) => AlertDialog(
                                          backgroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          title: const Text(
                                            'Delete Address',
                                            style: TextStyle(
                                              color: Colors.black,
                                            ),
                                          ),
                                          content: const Text(
                                            'Are you sure you want to delete the address?',
                                            style: TextStyle(
                                              color: Colors.black,
                                            ),
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.of(c).pop(false),
                                              child: const Text(
                                                'Cancel',
                                                style: TextStyle(
                                                  color: Color.fromARGB(
                                                    255,
                                                    54,
                                                    168,
                                                    244,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.of(c).pop(true),
                                              child: const Text(
                                                'Delete',
                                                style: TextStyle(
                                                  color: Colors.red,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                      if (confirm == true) {
                                        final prev = _addressController.text;
                                        _lastDeleted = {
                                          'field': 'address',
                                          'previousText': prev,
                                        };
                                        setState(() {
                                          _addressController.clear();
                                          _isEditingAddress = false;
                                        });
                                        _scaffoldMessengerKey.currentState
                                            ?.showSnackBar(
                                              SnackBar(
                                                content: const Text(
                                                  'Address cleared',
                                                ),
                                                action: SnackBarAction(
                                                  label: 'Undo',
                                                  onPressed: () {
                                                    final info = _lastDeleted;
                                                    if (info == null) return;
                                                    if (info['field'] ==
                                                        'address') {
                                                      final prevText =
                                                          info['previousText']
                                                              as String;
                                                      setState(() {
                                                        _addressController
                                                                .text =
                                                            prevText;
                                                      });
                                                    }
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
                                        _isEditingAddress ? 'Save' : 'Edit',
                                        style: const TextStyle(
                                          color: Colors.black,
                                        ),
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 'delete',
                                      child: Text(
                                        'Delete',
                                        style: TextStyle(color: Colors.red),
                                      ),
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
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: TextField(
                                      controller: _addressController,
                                      readOnly: !_isEditingAddress,
                                      decoration: const InputDecoration(
                                        border: InputBorder.none,
                                        isCollapsed: true,
                                      ),
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[800],
                                      ),
                                      maxLines: 2,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                const Icon(
                                  Icons.access_time,
                                  color: Colors.blue,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: const Text(
                                    'Office Hours',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: Color.fromARGB(255, 33, 32, 32),
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
                                      color: Colors.transparent,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.more_horiz,
                                      color: Colors.black,
                                    ),
                                  ),
                                  onSelected: (value) async {
                                    if (value == 'edit') {
                                      setState(() {
                                        if (_isEditingHours) {
                                          _isEditingHours = false;
                                          _scaffoldMessengerKey.currentState
                                              ?.showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                    'Office hours saved',
                                                  ),
                                                ),
                                              );
                                        } else {
                                          _isEditingHours = true;
                                        }
                                      });
                                    } else if (value == 'delete') {
                                      final confirm = await showDialog<bool>(
                                        context: context,
                                        builder: (c) => AlertDialog(
                                          backgroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          title: const Text(
                                            'Delete Office Hours',
                                            style: TextStyle(
                                              color: Colors.black,
                                            ),
                                          ),
                                          content: const Text(
                                            'Are you sure you want to delete the office hours?',
                                            style: TextStyle(
                                              color: Colors.black,
                                            ),
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.of(c).pop(false),
                                              child: const Text(
                                                'Cancel',
                                                style: TextStyle(
                                                  color: Color.fromARGB(
                                                    255,
                                                    54,
                                                    168,
                                                    244,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.of(c).pop(true),
                                              child: const Text(
                                                'Delete',
                                                style: TextStyle(
                                                  color: Colors.red,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                      if (confirm == true) {
                                        final prev = _hoursController.text;
                                        _lastDeleted = {
                                          'field': 'hours',
                                          'previousText': prev,
                                        };
                                        setState(() {
                                          _hoursController.clear();
                                          _isEditingHours = false;
                                        });
                                        _scaffoldMessengerKey.currentState
                                            ?.showSnackBar(
                                              SnackBar(
                                                content: const Text(
                                                  'Office hours cleared',
                                                ),
                                                action: SnackBarAction(
                                                  label: 'Undo',
                                                  onPressed: () {
                                                    final info = _lastDeleted;
                                                    if (info == null) return;
                                                    if (info['field'] ==
                                                        'hours') {
                                                      final prevText =
                                                          info['previousText']
                                                              as String;
                                                      setState(() {
                                                        _hoursController.text =
                                                            prevText;
                                                      });
                                                    }
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
                                        _isEditingHours ? 'Save' : 'Edit',
                                        style: const TextStyle(
                                          color: Colors.black,
                                        ),
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 'delete',
                                      child: Text(
                                        'Delete',
                                        style: TextStyle(color: Colors.red),
                                      ),
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
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                    ),
                                    child: TextField(
                                      controller: _hoursController,
                                      readOnly: !_isEditingHours,
                                      decoration: const InputDecoration(
                                        border: InputBorder.none,
                                        isCollapsed: true,
                                      ),
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[800],
                                      ),
                                      maxLines: 2,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                const Icon(Icons.phone, color: Colors.blue),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: const Text(
                                    'Contact Numbers',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: Color.fromARGB(255, 33, 32, 32),
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
                                      color: Colors.transparent,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.more_horiz,
                                      color: Colors.black,
                                    ),
                                  ),
                                  onSelected: (value) async {
                                    if (value == 'edit') {
                                      setState(() {
                                        if (_isEditingContacts) {
                                          _isEditingContacts = false;
                                          _scaffoldMessengerKey.currentState
                                              ?.showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                    'Contact numbers saved',
                                                  ),
                                                ),
                                              );
                                        } else {
                                          _isEditingContacts = true;
                                        }
                                      });
                                    } else if (value == 'delete') {
                                      final confirm = await showDialog<bool>(
                                        context: context,
                                        builder: (c) => AlertDialog(
                                          backgroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          title: const Text(
                                            'Delete Contact Numbers',
                                            style: TextStyle(
                                              color: Colors.black,
                                            ),
                                          ),
                                          content: const Text(
                                            'Are you sure you want to delete the contact numbers?',
                                            style: TextStyle(
                                              color: Colors.black,
                                            ),
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.of(c).pop(false),
                                              child: const Text(
                                                'Cancel',
                                                style: TextStyle(
                                                  color: Color.fromARGB(
                                                    255,
                                                    54,
                                                    168,
                                                    244,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.of(c).pop(true),
                                              child: const Text(
                                                'Delete',
                                                style: TextStyle(
                                                  color: Colors.red,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                      if (confirm == true) {
                                        final prev =
                                            _contactNumbersController.text;
                                        _lastDeleted = {
                                          'field': 'contacts',
                                          'previousText': prev,
                                        };
                                        setState(() {
                                          _contactNumbersController.clear();
                                          _isEditingContacts = false;
                                        });
                                        _scaffoldMessengerKey.currentState
                                            ?.showSnackBar(
                                              SnackBar(
                                                content: const Text(
                                                  'Contact numbers cleared',
                                                ),
                                                action: SnackBarAction(
                                                  label: 'Undo',
                                                  onPressed: () {
                                                    final info = _lastDeleted;
                                                    if (info == null) return;
                                                    if (info['field'] ==
                                                        'contacts') {
                                                      final prevText =
                                                          info['previousText']
                                                              as String;
                                                      setState(() {
                                                        _contactNumbersController
                                                                .text =
                                                            prevText;
                                                      });
                                                    }
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
                                        _isEditingContacts ? 'Save' : 'Edit',
                                        style: const TextStyle(
                                          color: Colors.black,
                                        ),
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 'delete',
                                      child: Text(
                                        'Delete',
                                        style: TextStyle(color: Colors.red),
                                      ),
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
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                    ),
                                    child: TextField(
                                      controller: _contactNumbersController,
                                      readOnly: !_isEditingContacts,
                                      decoration: const InputDecoration(
                                        border: InputBorder.none,
                                        isCollapsed: true,
                                      ),
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[800],
                                      ),
                                      maxLines: 2,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                              ],
                            ),
                          ],
                        ),
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
              label: 'Announcement',
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

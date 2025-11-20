import 'package:flutter/material.dart';

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

class StaffHomePage extends StatefulWidget {
  const StaffHomePage({super.key});

  @override
  State<StaffHomePage> createState() => _StaffHomePageState();
}

class _StaffHomePageState extends State<StaffHomePage> {
  // Sample info items (replace with Firestore data later)
  List<Map<String, String>> infoItems = [
    {
      'title': 'Health & Welfare',
      'category': 'Health & Welfare',
      'description':
          'Schedules for the Brgy Health Center (BHC), available services (immunization, check-ups), contact information, and health guidelines.',
      'lastUpdated': '2 days ago',
    },
    {
      'title': 'Brgy Clearance/Permit Process',
      'category': 'Brgy Clearance/Permit Process',
      'description':
          'Step-by-step guide on how to secure a Brgy Clearance (requirements, fees, processing time, and online application status).',
      'lastUpdated': '1 week ago',
    },
    {
      'title': 'Brgy Hall Schedule',
      'category': 'Brgy Hall Schedule',
      'description':
          'Operating hours of the Brgy Hall and specific department schedules (e.g., Treasurer\'s office hours, Mayor\'s receiving days).',
      'lastUpdated': 'Today',
    },
  ];

  int _selectedIndex = 0;
  // Inline edit state for info items (to mimic emergency-hotline edit/save behavior)
  List<TextEditingController> _titleControllers = [];
  List<TextEditingController> _categoryControllers = [];
  List<TextEditingController> _descriptionControllers = [];
  List<bool> _isEditingInfo = [];
  List<FocusNode> _infoFocusNodes = [];
  List<String?> _inlineInfoMessages = [];

  void _onItemTapped(int index) {
    if (index == 1) {
      // Emergency button -> Staff Emergency Hotline page
      Navigator.pushReplacementNamed(context, '/staff-emergency-hotline');
    } else if (index == 2) {
      // Add button -> Staff Announcement page
      Navigator.pushReplacementNamed(context, '/staff-announcement');
    } else if (index == 3) {
      // People -> Staff Brgy Officials page
      Navigator.pushReplacementNamed(context, '/staff-brgy-officials');
    } else if (index == 4) {
      // Profile -> Staff Account Settings
      Navigator.pushReplacementNamed(context, '/staff-account-settings');
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Column(
          children: [
            // --- HEADER: iBrgy style copied from admin_dashboard ---
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 20.0,
                vertical: 16.0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Left side: Home Icon + iBrgy Text
                  Row(
                    children: [
                      Icon(Icons.home, color: Colors.blue.shade700, size: 30),
                      const SizedBox(width: 8),
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: 'iB',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                            TextSpan(
                              text: 'rgy',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // Right side: Profile Icon (optional for staff)
                ],
              ),
            ),

            // Info cards list
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Community Information',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        // --- UPDATED BUTTON: IconButton (no border) ---
                        IconButton(
                          onPressed: () => _showAddInfoDialog(),
                          icon: const Icon(Icons.add, size: 28),
                          color: Colors.blue,
                          tooltip: 'Add Information',
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Info cards
                    for (int i = 0; i < infoItems.length; i++)
                      _buildEnhancedInfoCard(context, infoItems[i], index: i),
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
          BottomNavigationBarItem(icon: Icon(Icons.phone), label: 'Emergency'),
          BottomNavigationBarItem(
            icon: Icon(Icons.announcement, size: 30),
            label: 'Updates',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'People'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    // initialize controllers and states to match infoItems
    _syncInfoControllers();
  }

  @override
  void dispose() {
    for (final c in _titleControllers) {
      c.dispose();
    }
    for (final c in _categoryControllers) {
      c.dispose();
    }
    for (final c in _descriptionControllers) {
      c.dispose();
    }
    for (final f in _infoFocusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _syncInfoControllers() {
    // Ensure lists match the length of infoItems while preserving existing values
    final len = infoItems.length;
    _titleControllers = List.generate(
      len,
      (i) => i < _titleControllers.length
          ? _titleControllers[i]
          : TextEditingController(text: infoItems[i]['title']),
    );
    _categoryControllers = List.generate(
      len,
      (i) => i < _categoryControllers.length
          ? _categoryControllers[i]
          : TextEditingController(text: infoItems[i]['category']),
    );
    _descriptionControllers = List.generate(
      len,
      (i) => i < _descriptionControllers.length
          ? _descriptionControllers[i]
          : TextEditingController(text: infoItems[i]['description']),
    );
    _isEditingInfo = List.generate(
      len,
      (i) => i < _isEditingInfo.length ? _isEditingInfo[i] : false,
    );
    _infoFocusNodes = List.generate(
      len,
      (i) => i < _infoFocusNodes.length ? _infoFocusNodes[i] : FocusNode(),
    );
    _inlineInfoMessages = List.generate(
      len,
      (i) => i < _inlineInfoMessages.length ? _inlineInfoMessages[i] : null,
    );
  }

  // (Stat cards removed — helper deleted)

  Widget _buildEnhancedInfoCard(
    BuildContext context,
    Map<String, String> info, {
    required int index,
  }) {
    final category = info['category'] ?? 'Community Info';
    final config =
        categoryConfig[category] ?? {'color': Colors.grey, 'icon': Icons.info};

    // Make sure controllers and states sync with infoItems
    if (_titleControllers.length < infoItems.length) {
      _syncInfoControllers();
    }

    final isEditing = index < _isEditingInfo.length
        ? _isEditingInfo[index]
        : false;
    final focusNode = index < _infoFocusNodes.length
        ? _infoFocusNodes[index]
        : FocusNode();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category header with color bar
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: (config['color'] as Color).withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              border: Border(
                left: BorderSide(color: config['color'] as Color, width: 4),
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: (config['color'] as Color).withOpacity(0.3),
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
                      // Title (editable inline)
                      isEditing
                          ? TextField(
                              controller: _titleControllers[index],
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                isDense: true,
                              ),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            )
                          : Text(
                              info['title'] ?? '',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                      Text(
                        'Updated ${info['lastUpdated'] ?? 'recently'}',
                        style: TextStyle(fontSize: 11, color: Colors.grey[600]),
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
                      color: Colors.transparent,
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
                        // commit IME composing text
                        focusNode.unfocus();
                        final savedTitle = _titleControllers[index].text.trim();
                        final savedCategory = _categoryControllers[index].text
                            .trim();
                        final savedDescription = _descriptionControllers[index]
                            .text
                            .trim();
                        setState(() {
                          infoItems[index] = {
                            'title': savedTitle,
                            'category': savedCategory,
                            'description': savedDescription,
                            'lastUpdated': 'Just now',
                          };
                          _isEditingInfo[index] = false;
                          _inlineInfoMessages[index] = 'Saved';
                        });
                        Future.delayed(const Duration(milliseconds: 1600), () {
                          if (!mounted) return;
                          setState(() => _inlineInfoMessages[index] = null);
                        });
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(const SnackBar(content: Text('Saved')));
                      } else {
                        setState(() {
                          _isEditingInfo[index] = true;
                        });
                        Future.delayed(const Duration(milliseconds: 80), () {
                          if (!mounted) return;
                          _infoFocusNodes[index].requestFocus();
                        });
                      }
                    } else if (value == 'delete') {
                      _showDeleteConfirmation(index);
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
                      child: Text(
                        'Delete',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Description / editable area
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: isEditing ? Colors.blue : Colors.transparent,
                      width: isEditing ? 2 : 0,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    color: isEditing ? Colors.white : Colors.white,
                  ),
                  child: isEditing
                      ? Column(
                          children: [
                            TextField(
                              controller: _descriptionControllers[index],
                              focusNode: _infoFocusNodes[index],
                              maxLines: 5,
                              decoration: InputDecoration(
                                hintText: 'Edit description...',
                                border: InputBorder.none,
                                hintStyle: TextStyle(color: Colors.grey[500]),
                              ),
                              style: const TextStyle(color: Colors.black87),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _categoryControllers[index],
                              decoration: InputDecoration(
                                hintText: 'Category',
                                border: InputBorder.none,
                                hintStyle: TextStyle(color: Colors.grey[500]),
                              ),
                              style: const TextStyle(color: Colors.black87),
                            ),
                          ],
                        )
                      : Text(
                          info['description'] ?? '',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[700],
                            height: 1.5,
                          ),
                        ),
                ),
                const SizedBox(height: 12),
                // Action buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Full details: ${infoItems[index]['title']}',
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.read_more, size: 16),
                      label: const Text('Read More'),
                      style: TextButton.styleFrom(
                        foregroundColor: config['color'] as Color,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Shared: ${infoItems[index]['title']}',
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.share, size: 16),
                      label: const Text('Share'),
                      style: TextButton.styleFrom(foregroundColor: Colors.grey),
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

  // --- ENHANCED DIALOG FUNCTION (MATCHING BRGY OFFICIALS STYLE) ---
  void _showAddInfoDialog() {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
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
        surfaceTintColor: Colors.white,
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
                Icons.post_add_rounded,
                color: Colors.blue.shade700,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Text(
                'Add Info',
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
              // Title Input
              TextField(
                controller: titleController,
                style: const TextStyle(color: Colors.black87),
                decoration: buildInputDecoration(
                  label: 'Title',
                  hint: 'e.g., Health & Welfare',
                  icon: Icons.title_rounded,
                ),
              ),
              const SizedBox(height: 16),
              // Category Input
              TextField(
                controller: categoryController,
                style: const TextStyle(color: Colors.black87),
                decoration: buildInputDecoration(
                  label: 'Category',
                  hint: 'e.g., Services',
                  icon: Icons.category_outlined,
                ),
              ),
              const SizedBox(height: 16),
              // Description Input
              TextField(
                controller: descriptionController,
                style: const TextStyle(color: Colors.black87),
                maxLines: 4,
                decoration: buildInputDecoration(
                  label: 'Description',
                  hint: 'Detailed description...',
                  icon: Icons.description_outlined,
                ),
              ),
            ],
          ),
        ),
        actions: [
          // Cancel Button
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
          // Add Button
          ElevatedButton.icon(
            onPressed: () {
              final title = titleController.text.trim();
              final description = descriptionController.text.trim();
              final category = categoryController.text.trim().isEmpty
                  ? 'Community Info'
                  : categoryController.text.trim();

              if (title.isEmpty || description.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please fill all fields'),
                    backgroundColor: Colors.redAccent,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
                return;
              }

              setState(() {
                infoItems.add({
                  'title': title,
                  'category': category,
                  'description': description,
                  'lastUpdated': 'Just now',
                });
              });

              Navigator.of(context).pop();

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Information added successfully'),
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
              shape: const StadiumBorder(),
            ),
            icon: const Icon(Icons.check_rounded, size: 20),
            label: const Text(
              'Add Info',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  // --- END ENHANCED DIALOG FUNCTION ---
  void _showEditInfoDialog(int index, Map<String, String> info) {
    final titleController = TextEditingController(text: info['title']);
    final descriptionController = TextEditingController(
      text: info['description'],
    );
    final categoryController = TextEditingController(
      text: info['category'] ?? 'Community Info',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text(
          'Edit Information',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: InputDecoration(
                  labelText: 'Title',
                  labelStyle: const TextStyle(color: Colors.black87),
                  hintStyle: TextStyle(color: Colors.grey[700]),
                  border: const OutlineInputBorder(),
                  prefixIcon: Icon(Icons.title, color: Colors.grey[700]),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: categoryController,
                decoration: InputDecoration(
                  labelText: 'Category',
                  labelStyle: const TextStyle(color: Colors.black87),
                  hintStyle: TextStyle(color: Colors.grey[700]),
                  border: const OutlineInputBorder(),
                  prefixIcon: Icon(Icons.category, color: Colors.grey[700]),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descriptionController,
                decoration: InputDecoration(
                  labelText: 'Description',
                  labelStyle: const TextStyle(color: Colors.black87),
                  hintStyle: TextStyle(color: Colors.grey[700]),
                  border: const OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description, color: Colors.grey[700]),
                ),
                maxLines: 5,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final title = titleController.text.trim();
              final description = descriptionController.text.trim();
              final category = categoryController.text.trim();

              if (title.isEmpty || description.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please fill all fields')),
                );
                return;
              }

              setState(() {
                infoItems[index] = {
                  'title': title,
                  'category': category,
                  'description': description,
                  'lastUpdated': 'Just now',
                };
              });

              Navigator.of(context).pop();

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Information updated successfully'),
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Information'),
        content: const Text(
          'Are you sure you want to delete this information?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                infoItems.removeAt(index);
              });

              Navigator.of(context).pop();

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Information deleted successfully'),
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

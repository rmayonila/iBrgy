import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../services/emergency_store.dart';

class StaffEmergencyHotlinePage extends StatefulWidget {
  const StaffEmergencyHotlinePage({super.key});

  @override
  State<StaffEmergencyHotlinePage> createState() =>
      _StaffEmergencyHotlinePageState();
}

class _StaffEmergencyHotlinePageState extends State<StaffEmergencyHotlinePage> {
  int _selectedIndex = 1; // Emergency tab

  // Sample emergency hotlines
  List<Map<String, String>> emergencyHotlines = [
    {
      'title': 'Barangay Emergency Response Team (BERT) / Brgy Hall',
      'number': '',
    },
    {'title': 'Local Police Station', 'number': ''},
    {'title': 'Local Fire Department (BFP)', 'number': ''},
    {'title': 'Local Hospital / Ambulance Service', 'number': ''},
  ];

  // Controllers for each hotline number field
  List<TextEditingController> hotlineControllers = [];
  // Editing state and focus nodes for inline edit/save behavior
  List<bool> _isEditingHotline = [];
  List<FocusNode> _hotlineFocusNodes = [];
  // Inline messages shown inside the phone frame (e.g., 'Saved', 'Number cleared')
  List<String?> _inlineMessages = [];
  Map<String, dynamic>? _lastDeletedHotline;
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  @override
  void initState() {
    super.initState();
    hotlineControllers = List.generate(
      emergencyHotlines.length,
      (i) => TextEditingController(text: emergencyHotlines[i]['number']),
    );
    // Initialize shared store with current defaults so other pages can read them
    EmergencyStore.instance.setAll(emergencyHotlines);
    _isEditingHotline = List.generate(emergencyHotlines.length, (_) => false);
    _hotlineFocusNodes = List.generate(
      emergencyHotlines.length,
      (_) => FocusNode(),
    );
    _inlineMessages = List.generate(emergencyHotlines.length, (_) => null);
  }

  @override
  void dispose() {
    for (final c in hotlineControllers) {
      c.dispose();
    }
    for (final f in _hotlineFocusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _onItemTapped(int index) {
    if (index == 0) {
      Navigator.pushReplacementNamed(context, '/staff-home');
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
      setState(() => _selectedIndex = index);
    }
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
              // Header with iBrgy and ADD NUMBER button
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
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
                      tooltip: 'Add Number',
                      onPressed: () => _showAddHotlineDialog(),
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

              // Search box
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 13,
                  ),
                  child: TextField(
                    textAlign: TextAlign.center,
                    textAlignVertical: TextAlignVertical.center,
                    maxLines: 2,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                      shadows: [
                        Shadow(
                          color: Colors.black26,
                          offset: Offset(2, 2),
                          blurRadius: 4,
                        ),
                      ],
                      letterSpacing: 0.5,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Your Safety is Priority!\nStay Safe!',
                      hintStyle: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: Color.fromARGB(255, 10, 9, 9),
                        shadows: [
                          Shadow(
                            color: Colors.black26,
                            offset: Offset(2, 2),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // Emergency header with icon
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    const Icon(Icons.phone, color: Colors.red, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Text(
                          'EMERGENCY HOTLINES',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // List of hotlines
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      for (int i = 0; i < emergencyHotlines.length; i++)
                        _buildHotlineEntry(i),
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
            BottomNavigationBarItem(icon: Icon(Icons.people), label: 'People'),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          ],
        ),
      ),
    );
  }

  // --- FINAL ENHANCED DIALOG FUNCTION (MATCHING BRGY OFFICIALS STYLE) ---
  Future<void> _showAddHotlineDialog() async {
    final titleController = TextEditingController();
    final numberController = TextEditingController();

    // Reusable decoration for consistent look (Exactly matching Brgy Official modal)
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

    await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (c) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        // Matches Brgy Official Border Radius (20)
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        // Matches Brgy Official Paddings
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
                Icons.contact_phone_rounded,
                color: Colors.blue.shade700,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Text(
                'Add Hotline',
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
                  label: 'Title Name',
                  hint: 'e.g. Main Office',
                  icon: Icons.business_rounded,
                ),
              ),
              const SizedBox(height: 16),
              // Number Input
              TextField(
                controller: numberController,
                keyboardType: TextInputType.phone,
                style: const TextStyle(color: Colors.black87),
                decoration: buildInputDecoration(
                  label: 'Hotline Number',
                  hint: 'e.g. 0912 345 6789',
                  icon: Icons.phone_rounded,
                ),
              ),
            ],
          ),
        ),
        actions: [
          // Cancel Button (Matches Brgy Official Style)
          TextButton(
            onPressed: () => Navigator.of(c).pop(false),
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey.shade700,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            child: const Text(
              'Cancel',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          // Add Button (Matches Brgy Official Stadium Style)
          ElevatedButton.icon(
            onPressed: () {
              final title = titleController.text.trim();
              final number = numberController.text.trim();
              if (title.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a title'),
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: Colors.redAccent,
                  ),
                );
                return;
              }

              setState(() {
                emergencyHotlines.add({'title': title, 'number': number});
                hotlineControllers.add(TextEditingController(text: number));
                _isEditingHotline.add(false);
                _hotlineFocusNodes.add(FocusNode());
                _inlineMessages.add(null);
                EmergencyStore.instance.setAll(emergencyHotlines);
              });

              Navigator.of(c).pop(true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade700,
              foregroundColor: Colors.white,
              elevation: 2,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: const StadiumBorder(), // Rounded pill shape
            ),
            icon: const Icon(Icons.check_rounded, size: 20),
            label: const Text(
              'Add Hotline',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        ],
      ),
    );

    titleController.dispose();
    numberController.dispose();
  }

  // --- END ENHANCED DIALOG FUNCTION ---
  Widget _buildHotlineEntry(int index) {
    final hotline = emergencyHotlines[index];
    // keep lists in sync
    if (hotlineControllers.length < emergencyHotlines.length) {
      hotlineControllers = List.generate(
        emergencyHotlines.length,
        (i) => TextEditingController(text: emergencyHotlines[i]['number']),
      );
    }
    if (_isEditingHotline.length < emergencyHotlines.length) {
      _isEditingHotline = List.generate(emergencyHotlines.length, (_) => false);
    }
    if (_hotlineFocusNodes.length < emergencyHotlines.length) {
      _hotlineFocusNodes = List.generate(
        emergencyHotlines.length,
        (_) => FocusNode(),
      );
    }
    if (_inlineMessages.length < emergencyHotlines.length) {
      final existing = List<String?>.from(_inlineMessages);
      _inlineMessages = List.generate(
        emergencyHotlines.length,
        (i) => i < existing.length ? existing[i] : null,
      );
    }

    final isEditing = _isEditingHotline[index];
    final focusNode = _hotlineFocusNodes[index];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  hotline['title'] ?? '',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
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
                    color: Color.fromARGB(255, 132, 129, 129),
                  ),
                ),
                onSelected: (value) async {
                  if (value == 'edit') {
                    if (isEditing) {
                      // If the field is currently focused (IME), unfocus first to commit text
                      focusNode.unfocus();
                      setState(() {
                        final saved = hotlineControllers[index].text.trim();
                        hotlineControllers[index].text = saved;
                        emergencyHotlines[index]['number'] = saved;
                        EmergencyStore.instance.updateNumber(index, saved);
                        _isEditingHotline[index] = false;
                      });
                      Timer(const Duration(milliseconds: 1600), () {
                        if (!mounted) return;
                        setState(() => _inlineMessages[index] = null);
                      });
                      _scaffoldMessengerKey.currentState?.showSnackBar(
                        const SnackBar(content: Text('Saved')),
                      );
                    } else {
                      setState(() {
                        _isEditingHotline[index] = true;
                      });
                      Future.delayed(const Duration(milliseconds: 80), () {
                        focusNode.requestFocus();
                      });
                    }
                  } else if (value == 'delete') {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (c) {
                        return AlertDialog(
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          title: const Text(
                            'Delete Number',
                            style: TextStyle(color: Colors.black),
                          ),
                          content: const Text(
                            'Are you sure you want to delete this number?',
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
                        );
                      },
                    );

                    if (confirm == true) {
                      final previousNumber = hotlineControllers[index].text;
                      _lastDeletedHotline = {
                        'index': index,
                        'previousNumber': previousNumber,
                      };
                      setState(() {
                        hotlineControllers[index].clear();
                        emergencyHotlines[index]['number'] = '';
                        // propagate deletion to shared store
                        EmergencyStore.instance.updateNumber(index, '');
                        if (_isEditingHotline.length > index)
                          _isEditingHotline[index] = false;
                      });

                      Timer(const Duration(milliseconds: 2200), () {
                        if (!mounted) return;
                        setState(() => _inlineMessages[index] = null);
                      });

                      _scaffoldMessengerKey.currentState?.showSnackBar(
                        SnackBar(
                          content: const Text('Number cleared'),
                          action: SnackBarAction(
                            label: 'Undo',
                            onPressed: () {
                              final info = _lastDeletedHotline;
                              if (info == null) return;
                              final idx = info['index'] as int;
                              final prev = info['previousNumber'] as String;
                              setState(() {
                                if (emergencyHotlines.length > idx) {
                                  emergencyHotlines[idx]['number'] = prev;
                                  hotlineControllers[idx].text = prev;
                                  EmergencyStore.instance.updateNumber(
                                    idx,
                                    prev,
                                  );
                                }
                                _inlineMessages[idx] = null;
                              });
                              _lastDeletedHotline = null;
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
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              border: Border.all(
                color: isEditing ? Colors.blue : Colors.grey.shade300,
                width: isEditing ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: hotlineControllers[index],
                        focusNode: focusNode,
                        readOnly: !isEditing,
                        style: TextStyle(
                          color:
                              hotlineControllers[index].text.trim().isNotEmpty
                              ? Colors.black
                              : Colors.grey.shade600,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Enter number',
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          hintStyle: TextStyle(color: Colors.grey.shade400),
                        ),
                        onChanged: (value) {
                          setState(() {
                            emergencyHotlines[index]['number'] = value;
                            // propagate change to shared store immediately
                            EmergencyStore.instance.updateNumber(index, value);
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 6),
                  ],
                ),
                if (_inlineMessages[index] != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _inlineMessages[index]!,
                      style: const TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

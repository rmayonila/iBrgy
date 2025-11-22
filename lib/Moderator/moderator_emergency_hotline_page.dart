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
  int _selectedIndex = 1; // Emergency tab

  final List<Map<String, String>> _hotlines = [];
  final List<TextEditingController> _numberControllers = [];
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _loadHotlines();
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
          'subtitle': (data['subtitle'] ?? '').toString(),
          'number': (data['number'] ?? '').toString(),
        };
      }).toList();
      setState(() {
        _hotlines.clear();
        _numberControllers.clear();
        for (var it in items) {
          _hotlines.add(it);
          _numberControllers.add(TextEditingController(text: it['number']));
        }
      });
    } catch (e) {
      // ignore
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

  Future<void> _showAddHotlineDialog() async {
    final nameController = TextEditingController();
    final numberController = TextEditingController();

    final entered = await showDialog<Map<String, String>>(
      context: context,
      builder: (ctx) => AlertDialog(
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
                const SizedBox(height: 8),
                TextField(
                  controller: numberController,
                  decoration: const InputDecoration(labelText: 'Phone Number'),
                  keyboardType: TextInputType.phone,
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
              });
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    nameController.dispose();
    numberController.dispose();

    if (entered != null) {
      if (!mounted) return;
      final scaffold = ScaffoldMessenger.of(context);
      final name = entered['name'] ?? '';
      final number = entered['number'] ?? '';
      try {
        final docRef = await _db.collection('hotlines').add({
          'name': name.isEmpty ? 'New Hotline' : name,
          'number': number,
          'createdAt': FieldValue.serverTimestamp(),
        });
        if (!mounted) return;
        setState(() {
          _hotlines.insert(0, {
            'id': docRef.id,
            'name': name.isEmpty ? 'New Hotline' : name,
            'subtitle': '',
            'number': number,
          });
          _numberControllers.insert(0, TextEditingController(text: number));
        });
        scaffold.showSnackBar(const SnackBar(content: Text('Hotline added')));
      } catch (e) {
        scaffold.showSnackBar(
          SnackBar(content: Text('Failed to add hotline: $e')),
        );
      }
    }
  }

  Future<void> _showEditHotlineDialog(int index) async {
    final current = _hotlines[index];
    final nameController = TextEditingController(text: current['name']);
    final numberController = TextEditingController(text: current['number']);

    final entered = await showDialog<Map<String, String>>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Emergency Hotline'),
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
                const SizedBox(height: 8),
                TextField(
                  controller: numberController,
                  decoration: const InputDecoration(labelText: 'Phone Number'),
                  keyboardType: TextInputType.phone,
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
              });
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    nameController.dispose();
    numberController.dispose();

    if (entered != null) {
      if (!mounted) return;
      final scaffold = ScaffoldMessenger.of(context);
      final newName = entered['name'] ?? _hotlines[index]['name']!;
      final newNumber = entered['number'] ?? _hotlines[index]['number']!;
      setState(() {
        _hotlines[index]['name'] = newName;
        _hotlines[index]['number'] = newNumber;
        _numberControllers[index].text = newNumber;
      });
      // update remote if id present
      final id = _hotlines[index]['id'];
      if (id != null) {
        try {
          await _db.collection('hotlines').doc(id).update({
            'name': newName,
            'number': newNumber,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        } catch (e) {
          scaffold.showSnackBar(
            SnackBar(content: Text('Failed to update remote: $e')),
          );
        }
      }
      scaffold.showSnackBar(const SnackBar(content: Text('Hotline updated')));
    }
  }

  @override
  void dispose() {
    for (final c in _numberControllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(0),
        child: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: Colors.white,
          elevation: 0,
        ),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(12.0, 8.0, 12.0, 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const SizedBox(width: 4),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              RichText(
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
                              const SizedBox(width: 6),
                              Transform.translate(
                                offset: const Offset(6, -6),
                                child: IconButton(
                                  tooltip: 'Add Number',
                                  onPressed: _showAddHotlineDialog,
                                  icon: Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: Colors.transparent,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.add,
                                      color: Colors.blue,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'BARANGAY EMERGENCY HOTLINE',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[700],
                              letterSpacing: 0.6,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 12),
                      Image.asset(
                        'assets/images/ibrgy_logo.png',
                        width: 100,
                        height: 36,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stack) =>
                            const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: _hotlines.isEmpty
                  ? const Center(
                      child: Text(
                        'NO EMERGENCY HOTLINES POSTED',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black54,
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(12),
                      itemCount: _hotlines.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final item = _hotlines[index];
                        final controller = _numberControllers[index];
                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade200),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withAlpha(8),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Stack(
                            children: [
                              // Positioned menu at the top-center of the card
                              Positioned(
                                top: 2,
                                left: 0,
                                right: 0,
                                child: Align(
                                  alignment: Alignment.topCenter,
                                  child: PopupMenuButton<int>(
                                    icon: const Icon(
                                      Icons.more_horiz,
                                      color: Colors.black,
                                    ),
                                    itemBuilder: (_) => const [
                                      PopupMenuItem(
                                        value: 0,
                                        child: Text('Edit'),
                                      ),
                                      PopupMenuItem(
                                        value: 1,
                                        child: Text('Delete'),
                                      ),
                                    ],
                                    onSelected: (v) async {
                                      if (v == 1) {
                                        final id = _hotlines[index]['id'];
                                        final scaffold = ScaffoldMessenger.of(
                                          context,
                                        );
                                        if (id != null) {
                                          try {
                                            await _db
                                                .collection('hotlines')
                                                .doc(id)
                                                .delete();
                                          } catch (e) {
                                            scaffold.showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  'Failed to delete remote: $e',
                                                ),
                                              ),
                                            );
                                          }
                                        }
                                        setState(() {
                                          _hotlines.removeAt(index);
                                          _numberControllers
                                              .removeAt(index)
                                              .dispose();
                                        });
                                      } else if (v == 0) {
                                        _showEditHotlineDialog(index);
                                      }
                                    },
                                  ),
                                ),
                              ),

                              // Main content shifted down to avoid overlap with the menu
                              Padding(
                                padding: const EdgeInsets.only(top: 26.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Name (centered less the menu)
                                    Text(
                                      item['name'] ?? '',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: Color.fromARGB(255, 33, 33, 33),
                                      ),
                                    ),
                                    if ((item['subtitle'] ?? '').isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          top: 6.0,
                                        ),
                                        child: Text(
                                          item['subtitle'] ?? '',
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    const SizedBox(height: 12),
                                    TextField(
                                      controller: controller,
                                      style: const TextStyle(
                                        color: Color.fromARGB(255, 33, 33, 33),
                                      ),
                                      cursorColor: Colors.black87,
                                      decoration: InputDecoration(
                                        hintText: 'Enter number',
                                        hintStyle: TextStyle(
                                          color: Colors.grey[400],
                                        ),
                                        filled: true,
                                        fillColor: Colors.white,
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 14,
                                            ),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          borderSide: BorderSide(
                                            color: Colors.grey.shade300,
                                          ),
                                        ),
                                      ),
                                      keyboardType: TextInputType.phone,
                                      onChanged: (v) {
                                        _hotlines[index]['number'] = v;
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
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
}

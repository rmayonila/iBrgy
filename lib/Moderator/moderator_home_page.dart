import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'moderator_nav.dart';

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

class ModeratorHomePage extends StatefulWidget {
  const ModeratorHomePage({super.key});

  @override
  // 2. Renamed state
  State<ModeratorHomePage> createState() => _ModeratorHomePageState();
}

// 3. Renamed state class
class _ModeratorHomePageState extends State<ModeratorHomePage> {
  // track expanded indices for inline post expansion
  final Set<int> _expanded = {};

  // Start with no seeded items — show placeholder for empty state
  List<Map<String, String>> infoItems = [];
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> _ensureSignedIn() async {
    try {
      if (_auth.currentUser == null) {
        await _auth.signInAnonymously();
      }
    } catch (_) {
      // ignore auth errors here; writes will fail with permission denied
    }
  }

  @override
  void initState() {
    super.initState();
    _loadInfoItems();
  }

  Future<void> _loadInfoItems() async {
    try {
      final snap = await _db
          .collection('infoItems')
          .orderBy('createdAt', descending: true)
          .get();
      if (!mounted) return;
      final items = snap.docs.map((d) {
        final data = d.data();
        return {
          'id': d.id,
          'title': (data['title'] ?? '').toString(),
          'category': (data['category'] ?? '').toString(),
          'description': (data['description'] ?? '').toString(),
          'lastUpdated': data['createdAt'] != null
              ? data['createdAt'].toDate().toString()
              : 'recently',
        };
      }).toList();
      setState(() {
        infoItems = items;
      });
    } catch (e) {
      // ignore load errors for now
    }
  }

  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    navigateModeratorIndex(
      context,
      index,
      currentIndex: _selectedIndex,
      onSamePage: (i) => setState(() => _selectedIndex = i),
    );
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
                    color: Colors.black.withAlpha(13),
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

  // 8. Modified Info Card for USER (no edit/delete)
  Widget _buildEnhancedInfoCard(
    BuildContext context,
    Map<String, String> info, {
    int? index,
  }) {
    final category = info['category'] ?? 'Community Info';
    final config =
        categoryConfig[category] ?? {'color': Colors.grey, 'icon': Icons.info};

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(20),
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
              color: (config['color'] as Color).withAlpha(26),
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
                  backgroundColor: (config['color'] as Color).withAlpha(76),
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
                      Text(
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
                // 9. REMOVED PopupMenuButton (Edit/Delete)
              ],
            ),
          ),

          // Description
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  info['description'] ?? '',
                  maxLines: (index != null && _expanded.contains(index))
                      ? null
                      : 3,
                  overflow: (index != null && _expanded.contains(index))
                      ? TextOverflow.visible
                      : TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[700],
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 12),
                // Action buttons (User-facing)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton.icon(
                      onPressed: () {
                        if (index != null) {
                          setState(() {
                            if (_expanded.contains(index)) {
                              _expanded.remove(index);
                            } else {
                              _expanded.add(index);
                            }
                          });
                        }
                      },
                      icon: Icon(
                        _expanded.contains(index)
                            ? Icons.expand_less
                            : Icons.read_more,
                        size: 16,
                      ),
                      label: Text(
                        _expanded.contains(index) ? 'Show Less' : 'Read More',
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: config['color'] as Color,
                      ),
                    ),
                    const SizedBox.shrink(),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Simple dialog to add an info item (title, category, description)
  void _showAddInfoDialog() {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String selectedCategory = categoryConfig.keys.first;

    showDialog<void>(
      context: context,
      builder: (ctx) {
        // Use the same centered fixed dialog approach as the announcements
        // modal so the dialog stays in place when the keyboard appears.
        return MediaQuery(
          data: MediaQuery.of(ctx).copyWith(viewInsets: EdgeInsets.zero),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: Material(
                color:
                    Theme.of(ctx).dialogTheme.backgroundColor ??
                    Theme.of(ctx).colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Add Information',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(),
                            child: const Text('Cancel'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: titleCtrl,
                        decoration: const InputDecoration(labelText: 'Title'),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        initialValue: selectedCategory,
                        items: categoryConfig.keys
                            .map(
                              (k) => DropdownMenuItem(value: k, child: Text(k)),
                            )
                            .toList(),
                        onChanged: (v) {
                          if (v != null) selectedCategory = v;
                        },
                        decoration: const InputDecoration(
                          labelText: 'Category',
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 140,
                        child: TextField(
                          controller: descCtrl,
                          maxLines: 6,
                          textAlignVertical: TextAlignVertical.top,
                          decoration: InputDecoration(
                            labelText: 'Description',
                            contentPadding: const EdgeInsets.all(12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          autofocus: true,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Spacer(),
                          ElevatedButton(
                            onPressed: () async {
                              final title = titleCtrl.text.trim();
                              final desc = descCtrl.text.trim();
                              if (title.isEmpty) return;
                              try {
                                final navigator = Navigator.of(ctx);
                                await _ensureSignedIn();
                                final docRef = await _db
                                    .collection('infoItems')
                                    .add({
                                      'title': title,
                                      'category': selectedCategory,
                                      'description': desc,
                                      'createdAt': FieldValue.serverTimestamp(),
                                    });
                                if (!mounted) return;
                                setState(() {
                                  infoItems.insert(0, {
                                    'id': docRef.id,
                                    'title': title,
                                    'category': selectedCategory,
                                    'description': desc,
                                    'lastUpdated': 'Just now',
                                  });
                                });
                                navigator.pop();
                              } catch (e) {
                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Failed to add: $e')),
                                );
                              }
                            },
                            child: const Text('Add'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // 10. REMOVED _showAddInfoDialog, _showEditInfoDialog, and _showDeleteConfirmation
}

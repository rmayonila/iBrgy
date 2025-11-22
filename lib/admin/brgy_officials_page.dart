import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BrgyOfficialsPage extends StatefulWidget {
  const BrgyOfficialsPage({super.key});

  @override
  State<BrgyOfficialsPage> createState() => _BrgyOfficialsPageState();
}

class _BrgyOfficialsPageState extends State<BrgyOfficialsPage> {
  int _selectedIndex = 3;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  Map<String, List<Map<String, String>>> _officials = {};
  Map<String, Map<String, String>> _contacts = {};

  void _onItemTapped(BuildContext context, int index) {
    if (index == 0) {
      Navigator.pushReplacementNamed(context, '/admin-home');
    } else if (index == 1) {
      Navigator.pushReplacementNamed(context, '/emergency-hotline');
    } else if (index == 2) {
      Navigator.pushReplacementNamed(context, '/announcement');
    } else if (index == 4) {
      Navigator.pushReplacementNamed(context, '/account-settings');
    }
  }

  @override
  void initState() {
    super.initState();
    _loadOfficialsAndContacts();
  }

  Future<void> _loadOfficialsAndContacts() async {
    try {
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
        _officials = loaded;
        _contacts = contacts;
      });
    } catch (e) {
      // ignore
    }
  }

  bool _hasContactInfo(String category) {
    final c = _contacts[category];
    if (c == null) return false;
    return (c['address']?.trim().isNotEmpty ?? false) ||
        (c['hours']?.trim().isNotEmpty ?? false) ||
        (c['contacts']?.trim().isNotEmpty ?? false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex, // People icon selected
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.white,
        showSelectedLabels: true,
        elevation: 8,
        onTap: (index) => _onItemTapped(context, index),
        items: const <BottomNavigationBarItem>[
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

      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(0),
        child: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: Colors.white,
          elevation: 0,
        ),
      ),
      body: SizedBox.expand(
        child: Stack(
          children: [
            // Placeholder when no officials
            if (_officials.isEmpty)
              const Positioned.fill(
                child: Center(
                  child: Text(
                    'NO BARANGAY OFFICIALS POSTED',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black54,
                    ),
                  ),
                ),
              ),

            Padding(
              padding: const EdgeInsets.fromLTRB(12.0, 8.0, 12.0, 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(
                      left: 4.0,
                      right: 12.0,
                      top: 6.0,
                      bottom: 4.0,
                    ),
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
                                const SizedBox(height: 12),
                                Text(
                                  'BARANGAY OFFICIALS',
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

                  const SizedBox(height: 8),

                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (var entry in _officials.entries) ...[
                            Text(
                              entry.key,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                            const SizedBox(height: 12),
                            for (var o in entry.value)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      o['title'] ?? '',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      o['name'] ?? '',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                  ],
                                ),
                              ),

                            if (_hasContactInfo(entry.key))
                              Container(
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
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if ((_contacts[entry.key]?['address'] ?? '')
                                        .isNotEmpty) ...[
                                      const Text(
                                        'Office Address',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        _contacts[entry.key]!['address'] ?? '',
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                      const SizedBox(height: 8),
                                    ],
                                    if ((_contacts[entry.key]?['hours'] ?? '')
                                        .isNotEmpty) ...[
                                      const Text(
                                        'Office Hours',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        _contacts[entry.key]!['hours'] ?? '',
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                      const SizedBox(height: 8),
                                    ],
                                    if ((_contacts[entry.key]?['contacts'] ??
                                            '')
                                        .isNotEmpty) ...[
                                      const Text(
                                        'Office Telephone Number',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        _contacts[entry.key]!['contacts'] ?? '',
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                    ],
                                  ],
                                ),
                              ),

                            const SizedBox(height: 18),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

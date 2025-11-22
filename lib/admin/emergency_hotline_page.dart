import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EmergencyHotlinePage extends StatefulWidget {
  const EmergencyHotlinePage({super.key});

  @override
  State<EmergencyHotlinePage> createState() => _EmergencyHotlinePageState();
}

class _EmergencyHotlinePageState extends State<EmergencyHotlinePage> {
  int _selectedIndex = 1;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  List<Map<String, String>> _hotlines = [];

  void _onItemTapped(BuildContext context, int index) {
    if (index == 0) {
      Navigator.pushReplacementNamed(context, '/admin-home');
    } else if (index == 2) {
      Navigator.pushReplacementNamed(context, '/announcement');
    } else if (index == 3) {
      Navigator.pushReplacementNamed(context, '/brgy-officials');
    } else if (index == 4) {
      Navigator.pushReplacementNamed(context, '/account-settings');
    }
  }

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
      final items = snap.docs.map((d) {
        final data = d.data();
        return {
          'id': d.id,
          'name': (data['name'] ?? '').toString(),
          'number': (data['number'] ?? '').toString(),
        };
      }).toList();
      if (!mounted) return;
      setState(() {
        _hotlines = items;
      });
    } catch (e) {
      // ignore
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex, // Phone icon selected
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.white,
        showSelectedLabels: true,
        elevation: 8,
        onTap: (index) => _onItemTapped(context, index),
        // consistent label styles (use defaults)
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
            tooltip: '',
            backgroundColor: Colors.white,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.phone),
            label: 'Emergency',
            tooltip: '',
            backgroundColor: Colors.white,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.announcement, size: 30),
            label: 'Updates',
            tooltip: '',
            backgroundColor: Colors.white,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'People',
            tooltip: '',
            backgroundColor: Colors.white,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
            tooltip: '',
            backgroundColor: Colors.white,
          ),
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
            // Full-body centered placeholder
            if (_hotlines.isEmpty)
              const Positioned.fill(
                child: Center(
                  child: Text(
                    'NO EMERGENCY HOTLINES POSTED',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black54,
                    ),
                  ),
                ),
              ),

            // Header and content on top
            Padding(
              padding: const EdgeInsets.fromLTRB(12.0, 8.0, 12.0, 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
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

                  const SizedBox(height: 8),

                  // List of hotlines
                  if (_hotlines.isNotEmpty)
                    Expanded(
                      child: ListView.separated(
                        itemCount: _hotlines.length,
                        separatorBuilder: (_, __) => const Divider(),
                        itemBuilder: (ctx, i) {
                          final h = _hotlines[i];
                          return ListTile(
                            leading: const Icon(
                              Icons.phone,
                              color: Colors.blue,
                            ),
                            title: Text(h['name'] ?? ''),
                            subtitle: Text(h['number'] ?? ''),
                            onTap: () {},
                          );
                        },
                      ),
                    )
                  else
                    const SizedBox(height: 0),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

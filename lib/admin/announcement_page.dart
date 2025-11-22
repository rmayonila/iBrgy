import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AnnouncementPage extends StatefulWidget {
  const AnnouncementPage({super.key});

  @override
  State<AnnouncementPage> createState() => _AnnouncementPageState();
}

class _AnnouncementPageState extends State<AnnouncementPage> {
  int _selectedIndex = 2;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  List<Map<String, String>> _posts = [];

  void _onItemTapped(BuildContext context, int index) {
    if (index == 0) {
      Navigator.pushReplacementNamed(context, '/admin-home');
    } else if (index == 1) {
      Navigator.pushReplacementNamed(context, '/emergency-hotline');
    } else if (index == 3) {
      Navigator.pushReplacementNamed(context, '/brgy-officials');
    } else if (index == 4) {
      Navigator.pushReplacementNamed(context, '/account-settings');
    }
  }

  @override
  void initState() {
    super.initState();
    _loadAnnouncements();
  }

  Future<void> _loadAnnouncements() async {
    try {
      final snap = await _db
          .collection('announcements')
          .orderBy('createdAt', descending: true)
          .get();
      final items = snap.docs.map((d) {
        final data = d.data();
        return {
          'id': d.id,
          'author': (data['author'] ?? '').toString(),
          'time': data['createdAt'] != null
              ? data['createdAt'].toDate().toString()
              : 'recently',
          'content': (data['content'] ?? '').toString(),
        };
      }).toList();
      if (!mounted) return;
      setState(() {
        _posts = items;
      });
    } catch (e) {
      // ignore load errors
    }
  }

  Widget _buildPost(Map<String, String> post) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: const Color.fromARGB(8, 250, 245, 245),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      (post['author'] ?? 'U').substring(0, 1),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post['author'] ?? 'Unknown',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        post['time'] ?? '',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.more_horiz),
                  color: Colors.grey,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              post['content'] ?? '',
              style: const TextStyle(
                fontSize: 14,
                height: 1.3,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            // Image placeholder (optional)
            Container(
              width: double.infinity,
              height: 140,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(child: Icon(Icons.image, color: Colors.grey)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SizedBox.expand(
        child: Stack(
          children: [
            // Full-body centered placeholder when there are no posts
            if (_posts.isEmpty)
              const Positioned.fill(
                child: Center(
                  child: Text(
                    'NO ANNOUNCEMENTS POSTED',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black54,
                    ),
                  ),
                ),
              ),

            // Main content (header + posts). Drawn on top so header remains visible.
            Padding(
              padding: const EdgeInsets.fromLTRB(12.0, 8.0, 12.0, 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header (matches staff layout: left brand, right add button)
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
                                  'BARANGAY ANNOUNCEMENT',
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

                  const SizedBox(height: 2),

                  // Page title
                  const Text(
                    'Barangay Updates',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),

                  // Posts area (scrollable when present)
                  if (_posts.isNotEmpty)
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          children: [for (var post in _posts) _buildPost(post)],
                        ),
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
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 2,
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
    );
  }
}

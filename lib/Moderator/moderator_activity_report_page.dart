import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ModeratorActivityReportPage extends StatefulWidget {
  const ModeratorActivityReportPage({super.key});

  @override
  State<ModeratorActivityReportPage> createState() =>
      _ModeratorActivityReportPageState();
}

class _ModeratorActivityReportPageState
    extends State<ModeratorActivityReportPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  int _selectedFilter = 0; // 0: Today, 1: This Week, 2: This Month
  List<String> filterOptions = ['Today', 'This Week', 'This Month'];

  Map<String, dynamic> _stats = {
    'postsCreated': 0,
    'announcementsPosted': 0,
    'contentEdited': 0,
    'totalEngagement': 0,
  };

  List<Map<String, dynamic>> _recentActivities = [];

  @override
  void initState() {
    super.initState();
    _loadActivityData();
  }

  Future<void> _loadActivityData() async {
    final user = _auth.currentUser;
    if (user == null) return;

    // Calculate date range based on filter
    DateTime startDate;
    final now = DateTime.now();

    switch (_selectedFilter) {
      case 0: // Today
        startDate = DateTime(now.year, now.month, now.day);
        break;
      case 1: // This Week
        startDate = now.subtract(const Duration(days: 7));
        break;
      case 2: // This Month
        startDate = DateTime(now.year, now.month, 1);
        break;
      default:
        startDate = now.subtract(const Duration(days: 7));
    }

    try {
      // Get posts created by moderator
      final postsSnapshot = await _firestore
          .collection('posts')
          .where('createdBy', isEqualTo: user.uid)
          .where('createdAt', isGreaterThanOrEqualTo: startDate)
          .get();

      // Get announcements
      final announcementsSnapshot = await _firestore
          .collection('announcements')
          .where('createdBy', isEqualTo: user.uid)
          .where('createdAt', isGreaterThanOrEqualTo: startDate)
          .get();

      // Calculate stats
      final postsCreated = postsSnapshot.docs.length;
      final announcementsPosted = announcementsSnapshot.docs.length;

      // Calculate engagement (likes + comments)
      int totalEngagement = 0;
      for (final doc in postsSnapshot.docs) {
        final data = doc.data();
        totalEngagement += (data['likes'] as List? ?? []).length;
        totalEngagement += (data['comments'] as List? ?? []).length;
      }

      // Get recent activities
      final activitiesSnapshot = await _firestore
          .collection('moderator_activities')
          .where('moderatorId', isEqualTo: user.uid)
          .where('timestamp', isGreaterThanOrEqualTo: startDate)
          .orderBy('timestamp', descending: true)
          .limit(10)
          .get();

      setState(() {
        _stats = {
          'postsCreated': postsCreated,
          'announcementsPosted': announcementsPosted,
          'contentEdited': postsCreated + announcementsPosted, // Simplified
          'totalEngagement': totalEngagement,
        };

        _recentActivities = activitiesSnapshot.docs.map((doc) {
          final data = doc.data();
          return {
            'id': doc.id,
            'action': data['action'] ?? 'Unknown Action',
            'details': data['details'] ?? '',
            'timestamp': data['timestamp'],
          };
        }).toList();
      });
    } catch (e) {
      print('Error loading activity data: $e');
    }
  }

  Widget _buildStatCard(String title, int count, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              count.toString(),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(Timestamp timestamp) {
    final time = timestamp.toDate();
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inHours < 1) return '${difference.inMinutes}m ago';
    if (difference.inDays < 1) return '${difference.inHours}h ago';
    if (difference.inDays < 7) return '${difference.inDays}d ago';

    return '${time.month}/${time.day}/${time.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Activity Report'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Filter Chips
            SizedBox(
              height: 40,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: filterOptions.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(filterOptions[index]),
                      selected: _selectedFilter == index,
                      onSelected: (selected) {
                        setState(() {
                          _selectedFilter = index;
                        });
                        _loadActivityData();
                      },
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),

            // Statistics Cards
            const Text(
              'Overview',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildStatCard(
                  'Posts',
                  _stats['postsCreated'] as int,
                  Icons.post_add,
                  Colors.blue,
                ),
                const SizedBox(width: 12),
                _buildStatCard(
                  'Announcements',
                  _stats['announcementsPosted'] as int,
                  Icons.campaign,
                  Colors.green,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildStatCard(
                  'Edited',
                  _stats['contentEdited'] as int,
                  Icons.edit,
                  Colors.orange,
                ),
                const SizedBox(width: 12),
                _buildStatCard(
                  'Engagement',
                  _stats['totalEngagement'] as int,
                  Icons.thumb_up,
                  Colors.purple,
                ),
              ],
            ),
            const SizedBox(height: 30),

            // Recent Activities
            const Text(
              'Recent Activities',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (_recentActivities.isEmpty)
              const Center(
                child: Column(
                  children: [
                    Icon(Icons.history, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text('No recent activities'),
                  ],
                ),
              )
            else
              ..._recentActivities.map(
                (activity) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.history, color: Colors.grey[600], size: 16),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              activity['action'] as String,
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if ((activity['details'] as String).isNotEmpty)
                              Text(
                                activity['details'] as String,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                          ],
                        ),
                      ),
                      Text(
                        _formatTimestamp(activity['timestamp'] as Timestamp),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

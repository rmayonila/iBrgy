import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ModeratorScheduledContentPage extends StatefulWidget {
  const ModeratorScheduledContentPage({super.key});

  @override
  State<ModeratorScheduledContentPage> createState() =>
      _ModeratorScheduledContentPageState();
}

class _ModeratorScheduledContentPageState
    extends State<ModeratorScheduledContentPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<Map<String, dynamic>> _scheduledContent = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadScheduledContent();
  }

  Future<void> _loadScheduledContent() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final snapshot = await _firestore
          .collection('scheduled_content')
          .where('createdBy', isEqualTo: user.uid)
          .where('scheduledFor', isGreaterThan: DateTime.now())
          .orderBy('scheduledFor', descending: false)
          .get();

      setState(() {
        _scheduledContent = snapshot.docs.map((doc) {
          final data = doc.data();
          return {
            'id': doc.id,
            'title': data['title'] ?? 'Untitled',
            'type': data['type'] ?? 'post',
            'scheduledFor': data['scheduledFor'],
            'status': data['status'] ?? 'scheduled',
          };
        }).toList();
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading scheduled content: $e');
      setState(() => _isLoading = false);
    }
  }

  Widget _buildScheduledItem(Map<String, dynamic> item) {
    final scheduledFor = (item['scheduledFor'] as Timestamp).toDate();
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            item['type'] == 'announcement' ? Icons.campaign : Icons.post_add,
            color: Colors.blue,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['title'] as String,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Scheduled for: ${scheduledFor.toString().substring(0, 16)}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit, size: 20, color: Colors.blue),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Edit scheduled content')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete, size: 20, color: Colors.red),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Delete scheduled content')),
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Scheduled Content'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  if (_scheduledContent.isEmpty)
                    const Center(
                      child: Column(
                        children: [
                          Icon(Icons.schedule, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text('No scheduled content'),
                          Text(
                            'Schedule your first post!',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  else
                    ..._scheduledContent.map(_buildScheduledItem),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Schedule new content')));
        },
        backgroundColor: Colors.orange,
        child: const Icon(Icons.schedule, color: Colors.white),
      ),
    );
  }
}

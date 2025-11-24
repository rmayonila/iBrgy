import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ModeratorMyPostPage extends StatefulWidget {
  const ModeratorMyPostPage({super.key});

  @override
  State<ModeratorMyPostPage> createState() => _ModeratorMyPostPageState();
}

class _ModeratorMyPostPageState extends State<ModeratorMyPostPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<Map<String, dynamic>> _myPosts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMyPosts();
  }

  Future<void> _loadMyPosts() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final snapshot = await _firestore
          .collection('posts')
          .where('createdBy', isEqualTo: user.uid)
          .orderBy('createdAt', descending: true)
          .limit(20)
          .get();

      setState(() {
        _myPosts = snapshot.docs.map((doc) {
          final data = doc.data();
          return {
            'id': doc.id,
            'title': data['title'] ?? 'Untitled',
            'content': data['content'] ?? '',
            'createdAt': data['createdAt'],
            'likes': (data['likes'] as List? ?? []).length,
            'comments': (data['comments'] as List? ?? []).length,
            'status': data['status'] ?? 'published',
            'type': data['type'] ?? 'post',
          };
        }).toList();
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading posts: $e');
      setState(() => _isLoading = false);
    }
  }

  Widget _buildPostItem(Map<String, dynamic> post) {
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                post['type'] == 'announcement'
                    ? Icons.campaign
                    : Icons.post_add,
                color: Colors.blue,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  post['title'] as String,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            (post['content'] as String).length > 100
                ? '${(post['content'] as String).substring(0, 100)}...'
                : post['content'] as String,
            style: const TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.thumb_up, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text('${post['likes']}'),
              const SizedBox(width: 16),
              Icon(Icons.comment, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text('${post['comments']}'),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: (post['status'] == 'published')
                      ? Colors.green.withOpacity(0.1)
                      : Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  post['status'] as String,
                  style: TextStyle(
                    color: (post['status'] == 'published')
                        ? Colors.green
                        : Colors.orange,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
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
        title: const Text('My Posts & Announcements'),
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
                  if (_myPosts.isEmpty)
                    const Center(
                      child: Column(
                        children: [
                          Icon(Icons.post_add, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text('No posts yet'),
                          Text(
                            'Create your first post!',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  else
                    ..._myPosts.map(_buildPostItem),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Create new post feature')),
          );
        },
        backgroundColor: Colors.green,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

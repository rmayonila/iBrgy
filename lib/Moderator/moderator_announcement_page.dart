import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'moderator_nav.dart';

class ModeratorAnnouncementPage extends StatefulWidget {
  const ModeratorAnnouncementPage({super.key});

  @override
  State<ModeratorAnnouncementPage> createState() =>
      _ModeratorAnnouncementPageState();
}

class _ModeratorAnnouncementPageState extends State<ModeratorAnnouncementPage> {
  int _selectedIndex = 2;

  void _onItemTapped(int index) {
    navigateModeratorIndex(
      context,
      index,
      currentIndex: _selectedIndex,
      onSamePage: (i) => setState(() => _selectedIndex = i),
    );
  }

  // Posts state (start empty — no seeded posts)
  final List<Map<String, String>> _posts = [];
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> _ensureSignedIn() async {
    try {
      if (_auth.currentUser == null) {
        await _auth.signInAnonymously();
      }
    } catch (e) {
      // ignore sign-in errors; writes will report failures
    }
  }

  final TextEditingController _postController = TextEditingController();
  bool _isComposing = false;
  late FocusNode _composerFocusNode;

  @override
  void dispose() {
    _postController.dispose();
    _composerFocusNode.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _composerFocusNode = FocusNode();
    _loadAnnouncements();
  }

  Future<void> _loadAnnouncements() async {
    try {
      final snap = await _db
          .collection('announcements')
          .orderBy('createdAt', descending: true)
          .get();
      if (!mounted) return;
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
      setState(() {
        _posts.clear();
        _posts.addAll(items);
      });
    } catch (e) {
      // ignore
    }
  }

  // New: show a centered fixed-position modal dialog for creating posts.
  void _showCenteredCreatePostDialog() {
    _postController.clear();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(viewInsets: EdgeInsets.zero),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: Colors.blue,
                            child: const Icon(
                              Icons.business,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'Create post',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text(
                              'Cancel',
                              style: TextStyle(
                                color: Color.fromARGB(255, 249, 18, 18),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 140,
                        child: TextField(
                          controller: _postController,
                          maxLines: 6,
                          style: const TextStyle(color: Colors.black),
                          cursorColor: Colors.black,
                          textAlignVertical: TextAlignVertical.top,
                          decoration: InputDecoration(
                            hintText: 'What\'s happening in your barangay?',
                            hintStyle: TextStyle(color: Colors.black45),
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
                          IconButton(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Attach photo not implemented'),
                                ),
                              );
                            },
                            icon: const Icon(Icons.image, color: Colors.grey),
                          ),
                          const Spacer(),
                          ElevatedButton(
                            onPressed: () async {
                              final text = _postController.text.trim();
                              if (text.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Please write something'),
                                  ),
                                );
                                return;
                              }
                              final navigator = Navigator.of(context);
                              final scaffold = ScaffoldMessenger.of(context);
                              try {
                                await _ensureSignedIn();
                                final docRef = await _db
                                    .collection('announcements')
                                    .add({
                                      'author': 'Barangay Office',
                                      'content': text,
                                      'createdAt': FieldValue.serverTimestamp(),
                                    });
                                if (!mounted) return;
                                setState(() {
                                  _posts.insert(0, {
                                    'id': docRef.id,
                                    'author': 'Barangay Office',
                                    'time': 'Just now',
                                    'content': text,
                                  });
                                });
                                navigator.pop();
                                scaffold.showSnackBar(
                                  const SnackBar(content: Text('Posted')),
                                );
                              } catch (e) {
                                if (!mounted) return;
                                scaffold.showSnackBar(
                                  SnackBar(content: Text('Failed: $e')),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                            ),
                            child: const Text(
                              'Post',
                              style: TextStyle(
                                color: Color.fromARGB(255, 248, 250, 251),
                              ),
                            ),
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

  void _closeInlineComposer() {
    setState(() {
      _isComposing = false;
    });
    _composerFocusNode.unfocus();
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
            color: const Color.fromARGB(255, 250, 245, 245).withAlpha(8),
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
                      post['author']!.substring(0, 1),
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
                        post['author']!,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        post['time']!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black,
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
              post['content']!,
              style: const TextStyle(
                fontSize: 14,
                height: 1.3,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 8),
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

  Widget _buildInlineComposer(BuildContext ctx) {
    if (!_isComposing) return const SizedBox.shrink();

    return Positioned.fill(
      child: Material(
        color: Colors.transparent,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => _closeInlineComposer(),
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 360),
                child: Material(
                  borderRadius: BorderRadius.circular(12),
                  clipBehavior: Clip.antiAlias,
                  child: Container(
                    color: Colors.white,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: Colors.blue,
                              child: const Icon(
                                Icons.business,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                'Create post',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: () => _closeInlineComposer(),
                              style: TextButton.styleFrom(
                                foregroundColor: const Color.fromARGB(
                                  221,
                                  232,
                                  74,
                                  74,
                                ),
                              ),
                              child: const Text(
                                'Cancel',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _postController,
                          focusNode: _composerFocusNode,
                          maxLines: 6,
                          style: const TextStyle(color: Colors.black),
                          cursorColor: Colors.black,
                          decoration: InputDecoration(
                            hintText: 'What\'s happening in your barangay?',
                            hintStyle: TextStyle(color: Colors.black45),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            IconButton(
                              onPressed: () {
                                ScaffoldMessenger.of(ctx).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Attach photo not implemented',
                                    ),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.image, color: Colors.grey),
                            ),
                            const SizedBox(width: 8),
                            const Spacer(),
                            ElevatedButton(
                              onPressed: () async {
                                final text = _postController.text.trim();
                                if (text.isEmpty) {
                                  ScaffoldMessenger.of(ctx).showSnackBar(
                                    const SnackBar(
                                      content: Text('Please write something'),
                                    ),
                                  );
                                  return;
                                }
                                final scaffold = ScaffoldMessenger.of(ctx);
                                try {
                                  await _ensureSignedIn();
                                  final docRef = await _db
                                      .collection('announcements')
                                      .add({
                                        'author': 'Barangay Office',
                                        'content': text,
                                        'createdAt':
                                            FieldValue.serverTimestamp(),
                                      });
                                  if (!mounted) return;
                                  setState(() {
                                    _posts.insert(0, {
                                      'id': docRef.id,
                                      'author': 'Barangay Office',
                                      'time': 'Just now',
                                      'content': text,
                                    });
                                  });
                                  _closeInlineComposer();
                                  scaffold.showSnackBar(
                                    const SnackBar(content: Text('Posted')),
                                  );
                                } catch (e) {
                                  if (!mounted) return;
                                  scaffold.showSnackBar(
                                    SnackBar(content: Text('Failed: $e')),
                                  );
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 12,
                                ),
                              ),
                              child: const Text(
                                'Post',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50], // Matched moderator page background
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // --- HEADER: iBrgy style (Edge to Edge) ---
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
                          Icon(
                            Icons.home,
                            color: Colors.blue.shade700,
                            size: 30,
                          ),
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
                      // Removed the Add button from here to match Moderator Page
                    ],
                  ),
                ),

                // --- SCROLLABLE BODY ---
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // --- SECTION HEADER: Text + Add Button ---
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Announcements',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            // Button moved here to match Community Info style
                            IconButton(
                              onPressed: _showCenteredCreatePostDialog,
                              icon: const Icon(Icons.add, size: 28),
                              color: Colors.blue,
                              tooltip: 'Post Update',
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // --- POSTS LIST ---
                        if (_posts.isEmpty)
                          Container(
                            height: 300,
                            alignment: Alignment.center,
                            child: const Text(
                              'NO ANNOUNCEMENTS POSTED',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black54,
                              ),
                            ),
                          )
                        else
                          for (var post in _posts) _buildPost(post),

                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // Inline composer overlay remains on top
            _buildInlineComposer(context),
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

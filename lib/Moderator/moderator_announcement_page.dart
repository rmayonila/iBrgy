import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'moderator_nav.dart';

class StaffAnnouncementPage extends StatefulWidget {
  const StaffAnnouncementPage({super.key});

  @override
  State<StaffAnnouncementPage> createState() => _StaffAnnouncementPageState();
}

class _StaffAnnouncementPageState extends State<StaffAnnouncementPage> {
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

  // (Optional: This modal method is kept if you need it elsewhere,
  // but the inline composer below is the one currently active).
  // ignore: unused_element
  void _showPostUpdateModal() {
    _postController.clear();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.blue,
                      child: const Icon(Icons.business, color: Colors.white),
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
                      child: const Text('Cancel'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _postController,
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
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Attach photo not implemented'),
                          ),
                        );
                      },
                      icon: const Icon(Icons.image, color: Colors.grey),
                    ),
                    // Location icon removed here as requested
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
        );
      },
    );
  }

  // New: show a centered fixed-position modal dialog for creating posts.
  // The dialog will remain centered even when the keyboard opens.
  void _showCenteredCreatePostDialog() {
    _postController.clear();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        // Prevent the dialog from shifting when the keyboard opens by
        // removing viewInsets from MediaQuery for this subtree.
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
                      // Use a fixed-height multiline TextField and ensure
                      // the hint and typed text start at the top-left.
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
    // unfocus
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
                            // --- UPDATED CANCEL BUTTON ---
                            TextButton(
                              onPressed: () => _closeInlineComposer(),
                              style: TextButton.styleFrom(
                                foregroundColor: const Color.fromARGB(
                                  221,
                                  232,
                                  74,
                                  74,
                                ), // Dark text
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

                            // --- LOCATION ICON REMOVED FROM HERE ---
                            const Spacer(),
                            // --- UPDATED POST BUTTON ---
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
                                foregroundColor: Colors.white, // White text
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
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with iBrgy logo and POST UPDATES button
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 5,
                          ),
                          child: Column(
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
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[700],
                                  letterSpacing: 0.6,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'Post Updates',
                          onPressed: _showCenteredCreatePostDialog,
                          icon: const Icon(Icons.add, color: Colors.blue),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 4),

                  // Posts — show immediately below the subtitle so announcements sit under the brand
                  // If no posts, show centered placeholder (matches staff style)
                  if (_posts.isEmpty)
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.55,
                      child: const Center(
                        child: Text(
                          'NO ANNOUNCEMENTS POSTED',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black54,
                          ),
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
          // inline composer overlay inside the phone frame
          _buildInlineComposer(context),
        ],
      ),
      floatingActionButton: null,
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

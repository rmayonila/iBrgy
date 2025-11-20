import 'package:flutter/material.dart';

class StaffAnnouncementPage extends StatefulWidget {
  const StaffAnnouncementPage({super.key});

  @override
  State<StaffAnnouncementPage> createState() => _StaffAnnouncementPageState();
}

class _StaffAnnouncementPageState extends State<StaffAnnouncementPage> {
  int _selectedIndex = 2;

  void _onItemTapped(int index) {
    if (index == 0) {
      Navigator.pushReplacementNamed(context, '/staff-home');
    } else if (index == 1) {
      Navigator.pushReplacementNamed(context, '/staff-emergency-hotline');
    } else if (index == 3) {
      Navigator.pushReplacementNamed(context, '/staff-brgy-officials');
    } else if (index == 4) {
      Navigator.pushReplacementNamed(context, '/staff-account-settings');
    } else {
      setState(() => _selectedIndex = index);
    }
  }

  // Posts state (start empty so placeholder shows)
  final List<Map<String, String>> _posts =
      []; // explicitly empty — no seeded posts

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
  }

  // (Optional: This modal method is kept if you need it elsewhere,
  // but the inline composer below is the one currently active).
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
                  decoration: InputDecoration(
                    hintText: 'What\'s happening in your barangay?',
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
                      onPressed: () {
                        final text = _postController.text.trim();
                        if (text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please write something'),
                            ),
                          );
                          return;
                        }
                        setState(() {
                          _posts.insert(0, {
                            'author': 'Barangay Office',
                            'time': 'Just now',
                            'content': text,
                          });
                        });
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(const SnackBar(content: Text('Posted')));
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

  void _onPostUpdatesPressed() {
    if (!mounted) return;
    // open the inline composer inside the phone frame
    _openInlineComposer();
  }

  void _openInlineComposer() {
    _postController.clear();
    setState(() {
      _isComposing = true;
    });
    // request focus after frame so keyboard opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) FocusScope.of(context).requestFocus(_composerFocusNode);
    });
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
            color: const Color.fromARGB(255, 250, 245, 245).withOpacity(0.03),
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
        color: Colors.black.withOpacity(0.45),
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
                          decoration: InputDecoration(
                            hintText: 'What\'s happening in your barangay?',
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
                              onPressed: () {
                                final text = _postController.text.trim();
                                if (text.isEmpty) {
                                  ScaffoldMessenger.of(ctx).showSnackBar(
                                    const SnackBar(
                                      content: Text('Please write something'),
                                    ),
                                  );
                                  return;
                                }
                                setState(() {
                                  _posts.insert(0, {
                                    'author': 'Barangay Office',
                                    'time': 'Just now',
                                    'content': text,
                                  });
                                });
                                _closeInlineComposer();
                                ScaffoldMessenger.of(ctx).showSnackBar(
                                  const SnackBar(content: Text('Posted')),
                                );
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
                          child: RichText(
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
                        ),
                        IconButton(
                          tooltip: 'Post Updates',
                          onPressed:
                              _showPostUpdateModal, // open modal composer so posts match attached layout
                          icon: const Icon(Icons.add, color: Colors.blue),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Page title
                  const Text(
                    'Barangay Updates',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),

                  // If no posts, show centered placeholder
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

                  const SizedBox(height: 40),
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

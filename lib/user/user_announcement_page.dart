// ignore_for_file: use_build_context_synchronously
import 'dart:convert'; // Required for image decoding
import 'package:flutter/foundation.dart'; // For web check
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // For logout
import 'package:cloud_firestore/cloud_firestore.dart';
import '../splash_screen.dart'; // Import your splash screen

class UserAnnouncementPage extends StatefulWidget {
  const UserAnnouncementPage({super.key});

  @override
  State<UserAnnouncementPage> createState() => _UserAnnouncementPageState();
}

class _UserAnnouncementPageState extends State<UserAnnouncementPage> {
  // 1. Stream for Regular Announcements
  final Stream<QuerySnapshot> _announcementsStream = FirebaseFirestore.instance
      .collection('announcements')
      .orderBy('createdAt', descending: true)
      .snapshots();

  // 2. Stream for Important Reminders
  final Stream<QuerySnapshot> _remindersStream = FirebaseFirestore.instance
      .collection('important_reminders')
      .orderBy('createdAt', descending: true)
      .snapshots();

  final TextEditingController _searchController = TextEditingController();

  // Key to force Snackbars/Dialogs to show INSIDE the phone frame if needed
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Navigation for User
  void _onItemTapped(BuildContext context, int index) {
    if (index == 0) {
      Navigator.pushReplacementNamed(context, '/user-home');
    } else if (index == 1) {
      Navigator.pushReplacementNamed(context, '/user-emergency-hotline');
    } else if (index == 3) {
      Navigator.pushReplacementNamed(context, '/user-brgy-officials');
    }
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp is Timestamp) {
      final date = timestamp.toDate();
      return "${date.month}/${date.day}/${date.year}";
    }
    return 'recently';
  }

  // --- EXIT / LOGOUT FUNCTION ---
  Future<void> _handleBackOrLogout() async {
    final shouldExit = await showDialog<bool>(
      context: context,
      useRootNavigator: false, // Keep inside phone frame
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Exit',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        content: const Text(
          'Are you sure you want to exit?',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.black87, fontSize: 14),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actionsPadding: const EdgeInsets.only(bottom: 16, left: 8, right: 8),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Exit',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (shouldExit == true) {
      try {
        await FirebaseAuth.instance.signOut();
      } catch (_) {}
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const SplashScreen()),
        (r) => false,
      );
    }
  }

  // --- HELPER: SHOW FULL IMAGE MODAL ---
  void _showFullImageDialog(BuildContext context, ImageProvider imageProvider) {
    showDialog(
      context: context,
      useRootNavigator: false, // Keep inside PhoneFrame
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero, // Full screen inside the frame
        child: Stack(
          alignment: Alignment.center,
          children: [
            // InteractiveViewer allows zooming/panning
            InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: Image(image: imageProvider, fit: BoxFit.contain),
            ),
            // Close Button
            Positioned(
              top: 20,
              right: 20,
              child: GestureDetector(
                onTap: () => Navigator.of(ctx).pop(),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 24),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- WIDGET BUILDERS ---

  Widget _buildHeader() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color.fromRGBO(0, 0, 0, 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
      // REVERTED to original Row structure
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.campaign_rounded,
              color: Colors.blue,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          RichText(
            text: TextSpan(
              children: [
                const TextSpan(
                  text: 'iB',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Colors.blue,
                    letterSpacing: -0.5,
                  ),
                ),
                TextSpan(
                  text: 'rgy',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Colors.blue.shade900,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: _handleBackOrLogout,
            icon: const Icon(Icons.logout, color: Colors.red),
            tooltip: "Exit",
          ),
        ],
      ),
    );
  }

  // --- NEW WIDGET: Instructional Note ---
  Widget _buildInstructionalNote() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Quick Guide',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.blue.shade900,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'The Barangay Updates provides the important reminders and recent updates from the barangay office.',
                  textAlign: TextAlign.justify,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.black87,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color.fromRGBO(0, 0, 0, 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (val) => setState(() {}),
        style: const TextStyle(color: Colors.black),
        decoration: InputDecoration(
          hintText: "Search updates...",
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
          prefixIcon: Icon(Icons.search, color: Colors.grey.shade400),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12, top: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.grey.shade600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  // --- IMPORTANT REMINDER CARD (User View) ---
  Widget _buildImportantReminderCard(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBE6), // Yellowish background
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFE58F), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFECB3),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.push_pin_rounded,
                    color: Colors.orange.shade900,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data['title'] ?? 'Reminder',
                        style: TextStyle(
                          color: Colors.orange.shade900,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Important Reminder',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              data['content'] ?? '',
              style: TextStyle(
                color: Colors.grey.shade800,
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyRemindersPlaceholder() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: const Color.fromRGBO(0, 0, 0, 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            Icons.notifications_off_outlined,
            size: 40,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 8),
          Text(
            'No important reminders yet.',
            style: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // --- RECENT UPDATE CARD (User View - With Expandable Text & Multiple Images) ---
  Widget _buildPostCard(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Support both old single image and new multiple images
    List<String> images = [];
    if (data['images'] != null && data['images'] is List) {
      images = List<String>.from(data['images']);
    } else if (data['imageUrl'] != null &&
        data['imageUrl'].toString().isNotEmpty) {
      // Backward compatibility
      images = [data['imageUrl'].toString()];
    }

    // Helper to build image grid
    Widget? buildImageGrid() {
      if (images.isEmpty) return null;

      List<Widget> imageWidgets = [];
      for (int i = 0; i < images.length; i++) {
        try {
          final imageProvider = MemoryImage(base64Decode(images[i]));
          imageWidgets.add(
            GestureDetector(
              onTap: () => _showFullImageDialog(context, imageProvider),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey.shade100,
                  image: DecorationImage(
                    image: imageProvider,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          );
        } catch (e) {
          // Skip invalid images
        }
      }

      if (imageWidgets.isEmpty) return null;

      // Layout based on number of images
      if (imageWidgets.length == 1) {
        return Container(
          margin: const EdgeInsets.only(top: 12),
          height: 200,
          child: imageWidgets[0],
        );
      } else if (imageWidgets.length == 2) {
        return Container(
          margin: const EdgeInsets.only(top: 12),
          height: 150,
          child: Row(
            children: [
              Expanded(child: imageWidgets[0]),
              const SizedBox(width: 4),
              Expanded(child: imageWidgets[1]),
            ],
          ),
        );
      } else if (imageWidgets.length == 3) {
        return Container(
          margin: const EdgeInsets.only(top: 12),
          child: Column(
            children: [
              SizedBox(height: 150, child: imageWidgets[0]),
              const SizedBox(height: 4),
              SizedBox(
                height: 100,
                child: Row(
                  children: [
                    Expanded(child: imageWidgets[1]),
                    const SizedBox(width: 4),
                    Expanded(child: imageWidgets[2]),
                  ],
                ),
              ),
            ],
          ),
        );
      } else {
        // 4 or more images
        return Container(
          margin: const EdgeInsets.only(top: 12),
          child: Column(
            children: [
              SizedBox(
                height: 150,
                child: Row(
                  children: [
                    Expanded(child: imageWidgets[0]),
                    const SizedBox(width: 4),
                    Expanded(child: imageWidgets[1]),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              SizedBox(
                height: 100,
                child: Row(
                  children: [
                    Expanded(child: imageWidgets[2]),
                    const SizedBox(width: 4),
                    Expanded(
                      child: imageWidgets.length > 3
                          ? imageWidgets[3]
                          : Container(color: Colors.grey.shade100),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color.fromRGBO(0, 0, 0, 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      (data['author']?.toString() ?? 'B')
                          .substring(0, 1)
                          .toUpperCase(),
                      style: const TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data['author']?.toString() ?? 'Barangay Office',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        data['createdAt'] != null
                            ? _formatTimestamp(data['createdAt'])
                            : 'recently',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Expandable Text Feature
            _ExpandableText(text: data['content']?.toString() ?? ''),

            // Multiple Images Grid
            if (buildImageGrid() != null) buildImageGrid()!,
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: const Color.fromRGBO(0, 0, 0, 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: 2,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey.shade400,
        backgroundColor: Colors.white,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        elevation: 0,
        onTap: (index) => _onItemTapped(context, index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.phone_rounded),
            label: 'Emergency',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.campaign_rounded),
            label: 'Updates',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_alt_rounded),
            label: 'People',
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget mobileContent = ScaffoldMessenger(
      key: _scaffoldMessengerKey,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSearchBar(),
                      const SizedBox(height: 20), // Adjusted spacing
                      _buildInstructionalNote(), // <<< NEW INSTRUCTIONAL NOTE
                      const SizedBox(height: 24),
                      const Text(
                        'Barangay Updates',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),

                      // --- SECTION 1: IMPORTANT REMINDERS ---
                      _buildSectionTitle("IMPORTANT REMINDERS"),
                      StreamBuilder<QuerySnapshot>(
                        stream: _remindersStream,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(8.0),
                                child: CircularProgressIndicator(),
                              ),
                            );
                          }
                          if (snapshot.hasError) {
                            return const Text('Something went wrong');
                          }

                          final docs = snapshot.data?.docs ?? [];
                          // Filter by search query
                          final searchQuery = _searchController.text
                              .toLowerCase();
                          final filteredDocs = docs.where((doc) {
                            final data = doc.data() as Map<String, dynamic>;
                            final title = (data['title'] ?? '')
                                .toString()
                                .toLowerCase();
                            final content = (data['content'] ?? '')
                                .toString()
                                .toLowerCase();
                            return title.contains(searchQuery) ||
                                content.contains(searchQuery);
                          }).toList();

                          if (filteredDocs.isEmpty) {
                            if (searchQuery.isNotEmpty) {
                              return const Center(
                                child: Text(
                                  "No reminders found",
                                  style: TextStyle(color: Colors.grey),
                                ),
                              );
                            }
                            return _buildEmptyRemindersPlaceholder();
                          }

                          return Column(
                            children: filteredDocs
                                .map((doc) => _buildImportantReminderCard(doc))
                                .toList(),
                          );
                        },
                      ),

                      const SizedBox(height: 24),

                      // --- SECTION 2: RECENT UPDATES ---
                      _buildSectionTitle("RECENT UPDATES"),
                      StreamBuilder<QuerySnapshot>(
                        stream: _announcementsStream,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Padding(
                              padding: EdgeInsets.all(20),
                              child: Center(child: CircularProgressIndicator()),
                            );
                          }
                          final docs = snapshot.data?.docs ?? [];
                          // Filter by search query
                          final searchQuery = _searchController.text
                              .toLowerCase();
                          final filteredDocs = docs.where((doc) {
                            final data = doc.data() as Map<String, dynamic>;
                            final content = (data['content'] ?? '')
                                .toString()
                                .toLowerCase();
                            return content.contains(searchQuery);
                          }).toList();

                          if (filteredDocs.isEmpty) {
                            return const Center(
                              child: Text(
                                "No updates found",
                                style: TextStyle(color: Colors.grey),
                              ),
                            );
                          }

                          return Column(
                            children: filteredDocs.map((doc) {
                              return _buildPostCard(doc);
                            }).toList(),
                          );
                        },
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: _buildBottomNavBar(),
      ),
    );

    if (kIsWeb) {
      return PhoneFrame(
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            scaffoldBackgroundColor: const Color(0xFFF8F9FA),
            primarySwatch: Colors.blue,
            useMaterial3: true,
          ),
          home: mobileContent,
        ),
      );
    }
    return mobileContent;
  }
}

// --- HELPER WIDGET FOR "SEE MORE / SEE LESS" ---
class _ExpandableText extends StatefulWidget {
  final String text;
  const _ExpandableText({required this.text});

  @override
  State<_ExpandableText> createState() => _ExpandableTextState();
}

class _ExpandableTextState extends State<_ExpandableText> {
  bool isExpanded = false;
  static const int maxLines = 3;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final span = TextSpan(
          text: widget.text,
          style: const TextStyle(
            fontSize: 14,
            height: 1.5,
            color: Color.fromRGBO(33, 33, 33, 0.8),
          ),
        );

        final tp = TextPainter(
          text: span,
          maxLines: maxLines,
          textDirection: TextDirection.ltr,
        );
        tp.layout(maxWidth: constraints.maxWidth);

        if (tp.didExceedMaxLines) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.text,
                maxLines: isExpanded ? null : maxLines,
                overflow: isExpanded
                    ? TextOverflow.visible
                    : TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: Color.fromRGBO(33, 33, 33, 0.8),
                ),
              ),
              const SizedBox(height: 4),
              GestureDetector(
                onTap: () {
                  setState(() {
                    isExpanded = !isExpanded;
                  });
                },
                child: Text(
                  isExpanded ? "See Less" : "See More",
                  style: const TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          );
        } else {
          return Text(
            widget.text,
            style: const TextStyle(
              fontSize: 14,
              height: 1.5,
              color: Color.fromRGBO(33, 33, 33, 0.8),
            ),
          );
        }
      },
    );
  }
}

// --- PHONE FRAME WRAPPER ---
class PhoneFrame extends StatelessWidget {
  final Widget child;
  const PhoneFrame({super.key, required this.child});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      body: Center(
        child: Container(
          width: 375,
          height: 812,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(40),
            boxShadow: [
              BoxShadow(
                color: const Color.fromRGBO(0, 0, 0, 0.1),
                blurRadius: 30,
                spreadRadius: 5,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(40),
            child: child,
          ),
        ),
      ),
    );
  }
}

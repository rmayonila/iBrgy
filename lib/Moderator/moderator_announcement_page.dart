import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart'; // For kIsWeb check
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart'; // Required
import 'moderator_nav.dart';

class ModeratorAnnouncementPage extends StatefulWidget {
  const ModeratorAnnouncementPage({super.key});

  @override
  State<ModeratorAnnouncementPage> createState() =>
      _ModeratorAnnouncementPageState();
}

class _ModeratorAnnouncementPageState extends State<ModeratorAnnouncementPage> {
  int _selectedIndex = 2;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _searchController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  // Key to force SnackBars to show INSIDE the phone frame
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    navigateModeratorIndex(
      context,
      index,
      currentIndex: _selectedIndex,
      onSamePage: (i) => setState(() => _selectedIndex = i),
    );
  }

  Future<void> _ensureSignedIn() async {
    try {
      if (_auth.currentUser == null) {
        await _auth.signInAnonymously();
      }
    } catch (e) {
      // ignore sign-in errors
    }
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp is Timestamp) {
      final date = timestamp.toDate();
      return "${date.month}/${date.day}/${date.year}";
    }
    return 'recently';
  }

  // --- HELPER: CONVERT IMAGE TO BASE64 ---
  Future<String> _imageToBase64(XFile imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      return base64Encode(bytes);
    } catch (e) {
      return '';
    }
  }

  // --- CRUD: IMPORTANT REMINDERS ---

  Future<void> _showAddReminderDialog({DocumentSnapshot? existingDoc}) async {
    final isEditing = existingDoc != null;
    final titleController = TextEditingController(
      text: isEditing ? existingDoc['title'] : '',
    );
    final contentController = TextEditingController(
      text: isEditing ? existingDoc['content'] : '',
    );

    InputDecoration buildInputDecoration({
      required String label,
      required String hint,
      required IconData icon,
    }) {
      return InputDecoration(
        labelText: label,
        hintText: hint,
        filled: true,
        fillColor: Colors.grey.shade50,
        prefixIcon: Icon(icon, color: Colors.orange.shade800),
        labelStyle: TextStyle(color: Colors.grey.shade700),
        hintStyle: TextStyle(color: Colors.grey.shade400),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 20,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.orange.shade800, width: 2),
        ),
      );
    }

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
        contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
        actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.push_pin_rounded,
                color: Colors.orange.shade800,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                isEditing ? 'Edit Reminder' : 'Add Reminder',
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                style: const TextStyle(color: Colors.black87),
                decoration: buildInputDecoration(
                  label: 'Title',
                  hint: 'e.g. Office Hours',
                  icon: Icons.title_rounded,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: contentController,
                style: const TextStyle(color: Colors.black87),
                maxLines: 4,
                decoration: buildInputDecoration(
                  label: 'Content',
                  hint: 'Enter reminder details...',
                  icon: Icons.description_outlined,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            style: TextButton.styleFrom(foregroundColor: Colors.grey.shade700),
            child: const Text(
              'Cancel',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              final title = titleController.text.trim();
              final content = contentController.text.trim();

              if (title.isEmpty || content.isEmpty) {
                _scaffoldMessengerKey.currentState?.showSnackBar(
                  const SnackBar(content: Text('Please fill all fields')),
                );
                return;
              }

              Navigator.of(ctx).pop();

              try {
                await _ensureSignedIn();
                if (isEditing) {
                  await _db
                      .collection('important_reminders')
                      .doc(existingDoc.id)
                      .update({
                        'title': title,
                        'content': content,
                        'updatedAt': FieldValue.serverTimestamp(),
                      });
                  _scaffoldMessengerKey.currentState?.showSnackBar(
                    const SnackBar(content: Text('Reminder updated')),
                  );
                } else {
                  await _db.collection('important_reminders').add({
                    'title': title,
                    'content': content,
                    'createdAt': FieldValue.serverTimestamp(),
                    'author': 'Admin',
                  });
                  _scaffoldMessengerKey.currentState?.showSnackBar(
                    const SnackBar(content: Text('Reminder added')),
                  );
                }
              } catch (e) {
                _scaffoldMessengerKey.currentState?.showSnackBar(
                  SnackBar(content: Text('Error: $e')),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange.shade800,
              foregroundColor: Colors.white,
              elevation: 2,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: const StadiumBorder(),
            ),
            icon: const Icon(Icons.check, size: 18),
            label: Text(
              isEditing ? 'Update' : 'Post',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteReminder(String docId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Reminder'),
        content: const Text('Are you sure you want to delete this reminder?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _db.collection('important_reminders').doc(docId).delete();
      _scaffoldMessengerKey.currentState?.showSnackBar(
        const SnackBar(content: Text('Reminder deleted')),
      );
    }
  }

  // --- CRUD: REGULAR UPDATES (With Image) ---

  Future<void> _showUpdateDialog({DocumentSnapshot? existingDoc}) async {
    final isEditing = existingDoc != null;
    final data = isEditing ? existingDoc.data() as Map<String, dynamic> : {};

    final contentController = TextEditingController(
      text: data['content'] ?? '',
    );

    String? currentImageBase64 = data['imageUrl'];
    XFile? pickedImageFile;

    // Reusable Decoration
    InputDecoration buildBlueDecoration({
      required String label,
      required String hint,
    }) {
      return InputDecoration(
        labelText: label,
        hintText: hint,
        alignLabelWithHint: true,
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: const EdgeInsets.all(16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.blue, width: 2),
        ),
      );
    }

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          // Helper to show selected image
          Widget buildImagePreview() {
            ImageProvider? provider;
            if (pickedImageFile != null) {
              if (kIsWeb) {
                provider = NetworkImage(pickedImageFile!.path);
              } else {
                provider = FileImage(File(pickedImageFile!.path));
              }
            } else if (currentImageBase64 != null &&
                currentImageBase64!.isNotEmpty) {
              try {
                provider = MemoryImage(base64Decode(currentImageBase64!));
              } catch (e) {
                // ignore error
              }
            }

            if (provider != null) {
              return Stack(
                children: [
                  Container(
                    height: 150,
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                      image: DecorationImage(
                        image: provider,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () {
                        setDialogState(() {
                          pickedImageFile = null;
                          currentImageBase64 = null;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }
            return const SizedBox.shrink();
          }

          return AlertDialog(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    isEditing ? Icons.edit_rounded : Icons.campaign_rounded,
                    color: Colors.blue,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    isEditing ? 'Edit Update' : 'Create Update',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  buildImagePreview(),
                  TextField(
                    controller: contentController,
                    maxLines: 5,
                    style: const TextStyle(fontSize: 15),
                    decoration: buildBlueDecoration(
                      label: 'Content',
                      hint: "What's happening in the barangay?",
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              Row(
                children: [
                  // --- ADD PHOTO BUTTON (Bottom Left) ---
                  IconButton(
                    onPressed: () async {
                      final XFile? image = await _picker.pickImage(
                        source: ImageSource.gallery,
                        imageQuality: 50,
                        maxWidth: 600,
                      );
                      if (image != null) {
                        setDialogState(() {
                          pickedImageFile = image;
                        });
                      }
                    },
                    icon: const Icon(
                      Icons.add_photo_alternate_rounded,
                      color: Colors.blue,
                      size: 28,
                    ),
                    tooltip: 'Add Photo',
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    style: TextButton.styleFrom(foregroundColor: Colors.grey),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () async {
                      final content = contentController.text.trim();
                      if (content.isEmpty &&
                          pickedImageFile == null &&
                          currentImageBase64 == null) {
                        // Allow post if only image exists, or only text exists
                        // But reject if both empty
                        return;
                      }

                      Navigator.of(ctx).pop();

                      try {
                        await _ensureSignedIn();

                        // Handle Image
                        String finalImageString = currentImageBase64 ?? '';
                        if (pickedImageFile != null) {
                          finalImageString = await _imageToBase64(
                            pickedImageFile!,
                          );
                        }

                        if (isEditing) {
                          await _db
                              .collection('announcements')
                              .doc(existingDoc.id)
                              .update({
                                'content': content,
                                'imageUrl': finalImageString,
                                'updatedAt': FieldValue.serverTimestamp(),
                              });
                          _scaffoldMessengerKey.currentState?.showSnackBar(
                            const SnackBar(
                              content: Text('Update edited successfully'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        } else {
                          await _db.collection('announcements').add({
                            'author': 'Barangay Office',
                            'content': content,
                            'imageUrl': finalImageString,
                            'createdAt': FieldValue.serverTimestamp(),
                          });
                          _scaffoldMessengerKey.currentState?.showSnackBar(
                            const SnackBar(
                              content: Text('Posted successfully'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      } catch (e) {
                        _scaffoldMessengerKey.currentState?.showSnackBar(
                          const SnackBar(
                            content: Text('Error posting update'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      shape: const StadiumBorder(),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                    ),
                    child: Text(
                      isEditing ? 'Save' : 'Post',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _deleteUpdate(String docId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Update'),
        content: const Text('Are you sure you want to delete this post?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _db.collection('announcements').doc(docId).delete();
      _scaffoldMessengerKey.currentState?.showSnackBar(
        const SnackBar(
          content: Text('Post deleted'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  // --- WIDGETS ---

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
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
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
            onPressed: () {},
            icon: const Icon(
              Icons.notifications_none_rounded,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  // --- SECTION HEADER ---
  // Used for both "IMPORTANT REMINDERS" and "RECENT UPDATES"
  Widget _buildSectionTitle(String title, VoidCallback? onAdd) {
    final isReminder = title.contains("REMINDERS");
    final color = isReminder ? Colors.orange.shade800 : Colors.blue;

    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12, top: 8),
      child: Row(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
              letterSpacing: 0.5,
            ),
          ),
          const Spacer(),
          if (onAdd != null)
            // Both buttons now use the same style: Icon only
            IconButton(
              onPressed: onAdd,
              icon: Icon(
                Icons.add, // Consistent icon style
                size: 28,
                color: color,
              ),
              tooltip: 'Add Item',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
        ],
      ),
    );
  }

  Widget _buildImportantReminderCard(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBE6),
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
                PopupMenuButton<String>(
                  padding: EdgeInsets.zero,
                  icon: Icon(Icons.more_horiz, color: Colors.grey.shade500),
                  color: Colors.white,
                  onSelected: (value) {
                    if (value == 'edit') {
                      _showAddReminderDialog(existingDoc: doc);
                    } else if (value == 'delete') {
                      _deleteReminder(doc.id);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(
                            Icons.edit,
                            size: 18,
                            color: Colors.black87,
                          ), // Black icon
                          SizedBox(width: 8),
                          Text(
                            'Edit',
                            style: TextStyle(color: Colors.black87),
                          ), // Black text
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: Colors.red, size: 18),
                          SizedBox(width: 8),
                          Text('Delete', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
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
            color: Colors.black.withOpacity(0.02),
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

  Widget _buildPostCard(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final imageUrl = data['imageUrl']?.toString() ?? '';

    // Helper to decode image string
    ImageProvider? getPostImage() {
      if (imageUrl.isEmpty) return null;
      try {
        return MemoryImage(base64Decode(imageUrl));
      } catch (e) {
        return null;
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
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
                      (data['author']?.toString() ?? 'U')
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
                        data['author']?.toString() ?? 'Unknown',
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
                // 6. & 7. THREE-DOT MENU FOR EDIT/DELETE
                PopupMenuButton<String>(
                  padding: EdgeInsets.zero,
                  icon: Icon(Icons.more_horiz, color: Colors.grey.shade400),
                  onSelected: (value) {
                    if (value == 'edit') {
                      _showUpdateDialog(existingDoc: doc);
                    } else if (value == 'delete') {
                      _deleteUpdate(doc.id);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 20, color: Colors.black87),
                          SizedBox(width: 8),
                          Text('Edit', style: TextStyle(color: Colors.black87)),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 20, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Delete', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              data['content']?.toString() ?? '',
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: Colors.black87.withOpacity(0.8),
              ),
            ),
            // Display Image if available
            if (getPostImage() != null) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                height: 180,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.grey.shade100,
                  image: DecorationImage(
                    image: getPostImage()!,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ],
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
            color: Colors.black.withOpacity(0.05),
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
        onTap: _onItemTapped,
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
          BottomNavigationBarItem(
            icon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldMessenger(
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
                      // Search Bar
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.03),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: "Search updates...",
                            hintStyle: TextStyle(
                              color: Colors.grey.shade400,
                              fontSize: 14,
                            ),
                            prefixIcon: Icon(
                              Icons.search,
                              color: Colors.grey.shade400,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 14,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Barangay Updates',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // --- SECTION 1: IMPORTANT REMINDERS (Dynamic Stream) ---
                      _buildSectionTitle(
                        "IMPORTANT REMINDERS",
                        () => _showAddReminderDialog(),
                      ),
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

                          if (docs.isEmpty) {
                            return _buildEmptyRemindersPlaceholder();
                          }

                          return Column(
                            children: docs
                                .map((doc) => _buildImportantReminderCard(doc))
                                .toList(),
                          );
                        },
                      ),

                      const SizedBox(height: 24),

                      // --- SECTION 2: RECENT UPDATES (Dynamic Stream) ---
                      _buildSectionTitle(
                        "RECENT UPDATES",
                        () => _showUpdateDialog(),
                      ),
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
                          if (docs.isEmpty) {
                            return const Center(
                              child: Text(
                                "No recent updates",
                                style: TextStyle(color: Colors.grey),
                              ),
                            );
                          }

                          final searchQuery = _searchController.text
                              .toLowerCase();
                          final filteredDocs = docs.where((doc) {
                            final data = doc.data() as Map<String, dynamic>;
                            final content = (data['content'] ?? '')
                                .toString()
                                .toLowerCase();
                            return content.contains(searchQuery);
                          }).toList();

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
  }
}

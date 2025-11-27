import 'dart:convert'; // Needed for Base64 images
import 'dart:io';
import 'package:flutter/foundation.dart'; // For kIsWeb check
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart'; // Required for gallery
import 'moderator_nav.dart';

class ModeratorBrgyOfficialsPage extends StatefulWidget {
  const ModeratorBrgyOfficialsPage({super.key});

  @override
  State<ModeratorBrgyOfficialsPage> createState() =>
      _ModeratorBrgyOfficialsPageState();
}

class _ModeratorBrgyOfficialsPageState
    extends State<ModeratorBrgyOfficialsPage> {
  int _selectedIndex = 3; // People tab
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  final ImagePicker _picker = ImagePicker();

  // Key to force SnackBars to show INSIDE the phone frame
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  // Stream for Officials
  final Stream<QuerySnapshot> _officialsStream = FirebaseFirestore.instance
      .collection('officials')
      .orderBy('createdAt', descending: true)
      .snapshots();

  // Stream for Contact Info
  final Stream<QuerySnapshot> _contactsStream = FirebaseFirestore.instance
      .collection('official_contacts')
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

  void _updateSearch(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
    });
  }

  // --- HELPER: CONVERT IMAGE TO BASE64 STRING ---
  // This solves the "Storage not working" issue by saving image data directly to Firestore text.
  Future<String> _imageToBase64(XFile imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      return base64Encode(bytes);
    } catch (e) {
      return '';
    }
  }

  // --- UNIFIED DIALOG (ADD & EDIT) ---
  Future<void> _showOfficialDialog({DocumentSnapshot? existingDoc}) async {
    final isEditing = existingDoc != null;
    final data = isEditing ? existingDoc.data() as Map<String, dynamic> : {};

    final titleController = TextEditingController(text: data['title'] ?? '');
    final nameController = TextEditingController(text: data['name'] ?? '');
    final categoryController = TextEditingController(
      text: data['category'] ?? '',
    );

    String? currentImageBase64 = data['imageUrl']; // Can be URL or Base64
    XFile? pickedImageFile;

    // Reusable decoration
    InputDecoration buildDecoration(String label, String hint, IconData icon) {
      return InputDecoration(
        labelText: label,
        hintText: hint,
        filled: true,
        fillColor: Colors.grey.shade50,
        prefixIcon: Icon(icon, color: Colors.blue.shade700),
        labelStyle: TextStyle(color: Colors.grey.shade700),
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
          borderSide: BorderSide(color: Colors.blue.shade700, width: 2),
        ),
      );
    }

    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          // Helper to decide what image provider to show
          ImageProvider? getImageProvider() {
            if (pickedImageFile != null) {
              // 1. User just picked a new photo from gallery
              if (kIsWeb) {
                return NetworkImage(pickedImageFile!.path);
              } else {
                return FileImage(File(pickedImageFile!.path));
              }
            } else if (currentImageBase64 != null &&
                currentImageBase64!.isNotEmpty) {
              // 2. Existing photo from database
              try {
                // Check if it's a URL (http) or Base64 data
                if (currentImageBase64!.startsWith('http')) {
                  return NetworkImage(currentImageBase64!);
                } else {
                  return MemoryImage(base64Decode(currentImageBase64!));
                }
              } catch (e) {
                return null;
              }
            }
            return null;
          }

          return AlertDialog(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
            contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    isEditing
                        ? Icons.edit_rounded
                        : Icons.person_add_alt_1_rounded,
                    color: Colors.blue.shade700,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    isEditing ? 'Edit Official' : 'Add Official',
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
                  // --- IMAGE PICKER (Gallery Access) ---
                  GestureDetector(
                    onTap: () async {
                      // Opens the device's Photo Gallery/File Explorer
                      final XFile? image = await _picker.pickImage(
                        source: ImageSource.gallery,
                        imageQuality: 50, // Low quality to save DB space
                        maxWidth: 400, // Resize to keep string short
                      );
                      if (image != null) {
                        setDialogState(() {
                          pickedImageFile = image;
                        });
                      }
                    },
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.blue.shade200,
                          width: 2,
                        ),
                        image: getImageProvider() != null
                            ? DecorationImage(
                                image: getImageProvider()!,
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: getImageProvider() == null
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.add_a_photo_rounded,
                                  color: Colors.grey.shade400,
                                  size: 28,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "Select Photo",
                                  style: TextStyle(
                                    color: Colors.grey.shade500,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            )
                          : Stack(
                              children: [
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: Colors.blue,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.edit,
                                      color: Colors.white,
                                      size: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  TextField(
                    controller: categoryController,
                    style: const TextStyle(color: Colors.black87),
                    decoration: buildDecoration(
                      'Category',
                      'e.g., Punong Barangay',
                      Icons.category_outlined,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: titleController,
                    style: const TextStyle(color: Colors.black87),
                    decoration: buildDecoration(
                      'Position Title',
                      'e.g., Barangay Captain',
                      Icons.work_outline_rounded,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nameController,
                    style: const TextStyle(color: Colors.black87),
                    decoration: buildDecoration(
                      'Full Name',
                      'e.g., Juan Dela Cruz',
                      Icons.person_outline_rounded,
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.grey.shade700,
                ),
                child: const Text(
                  'Cancel',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () async {
                  final category = categoryController.text.trim();
                  final title = titleController.text.trim();
                  final name = nameController.text.trim();

                  if (category.isEmpty || title.isEmpty || name.isEmpty) {
                    _scaffoldMessengerKey.currentState?.showSnackBar(
                      const SnackBar(
                        content: Text('Please fill all fields'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  Navigator.of(
                    ctx,
                  ).pop(); // Close dialog to show loading/result

                  try {
                    // Handle Image Conversion
                    String finalImageString = currentImageBase64 ?? '';
                    if (pickedImageFile != null) {
                      // Convert new image to Base64
                      finalImageString = await _imageToBase64(pickedImageFile!);
                    }

                    if (isEditing) {
                      await _db
                          .collection('officials')
                          .doc(existingDoc.id)
                          .update({
                            'category': category,
                            'title': title,
                            'name': name,
                            'imageUrl': finalImageString,
                            'updatedAt': FieldValue.serverTimestamp(),
                          });
                      _scaffoldMessengerKey.currentState?.showSnackBar(
                        const SnackBar(
                          content: Text('Official updated'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } else {
                      await _db.collection('officials').add({
                        'category': category,
                        'title': title,
                        'name': name,
                        'imageUrl': finalImageString,
                        'createdAt': FieldValue.serverTimestamp(),
                      });
                      _scaffoldMessengerKey.currentState?.showSnackBar(
                        const SnackBar(
                          content: Text('Official added'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } catch (e) {
                    _scaffoldMessengerKey.currentState?.showSnackBar(
                      SnackBar(
                        content: Text('Error: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade700,
                  foregroundColor: Colors.white,
                  elevation: 2,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: const StadiumBorder(),
                ),
                icon: const Icon(Icons.check_rounded, size: 20),
                label: Text(
                  isEditing ? 'Save Changes' : 'Add Official',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // DELETE Official
  Future<void> _deleteOfficial(String docId, String title) async {
    final confirmDelete = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Deletion'),
        content: Text('Are you sure you want to delete "$title"?'),
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

    if (confirmDelete == true) {
      try {
        await _db.collection('officials').doc(docId).delete();
        _scaffoldMessengerKey.currentState?.showSnackBar(
          const SnackBar(
            content: Text('Official deleted'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        _scaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(
            content: Text('Failed to delete: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // EDIT Contact Info
  Future<void> _editContactInfo(
    String category,
    String field,
    String label,
    String currentValue,
  ) async {
    final inputController = TextEditingController(text: currentValue);

    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Edit $label'),
        content: TextField(
          controller: inputController,
          decoration: InputDecoration(hintText: 'Enter $label'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(null),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(inputController.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    inputController.dispose();

    if (result != null) {
      try {
        await _db.collection('official_contacts').doc(category).set({
          field: result,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        _scaffoldMessengerKey.currentState?.showSnackBar(
          const SnackBar(
            content: Text('Contact updated'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        _scaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(
            content: Text('Failed to update contact info: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
              Icons.people_alt_rounded,
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
        ],
      ),
    );
  }

  Widget _buildBanner() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade700, Colors.blue.shade500],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Meet Your Leaders",
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Dedicated to serving the community with integrity and transparency.",
            style: TextStyle(color: Colors.blue.shade50, fontSize: 14),
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
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: _updateSearch,
        decoration: InputDecoration(
          hintText: "Search official...",
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

  Widget _buildOfficialCard(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final docId = doc.id;
    final title = data['title']?.toString() ?? '';
    final name = data['name']?.toString() ?? '';
    final imageUrl = data['imageUrl']?.toString() ?? '';

    // Helper to decode image string
    ImageProvider? getProfileImage() {
      if (imageUrl.isEmpty) return null;
      try {
        if (imageUrl.startsWith('http')) {
          return NetworkImage(imageUrl);
        } else {
          // It's a base64 string
          return MemoryImage(base64Decode(imageUrl));
        }
      } catch (e) {
        return null;
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
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
      child: Row(
        children: [
          // Profile Image
          CircleAvatar(
            radius: 24,
            backgroundColor: Colors.blue.shade50,
            backgroundImage: getProfileImage(),
            child: getProfileImage() == null
                ? Text(
                    name.isNotEmpty ? name.substring(0, 1).toUpperCase() : '?',
                    style: TextStyle(
                      color: Colors.blue.shade700,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue.shade700,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          // MENU BUTTON (Edit/Delete)
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'edit') {
                // 1. Open the Full Edit Dialog
                _showOfficialDialog(existingDoc: doc);
              } else if (value == 'delete') {
                // 2. Delete
                _deleteOfficial(docId, title);
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(
                      Icons.edit_rounded,
                      size: 20,
                      color: Colors.blue.shade700,
                    ),
                    const SizedBox(width: 8),
                    const Text('Edit'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(
                      Icons.delete_outline_rounded,
                      size: 20,
                      color: Colors.red,
                    ),
                    const SizedBox(width: 8),
                    Text('Delete', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
            icon: Icon(Icons.more_vert, color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }

  Widget _buildContactInfoCard(String category, Map<String, dynamic> contacts) {
    final address = contacts['address']?.toString() ?? '';
    final hours = contacts['hours']?.toString() ?? '';
    final phone = contacts['contacts']?.toString() ?? '';

    if (address.isEmpty && hours.isEmpty && phone.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(top: 4, bottom: 20),
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F7FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (address.isNotEmpty) ...[
            _buildContactRow(
              Icons.location_on_outlined,
              'Address',
              address,
              onEdit: () =>
                  _editContactInfo(category, 'address', 'Address', address),
            ),
            const SizedBox(height: 12),
          ],
          if (hours.isNotEmpty) ...[
            _buildContactRow(
              Icons.access_time,
              'Office Hours',
              hours,
              onEdit: () =>
                  _editContactInfo(category, 'hours', 'Office Hours', hours),
            ),
            const SizedBox(height: 12),
          ],
          if (phone.isNotEmpty) ...[
            _buildContactRow(
              Icons.phone_outlined,
              'Contact',
              phone,
              onEdit: () =>
                  _editContactInfo(category, 'contacts', 'Contact', phone),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildContactRow(
    IconData icon,
    String label,
    String value, {
    VoidCallback? onEdit,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.blue.shade400),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade800,
                    ),
                  ),
                  const Spacer(),
                  if (onEdit != null)
                    IconButton(
                      onPressed: onEdit,
                      icon: Icon(
                        Icons.edit,
                        size: 16,
                        color: Colors.blue.shade600,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(fontSize: 13, color: Colors.black87),
              ),
            ],
          ),
        ),
      ],
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
        currentIndex: _selectedIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey.shade400,
        backgroundColor: Colors.white,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        selectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
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
    // Ensure snackbars show inside this scaffold context
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
                      _buildSearchBar(),
                      const SizedBox(height: 24),
                      _buildBanner(),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "Barangay Officials",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            IconButton(
                              onPressed: () => _showOfficialDialog(),
                              icon: const Icon(Icons.add, size: 24),
                              color: Colors.blue,
                              tooltip: 'Add Official',
                            ),
                          ],
                        ),
                      ),

                      // --- OFFICIALS STREAM ---
                      StreamBuilder<QuerySnapshot>(
                        stream: _officialsStream,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(40),
                                child: CircularProgressIndicator(),
                              ),
                            );
                          }

                          final officialDocs = snapshot.data?.docs ?? [];

                          if (officialDocs.isEmpty) {
                            if (_searchQuery.isNotEmpty) {
                              return Center(
                                child: Padding(
                                  padding: const EdgeInsets.only(top: 20),
                                  child: Text(
                                    "No matching officials found",
                                    style: TextStyle(color: Colors.grey[500]),
                                  ),
                                ),
                              );
                            }
                            // Empty Placeholder
                            return Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.people_outline,
                                    size: 40,
                                    color: Colors.grey.shade300,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    "No officials added yet",
                                    style: TextStyle(
                                      color: Colors.grey.shade500,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "Tap + to add new officials",
                                    style: TextStyle(
                                      color: Colors.grey.shade400,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }

                          // Filter and Group Data
                          final Map<String, List<DocumentSnapshot>> grouped =
                              {};
                          for (var doc in officialDocs) {
                            final data = doc.data() as Map<String, dynamic>;
                            final name = (data['name'] ?? '')
                                .toString()
                                .toLowerCase();
                            final title = (data['title'] ?? '')
                                .toString()
                                .toLowerCase();
                            final category =
                                (data['category'] ?? 'Uncategorized')
                                    .toString();

                            if (_searchQuery.isEmpty ||
                                name.contains(_searchQuery) ||
                                title.contains(_searchQuery)) {
                              if (!grouped.containsKey(category)) {
                                grouped[category] = [];
                              }
                              grouped[category]!.add(doc);
                            }
                          }

                          if (grouped.isEmpty) {
                            return Center(
                              child: Padding(
                                padding: const EdgeInsets.only(top: 20),
                                child: Text(
                                  "No matching officials found",
                                  style: TextStyle(color: Colors.grey[500]),
                                ),
                              ),
                            );
                          }

                          // --- CONTACTS STREAM (Nested) ---
                          return StreamBuilder<QuerySnapshot>(
                            stream: _contactsStream,
                            builder: (ctx, contactSnap) {
                              final contactDocs = contactSnap.data?.docs ?? [];
                              final Map<String, Map<String, dynamic>> contacts =
                                  {};
                              for (var d in contactDocs) {
                                contacts[d.id] =
                                    d.data() as Map<String, dynamic>;
                              }

                              return Column(
                                children: grouped.entries.map((entry) {
                                  final category = entry.key;
                                  final docs = entry.value;
                                  final categoryContacts =
                                      contacts[category] ??
                                      {
                                        // Defaults
                                        'address': '',
                                        'hours': '',
                                        'contacts': '',
                                      };

                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 12.0,
                                          left: 4,
                                        ),
                                        child: Text(
                                          category,
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.grey.shade600,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ),
                                      ...docs.map(
                                        (doc) => _buildOfficialCard(doc),
                                      ),
                                      _buildContactInfoCard(
                                        category,
                                        categoryContacts,
                                      ),
                                    ],
                                  );
                                }).toList(),
                              );
                            },
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

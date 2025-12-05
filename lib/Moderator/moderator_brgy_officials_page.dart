// ignore_for_file: use_build_context_synchronously
import 'dart:convert'; // Needed for Base64 images
import 'dart:io';
import 'package:flutter/foundation.dart'; // For kIsWeb check
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart'; // Required for gallery

// ▼▼▼ CHANGED: Imported the correct service ▼▼▼
import '../services/activity_service.dart';
// ▲▲▲ END CHANGE ▲▲▲

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
    // Standard Navigation logic
    if (index == 0) {
      Navigator.pushReplacementNamed(context, '/moderator-home');
    } else if (index == 1) {
      Navigator.pushReplacementNamed(context, '/moderator-emergency-hotline');
    } else if (index == 2) {
      Navigator.pushReplacementNamed(context, '/moderator-announcement');
    } else if (index == 4) {
      Navigator.pushReplacementNamed(context, '/moderator-account-settings');
    }
    setState(() {
      _selectedIndex = index;
    });
  }

  void _updateSearch(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
    });
  }

  // --- HELPER: CONVERT IMAGE TO BASE64 STRING ---
  Future<String> _imageToBase64(XFile imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      return base64Encode(bytes);
    } catch (e) {
      return '';
    }
  }

  // --- HELPER: SHOW CUSTOM SNACKBAR ---
  void _showSnackBar(String message, {bool isError = false}) {
    _scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
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
    final nicknameController = TextEditingController(
      text: data['nickname'] ?? '',
    );
    final ageController = TextEditingController(
      text: data['age']?.toString() ?? '',
    );
    final addressController = TextEditingController(
      text: data['address'] ?? '',
    );

    String? currentImageBase64 = data['imageUrl'];
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
      useRootNavigator: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          ImageProvider? getImageProvider() {
            if (pickedImageFile != null) {
              if (kIsWeb) {
                return NetworkImage(pickedImageFile!.path);
              } else {
                return FileImage(File(pickedImageFile!.path));
              }
            } else if (currentImageBase64 != null &&
                currentImageBase64!.isNotEmpty) {
              try {
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
                  // --- IMAGE PICKER ---
                  GestureDetector(
                    onTap: () async {
                      final XFile? image = await _picker.pickImage(
                        source: ImageSource.gallery,
                        imageQuality: 50,
                        maxWidth: 400,
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
                  const SizedBox(height: 16),
                  TextField(
                    controller: nicknameController,
                    style: const TextStyle(color: Colors.black87),
                    decoration: buildDecoration(
                      'Nickname / Alias',
                      'e.g., Kap Juan',
                      Icons.face_rounded,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: ageController,
                    style: const TextStyle(color: Colors.black87),
                    keyboardType: TextInputType.number,
                    decoration: buildDecoration(
                      'Age',
                      'e.g., 45',
                      Icons.calendar_today_rounded,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: addressController,
                    style: const TextStyle(color: Colors.black87),
                    decoration: buildDecoration(
                      'Address',
                      'e.g., Purok 1, Poblacion',
                      Icons.location_on_outlined,
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
                  final nickname = nicknameController.text.trim();
                  final age = ageController.text.trim();
                  final address = addressController.text.trim();
                  if (category.isEmpty || title.isEmpty || name.isEmpty) {
                    _showSnackBar(
                      'Category, Position Title, and Name are required.',
                      isError: true,
                    );
                    return;
                  }

                  Navigator.of(ctx).pop();
                  // Close dialog

                  try {
                    String finalImageString = currentImageBase64 ?? '';
                    if (pickedImageFile != null) {
                      finalImageString = await _imageToBase64(pickedImageFile!);
                    }

                    final dataToSave = {
                      'category': category,
                      'title': title,
                      'name': name,
                      'nickname': nickname,
                      'age': age,
                      'address': address,
                      'imageUrl': finalImageString,
                      if (!isEditing) 'createdAt': FieldValue.serverTimestamp(),
                      if (isEditing) 'updatedAt': FieldValue.serverTimestamp(),
                    };
                    if (isEditing) {
                      await _db
                          .collection('officials')
                          .doc(existingDoc!.id)
                          .update(dataToSave);

                      // ▼▼▼ TRACKING: EDIT OFFICIAL ▼▼▼
                      await ActivityService().logActivity(
                        context,
                        actionTitle: 'Edited Official',
                        details: 'Updated profile for: $name ($title)',
                      );
                      // ▲▲▲ END TRACKING ▲▲▲

                      _showSnackBar('Official updated successfully');
                    } else {
                      await _db.collection('officials').add(dataToSave);

                      // ▼▼▼ TRACKING: ADD OFFICIAL ▼▼▼
                      await ActivityService().logActivity(
                        context,
                        actionTitle: 'Added Official',
                        details: 'Added new official: $name ($title)',
                      );
                      // ▲▲▲ END TRACKING ▲▲▲

                      _showSnackBar('Official added successfully');
                    }
                  } catch (e) {
                    _showSnackBar('Error: $e', isError: true);
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

  // --- DELETE OFFICIAL ---
  Future<void> _deleteOfficial(String docId, String officialName) async {
    final confirmDelete = await showDialog<bool>(
      context: context,
      useRootNavigator: false, // Inside frame
      builder: (ctx) => Padding(
        // Ensure dialog respects outer constraints
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          // Use rounded corners to match the image
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),

          title: Text(
            'Confirm Deletion',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontWeight: FontWeight.bold,
              fontSize: 22,
            ),
          ),
          content: Text(
            'Are you sure you want to delete "$officialName"?',
            style: const TextStyle(color: Colors.black87),
          ),
          actions: [
            // 1. Cancel Button (Light color, non-bold text)
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: Colors.blue.shade400, // Light blue/grey tone
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            // 2. Delete Button (Large, Red, Elevated)
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, // Red background
                foregroundColor: Colors.white, // White text
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10), // Rounded corners
                ),
                minimumSize: const Size(90, 40), // Ensures it's a decent size
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              child: const Text(
                'Delete',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
    if (confirmDelete == true) {
      try {
        await _db.collection('officials').doc(docId).delete();

        // ▼▼▼ TRACKING: DELETE OFFICIAL ▼▼▼
        await ActivityService().logActivity(
          context,
          actionTitle: 'Deleted Official',
          details: 'Removed official: $officialName',
        );
        // ▲▲▲ END TRACKING ▲▲▲

        _showSnackBar('Official deleted successfully');
      } catch (e) {
        _showSnackBar('Failed to delete: $e', isError: true);
      }
    }
  }

  // --- SHOW DETAILS MODAL (Read-Only Version) ---
  void _showOfficialDetails(Map<String, dynamic> data) {
    final title = data['title']?.toString() ?? '';
    final name = data['name']?.toString() ?? '';
    final nickname = data['nickname']?.toString() ?? '';
    final age = data['age']?.toString() ?? '';
    // Added Age
    final address = data['address']?.toString() ?? '';
    final imageUrl = data['imageUrl']?.toString() ?? '';
    // --- FINAL FIX: Only use 'title' (Position) as the position text ---
    final String positionText = title;
    // ------------------------------------------------------------------

    // Helper for image in modal
    ImageProvider? getProfileImage() {
      if (imageUrl.isEmpty) return null;
      try {
        if (imageUrl.startsWith('http')) {
          return NetworkImage(imageUrl);
        } else {
          return MemoryImage(base64Decode(imageUrl));
        }
      } catch (e) {
        return null;
      }
    }

    showDialog(
      context: context,
      useRootNavigator: false, // CRITICAL: Keeps modal inside the "phone frame"
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 30, vertical: 24),
        child: Container(
          clipBehavior: Clip.antiAlias,
          constraints: const BoxConstraints(maxWidth: 340),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: const Color.fromRGBO(0, 0, 0, 0.25), // Fixed Opacity
                blurRadius: 25,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Stack(
            children: [
              // MAIN CONTENT
              SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 40, 24, 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Large Image
                    Container(
                      width: 130,
                      height: 130,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.blue.shade50,
                        border: Border.all(
                          color: Colors.blue.shade100,
                          width: 4,
                        ),
                        image: getProfileImage() != null
                            ? DecorationImage(
                                image: getProfileImage()!,
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: getProfileImage() == null
                          ? Icon(
                              Icons.person,
                              size: 65,
                              color: Colors.blue.shade200,
                            )
                          : null,
                    ),
                    const SizedBox(height: 20),

                    // Name & Nickname
                    Text(
                      name,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                        letterSpacing: -0.5,
                      ),
                    ),
                    if (nickname.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 6.0),
                        child: Text(
                          '"$nickname"',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 18,
                            fontStyle: FontStyle.italic,
                            color: Colors.blue.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),

                    const SizedBox(height: 24),
                    const Divider(height: 1, thickness: 0.5),
                    const SizedBox(height: 24),

                    // Details List
                    // Showing Position only (using corrected logic)
                    _buildDetailRow(
                      Icons.work_outline_rounded,
                      "Position",
                      positionText.toUpperCase(),
                    ),
                    // 2. Added Age Row
                    if (age.isNotEmpty)
                      _buildDetailRow(
                        Icons.calendar_today_rounded,
                        "Age",
                        "$age years old",
                      ),
                    if (address.isNotEmpty)
                      _buildDetailRow(
                        Icons.location_on_outlined,
                        "Address",
                        address,
                      ),
                  ],
                ),
              ),

              // CLOSE BUTTON ("X" at Upper Right)
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.grey.shade100,
                    highlightColor: Colors.grey.shade200,
                  ),
                  icon: Icon(Icons.close, color: Colors.grey.shade600),
                  tooltip: 'Close',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper widget for the details modal
  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: Colors.blue.shade700),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- EDIT CONTACT INFO ---
  Future<void> _editContactInfo(
    String category,
    String field,
    String label,
    String currentValue,
  ) async {
    final inputController = TextEditingController(text: currentValue);
    final result = await showDialog<String>(
      context: context,
      useRootNavigator: false, // Inside frame
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white, // White background for consistency
        title: Text('Edit $label', style: const TextStyle(color: Colors.black)),
        content: TextField(
          controller: inputController,
          style: const TextStyle(color: Colors.black),
          decoration: InputDecoration(
            hintText: 'Enter $label',
            enabledBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.grey),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.blue),
            ),
          ),
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

        // ▼▼▼ TRACKING: EDIT CONTACT INFO ▼▼▼
        await ActivityService().logActivity(
          context,
          actionTitle: 'Updated Contact Info',
          details: 'Updated $label for $category to: $result',
        );
        // ▲▲▲ END TRACKING ▲▲▲

        _showSnackBar('Contact info updated');
      } catch (e) {
        _showSnackBar('Failed to update: $e', isError: true);
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
            color: Colors.black.withOpacity(0.05), // Corrected Opacity
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
            color: Colors.blue.withOpacity(0.3), // Corrected Opacity
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
            color: Colors.black.withOpacity(0.03), // Corrected Opacity
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: _updateSearch,
        style: const TextStyle(color: Colors.black87),
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

  Widget _buildOfficialCard(Map<String, dynamic> data, DocumentSnapshot doc) {
    final name = data['name'] ?? '';
    final title = data['title'] ?? '';
    final imageUrl = data['imageUrl']?.toString() ?? '';

    ImageProvider? getProfileImage() {
      if (imageUrl.isEmpty) return null;
      try {
        if (imageUrl.startsWith('http')) return NetworkImage(imageUrl);
        return MemoryImage(base64Decode(imageUrl));
      } catch (e) {
        return null;
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02), // Corrected Opacity
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
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
        title: Text(
          title,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.blue.shade700,
            letterSpacing: 0.5,
          ),
        ),
        subtitle: Text(
          name,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        onTap: () => _showOfficialDetails(data),
        trailing: PopupMenuButton<String>(
          // Change popup background to White
          color: Colors.white,
          icon: Icon(Icons.more_vert, color: Colors.grey.shade400),
          onSelected: (value) {
            if (value == 'edit') {
              _showOfficialDialog(existingDoc: doc);
            } else if (value == 'delete') {
              // PASS THE NAME INSTEAD OF TITLE SO LOG SAYS "Deleted Juan" instead of "Deleted Captain"
              _deleteOfficial(doc.id, name);
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(
                    Icons.edit_rounded,
                    size: 20,
                    color: Color.fromARGB(255, 9, 9, 9),
                  ),
                  SizedBox(width: 8),
                  // Change "Edit" text color to Black
                  Text('Edit', style: TextStyle(color: Colors.black)),
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
                  SizedBox(width: 8),
                  Text('Delete', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
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
            color: Colors.black.withOpacity(0.05), // Corrected Opacity
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
            icon: Icon(
              Icons.campaign_rounded,
            ), // Standard icon (grey when unselected)
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
                                        (doc) => _buildOfficialCard(
                                          doc.data() as Map<String, dynamic>,
                                          doc,
                                        ),
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

    if (kIsWeb) {
      return PhoneFrame(child: mobileContent);
    }
    return mobileContent;
  }
}

// --- PHONE FRAME ---
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
                color: Colors.black.withOpacity(0.1), // Corrected Opacity
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

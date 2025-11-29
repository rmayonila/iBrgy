import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditProfilePage extends StatefulWidget {
  final String? initialName;
  final String? initialEmail;

  const EditProfilePage({super.key, this.initialName, this.initialEmail});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  bool isLoading = false;
  bool isSaving = false;

  // Check if current user is the seeded admin
  bool get _isSeededAdmin {
    final currentEmail = emailController.text.trim().toLowerCase();
    return currentEmail == 'admin@ibrgy.com';
  }

  @override
  void initState() {
    super.initState();
    if (widget.initialName != null) nameController.text = widget.initialName!;
    if (widget.initialEmail != null)
      emailController.text = widget.initialEmail!;
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => isLoading = true);

    try {
      // For seeded admin, just use the initial values
      if (_isSeededAdmin) {
        if (mounted) {
          setState(() {
            nameController.text = widget.initialName ?? 'Admin User';
            emailController.text = widget.initialEmail ?? 'admin@ibrgy.com';
          });
        }
      } else {
        // For Firebase Auth users, load from Firestore
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          final doc = await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();

          if (doc.exists) {
            final data = doc.data();
            if (mounted) {
              setState(() {
                nameController.text =
                    (data?['name'] as String?) ?? user.displayName ?? '';
                emailController.text =
                    (data?['email'] as String?) ?? user.email ?? '';
              });
            }
          } else {
            // Fallback to FirebaseAuth user fields
            if (mounted) {
              setState(() {
                nameController.text = user.displayName ?? '';
                emailController.text = user.email ?? '';
              });
            }
          }
        }
      }
    } catch (e) {
      print('Error loading profile: $e');
      // Use initial values as fallback
      if (mounted) {
        setState(() {
          nameController.text = widget.initialName ?? 'Admin User';
          emailController.text = widget.initialEmail ?? 'admin@ibrgy.com';
        });
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _saveProfile() async {
    final newName = nameController.text.trim();
    final newEmail = emailController.text.trim();

    if (newName.isEmpty) {
      _showSnackBar('Please enter your name');
      return;
    }

    if (newEmail.isEmpty) {
      _showSnackBar('Please enter your email');
      return;
    }

    // Email format validation
    if (!_isValidEmail(newEmail)) {
      _showSnackBar('Please enter a valid email address');
      return;
    }

    setState(() => isSaving = true);

    try {
      if (_isSeededAdmin) {
        // For seeded admin, just show success message (no Firebase update)
        print('Seeded admin profile updated locally');
        if (mounted) {
          _showSnackBar('Profile updated successfully!', isError: false);
          await Future.delayed(const Duration(milliseconds: 1500));
          Navigator.pop(context);
        }
      } else {
        // For Firebase Auth users, update in Firebase
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) {
          _showSnackBar('No user logged in');
          return;
        }

        // Update display name in Firebase Auth
        try {
          await user.updateDisplayName(newName);
          print('Display name updated in Auth');
        } catch (e) {
          print('Error updating display name: $e');
          // Continue with Firestore update even if Auth fails
        }

        // Update Firestore
        final updateData = {
          'name': newName,
          'email': newEmail,
          'updatedAt': FieldValue.serverTimestamp(),
        };

        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .set(updateData, SetOptions(merge: true));

        print('Firestore update successful');

        if (mounted) {
          _showSnackBar('Profile updated successfully!', isError: false);
          await Future.delayed(const Duration(milliseconds: 1500));
          Navigator.pop(context);
        }
      }
    } catch (e) {
      print('Error in _saveProfile: $e');
      if (mounted) {
        _showSnackBar('Failed to update profile: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => isSaving = false);
      }
    }
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  void _showSnackBar(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Column(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.blue.shade50,
            border: Border.all(color: Colors.blue.shade200, width: 3),
          ),
          child: Icon(Icons.person, size: 50, color: Colors.blue.shade300),
        ),
        const SizedBox(height: 16),
        Text(
          _isSeededAdmin ? 'Admin Profile' : 'User Profile',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.blue.shade800,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _isSeededAdmin
              ? 'Update your admin account information'
              : 'Update your account information',
          style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Colors.blue),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.blue, width: 2),
          ),
          filled: true,
          fillColor: Colors.grey.shade50,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
        keyboardType: keyboardType,
        style: const TextStyle(color: Colors.black, fontSize: 16),
        cursorColor: Colors.blue,
      ),
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PhoneFrame(
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        appBar: AppBar(
          title: const Text(
            'Edit Profile',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
          backgroundColor: Colors.blue,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          centerTitle: true,
        ),
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    // Profile Header
                    _buildProfileHeader(),
                    const SizedBox(height: 32),

                    // Form Fields
                    _buildTextField(
                      controller: nameController,
                      label: 'Full Name',
                      icon: Icons.person_outline,
                    ),
                    _buildTextField(
                      controller: emailController,
                      label: 'Email Address',
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                    ),

                    const SizedBox(height: 32),

                    // Action Buttons
                    Row(
                      children: [
                        // Cancel Button
                        Expanded(
                          child: OutlinedButton(
                            onPressed: isSaving
                                ? null
                                : () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              side: BorderSide(color: Colors.grey.shade400),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              'Cancel',
                              style: TextStyle(
                                color: Colors.grey.shade700,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),

                        // Save Button
                        Expanded(
                          child: ElevatedButton(
                            onPressed: isSaving ? null : _saveProfile,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 2,
                            ),
                            child: isSaving
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : Text(
                                    'Save Changes',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Info Note
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue.shade100),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.blue.shade600,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _isSeededAdmin
                                  ? 'Admin profile changes are saved locally in the app.'
                                  : 'Profile information updated in the app database.',
                              style: TextStyle(
                                color: Colors.blue.shade800,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

// Phone Frame Widget
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
                color: Colors.black.withOpacity(0.1),
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

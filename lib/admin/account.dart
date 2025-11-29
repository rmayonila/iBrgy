import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// ---------------------------------------------------------------------------
// PAGE 1: ACCOUNT PAGE
// ---------------------------------------------------------------------------

class AccountPage extends StatefulWidget {
  final String? initialName;
  final String? initialEmail;

  const AccountPage({super.key, this.initialName, this.initialEmail});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();

  bool isLoading = false;
  bool _showPassword = false;

  // We store the current admin password in a variable so it can be updated
  String _currentAdminPassword = 'admin1234';

  bool get _isSeededAdmin {
    final currentEmail = emailController.text.trim().toLowerCase();
    final fallbackEmail = widget.initialEmail?.trim().toLowerCase() ?? '';
    return currentEmail == 'admin@ibrgy.com' ||
        fallbackEmail == 'admin@ibrgy.com';
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
      if (_isSeededAdmin) {
        // Try to fetch the updated admin password from Firestore if it exists
        // This makes the change persist even for the "Seeded" admin
        try {
          final doc = await FirebaseFirestore.instance
              .collection('settings')
              .doc('admin_auth')
              .get();
          if (doc.exists && doc.data() != null) {
            final storedPassword = doc.data()?['currentPassword'];
            if (storedPassword != null) {
              _currentAdminPassword = storedPassword;
            }
          }
        } catch (e) {
          print("Could not fetch admin settings: $e");
        }

        if (mounted) {
          setState(() {
            nameController.text = widget.initialName ?? 'Admin User';
            emailController.text = widget.initialEmail ?? 'admin@ibrgy.com';
          });
        }
      } else {
        // Standard Firebase User Logic
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
          }
        }
      }
    } catch (e) {
      print('Error loading profile: $e');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
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
          child: Icon(Icons.shield, size: 50, color: Colors.blue.shade300),
        ),
        const SizedBox(height: 16),
        const Text(
          'Administrator',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A1A1A),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Manage your account details',
          style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildReadOnlyField(
    String label,
    String value,
    IconData icon, {
    Widget? suffix,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.grey.shade600, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          if (suffix != null) suffix,
        ],
      ),
    );
  }

  Widget _buildChangePasswordTile() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            // Wait for the result from ChangePasswordPage
            final newPassword = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChangePasswordPage(
                  isSeededAdmin: _isSeededAdmin,
                  currentAdminPassword: _currentAdminPassword,
                ),
              ),
            );

            // If a new password was returned (update successful), update UI
            if (newPassword != null && newPassword is String) {
              setState(() {
                _currentAdminPassword = newPassword;
              });
            }
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.lock_reset,
                    color: Colors.blue.shade600,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Text(
                    'Change Password',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ),
                Icon(Icons.chevron_right, color: Colors.grey.shade400),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String passwordDisplay;
    Widget? passwordSuffix;

    if (_isSeededAdmin) {
      // Use the local variable _currentAdminPassword
      passwordDisplay = _showPassword ? _currentAdminPassword : '••••••••••••';
      passwordSuffix = IconButton(
        icon: Icon(
          _showPassword
              ? Icons.visibility_outlined
              : Icons.visibility_off_outlined,
          color: Colors.grey.shade500,
        ),
        onPressed: () => setState(() => _showPassword = !_showPassword),
      );
    } else {
      passwordDisplay = '••••••••••••';
      passwordSuffix = null;
    }

    return PhoneFrame(
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        appBar: AppBar(
          title: const Text(
            'Account',
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(child: _buildProfileHeader()),
                    const SizedBox(height: 32),
                    const Text(
                      "ACCOUNT DETAILS",
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildReadOnlyField(
                      'Full Name',
                      nameController.text.isEmpty
                          ? 'Loading...'
                          : nameController.text,
                      Icons.person_outline,
                    ),
                    _buildReadOnlyField(
                      'Email Address',
                      emailController.text.isEmpty
                          ? 'Loading...'
                          : emailController.text,
                      Icons.email_outlined,
                    ),
                    _buildReadOnlyField(
                      'Password',
                      passwordDisplay,
                      Icons.lock_outline,
                      suffix: passwordSuffix,
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      "SECURITY",
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildChangePasswordTile(),
                  ],
                ),
              ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// PAGE 2: CHANGE PASSWORD PAGE
// ---------------------------------------------------------------------------

class ChangePasswordPage extends StatefulWidget {
  final bool isSeededAdmin;
  final String currentAdminPassword; // Received from AccountPage

  const ChangePasswordPage({
    super.key,
    required this.isSeededAdmin,
    required this.currentAdminPassword,
  });

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  // Controllers
  final currentPasswordController = TextEditingController();
  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  // Visibility Toggles
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  bool isSaving = false;

  // Button Active Logic
  bool get isButtonActive {
    return currentPasswordController.text.isNotEmpty &&
        newPasswordController.text.isNotEmpty &&
        confirmPasswordController.text.isNotEmpty;
  }

  @override
  void initState() {
    super.initState();
    // Listeners for UI updates (button color & icons)
    currentPasswordController.addListener(_refreshUI);
    newPasswordController.addListener(_refreshUI);
    confirmPasswordController.addListener(_refreshUI);
  }

  void _refreshUI() {
    setState(() {});
  }

  @override
  void dispose() {
    currentPasswordController.removeListener(_refreshUI);
    newPasswordController.removeListener(_refreshUI);
    confirmPasswordController.removeListener(_refreshUI);
    currentPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  // -------------------------------------------------------------------------
  // 2. STRICT SECURITY REGEX CHECK
  // -------------------------------------------------------------------------
  bool _isPasswordStrong(String password) {
    // Regex: At least 6 characters, 1 letter, 1 number, 1 special char (! $ @ %)
    final regex = RegExp(r'^(?=.*[a-zA-Z])(?=.*[0-9])(?=.*[!$@%]).{6,}$');
    return regex.hasMatch(password);
  }

  Future<void> _updatePassword() async {
    if (!isButtonActive || isSaving) return;

    final currentPassword = currentPasswordController.text.trim();
    final newPassword = newPasswordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();

    // 2. STRICT VALIDATION IMPLEMENTATION
    if (!_isPasswordStrong(newPassword)) {
      _showSnackBar(
        'Password must be at least 6 characters and include numbers, letters and special characters (!\$@%).',
        isError: true,
      );
      return;
    }

    if (newPassword != confirmPassword) {
      _showSnackBar('New passwords do not match', isError: true);
      return;
    }

    setState(() => isSaving = true);

    try {
      if (widget.isSeededAdmin) {
        // --- SEEDED ADMIN LOGIC ---

        // Check against the current known password (passed from AccountPage)
        if (currentPassword != widget.currentAdminPassword) {
          _showSnackBar('Current password is incorrect', isError: true);
          setState(() => isSaving = false);
          return;
        }

        // UPDATE FIREBASE: We create/update a dedicated doc for admin settings
        // This is necessary so the Login Page can eventually read this.
        try {
          await FirebaseFirestore.instance
              .collection('settings')
              .doc('admin_auth')
              .set({
                'currentPassword': newPassword,
                'updatedAt': FieldValue.serverTimestamp(),
              });
        } catch (e) {
          print("Error updating admin settings in Firestore: $e");
        }

        // Mock delay for UX
        await Future.delayed(const Duration(seconds: 1));

        if (mounted) {
          _showSnackBar('Password updated successfully!', isError: false);
          await Future.delayed(const Duration(milliseconds: 1500));

          // 3. PASS DATA BACK TO ACCOUNT PAGE
          // Return the new password so Account Page updates immediately
          Navigator.pop(context, newPassword);
        }
      } else {
        // --- FIREBASE USER LOGIC ---
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) {
          _showSnackBar('No user logged in', isError: true);
          return;
        }

        // Update Auth
        await user.updatePassword(newPassword);

        // Update Firestore
        try {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .set({
                'password': newPassword,
                'updatedAt': FieldValue.serverTimestamp(),
              }, SetOptions(merge: true));
        } catch (e) {
          print("Firestore update error: $e");
        }

        if (mounted) {
          _showSnackBar('Password updated successfully!', isError: false);
          await Future.delayed(const Duration(milliseconds: 1500));
          // Pass new password back (though for Auth users we hide it usually)
          Navigator.pop(context, newPassword);
        }
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        _showSnackBar(
          'For security, please logout and login again to change password.',
          isError: true,
        );
      } else {
        _showSnackBar(e.message ?? 'Failed to update password', isError: true);
      }
    } catch (e) {
      _showSnackBar('Failed to update: ${e.toString()}', isError: true);
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  void _showSnackBar(String message, {bool isError = true}) {
    // 1. CONFIRMATION MESSAGE INSIDE PHONE FRAME
    // Because this Scaffold is inside PhoneFrame, the SnackBar stays inside.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Widget _buildStyledTextField({
    required TextEditingController controller,
    required String hintText,
    required bool obscureText,
    required VoidCallback onToggleVisibility,
  }) {
    final bool showSuffixIcon = controller.text.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        // Text Color Black
        style: const TextStyle(color: Colors.black, fontSize: 16),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 16),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 18,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.blue, width: 2),
          ),
          filled: true,
          fillColor: Colors.white,
          // Dynamic Eye Icon
          suffixIcon: showSuffixIcon
              ? IconButton(
                  icon: Icon(
                    obscureText
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: Colors.grey,
                  ),
                  onPressed: onToggleVisibility,
                )
              : null,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dateString = "${now.month}/${now.day}/${now.year}";

    return PhoneFrame(
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Text(
                        'Admin • iBrgy',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Title
                      const Text(
                        'Change password',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Description
                      Text(
                        'Your password must be at least 6 characters and should include a combination of numbers, letters and special characters (!\$@%).',
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.grey.shade700,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Input Fields
                      _buildStyledTextField(
                        controller: currentPasswordController,
                        hintText: 'Current password (Updated $dateString)',
                        obscureText: _obscureCurrent,
                        onToggleVisibility: () =>
                            setState(() => _obscureCurrent = !_obscureCurrent),
                      ),
                      _buildStyledTextField(
                        controller: newPasswordController,
                        hintText: 'New password',
                        obscureText: _obscureNew,
                        onToggleVisibility: () =>
                            setState(() => _obscureNew = !_obscureNew),
                      ),
                      _buildStyledTextField(
                        controller: confirmPasswordController,
                        hintText: 'Re-type new password',
                        obscureText: _obscureConfirm,
                        onToggleVisibility: () =>
                            setState(() => _obscureConfirm = !_obscureConfirm),
                      ),
                    ],
                  ),
                ),
              ),

              // Bottom Button
              Padding(
                padding: const EdgeInsets.all(24),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: (isButtonActive && !isSaving)
                        ? _updatePassword
                        : null,
                    style: ButtonStyle(
                      // Button Colors: Blue if active, Pale if disabled
                      backgroundColor: WidgetStateProperty.resolveWith<Color>((
                        states,
                      ) {
                        if (states.contains(WidgetState.disabled)) {
                          return const Color(
                            0xFF1877F2,
                          ).withOpacity(0.3); // Pale Blue
                        }
                        return const Color(0xFF1877F2); // Solid Blue
                      }),
                      padding: WidgetStateProperty.all(
                        const EdgeInsets.symmetric(vertical: 16),
                      ),
                      shape: WidgetStateProperty.all(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      elevation: WidgetStateProperty.all(0),
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
                            'Change password',
                            style: TextStyle(
                              color: isButtonActive
                                  ? Colors.white
                                  : Colors.white.withOpacity(0.7),
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// UTILS: PHONE FRAME
// ---------------------------------------------------------------------------

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

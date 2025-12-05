// ignore_for_file: use_build_context_synchronously
import 'dart:convert';
import 'package:flutter/foundation.dart'; // For kIsWeb check
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

class AddModeratorAccountPage extends StatefulWidget {
  const AddModeratorAccountPage({super.key});

  @override
  State<AddModeratorAccountPage> createState() =>
      _AddModeratorAccountPageState();
}

class _AddModeratorAccountPageState extends State<AddModeratorAccountPage> {
  // Controllers
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // State Variables
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isFormFilled = false;

  final _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    void checkForm() {
      setState(() {
        _isFormFilled =
            _nameController.text.isNotEmpty &&
            _emailController.text.isNotEmpty &&
            _passwordController.text.isNotEmpty &&
            _confirmPasswordController.text.isNotEmpty;
      });
    }

    _nameController.addListener(checkForm);
    _emailController.addListener(checkForm);
    _passwordController.addListener(checkForm);
    _confirmPasswordController.addListener(checkForm);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // --- HELPER: Custom SnackBar to appear ABOVE the button ---
  void _showMessage(String message, {bool isError = false}) {
    _scaffoldMessengerKey.currentState?.hideCurrentSnackBar();
    _scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : const Color(0xFF4CAF50),
        behavior: SnackBarBehavior.floating,
        // MARGIN: Pushes the snackbar up by 100px so it sits ABOVE the button
        margin: const EdgeInsets.only(bottom: 100, left: 20, right: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _createModeratorAccount() async {
    if (!_formKey.currentState!.validate()) return;

    String name = _nameController.text.trim();
    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();
    String confirmPassword = _confirmPasswordController.text.trim();

    // Specific check for password length (Extra safety)
    if (password.length < 6) {
      _showMessage('Password must be at least 6 characters.', isError: true);
      return;
    }

    if (password != confirmPassword) {
      _showMessage('Passwords do not match.', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final apiKey = Firebase.app().options.apiKey;
      final url = Uri.parse(
        'https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=$apiKey',
      );

      final response = await http.post(
        url,
        body: json.encode({
          'email': email,
          'password': password,
          'returnSecureToken': true,
        }),
        headers: {'Content-Type': 'application/json'},
      );

      final responseData = json.decode(response.body);

      if (response.statusCode != 200) {
        String errorMessage = 'An error occurred';
        if (responseData['error'] != null) {
          errorMessage = responseData['error']['message'] ?? errorMessage;
        }
        if (errorMessage.contains('EMAIL_EXISTS')) {
          errorMessage = 'The email address is already in use.';
        } else if (errorMessage.contains('WEAK_PASSWORD')) {
          errorMessage = 'The password is too weak.';
        }
        throw FirebaseAuthException(code: 'api-error', message: errorMessage);
      }

      final newUserId = responseData['localId'];

      await FirebaseFirestore.instance.collection('users').doc(newUserId).set({
        'uid': newUserId,
        'name': name,
        'email': email,
        'password': password,
        'role': 'moderator',
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      _showMessage('Moderator account created successfully!');

      await Future.delayed(const Duration(seconds: 2));
      if (mounted) Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      _showMessage(e.message ?? 'Error', isError: true);
    } catch (e) {
      _showMessage('Error: $e', isError: true);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildStyledTextField({
    required TextEditingController controller,
    required String hintText,
    TextInputType? keyboardType,
    bool isPassword = false,
    bool? obscureText,
    VoidCallback? onToggleVisibility,
    String? Function(String?)? validator,
  }) {
    bool showIcon = isPassword && controller.text.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText ?? false,
        keyboardType: keyboardType,
        style: const TextStyle(color: Colors.black, fontSize: 16),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 15),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 18,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.blue, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.redAccent, width: 1),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
          ),
          filled: true,
          fillColor: Colors.white,
          suffixIcon: showIcon
              ? IconButton(
                  icon: Icon(
                    (obscureText ?? false)
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: Colors.grey,
                  ),
                  onPressed: onToggleVisibility,
                )
              : null,
        ),
        validator: validator,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget mobileContent = ScaffoldMessenger(
      key: _scaffoldMessengerKey,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black87),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        const Text(
                          'Create Moderator',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Create an account for a moderator. They will use these credentials to log in.',
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.grey.shade600,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 32),

                        _buildStyledTextField(
                          controller: _nameController,
                          hintText: 'Full Name',
                          validator: (v) =>
                              v!.isEmpty ? "Name is required" : null,
                        ),

                        _buildStyledTextField(
                          controller: _emailController,
                          hintText: 'Email address',
                          keyboardType: TextInputType.emailAddress,
                          validator: (v) =>
                              v!.contains('@') ? null : "Enter a valid email",
                        ),

                        _buildStyledTextField(
                          controller: _passwordController,
                          hintText: 'Password',
                          isPassword: true,
                          obscureText: _obscurePassword,
                          onToggleVisibility: () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                          // VALIDATOR UPDATED: Checks for 6 characters
                          validator: (v) => (v == null || v.length < 6)
                              ? "Password must be at least 6 characters"
                              : null,
                        ),

                        _buildStyledTextField(
                          controller: _confirmPasswordController,
                          hintText: 'Confirm Password',
                          isPassword: true,
                          obscureText: _obscureConfirmPassword,
                          onToggleVisibility: () => setState(
                            () => _obscureConfirmPassword =
                                !_obscureConfirmPassword,
                          ),
                          validator: (v) =>
                              v!.isEmpty ? "Confirm your password" : null,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(24.0),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: (_isFormFilled && !_isLoading)
                        ? _createModeratorAccount
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1565C0),
                      disabledBackgroundColor: const Color(0xFFBBDEFB),

                      // 1. VISIBLE TEXT WHEN DISABLED
                      disabledForegroundColor: Colors.white,
                      foregroundColor: Colors.white,

                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : const Text(
                            "Create account",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
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

    if (kIsWeb) {
      return PhoneFrame(child: mobileContent);
    }
    return mobileContent;
  }
}

// --- PHONE FRAME UTILITY ---
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

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'main.dart' show PhoneFrame;

class AccessCodePage extends StatefulWidget {
  const AccessCodePage({super.key});

  @override
  State<AccessCodePage> createState() => _AccessCodePageState();
}

class _AccessCodePageState extends State<AccessCodePage> {
  final List<TextEditingController> _controllers = List.generate(
    4,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(4, (_) => FocusNode());
  bool _isLoading = false;
  String _errorMessage = '';

  // Default access codes (fallback if Firestore fails)
  static const List<String> _defaultAccessCodes = ['1234', '0000'];

  @override
  void initState() {
    super.initState();
    _setupFocusListeners();
  }

  void _setupFocusListeners() {
    for (int i = 0; i < _focusNodes.length; i++) {
      _focusNodes[i].addListener(() {
        if (!_focusNodes[i].hasFocus && _controllers[i].text.isEmpty) {
          if (i > 0) {
            _focusNodes[i - 1].requestFocus();
          }
        }
      });
    }
  }

  void _onDigitChanged(String value, int index) {
    // Only allow numeric input
    if (value.isNotEmpty && !RegExp(r'[0-9]').hasMatch(value)) {
      _controllers[index].clear();
      return;
    }

    if (value.isNotEmpty && index < 3) {
      _focusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }

    if (_isAllFieldsFilled()) {
      _verifyAccessCode();
    }
  }

  bool _isAllFieldsFilled() {
    return _controllers.every((controller) => controller.text.isNotEmpty);
  }

  String _getEnteredCode() {
    return _controllers.map((controller) => controller.text).join();
  }

  Future<List<String>> _getAccessCodesFromFirestore() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('settings')
          .doc('access_codes')
          .get();

      if (doc.exists && doc.data() != null) {
        final codes = doc.data()?['codes'] as List<dynamic>?;
        if (codes != null) {
          return codes.map((code) => code.toString()).toList();
        }
      }
    } catch (e) {
      print('Error fetching access codes: $e');
    }

    // Return default codes if Firestore fails
    return _defaultAccessCodes;
  }

  Future<void> _verifyAccessCode() async {
    if (!_isAllFieldsFilled()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    final enteredCode = _getEnteredCode();
    final validCodes = await _getAccessCodesFromFirestore();
    final isValid = validCodes.contains(enteredCode);

    // Simulate verification delay
    await Future.delayed(const Duration(milliseconds: 500));

    if (isValid) {
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    } else {
      setState(() {
        _errorMessage = 'Invalid access code. Please try again.';
        _isLoading = false;
      });
      _clearAllFields();
      _focusNodes[0].requestFocus();
    }
  }

  void _clearAllFields() {
    for (final controller in _controllers) {
      controller.clear();
    }
  }

  void _onBackPressed() {
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    for (final focusNode in _focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PhoneFrame(
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        body: Stack(
          children: [
            // Background similar to your splash screen
            _buildBackground(),

            // Main content
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo (smaller version)
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: const Color.fromRGBO(33, 150, 243, 0.15),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/images/ibrgy_logo.jpg',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),

                    // Title
                    Text(
                      "Admin Access",
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: Colors.blueGrey.shade800,
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Subtitle
                    Text(
                      "Enter the access code to continue",
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.blueGrey.shade500,
                      ),
                    ),

                    const SizedBox(height: 30),

                    // Error Message
                    if (_errorMessage.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(bottom: 20),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.red.shade100),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 20,
                              color: Colors.red.shade700,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _errorMessage,
                                style: TextStyle(
                                  color: Colors.red.shade800,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Access Code Input Fields
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(4, (index) {
                        return SizedBox(
                          width: 60,
                          height: 60,
                          child: TextField(
                            controller: _controllers[index],
                            focusNode: _focusNodes[index],
                            textAlign: TextAlign.center,
                            keyboardType: TextInputType.number,
                            maxLength: 1,
                            style: GoogleFonts.poppins(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade700,
                            ),
                            decoration: InputDecoration(
                              counterText: '',
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.grey.shade300,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.grey.shade300,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.blue.shade400,
                                  width: 2,
                                ),
                              ),
                            ),
                            onChanged: (value) => _onDigitChanged(value, index),
                          ),
                        );
                      }),
                    ),

                    const SizedBox(height: 30),

                    // Info Text
                    Text(
                      "Contact barangay administration for access code",
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.blueGrey.shade400,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 20),

                    // Verify Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: _isLoading
                          ? const Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.blue.shade700,
                                    Colors.blue.shade500,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.blue.shade300.withAlpha(100),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ElevatedButton(
                                onPressed: _isAllFieldsFilled()
                                    ? _verifyAccessCode
                                    : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                child: const Text(
                                  'CONTINUE TO LOGIN',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                              ),
                            ),
                    ),

                    const SizedBox(height: 16),

                    // Back Button
                    TextButton(
                      onPressed: _onBackPressed,
                      child: Text(
                        'Back to Home',
                        style: TextStyle(
                          color: Colors.blue.shade600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackground() {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFFF0F8FF),
                Colors.white,
                const Color(0xFFE3F2FD),
              ],
            ),
          ),
        ),
        Positioned(
          top: -100,
          right: -100,
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color.fromRGBO(187, 222, 251, 0.4),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        Positioned(
          bottom: -50,
          left: -50,
          child: Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color.fromRGBO(144, 202, 249, 0.3),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

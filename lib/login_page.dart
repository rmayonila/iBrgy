// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'admin/admin_home.dart' as admin;
import 'main.dart' show PhoneFrame;

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  bool _loading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
  }

  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    // Clear previous error message
    setState(() => _errorMessage = null);

    if (email.isEmpty || password.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter your email and password';
      });
      return;
    }

    setState(() => _loading = true);

    // 1. Admin Bypass Check (for the hardcoded admin)
    if (email.toLowerCase() == 'admin@ibrgy.com' && password == 'admin1234') {
      if (mounted) setState(() => _loading = false);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (ctx) => PhoneFrame(child: admin.AdminHomePage()),
        ),
      );
      return;
    }

    try {
      // 2. Sign in with Email and Password
      final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = cred.user?.uid;
      if (uid == null) throw FirebaseAuthException(code: 'no-user');

      // 3. Fetch User Role from Firestore
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

      if (!doc.exists) {
        await FirebaseAuth.instance.signOut();
        if (mounted) {
          setState(() {
            _errorMessage =
                'User profile not found in database. Contact support.';
          });
        }
        return;
      }

      final roleFromDb = (doc.data()?['role'] ?? '').toString().toLowerCase();

      // 4. Redirect based on the fetched role
      if (mounted) {
        if (roleFromDb == 'admin') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (ctx) => PhoneFrame(child: admin.AdminHomePage()),
            ),
          );
        } else if (roleFromDb == 'moderator') {
          // Redirect to moderator dashboard
          Navigator.pushReplacementNamed(context, '/moderator-home');
        } else {
          // Handle unknown or unauthorized roles
          await FirebaseAuth.instance.signOut();
          if (mounted) {
            setState(() {
              _errorMessage =
                  'Unauthorized role detected. Please contact support.';
            });
          }
        }
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Authentication error';

      // Specific error messages based on Firebase error codes
      if (e.code == 'user-not-found') {
        errorMessage = 'INCORRECT EMAIL';
      } else if (e.code == 'invalid-email') {
        errorMessage = 'INVALID EMAIL FORMAT';
      } else if (e.code == 'wrong-password') {
        errorMessage = 'INCORRECT PASSWORD';
      } else if (e.code == 'invalid-credential') {
        errorMessage = 'INCORRECT EMAIL OR PASSWORD';
      } else {
        errorMessage = e.message ?? 'Authentication error';
      }

      if (mounted) {
        setState(() {
          _errorMessage = errorMessage;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Login failed. Please try again.';
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SizedBox(
            width: 320,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // iBrgy Logo
                      SizedBox(
                        height: 40,
                        width: 100,
                        child: Image.network(
                          'https://i.postimg.cc/mkm9rg5L/ibrgy-logo.png',
                          fit: BoxFit.contain,
                          errorBuilder: (c, e, st) =>
                              const SizedBox(height: 40, width: 100),
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return const SizedBox(height: 40, width: 100);
                          },
                        ),
                      ),
                      const SizedBox(height: 2), // Minimal space
                      // iBrgy Text Label
                      Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 25,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
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
                      ),
                      const SizedBox(height: 16),

                      // Error Message Display - No border
                      if (_errorMessage != null)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(
                              color: Colors.redAccent,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),

                      if (_errorMessage != null) const SizedBox(height: 12),

                      // Email Field
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'EMAIL',
                          style: TextStyle(fontSize: 12, color: Colors.black),
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _emailController,
                        style: const TextStyle(color: Colors.black),
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Password Field
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'PASSWORD',
                          style: TextStyle(fontSize: 12, color: Colors.black),
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        style: const TextStyle(color: Colors.black),
                        decoration: InputDecoration(
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: Colors.grey,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Login Button
                      SizedBox(
                        width: 250,
                        height: 40,
                        child: _loading
                            ? Center(
                                child: Container(
                                  width: 250,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: Colors.blue,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Center(
                                    child: SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              )
                            : ElevatedButton(
                                onPressed: _login,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.lightBlue,
                                ),
                                child: const Text(
                                  'LOG IN',
                                  style: TextStyle(
                                    color: Color.fromARGB(255, 238, 242, 245),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                      ),
                    ],
                  ),
                ),

                // Close Icon - Moved much closer to the top
                Positioned(
                  top: 2, // Very close to the top
                  right: 2, // Very close to the right edge
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).maybePop(),
                    child: Semantics(
                      label: 'Close',
                      button: true,
                      child: const Icon(
                        Icons.close,
                        color: Colors.black,
                        size: 22,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

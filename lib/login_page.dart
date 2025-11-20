import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  String? _selectedRole;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    // Initialize empty controllers
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
  }

  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter email and password')),
      );
      return;
    }

    setState(() => _loading = true);

    // Development shortcut: allow a pre-provisioned admin to log in with hardcoded credentials
    // NOTE: This is intentionally hardcoded for development purposes only. Remove or protect in production.
    if ((_selectedRole?.toLowerCase() ?? '') == 'admin' &&
        email.toLowerCase() == 'admin@ibrgy.com' &&
        password == 'admin1234') {
      // clear loading and navigate to admin dashboard
      if (mounted) setState(() => _loading = false);
      Navigator.pushReplacementNamed(context, '/admin-dashboard');
      return;
    }

    try {
      final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = cred.user?.uid;
      if (uid == null) throw FirebaseAuthException(code: 'no-user');

      // Check user role in Firestore (collection 'users', doc = uid)
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      if (!doc.exists) {
        await FirebaseAuth.instance.signOut();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('User profile not found')));
        return;
      }

      final roleFromDb = (doc.data()?['role'] ?? '').toString().toLowerCase();
      final selected = (_selectedRole ?? '').toLowerCase();

      if (roleFromDb != selected) {
        await FirebaseAuth.instance.signOut();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Selected role does not match account role'),
          ),
        );
        return;
      }

      // Navigate depending on role
      if (selected == 'admin') {
        Navigator.pushReplacementNamed(context, '/admin-dashboard');
      } else {
        Navigator.pushReplacementNamed(context, '/staff-home');
      }
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Authentication error')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Login failed: $e')));
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
        child: Stack(
          children: [
            Center(
              child: Container(
                width: 320,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // logo
                    Image.network(
                      'https://i.postimg.cc/mkm9rg5L/ibrgy-logo.png',
                      width: 100,
                      height: 40,
                      fit: BoxFit.contain,
                      errorBuilder: (c, e, st) => const SizedBox.shrink(),
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        const Text(
                          'ROLE',
                          style: TextStyle(fontSize: 12, color: Colors.black),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: _selectedRole,
                            hint: const Text(
                              'Select Role',
                              style: TextStyle(color: Colors.black54),
                            ),
                            dropdownColor: Colors.white,
                            items: const [
                              DropdownMenuItem(
                                value: 'Admin',
                                child: Text(
                                  'Admin',
                                  style: TextStyle(color: Colors.black),
                                ),
                              ),
                              DropdownMenuItem(
                                value: 'Staff',
                                child: Text(
                                  'Staff',
                                  style: TextStyle(color: Colors.black),
                                ),
                              ),
                            ],
                            onChanged: (v) {
                              setState(() => _selectedRole = v);
                            },
                            decoration: const InputDecoration(
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 6,
                              ),
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Email
                    Row(
                      children: [
                        const Text(
                          'EMAIL',
                          style: TextStyle(fontSize: 12, color: Colors.black),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _emailController,
                      style: const TextStyle(color: Colors.black),
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 12),

                    Row(
                      children: [
                        const Text(
                          'PASSWORD',
                          style: TextStyle(fontSize: 12, color: Colors.black),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      style: const TextStyle(color: Colors.black),
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 16),

                    SizedBox(
                      width: 250,
                      height: 40,
                      child: _loading
                          ? Center(
                              child: SizedBox(
                                width: 250,
                                height: 40,
                                child: Container(
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
            ),

            // Close X at top-right of the dialog area
            Positioned(
              top: 60,
              right: 40,
              child: GestureDetector(
                onTap: () => Navigator.of(context).maybePop(),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.grey),
                    shape: BoxShape.circle,
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(6.0),
                    child: Icon(Icons.close, size: 16, color: Colors.black),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

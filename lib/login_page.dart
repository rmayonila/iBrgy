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
  String? _selectedRole;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
  }

  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    // 1. Check if Role is selected (Crucial Step)
    if (_selectedRole == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a Role (Admin or Moderator)'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    // 2. Check if fields are empty
    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter email and password')),
      );
      return;
    }

    setState(() => _loading = true);

    // ---------------------------------------------------------
    // SEEDED ADMIN CREDENTIALS (KEPT AS REQUESTED)
    // ---------------------------------------------------------
    // This allows bypassing Firebase if the specific hardcoded creds are used
    if ((_selectedRole?.toLowerCase() ?? '') == 'admin' &&
        email.toLowerCase() == 'admin@ibrgy.com' &&
        password == 'admin1234') {
      if (mounted) setState(() => _loading = false);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (ctx) => PhoneFrame(child: admin.AdminHomePage()),
        ),
      );
      return;
    }
    // ---------------------------------------------------------

    try {
      // 3. Firebase Login
      final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = cred.user?.uid;
      if (uid == null) throw FirebaseAuthException(code: 'no-user');

      // 4. Check User Role in Firestore
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

      if (!doc.exists) {
        await FirebaseAuth.instance.signOut();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('User profile not found in database')),
          );
        }
        return;
      }

      // Normalize strings to lowercase to prevent capitalization errors
      final roleFromDb = (doc.data()?['role'] ?? '').toString().toLowerCase();
      final selectedRoleInput = (_selectedRole ?? '').toLowerCase();

      if (roleFromDb != selectedRoleInput) {
        await FirebaseAuth.instance.signOut();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Role mismatch: You are not authorized for this role.',
              ),
            ),
          );
        }
        return;
      }

      // 5. Navigate
      if (mounted) {
        if (selectedRoleInput == 'admin') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (ctx) => PhoneFrame(child: admin.AdminHomePage()),
            ),
          );
        } else {
          // Navigate moderators to the moderator home route
          Navigator.pushReplacementNamed(context, '/moderator-home');
        }
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message ?? 'Authentication error')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Login failed: $e')));
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
                      // Logo
                      Image.network(
                        'https://i.postimg.cc/mkm9rg5L/ibrgy-logo.png',
                        width: 100,
                        height: 40,
                        fit: BoxFit.contain,
                        errorBuilder: (c, e, st) => const SizedBox.shrink(),
                      ),
                      const SizedBox(height: 12),

                      // iBrgy Label
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

                      // Role Dropdown
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
                                  value: 'Moderator',
                                  child: Text(
                                    'Moderator',
                                    style: TextStyle(color: Colors.black),
                                  ),
                                ),
                              ],
                              onChanged: (v) =>
                                  setState(() => _selectedRole = v),
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
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Password
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
                        obscureText: true,
                        style: const TextStyle(color: Colors.black),
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
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

                // Close Icon
                Positioned(
                  top: 12,
                  right: 12,
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

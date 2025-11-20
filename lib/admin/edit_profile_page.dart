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

  @override
  void initState() {
    super.initState();
    // If initial values were provided (e.g. from caller), set them first
    if (widget.initialName != null) nameController.text = widget.initialName!;
    if (widget.initialEmail != null) {
      emailController.text = widget.initialEmail!;
    }
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
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
        return;
      }
    } catch (_) {
      // ignore and fallback to auth user
    }

    // fallback to FirebaseAuth user fields
    if (mounted) {
      setState(() {
        nameController.text = user.displayName ?? '';
        emailController.text = user.email ?? '';
      });
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    setState(() => isLoading = true);
    final user = FirebaseAuth.instance.currentUser;
    final newName = nameController.text.trim();
    final newEmail = emailController.text.trim();
    try {
      if (user != null) {
        await user.updateDisplayName(newName);
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({'name': newName, 'email': newEmail});
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile updated successfully!')),
          );
          Navigator.pop(context);
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update profile.')),
        );
      }
    }
    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return PhoneFrame(
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text('Edit Profile'),
          backgroundColor: Colors.blue,
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const SizedBox(height: 16),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name'),
                style: const TextStyle(color: Colors.black),
                cursorColor: Colors.black,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(color: Colors.black),
                cursorColor: Colors.black,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: isLoading ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  side: BorderSide(color: Colors.grey.shade300),
                  padding: const EdgeInsets.symmetric(
                    vertical: 14,
                    horizontal: 24,
                  ),
                ),
                child: Text(isLoading ? 'Saving...' : 'Save Changes'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Local PhoneFrame copied from main.dart to avoid importing main.dart
class PhoneFrame extends StatelessWidget {
  final Widget child;

  const PhoneFrame({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[300],
      body: Center(
        child: Container(
          width: 375, // iPhone-like width
          height: 812, // iPhone-like height
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(40),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 20,
                spreadRadius: 5,
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

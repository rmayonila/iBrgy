// ignore_for_file: use_build_context_synchronously
import 'package:flutter/foundation.dart'; // For web check
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'add_moderator_account_page.dart';
import '../services/subscription_service.dart';
import '../widgets/subscription_widgets.dart';

class ManageModeratorsPage extends StatelessWidget {
  const ManageModeratorsPage({super.key});

  @override
  Widget build(BuildContext context) {
    Widget mobileUI = Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Moderator Accounts',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: Colors.grey.shade200, height: 1.0),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.blue,
        elevation: 4,
        icon: const Icon(Icons.add),
        label: const Text("Add New Moderator"),
        onPressed: () async {
          // Check subscription limit before allowing add
          final snapshot = await FirebaseFirestore.instance
              .collection('users')
              .where(
                'role',
                whereIn: ['staff', 'moderator', 'Staff', 'Moderator'],
              )
              .get();

          final currentCount = snapshot.docs.length;
          final canAdd = await checkSubscriptionLimit(
            context: context,
            action: 'add_moderator',
            currentCount: currentCount,
          );

          if (canAdd) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AddModeratorAccountPage(),
              ),
            );
          }
        },
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .where(
              'role',
              whereIn: ['staff', 'moderator', 'Staff', 'Moderator'],
            )
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline, size: 80, color: Colors.grey[200]),
                  const SizedBox(height: 16),
                  Text(
                    'No staff accounts found.',
                    style: TextStyle(color: Colors.grey[400], fontSize: 16),
                  ),
                ],
              ),
            );
          }

          final users = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: users.length,
            itemBuilder: (context, index) {
              final userData = users[index].data() as Map<String, dynamic>;
              final docId = users[index].id;

              // Using the extracted widget to prevent lag
              return ModeratorCard(
                key: ValueKey(docId),
                docId: docId,
                userData: userData,
              );
            },
          );
        },
      ),
    );

    if (kIsWeb) {
      return PhoneFrame(child: mobileUI);
    }
    return mobileUI;
  }
}

// --- EXTRACTED WIDGET FOR PERFORMANCE ---
class ModeratorCard extends StatelessWidget {
  final String docId;
  final Map<String, dynamic> userData;

  const ModeratorCard({super.key, required this.docId, required this.userData});

  @override
  Widget build(BuildContext context) {
    final name = userData['name'] ?? 'No Name';
    final email = userData['email'] ?? 'No Email';
    final role = userData['role'] ?? 'Staff';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          radius: 22,
          backgroundColor: Colors.blue.shade50,
          child: Text(
            name.isNotEmpty ? name[0].toUpperCase() : '?',
            style: const TextStyle(
              color: Colors.blue,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ),
        title: Text(
          name,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: Colors.black,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              email,
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
            Text(
              'Role: $role',
              style: TextStyle(color: Colors.blue[300], fontSize: 11),
            ),
          ],
        ),
        trailing: PopupMenuButton(
          color: Colors.white, // Ensure white background
          surfaceTintColor: Colors.white, // Ensures no material tint
          icon: Icon(Icons.more_vert, color: Colors.grey[400]),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit_outlined, color: Colors.blue, size: 20),
                  SizedBox(width: 8),
                  Text("Edit Details", style: TextStyle(color: Colors.black87)),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete_outline, color: Colors.red, size: 20),
                  SizedBox(width: 8),
                  Text("Remove Access", style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
          onSelected: (value) {
            if (value == 'delete') {
              _confirmDelete(context, docId, name);
            } else if (value == 'edit') {
              _showEditDialog(context, docId, name, email, userData);
            }
          },
        ),
      ),
    );
  }

  // --- DELETE FUNCTION ---
  void _confirmDelete(BuildContext context, String docId, String name) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          "Remove Account?",
          style: TextStyle(color: Colors.black),
        ),
        content: Container(
          width: 300,
          constraints: const BoxConstraints(maxWidth: 300),
          child: Text(
            "Are you sure you want to remove $name? They will no longer be able to log in.",
            style: const TextStyle(color: Colors.black87),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(foregroundColor: Colors.grey),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              FocusScope.of(context).unfocus();
              Navigator.pop(context);
              await Future.delayed(const Duration(milliseconds: 400));

              try {
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(docId)
                    .delete();

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Account removed successfully"),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text("Error: $e")));
                }
              }
            },
            child: const Text("Remove", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // --- EDIT FUNCTION ---
  void _showEditDialog(
    BuildContext context,
    String docId,
    String currentName,
    String currentEmail,
    Map<String, dynamic> userData,
  ) {
    final nameController = TextEditingController(text: currentName);
    final emailController = TextEditingController(text: currentEmail);

    // --- PASSWORD LOGIC ---
    // 1. Get password from Firestore (if it exists)
    String savedPassword = userData['password'] ?? '';
    bool hasSavedPassword = savedPassword.isNotEmpty;

    // 2. Setup Controller
    // If we have it, show it. If not, show "Not Available" (instead of stars)
    final currentPassController = TextEditingController(
      text: hasSavedPassword ? savedPassword : "Not Available (Reset Required)",
    );

    final passwordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          "Edit Moderator Details",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        content: Container(
          width: 320,
          constraints: const BoxConstraints(maxWidth: 320),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(bottom: 12.0),
                  child: Text(
                    "ACCOUNT DETAILS",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                TextField(
                  controller: nameController,
                  style: const TextStyle(color: Colors.black),
                  decoration: const InputDecoration(
                    labelText: "Full Name",
                    labelStyle: TextStyle(color: Colors.black54),
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 14,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: emailController,
                  style: const TextStyle(color: Colors.black),
                  decoration: const InputDecoration(
                    labelText: "Email Address",
                    labelStyle: TextStyle(color: Colors.black54),
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 14,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Padding(
                  padding: EdgeInsets.only(bottom: 12.0),
                  child: Text(
                    "CHANGE PASSWORD (OPTIONAL)",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),

                // --- CURRENT PASSWORD FIELD ---
                TextField(
                  controller: currentPassController,
                  readOnly: true,
                  enableInteractiveSelection: false,
                  // VISIBILITY LOGIC:
                  // If we have a password -> Show it (obscureText: false)
                  // If we don't -> Show text "Not Available" (obscureText: false)
                  // We effectively NEVER obscure it now, per your request.
                  obscureText: false,
                  style: TextStyle(
                    // Black if real password, Red if missing
                    color: hasSavedPassword ? Colors.black : Colors.red,
                    fontWeight: hasSavedPassword
                        ? FontWeight.normal
                        : FontWeight.bold,
                  ),
                  decoration: InputDecoration(
                    labelText: "Current Password",
                    floatingLabelBehavior: FloatingLabelBehavior.always,
                    // If hidden, explain why
                    helperText: hasSavedPassword
                        ? "Visible to Admin"
                        : "Old account: Password was not saved.",
                    labelStyle: const TextStyle(color: Colors.black54),
                    border: const OutlineInputBorder(),
                    fillColor: const Color(0xFFF5F5F5),
                    filled: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 14,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: passwordController,
                  obscureText: true,
                  style: const TextStyle(color: Colors.black),
                  decoration: const InputDecoration(
                    labelText: "New Password",
                    hintText: "Enter to change",
                    labelStyle: TextStyle(color: Colors.black54),
                    hintStyle: TextStyle(color: Colors.grey),
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 14,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: confirmPasswordController,
                  obscureText: true,
                  style: const TextStyle(color: Colors.black),
                  decoration: const InputDecoration(
                    labelText: "Confirm Password",
                    hintText: "Re-enter new password",
                    labelStyle: TextStyle(color: Colors.black54),
                    hintStyle: TextStyle(color: Colors.grey),
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              FocusManager.instance.primaryFocus?.unfocus();

              if (passwordController.text.isNotEmpty &&
                  passwordController.text != confirmPasswordController.text) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Passwords do not match"),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              final newName = nameController.text.trim();
              final newEmail = emailController.text.trim();
              final newPass = passwordController.text;

              await Future.delayed(const Duration(milliseconds: 200));

              if (context.mounted) Navigator.pop(context);

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Saving changes..."),
                    duration: Duration(seconds: 1),
                  ),
                );
              }

              await Future.delayed(const Duration(milliseconds: 600));

              try {
                // Update map
                Map<String, dynamic> updateData = {
                  'name': newName,
                  'email': newEmail,
                };

                // CRITICAL: IF ADMIN CHANGES PASSWORD, SAVE THE NEW ONE TO DB
                // This fixes the "Not Available" issue for old accounts if you reset them.
                if (newPass.isNotEmpty) {
                  updateData['password'] = newPass;
                }

                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(docId)
                    .update(updateData);

                String message = "Details updated successfully";
                if (newPass.isNotEmpty) {
                  try {
                    await FirebaseAuth.instance.sendPasswordResetEmail(
                      email: newEmail,
                    );
                    message = "Details saved. Password reset email sent.";
                  } catch (e) {
                    message = "Saved, but failed to send password reset.";
                  }
                }

                if (context.mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(message)));
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text("Update failed: $e")));
                }
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.blue,
              textStyle: const TextStyle(fontWeight: FontWeight.bold),
            ),
            child: const Text("Save"),
          ),
        ],
      ),
    );
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

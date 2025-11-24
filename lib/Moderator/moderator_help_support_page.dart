import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class ModeratorHelpSupportPage extends StatelessWidget {
  const ModeratorHelpSupportPage({super.key});

  @override
  Widget build(BuildContext context) {
    Widget mobileContent = Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Help & Support',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Contact Information
                _buildSupportSection(
                  icon: Icons.email,
                  title: 'Email Support',
                  subtitle: 'Get in touch with our support team',
                  content:
                      'support@ibrgy.com\n\nWe typically respond within 24 hours during business days.',
                ),
                const SizedBox(height: 25),

                // Phone Support
                _buildSupportSection(
                  icon: Icons.phone,
                  title: 'Phone Support',
                  subtitle: 'Call us for immediate assistance',
                  content:
                      '+63 (2) 8123-4567\n\nAvailable Monday to Friday, 8:00 AM - 5:00 PM',
                ),
                const SizedBox(height: 25),

                // FAQ
                _buildSupportSection(
                  icon: Icons.help,
                  title: 'Frequently Asked Questions',
                  subtitle: 'Quick answers to common questions',
                  content:
                      '• How do I reset my password?\n• How to manage barangay officials?\n• How to create announcements?\n• How to handle emergency contacts?\n• How to manage user accounts?\n• How to generate reports?',
                ),
                const SizedBox(height: 25),

                // Emergency Contact
                _buildSupportSection(
                  icon: Icons.warning,
                  title: 'Emergency Technical Support',
                  subtitle: 'For critical system issues',
                  content:
                      'For urgent technical issues affecting barangay services, contact our emergency tech support line at +63 (2) 8123-4567 (Emergency Line). Available 24/7 for critical system outages.',
                ),
                const SizedBox(height: 30),

                // Contact Buttons
                Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () {
                          _showContactDialog(
                            context,
                            'Email Support',
                            'We will open your email client to send a message to support@ibrgy.com',
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Contact Support via Email',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: OutlinedButton(
                        onPressed: () {
                          _showContactDialog(
                            context,
                            'Phone Support',
                            'Calling support number: +63 (2) 8123-4567',
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          side: const BorderSide(color: Colors.blue),
                        ),
                        child: const Text(
                          'Call Support',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.blue,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (kIsWeb) {
      return PhoneFrame(child: mobileContent);
    }

    return mobileContent;
  }

  Widget _buildSupportSection({
    required IconData icon,
    required String title,
    required String subtitle,
    required String content,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.blue, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  void _showContactDialog(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
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

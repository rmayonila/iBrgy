import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EmergencyHotlinePage extends StatelessWidget {
  const EmergencyHotlinePage({super.key});

  void _onItemTapped(BuildContext context, int index) {
    if (index == 0) {
      Navigator.pushReplacementNamed(context, '/admin-dashboard');
    } else if (index == 2) {
      Navigator.pushReplacementNamed(context, '/announcement');
    } else if (index == 3) {
      Navigator.pushReplacementNamed(context, '/brgy-officials');
    } else if (index == 4) {
      Navigator.pushReplacementNamed(context, '/account-settings');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1, // Phone icon selected
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.white,
        showSelectedLabels: true,
        elevation: 8,
        onTap: (index) => _onItemTapped(context, index),
        // consistent label styles (use defaults)
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
            tooltip: '',
            backgroundColor: Colors.white,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.phone),
            label: 'Emergency',
            tooltip: '',
            backgroundColor: Colors.white,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.announcement, size: 30),
            label: 'Updates',
            tooltip: '',
            backgroundColor: Colors.white,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'People',
            tooltip: '',
            backgroundColor: Colors.white,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
            tooltip: '',
            backgroundColor: Colors.white,
          ),
        ],
      ),

      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(0),
        child: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: Colors.white,
          elevation: 0,
        ),
      ),

      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with iBrgy logo (match AdminDashboard sizing)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Align(
              alignment: Alignment.topLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 5,
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
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: const [
                Icon(Icons.phone, color: Colors.red),
                SizedBox(width: 8),
                Text(
                  'EMERGENCY HOTLINES',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Barangay Emergency Response',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 24),
                    StreamBuilder<DocumentSnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('settings')
                          .doc('hotlines')
                          .snapshots(),
                      builder: (context, snapshot) {
                        final numbers = <String>[];
                        if (snapshot.hasData && snapshot.data!.exists) {
                          final data =
                              snapshot.data!.data() as Map<String, dynamic>?;
                          if (data != null && data['numbers'] is List) {
                            for (var v in data['numbers']) {
                              numbers.add(v?.toString() ?? '');
                            }
                          }
                        }

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildEmergencyField(
                              'Local Police Station:',
                              numbers.isNotEmpty ? numbers[0] : '',
                            ),
                            const SizedBox(height: 16),
                            _buildEmergencyField(
                              'Local Fire Department (BFP):',
                              numbers.length > 1 ? numbers[1] : '',
                            ),
                            const SizedBox(height: 16),
                            _buildEmergencyField(
                              'Local Hospital/Ambulance Service:',
                              numbers.length > 2 ? numbers[2] : '',
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        Material(
          elevation: 2,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      value.isEmpty ? '' : value,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: value.isEmpty
                            ? FontWeight.w400
                            : FontWeight.w500,
                        color: value.isEmpty
                            ? Colors.grey.shade400
                            : Colors.black,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  Builder(
                    builder: (context) => InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: value.isNotEmpty
                          ? () {
                              Clipboard.setData(ClipboardData(text: value));
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Number copied to clipboard'),
                                  duration: const Duration(seconds: 1),
                                ),
                              );
                            }
                          : null,
                      child: Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: value.isNotEmpty
                              ? Colors.blue.shade50
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: value.isNotEmpty
                                ? Colors.blue
                                : Colors.grey.shade300,
                            width: 2,
                          ),
                        ),
                        child: Icon(
                          Icons.copy_outlined,
                          size: 20,
                          color: value.isNotEmpty
                              ? Colors.blue.shade700
                              : Colors.grey.shade400,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

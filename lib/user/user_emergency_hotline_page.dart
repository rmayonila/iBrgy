import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/emergency_store.dart';

class UserEmergencyHotlinePage extends StatelessWidget {
  const UserEmergencyHotlinePage({super.key});

  void _onItemTapped(BuildContext context, int index) {
    if (index == 0) {
      Navigator.pushReplacementNamed(context, '/user-home');
    } else if (index == 2) {
      Navigator.pushReplacementNamed(context, '/user-announcement');
    } else if (index == 3) {
      Navigator.pushReplacementNamed(context, '/user-brgy-officials');
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
        selectedLabelStyle: const TextStyle(color: Colors.black),
        unselectedLabelStyle: const TextStyle(color: Colors.black),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.phone), label: 'Emergency'),
          BottomNavigationBarItem(
            icon: Icon(Icons.announcement, size: 30),
            label: 'Updates',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'People'),
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
          // Updated iBrgy header with logo and styled text
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                const SizedBox(width: 16),
                Align(
                  alignment: Alignment.centerLeft,
                  child: RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: 'iB',
                          style: TextStyle(
                            fontSize: 25,
                            fontWeight: FontWeight.bold,
                            color: Colors.lightBlue,
                          ),
                        ),
                        TextSpan(
                          text: 'rgy',
                          style: TextStyle(
                            fontSize: 25,
                            fontWeight: FontWeight.bold,
                            color: const Color.fromARGB(255, 35, 108, 168),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
              ],
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
                child: ValueListenableBuilder<List<Map<String, String>>>(
                  valueListenable: EmergencyStore.instance.notifier,
                  builder: (context, list, _) {
                    final police = (list.length > 1)
                        ? (list[1]['number'] ?? '')
                        : '';
                    final fire = (list.length > 2)
                        ? (list[2]['number'] ?? '')
                        : '';
                    final hospital = (list.length > 3)
                        ? (list[3]['number'] ?? '')
                        : '';
                    return Column(
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
                        _buildEmergencyField('Local Police Station:', police),
                        const SizedBox(height: 16),
                        _buildEmergencyField(
                          'Local Fire Department (BFP):',
                          fire,
                        ),
                        const SizedBox(height: 16),
                        _buildEmergencyField(
                          'Local Hospital/Ambulance Service:',
                          hospital,
                        ),
                      ],
                    );
                  },
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

import 'package:flutter/material.dart';

class AdminHomePage extends StatefulWidget {
  const AdminHomePage({super.key});

  @override
  State<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  // Start with no seeded items — show placeholder for empty state
  List<Map<String, String>> infoItems = [];

  int _selectedIndex = 0;

  void _onItemTapped(BuildContext context, int index) {
    // Admin navigation mapping:
    // 0 -> Home (stay on admin home)
    // 1 -> Emergency Hotline
    // 2 -> Updates / Announcement
    // 3 -> People / Brgy Officials
    // 4 -> Profile / Account Settings
    if (index == 1) {
      Navigator.pushReplacementNamed(context, '/emergency-hotline');
      return;
    }

    if (index == 2) {
      Navigator.pushReplacementNamed(context, '/announcement');
      return;
    }

    if (index == 3) {
      Navigator.pushReplacementNamed(context, '/brgy-officials');
      return;
    }

    if (index == 4) {
      Navigator.pushReplacementNamed(context, '/account-settings');
      return;
    }

    // index == 0 -> stay on home tab
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Column(
          children: [
            // --- HEADER: iBrgy style copied from admin_dashboard ---
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(13),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 20.0,
                vertical: 16.0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Left side: Home Icon + iBrgy Text + Back Arrow
                  Row(
                    children: [
                      Icon(Icons.home, color: Colors.blue.shade700, size: 30),
                      const SizedBox(width: 8),
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: 'iB',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                            TextSpan(
                              text: 'rgy',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: const Color.fromARGB(255, 5, 81, 143),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Info cards list
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Community Information',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        // 5. REMOVED "ADD" BUTTON
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Info cards / Empty placeholder
                    if (infoItems.isEmpty)
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.55,
                        child: const Center(
                          child: Text(
                            'NO BARANGAY SERVICES POSTED',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black54,
                            ),
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
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
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
    );
  }
}

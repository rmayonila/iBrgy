import 'package:flutter/material.dart';

// Category colors and icons mapping
const Map<String, Map<String, dynamic>> categoryConfig = {
  'Health & Welfare': {'color': Color(0xFF4CAF50), 'icon': Icons.favorite},
  'Brgy Clearance/Permit Process': {
    'color': Color(0xFFFFA726),
    'icon': Icons.assignment,
  },
  'Brgy Hall Schedule': {'color': Color(0xFF29B6F6), 'icon': Icons.schedule},
  'Emergency Services': {'color': Color(0xFFEF5350), 'icon': Icons.emergency},
  'Events & Announcements': {'color': Color(0xFF7E57C2), 'icon': Icons.event},
  'Community Programs': {'color': Color(0xFF26A69A), 'icon': Icons.groups},
};

// 1. Renamed to UserHomePage
class UserHomePage extends StatefulWidget {
  const UserHomePage({super.key});

  @override
  // 2. Renamed state
  State<UserHomePage> createState() => _UserHomePageState();
}

// 3. Renamed state class
class _UserHomePageState extends State<UserHomePage> {
  // Sample info items (replace with Firestore data later)
  List<Map<String, String>> infoItems = [
    {
      'title': 'Health & Welfare',
      'category': 'Health & Welfare',
      'description':
          'Schedules for the Brgy Health Center (BHC), available services (immunization, check-ups), contact information, and health guidelines.',
      'lastUpdated': '2 days ago',
    },
    {
      'title': 'Brgy Clearance/Permit Process',
      'category': 'Brgy Clearance/Permit Process',
      'description':
          'Step-by-step guide on how to secure a Brgy Clearance (requirements, fees, processing time, and online application status).',
      'lastUpdated': '1 week ago',
    },
    {
      'title': 'Brgy Hall Schedule',
      'category': 'Brgy Hall Schedule',
      'description':
          'Operating hours of the Brgy Hall and specific department schedules (e.g., Treasurer\'s office hours, Mayor\'s receiving days).',
      'lastUpdated': 'Today',
    },
  ];

  int _selectedIndex = 0;

  // 4. Simplified navigation logic for 4 tabs
  void _onItemTapped(int index) {
    if (index == 1) {
      // Emergency
      Navigator.pushReplacementNamed(context, '/user-emergency-hotline');
    } else if (index == 2) {
      // Updates
      Navigator.pushReplacementNamed(context, '/user-announcement');
    } else if (index == 3) {
      // People
      Navigator.pushReplacementNamed(context, '/user-brgy-officials');
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
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
                    color: Colors.black.withOpacity(0.05),
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
                  // Right side: Back icon moved here
                  IconButton(
                    icon: Icon(Icons.arrow_forward_ios, color: Colors.blue),
                    onPressed: () {
                      Navigator.pushReplacementNamed(context, '/');
                    },
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

                    // Info cards
                    for (int i = 0; i < infoItems.length; i++)
                      // 6. Modified card builder to remove index/staff functions
                      _buildEnhancedInfoCard(context, infoItems[i]),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      // 7. FIXED BOTTOM NAVIGATION BAR
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.white,
        showSelectedLabels: true,
        elevation: 8,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.phone), label: 'Emergency'),
          BottomNavigationBarItem(
            icon: Icon(Icons.announcement, size: 30),
            label: 'Updates',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'People'),
          // "Profile" item removed
        ],
      ),
    );
  }

  // 8. Modified Info Card for USER (no edit/delete)
  Widget _buildEnhancedInfoCard(
    BuildContext context,
    Map<String, String> info,
  ) {
    final category = info['category'] ?? 'Community Info';
    final config =
        categoryConfig[category] ?? {'color': Colors.grey, 'icon': Icons.info};

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category header with color bar
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: (config['color'] as Color).withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              border: Border(
                left: BorderSide(color: config['color'] as Color, width: 4),
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: (config['color'] as Color).withOpacity(0.3),
                  child: Icon(
                    config['icon'] as IconData,
                    color: config['color'] as Color,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        info['title'] ?? '',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        'Updated ${info['lastUpdated'] ?? 'recently'}',
                        style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                // 9. REMOVED PopupMenuButton (Edit/Delete)
              ],
            ),
          ),

          // Description
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  info['description'] ?? '',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[700],
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 12),
                // Action buttons (User-facing)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Full details: ${info['title']}'),
                          ),
                        );
                      },
                      icon: const Icon(Icons.read_more, size: 16),
                      label: const Text('Read More'),
                      style: TextButton.styleFrom(
                        foregroundColor: config['color'] as Color,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Shared: ${info['title']}')),
                        );
                      },
                      icon: const Icon(Icons.share, size: 16),
                      label: const Text('Share'),
                      style: TextButton.styleFrom(foregroundColor: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 10. REMOVED _showAddInfoDialog, _showEditInfoDialog, and _showDeleteConfirmation
}

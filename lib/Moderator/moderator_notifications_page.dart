import 'package:flutter/material.dart';

class ModeratorNotificationsPage extends StatelessWidget {
  const ModeratorNotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final notifications = [
      {
        'avatarUrl': null,
        'icon': Icons.announcement,
        'color': Colors.blue,
        'title': 'Barangay Office',
        'message': 'Barangay meeting this Saturday! Please attend.',
        'time': '2 hours ago',
        'unread': true,
      },
      {
        'avatarUrl': null,
        'icon': Icons.health_and_safety,
        'color': Colors.green,
        'title': 'Health Center',
        'message': 'Free vaccination drive tomorrow. Bring your ID.',
        'time': '1 day ago',
        'unread': false,
      },
      {
        'avatarUrl': null,
        'icon': Icons.warning,
        'color': Colors.orange,
        'title': 'Meralco',
        'message': 'Power interruption scheduled at 3PM.',
        'time': '3 days ago',
        'unread': true,
      },
    ];

    // Wrap the existing Scaffold with Phone frame
    return ModeratorPhoneFrame(
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              // --- HEADER: iBrgy style (same as ModeratorHomePage) ---
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
                                  color: Colors.blue.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    // Right side left empty (back handled by phone frame)
                  ],
                ),
              ),

              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: notifications.length,
                  separatorBuilder: (context, index) =>
                      const Divider(indent: 80, endIndent: 16, height: 0),
                  itemBuilder: (context, index) {
                    final notif = notifications[index];
                    return InkWell(
                      onTap: () {},
                      child: Container(
                        color: notif['unread'] as bool
                            ? Colors.blue[50]
                            : Colors.white,
                        child: ListTile(
                          leading: notif['avatarUrl'] != null
                              ? CircleAvatar(
                                  backgroundImage: NetworkImage(
                                    notif['avatarUrl'] as String,
                                  ),
                                )
                              : Icon(
                                  notif['icon'] as IconData,
                                  color: notif['color'] as Color,
                                  size: 32,
                                ),
                          title: Text(
                            notif['title'] as String,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(notif['message'] as String),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                notif['time'] as String,
                                style: const TextStyle(fontSize: 12),
                              ),
                              if (notif['unread'] as bool)
                                Container(
                                  margin: const EdgeInsets.only(top: 4),
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: Colors.blue,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Phone frame wrapper for web view (renamed to avoid conflicts)
class ModeratorPhoneFrame extends StatelessWidget {
  final Widget child;

  const ModeratorPhoneFrame({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Container(
          width: 375, // iPhone-like width
          height: 812, // iPhone-like height
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(40),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(76),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(40),
            child: Container(
              color: Colors.white, // interior background color
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

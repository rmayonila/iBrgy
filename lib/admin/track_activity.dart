import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/notification_service.dart';

class TrackActivityPage extends StatefulWidget {
  const TrackActivityPage({super.key});

  @override
  State<TrackActivityPage> createState() => _TrackActivityPageState();
}

class _TrackActivityPageState extends State<TrackActivityPage> {
  // Enhanced icons mapping for different notification types and actions
  final Map<String, IconData> _notificationIcons = {
    // Moderator actions
    'moderator_added': Icons.add_circle,
    'moderator_edited': Icons.edit,
    'moderator_deleted': Icons.delete,

    // Page specific icons
    'services': Icons.miscellaneous_services,
    'emergency': Icons.emergency,
    'updates': Icons.campaign,
    'officials': Icons.people,

    // Legacy types
    'moderator_post': Icons.person,
    'user_registration': Icons.person_add,
    'document_request': Icons.description,
    'system_alert': Icons.warning,
    'security_update': Icons.security,
    'backup': Icons.backup,
    'report': Icons.analytics,
  };

  // Enhanced colors mapping
  final Map<String, Color> _notificationColors = {
    // Action-based colors
    'moderator_added': Colors.green,
    'moderator_edited': Colors.orange,
    'moderator_deleted': Colors.red,

    // Page-based colors
    'services': Colors.blue,
    'emergency': Colors.red,
    'updates': Colors.purple,
    'officials': Colors.teal,

    // Legacy colors
    'user_registration': Colors.green,
    'document_request': Colors.orange,
    'system_alert': Colors.red,
    'security_update': Colors.purple,
    'backup': Colors.blue,
    'report': Colors.teal,
  };

  // Get icon for notification based on type and action
  IconData _getNotificationIcon(String type, String? action, String? page) {
    // For moderator actions
    if (action != null) {
      return _notificationIcons['moderator_$action'] ?? Icons.notifications;
    }

    // For page-specific notifications
    if (page != null && _notificationIcons.containsKey(page)) {
      return _notificationIcons[page]!;
    }

    // Fallback to type-based icon
    return _notificationIcons[type] ?? Icons.notifications;
  }

  // Get color for notification based on type and action
  Color _getNotificationColor(String type, String? action, String? page) {
    // For moderator actions
    if (action != null) {
      return _notificationColors['moderator_$action'] ?? Colors.grey;
    }

    // For page-specific notifications
    if (page != null && _notificationColors.containsKey(page)) {
      return _notificationColors[page]!;
    }

    // Fallback to type-based color
    return _notificationColors[type] ?? Colors.grey;
  }

  // Format timestamp with detailed date and time
  String _formatTimestamp(Timestamp timestamp) {
    final time = timestamp.toDate();

    // Get detailed date and time
    final month = time.month.toString().padLeft(2, '0');
    final day = time.day.toString().padLeft(2, '0');
    final year = time.year.toString();
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');

    return '$month/$day/$year at $hour:${minute}';
  }

  // Get relative time for subtitle
  String _getRelativeTime(Timestamp timestamp) {
    final now = DateTime.now();
    final time = timestamp.toDate();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return _formatTimestamp(timestamp);
    }
  }

  void _handleNotificationTap(String notificationId, bool isRead) {
    if (!isRead) {
      NotificationService.markAsRead(notificationId);
    }
    // You can add additional navigation logic here based on notification data
  }

  @override
  Widget build(BuildContext context) {
    return PhoneFrame(
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.of(context).pop(),
          ),
          automaticallyImplyLeading: false,
          title: const Text('Notifications'),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 1,
          actions: [
            StreamBuilder<QuerySnapshot>(
              stream: NotificationService.getAdminNotifications(),
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const SizedBox();
                }

                final hasUnread = snapshot.data!.docs.any(
                  (doc) => doc['read'] == false,
                );

                return IconButton(
                  icon: Stack(
                    children: [
                      const Icon(Icons.checklist, color: Colors.black),
                      if (hasUnread)
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                  onPressed: hasUnread
                      ? () {
                          NotificationService.markAllAsRead();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('All notifications marked as read'),
                            ),
                          );
                        }
                      : null,
                );
              },
            ),
          ],
        ),
        body: Container(
          color: Colors.white,
          child: StreamBuilder<QuerySnapshot>(
            stream: NotificationService.getAdminNotifications(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'Error loading notifications',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ],
                  ),
                );
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final notifications = snapshot.data!.docs;

              if (notifications.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.notifications_none,
                        size: 80,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 20),
                      Text(
                        'No notifications yet',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey,
                        ),
                      ),
                      SizedBox(height: 10),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 40),
                        child: Text(
                          'You will receive notifications when moderators add, edit, or delete posts in Services, Emergency, Updates, or Officials pages.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: notifications.length,
                separatorBuilder: (context, index) =>
                    const Divider(indent: 80, endIndent: 16, height: 0),
                itemBuilder: (context, index) {
                  final notification = notifications[index];
                  final data = notification.data() as Map<String, dynamic>;
                  final notificationId = notification.id;
                  final isRead = data['read'] ?? false;
                  final type = data['type'] ?? 'moderator_post';
                  final action = data['action'] as String?;
                  final page = data['page'] as String?;
                  final title = data['title'] ?? 'Notification';
                  final message = data['message'] ?? '';
                  final timestamp = data['timestamp'] as Timestamp?;
                  final senderName = data['senderName'] as String?;
                  final postTitle = data['postTitle'] as String?;

                  return InkWell(
                    onTap: () => _handleNotificationTap(notificationId, isRead),
                    onLongPress: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Delete Notification'),
                          content: const Text(
                            'Are you sure you want to delete this notification?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () {
                                NotificationService.deleteNotification(
                                  notificationId,
                                );
                                Navigator.pop(context);
                              },
                              child: const Text(
                                'Delete',
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                    child: Container(
                      color: isRead ? Colors.white : Colors.blue[50],
                      child: ListTile(
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: _getNotificationColor(
                              type,
                              action,
                              page,
                            ).withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _getNotificationIcon(type, action, page),
                            color: _getNotificationColor(type, action, page),
                            size: 20,
                          ),
                        ),
                        title: Text(
                          title,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isRead ? Colors.black87 : Colors.blue[800],
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              message,
                              style: TextStyle(
                                color: isRead
                                    ? Colors.grey[600]
                                    : Colors.blue[600],
                              ),
                            ),
                            if (senderName != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 2.0),
                                child: Text(
                                  'By: $senderName',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                            if (timestamp != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 2.0),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.access_time,
                                      size: 12,
                                      color: Colors.grey[500],
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      _getRelativeTime(timestamp),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[500],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      _formatTimestamp(timestamp),
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey[400],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (!isRead)
                              Container(
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
              );
            },
          ),
        ),
      ),
    );
  }
}

// PhoneFrame widget
class PhoneFrame extends StatelessWidget {
  final Widget child;

  const PhoneFrame({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
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
                blurRadius: 20,
                spreadRadius: 5,
                offset: const Offset(0, 5),
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

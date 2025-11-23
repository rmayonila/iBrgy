import 'package:flutter/material.dart';
import 'splash_screen.dart';
import 'login_page.dart';
import 'admin/admin_home.dart' as admin;
import 'admin/emergency_hotline_page.dart';
import 'admin/announcement_page.dart';
import 'admin/brgy_officials_page.dart';
import 'admin/account_settings_page.dart';
import 'Moderator/moderator_home_page.dart' as mod_home;
import 'Moderator/moderator_emergency_hotline_page.dart' as mod_emergency;
import 'Moderator/moderator_announcement_page.dart' as mod_announcement;
import 'Moderator/moderator_notifications_page.dart' as mod_notifications;
import 'Moderator/moderator_brgy_officials_page.dart' as mod_brgy;
import 'Moderator/moderator_account_settings_page.dart' as mod_account;
import 'firebase_options.dart';
import 'user/user_home_page.dart' as user;
import 'user/user_emergency_hotline_page.dart';
import 'user/user_announcement_page.dart';
import 'user/user_brgy_officials_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeFirebase();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  static State<MyApp>? of(BuildContext context) =>
      context.findAncestorStateOfType<_MyAppState>();

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.system;

  void setThemeMode(ThemeMode mode) {
    setState(() {
      _themeMode = mode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'iBrgy',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.black,
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.white),
          bodyMedium: TextStyle(color: Colors.white),
          bodySmall: TextStyle(color: Colors.white),
          titleLarge: TextStyle(color: Colors.white),
          titleMedium: TextStyle(color: Colors.white),
          titleSmall: TextStyle(color: Colors.white),
          labelLarge: TextStyle(color: Colors.white),
          labelMedium: TextStyle(color: Colors.white),
          labelSmall: TextStyle(color: Colors.white),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
        ),
      ),
      themeMode: _themeMode,
      home: const PhoneFrame(child: SplashScreen()),
      routes: {
        '/login': (context) => PhoneFrame(child: LoginPage()),
        '/moderator-home': (context) =>
            PhoneFrame(child: mod_home.ModeratorHomePage()),
        '/user-home': (context) => PhoneFrame(child: user.UserHomePage()),
        '/user-emergency-hotline': (context) =>
            PhoneFrame(child: UserEmergencyHotlinePage()),
        '/user-announcement': (context) =>
            PhoneFrame(child: UserAnnouncementPage()),
        '/user-brgy-officials': (context) =>
            PhoneFrame(child: UserBrgyOfficialsPage()),
        '/moderator-emergency-hotline': (context) =>
            PhoneFrame(child: mod_emergency.ModeratorEmergencyHotlinePage()),
        '/moderator-notifications': (context) =>
            PhoneFrame(child: mod_notifications.ModeratorNotificationsPage()),
        '/moderator-announcement': (context) =>
            PhoneFrame(child: mod_announcement.ModeratorAnnouncementPage()),
        '/moderator-brgy-officials': (context) =>
            PhoneFrame(child: mod_brgy.ModeratorBrgyOfficialsPage()),
        '/moderator-account-settings': (context) =>
            PhoneFrame(child: mod_account.ModeratorAccountSettingsPage()),
        '/admin-home': (context) => PhoneFrame(child: admin.AdminHomePage()),
        '/emergency-hotline': (context) =>
            PhoneFrame(child: EmergencyHotlinePage()),
        '/announcement': (context) => PhoneFrame(child: AnnouncementPage()),
        '/brgy-officials': (context) => PhoneFrame(child: BrgyOfficialsPage()),
        '/account-settings': (context) =>
            PhoneFrame(child: AccountSettingsPage()),
      },
    );
  }
}

// Phone frame wrapper for web view
class PhoneFrame extends StatelessWidget {
  final Widget child;

  const PhoneFrame({super.key, required this.child});

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
            child: child,
          ),
        ),
      ),
    );
  }
}

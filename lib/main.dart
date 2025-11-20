import 'package:flutter/material.dart';
import 'splash_screen.dart';
import 'login_page.dart';
import 'admin/admin_home.dart';
import 'admin/emergency_hotline_page.dart';
import 'admin/announcement_page.dart';
import 'admin/brgy_officials_page.dart';
import 'admin/account_settings_page.dart';
import 'staff/staff_home_page.dart';
import 'staff/staff_emergency_hotline_page.dart' as staff;
import 'staff/staff_announcement_page.dart';
import 'staff/staff_notifications_page.dart';
import 'staff/staff_brgy_officials_page.dart' as staff;
import 'staff/staff_account_settings_page.dart';
import 'firebase_options.dart';
import 'user/user_home_page.dart';
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

  static _MyAppState? of(BuildContext context) =>
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
        '/staff-home': (context) => PhoneFrame(child: StaffHomePage()),
        '/user-home': (context) => PhoneFrame(child: UserHomePage()),
        '/user-emergency-hotline': (context) =>
            PhoneFrame(child: UserEmergencyHotlinePage()),
        '/user-announcement': (context) =>
            PhoneFrame(child: UserAnnouncementPage()),
        '/user-brgy-officials': (context) =>
            PhoneFrame(child: UserBrgyOfficialsPage()),
        '/staff-emergency-hotline': (context) =>
            PhoneFrame(child: staff.StaffEmergencyHotlinePage()),
        '/staff-notifications': (context) =>
            PhoneFrame(child: StaffNotificationsPage()),
        '/staff-announcement': (context) =>
            PhoneFrame(child: StaffAnnouncementPage()),
        '/staff-brgy-officials': (context) =>
            PhoneFrame(child: staff.StaffBrgyOfficialsPage()),
        '/staff-account-settings': (context) =>
            PhoneFrame(child: StaffAccountSettingsPage()),
        '/admin-dashboard': (context) => PhoneFrame(child: AdminHomePage()),
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

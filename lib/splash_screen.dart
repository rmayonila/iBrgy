import 'package:flutter/material.dart';
import 'dart:ui'; // Required for Glassmorphism blur
import 'package:google_fonts/google_fonts.dart'; // REQUIRED: Import this package

// --- 1. Phone Frame Wrapper ---
class PhoneFrame extends StatelessWidget {
  final Widget child;

  const PhoneFrame({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: Center(
        child: Container(
          width: 375,
          height: 812,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(40),
            boxShadow: [
              BoxShadow(
                color: const Color.fromARGB(76, 149, 191, 218),
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

// --- 2. Splash Screen ---
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _pulseController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    // Entrance Animation
    _mainController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
      ),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _mainController,
            curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
          ),
        );

    // Pulse Animation
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _mainController.forward();
  }

  @override
  void dispose() {
    _mainController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _handleUserTap() {
    Navigator.pushReplacementNamed(context, '/user-home');
  }

  @override
  Widget build(BuildContext context) {
    return PhoneFrame(
      child: Scaffold(
        body: Stack(
          children: [
            // --- Layer 1: Background ---
            _buildBackground(),

            // --- Layer 2: Content ---
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _handleUserTap,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Spacer(flex: 2),

                    // Logo
                    ScaleTransition(
                      scale: _scaleAnimation,
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: _buildLogo(),
                      ),
                    ),

                    const SizedBox(height: 40),

                    // Text Content
                    SlideTransition(
                      position: _slideAnimation,
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: Column(
                          children: [
                            // 1. HEADLINE (Updated to Serif Italic)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
                              child: Text(
                                "Bridging the Community",
                                textAlign: TextAlign.center,
                                style: GoogleFonts.playfairDisplay(
                                  // Using the "Beautiful" font style
                                  fontSize: 25,
                                  fontWeight:
                                      FontWeight.w600, // Semi-bold for clarity
                                  fontStyle: FontStyle
                                      .italic, // ITALIC to match your image
                                  color: const Color(
                                    0xFF0D47A1,
                                  ), // Deep Navy Blue (Solid)
                                  height: 1.1, // Tighter line height
                                ),
                              ),
                            ),

                            const SizedBox(height: 12),

                            // 2. SUBTITLE (Kept as Sans-Serif per request)
                            Text(
                              'Closer to You',
                              style: TextStyle(
                                // Standard font
                                fontSize: 16,
                                fontWeight: FontWeight.w400,
                                color: Colors
                                    .blueGrey
                                    .shade600, // Slightly darker for readability
                                letterSpacing: 0.5,
                              ),
                            ),

                            const SizedBox(height: 30),

                            // Divider
                            Container(
                              width: 40,
                              height: 3,
                              decoration: BoxDecoration(
                                color: Colors.blue.shade100,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),

                            const SizedBox(height: 25),

                            // 3. MOTTO
                            Text(
                              "SERVE  •  CONNECT  •  GROW",
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade400,
                                letterSpacing: 2.0,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const Spacer(flex: 3),

                    // Tap Hint
                    FadeTransition(
                      opacity: _pulseController,
                      child: Column(
                        children: [
                          Text(
                            "Tap screen to enter",
                            style: TextStyle(
                              color: Colors.blue.shade300,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // --- Layer 3: Admin Button ---
            Positioned(top: 50, right: 20, child: _buildAdminButton(context)),
          ],
        ),
      ),
    );
  }

  // --- Helpers ---

  Widget _buildBackground() {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFFF0F8FF),
                Colors.white,
                const Color(0xFFE3F2FD),
              ],
            ),
          ),
        ),
        Positioned(
          top: -100,
          right: -100,
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  Colors.blue.shade100.withOpacity(0.4),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        Positioned(
          bottom: -50,
          left: -50,
          child: Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  Colors.blue.shade200.withOpacity(0.3),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLogo() {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.15),
            blurRadius: 40,
            spreadRadius: 10,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipOval(
        child: Container(
          width: 200,
          height: 200,
          color: Colors.white,
          padding: const EdgeInsets.all(15),
          child: Image.asset(
            'assets/images/ibrgy_logo.jpg',
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }

  Widget _buildAdminButton(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.5),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.white.withOpacity(0.6)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                Navigator.pushNamed(context, '/login');
              },
              borderRadius: BorderRadius.circular(30),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.admin_panel_settings_rounded,
                      size: 20,
                      color: Colors.blue.shade700,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

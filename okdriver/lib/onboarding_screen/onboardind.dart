import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:okdriver/driver_auth_screen/send_otp.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  int currentPage = 0;
  final int totalPages = 4;

  final List<OnboardingData> onboardingPages = [
    OnboardingData(
      title: "Dashcam Recording",
      subtitle: "Drive Safe, Record Everything",
      description:
          "Record your journey with both front and back cameras. Keep evidence of your trips and ensure safety on the road with HD video recording.",
      icon: Icons.videocam,
      features: [
        "Front & Back Camera Recording",
        "HD Video Quality",
        "Auto Loop Recording",
        "Emergency Lock Feature"
      ],
      color: Colors.blue,
    ),
    OnboardingData(
      title: "Drowsiness Monitoring",
      subtitle: "Stay Alert, Stay Alive",
      description:
          "AI-powered drowsiness detection system monitors your alertness and warns you when you need to take a break. Your safety is our priority.",
      icon: Icons.visibility,
      features: [
        "Real-time Eye Tracking",
        "Fatigue Detection",
        "Audio & Visual Alerts",
        "Break Recommendations"
      ],
      color: Colors.orange,
    ),
    OnboardingData(
      title: "SOS Emergency Alert",
      subtitle: "Help When You Need It Most",
      description:
          "In case of accidents or emergencies, instantly alert your family members and nearby hospitals for immediate assistance and quick relief.",
      icon: Icons.emergency,
      features: [
        "One-Tap Emergency Alert",
        "Auto Family Notification",
        "Nearby Hospital Locator",
        "GPS Location Sharing"
      ],
      color: Colors.red,
    ),
    OnboardingData(
      title: "Convoi AI Assistant",
      subtitle: "Your Smart Driving Companion",
      description:
          "Interact with your intelligent AI assistant for navigation, weather updates, traffic information, and hands-free communication while driving.",
      icon: Icons.smart_toy,
      features: [
        "Voice Commands",
        "Smart Navigation",
        "Traffic Updates",
        "Hands-free Operation"
      ],
      color: Colors.green,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _animationController.forward();
  }

  void _nextPage() {
    if (currentPage < totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _navigateToPermissions();
    }
  }

  void _previousPage() {
    if (currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _skipOnboarding() {
    _navigateToPermissions();
  }

  void _navigateToPermissions() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => SendOTPScreen()),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Background gradient
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF1A1A1A),
                    Colors.black,
                  ],
                ),
              ),
            ),

            // Main content
            Column(
              children: [
                // PageView content
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (index) {
                      setState(() {
                        currentPage = index;
                      });
                      _animationController.reset();
                      _animationController.forward();
                    },
                    itemCount: totalPages,
                    itemBuilder: (context, index) {
                      final page = onboardingPages[index];
                      return FadeTransition(
                        opacity: _fadeAnimation,
                        child: SlideTransition(
                          position: _slideAnimation,
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              children: [
                                const SizedBox(height: 40),

                                // Feature icon
                                Container(
                                  width: 120,
                                  height: 120,
                                  decoration: BoxDecoration(
                                    color: page.color.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(60),
                                    border: Border.all(
                                      color: page.color.withOpacity(0.3),
                                      width: 2,
                                    ),
                                  ),
                                  child: Icon(
                                    page.icon,
                                    size: 60,
                                    color: page.color,
                                  ),
                                ),

                                const SizedBox(height: 40),

                                // Title
                                Text(
                                  page.title,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),

                                const SizedBox(height: 12),

                                // Subtitle
                                Text(
                                  page.subtitle,
                                  style: TextStyle(
                                    color: page.color,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  textAlign: TextAlign.center,
                                ),

                                const SizedBox(height: 24),

                                // Description
                                Text(
                                  page.description,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 16,
                                    height: 1.6,
                                  ),
                                  textAlign: TextAlign.center,
                                ),

                                const SizedBox(height: 40),

                                // Features list
                                Column(
                                  children: page.features.map((feature) {
                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 16),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 20,
                                        vertical: 12,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.05),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: Colors.white.withOpacity(0.1),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 24,
                                            height: 24,
                                            decoration: BoxDecoration(
                                              color:
                                                  page.color.withOpacity(0.2),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Icon(
                                              Icons.check,
                                              size: 16,
                                              color: page.color,
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: Text(
                                              feature,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Bottom navigation buttons
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      // Back button
                      if (currentPage > 0)
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _previousPage,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: const BorderSide(color: Colors.white30),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Back',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),

                      if (currentPage > 0) const SizedBox(width: 16),

                      // Next/Get Started button
                      Expanded(
                        flex: currentPage == 0 ? 1 : 2,
                        child: ElevatedButton(
                          onPressed: _nextPage,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            currentPage == totalPages - 1
                                ? 'Get Started'
                                : 'Next',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
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
    );
  }
}

// Onboarding data model
class OnboardingData {
  final String title;
  final String subtitle;
  final String description;
  final IconData icon;
  final List<String> features;
  final Color color;

  OnboardingData({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.icon,
    required this.features,
    required this.color,
  });
}

// Placeholder for permission screen
class PermissionScreen extends StatelessWidget {
  const PermissionScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          'Permissions Required',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.security,
              size: 80,
              color: Colors.white,
            ),
            SizedBox(height: 20),
            Text(
              'Permission Screen',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 10),
            Text(
              'This will be your permission screen',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

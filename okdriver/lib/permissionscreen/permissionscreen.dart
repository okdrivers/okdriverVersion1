import 'package:flutter/material.dart';
import 'package:okdriver/onboarding_screen/onboardind.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/services.dart';

// Theme Provider for managing light/dark themes
class ThemeProvider extends ChangeNotifier {
  bool _isDarkTheme = false;

  bool get isDarkTheme => _isDarkTheme;

  void toggleTheme() {
    _isDarkTheme = !_isDarkTheme;
    notifyListeners();
  }

  ThemeData get currentTheme => _isDarkTheme ? _darkTheme : _lightTheme;

  static final ThemeData _lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: Colors.black,
    scaffoldBackgroundColor: const Color(0xFFFAFAFA),
    cardColor: Colors.white,
    dividerColor: const Color(0xFFE0E0E0),
    textTheme: const TextTheme(
      titleLarge:
          TextStyle(color: Color(0xFF212121), fontWeight: FontWeight.bold),
      bodyLarge: TextStyle(color: Color(0xFF424242)),
      bodyMedium: TextStyle(color: Color(0xFF757575)),
    ),
  );

  static final ThemeData _darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: Colors.white,
    scaffoldBackgroundColor: const Color(0xFF121212),
    cardColor: const Color(0xFF1E1E1E),
    dividerColor: const Color(0xFF2A2A2A),
    textTheme: const TextTheme(
      titleLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      bodyLarge: TextStyle(color: Color(0xFFE0E0E0)),
      bodyMedium: TextStyle(color: Color(0xFFBDBDBD)),
    ),
  );
}

class PermissionScreen extends StatefulWidget {
  const PermissionScreen({Key? key}) : super(key: key);

  @override
  State<PermissionScreen> createState() => _PermissionScreenState();
}

class _PermissionScreenState extends State<PermissionScreen>
    with TickerProviderStateMixin {
  late AnimationController _mainAnimationController;
  late AnimationController _pulseController;
  late AnimationController _slideController;

  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _staggerAnimation;

  // Theme management
  final ThemeProvider _themeProvider = ThemeProvider();

  // Permission status tracking
  Map<Permission, PermissionStatus> permissionStatuses = {};
  bool isCheckingPermissions = false;
  bool allPermissionsGranted = false;
  int grantedCount = 0;

  // List of required permissions
  final List<PermissionData> requiredPermissions = [
    PermissionData(
      permission: Permission.camera,
      title: 'Camera Access',
      description: 'Capture photos and videos for your profile',
      icon: Icons.camera_alt_outlined,
      color: const Color(0xFF424242),
    ),
    PermissionData(
      permission: Permission.microphone,
      title: 'Microphone',
      description: 'Record audio for calls and voice messages',
      icon: Icons.mic_outlined,
      color: const Color(0xFF424242),
    ),
    PermissionData(
      permission: Permission.location,
      title: 'Location Services',
      description: 'Find nearby drivers and optimize routes',
      icon: Icons.location_on_outlined,
      color: const Color(0xFF424242),
    ),
    PermissionData(
      permission: Permission.notification,
      title: 'Push Notifications',
      description: 'Receive ride updates and important alerts',
      icon: Icons.notifications_outlined,
      color: const Color(0xFF424242),
    ),
    PermissionData(
      permission: Permission.bluetooth,
      title: 'Bluetooth',
      description: 'Connect with in-car systems seamlessly',
      icon: Icons.bluetooth_outlined,
      color: const Color(0xFF424242),
    ),
    PermissionData(
      permission: Permission.storage,
      title: 'Storage Access',
      description: 'Save trip data and offline maps',
      icon: Icons.folder_outlined,
      color: const Color(0xFF424242),
    ),
    PermissionData(
      permission: Permission.phone,
      title: 'Phone Access',
      description: 'Make emergency calls and contact support',
      icon: Icons.phone_outlined,
      color: const Color(0xFF424242),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _checkInitialPermissions();
  }

  void _initializeAnimations() {
    _mainAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _mainAnimationController,
      curve: Curves.easeOutQuart,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _staggerAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _mainAnimationController,
      curve: const Interval(0.3, 1.0, curve: Curves.easeOutQuart),
    ));

    _mainAnimationController.forward();
    _slideController.forward();
    _pulseController.repeat(reverse: true);
  }

  Future<void> _checkInitialPermissions() async {
    for (var permissionData in requiredPermissions) {
      final status = await permissionData.permission.status;
      permissionStatuses[permissionData.permission] = status;
    }
    _updatePermissionCounts();
    setState(() {});
  }

  void _updatePermissionCounts() {
    grantedCount = permissionStatuses.values
        .where((status) => status == PermissionStatus.granted)
        .length;
    allPermissionsGranted = grantedCount == requiredPermissions.length;
  }

  Future<void> _requestAllPermissions() async {
    setState(() {
      isCheckingPermissions = true;
    });

    // Add haptic feedback
    HapticFeedback.lightImpact();

    try {
      for (int i = 0; i < requiredPermissions.length; i++) {
        final permissionData = requiredPermissions[i];
        if (permissionStatuses[permissionData.permission] !=
            PermissionStatus.granted) {
          final status = await permissionData.permission.request();
          permissionStatuses[permissionData.permission] = status;

          setState(() {
            _updatePermissionCounts();
          });

          await Future.delayed(const Duration(milliseconds: 400));
        }
      }

      HapticFeedback.mediumImpact();

      if (allPermissionsGranted) {
        _showSuccessAnimation();
      } else {
        _showPartialPermissionDialog();
      }
    } catch (e) {
      _showErrorDialog('Error requesting permissions: $e');
    } finally {
      setState(() {
        isCheckingPermissions = false;
      });
    }
  }

  void _showSuccessAnimation() {
    HapticFeedback.heavyImpact();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _buildSuccessDialog(),
    );
  }

  Widget _buildSuccessDialog() {
    final isDark = _themeProvider.isDarkTheme;
    return AlertDialog(
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: isDark ? Colors.white : Colors.black,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check_rounded,
              color: isDark ? Colors.black : Colors.white,
              size: 40,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Perfect!',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'All permissions granted successfully.\nYou\'re ready to go!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: isDark ? const Color(0xFFBDBDBD) : const Color(0xFF757575),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 25),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _navigateToNextScreen();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? Colors.white : Colors.black,
                foregroundColor: isDark ? Colors.black : Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Continue',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showPartialPermissionDialog() {
    final isDark = _themeProvider.isDarkTheme;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFF757575),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.warning_outlined,
                color: Colors.white,
                size: 40,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Almost There!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Some permissions were not granted.\nYou can enable them later in Settings.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color:
                    isDark ? const Color(0xFFBDBDBD) : const Color(0xFF757575),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 25),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _navigateToNextScreen();
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: isDark
                              ? const Color(0xFF2A2A2A)
                              : const Color(0xFFE0E0E0),
                        ),
                      ),
                    ),
                    child: Text(
                      'Skip',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: isDark
                            ? const Color(0xFFBDBDBD)
                            : const Color(0xFF757575),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      openAppSettings();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark ? Colors.white : Colors.black,
                      foregroundColor: isDark ? Colors.black : Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Settings',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showErrorDialog(String message) {
    final isDark = _themeProvider.isDarkTheme;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: Color(0xFF757575),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.error_outline,
                  color: Colors.white, size: 24),
            ),
            const SizedBox(width: 15),
            Text(
              'Error',
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: TextStyle(
            color: isDark ? const Color(0xFFBDBDBD) : const Color(0xFF757575),
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark ? Colors.white : Colors.black,
              foregroundColor: isDark ? Colors.black : Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              elevation: 0,
            ),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _navigateToNextScreen() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => OnboardingScreen()),
    );
  }

  @override
  void dispose() {
    _mainAnimationController.dispose();
    _pulseController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _themeProvider,
      builder: (context, child) {
        final isDark = _themeProvider.isDarkTheme;
        final theme = _themeProvider.currentTheme;

        return Theme(
          data: theme,
          child: Scaffold(
            backgroundColor:
                isDark ? const Color(0xFF121212) : const Color(0xFFFAFAFA),
            body: SafeArea(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Column(
                  children: [
                    // Header Section
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: _buildHeader(isDark),
                      ),
                    ),

                    const SizedBox(height: 40),

                    // Progress Indicator
                    FadeTransition(
                      opacity: _staggerAnimation,
                      child: _buildProgressIndicator(isDark),
                    ),

                    const SizedBox(height: 30),

                    // Permissions List
                    Expanded(
                      child: FadeTransition(
                        opacity: _staggerAnimation,
                        child: _buildPermissionsList(isDark),
                      ),
                    ),

                    // Bottom Section
                    FadeTransition(
                      opacity: _staggerAnimation,
                      child: _buildBottomSection(isDark),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(bool isDark) {
    return Column(
      children: [
        AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _pulseAnimation.value,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white : Colors.black,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: (isDark ? Colors.white : Colors.black)
                          .withOpacity(0.1),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.security_outlined,
                  color: isDark ? Colors.black : Colors.white,
                  size: 45,
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 25),
        Text(
          'App Permissions',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'To deliver the best experience, OK Driver\nneeds access to these features',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            color: isDark ? const Color(0xFFBDBDBD) : const Color(0xFF757575),
            height: 1.5,
            letterSpacing: 0.1,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressIndicator(bool isDark) {
    final progress = grantedCount / requiredPermissions.length;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Progress',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            Text(
              '$grantedCount/${requiredPermissions.length}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color:
                    isDark ? const Color(0xFFBDBDBD) : const Color(0xFF757575),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor:
                isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE0E0E0),
            valueColor: AlwaysStoppedAnimation<Color>(
              isDark ? Colors.white : Colors.black,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPermissionsList(bool isDark) {
    return ListView.builder(
      itemCount: requiredPermissions.length,
      itemBuilder: (context, index) {
        final permissionData = requiredPermissions[index];
        final status = permissionStatuses[permissionData.permission];
        final isGranted = status == PermissionStatus.granted;

        return AnimatedContainer(
          duration: Duration(milliseconds: 300 + (index * 100)),
          margin: const EdgeInsets.only(bottom: 16),
          child: _buildPermissionCard(permissionData, isGranted, isDark),
        );
      },
    );
  }

  Widget _buildPermissionCard(
      PermissionData data, bool isGranted, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isGranted
              ? (isDark ? Colors.white : Colors.black).withOpacity(0.3)
              : (isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE0E0E0)),
          width: isGranted ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: isGranted
                  ? (isDark ? Colors.white : Colors.black)
                  : (isDark
                      ? const Color(0xFF2A2A2A)
                      : const Color(0xFFF5F5F5)),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              data.icon,
              color: isGranted
                  ? (isDark ? Colors.black : Colors.white)
                  : (isDark
                      ? const Color(0xFFBDBDBD)
                      : const Color(0xFF757575)),
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : Colors.black,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  data.description,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark
                        ? const Color(0xFFBDBDBD)
                        : const Color(0xFF757575),
                    height: 1.4,
                    letterSpacing: 0.1,
                  ),
                ),
              ],
            ),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isGranted
                  ? (isDark ? Colors.white : Colors.black)
                  : (isDark
                      ? const Color(0xFF2A2A2A)
                      : const Color(0xFFE0E0E0)),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isGranted ? Icons.check_rounded : Icons.close_rounded,
              color: isGranted
                  ? (isDark ? Colors.black : Colors.white)
                  : (isDark
                      ? const Color(0xFF757575)
                      : const Color(0xFF9E9E9E)),
              size: 18,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomSection(bool isDark) {
    return Column(
      children: [
        // Main Action Button
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: isCheckingPermissions ? null : _requestAllPermissions,
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark ? Colors.white : Colors.black,
              foregroundColor: isDark ? Colors.black : Colors.white,
              disabledBackgroundColor:
                  isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE0E0E0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            child: isCheckingPermissions
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            isDark ? Colors.black : Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Requesting Access...',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.black : Colors.white,
                        ),
                      ),
                    ],
                  )
                : const Text(
                    'Grant All Permissions',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),

        const SizedBox(height: 16),

        // Privacy Note
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: (isDark ? Colors.white : Colors.black).withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                Icons.shield_outlined,
                size: 20,
                color:
                    isDark ? const Color(0xFFBDBDBD) : const Color(0xFF757575),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Your privacy matters. Permissions are used only to enhance your experience.',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark
                        ? const Color(0xFFBDBDBD)
                        : const Color(0xFF757575),
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// Permission Data Model
class PermissionData {
  final Permission permission;
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  PermissionData({
    required this.permission,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
}

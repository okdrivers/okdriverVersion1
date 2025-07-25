import 'package:flutter/material.dart';
import 'package:okdriver/onboarding_screen/onboardind.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/services.dart';

class PermissionScreen extends StatefulWidget {
  const PermissionScreen({Key? key}) : super(key: key);

  @override
  State<PermissionScreen> createState() => _PermissionScreenState();
}

class _PermissionScreenState extends State<PermissionScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Permission status tracking
  Map<Permission, PermissionStatus> permissionStatuses = {};
  bool isCheckingPermissions = false;
  bool allPermissionsGranted = false;

  // List of required permissions
  final List<PermissionData> requiredPermissions = [
    PermissionData(
      permission: Permission.camera,
      title: 'Camera',
      description: 'Access camera to take photos and videos',
      icon: Icons.camera_alt,
    ),
    PermissionData(
      permission: Permission.microphone,
      title: 'Microphone',
      description: 'Record audio for video calls and voice messages',
      icon: Icons.mic,
    ),
    PermissionData(
      permission: Permission.location,
      title: 'Location',
      description: 'Access your location for better service',
      icon: Icons.location_on,
    ),
    PermissionData(
      permission: Permission.notification,
      title: 'Notifications',
      description: 'Send you important updates and alerts',
      icon: Icons.notifications,
    ),
    PermissionData(
      permission: Permission.bluetooth,
      title: 'Bluetooth',
      description: 'Connect with nearby devices',
      icon: Icons.bluetooth,
    ),
    PermissionData(
      permission: Permission.storage,
      title: 'File Access',
      description: 'Read and write files on your device',
      icon: Icons.folder,
    ),
    PermissionData(
      permission: Permission.phone,
      title: 'Phone',
      description: 'Make and manage phone calls',
      icon: Icons.phone,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _checkInitialPermissions();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
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
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _animationController.forward();
  }

  Future<void> _checkInitialPermissions() async {
    for (var permissionData in requiredPermissions) {
      final status = await permissionData.permission.status;
      permissionStatuses[permissionData.permission] = status;
    }
    _updateAllPermissionsStatus();
    setState(() {});
  }

  void _updateAllPermissionsStatus() {
    allPermissionsGranted = permissionStatuses.values
        .every((status) => status == PermissionStatus.granted);
  }

  Future<void> _requestAllPermissions() async {
    setState(() {
      isCheckingPermissions = true;
    });

    try {
      // Request permissions one by one for better UX
      for (var permissionData in requiredPermissions) {
        if (permissionStatuses[permissionData.permission] !=
            PermissionStatus.granted) {
          final status = await permissionData.permission.request();
          permissionStatuses[permissionData.permission] = status;

          // Small delay for better UX
          await Future.delayed(const Duration(milliseconds: 300));
        }
      }

      _updateAllPermissionsStatus();

      if (allPermissionsGranted) {
        _showSuccessDialog();
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

  Future<void> _openAppSettings() async {
    await openAppSettings();
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 28),
            SizedBox(width: 10),
            Text('All Set!'),
          ],
        ),
        content: const Text(
          'All permissions have been granted successfully. You can now enjoy all features of the app.',
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _navigateToNextScreen();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  void _showPartialPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.orange, size: 28),
            SizedBox(width: 10),
            Text('Some Permissions Missing'),
          ],
        ),
        content: const Text(
          'Some permissions were not granted. This may limit app functionality. You can grant them later in Settings.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _navigateToNextScreen();
            },
            child: const Text('Continue Anyway'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Row(
          children: [
            Icon(Icons.error, color: Colors.red, size: 28),
            SizedBox(width: 10),
            Text('Error'),
          ],
        ),
        content: Text(message),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
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
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Header
              FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Column(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                          ),
                          borderRadius: BorderRadius.circular(40),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.security,
                          color: Colors.white,
                          size: 40,
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Permission Required',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2D3748),
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'To provide you with the best experience, we need access to the following permissions:',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xFF718096),
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // Permissions List
              Expanded(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: ListView.builder(
                    itemCount: requiredPermissions.length,
                    itemBuilder: (context, index) {
                      final permissionData = requiredPermissions[index];
                      final status =
                          permissionStatuses[permissionData.permission];

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: status == PermissionStatus.granted
                                ? Colors.green.withOpacity(0.3)
                                : Colors.grey.withOpacity(0.2),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 5,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: status == PermissionStatus.granted
                                    ? Colors.green.withOpacity(0.1)
                                    : const Color(0xFF667eea).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(25),
                              ),
                              child: Icon(
                                permissionData.icon,
                                color: status == PermissionStatus.granted
                                    ? Colors.green
                                    : const Color(0xFF667eea),
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    permissionData.title,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF2D3748),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    permissionData.description,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF718096),
                                      height: 1.3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Status Icon
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: status == PermissionStatus.granted
                                    ? Colors.green
                                    : Colors.grey.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                status == PermissionStatus.granted
                                    ? Icons.check
                                    : Icons.close,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),

              // Bottom Buttons
              FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  children: [
                    // Grant Permissions Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: isCheckingPermissions
                            ? null
                            : _requestAllPermissions,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF667eea),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 2,
                        ),
                        child: isCheckingPermissions
                            ? const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Text(
                                    'Requesting Permissions...',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
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

                    const SizedBox(height: 12),

                    // Continue Anyway Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: TextButton(
                        onPressed: _navigateToNextScreen,
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF718096),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                            side: BorderSide(
                              color: Colors.grey.withOpacity(0.3),
                            ),
                          ),
                        ),
                        child: const Text(
                          'Continue Without Permissions',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Privacy Note
                    Text(
                      'We respect your privacy. Permissions are only used to enhance your app experience.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Permission Data Model
class PermissionData {
  final Permission permission;
  final String title;
  final String description;
  final IconData icon;

  PermissionData({
    required this.permission,
    required this.title,
    required this.description,
    required this.icon,
  });
}

// Home Screen (replace with your actual home screen)
class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        backgroundColor: const Color(0xFF667eea),
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 80,
              color: Colors.green,
            ),
            SizedBox(height: 20),
            Text(
              'Welcome to the App!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 10),
            Text(
              'All permissions have been configured.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

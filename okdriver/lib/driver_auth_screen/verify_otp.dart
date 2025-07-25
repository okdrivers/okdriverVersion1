import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:okdriver/driver_auth_screen/driver_registration_screen.dart';
import 'dart:convert';
import 'dart:async';

import 'package:okdriver/home_screen/homescreen.dart';
// Import your driver registration screen
// import 'driver_registration_screen.dart';

class OTPVerificationScreen extends StatefulWidget {
  final String phoneNumber; // Phone number with country code

  const OTPVerificationScreen({
    Key? key,
    required this.phoneNumber,
  }) : super(key: key);

  @override
  State<OTPVerificationScreen> createState() => _OTPVerificationScreenState();
}

class _OTPVerificationScreenState extends State<OTPVerificationScreen>
    with TickerProviderStateMixin {
  final List<TextEditingController> _otpControllers = List.generate(
    6,
    (index) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(
    6,
    (index) => FocusNode(),
  );

  late AnimationController _animationController;
  late AnimationController _shakeController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _shakeAnimation;

  bool _isLoading = false;
  bool _isResending = false;
  String _verificationMessage = '';
  bool _isDarkMode = true;

  // Timer for resend OTP
  Timer? _timer;
  int _resendTimer = 30;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startResendTimer();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
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

    _shakeAnimation = Tween<double>(
      begin: 0,
      end: 10,
    ).animate(CurvedAnimation(
      parent: _shakeController,
      curve: Curves.elasticIn,
    ));

    _animationController.forward();
  }

  void _startResendTimer() {
    _canResend = false;
    _resendTimer = 30;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendTimer == 0) {
        setState(() {
          _canResend = true;
        });
        timer.cancel();
      } else {
        setState(() {
          _resendTimer--;
        });
      }
    });
  }

  void _shakeOTPFields() {
    _shakeController.forward().then((_) {
      _shakeController.reverse();
    });
  }

  String _getOTPCode() {
    return _otpControllers.map((controller) => controller.text).join();
  }

  void _clearOTP() {
    for (var controller in _otpControllers) {
      controller.clear();
    }
    _focusNodes[0].requestFocus();
  }

  // API call to verify OTP
  Future<void> _verifyOTP() async {
    final otpCode = _getOTPCode();

    if (otpCode.length != 6) {
      _showMessage('Please enter complete OTP', isError: true);
      _shakeOTPFields();
      return;
    }

    setState(() {
      _isLoading = true;
      _verificationMessage = '';
    });

    try {
      final response = await http.post(
        Uri.parse('http://localhost:5000/api/driver/verify-otp'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'phone': widget.phoneNumber,
          'code': otpCode,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _showMessage('OTP verified successfully!', isError: false);

        // Check if user is new or existing
        final bool isNewUser = data['isNewUser'] ?? true;
        final Map<String, dynamic> user = data['user'] ?? {};

        // Navigate based on user status
        Future.delayed(const Duration(seconds: 1), () {
          if (isNewUser) {
            // Navigate to driver registration screen
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => DriverRegistrationScreen(
                  phoneNumber: widget.phoneNumber,
                  userId: user['id'] ?? '',
                ),
              ),
            );
          } else {
            // Navigate to home screen for existing user
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const Homescreen()),
            );
          }
        });
      } else {
        final errorData = json.decode(response.body);
        _showMessage(
          errorData['message'] ?? 'OTP verification failed',
          isError: true,
        );
        _shakeOTPFields();
        _clearOTP();
      }
    } catch (e) {
      _showMessage('Network error. Please try again.', isError: true);
      _shakeOTPFields();
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // API call to resend OTP
  Future<void> _resendOTP() async {
    if (!_canResend || _isResending) return;

    setState(() {
      _isResending = true;
    });

    try {
      final response = await http.post(
        Uri.parse('http://localhost:5000/api/driver/send-otp'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'phone': widget.phoneNumber,
        }),
      );

      if (response.statusCode == 200) {
        _showMessage('OTP sent successfully!', isError: false);
        _startResendTimer();
        _clearOTP();
      } else {
        final errorData = json.decode(response.body);
        _showMessage(
          errorData['message'] ?? 'Failed to resend OTP',
          isError: true,
        );
      }
    } catch (e) {
      _showMessage('Network error. Please try again.', isError: true);
    } finally {
      setState(() {
        _isResending = false;
      });
    }
  }

  void _showMessage(String message, {required bool isError}) {
    setState(() {
      _verificationMessage = message;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _onOTPChanged(String value, int index) {
    if (value.isNotEmpty && index < 5) {
      _focusNodes[index + 1].requestFocus();
    }
    if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }

    // Auto verify when all fields are filled
    if (_getOTPCode().length == 6) {
      Future.delayed(const Duration(milliseconds: 100), () {
        _verifyOTP();
      });
    }
  }

  Color get backgroundColor => _isDarkMode ? Colors.black : Colors.white;
  Color get primaryTextColor => _isDarkMode ? Colors.white : Colors.black;
  Color get secondaryTextColor => _isDarkMode ? Colors.white70 : Colors.black54;
  Color get cardColor =>
      _isDarkMode ? const Color(0xFF1E1E1E) : const Color(0xFFF5F5F5);

  @override
  void dispose() {
    _timer?.cancel();
    _animationController.dispose();
    _shakeController.dispose();
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: primaryTextColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'OTP Verification',
          style: TextStyle(
            color: primaryTextColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isDarkMode ? Icons.light_mode : Icons.dark_mode,
              color: primaryTextColor,
            ),
            onPressed: () {
              setState(() {
                _isDarkMode = !_isDarkMode;
              });
            },
          ),
        ],
      ),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Header Icon
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(40),
                    ),
                    child: const Icon(
                      Icons.message_outlined,
                      size: 40,
                      color: Colors.green,
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Title
                  Text(
                    'Enter Verification Code',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: primaryTextColor,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 8),

                  // Subtitle
                  Text(
                    'We sent a 6-digit code to\n${widget.phoneNumber}',
                    style: TextStyle(
                      fontSize: 16,
                      color: secondaryTextColor,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 40),

                  // OTP Input Fields
                  AnimatedBuilder(
                    animation: _shakeAnimation,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(_shakeAnimation.value, 0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: List.generate(6, (index) {
                            return Container(
                              width: 45,
                              height: 55,
                              decoration: BoxDecoration(
                                color: cardColor,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _focusNodes[index].hasFocus
                                      ? Colors.green
                                      : _isDarkMode
                                          ? Colors.white.withOpacity(0.1)
                                          : Colors.black.withOpacity(0.1),
                                  width: _focusNodes[index].hasFocus ? 2 : 1,
                                ),
                              ),
                              child: TextFormField(
                                controller: _otpControllers[index],
                                focusNode: _focusNodes[index],
                                textAlign: TextAlign.center,
                                keyboardType: TextInputType.number,
                                maxLength: 1,
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: primaryTextColor,
                                ),
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  counterText: '',
                                ),
                                onChanged: (value) =>
                                    _onOTPChanged(value, index),
                              ),
                            );
                          }),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 32),

                  // Verify Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _verifyOTP,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Text(
                              'Verify OTP',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Resend OTP Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Didn't receive code? ",
                        style: TextStyle(
                          fontSize: 14,
                          color: secondaryTextColor,
                        ),
                      ),
                      if (_canResend)
                        GestureDetector(
                          onTap: _isResending ? null : _resendOTP,
                          child: Text(
                            _isResending ? 'Sending...' : 'Resend',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.green,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        )
                      else
                        Text(
                          'Resend in ${_resendTimer}s',
                          style: TextStyle(
                            fontSize: 14,
                            color: secondaryTextColor,
                          ),
                        ),
                    ],
                  ),

                  // Verification Message
                  if (_verificationMessage.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _verificationMessage.contains('successfully')
                            ? Colors.green.withOpacity(0.1)
                            : Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _verificationMessage.contains('successfully')
                              ? Colors.green
                              : Colors.red,
                        ),
                      ),
                      child: Text(
                        _verificationMessage,
                        style: TextStyle(
                          color: _verificationMessage.contains('successfully')
                              ? Colors.green
                              : Colors.red,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

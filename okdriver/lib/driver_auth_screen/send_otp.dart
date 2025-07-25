import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:country_picker/country_picker.dart';

import 'package:okdriver/home_screen/homescreen.dart';
import 'package:okdriver/driver_auth_screen/driver_registration_screen.dart';

class SendOTPScreen extends StatefulWidget {
  const SendOTPScreen({Key? key}) : super(key: key);

  @override
  State<SendOTPScreen> createState() => _SendOTPScreenState();
}

class _SendOTPScreenState extends State<SendOTPScreen>
    with TickerProviderStateMixin {
  final TextEditingController _phoneController = TextEditingController();
  final List<TextEditingController> _otpControllers =
      List.generate(6, (index) => TextEditingController());
  final List<FocusNode> _otpFocusNodes =
      List.generate(6, (index) => FocusNode());

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  bool _isLoading = false;
  bool _otpSent = false;
  bool _isVerifying = false;
  int _resendTimer = 30;
  Timer? _timer;
  String _verificationMessage = '';
  bool _isDarkMode = true;

  // Selected country - default to India
  Country _selectedCountry = Country.parse('IN');

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
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

  // API call to send OTP
  Future<void> _sendOTP() async {
    if (_phoneController.text.length < 10) {
      _showMessage('Please enter a valid phone number', isError: true);
      return;
    }

    setState(() {
      _isLoading = true;
      _verificationMessage = '';
    });

    try {
      final response = await http.post(
        Uri.parse('http://localhost:5000/api/driver/send-otp'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'phone': '+${_selectedCountry.phoneCode}${_phoneController.text}',
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _otpSent = true;
          _isLoading = false;
        });
        _showMessage('OTP sent successfully!', isError: false);
        _startResendTimer();
      } else {
        final errorData = json.decode(response.body);
        _showMessage(errorData['message'] ?? 'Failed to send OTP',
            isError: true);
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      _showMessage('Network error. Please try again.', isError: true);
      setState(() {
        _isLoading = false;
      });
    }
  }

  // API call to verify OTP
  Future<void> _verifyOTP() async {
    String otp = _otpControllers.map((controller) => controller.text).join();

    if (otp.length != 6) {
      _showMessage('Please enter complete OTP', isError: true);
      return;
    }

    setState(() {
      _isVerifying = true;
      _verificationMessage = '';
    });

    try {
      final response = await http.post(
        Uri.parse('http://localhost:5000/api/driver/verify-otp'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'phone': '+${_selectedCountry.phoneCode}${_phoneController.text}',
          'code': otp,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _showMessage('Phone verified successfully!', isError: false);

        // Navigate to registration screen after delay
        Future.delayed(const Duration(seconds: 2), () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => DriverRegistrationScreen(
                phoneNumber:
                    '+${_selectedCountry.phoneCode}${_phoneController.text}',
                userId: data['driverId'] ?? '',
              ),
            ),
          );
        });
      } else {
        final errorData = json.decode(response.body);
        _showMessage(errorData['message'] ?? 'Invalid OTP', isError: true);
      }
    } catch (e) {
      _showMessage('Network error. Please try again.', isError: true);
    } finally {
      setState(() {
        _isVerifying = false;
      });
    }
  }

  void _startResendTimer() {
    _resendTimer = 30;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_resendTimer > 0) {
          _resendTimer--;
        } else {
          _timer?.cancel();
        }
      });
    });
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

  void _showCountryPicker() {
    showCountryPicker(
      context: context,
      showPhoneCode: true,
      onSelect: (Country country) {
        setState(() {
          _selectedCountry = country;
        });
      },
      // Customize the country picker theme
      countryListTheme: CountryListThemeData(
        backgroundColor: _isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        textStyle: TextStyle(
          color: _isDarkMode ? Colors.white : Colors.black,
        ),
        searchTextStyle: TextStyle(
          color: _isDarkMode ? Colors.white : Colors.black,
        ),
        inputDecoration: InputDecoration(
          hintText: 'Search country',
          hintStyle: TextStyle(
            color: _isDarkMode ? Colors.white70 : Colors.black54,
          ),
          prefixIcon: Icon(
            Icons.search,
            color: _isDarkMode ? Colors.white70 : Colors.black54,
          ),
          border: OutlineInputBorder(
            borderSide: BorderSide(
              color: _isDarkMode
                  ? Colors.white.withOpacity(0.1)
                  : Colors.black.withOpacity(0.1),
            ),
          ),
          focusedBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Colors.blue),
          ),
        ),
      ),
      // Show popular countries at top
      favorite: <String>[
        'IN',
        'US',
        'GB',
        'CA',
        'AU',
        'DE',
        'FR',
        'JP',
        'KR',
        'SG'
      ],
    );
  }

  void _onOTPChanged(String value, int index) {
    if (value.isNotEmpty && index < 5) {
      _otpFocusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _otpFocusNodes[index - 1].requestFocus();
    }

    // Auto verify when all digits are entered
    if (index == 5 && value.isNotEmpty) {
      String otp = _otpControllers.map((controller) => controller.text).join();
      if (otp.length == 6) {
        _verifyOTP();
      }
    }
  }

  Color get backgroundColor => _isDarkMode ? Colors.black : Colors.white;
  Color get primaryTextColor => _isDarkMode ? Colors.white : Colors.black;
  Color get secondaryTextColor => _isDarkMode ? Colors.white70 : Colors.black54;
  Color get cardColor =>
      _isDarkMode ? const Color(0xFF1E1E1E) : const Color(0xFFF5F5F5);

  @override
  void dispose() {
    _animationController.dispose();
    _phoneController.dispose();
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var node in _otpFocusNodes) {
      node.dispose();
    }
    _timer?.cancel();
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
          'Phone Verification',
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Center(
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(40),
                      ),
                      child: const Icon(
                        Icons.phone_android,
                        size: 40,
                        color: Colors.blue,
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  Text(
                    _otpSent
                        ? 'Enter Verification Code'
                        : 'Enter Your Phone Number',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: primaryTextColor,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    _otpSent
                        ? 'We\'ve sent a 6-digit code to +${_selectedCountry.phoneCode} ${_phoneController.text}'
                        : 'We\'ll send you a verification code via SMS',
                    style: TextStyle(
                      fontSize: 16,
                      color: secondaryTextColor,
                      height: 1.5,
                    ),
                  ),

                  const SizedBox(height: 32),

                  if (!_otpSent) ...[
                    // Phone number input
                    Container(
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _isDarkMode
                              ? Colors.white.withOpacity(0.1)
                              : Colors.black.withOpacity(0.1),
                        ),
                      ),
                      child: Row(
                        children: [
                          // Country selector
                          InkWell(
                            onTap: _showCountryPicker,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    _selectedCountry.flagEmoji,
                                    style: const TextStyle(fontSize: 24),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '+${_selectedCountry.phoneCode}',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: primaryTextColor,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(
                                    Icons.arrow_drop_down,
                                    color: secondaryTextColor,
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Divider
                          Container(
                            width: 1,
                            height: 40,
                            color: _isDarkMode
                                ? Colors.white.withOpacity(0.1)
                                : Colors.black.withOpacity(0.1),
                          ),

                          // Phone number input
                          Expanded(
                            child: TextField(
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(
                                    15), // Increased to accommodate different country formats
                              ],
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: primaryTextColor,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Enter phone number',
                                hintStyle: TextStyle(color: secondaryTextColor),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 16,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Send OTP Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _sendOTP,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
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
                                'Send OTP',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                  ] else ...[
                    // OTP Input Fields
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(6, (index) {
                        return SizedBox(
                          width: 45,
                          height: 55,
                          child: TextField(
                            controller: _otpControllers[index],
                            focusNode: _otpFocusNodes[index],
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            maxLength: 1,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: primaryTextColor,
                            ),
                            decoration: InputDecoration(
                              counterText: '',
                              filled: true,
                              fillColor: cardColor,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: _isDarkMode
                                      ? Colors.white.withOpacity(0.1)
                                      : Colors.black.withOpacity(0.1),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: Colors.blue,
                                  width: 2,
                                ),
                              ),
                            ),
                            onChanged: (value) => _onOTPChanged(value, index),
                          ),
                        );
                      }),
                    ),

                    const SizedBox(height: 32),

                    // Verify Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isVerifying ? null : _verifyOTP,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: _isVerifying
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

                    // Resend OTP
                    Center(
                      child: Column(
                        children: [
                          if (_resendTimer > 0)
                            Text(
                              'Resend OTP in ${_resendTimer}s',
                              style: TextStyle(
                                fontSize: 14,
                                color: secondaryTextColor,
                              ),
                            )
                          else
                            TextButton(
                              onPressed: () {
                                // Clear OTP fields
                                for (var controller in _otpControllers) {
                                  controller.clear();
                                }
                                // Send OTP again
                                _sendOTP();
                              },
                              child: const Text(
                                'Resend OTP',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.blue,
                                ),
                              ),
                            ),
                          const SizedBox(height: 16),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _otpSent = false;
                                _phoneController.clear();
                              });
                              for (var controller in _otpControllers) {
                                controller.clear();
                              }
                            },
                            child: Text(
                              'Change Phone Number',
                              style: TextStyle(
                                fontSize: 14,
                                color: secondaryTextColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Verification Message
                  if (_verificationMessage.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _verificationMessage.contains('success')
                            ? Colors.green.withOpacity(0.1)
                            : Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _verificationMessage.contains('success')
                              ? Colors.green
                              : Colors.red,
                        ),
                      ),
                      child: Text(
                        _verificationMessage,
                        style: TextStyle(
                          color: _verificationMessage.contains('success')
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

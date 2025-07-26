// DashCam Screen
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:okdriver/permissionscreen/permissionscreen.dart';
import 'package:provider/provider.dart';

class DashCamScreen extends StatefulWidget {
  const DashCamScreen({super.key});

  @override
  State<DashCamScreen> createState() => _DashCamScreenState();
}

class _DashCamScreenState extends State<DashCamScreen> {
  late bool _isDarkMode;
  bool _isRecording = false;
  String _selectedCamera = 'front'; // 'front', 'rear', 'both'
  String _recordingTime = '00:00:00';

  @override
  void initState() {
    super.initState();
    // Initialize _isDarkMode from ThemeProvider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
      setState(() {
        _isDarkMode = themeProvider.isDarkTheme;
      });
    });
  }

  final List<Map<String, dynamic>> _cameraOptions = [
    {
      'id': 'front',
      'title': 'Front Camera',
      'subtitle': 'Record road ahead',
      'icon': Icons.camera_front_rounded,
      'color': const Color(0xFF2196F3),
    },
    {
      'id': 'rear',
      'title': 'Rear Camera',
      'subtitle': 'Record behind vehicle',
      'icon': Icons.camera_rear_rounded,
      'color': const Color(0xFF4CAF50),
    },
    {
      'id': 'both',
      'title': 'Both Cameras',
      'subtitle': 'Dual camera recording',
      'icon': Icons.camera_alt_rounded,
      'color': const Color(0xFF9C27B0),
    },
  ];

  void _selectCamera(String cameraId) {
    setState(() {
      _selectedCamera = cameraId;
    });
    HapticFeedback.lightImpact();
  }

  void _toggleRecording() {
    setState(() {
      _isRecording = !_isRecording;
    });
    HapticFeedback.mediumImpact();

    if (_isRecording) {
      // Start recording timer simulation
      _startRecordingTimer();
    } else {
      // Stop recording
      setState(() {
        _recordingTime = '00:00:00';
      });
    }
  }

  void _startRecordingTimer() {
    // Simulate recording timer (in real app, use actual timer)
    if (_isRecording) {
      Future.delayed(const Duration(seconds: 1), () {
        if (_isRecording) {
          // Update timer logic here
          _startRecordingTimer();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen to theme changes
    final themeProvider = Provider.of<ThemeProvider>(context);
    _isDarkMode = themeProvider.isDarkTheme;
    return Scaffold(
      backgroundColor: _isDarkMode ? Colors.black : const Color(0xFFF8F9FA),
      appBar: _buildAppBar(),
      body: Column(
        children: [
          // Camera Preview Area
          _buildCameraPreview(),

          // Camera Selection
          _buildCameraSelection(),

          // Recording Controls
          _buildRecordingControls(),

          // Recording Info
          _buildRecordingInfo(),
        ],
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: _isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: Icon(
          Icons.arrow_back_ios_rounded,
          color: _isDarkMode ? Colors.white : Colors.black87,
        ),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        'DashCam',
        style: TextStyle(
          color: _isDarkMode ? Colors.white : Colors.black87,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(
            _isDarkMode ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
            color: _isDarkMode ? Colors.white : Colors.black54,
          ),
          onPressed: () {
            final themeProvider =
                Provider.of<ThemeProvider>(context, listen: false);
            themeProvider.toggleTheme();
            setState(() {
              _isDarkMode = themeProvider.isDarkTheme;
            });
          },
        ),
        IconButton(
          icon: Icon(
            Icons.settings_rounded,
            color: _isDarkMode ? Colors.white : Colors.black54,
          ),
          onPressed: () {
            // Open settings
          },
        ),
      ],
    );
  }

  Widget _buildCameraPreview() {
    return Expanded(
      flex: 3,
      child: Container(
        margin: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: _isDarkMode
                  ? Colors.black.withOpacity(0.3)
                  : Colors.grey.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              // Camera Preview Placeholder
              Container(
                width: double.infinity,
                height: double.infinity,
                color: Colors.black87,
                child: _selectedCamera == 'both'
                    ? _buildDualCameraView()
                    : _buildSingleCameraView(),
              ),

              // Recording Indicator
              if (_isRecording)
                Positioned(
                  top: 16,
                  left: 16,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'REC $_recordingTime',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Camera Type Indicator
              Positioned(
                top: 16,
                right: 16,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getCameraDisplayName(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSingleCameraView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _getSelectedCameraIcon(),
            size: 64,
            color: Colors.white.withOpacity(0.7),
          ),
          const SizedBox(height: 16),
          Text(
            '${_getCameraDisplayName()} Preview',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Camera feed will appear here',
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDualCameraView() {
    return Column(
      children: [
        // Front Camera View
        Expanded(
          child: Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.white24, width: 1),
              ),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.camera_front_rounded,
                    size: 32,
                    color: Colors.white.withOpacity(0.7),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Front Camera',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Rear Camera View
        Expanded(
          child: Container(
            width: double.infinity,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.camera_rear_rounded,
                    size: 32,
                    color: Colors.white.withOpacity(0.7),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Rear Camera',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCameraSelection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Camera Selection',
            style: TextStyle(
              color: _isDarkMode ? Colors.white : Colors.black87,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: _cameraOptions.map((option) {
              final isSelected = option['id'] == _selectedCamera;
              return Expanded(
                child: GestureDetector(
                  onTap: () => _selectCamera(option['id']),
                  child: Container(
                    margin: const EdgeInsets.only(right: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? (option['color'] as Color).withOpacity(0.1)
                          : (_isDarkMode
                              ? const Color(0xFF1E1E1E)
                              : Colors.white),
                      borderRadius: BorderRadius.circular(12),
                      border: isSelected
                          ? Border.all(color: option['color'], width: 2)
                          : Border.all(
                              color: _isDarkMode
                                  ? Colors.white.withOpacity(0.1)
                                  : Colors.grey.withOpacity(0.2),
                            ),
                      boxShadow: [
                        BoxShadow(
                          color: _isDarkMode
                              ? Colors.black.withOpacity(0.3)
                              : Colors.grey.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Icon(
                          option['icon'],
                          color: isSelected
                              ? option['color']
                              : (_isDarkMode
                                  ? Colors.white.withOpacity(0.7)
                                  : Colors.black54),
                          size: 24,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          option['title'],
                          style: TextStyle(
                            color: isSelected
                                ? option['color']
                                : (_isDarkMode ? Colors.white : Colors.black87),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          option['subtitle'],
                          style: TextStyle(
                            color: _isDarkMode
                                ? Colors.white.withOpacity(0.6)
                                : Colors.black54,
                            fontSize: 10,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordingControls() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Settings Button
          _buildControlButton(
            icon: Icons.settings_rounded,
            label: 'Settings',
            onTap: () {
              // Open camera settings
            },
          ),

          // Recording Button
          GestureDetector(
            onTap: _toggleRecording,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: _isRecording ? Colors.red : const Color(0xFF4CAF50),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: (_isRecording ? Colors.red : const Color(0xFF4CAF50))
                        .withOpacity(0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                _isRecording
                    ? Icons.stop_rounded
                    : Icons.fiber_manual_record_rounded,
                color: Colors.white,
                size: 32,
              ),
            ),
          ),

          // Gallery Button
          _buildControlButton(
            icon: Icons.photo_library_rounded,
            label: 'Gallery',
            onTap: () {
              // Open recorded videos
            },
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: _isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: _isDarkMode
                      ? Colors.black.withOpacity(0.3)
                      : Colors.grey.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              icon,
              color: _isDarkMode ? Colors.white : Colors.black54,
              size: 24,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color:
                  _isDarkMode ? Colors.white.withOpacity(0.7) : Colors.black54,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordingInfo() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: _isDarkMode
                ? Colors.black.withOpacity(0.3)
                : Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildInfoItem('Storage', '15.2GB / 32GB'),
              _buildInfoItem('Quality', '1080p HD'),
              _buildInfoItem('Status', _isRecording ? 'Recording' : 'Ready'),
            ],
          ),
          if (_isRecording) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    color: Colors.red,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Recording in progress. Keep the app open for best performance.',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: _isDarkMode ? Colors.white : Colors.black87,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: _isDarkMode ? Colors.white.withOpacity(0.6) : Colors.black54,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  String _getCameraDisplayName() {
    switch (_selectedCamera) {
      case 'front':
        return 'Front Camera';
      case 'rear':
        return 'Rear Camera';
      case 'both':
        return 'Dual Camera';
      default:
        return 'Camera';
    }
  }

  IconData _getSelectedCameraIcon() {
    switch (_selectedCamera) {
      case 'front':
        return Icons.camera_front_rounded;
      case 'rear':
        return Icons.camera_rear_rounded;
      case 'both':
        return Icons.camera_alt_rounded;
      default:
        return Icons.camera_alt_rounded;
    }
  }
}

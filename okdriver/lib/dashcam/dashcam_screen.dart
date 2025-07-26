import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:okdriver/dashcam/components/camera_selection.dart';
import 'package:okdriver/dashcam/components/recording_controls.dart';
import 'package:okdriver/dashcam/components/video_preview.dart';
import 'package:okdriver/theme/theme_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';

class DashcamScreen extends StatefulWidget {
  const DashcamScreen({Key? key}) : super(key: key);

  @override
  State<DashcamScreen> createState() => _DashcamScreenState();
}

class _DashcamScreenState extends State<DashcamScreen>
    with WidgetsBindingObserver {
  bool _isDarkMode = false;
  String _selectedCamera = ''; // 'front', 'back', or 'dual'
  bool _isRecording = false;
  bool _isPaused = false;
  bool _recordWithAudio = true;
  int _recordingDuration = 15; // in minutes
  String _storageLocation = 'local'; // 'local' or 'cloud'
  String? _currentVideoPath;
  List<String> _savedVideos = [];
  Timer? _recordingTimer;
  DateTime? _recordingStartTime;

  // Controllers for video preview
  VideoPlayerController? _livePreviewController;
  VideoPlayerController? _savedVideoController;
  bool _isPlayingSavedVideo = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadTheme();
    _checkPermissions();
    _loadSavedVideos();
  }

  void _loadTheme() {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    setState(() {
      // _isDarkMode = themeProvider.isDarkMode;
    });
  }

  Future<void> _checkPermissions() async {
    final cameraStatus = await Permission.camera.status;
    final microphoneStatus = await Permission.microphone.status;
    final storageStatus = await Permission.storage.status;

    if (!cameraStatus.isGranted ||
        !microphoneStatus.isGranted ||
        !storageStatus.isGranted) {
      // Permissions will be requested in the CameraSelectionScreen
    }
  }

  Future<void> _loadSavedVideos() async {
    // In a real app, you would load the list of saved videos from storage
    // For this example, we'll just use a placeholder
    setState(() {
      _savedVideos = [];
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadTheme();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Handle app lifecycle changes to ensure recording continues in background
    if (state == AppLifecycleState.paused) {
      // App is in background
      if (_isRecording && !_isPaused) {
        // Continue recording in background
      }
    } else if (state == AppLifecycleState.resumed) {
      // App is in foreground again
      _checkPermissions();
    }
  }

  void _onCameraSelected(String camera) {
    setState(() {
      _selectedCamera = camera;
    });
    _initializeCameraPreview();
  }

  void _initializeCameraPreview() {
    // In a real app, you would initialize the camera preview here
    // For this example, we'll just use a placeholder
    _livePreviewController?.dispose();
    _livePreviewController = null;

    // This would be replaced with actual camera initialization code
    setState(() {
      // Placeholder for camera initialization
    });
  }

  void _onAudioToggle(bool value) {
    setState(() {
      _recordWithAudio = value;
    });
  }

  void _onDurationChange(int duration) {
    setState(() {
      _recordingDuration = duration;
    });
  }

  void _onStorageLocationChange(String location) {
    setState(() {
      _storageLocation = location;
    });
  }

  void _startRecording() {
    if (_isRecording && _isPaused) {
      // Resume recording
      setState(() {
        _isPaused = false;
      });
    } else if (!_isRecording) {
      // Start new recording
      setState(() {
        _isRecording = true;
        _isPaused = false;
        _recordingStartTime = DateTime.now();
      });

      // Start recording timer
      _recordingTimer = Timer(Duration(minutes: _recordingDuration), () {
        _stopRecording();
      });
    }
  }

  void _pauseRecording() {
    if (_isRecording && !_isPaused) {
      setState(() {
        _isPaused = true;
      });

      // Cancel the current timer
      _recordingTimer?.cancel();
    }
  }

  void _stopRecording() {
    if (_isRecording) {
      // Cancel the timer
      _recordingTimer?.cancel();

      // Generate a filename with timestamp
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final videoPath =
          '/storage/emulated/0/DCIM/OkDriver/dashcam_$timestamp.mp4';

      setState(() {
        _isRecording = false;
        _isPaused = false;
        _currentVideoPath = videoPath;
        _savedVideos.add(videoPath);
      });

      // In a real app, you would save the video file here
      _showRecordingCompleteDialog();
    }
  }

  void _deleteRecording() {
    if (_isRecording) {
      // Cancel the timer
      _recordingTimer?.cancel();

      setState(() {
        _isRecording = false;
        _isPaused = false;
        _currentVideoPath = null;
      });

      // In a real app, you would delete the temporary recording file
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Recording discarded')),
      );
    }
  }

  void _showRecordingCompleteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Recording Complete'),
        content: const Text('Your video has been saved successfully.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('OK'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _playSavedVideo(_currentVideoPath!);
            },
            child: const Text('View'),
          ),
        ],
      ),
    );
  }

  void _playSavedVideo(String videoPath) {
    // In a real app, you would play the saved video file
    // For this example, we'll just use a placeholder
    _savedVideoController?.dispose();

    // This would be replaced with actual video player initialization
    // _savedVideoController = VideoPlayerController.file(File(videoPath));
    // _savedVideoController!.initialize().then((_) {
    //   _savedVideoController!.play();
    //   setState(() {
    //     _isPlayingSavedVideo = true;
    //   });
    // });

    setState(() {
      _isPlayingSavedVideo = true;
    });
  }

  void _stopPlayingSavedVideo() {
    _savedVideoController?.pause();
    _savedVideoController?.dispose();
    _savedVideoController = null;

    setState(() {
      _isPlayingSavedVideo = false;
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _recordingTimer?.cancel();
    _livePreviewController?.dispose();
    _savedVideoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashcam'),
        actions: [
          if (_isPlayingSavedVideo)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: _stopPlayingSavedVideo,
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Video Preview (25% of screen)
            VideoPreviewScreen(
              videoPath: _currentVideoPath,
              isRecording: _isRecording,
              isPaused: _isPaused,
              selectedCamera: _selectedCamera,
              livePreviewController: _livePreviewController,
              savedVideoController: _savedVideoController,
              isPlayingSavedVideo: _isPlayingSavedVideo,
            ),

            // Camera Selection or Recording Controls
            Expanded(
              child: _isPlayingSavedVideo
                  ? const Center(child: Text('Playing saved video'))
                  : _selectedCamera.isEmpty
                      ? CameraSelectionScreen(
                          onCameraSelected: _onCameraSelected,
                        )
                      : SingleChildScrollView(
                          child: RecordingControlsScreen(
                            onAudioToggle: _onAudioToggle,
                            onDurationChange: _onDurationChange,
                            onStorageLocationChange: _onStorageLocationChange,
                            onStartRecording: _startRecording,
                            onPauseRecording: _pauseRecording,
                            onStopRecording: _stopRecording,
                            onDeleteRecording: _deleteRecording,
                            isRecording: _isRecording,
                            isPaused: _isPaused,
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

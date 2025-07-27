import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:okdriver/dashcam/services/background_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:okdriver/dashcam/components/camera_selection.dart';
import 'package:okdriver/dashcam/components/recording_controls.dart';
import 'package:okdriver/dashcam/components/video_preview.dart';

class DashcamScreen extends StatefulWidget {
  final CameraType cameraType;
  final CameraDescription? frontCamera;
  final CameraDescription? backCamera;

  const DashcamScreen({
    Key? key,
    required this.cameraType,
    this.frontCamera,
    this.backCamera,
  }) : super(key: key);

  @override
  State<DashcamScreen> createState() => _DashcamScreenState();
}

class _DashcamScreenState extends State<DashcamScreen>
    with WidgetsBindingObserver {
  late CameraController _cameraController;
  bool _isInitialized = false;
  bool _isRecording = false;
  bool _isPaused = false;
  bool _isAudioEnabled = true;
  String _recordingDuration = '00:00';
  String _selectedDuration = '15m'; // Default 15 minutes
  String _storageOption = 'local'; // Default local storage
  Timer? _recordingTimer;
  int _elapsedSeconds = 0;
  String? _currentVideoPath;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopRecordingTimer();
    _cameraController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    if (!_cameraController.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      // App is going to background
      print('App going to background, current recording state: $_isRecording');

      // If recording, ensure the background service is running
      if (_isRecording) {
        print('Transferring recording to background service');
        // Initialize background service with current camera settings
        await DashcamBackgroundService().initialize(
          cameraController: _cameraController,
          maxRecordingDurationMinutes: _getDurationInMinutes(),
        );

        // Start background recording
        await DashcamBackgroundService().startBackgroundRecording();

        // We don't stop the current recording as the background service will handle it
      } else {
        // Dispose of the controller when the app is in the background if not recording
        _cameraController.dispose();
        _isInitialized = false;
      }
    } else if (state == AppLifecycleState.resumed) {
      print('App resumed from background');

      // Reinitialize the camera if needed
      if (!_cameraController.value.isInitialized) {
        await _initializeCamera();
      }

      // Check if background service was recording
      if (DashcamBackgroundService().isRecording) {
        print('Background service was recording, syncing state');

        // Update UI state to match background service
        setState(() {
          _isRecording = true;
          _elapsedSeconds = DashcamBackgroundService().elapsedSeconds;
          final minutes = (_elapsedSeconds ~/ 60).toString().padLeft(2, '0');
          final seconds = (_elapsedSeconds % 60).toString().padLeft(2, '0');
          _recordingDuration = '$minutes:$seconds';
        });

        // Continue recording in foreground
        await DashcamBackgroundService().stopBackgroundRecording();

        // We don't need to start recording again as it's already running
      } else if (_isRecording) {
        // Our state thinks we're recording but background service isn't
        // This could happen if the background service stopped recording due to error or time limit
        setState(() {
          _isRecording = false;
          _isPaused = false;
          _elapsedSeconds = 0;
          _recordingDuration = '00:00';
        });
      }
    }
  }

  Future<void> _initializeCamera() async {
    // Determine which camera to use based on the selected type
    CameraDescription cameraToUse;

    switch (widget.cameraType) {
      case CameraType.front:
        cameraToUse = widget.frontCamera!;
        break;
      case CameraType.back:
        cameraToUse = widget.backCamera!;
        break;
      case CameraType.dual:
        // For dual mode, we'll use the front camera as primary
        // In a real implementation, we would handle both cameras
        cameraToUse = widget.frontCamera ?? widget.backCamera!;
        break;
    }

    // Initialize the camera controller
    _cameraController = CameraController(
      cameraToUse,
      ResolutionPreset.high,
      enableAudio: _isAudioEnabled,
    );

    try {
      await _cameraController.initialize();
      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error initializing camera: $e')),
      );
    }
  }

  Future<void> _toggleRecording() async {
    if (_isRecording) {
      await _stopRecording();
    } else {
      await _startRecording();
    }
  }

  Future<void> _startRecording() async {
    if (!_cameraController.value.isInitialized) return;

    // Ensure storage permission is granted
    final storageStatus = await Permission.storage.request();
    if (!storageStatus.isGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Storage permission is required to save videos')),
      );
      return;
    }

    // Create a timestamped file path for the video
    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final path = '${directory.path}/dashcam_$timestamp.mp4';

    try {
      // Initialize background service with current camera settings
      await DashcamBackgroundService().initialize(
        cameraController: _cameraController,
        maxRecordingDurationMinutes: _getDurationInMinutes(),
      );

      // Start recording with camera controller
      await _cameraController.startVideoRecording();
      _currentVideoPath = path;

      setState(() {
        _isRecording = true;
        _isPaused = false;
        _elapsedSeconds = 0;
      });

      // Start the recording timer
      _startRecordingTimer();

      // Set up automatic stop based on selected duration
      _setupAutomaticStop();

      print('Started recording in foreground mode');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error starting recording: $e')),
      );
    }
  }

  // Helper method to convert selected duration string to minutes
  int _getDurationInMinutes() {
    switch (_selectedDuration) {
      case '15m':
        return 15;
      case '30m':
        return 30;
      case '1h':
        return 60;
      default:
        return 15; // Default to 15 minutes
    }
  }

  Future<void> _stopRecording() async {
    // Check if we're recording in foreground or background
    bool isRecordingInForeground = _cameraController.value.isInitialized &&
        _cameraController.value.isRecordingVideo;
    bool isRecordingInBackground = DashcamBackgroundService().isRecording;

    print(
        'Stopping recording - Foreground: $isRecordingInForeground, Background: $isRecordingInBackground');

    _stopRecordingTimer();

    try {
      XFile? videoFile;

      // Stop foreground recording if active
      if (isRecordingInForeground) {
        videoFile = await _cameraController.stopVideoRecording();
        print('Stopped foreground recording: ${videoFile.path}');
      }

      // Stop background recording if active
      if (isRecordingInBackground) {
        await DashcamBackgroundService().stopBackgroundRecording();
        print('Stopped background recording');

        // If we have a video path from background service, use it
        String? backgroundVideoPath =
            DashcamBackgroundService().currentVideoPath;
        if (backgroundVideoPath != null && videoFile == null) {
          videoFile = XFile(backgroundVideoPath);
        }
      }

      setState(() {
        _isRecording = false;
        _isPaused = false;
        _elapsedSeconds = 0;
        _recordingDuration = '00:00';
      });

      // Save the video file if we have one
      if (videoFile != null) {
        await _saveVideoFile(videoFile);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Video saved successfully')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No video file was created')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error stopping recording: $e')),
      );
    }
  }

  Future<void> _pauseResumeRecording() async {
    if (!_isRecording) return;

    try {
      if (_isPaused) {
        await _cameraController.resumeVideoRecording();
        _startRecordingTimer();
      } else {
        await _cameraController.pauseVideoRecording();
        _stopRecordingTimer();
      }

      setState(() {
        _isPaused = !_isPaused;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error pausing/resuming recording: $e')),
      );
    }
  }

  Future<void> _saveVideoFile(XFile videoFile) async {
    // In a real implementation, we would handle cloud storage here
    // based on the _storageOption value
    if (_storageOption == 'cloud') {
      // Upload to cloud storage (would require subscription)
      // For now, we'll just show a message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cloud storage requires subscription')),
      );
    }

    try {
      // Save to local storage (app documents directory)
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final localPath = '${directory.path}/dashcam_$timestamp.mp4';

      // Copy the file to the app's documents directory
      final sourceFile = File(videoFile.path);
      await sourceFile.copy(localPath);

      // Save to device gallery
      final result = await ImageGallerySaver.saveFile(localPath);

      if (result['isSuccess']) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Video saved to gallery successfully')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('Failed to save to gallery: ${result['errorMessage']}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving video: $e')),
      );
    }
  }

  void _startRecordingTimer() {
    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _elapsedSeconds++;
        final minutes = (_elapsedSeconds ~/ 60).toString().padLeft(2, '0');
        final seconds = (_elapsedSeconds % 60).toString().padLeft(2, '0');
        _recordingDuration = '$minutes:$seconds';
      });
    });
  }

  void _stopRecordingTimer() {
    _recordingTimer?.cancel();
    _recordingTimer = null;
  }

  void _setupAutomaticStop() {
    // Convert selected duration to seconds
    int durationInSeconds;
    switch (_selectedDuration) {
      case '15m':
        durationInSeconds = 15 * 60;
        break;
      case '30m':
        durationInSeconds = 30 * 60;
        break;
      case '1h':
        durationInSeconds = 60 * 60;
        break;
      default:
        durationInSeconds = 15 * 60; // Default to 15 minutes
    }

    // Set up a timer to stop recording after the selected duration
    Timer(Duration(seconds: durationInSeconds), () {
      if (_isRecording) {
        _stopRecording();
      }
    });
  }

  void _toggleAudio() {
    setState(() {
      _isAudioEnabled = !_isAudioEnabled;
    });

    // Reinitialize camera with new audio setting
    _cameraController.dispose();
    _initializeCamera();
  }

  void _setRecordingDuration(String duration) {
    setState(() {
      _selectedDuration = duration;
    });
  }

  void _setStorageOption(String option) {
    setState(() {
      _storageOption = option;
    });

    // If cloud storage is selected, we would typically navigate to subscription screen
    if (option == 'cloud') {
      // For now, just show a message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cloud storage requires subscription')),
      );
    }
  }

  void _deleteCurrentRecording() async {
    // If recording is in progress, stop it first
    if (_isRecording) {
      _stopRecordingTimer();
      try {
        await _cameraController.stopVideoRecording();
        setState(() {
          _isRecording = false;
          _isPaused = false;
        });
        DashcamBackgroundService().stopBackgroundRecording();
      } catch (e) {
        // Handle error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error stopping recording: $e')),
        );
        return;
      }
    }

    // Delete the current video file if it exists
    if (_currentVideoPath != null) {
      try {
        final file = File(_currentVideoPath!);
        if (await file.exists()) {
          await file.delete();
          _currentVideoPath = null;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Recording deleted')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting recording: $e')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No recording to delete')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashcam'),
        actions: [
          IconButton(
            icon: Icon(_isAudioEnabled ? Icons.mic : Icons.mic_off),
            onPressed: _toggleAudio,
            tooltip: 'Toggle Audio',
          ),
        ],
      ),
      body: Column(
        children: [
          // Camera preview (50% of screen in square shape)
          Container(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context)
                .size
                .width, // Same as width to make it square
            alignment: Alignment.center,
            child: AspectRatio(
              aspectRatio: 1.0, // Square aspect ratio
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: CameraPreview(_cameraController),
              ),
            ),
          ),

          // Recording duration and status
          Container(
            padding: const EdgeInsets.all(8.0),
            color: Colors.black,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      _isRecording
                          ? _isPaused
                              ? Icons.pause
                              : Icons.fiber_manual_record
                          : Icons.stop,
                      color: _isRecording && !_isPaused
                          ? Colors.red
                          : Colors.white,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _isRecording ? _recordingDuration : 'Ready',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ],
                ),
                Text(
                  'Camera: ${widget.cameraType.toString().split('.').last}',
                  style: const TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),

          // Recording options
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Duration selection
                  const Text(
                    'Recording Duration:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildDurationOption('15m', '15 min'),
                      _buildDurationOption('30m', '30 min'),
                      _buildDurationOption('1h', '1 hour'),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Storage option
                  const Text(
                    'Storage Option:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStorageOption('local', 'Local Storage'),
                      _buildStorageOption('cloud', 'Cloud Storage'),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Recording progress (seekbar)
                  if (_isRecording)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Recording Progress:',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: _calculateProgressValue(),
                          backgroundColor: Colors.grey[300],
                          valueColor:
                              const AlwaysStoppedAnimation<Color>(Colors.red),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),

          // Recording controls
          Container(
            padding: const EdgeInsets.all(16.0),
            color: Colors.grey[200],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Record/Stop button
                IconButton(
                  icon: Icon(
                    _isRecording ? Icons.stop : Icons.fiber_manual_record,
                    color: _isRecording ? Colors.black : Colors.red,
                    size: 36,
                  ),
                  onPressed: _toggleRecording,
                  tooltip: _isRecording ? 'Stop Recording' : 'Start Recording',
                ),
                // Pause/Resume button (only shown when recording)
                if (_isRecording)
                  IconButton(
                    icon: Icon(
                      _isPaused ? Icons.play_arrow : Icons.pause,
                      size: 36,
                    ),
                    onPressed: _pauseResumeRecording,
                    tooltip: _isPaused ? 'Resume Recording' : 'Pause Recording',
                  ),
                // Save button
                ElevatedButton.icon(
                  icon: const Icon(Icons.save),
                  label: const Text('Save'),
                  onPressed: _isRecording
                      ? () async {
                          final videoFile =
                              await _cameraController.stopVideoRecording();
                          setState(() {
                            _isRecording = false;
                            _isPaused = false;
                          });
                          _stopRecordingTimer();
                          await _saveVideoFile(videoFile);
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
                // Delete button
                ElevatedButton.icon(
                  icon: const Icon(Icons.delete),
                  label: const Text('Delete'),
                  onPressed: _deleteCurrentRecording,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDurationOption(String value, String label) {
    final isSelected = _selectedDuration == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          _setRecordingDuration(value);
        }
      },
    );
  }

  Widget _buildStorageOption(String value, String label) {
    final isSelected = _storageOption == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          _setStorageOption(value);
        }
      },
    );
  }

  double _calculateProgressValue() {
    // Calculate progress based on elapsed time and selected duration
    int totalSeconds;
    switch (_selectedDuration) {
      case '15m':
        totalSeconds = 15 * 60;
        break;
      case '30m':
        totalSeconds = 30 * 60;
        break;
      case '1h':
        totalSeconds = 60 * 60;
        break;
      default:
        totalSeconds = 15 * 60;
    }

    return _elapsedSeconds / totalSeconds;
  }
}

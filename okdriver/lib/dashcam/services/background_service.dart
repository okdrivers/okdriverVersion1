import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_local_notifications_platform_interface/flutter_local_notifications_platform_interface.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';

const notificationChannelId = 'my_foreground';
const notificationId = 888;

// Initialize service with proper notification channel
Future<void> initializeService() async {
  final service = FlutterBackgroundService();

  // Create notification channel for Android 8.0+
  await _createNotificationChannel();

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      isForegroundMode: true,
      autoStart: false,
      notificationChannelId: notificationChannelId,
      initialNotificationTitle: 'Dashcam Recording',
      initialNotificationContent: 'Initializing',
      foregroundServiceNotificationId: notificationId,
    ),
    iosConfiguration: IosConfiguration(
      autoStart: false,
      onForeground: onStart,
      onBackground: onIosBackground,
    ),
  );
}

// Create notification channel for Android 8.0+
Future<void> _createNotificationChannel() async {
  final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  const androidNotificationChannel = AndroidNotificationChannel(
    notificationChannelId, // Same channel ID as used in service
    'Dashcam Recording Service', // Channel name
    description:
        'Notifications for dashcam recording service', // Channel description
    importance: Importance.low, // Low importance to minimize visibility
  );

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(androidNotificationChannel);
}

@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  return true;
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  // Ensure Flutter is initialized in this isolate
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();

  // Global variables for background recording
  CameraController? cameraController;
  bool isRecording = false;
  String? currentVideoPath;
  int elapsedSeconds = 0;

  if (service is AndroidServiceInstance) {
    service.on('setAsForeground').listen((event) {
      if (event != null && event is Map<String, dynamic>) {
        service.setAsForegroundService();
      }
    });

    service.on('setAsBackground').listen((event) {
      service.setAsBackgroundService();
    });

    // Handle start recording event
    service.on('startRecording').listen((event) async {
      if (event != null && event is Map<String, dynamic>) {
        try {
          // Initialize camera if needed
          if (cameraController == null ||
              !cameraController!.value.isInitialized) {
            final cameras = await availableCameras();
            if (cameras.isEmpty) return;

            // Use the first camera (usually back camera)
            final cameraDescription = cameras.first;

            cameraController = CameraController(
              cameraDescription,
              ResolutionPreset.high,
              enableAudio: true,
              imageFormatGroup: ImageFormatGroup.jpeg,
            );

            await cameraController!.initialize();
          }

          // Start recording
          if (!isRecording) {
            final directory = await getApplicationDocumentsDirectory();
            final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
            currentVideoPath = '${directory.path}/dashcam_$timestamp.mp4';

            await cameraController!.startVideoRecording();
            isRecording = true;
            elapsedSeconds = 0;

            print('Background recording started: $currentVideoPath');
          }
        } catch (e) {
          print('Error starting background recording: $e');
        }
      }
    });

    // Handle stop recording event
    service.on('stopRecording').listen((event) async {
      if (isRecording &&
          cameraController != null &&
          cameraController!.value.isRecordingVideo) {
        try {
          final videoFile = await cameraController!.stopVideoRecording();
          isRecording = false;
          print('Background recording stopped: ${videoFile.path}');

          // Save to gallery
          try {
            await ImageGallerySaver.saveFile(videoFile.path);
            print('Video saved to gallery');
          } catch (e) {
            print('Error saving to gallery: $e');
          }

          service.invoke('recordingStopped', {'videoPath': videoFile.path});
        } catch (e) {
          print('Error stopping background recording: $e');
        }
      }
    });
  }

  service.on('stopService').listen((event) {
    // Stop recording if active before stopping service
    if (isRecording &&
        cameraController != null &&
        cameraController!.value.isRecordingVideo) {
      cameraController!.stopVideoRecording().then((file) {
        print('Recording stopped before service termination: ${file.path}');
      }).catchError((error) {
        print('Error stopping recording: $error');
      });
    }

    // Dispose camera controller
    cameraController?.dispose();

    service.stopSelf();
  });

  // Set service to run in background with minimal notification
  if (service is AndroidServiceInstance) {
    try {
      service.setAsForegroundService();
      // Android requires a valid notification for foreground services
      service.setForegroundNotificationInfo(
        title: "Dashcam Running",
        content: "Recording in background",
      );
    } catch (e) {
      print('Error setting foreground service: $e');
    }
  }

  // Update service state and notification periodically
  Timer.periodic(const Duration(seconds: 1), (timer) async {
    if (service is AndroidServiceInstance) {
      try {
        if (await service.isForegroundService()) {
          if (isRecording) {
            elapsedSeconds++;
            final minutes = (elapsedSeconds ~/ 60).toString().padLeft(2, '0');
            final seconds = (elapsedSeconds % 60).toString().padLeft(2, '0');

            // Update notification with recording status and time
            service.setForegroundNotificationInfo(
              title: "Dashcam Recording",
              content: "Recording: $minutes:$seconds",
            );
          } else {
            // Update notification for standby mode
            service.setForegroundNotificationInfo(
              title: "Dashcam Ready",
              content: "Ready to record",
            );
          }
        }
      } catch (e) {
        print('Error updating foreground notification: $e');
      }
    }

    try {
      service.invoke(
        'update',
        {
          "current_date": DateTime.now().toIso8601String(),
          "elapsed_seconds": elapsedSeconds,
          "is_recording": isRecording,
        },
      );
    } catch (e) {
      print('Error invoking update event: $e');
    }
  });
}

class DashcamBackgroundService {
  static final DashcamBackgroundService _instance =
      DashcamBackgroundService._internal();
  factory DashcamBackgroundService() => _instance;
  DashcamBackgroundService._internal();

  CameraController? _cameraController;
  bool _isRecording = false;
  Timer? _timer;
  Timer? _recordingTimer;
  Timer? _autoStopTimer;
  int _elapsedSeconds = 0;
  FlutterBackgroundService? _backgroundService;
  bool _isServiceRunning = false;

  String? _currentVideoPath;
  int _maxRecordingDurationSeconds = 15 * 60; // Default 15 minutes

  // Initialize the background service
  Future<void> initialize({
    required CameraController cameraController,
    required int maxRecordingDurationMinutes,
  }) async {
    _cameraController = cameraController;
    _maxRecordingDurationSeconds = maxRecordingDurationMinutes * 60;

    try {
      // Initialize the background service
      await initializeService();

      // Get the service instance in the main isolate
      _backgroundService = FlutterBackgroundService();

      // Listen for updates from the background service
      _backgroundService?.on('update').listen((event) {
        if (event != null && event is Map<String, dynamic>) {
          if (event.containsKey('elapsed_seconds')) {
            _elapsedSeconds = event['elapsed_seconds'] as int;
          }
          if (event.containsKey('is_recording')) {
            _isRecording = event['is_recording'] as bool;
          }
        }
      });

      // Listen for recording stopped event
      _backgroundService?.on('recordingStopped').listen((event) {
        if (event != null && event is Map<String, dynamic>) {
          if (event.containsKey('videoPath')) {
            _currentVideoPath = event['videoPath'] as String;
            print('Recording stopped in background: $_currentVideoPath');
          }
        }
      });
    } catch (e) {
      print('Error initializing background service in main isolate: $e');
    }
  }

  // Start background recording
  Future<void> startBackgroundRecording() async {
    if (_isRecording) return; // Prevent multiple starts

    try {
      // Start the background service if not already running
      if (!_isServiceRunning) {
        await _backgroundService?.startService();
        _isServiceRunning = true;
      }

      // Tell the service to start recording
      _backgroundService?.invoke('startRecording', {
        'enableAudio': true,
        'maxDurationSeconds': _maxRecordingDurationSeconds,
      });

      _isRecording = true;
      _elapsedSeconds = 0;

      // Set up automatic stop based on max duration
      _setupAutomaticStop();
    } catch (e) {
      print('Error starting background recording: $e');
      // Reset state if service fails to start
      _isServiceRunning = false;
      _isRecording = false;
      throw Exception('Failed to start background recording: $e');
    }
  }

  // Stop background recording
  Future<void> stopBackgroundRecording() async {
    if (!_isRecording) return; // Prevent multiple stops

    try {
      // Tell the service to stop recording
      _backgroundService?.invoke('stopRecording');

      _isRecording = false;
      _autoStopTimer?.cancel();
      _elapsedSeconds = 0;
    } catch (e) {
      print('Error stopping background recording: $e');
      // Reset state even if there's an error
      _isRecording = false;
      _autoStopTimer?.cancel();
      _elapsedSeconds = 0;
    }
  }

  // Set up automatic stop based on max duration
  void _setupAutomaticStop() {
    _autoStopTimer?.cancel();
    _autoStopTimer = Timer(Duration(seconds: _maxRecordingDurationSeconds), () {
      if (_isRecording) {
        stopBackgroundRecording();
      }
    });
  }

  // Stop the background service completely
  Future<void> stopService() async {
    if (_isRecording) {
      await stopBackgroundRecording();
    }

    try {
      _backgroundService?.invoke('stopService');
      _isServiceRunning = false;
    } catch (e) {
      print('Error stopping background service: $e');
      // Reset state even if there's an error
      _isServiceRunning = false;
    }
  }

  // Dispose resources
  void dispose() {
    if (_isRecording) {
      stopBackgroundRecording();
    }
    _autoStopTimer?.cancel();
    _autoStopTimer = null;
  }

  // Get formatted duration
  String getFormattedDuration() {
    final minutes = (_elapsedSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (_elapsedSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  // Check if recording is in progress
  bool get isRecording => _isRecording;

  // Get elapsed seconds
  int get elapsedSeconds => _elapsedSeconds;

  // Get current video path
  String? get currentVideoPath => _currentVideoPath;

  // Get remaining time in seconds
  int get remainingSeconds => _maxRecordingDurationSeconds - _elapsedSeconds;

  // Get formatted remaining time
  String getFormattedRemainingTime() {
    final remaining = remainingSeconds;
    if (remaining <= 0) return '00:00';

    final minutes = (remaining ~/ 60).toString().padLeft(2, '0');
    final seconds = (remaining % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  // Check if service is running
  bool get isServiceRunning => _isServiceRunning;
}

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:okdriver/dashcam/models/video_file.dart';
import 'package:okdriver/dashcam/services/camera_service.dart';
import 'package:okdriver/theme/theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';

class SavedVideosScreen extends StatefulWidget {
  const SavedVideosScreen({Key? key}) : super(key: key);

  @override
  State<SavedVideosScreen> createState() => _SavedVideosScreenState();
}

class _SavedVideosScreenState extends State<SavedVideosScreen> {
  final CameraService _cameraService = CameraService();
  List<VideoFile> _videoFiles = [];
  bool _isLoading = true;
  VideoPlayerController? _videoController;
  VideoFile? _selectedVideo;
  bool _isDarkMode = false;

  @override
  void initState() {
    super.initState();
    _loadTheme();
    _loadSavedVideos();
  }

  void _loadTheme() {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    setState(() {
      // _isDarkMode = themeProvider.isDarkMode;
    });
  }

  Future<void> _loadSavedVideos() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get the list of saved video paths
      final videoPaths = await _cameraService.loadSavedVideos();

      // Convert paths to VideoFile objects
      final videoFiles = <VideoFile>[];
      for (final path in videoPaths) {
        final videoFile = await VideoFile.fromFile(
          filePath: path,
          cameraType:
              'unknown', // In a real app, this would be stored with the video
          hasAudio: true, // In a real app, this would be stored with the video
          storageType:
              'local', // In a real app, this would be stored with the video
        );

        if (videoFile != null) {
          videoFiles.add(videoFile);
        }
      }

      // Sort by timestamp (newest first)
      videoFiles.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      setState(() {
        _videoFiles = videoFiles;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading saved videos: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _playVideo(VideoFile videoFile) {
    // Dispose of any existing controller
    _videoController?.dispose();

    // Create a new controller for the selected video
    _videoController = VideoPlayerController.file(File(videoFile.filePath))
      ..initialize().then((_) {
        // Ensure the first frame is shown
        setState(() {
          _selectedVideo = videoFile;
        });
        _videoController!.play();
      });
  }

  void _stopVideo() {
    _videoController?.pause();
    _videoController?.dispose();
    _videoController = null;

    setState(() {
      _selectedVideo = null;
    });
  }

  Future<void> _deleteVideo(VideoFile videoFile) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Video'),
            content: Text(
                'Are you sure you want to delete "${videoFile.formattedTimestamp}"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed) return;

    // If this is the currently playing video, stop it
    if (_selectedVideo?.id == videoFile.id) {
      _stopVideo();
    }

    // Delete the video file
    final success = await _cameraService.deleteSavedVideo(videoFile.filePath);

    if (success) {
      setState(() {
        _videoFiles.removeWhere((v) => v.id == videoFile.id);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Video deleted successfully')),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete video')),
        );
      }
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Recordings'),
        actions: [
          if (_selectedVideo != null)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: _stopVideo,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _selectedVideo != null
              ? _buildVideoPlayer()
              : _buildVideoList(),
    );
  }

  Widget _buildVideoPlayer() {
    if (_selectedVideo == null || _videoController == null) {
      return const Center(child: Text('No video selected'));
    }

    if (!_videoController!.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        AspectRatio(
          aspectRatio: _videoController!.value.aspectRatio,
          child: VideoPlayer(_videoController!),
        ),
        _buildVideoControls(),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Recorded: ${_selectedVideo!.formattedTimestamp}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text('Duration: ${_selectedVideo!.formattedDuration}'),
              Text('File size: ${_selectedVideo!.formattedFileSize}'),
              Text('Camera: ${_selectedVideo!.cameraType}'),
              Text('Audio: ${_selectedVideo!.hasAudio ? 'Yes' : 'No'}'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVideoControls() {
    return ValueListenableBuilder(
      valueListenable: _videoController!,
      builder: (context, VideoPlayerValue value, child) {
        final position = value.position;
        final duration = value.duration;

        return Column(
          children: [
            Slider(
              value: position.inMilliseconds.toDouble(),
              min: 0,
              max: duration.inMilliseconds.toDouble(),
              onChanged: (value) {
                _videoController!.seekTo(Duration(milliseconds: value.toInt()));
              },
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(_formatDuration(position)),
                  Text(_formatDuration(duration)),
                ],
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.replay_10),
                  onPressed: () {
                    final newPosition = position - const Duration(seconds: 10);
                    _videoController!.seekTo(
                        newPosition.isNegative ? Duration.zero : newPosition);
                  },
                ),
                IconButton(
                  icon: Icon(
                    value.isPlaying ? Icons.pause : Icons.play_arrow,
                    size: 40,
                  ),
                  onPressed: () {
                    value.isPlaying
                        ? _videoController!.pause()
                        : _videoController!.play();
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.forward_10),
                  onPressed: () {
                    final newPosition = position + const Duration(seconds: 10);
                    _videoController!.seekTo(
                      newPosition > duration ? duration : newPosition,
                    );
                  },
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildVideoList() {
    if (_videoFiles.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.videocam_off,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            const Text(
              'No recordings found',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 8),
            const Text(
              'Your saved dashcam recordings will appear here',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _videoFiles.length,
      itemBuilder: (context, index) {
        final videoFile = _videoFiles[index];
        return _buildVideoListItem(videoFile);
      },
    );
  }

  Widget _buildVideoListItem(VideoFile videoFile) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.videocam,
            color: Colors.white,
            size: 32,
          ),
        ),
        title: Text(videoFile.formattedTimestamp),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Duration: ${videoFile.formattedDuration}'),
            Text('Size: ${videoFile.formattedFileSize}'),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.play_arrow),
              onPressed: () => _playVideo(videoFile),
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => _deleteVideo(videoFile),
            ),
          ],
        ),
        onTap: () => _playVideo(videoFile),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}

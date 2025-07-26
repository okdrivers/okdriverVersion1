import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoPreviewScreen extends StatefulWidget {
  final String? videoPath;
  final bool isRecording;
  final bool isPaused;
  final String selectedCamera; // 'front', 'back', or 'dual'
  final VideoPlayerController? livePreviewController;
  final VideoPlayerController? savedVideoController;
  final bool isPlayingSavedVideo;

  const VideoPreviewScreen({
    Key? key,
    this.videoPath,
    required this.isRecording,
    required this.isPaused,
    required this.selectedCamera,
    this.livePreviewController,
    this.savedVideoController,
    this.isPlayingSavedVideo = false,
  }) : super(key: key);

  @override
  State<VideoPreviewScreen> createState() => _VideoPreviewScreenState();
}

class _VideoPreviewScreenState extends State<VideoPreviewScreen> {
  double _currentPosition = 0;
  double _videoDuration = 1; // Default to 1 to avoid division by zero
  bool _isDraggingSeekBar = false;

  @override
  void initState() {
    super.initState();
    _initializeVideoPlayer();
  }

  void _initializeVideoPlayer() {
    if (widget.isPlayingSavedVideo && widget.savedVideoController != null) {
      widget.savedVideoController!.addListener(_updateVideoProgress);
    }
  }

  void _updateVideoProgress() {
    if (!mounted || _isDraggingSeekBar) return;

    if (widget.savedVideoController != null && widget.isPlayingSavedVideo) {
      final duration =
          widget.savedVideoController!.value.duration.inMilliseconds.toDouble();
      if (duration <= 0) return;

      setState(() {
        _videoDuration = duration;
        _currentPosition = widget
            .savedVideoController!.value.position.inMilliseconds
            .toDouble();
      });
    }
  }

  @override
  void dispose() {
    if (widget.savedVideoController != null) {
      widget.savedVideoController!.removeListener(_updateVideoProgress);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildVideoPreview(),
        if (widget.isPlayingSavedVideo && widget.savedVideoController != null)
          _buildVideoControls(),
      ],
    );
  }

  Widget _buildVideoPreview() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.25, // 25% of screen height
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: _buildPreviewContent(),
      ),
    );
  }

  Widget _buildPreviewContent() {
    // Show saved video playback
    if (widget.isPlayingSavedVideo && widget.savedVideoController != null) {
      return widget.savedVideoController!.value.isInitialized
          ? AspectRatio(
              aspectRatio: widget.savedVideoController!.value.aspectRatio,
              child: VideoPlayer(widget.savedVideoController!),
            )
          : const Center(child: CircularProgressIndicator());
    }

    // Show live camera preview
    if (widget.livePreviewController != null) {
      return Stack(
        children: [
          widget.livePreviewController!.value.isInitialized
              ? AspectRatio(
                  aspectRatio: widget.livePreviewController!.value.aspectRatio,
                  child: VideoPlayer(widget.livePreviewController!),
                )
              : const Center(child: CircularProgressIndicator()),
          if (widget.isRecording)
            Positioned(
              top: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.circle,
                      color: widget.isPaused ? Colors.grey : Colors.red,
                      size: 12,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      widget.isPaused ? 'PAUSED' : 'REC',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          Positioned(
            bottom: 16,
            left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'Camera: ${widget.selectedCamera.toUpperCase()}',
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ),
        ],
      );
    }

    // Fallback when no preview is available
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.videocam_off, size: 48, color: Colors.white54),
          const SizedBox(height: 16),
          Text(
            'No camera preview available',
            style: TextStyle(color: Colors.white.withOpacity(0.7)),
          ),
          const SizedBox(height: 8),
          Text(
            'Select a camera to start',
            style:
                TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoControls() {
    return Column(
      children: [
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Text(
                _formatDuration(_currentPosition),
                style: const TextStyle(fontSize: 12),
              ),
              Expanded(
                child: Slider(
                  value: _currentPosition,
                  min: 0,
                  max: _videoDuration,
                  onChanged: (value) {
                    setState(() {
                      _currentPosition = value;
                      _isDraggingSeekBar = true;
                    });
                  },
                  onChangeEnd: (value) {
                    setState(() {
                      _isDraggingSeekBar = false;
                    });
                    widget.savedVideoController?.seekTo(
                      Duration(milliseconds: value.toInt()),
                    );
                  },
                ),
              ),
              Text(
                _formatDuration(_videoDuration),
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.replay_10),
              onPressed: () {
                final newPosition = _currentPosition - 10000;
                widget.savedVideoController?.seekTo(
                  Duration(
                      milliseconds: newPosition > 0 ? newPosition.toInt() : 0),
                );
              },
            ),
            IconButton(
              icon: Icon(
                widget.savedVideoController?.value.isPlaying ?? false
                    ? Icons.pause
                    : Icons.play_arrow,
                size: 32,
              ),
              onPressed: () {
                if (widget.savedVideoController?.value.isPlaying ?? false) {
                  widget.savedVideoController?.pause();
                } else {
                  widget.savedVideoController?.play();
                }
                setState(() {});
              },
            ),
            IconButton(
              icon: const Icon(Icons.forward_10),
              onPressed: () {
                final newPosition = _currentPosition + 10000;
                widget.savedVideoController?.seekTo(
                  Duration(
                    milliseconds: newPosition < _videoDuration
                        ? newPosition.toInt()
                        : _videoDuration.toInt(),
                  ),
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  String _formatDuration(double milliseconds) {
    final duration = Duration(milliseconds: milliseconds.toInt());
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}

import 'package:flutter/material.dart';
import 'package:okdriver/driver_profile_screen/components/subscription_plan.dart';

class RecordingControlsScreen extends StatefulWidget {
  final Function(bool) onAudioToggle;
  final Function(int) onDurationChange;
  final Function(String) onStorageLocationChange;
  final Function() onStartRecording;
  final Function() onPauseRecording;
  final Function() onStopRecording;
  final Function() onDeleteRecording;
  final bool isRecording;
  final bool isPaused;

  const RecordingControlsScreen({
    Key? key,
    required this.onAudioToggle,
    required this.onDurationChange,
    required this.onStorageLocationChange,
    required this.onStartRecording,
    required this.onPauseRecording,
    required this.onStopRecording,
    required this.onDeleteRecording,
    required this.isRecording,
    required this.isPaused,
  }) : super(key: key);

  @override
  State<RecordingControlsScreen> createState() =>
      _RecordingControlsScreenState();
}

class _RecordingControlsScreenState extends State<RecordingControlsScreen> {
  bool _recordWithAudio = true;
  String _storageLocation = 'local'; // 'local' or 'cloud'
  int _recordingDuration = 15; // in minutes
  final List<int> _availableDurations = [15, 30, 60]; // in minutes

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStorageSelector(),
        if (_storageLocation == 'local') _buildDurationSelector(),
        _buildAudioToggle(),
        const SizedBox(height: 20),
        _buildRecordingControls(),
      ],
    );
  }

  Widget _buildStorageSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 16, top: 16, bottom: 8),
          child: Text(
            'Storage Location',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        Row(
          children: [
            Expanded(
              child: _buildStorageOption(
                'Local Storage',
                'local',
                Icons.phone_android,
              ),
            ),
            Expanded(
              child: _buildStorageOption(
                'Cloud Storage',
                'cloud',
                Icons.cloud_upload,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStorageOption(String title, String value, IconData icon) {
    final isSelected = _storageLocation == value;

    return InkWell(
      onTap: () {
        setState(() {
          _storageLocation = value;
        });
        widget.onStorageLocationChange(value);

        // If cloud storage is selected, navigate to subscription plan
        if (value == 'cloud') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const BuyPlanScreen()),
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).primaryColor.withOpacity(0.1)
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).primaryColor
                : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected
                  ? Theme.of(context).primaryColor
                  : Colors.grey.shade600,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                color: isSelected
                    ? Theme.of(context).primaryColor
                    : Colors.grey.shade800,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDurationSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 16, top: 16, bottom: 8),
          child: Text(
            'Recording Duration',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: _availableDurations.map((duration) {
              return _buildDurationOption(duration);
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildDurationOption(int duration) {
    final isSelected = _recordingDuration == duration;
    String durationText = duration == 60 ? '1 hour' : '$duration min';

    return InkWell(
      onTap: () {
        setState(() {
          _recordingDuration = duration;
        });
        widget.onDurationChange(duration);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).primaryColor.withOpacity(0.1)
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).primaryColor
                : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Text(
          durationText,
          style: TextStyle(
            color: isSelected
                ? Theme.of(context).primaryColor
                : Colors.grey.shade800,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildAudioToggle() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const Text(
            'Record with Audio',
            style: TextStyle(fontSize: 16),
          ),
          const Spacer(),
          Switch(
            value: _recordWithAudio,
            onChanged: (value) {
              setState(() {
                _recordWithAudio = value;
              });
              widget.onAudioToggle(value);
            },
            activeColor: Theme.of(context).primaryColor,
          ),
        ],
      ),
    );
  }

  Widget _buildRecordingControls() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildControlButton(
                icon: widget.isRecording
                    ? (widget.isPaused ? Icons.play_arrow : Icons.pause)
                    : Icons.fiber_manual_record,
                label: widget.isRecording
                    ? (widget.isPaused ? 'Resume' : 'Pause')
                    : 'Record',
                color: widget.isRecording && !widget.isPaused
                    ? Colors.amber
                    : Colors.red,
                onPressed: () {
                  if (!widget.isRecording) {
                    widget.onStartRecording();
                  } else if (widget.isPaused) {
                    widget.onStartRecording(); // Resume recording
                  } else {
                    widget.onPauseRecording();
                  }
                },
              ),
              if (widget.isRecording)
                _buildControlButton(
                  icon: Icons.stop,
                  label: 'Stop',
                  color: Colors.blue,
                  onPressed: widget.onStopRecording,
                ),
              if (widget.isRecording)
                _buildControlButton(
                  icon: Icons.delete,
                  label: 'Delete',
                  color: Colors.grey,
                  onPressed: widget.onDeleteRecording,
                ),
            ],
          ),
          if (widget.isRecording) const SizedBox(height: 16),
          if (widget.isRecording)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.circle,
                    color: widget.isPaused ? Colors.grey : Colors.red,
                    size: 12,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    widget.isPaused
                        ? 'Recording Paused'
                        : 'Recording in Progress',
                    style: TextStyle(
                      color: widget.isPaused ? Colors.grey : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Column(
      children: [
        ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            shape: const CircleBorder(),
            padding: const EdgeInsets.all(16),
            backgroundColor: color,
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 32,
          ),
        ),
        const SizedBox(height: 8),
        Text(label),
      ],
    );
  }
}

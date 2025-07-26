import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class CameraSelectionScreen extends StatefulWidget {
  final Function(String) onCameraSelected;

  const CameraSelectionScreen({Key? key, required this.onCameraSelected})
      : super(key: key);

  @override
  State<CameraSelectionScreen> createState() => _CameraSelectionScreenState();
}

class _CameraSelectionScreenState extends State<CameraSelectionScreen> {
  final List<Map<String, dynamic>> _cameras = [
    {
      'id': 'front',
      'name': 'Front Camera',
      'icon': Icons.camera_front,
      'description': 'Use the front-facing camera',
    },
    {
      'id': 'back',
      'name': 'Back Camera',
      'icon': Icons.camera_rear,
      'description': 'Use the rear-facing camera',
    },
    {
      'id': 'dual',
      'name': 'Dual Camera',
      'icon': Icons.camera,
      'description': 'Use both front and rear cameras',
    },
  ];

  String _selectedCamera = 'back'; // Default to back camera
  bool _hasCameraPermission = false;

  @override
  void initState() {
    super.initState();
    _checkCameraPermission();
  }

  Future<void> _checkCameraPermission() async {
    final status = await Permission.camera.status;
    setState(() {
      _hasCameraPermission = status.isGranted;
    });

    if (!status.isGranted) {
      await _requestCameraPermission();
    }
  }

  Future<void> _requestCameraPermission() async {
    final status = await Permission.camera.request();
    setState(() {
      _hasCameraPermission = status.isGranted;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Camera'),
        elevation: 0,
      ),
      body: _hasCameraPermission
          ? _buildCameraSelectionList()
          : _buildPermissionRequest(),
    );
  }

  Widget _buildCameraSelectionList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _cameras.length,
      itemBuilder: (context, index) {
        final camera = _cameras[index];
        final isSelected = camera['id'] == _selectedCamera;

        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              setState(() {
                _selectedCamera = camera['id'];
              });
              widget.onCameraSelected(camera['id']);
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: isSelected
                    ? Border.all(
                        color: Theme.of(context).primaryColor, width: 2)
                    : null,
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Theme.of(context).primaryColor
                          : Colors.grey.shade200,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      camera['icon'],
                      color: isSelected ? Colors.white : Colors.grey.shade700,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          camera['name'],
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          camera['description'],
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isSelected)
                    Icon(
                      Icons.check_circle,
                      color: Theme.of(context).primaryColor,
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPermissionRequest() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.camera_alt_outlined,
            size: 80,
            color: Colors.grey,
          ),
          const SizedBox(height: 24),
          const Text(
            'Camera Permission Required',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'OkDriver needs access to your camera to record dashcam footage.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _requestCameraPermission,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Grant Permission'),
          ),
        ],
      ),
    );
  }
}

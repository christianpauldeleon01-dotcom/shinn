import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/cupertino.dart';
import 'package:flutter/rendering.dart';
import 'package:image_picker/image_picker.dart';
import 'package:gal/gal.dart';
import 'package:latlong2/latlong.dart';
import 'package:path_provider/path_provider.dart';
import '../services/gps_service.dart';
import '../services/activity_service.dart';

class ActivityPhotoScreen extends StatefulWidget {
  final double distance;
  final String duration;
  final String pace;

  const ActivityPhotoScreen({
    super.key,
    required this.distance,
    required this.duration,
    required this.pace,
  });

  @override
  State<ActivityPhotoScreen> createState() => _ActivityPhotoScreenState();
}

class _ActivityPhotoScreenState extends State<ActivityPhotoScreen> {
  final ImagePicker _picker = ImagePicker();
  final GlobalKey _captureKey = GlobalKey();
  final ActivityService _activityService = ActivityService();

  File? _imageFile;
  bool _isCapturing = false;
  bool _showOverlay = true;

  double _overlayX = 20;
  double _overlayY = 20;
  double _overlayScale = 1.0;
  
  List<LatLng> _routePoints = [];

  @override
  void initState() {
    super.initState();
    _loadRoute();
  }

  void _loadRoute() {
    final coordinates = _activityService.coordinates;
    setState(() {
      _routePoints = GPSService.coordinatesToLatLng(coordinates);
    });
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Add Photo'),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => Navigator.of(context).pop(null),
          child: const Text('Skip'),
        ),
        trailing: _imageFile != null
            ? CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: _savePhoto,
                child: const Text(
                  'Save',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              )
            : null,
      ),
      child: SafeArea(
        child: _imageFile == null
            ? _buildImagePicker()
            : _buildPhotoEditor(),
      ),
    );
  }

  Widget _buildImagePicker() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            margin: const EdgeInsets.symmetric(horizontal: 32),
            decoration: BoxDecoration(
              color: CupertinoColors.systemGrey6.resolveFrom(context),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildQuickStat('Distance', '${widget.distance.toStringAsFixed(2)} km'),
                    Container(width: 1, height: 40, color: CupertinoColors.separator),
                    _buildQuickStat('Duration', widget.duration),
                    Container(width: 1, height: 40, color: CupertinoColors.separator),
                    _buildQuickStat('Pace', '${widget.pace}/km'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          Text(
            'Add a photo to your activity',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: CupertinoColors.label.resolveFrom(context),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Take a photo to remember your run',
            style: TextStyle(
              color: CupertinoColors.secondaryLabel.resolveFrom(context),
            ),
          ),
          const SizedBox(height: 32),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildImagePickerButton(
                icon: CupertinoIcons.camera_fill,
                label: 'Camera',
                onTap: () => _pickImage(ImageSource.camera),
                isPrimary: true,
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          CupertinoButton(
            onPressed: () => _pickImage(ImageSource.gallery),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  CupertinoIcons.photo_on_rectangle,
                  color: CupertinoColors.systemOrange,
                ),
                const SizedBox(width: 8),
                const Text('Choose from Gallery'),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          CupertinoButton(
            onPressed: () => Navigator.of(context).pop(null),
            child: Text(
              'Skip',
              style: TextStyle(
                color: CupertinoColors.secondaryLabel.resolveFrom(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: CupertinoColors.secondaryLabel.resolveFrom(context),
          ),
        ),
      ],
    );
  }

  Widget _buildImagePickerButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isPrimary = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: isPrimary ? 90 : 80,
            height: isPrimary ? 90 : 80,
            decoration: BoxDecoration(
              gradient: isPrimary
                  ? const LinearGradient(
                      colors: [
                        CupertinoColors.systemOrange,
                        CupertinoColors.systemRed,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              color: isPrimary 
                  ? null 
                  : CupertinoColors.systemOrange.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              boxShadow: isPrimary
                  ? [
                      BoxShadow(
                        color: CupertinoColors.systemOrange.withValues(alpha: 0.4),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ]
                  : null,
            ),
            child: Icon(
              icon,
              size: isPrimary ? 40 : 36,
              color: isPrimary 
                  ? CupertinoColors.white 
                  : CupertinoColors.systemOrange,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontWeight: isPrimary ? FontWeight.bold : FontWeight.w500,
              color: isPrimary 
                  ? CupertinoColors.systemOrange 
                  : CupertinoColors.label.resolveFrom(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoEditor() {
    return Column(
      children: [
        Expanded(
          child: RepaintBoundary(
            key: _captureKey,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.file(
                  _imageFile!,
                  fit: BoxFit.cover,
                ),
                if (_showOverlay)
                  Positioned(
                    left: _overlayX,
                    top: _overlayY,
                    child: GestureDetector(
                      onPanUpdate: (details) {
                        setState(() {
                          _overlayX += details.delta.dx;
                          _overlayY += details.delta.dy;
                        });
                      },
                      child: Transform.scale(
                        scale: _overlayScale,
                        child: _buildStravaOverlay(),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: CupertinoColors.systemBackground.resolveFrom(context),
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  const Icon(
                    CupertinoIcons.arrow_up_left_arrow_down_right,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  const Text('Size'),
                  Expanded(
                    child: CupertinoSlider(
                      value: _overlayScale,
                      min: 0.5,
                      max: 1.5,
                      onChanged: (value) {
                        setState(() {
                          _overlayScale = value;
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: CupertinoButton(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      color: CupertinoColors.systemGrey5,
                      onPressed: _retakePhoto,
                      child: const Text(
                        'Retake',
                        style: TextStyle(
                          color: CupertinoColors.label,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CupertinoButton.filled(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      onPressed: _isCapturing ? null : _saveWithOverlay,
                      child: _isCapturing
                          ? const CupertinoActivityIndicator(
                              color: CupertinoColors.white,
                            )
                          : const Text('Save with Overlay'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStravaOverlay() {
    return Container(
      width: 180,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.black.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(
                CupertinoIcons.location_fill,
                color: CupertinoColors.systemOrange,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                '${widget.distance.toStringAsFixed(2)} km',
                style: const TextStyle(
                  color: CupertinoColors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                CupertinoIcons.timer,
                color: CupertinoColors.white,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                widget.duration,
                style: const TextStyle(
                  color: CupertinoColors.white,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(
                CupertinoIcons.speedometer,
                color: CupertinoColors.white,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                '${widget.pace} /km',
                style: const TextStyle(
                  color: CupertinoColors.white,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_routePoints.isNotEmpty)
            SizedBox(
              height: 60,
              child: CustomPaint(
                size: const Size(double.infinity, 60),
                painter: _RoutePolylinePainter(
                  points: _routePoints,
                  color: CupertinoColors.systemOrange,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _imageFile = File(image.path);
        });
      }
    } catch (e) {
      // Handle error silently
    }
  }

  void _retakePhoto() {
    setState(() {
      _imageFile = null;
      _showOverlay = true;
      _overlayX = 20;
      _overlayY = 20;
      _overlayScale = 1.0;
    });
  }

  void _showSaveSuccessDialog() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Photo Saved'),
        content: const Text('Your activity photo has been saved to the gallery!'),
        actions: [
          CupertinoDialogAction(
            child: const Text('Continue'),
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop(null);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _saveWithOverlay() async {
    if (!mounted) return;
    
    setState(() => _isCapturing = true);

    try {
      await Future.delayed(const Duration(milliseconds: 100));
      
      if (!mounted) return;
      
      final RenderRepaintBoundary? boundary = _captureKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null || !mounted) {
        _navigateBack();
        return;
      }

      final ui.Image image = await boundary.toImage(pixelRatio: 2.0);
      if (!mounted) return;
      
      final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null || !mounted) {
        _navigateBack();
        return;
      }

      final Uint8List pngBytes = byteData.buffer.asUint8List();
      if (!mounted) return;

      final Directory directory = await getApplicationDocumentsDirectory();
      final String fileName = 'activity_photo_${DateTime.now().millisecondsSinceEpoch}.png';
      final File file = File('${directory.path}/$fileName');
      await file.writeAsBytes(pngBytes);
      
      if (!mounted) return;

      try {
        await Gal.putImage(file.path);
      } catch (_) {}

      _navigateBack();
    } catch (e) {
      if (mounted) {
        _navigateBack();
      }
    }
  }

  void _navigateBack() {
    if (mounted) {
      Navigator.of(context).pop('saved');
    }
  }

  Future<void> _savePhoto() async {
    if (_imageFile == null) return;

    final directory = await getApplicationDocumentsDirectory();
    final fileName =
        'activity_photo_${DateTime.now().millisecondsSinceEpoch}.jpg';
    await _imageFile!.copy('${directory.path}/$fileName');

    if (mounted) {
      Navigator.of(context).pop('saved');
    }
  }
}

class _RoutePolylinePainter extends CustomPainter {
  final List<LatLng> points;
  final Color color;

  _RoutePolylinePainter({
    required this.points,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    double minLat = double.infinity;
    double maxLat = double.negativeInfinity;
    double minLng = double.infinity;
    double maxLng = double.negativeInfinity;

    for (var point in points) {
      minLat = point.latitude < minLat ? point.latitude : minLat;
      maxLat = point.latitude > maxLat ? point.latitude : maxLat;
      minLng = point.longitude < minLng ? point.longitude : minLng;
      maxLng = point.longitude > maxLng ? point.longitude : maxLng;
    }

    final latPadding = (maxLat - minLat) * 0.1;
    final lngPadding = (maxLng - minLng) * 0.1;
    minLat -= latPadding;
    maxLat += latPadding;
    minLng -= lngPadding;
    maxLng += lngPadding;

    if (maxLat == minLat) {
      maxLat += 0.001;
      minLat -= 0.001;
    }
    if (maxLng == minLng) {
      maxLng += 0.001;
      minLng -= 0.001;
    }

    final latRange = maxLat - minLat;
    final lngRange = maxLng - minLng;
    
    if (latRange == 0 || latRange.isNaN || latRange.isInfinite ||
        lngRange == 0 || lngRange.isNaN || lngRange.isInfinite) {
      return;
    }
    
    final normalizedPoints = points.map((point) {
      final x = (point.longitude - minLng) / lngRange * size.width;
      final y = (size.height - (point.latitude - minLat) / latRange * size.height);
      return Offset(x, y);
    }).toList();

    if (normalizedPoints.length > 1) {
      final paint = Paint()
        ..color = color
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;

      final path = ui.Path();
      path.moveTo(normalizedPoints[0].dx, normalizedPoints[0].dy);

      for (int i = 1; i < normalizedPoints.length; i++) {
        path.lineTo(normalizedPoints[i].dx, normalizedPoints[i].dy);
      }

      canvas.drawPath(path, paint);
    }

    if (normalizedPoints.isNotEmpty) {
      final startPaint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;

      canvas.drawCircle(normalizedPoints.first, 6, startPaint);
    }

    if (normalizedPoints.length > 1) {
      final endPaint = Paint()
        ..color = CupertinoColors.systemOrange
        ..style = PaintingStyle.fill;

      canvas.drawCircle(normalizedPoints.last, 6, endPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _RoutePolylinePainter oldDelegate) {
    return oldDelegate.points != points || oldDelegate.color != color;
  }
}

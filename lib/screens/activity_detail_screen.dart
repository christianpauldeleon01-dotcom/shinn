import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import '../models/activity_model.dart';
import '../services/activity_service.dart';
import '../utils/app_utils.dart';
import '../theme/trak_design_system.dart';

/// Activity Detail Screen - Full route map and stats
class ActivityDetailScreen extends StatefulWidget {
  final String activityId;

  const ActivityDetailScreen({super.key, required this.activityId});

  @override
  State<ActivityDetailScreen> createState() => _ActivityDetailScreenState();
}

class _ActivityDetailScreenState extends State<ActivityDetailScreen> {
  final ActivityService _activityService = ActivityService();
  Activity? _activity;

  @override
  void initState() {
    super.initState();
    _loadActivity();
    themeChangeNotifier.addListener(_onThemeChange);
  }

  void _onThemeChange() {
    if (mounted) setState(() {});
  }

  void _loadActivity() {
    setState(() {
      _activity = _activityService.getActivity(widget.activityId);
    });
  }

  @override
  void dispose() {
    themeChangeNotifier.removeListener(_onThemeChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_activity == null) {
      return const CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(
          middle: Text('Activity'),
        ),
        child: Center(
          child: Text('Activity not found'),
        ),
      );
    }

    final routePoints = _activity!.routeCoordinates
        .map((c) => LatLng(c.latitude, c.longitude))
        .toList();

    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemGroupedBackground,
      navigationBar: CupertinoNavigationBar(
        middle: Text(_activity!.activityTypeString),
        backgroundColor: CupertinoColors.systemBackground,
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _showDeleteConfirmation,
          child: const Icon(
            CupertinoIcons.trash,
            color: CupertinoColors.systemRed,
          ),
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Map
              SizedBox(
                height: 300,
                child: _buildMap(routePoints),
              ),

              // Activity Info
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Date and Type
                    _buildHeader(),
                    const SizedBox(height: 24),

                    // Main Stats
                    _buildMainStats(),
                    const SizedBox(height: 24),

                    // Detailed Stats
                    _buildDetailedStats(),
                    const SizedBox(height: 24),

                    // Photo (if available)
                    if (_activity!.photoPath != null) ...[
                      _buildPhotoSection(),
                      const SizedBox(height: 24),
                    ],

                    // Route Info
                    _buildRouteInfo(routePoints.length),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMap(List<LatLng> routePoints) {
    if (routePoints.isEmpty) {
      return Container(
        color: CupertinoColors.systemGrey5.resolveFrom(context),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                CupertinoIcons.map,
                size: 48,
                color: CupertinoColors.secondaryLabel.resolveFrom(context),
              ),
              const SizedBox(height: 8),
              Text(
                'No route data',
                style: TextStyle(
                  color: CupertinoColors.secondaryLabel.resolveFrom(context),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Calculate bounds
    final bounds = LatLngBounds.fromPoints(routePoints);

    return FlutterMap(
      options: MapOptions(
        initialCenter: bounds.center,
        initialZoom: 15,
        minZoom: 3,
        maxZoom: 19,
        initialCameraFit: CameraFit.bounds(
          bounds: bounds,
          padding: const EdgeInsets.all(50),
        ),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
          userAgentPackageName: 'com.example.trak',
          maxZoom: 19,
        ),
        // Route polyline
        PolylineLayer(
          polylines: [
            Polyline(
              points: routePoints,
              strokeWidth: 5,
              color: CupertinoColors.activeOrange,
            ),
          ],
        ),
        // Start marker
        if (routePoints.isNotEmpty)
          MarkerLayer(
            markers: [
              Marker(
                point: routePoints.first,
                width: 40,
                height: 40,
                child: Container(
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemGreen,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: CupertinoColors.white,
                      width: 3,
                    ),
                  ),
                  child: const Icon(
                    CupertinoIcons.play_fill,
                    color: CupertinoColors.white,
                    size: 16,
                  ),
                ),
              ),
              // End marker
              if (routePoints.length > 1)
                Marker(
                  point: routePoints.last,
                  width: 40,
                  height: 40,
                  child: Container(
                    decoration: BoxDecoration(
                      color: CupertinoColors.systemRed,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: CupertinoColors.white,
                        width: 3,
                      ),
                    ),
                    child: const Icon(
                      CupertinoIcons.stop_fill,
                      color: CupertinoColors.white,
                      size: 16,
                    ),
                  ),
                ),
            ],
          ),
      ],
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppUtils.formatActivityDate(_activity!.date),
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              AppUtils.formatTime(_activity!.date),
              style: TextStyle(
                fontSize: 16,
                color: CupertinoColors.secondaryLabel.resolveFrom(context),
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: CupertinoColors.systemOrange.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            _activity!.activityTypeString,
            style: const TextStyle(
              color: CupertinoColors.systemOrange,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMainStats() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground.resolveFrom(context),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildMainStatItem(
            value: _activity!.distanceKm.toStringAsFixed(2),
            unit: 'km',
            label: 'Distance',
          ),
          Container(
            width: 1,
            height: 60,
            color: CupertinoColors.separator.resolveFrom(context),
          ),
          _buildMainStatItem(
            value: _activity!.formattedDuration,
            unit: '',
            label: 'Duration',
          ),
          Container(
            width: 1,
            height: 60,
            color: CupertinoColors.separator.resolveFrom(context),
          ),
          _buildMainStatItem(
            value: _activity!.formattedPace,
            unit: '/km',
            label: 'Pace',
          ),
        ],
      ),
    );
  }

  Widget _buildMainStatItem({
    required String value,
    required String unit,
    required String label,
  }) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (unit.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  unit,
                  style: TextStyle(
                    fontSize: 14,
                    color: CupertinoColors.secondaryLabel.resolveFrom(context),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: CupertinoColors.secondaryLabel.resolveFrom(context),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailedStats() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Details',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: CupertinoColors.systemBackground.resolveFrom(context),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              _buildDetailRow(
                icon: CupertinoIcons.speedometer,
                label: 'Avg Speed',
                value: '${AppUtils.formatSpeedKmh(_activity!.averageSpeedMps ?? 0)} km/h',
              ),
              _buildDivider(),
              _buildDetailRow(
                icon: CupertinoIcons.flame,
                label: 'Est. Calories',
                value: '${_activity!.caloriesBurned?.toStringAsFixed(0) ?? '--'} kcal',
              ),
              _buildDivider(),
              _buildDetailRow(
                icon: CupertinoIcons.location,
                label: 'Route Points',
                value: '${_activity!.routeCoordinates.length}',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(
            icon,
            color: CupertinoColors.secondaryLabel.resolveFrom(context),
            size: 20,
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              color: CupertinoColors.secondaryLabel.resolveFrom(context),
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      margin: const EdgeInsets.only(left: 48),
      height: 1,
      color: CupertinoColors.separator.resolveFrom(context),
    );
  }

  Widget _buildPhotoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Photo',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.file(
            File(_activity!.photoPath!),
            width: double.infinity,
            height: 200,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                height: 200,
                color: CupertinoColors.systemGrey5.resolveFrom(context),
                child: const Center(
                  child: Icon(
                    CupertinoIcons.photo,
                    size: 48,
                    color: CupertinoColors.systemGrey,
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        // Save to Gallery button
        SizedBox(
          width: double.infinity,
          child: CupertinoButton(
            padding: const EdgeInsets.symmetric(vertical: 12),
            color: CupertinoColors.systemBlue,
            onPressed: _savePhotoToGallery,
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  CupertinoIcons.photo,
                  color: CupertinoColors.white,
                  size: 20,
                ),
                SizedBox(width: 8),
                Text(
                  'Save to Gallery',
                  style: TextStyle(
                    color: CupertinoColors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _savePhotoToGallery() async {
    if (_activity?.photoPath == null) return;
    
    try {
      final sourceFile = File(_activity!.photoPath!);
      
      final tempDir = await getTemporaryDirectory();
      final fileName = 'activity_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final tempPath = '${tempDir.path}/$fileName';
      await sourceFile.copy(tempPath);
      
      await Gal.putImage(tempPath);
      
      final tempFile = File(tempPath);
      if (await tempFile.exists()) {
        await tempFile.delete();
      }
      
      if (mounted) {
        _showSuccessMessage('Photo saved to gallery');
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('Error saving photo: $e');
      }
    }
  }

  void _showSuccessMessage(String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Success'),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _buildRouteInfo(int pointCount) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.systemBlue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(
            CupertinoIcons.info_circle,
            color: CupertinoColors.systemBlue,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'This activity recorded $pointCount GPS points during your $_activity!.activityTypeString.',
              style: const TextStyle(
                color: CupertinoColors.systemBlue,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Delete Activity?'),
        content: const Text(
          'This action cannot be undone. Are you sure you want to delete this activity?',
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () async {
              Navigator.of(context).pop();
              await _activityService.deleteActivity(widget.activityId);
              if (mounted) {
                // Pass back true to indicate deletion so previous screen can refresh
                Navigator.of(context).pop(true);
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

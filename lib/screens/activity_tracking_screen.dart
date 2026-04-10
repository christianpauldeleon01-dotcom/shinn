import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Colors;
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../services/gps_service.dart';
import '../services/enhanced_tracking_service.dart';
import '../utils/app_utils.dart';
import '../theme/trak_design_system.dart';
import 'activity_photo_screen.dart';

/// Map style enum for switching between map types
enum MapStyle { satellite, street, terrain }

/// Activity Tracking Screen - Live tracking with neon styling
class ActivityTrackingScreen extends StatefulWidget {
  const ActivityTrackingScreen({super.key});

  @override
  State<ActivityTrackingScreen> createState() =>
      _ActivityTrackingScreenState();
}

class _ActivityTrackingScreenState extends State<ActivityTrackingScreen> {
  final EnhancedTrackingService _trackingService = EnhancedTrackingService();
  final GPSService _gpsService = GPSService();
  final MapController _mapController = MapController();

  ActivityState _state = ActivityState.idle;
  String _duration = '00:00';
  double _distance = 0.0;
  String _averagePace = '--:--';
  String _instantPace = '--:--';
  List<LatLng> _routePoints = [];
  LatLng? _currentPosition;
  bool _isLoading = true;
  String? _errorMessage;
  
  bool _isAutoPaused = false;
  double _gpsAccuracy = 0;
  double _currentSpeed = 0;
  int _currentSplit = 0;
  MapStyle _currentMapStyle = MapStyle.satellite;

  StreamSubscription? _durationSubscription;
  StreamSubscription? _coordinateSubscription;
  StreamSubscription? _stateSubscription;
  StreamSubscription? _autoPauseSubscription;
  StreamSubscription? _instantPaceSubscription;
  StreamSubscription? _splitSubscription;

  @override
  void initState() {
    super.initState();
    _initGPS();
    themeChangeNotifier.addListener(_onThemeChange);
  }

  void _onThemeChange() {
    if (mounted) setState(() {});
  }

  Future<void> _initGPS() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final permission = await _gpsService.checkPermission();

    if (permission == LocationPermission.denied) {
      final newPermission = await _gpsService.requestPermission();
      if (newPermission == LocationPermission.denied ||
          newPermission == LocationPermission.deniedForever) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Location permission denied. Please enable in settings.';
        });
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Location permission permanently denied. Please enable in app settings.';
      });
      return;
    }

    final serviceEnabled = await _gpsService.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Location services are disabled. Please enable them.';
      });
      return;
    }

    final position = await _gpsService.getCurrentPosition();
    if (position != null) {
      _currentPosition = LatLng(position.latitude, position.longitude);
      _gpsAccuracy = position.accuracy;
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } else {
      final lastKnown = await GPSService.getLastKnownPosition();
      if (lastKnown != null) {
        _currentPosition = LatLng(lastKnown.latitude, lastKnown.longitude);
      }
      setState(() {
        _isLoading = false;
      });
    }

    _stateSubscription = _trackingService.stateStream.listen((state) {
      if (mounted) {
        setState(() {
          _state = state;
        });
      }
    });

    _durationSubscription = _trackingService.durationStream.listen((seconds) {
      if (mounted) {
        setState(() {
          _duration = AppUtils.formatDuration(seconds);
          _distance = _trackingService.currentDistanceKm;
          _averagePace = _trackingService.formattedCurrentPace;
          _instantPace = _trackingService.formattedInstantPace;
          _currentSpeed = _trackingService.currentSpeed;
          _routePoints = GPSService.coordinatesToLatLng(
            _trackingService.filteredCoordinates,
            movingOnly: false,
          );
          _currentSplit = _trackingService.splits.length;
        });
      }
    });

    _autoPauseSubscription = _trackingService.autoPauseStream.listen((isPaused) {
      if (mounted) {
        setState(() {
          _isAutoPaused = isPaused;
        });
      }
    });

    _instantPaceSubscription = _trackingService.instantPaceStream.listen((pace) {
      if (mounted) {
        setState(() {
          _instantPace = _formatPace(pace);
        });
      }
    });

    _splitSubscription = _trackingService.splitStream.listen((split) {
      // Handle split events
    });

    _gpsService.coordinateStream.listen((coord) async {
      if (mounted && _state == ActivityState.running) {
        final position = await _gpsService.getCurrentPosition();
        if (position != null && mounted) {
          setState(() {
            _currentPosition = LatLng(position.latitude, position.longitude);
            _gpsAccuracy = position.accuracy;
            _routePoints = GPSService.coordinatesToLatLng(
            _trackingService.filteredCoordinates,
            movingOnly: false,
          );
            _distance = _trackingService.currentDistanceKm;
            _averagePace = _trackingService.formattedCurrentPace;
            _instantPace = _trackingService.formattedInstantPace;
            _currentSpeed = _trackingService.currentSpeed;
          });
          if (_currentPosition != null) {
            _mapController.move(_currentPosition!, 16);
          }
        }
      }
    });
  }

  String _formatPace(double paceSecondsPerKm) {
    if (paceSecondsPerKm <= 0 || paceSecondsPerKm.isInfinite || paceSecondsPerKm.isNaN) {
      return '--:--';
    }
    if (paceSecondsPerKm > 3600) {
      return '--:--';
    }
    final minutes = (paceSecondsPerKm / 60).floor();
    final seconds = (paceSecondsPerKm % 60).round();
    if (seconds >= 60) {
      return '${minutes + 1}:00';
    }
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _durationSubscription?.cancel();
    _coordinateSubscription?.cancel();
    _stateSubscription?.cancel();
    _autoPauseSubscription?.cancel();
    _instantPaceSubscription?.cancel();
    _splitSubscription?.cancel();
    themeChangeNotifier.removeListener(_onThemeChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: NeonColors.background,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: NeonColors.backgroundSecondary.withValues(alpha: 0.95),
        border: null,
        middle: Text(
          _getTitle(),
          style: NeonTypography.headlineSmall.copyWith(
            color: NeonColors.textPrimary,
          ),
        ),
        leading: _state == ActivityState.idle
            ? CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(
                  'Cancel',
                  style: NeonTypography.bodyLarge.copyWith(
                    color: NeonColors.primary,
                  ),
                ),
              )
            : null,
        trailing: _state != ActivityState.idle
            ? CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: _showStopConfirmation,
                child: Text(
                  'End',
                  style: NeonTypography.bodyLarge.copyWith(
                    color: NeonColors.error,
                  ),
                ),
              )
            : null,
      ),
      child: SafeArea(
        child: _isLoading
            ? const Center(child: CupertinoActivityIndicator())
            : _errorMessage != null
                ? _buildErrorView()
                : _buildContent(),
      ),
    );
  }

  String _getTitle() {
    switch (_state) {
      case ActivityState.idle:
        return 'Ready';
      case ActivityState.running:
        return 'Running';
      case ActivityState.paused:
        return 'Paused';
      case ActivityState.finished:
        return 'Summary';
    }
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: NeonColors.surface,
                shape: BoxShape.circle,
                border: Border.all(color: NeonColors.border, width: 1),
              ),
              child: Icon(
                CupertinoIcons.location_slash,
                size: 48,
                color: NeonColors.textTertiary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: NeonTypography.bodyLarge.copyWith(
                color: NeonColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            NeonButton(
              label: 'Try Again',
              onPressed: () async {
                if (_errorMessage!.contains('settings')) {
                  await _gpsService.openAppSettings();
                }
                _initGPS();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      children: [
        // Map
        Expanded(
          flex: 3,
          child: _buildMap(),
        ),

        // Stats Panel
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                NeonColors.surfaceElevated,
                NeonColors.surface,
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(24),
            ),
            border: Border(
              top: BorderSide(color: NeonColors.border.withValues(alpha: 0.5), width: 1),
            ),
            boxShadow: [
              BoxShadow(
                color: NeonColors.primary.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Column(
            children: [
              // Auto-pause indicator
              if (_isAutoPaused) _buildAutoPauseIndicator(),
              
              // Stats Row
              _buildStatsRow(),
              const SizedBox(height: 16),
              
              // Secondary stats
              _buildSecondaryStatsRow(),
              const SizedBox(height: 20),

              // Control Buttons
              _buildControls(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMap() {
    final textOnGradient = NeonColors.textOnPrimaryGradient;
    
    if (_currentPosition == null) {
      return Container(
        color: NeonColors.background,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CupertinoActivityIndicator(color: NeonColors.primary),
              const SizedBox(height: 16),
              Text(
                'Loading map...',
                style: NeonTypography.bodyMedium.copyWith(
                  color: NeonColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _currentPosition!,
            initialZoom: 16,
            minZoom: 3,
            maxZoom: 19,
          ),
          children: [
            TileLayer(
              urlTemplate: _getTileUrl(MapStyle.street),
              userAgentPackageName: 'com.trak.app',
              maxZoom: 19,
              tileBuilder: (context, widget, tile) {
                return ColorFiltered(
                  colorFilter: const ColorFilter.matrix(<double>[
                    0.2126, 0.7152, 0.0722, 0, 0,
                    0.2126, 0.7152, 0.0722, 0, 0,
                    0.2126, 0.7152, 0.0722, 0, 0,
                    0, 0, 0, 1, 0,
                  ]),
                  child: widget,
                );
              },
            ),
            if (_routePoints.isNotEmpty)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: _routePoints,
                    strokeWidth: 8,
                    color: NeonColors.secondary,
                  ),
                  Polyline(
                    points: _routePoints,
                    strokeWidth: 4,
                    color: NeonColors.primary,
                  ),
                ],
              ),
            MarkerLayer(
              markers: [
                if (_currentPosition != null)
                  Marker(
                    point: _currentPosition!,
                    width: 50,
                    height: 50,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: NeonColors.primary.withValues(alpha: 0.6),
                                blurRadius: 20,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: NeonColors.primary,
                            shape: BoxShape.circle,
                            border: Border.all(color: NeonColors.background, width: 2),
                          ),
                          child: Icon(
                            CupertinoIcons.location_fill,
                            color: textOnGradient,
                            size: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
        
        // Neon glow overlay at bottom
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          height: 120,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  NeonColors.background.withValues(alpha: 0),
                  NeonColors.background.withValues(alpha: 0.8),
                ],
              ),
            ),
          ),
        ),
        
        // Top right controls - neon styled
        Positioned(
          top: 16,
          right: 16,
          child: Container(
            decoration: BoxDecoration(
              color: NeonColors.background.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: NeonColors.primary.withValues(alpha: 0.3)),
              boxShadow: [
                BoxShadow(
                  color: NeonColors.primary.withValues(alpha: 0.2),
                  blurRadius: 12,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Column(
              children: [
                _buildNeonButton(
                  icon: CupertinoIcons.plus,
                  onTap: () {
                    final zoom = _mapController.camera.zoom + 1;
                    _mapController.move(_mapController.camera.center, zoom.clamp(3.0, 19.0));
                  },
                ),
                Container(height: 1, width: 32, color: NeonColors.primary.withValues(alpha: 0.2)),
                _buildNeonButton(
                  icon: CupertinoIcons.minus,
                  onTap: () {
                    final zoom = _mapController.camera.zoom - 1;
                    _mapController.move(_mapController.camera.center, zoom.clamp(3.0, 19.0));
                  },
                ),
                Container(height: 1, width: 32, color: NeonColors.primary.withValues(alpha: 0.2)),
                _buildNeonButton(
                  icon: CupertinoIcons.location,
                  onTap: () {
                    if (_currentPosition != null) {
                      _mapController.move(_currentPosition!, 16);
                    }
                  },
                ),
              ],
            ),
          ),
        ),
        
        // Map style selector - bottom left
        Positioned(
          bottom: 140,
          left: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: NeonColors.background.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: NeonColors.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildStyleChip(MapStyle.satellite, 'Sat'),
                const SizedBox(width: 8),
                _buildStyleChip(MapStyle.street, 'Map'),
                const SizedBox(width: 8),
                _buildStyleChip(MapStyle.terrain, 'Ter'),
              ],
            ),
          ),
        ),
        
        // Route info badge - bottom right
        if (_routePoints.isNotEmpty)
          Positioned(
            bottom: 140,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: NeonColors.primary,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: NeonColors.primary.withValues(alpha: 0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(CupertinoIcons.map, color: textOnGradient, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    '${_distance.toStringAsFixed(2)} km',
                    style: NeonTypography.labelMedium.copyWith(
                      color: textOnGradient,
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

  Widget _buildNeonButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        child: Icon(
          icon,
          color: NeonColors.primary,
          size: 20,
        ),
      ),
    );
  }

  Widget _buildStyleChip(MapStyle style, String label) {
    final isSelected = _currentMapStyle == style;
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentMapStyle = style;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? NeonColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: NeonTypography.labelSmall.copyWith(
            color: isSelected ? NeonColors.background : NeonColors.textSecondary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  String _getTileUrl(MapStyle style) {
    switch (style) {
      case MapStyle.satellite:
        return 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}';
      case MapStyle.street:
        return 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png';
      case MapStyle.terrain:
        return 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png';
    }
  }

  Widget _buildAutoPauseIndicator() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: NeonAnimations.normal,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: child,
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: NeonColors.warning.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: NeonColors.warning.withValues(alpha: 0.5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              CupertinoIcons.pause_fill,
              color: NeonColors.warning,
              size: 16,
            ),
            const SizedBox(width: 8),
            Text(
              'Auto-paused',
              style: NeonTypography.labelMedium.copyWith(
                color: NeonColors.warning,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildStatItem(
          label: 'Duration',
          value: _duration,
          icon: CupertinoIcons.timer,
          iconColor: NeonColors.iconOnSurface,
        ),
        Container(
          width: 1,
          height: 50,
          color: NeonColors.border,
        ),
        _buildStatItem(
          label: 'Distance',
          value: '${_distance.toStringAsFixed(2)} km',
          icon: CupertinoIcons.map,
          iconColor: currentThemeMode == TrakThemeMode.dark 
              ? const Color(0xFF000000) 
              : const Color(0xFFFFFFFF),
        ),
        Container(
          width: 1,
          height: 50,
          color: NeonColors.border,
        ),
        _buildStatItem(
          label: 'Avg Pace',
          value: '$_averagePace /km',
          icon: CupertinoIcons.speedometer,
          iconColor: NeonColors.iconOnSurface,
        ),
      ],
    );
  }

  Widget _buildSecondaryStatsRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildSecondaryStatItem(
          label: 'Current Pace',
          value: '$_instantPace /km',
        ),
        _buildSecondaryStatItem(
          label: 'Speed',
          value: '${(_currentSpeed * 3.6).toStringAsFixed(1)} km/h',
        ),
        _buildSecondaryStatItem(
          label: 'Split',
          value: _currentSplit > 0 ? '$_currentSplit km' : '--',
        ),
      ],
    );
  }

  Widget _buildSecondaryStatItem({
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Text(
          value,
          style: NeonTypography.titleLarge.copyWith(
            color: NeonColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: NeonTypography.labelSmall.copyWith(
            color: NeonColors.textTertiary,
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem({
    required String label,
    required String value,
    required IconData icon,
    required Color iconColor,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          color: iconColor,
          size: 22,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: NeonTypography.headlineSmall.copyWith(
            color: NeonColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: NeonTypography.labelSmall.copyWith(
            color: NeonColors.textTertiary,
          ),
        ),
      ],
    );
  }

  Widget _buildControls() {
    final textOnGradient = NeonColors.textOnPrimaryGradient;
    
    switch (_state) {
      case ActivityState.idle:
        return _buildIdleControls(textOnGradient);
      case ActivityState.running:
        return _buildRunningControls(textOnGradient);
      case ActivityState.paused:
        return _buildPausedControls(textOnGradient);
      case ActivityState.finished:
        return _buildStoppedControls();
    }
  }

  Widget _buildIdleControls(Color textOnGradient) {
    return Center(
      child: GestureDetector(
        onTap: _startActivity,
        child: Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            gradient: NeonColors.primaryGradient,
            shape: BoxShape.circle,
            boxShadow: NeonShadows.neon(NeonColors.primary),
          ),
          child: Center(
            child: Icon(
              CupertinoIcons.play_fill,
              color: textOnGradient,
              size: 40,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRunningControls(Color textOnGradient) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Lock button
        GestureDetector(
          onTap: () {},
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: NeonColors.surface,
              shape: BoxShape.circle,
              border: Border.all(color: NeonColors.border, width: 1),
            ),
            child: Icon(
              CupertinoIcons.lock,
              color: NeonColors.textSecondary,
              size: 24,
            ),
          ),
        ),
        
        // Pause button
        GestureDetector(
          onTap: _pauseActivity,
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: NeonColors.accentGradient,
              shape: BoxShape.circle,
              boxShadow: NeonShadows.neon(NeonColors.accent),
            ),
            child: Icon(
              CupertinoIcons.pause_fill,
              color: textOnGradient,
              size: 36,
            ),
          ),
        ),
        
        // Media button
        GestureDetector(
          onTap: () => _openMediaCapture(),
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: NeonColors.surface,
              shape: BoxShape.circle,
              border: Border.all(color: NeonColors.border, width: 1),
            ),
            child: Icon(
              CupertinoIcons.camera,
              color: NeonColors.textSecondary,
              size: 24,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPausedControls(Color textOnGradient) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Stop button
        GestureDetector(
          onTap: _stopActivity,
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: NeonColors.surface,
              shape: BoxShape.circle,
              border: Border.all(color: NeonColors.error, width: 2),
            ),
            child: Icon(
              CupertinoIcons.stop_fill,
              color: NeonColors.error,
              size: 32,
            ),
          ),
        ),
        
        // Resume button
        GestureDetector(
          onTap: _resumeActivity,
          child: Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              gradient: NeonColors.primaryGradient,
              shape: BoxShape.circle,
              boxShadow: NeonShadows.neon(NeonColors.primary),
            ),
            child: Icon(
              CupertinoIcons.play_fill,
              color: textOnGradient,
              size: 40,
            ),
          ),
        ),
        
        // Lock button
        GestureDetector(
          onTap: () {},
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: NeonColors.surface,
              shape: BoxShape.circle,
              border: Border.all(color: NeonColors.border, width: 1),
            ),
            child: Icon(
              CupertinoIcons.lock_open,
              color: NeonColors.textSecondary,
              size: 28,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStoppedControls() {
    return NeonButton(
      label: 'Save Activity',
      onPressed: _saveActivity,
    );
  }

  void _startActivity() {
    HapticFeedback.heavyImpact();
    _trackingService.startActivity();
  }

  void _pauseActivity() {
    HapticFeedback.mediumImpact();
    _trackingService.pauseActivity();
  }

  void _resumeActivity() {
    HapticFeedback.heavyImpact();
    _trackingService.resumeActivity();
  }

  void _stopActivity() {
    _trackingService.stopActivity();
  }

  void _saveActivity() {
    // Save the activity
  }

  void _showStopConfirmation() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('End Activity?'),
        content: const Text('Are you sure you want to end this activity?'),
        actions: [
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.pop(context);
              _stopActivity();
            },
            child: const Text('End'),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.pop(context),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  void _openMediaCapture() {
    _trackingService.pauseActivity();
    Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (context) => ActivityPhotoScreen(
          distance: _distance,
          duration: _duration,
          pace: _averagePace,
        ),
      ),
    ).then((result) {
      if (!mounted) return;
      
      if (result != null) {
        _trackingService.discardActivity();
      } else {
        _trackingService.resumeActivity();
      }
      if (mounted) {
        setState(() {
          _duration = '00:00';
          _distance = 0.0;
          _averagePace = '--:--';
          _instantPace = '--:--';
          _routePoints = [];
          _currentSpeed = 0;
          _currentSplit = 0;
        });
      }
    });
  }
}

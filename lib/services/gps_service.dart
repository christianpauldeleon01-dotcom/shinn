import 'dart:async';
import 'dart:math';
import 'package:geolocator/geolocator.dart' hide ActivityType;
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';
import '../models/activity_model.dart';

/// Service for handling GPS location tracking
class GPSService {
  static final GPSService _instance = GPSService._internal();
  factory GPSService() => _instance;
  GPSService._internal();

  /// Speed threshold for determining if user is moving (m/s)
  /// Strava uses 0.5 m/s (~1.8 km/h) as the cutoff
  static const double movingSpeedThreshold = 0.5;

  /// Auto-pause speed threshold (lower than moving threshold)
  /// Used to detect when user has stopped moving
  static const double autoPauseSpeedThreshold = 0.3;

  StreamSubscription<Position>? _positionStreamSubscription;
  final StreamController<Coordinate> _coordinateController =
      StreamController<Coordinate>.broadcast();
  final StreamController<bool> _trackingStateController =
      StreamController<bool>.broadcast();
  final StreamController<LocationAccuracy> _accuracyController =
      StreamController<LocationAccuracy>.broadcast();

  bool _isTracking = false;
  bool get isTracking => _isTracking;

  /// Current accuracy level
  final LocationAccuracy _currentAccuracy = LocationAccuracy.high;
  LocationAccuracy get currentAccuracy => _currentAccuracy;

  /// Stream of coordinates during tracking
  Stream<Coordinate> get coordinateStream => _coordinateController.stream;

  /// Stream of tracking state changes
  Stream<bool> get trackingStateStream => _trackingStateController.stream;

  /// Stream of accuracy changes
  Stream<LocationAccuracy> get accuracyStream => _accuracyController.stream;

  /// Check if location services are enabled
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// Request location permission
  Future<LocationPermission> requestPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    
    return permission;
  }

  /// Check current permission status
  Future<LocationPermission> checkPermission() async {
    return await Geolocator.checkPermission();
  }

  /// Get current position
  Future<Position?> getCurrentPosition() async {
    try {
      // Check if location services are enabled
      final serviceEnabled = await isLocationServiceEnabled();
      if (!serviceEnabled) {
        return null;
      }

      // Check permission
      LocationPermission permission = await checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await requestPermission();
        if (permission == LocationPermission.denied) {
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return null;
      }

      // Get current position
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 5, // Minimum distance in meters before update
        ),
      );
    } catch (e) {
      return null;
    }
  }

  /// Start tracking location
  Future<bool> startTracking() async {
    if (_isTracking) return true;

    try {
      // Check location services
      final serviceEnabled = await isLocationServiceEnabled();
      if (!serviceEnabled) {
        return false;
      }

      // Check/Request permission
      LocationPermission permission = await checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await requestPermission();
        if (permission == LocationPermission.denied) {
          return false;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return false;
      }

      // Configure location settings
      const locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5, // Update every 5 meters
      );

      // Start listening to position stream
      _positionStreamSubscription = Geolocator.getPositionStream(
        locationSettings: locationSettings,
      ).listen(
        (Position position) {
          // Convert to Coordinate and emit
          final coordinate = Coordinate(
            latitude: position.latitude,
            longitude: position.longitude,
            timestamp: position.timestamp ?? DateTime.now(),
            altitude: position.altitude,
            speed: position.speed,
          );
          _coordinateController.add(coordinate);
        },
        onError: (error) {
          // Handle error silently
        },
      );

      _isTracking = true;
      _trackingStateController.add(true);
      return true;
    } catch (e) {
      _isTracking = false;
      _trackingStateController.add(false);
      return false;
    }
  }

  /// Stop tracking location
  void stopTracking() {
    _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;
    _isTracking = false;
    _trackingStateController.add(false);
  }

  /// Calculate distance between two coordinates in meters
  static double calculateDistance(Coordinate from, Coordinate to) {
    return Geolocator.distanceBetween(
      from.latitude,
      from.longitude,
      to.latitude,
      to.longitude,
    );
  }

  /// Calculate distance between two LatLng points in meters
  static double calculateLatLngDistance(LatLng from, LatLng to) {
    return Geolocator.distanceBetween(
      from.latitude,
      from.longitude,
      to.latitude,
      to.longitude,
    );
  }

  /// Calculate total distance of a route in meters
  static double calculateTotalDistance(List<Coordinate> coordinates) {
    if (coordinates.length < 2) return 0.0;

    double totalDistance = 0.0;
    for (int i = 1; i < coordinates.length; i++) {
      totalDistance += calculateDistance(coordinates[i - 1], coordinates[i]);
    }
    return totalDistance;
  }

  /// Calculate average speed in meters per second
  static double calculateAverageSpeed(List<Coordinate> coordinates) {
    if (coordinates.length < 2) return 0.0;

    final totalDistance = calculateTotalDistance(coordinates);
    final startTime = coordinates.first.timestamp;
    final endTime = coordinates.last.timestamp;
    final duration = endTime.difference(startTime).inSeconds;

    if (duration == 0) return 0.0;
    return totalDistance / duration;
  }

  /// Calculate pace in seconds per kilometer (Strava-style)
  /// Uses total time and total distance
  static double calculatePace(List<Coordinate> coordinates) {
    if (coordinates.length < 2) return 0.0;

    final totalDistance = calculateTotalDistance(coordinates);
    if (totalDistance == 0) return 0.0;

    final startTime = coordinates.first.timestamp;
    final endTime = coordinates.last.timestamp;
    final durationSeconds = endTime.difference(startTime).inSeconds;

    // Check for zero duration
    if (durationSeconds == 0) return 0.0;

    // Convert to km
    final distanceKm = totalDistance / 1000;
    if (distanceKm == 0) return 0.0;

    // Pace = Total Time ÷ Total Distance (Strava-style)
    return durationSeconds / distanceKm;
  }

  /// Calculate speed between two coordinates in m/s
  static double calculateSpeed(Coordinate from, Coordinate to) {
    final distance = calculateDistance(from, to);
    final timeDiff = to.timestamp.difference(from.timestamp).inSeconds;
    if (timeDiff == 0) return 0.0;
    return distance / timeDiff;
  }

  /// Calculate moving distance (only when speed >= threshold)
  /// Strava-style: only count distance when actually moving
  static double calculateMovingDistance(List<Coordinate> coordinates) {
    if (coordinates.length < 2) return 0.0;

    double movingDistance = 0.0;
    for (int i = 1; i < coordinates.length; i++) {
      final speed = calculateSpeed(coordinates[i - 1], coordinates[i]);
      // Only count distance when moving above threshold
      if (speed >= movingSpeedThreshold) {
        movingDistance += calculateDistance(coordinates[i - 1], coordinates[i]);
      }
    }
    return movingDistance;
  }

  /// Calculate moving time (only when speed >= threshold)
  /// Strava-style: only count time when actually moving
  static int calculateMovingTime(List<Coordinate> coordinates) {
    if (coordinates.length < 2) return 0;

    int movingTimeSeconds = 0;
    for (int i = 1; i < coordinates.length; i++) {
      final speed = calculateSpeed(coordinates[i - 1], coordinates[i]);
      final timeDiff = coordinates[i].timestamp
          .difference(coordinates[i - 1].timestamp)
          .inSeconds;
      // Only count time when moving above threshold
      if (speed >= movingSpeedThreshold) {
        movingTimeSeconds += timeDiff;
      }
    }
    return movingTimeSeconds;
  }

  /// Calculate pace based on moving time (Strava-style)
  /// Returns seconds per kilometer
  /// Falls back to total time/distance if moving values are 0
  static double calculateMovingPace(List<Coordinate> coordinates) {
    if (coordinates.length < 2) return 0.0;

    final movingDistance = calculateMovingDistance(coordinates);
    final movingTime = calculateMovingTime(coordinates);

    // If moving distance or time is 0, fall back to total time and distance
    if (movingDistance == 0 || movingTime == 0) {
      final totalDistance = calculateTotalDistance(coordinates);
      if (totalDistance < 50) return 0.0;

      final startTime = coordinates.first.timestamp;
      final endTime = coordinates.last.timestamp;
      final totalTime = endTime.difference(startTime).inSeconds;

      if (totalTime == 0) return 0.0;

      final distanceKm = totalDistance / 1000;
      return totalTime / distanceKm;
    }

    // For very small distances (< 50m), pace calculation can be unstable
    // Return 0 to indicate pace is not reliable
    if (movingDistance < 50) return 0.0;

    final distanceKm = movingDistance / 1000;
    return movingTime / distanceKm;
  }

  /// Calculate average speed in meters per second
  /// Falls back to total time/distance if moving values are 0
  static double calculateMovingAverageSpeed(List<Coordinate> coordinates) {
    if (coordinates.length < 2) return 0.0;

    final movingDistance = calculateMovingDistance(coordinates);
    final movingTime = calculateMovingTime(coordinates);

    // If moving distance or time is 0, fall back to total time and distance
    if (movingDistance == 0 || movingTime == 0) {
      final totalDistance = calculateTotalDistance(coordinates);
      if (totalDistance == 0) return 0.0;

      final startTime = coordinates.first.timestamp;
      final endTime = coordinates.last.timestamp;
      final totalTime = endTime.difference(startTime).inSeconds;

      if (totalTime == 0) return 0.0;

      return totalDistance / totalTime;
    }

    return movingDistance / movingTime;
  }

  /// Convert coordinates to LatLng list for map display
  /// Only includes coordinates where speed >= movingSpeedThreshold
  static List<LatLng> coordinatesToLatLng(List<Coordinate> coordinates, {bool movingOnly = true}) {
    return coordinates
        .where((coord) => 
            coord.latitude.isFinite && !coord.latitude.isNaN &&
            coord.longitude.isFinite && !coord.longitude.isNaN &&
            (!movingOnly || (coord.speed ?? 0) >= movingSpeedThreshold))
        .map((coord) => LatLng(coord.latitude, coord.longitude))
        .toList();
  }

  /// Get last known position quickly
  static Future<Position?> getLastKnownPosition() async {
    try {
      return await Geolocator.getLastKnownPosition();
    } catch (e) {
      return null;
    }
  }

  /// Open location settings
  Future<bool> openLocationSettings() async {
    return await Geolocator.openLocationSettings();
  }

  /// Open app settings (for permissions)
  Future<bool> openAppSettings() async {
    return await Geolocator.openAppSettings();
  }

  /// Estimate steps based on distance (rough estimate)
  /// Uses average stride length of ~0.75m for running
  static int estimateSteps(List<Coordinate> coordinates) {
    final distance = calculateTotalDistance(coordinates);
    if (distance <= 0) return 0;
    
    // Average stride length for running is about 0.75-1.5m
    // Using 0.75m as conservative estimate
    const strideLength = 0.75;
    
    return (distance / strideLength).round();
  }

  // ============ ENHANCED CALCULATIONS ============

  /// Calculate total elevation gain (sum of positive elevation changes)
  static double calculateElevationGain(List<Coordinate> coordinates) {
    if (coordinates.length < 2) return 0.0;
    
    double elevationGain = 0.0;
    for (int i = 1; i < coordinates.length; i++) {
      final prevAltitude = coordinates[i - 1].altitude;
      final currAltitude = coordinates[i].altitude;
      
      if (prevAltitude != null && currAltitude != null) {
        final diff = currAltitude - prevAltitude;
        if (diff > 0) {
          elevationGain += diff;
        }
      }
    }
    return elevationGain;
  }

  /// Calculate total elevation loss (sum of negative elevation changes)
  static double calculateElevationLoss(List<Coordinate> coordinates) {
    if (coordinates.length < 2) return 0.0;
    
    double elevationLoss = 0.0;
    for (int i = 1; i < coordinates.length; i++) {
      final prevAltitude = coordinates[i - 1].altitude;
      final currAltitude = coordinates[i].altitude;
      
      if (prevAltitude != null && currAltitude != null) {
        final diff = currAltitude - prevAltitude;
        if (diff < 0) {
          elevationLoss += diff.abs();
        }
      }
    }
    return elevationLoss;
  }

  /// Calculate maximum elevation
  static double? calculateMaxElevation(List<Coordinate> coordinates) {
    if (coordinates.isEmpty) return null;
    
    double? maxAlt;
    for (final coord in coordinates) {
      if (coord.altitude != null) {
        if (maxAlt == null || coord.altitude! > maxAlt) {
          maxAlt = coord.altitude;
        }
      }
    }
    return maxAlt;
  }

  /// Calculate minimum elevation
  static double? calculateMinElevation(List<Coordinate> coordinates) {
    if (coordinates.isEmpty) return null;
    
    double? minAlt;
    for (final coord in coordinates) {
      if (coord.altitude != null) {
        if (minAlt == null || coord.altitude! < minAlt) {
          minAlt = coord.altitude;
        }
      }
    }
    return minAlt;
  }

  /// Calculate grade (slope) between two points as percentage
  static double calculateGrade(Coordinate from, Coordinate to) {
    final distance = calculateDistance(from, to);
    if (distance == 0) return 0.0;
    
    final elevationDiff = (to.altitude ?? 0) - (from.altitude ?? 0);
    // Grade = (elevation change / horizontal distance) * 100
    return (elevationDiff / distance) * 100;
  }

  /// Calculate grade-adjusted pace (GAP) in seconds per km
  /// Uses rules of thumb: +1% grade slows pace by ~3-4%
  static double calculateGradeAdjustedPace(
    List<Coordinate> coordinates,
    double weightKg,
  ) {
    if (coordinates.length < 2) return 0.0;
    
    final totalDistance = calculateTotalDistance(coordinates);
    if (totalDistance == 0) return 0.0;
    
    final startTime = coordinates.first.timestamp;
    final endTime = coordinates.last.timestamp;
    final durationSeconds = endTime.difference(startTime).inSeconds;
    
    if (durationSeconds == 0) return 0.0;
    
    // Calculate average grade
    double totalGrade = 0.0;
    int gradeCount = 0;
    
    for (int i = 1; i < coordinates.length; i++) {
      final grade = calculateGrade(coordinates[i - 1], coordinates[i]);
      if (grade.isFinite && !grade.isNaN) {
        totalGrade += grade;
        gradeCount++;
      }
    }
    
    final avgGrade = gradeCount > 0 ? totalGrade / gradeCount : 0.0;
    
    // Base pace
    final distanceKm = totalDistance / 1000;
    final basePace = durationSeconds / distanceKm;
    
    // Adjust for grade
    // Uphill: slower (add time)
    // Downhill: faster (subtract time)
    // Rule: 1% grade = ~3.5% pace adjustment
    final gradeFactor = 1 + (avgGrade * 0.035);
    
    return basePace * gradeFactor;
  }

  /// Calculate calories burned (rough estimate)
  /// Uses MET (Metabolic Equivalent of Task) values
  static double calculateCalories({
    required List<Coordinate> coordinates,
    required ActivityType activityType,
    required double weightKg,
  }) {
    if (coordinates.length < 2) return 0.0;
    
    final totalDistance = calculateTotalDistance(coordinates);
    final startTime = coordinates.first.timestamp;
    final endTime = coordinates.last.timestamp;
    final durationHours = endTime.difference(startTime).inSeconds / 3600;
    
    // MET values for different activities
    // Running: ~9.8 MET (varied by speed)
    // Jogging: ~7.0 MET
    // Walking: ~3.5 MET
    // Cycling: ~8.0 MET
    double met;
    switch (activityType) {
      case ActivityType.running:
        met = 9.8;
        break;
      case ActivityType.jogging:
        met = 7.0;
        break;
      case ActivityType.walking:
        met = 3.5;
        break;
      case ActivityType.cycling:
        met = 8.0;
        break;
    }
    
    // Calories = MET × weight (kg) × time (hours)
    return met * weightKg * durationHours;
  }

  /// Check if the user is currently stationary (for auto-pause)
  static bool isStationary(List<Coordinate> recentCoordinates) {
    if (recentCoordinates.length < 2) return false;
    
    final latest = recentCoordinates.last;
    final speed = latest.speed ?? 0;
    
    return speed < autoPauseSpeedThreshold;
  }

  /// Get bounding box for a list of coordinates
  static LatLngBounds? getBoundingBox(List<Coordinate> coordinates) {
    if (coordinates.isEmpty) return null;
    
    double minLat = double.infinity;
    double maxLat = double.negativeInfinity;
    double minLng = double.infinity;
    double maxLng = double.negativeInfinity;
    
    for (final coord in coordinates) {
      if (coord.latitude < minLat) minLat = coord.latitude;
      if (coord.latitude > maxLat) maxLat = coord.latitude;
      if (coord.longitude < minLng) minLng = coord.longitude;
      if (coord.longitude > maxLng) maxLng = coord.longitude;
    }
    
    return LatLngBounds(
      LatLng(minLat, minLng),
      LatLng(maxLat, maxLng),
    );
  }

  /// Calculate the center point of coordinates
  static LatLng? getCenterPoint(List<Coordinate> coordinates) {
    if (coordinates.isEmpty) return null;
    
    double sumLat = 0;
    double sumLng = 0;
    
    for (final coord in coordinates) {
      sumLat += coord.latitude;
      sumLng += coord.longitude;
    }
    
    return LatLng(sumLat / coordinates.length, sumLng / coordinates.length);
  }

  /// Get optimal map zoom level to fit all coordinates
  static double getOptimalZoom(List<Coordinate> coordinates, double screenWidth, double screenHeight) {
    final bounds = getBoundingBox(coordinates);
    if (bounds == null) return 15.0;
    
    final latDiff = (bounds.north - bounds.south).abs();
    final lngDiff = (bounds.east - bounds.west).abs();
    
    if (latDiff == 0 && lngDiff == 0) return 16.0;
    
    // Calculate zoom for latitude
    final latZoom = log(screenHeight / (latDiff * 111320)) / ln2;
    // Calculate zoom for longitude
    final lngZoom = log(screenWidth / (lngDiff * 111320 * cos(bounds.south * pi / 180))) / ln2;
    
    // Return the smaller zoom (more zoomed out) to fit everything
    return min(latZoom, lngZoom).clamp(3.0, 18.0);
  }

  /// Dispose resources
  void dispose() {
    stopTracking();
    _coordinateController.close();
    _trackingStateController.close();
    _accuracyController.close();
  }
}

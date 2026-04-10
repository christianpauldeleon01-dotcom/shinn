import 'dart:async';
import 'package:uuid/uuid.dart';
import '../models/activity_model.dart';
import '../database/database_service.dart';
import 'gps_service.dart';
import 'location_filter_service.dart';

/// Speed data for instant pace calculation
class SpeedData {
  final double speed;
  final DateTime timestamp;
  final double distance;
  
  SpeedData({
    required this.speed, 
    required this.timestamp, 
    required this.distance
  });
}

/// Activity state enum
enum ActivityState {
  idle,
  running,
  paused,
  finished,
}

/// Split data for per-kilometer tracking
class Split {
  final int kilometer;
  final double distanceMeters;
  final int durationSeconds;
  final double paceSecondsPerKm;
  final DateTime startTime;
  final DateTime endTime;
  
  Split({
    required this.kilometer,
    required this.distanceMeters,
    required this.durationSeconds,
    required this.paceSecondsPerKm,
    required this.startTime,
    required this.endTime,
  });
  
  /// Get formatted pace
  String get formattedPace {
    if (paceSecondsPerKm <= 0 || paceSecondsPerKm.isInfinite || paceSecondsPerKm.isNaN) {
      return '--:--';
    }
    final minutes = (paceSecondsPerKm / 60).floor();
    final seconds = (paceSecondsPerKm % 60).round();
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
  
  /// Get pace in min/km
  double get paceMinPerKm => paceSecondsPerKm / 60;
}

/// Enhanced Activity Service with advanced tracking features
class EnhancedTrackingService {
  static final EnhancedTrackingService _instance = EnhancedTrackingService._internal();
  factory EnhancedTrackingService() => _instance;
  EnhancedTrackingService._internal();

  final GPSService _gpsService = GPSService();
  final Uuid _uuid = const Uuid();
  final LocationFilterService _locationFilter = LocationFilterService();

  // Activity state
  ActivityState _state = ActivityState.idle;
  ActivityState get state => _state;

  // Current activity data
  Activity? _currentActivity;
  Activity? get currentActivity => _currentActivity;

  // Raw route coordinates (from GPS)
  final List<Coordinate> _rawCoordinates = [];
  List<Coordinate> get rawCoordinates => List.unmodifiable(_rawCoordinates);

  // Filtered route coordinates
  final List<Coordinate> _filteredCoordinates = [];
  List<Coordinate> get filteredCoordinates => List.unmodifiable(_filteredCoordinates);
  
  // Used coordinates for distance calculation (filtered)
  final List<Coordinate> _usedCoordinates = [];
  List<Coordinate> get usedCoordinates => List.unmodifiable(_usedCoordinates);

  // Timer for duration tracking
  Timer? _durationTimer;
  int _elapsedSeconds = 0;
  int get elapsedSeconds => _elapsedSeconds;
  
  // Moving time (excluding paused time)
  int _movingTimeSeconds = 0;
  int get movingTimeSeconds => _movingTimeSeconds;
  
  // Elapsed time when paused (reserved for future use)
  int _pausedElapsedSeconds = 0;

  // DateTime when activity started
  DateTime? _startTime;
  DateTime? get startTime => _startTime;
  
  // Auto-pause settings
  static const double autoPauseSpeedThreshold = 0.5; // m/s (~1.8 km/h)
  bool _isAutoPaused = false;
  bool get isAutoPaused => _isAutoPaused;
  int _autoPauseStartTime = 0; // Reserved for future auto-pause duration tracking
  
  // Splits tracking
  final List<Split> _splits = [];
  List<Split> get splits => List.unmodifiable(_splits);
  double _lastSplitDistance = 0;
  DateTime? _lastSplitTime;
  int _currentSplitNumber = 0;
  
  // Stream controllers
  final StreamController<ActivityState> _stateController =
      StreamController<ActivityState>.broadcast();
  final StreamController<int> _durationController =
      StreamController<int>.broadcast();
  final StreamController<Activity> _activityCompletedController =
      StreamController<Activity>.broadcast();
  final StreamController<bool> _autoPauseController =
      StreamController<bool>.broadcast();
  final StreamController<Split> _splitController =
      StreamController<Split>.broadcast();
  final StreamController<double> _instantPaceController =
      StreamController<double>.broadcast();

  // Streams
  Stream<ActivityState> get stateStream => _stateController.stream;
  Stream<int> get durationStream => _durationController.stream;
  Stream<Activity> get activityCompletedStream =>
      _activityCompletedController.stream;
  Stream<bool> get autoPauseStream => _autoPauseController.stream;
  Stream<Split> get splitStream => _splitController.stream;
  Stream<double> get instantPaceStream => _instantPaceController.stream;

  // Subscription for GPS coordinates
  StreamSubscription<Coordinate>? _coordinateSubscription;

  // Activity type
  ActivityType _activityType = ActivityType.running;
  ActivityType get activityType => _activityType;
  
  // Speed buffer for instant pace calculation
  final List<SpeedData> _speedBuffer = [];
  static const int instantPaceWindowSeconds = 10;

  /// Set activity type
  void setActivityType(ActivityType type) {
    _activityType = type;
  }

  /// Start a new activity
  Future<bool> startActivity() async {
    if (_state != ActivityState.idle) return false;

    // Clear previous data
    _rawCoordinates.clear();
    _filteredCoordinates.clear();
    _usedCoordinates.clear();
    _splits.clear();
    _speedBuffer.clear();
    _elapsedSeconds = 0;
    _movingTimeSeconds = 0;
    _pausedElapsedSeconds = 0;
    _startTime = DateTime.now();
    _lastSplitDistance = 0;
    _lastSplitTime = _startTime;
    _currentSplitNumber = 0;
    _isAutoPaused = false;
    _locationFilter.reset();

    // Start GPS tracking
    final started = await _gpsService.startTracking();
    if (!started) {
      return false;
    }

    // Listen to GPS coordinates
    _coordinateSubscription = _gpsService.coordinateStream.listen(
      (coordinate) {
        if (_state == ActivityState.running && !_isAutoPaused) {
          _processCoordinate(coordinate);
        }
      },
    );

    // Start duration timer
    _startDurationTimer();

    // Update state
    _state = ActivityState.running;
    _stateController.add(_state);

    return true;
  }

  /// Process incoming GPS coordinate
  void _processCoordinate(Coordinate raw) {
    _rawCoordinates.add(raw);
    
    // Apply location filter
    final filtered = _locationFilter.processCoordinate(raw);
    if (filtered != null) {
      _filteredCoordinates.add(filtered);
      
      // Only count distance when actually moving (speed above threshold)
      final speed = filtered.speed ?? 0.0;
      if (speed >= GPSService.movingSpeedThreshold && _filteredCoordinates.length >= 2) {
        _usedCoordinates.add(filtered);
      }
      
      // Update speed buffer
      _speedBuffer.add(SpeedData(
        speed: speed,
        timestamp: filtered.timestamp,
        distance: currentFilteredDistance,
      ));
      
      // Clean old speed data
      _cleanSpeedBuffer();
      
      // Check for auto-pause
      _checkAutoPause(speed);
      
      // Check for split
      _checkSplit();
      
      // Emit instant pace
      final instantPace = calculateInstantPace();
      if (instantPace > 0) {
        _instantPaceController.add(instantPace);
      }
    }
  }
  
  /// Clean speed buffer to keep only recent data
  void _cleanSpeedBuffer() {
    final cutoffTime = DateTime.now().subtract(
      const Duration(seconds: instantPaceWindowSeconds),
    );
    _speedBuffer.removeWhere((data) => data.timestamp.isBefore(cutoffTime));
  }
  
  /// Check and update auto-pause state
  void _checkAutoPause(double currentSpeed) {
    if (_isAutoPaused) {
      // Check if we should resume
      if (currentSpeed > autoPauseSpeedThreshold) {
        _isAutoPaused = false;
        _autoPauseController.add(false);
      }
    } else {
      // Check if we should auto-pause
      if (currentSpeed < autoPauseSpeedThreshold && currentSpeed > 0) {
        _isAutoPaused = true;
        _autoPauseStartTime = _elapsedSeconds;
        _autoPauseController.add(true);
      }
    }
  }
  
  /// Check for kilometer split
  void _checkSplit() {
    final distance = currentFilteredDistance;
    final targetDistance = (_currentSplitNumber + 1) * 1000.0;
    
    if (distance >= targetDistance && _lastSplitTime != null) {
      _currentSplitNumber++;
      
      // Calculate split duration
      final now = DateTime.now();
      final splitTimeSeconds = now.difference(_lastSplitTime!).inSeconds;
      final splitDistance = distance - _lastSplitDistance;
      
      // Calculate pace for this split
      final splitPace = splitDistance > 0 
          ? (splitTimeSeconds / (splitDistance / 1000.0)) 
          : 0.0;
      
      final split = Split(
        kilometer: _currentSplitNumber,
        distanceMeters: splitDistance,
        durationSeconds: splitTimeSeconds,
        paceSecondsPerKm: splitPace,
        startTime: _lastSplitTime!,
        endTime: now,
      );
      
      _splits.add(split);
      _splitController.add(split);
      
      _lastSplitDistance = distance;
      _lastSplitTime = now;
    }
  }

  /// Pause the current activity
  void pauseActivity() {
    if (_state != ActivityState.running) return;

    _gpsService.stopTracking();
    _durationTimer?.cancel();
    
    // Record paused time
    _pausedElapsedSeconds = _elapsedSeconds;

    _state = ActivityState.paused;
    _stateController.add(_state);
  }

  /// Resume the current activity
  Future<bool> resumeActivity() async {
    if (_state != ActivityState.paused) return false;

    // Resume GPS tracking
    final started = await _gpsService.startTracking();
    if (!started) {
      return false;
    }

    // Restart duration timer
    _startDurationTimer();

    _state = ActivityState.running;
    _stateController.add(_state);

    return true;
  }

  /// Stop and save the current activity
  Future<Activity?> stopActivity({
    String? photoPath,
    double weightKg = 70.0,
    String? notes,
    String? mapSnapshotPath,
  }) async {
    if (_state != ActivityState.running && _state != ActivityState.paused) {
      return null;
    }

    // Stop GPS tracking
    _gpsService.stopTracking();
    _durationTimer?.cancel();
    _coordinateSubscription?.cancel();

    // Calculate stats using filtered coordinates
    final distance = currentFilteredDistance;
    final pace = calculateAveragePace();
    final avgSpeed = calculateAverageSpeed();
    final movingDistance = _calculateMovingDistance();
    final movingTime = _calculateMovingTime();
    
    // Calculate enhanced stats
    final elevationGain = GPSService.calculateElevationGain(_usedCoordinates);
    final elevationLoss = GPSService.calculateElevationLoss(_usedCoordinates);
    final maxElevation = GPSService.calculateMaxElevation(_usedCoordinates);
    final minElevation = GPSService.calculateMinElevation(_usedCoordinates);
    final calories = GPSService.calculateCalories(
      coordinates: _usedCoordinates,
      activityType: _activityType,
      weightKg: weightKg,
    );
    final steps = GPSService.estimateSteps(_usedCoordinates);
    
    // Calculate max speed
    double maxSpeed = 0;
    for (int i = 1; i < _usedCoordinates.length; i++) {
      final speed = GPSService.calculateSpeed(_usedCoordinates[i - 1], _usedCoordinates[i]);
      if (speed > maxSpeed) {
        maxSpeed = speed;
      }
    }

    // Create activity object
    final activity = Activity(
      id: _uuid.v4(),
      date: _startTime ?? DateTime.now(),
      durationSeconds: _elapsedSeconds,
      distanceMeters: distance,
      averagePaceSecondsPerKm: pace,
      averageSpeedMps: avgSpeed,
      routeCoordinates: List.from(_usedCoordinates),
      activityType: _activityType,
      photoPath: photoPath,
      caloriesBurned: calories,
      steps: steps,
      movingTimeSeconds: movingTime,
      movingDistanceMeters: movingDistance,
      elevationGain: elevationGain,
      elevationLoss: elevationLoss,
      maxElevation: maxElevation,
      minElevation: minElevation,
      maxSpeedMps: maxSpeed,
      notes: notes,
      mapSnapshotPath: mapSnapshotPath,
      weightKg: weightKg,
    );

    // Save to database
    await DatabaseService.saveActivity(activity);

    // Emit completed activity
    _activityCompletedController.add(activity);

    // Reset state
    _reset();

    return activity;
  }

  /// Discard current activity without saving
  void discardActivity() {
    _gpsService.stopTracking();
    _durationTimer?.cancel();
    _coordinateSubscription?.cancel();
    _reset();
  }

  /// Get current distance in meters (using filtered coordinates)
  double get currentFilteredDistance {
    if (_usedCoordinates.length < 2) return 0;
    
    double totalDistance = 0;
    for (int i = 1; i < _usedCoordinates.length; i++) {
      totalDistance += GPSService.calculateDistance(
        _usedCoordinates[i - 1],
        _usedCoordinates[i],
      );
    }
    return totalDistance;
  }

  /// Get current distance in kilometers
  double get currentDistanceKm => currentFilteredDistance / 1000;

  /// Calculate average pace in seconds per km
  double calculateAveragePace() {
    final distance = currentFilteredDistance;
    if (distance <= 0) return 0;
    
    // Use moving time if available, otherwise total time
    final time = _movingTimeSeconds > 0 ? _movingTimeSeconds : _elapsedSeconds;
    if (time <= 0) return 0;
    
    final distanceKm = distance / 1000;
    return time / distanceKm;
  }
  
  /// Calculate instant/rolling pace in seconds per km
  /// Uses last N seconds of movement
  double calculateInstantPace() {
    if (_speedBuffer.length < 2) return 0;
    
    double totalDistance = 0;
    int totalTime = 0;
    
    for (int i = 1; i < _speedBuffer.length; i++) {
      final timeDiff = _speedBuffer[i].timestamp.difference(
        _speedBuffer[i-1].timestamp,
      ).inSeconds;
      
      if (timeDiff > 0) {
        final speed = _speedBuffer[i].speed;
        // Only count distance when moving above threshold
        if (speed >= GPSService.movingSpeedThreshold) {
          totalDistance += _speedBuffer[i].distance - _speedBuffer[i-1].distance;
          totalTime += timeDiff;
        }
      }
    }
    
    if (totalDistance <= 0 || totalTime <= 0) return 0;
    
    final distanceKm = totalDistance / 1000;
    return totalTime / distanceKm;
  }

  /// Calculate average speed in m/s
  double calculateAverageSpeed() {
    final distance = currentFilteredDistance;
    if (distance <= 0) return 0;
    
    // Use moving time if available, otherwise total time
    final time = _movingTimeSeconds > 0 ? _movingTimeSeconds : _elapsedSeconds;
    if (time <= 0) return 0;
    
    return distance / time;
  }
  
  /// Calculate moving distance
  double _calculateMovingDistance() {
    if (_usedCoordinates.length < 2) return 0;
    
    double movingDistance = 0;
    for (int i = 1; i < _usedCoordinates.length; i++) {
      final speed = GPSService.calculateSpeed(_usedCoordinates[i - 1], _usedCoordinates[i]);
      if (speed >= GPSService.movingSpeedThreshold) {
        movingDistance += GPSService.calculateDistance(
          _usedCoordinates[i - 1],
          _usedCoordinates[i],
        );
      }
    }
    return movingDistance;
  }
  
  /// Calculate moving time
  int _calculateMovingTime() {
    if (_usedCoordinates.length < 2) return 0;
    
    int movingTime = 0;
    for (int i = 1; i < _usedCoordinates.length; i++) {
      final speed = GPSService.calculateSpeed(_usedCoordinates[i - 1], _usedCoordinates[i]);
      final timeDiff = _usedCoordinates[i].timestamp
          .difference(_usedCoordinates[i - 1].timestamp)
          .inSeconds;
      if (speed >= GPSService.movingSpeedThreshold) {
        movingTime += timeDiff;
      }
    }
    return movingTime;
  }

  /// Get formatted current pace
  String get formattedCurrentPace {
    final pace = calculateAveragePace();
    return _formatPace(pace);
  }
  
  /// Get formatted instant pace
  String get formattedInstantPace {
    final pace = calculateInstantPace();
    return _formatPace(pace);
  }
  
  /// Format pace in seconds per km to string
  String _formatPace(double pace) {
    if (pace <= 0 || pace.isInfinite || pace.isNaN) {
      return '--:--';
    }
    
    // Ignore unreasonably slow paces (> 1 hour per km)
    if (pace > 3600) {
      return '--:--';
    }
    
    final minutes = (pace / 60).floor();
    final seconds = (pace % 60).round();
    
    if (seconds >= 60) {
      return '${minutes + 1}:00';
    }
    
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  /// Get current speed in m/s
  double get currentSpeed {
    return GPSService.calculateMovingAverageSpeed(_usedCoordinates);
  }

  /// Get formatted duration
  String get formattedDuration {
    final hours = _elapsedSeconds ~/ 3600;
    final minutes = (_elapsedSeconds % 3600) ~/ 60;
    final seconds = _elapsedSeconds % 60;
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// Start duration timer
  void _startDurationTimer() {
    _durationTimer?.cancel();
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _elapsedSeconds++;
      
      // Only count moving time when actually moving (speed above threshold)
      if (_usedCoordinates.isNotEmpty) {
        final lastCoord = _usedCoordinates.last;
        final speed = lastCoord.speed ?? 0.0;
        if (speed >= GPSService.movingSpeedThreshold) {
          _movingTimeSeconds++;
        }
      }
      
      _durationController.add(_elapsedSeconds);
    });
  }

  /// Reset to idle state
  void _reset() {
    _state = ActivityState.idle;
    _currentActivity = null;
    _rawCoordinates.clear();
    _filteredCoordinates.clear();
    _usedCoordinates.clear();
    _splits.clear();
    _speedBuffer.clear();
    _elapsedSeconds = 0;
    _movingTimeSeconds = 0;
    _pausedElapsedSeconds = 0;
    _startTime = null;
    _isAutoPaused = false;
    _locationFilter.reset();
    _stateController.add(_state);
  }

  /// Get all saved activities
  List<Activity> getAllActivities() {
    return DatabaseService.getAllActivities();
  }

  /// Get activity by ID
  Activity? getActivity(String id) {
    return DatabaseService.getActivity(id);
  }

  /// Delete an activity
  Future<void> deleteActivity(String id) async {
    await DatabaseService.deleteActivity(id);
  }

  /// Dispose resources
  void dispose() {
    _durationTimer?.cancel();
    _coordinateSubscription?.cancel();
    _stateController.close();
    _durationController.close();
    _activityCompletedController.close();
    _autoPauseController.close();
    _splitController.close();
    _instantPaceController.close();
  }
}

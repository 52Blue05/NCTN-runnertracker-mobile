import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';

import '../model/run_session_model.dart';
import '../service/location_service.dart';
import '../service/run_session_service.dart';
import '../../../core/storage/local_run_database.dart';

final locationServiceProvider = Provider<LocationService>((ref) {
  return LocationService();
});

enum RunState { stopped, running, paused }

class TrackingState {
  final RunState runState;
  final DateTime? startTime;
  final int elapsedSeconds;
  final double totalDistanceKm;
  final int stepCount;
  final List<LatLng> coordinates;
  final Position? currentPosition; // Chỉ dùng cho việc pan camera

  TrackingState({
    this.runState = RunState.stopped,
    this.startTime,
    this.elapsedSeconds = 0,
    this.totalDistanceKm = 0.0,
    this.stepCount = 0,
    this.coordinates = const [],
    this.currentPosition,
  });

  bool get isRunning => runState == RunState.running;
  bool get isPaused => runState == RunState.paused;

  TrackingState copyWith({
    RunState? runState,
    DateTime? startTime,
    int? elapsedSeconds,
    double? totalDistanceKm,
    int? stepCount,
    List<LatLng>? coordinates,
    Position? currentPosition,
  }) {
    return TrackingState(
      runState: runState ?? this.runState,
      startTime: startTime ?? this.startTime,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      totalDistanceKm: totalDistanceKm ?? this.totalDistanceKm,
      stepCount: stepCount ?? this.stepCount,
      coordinates: coordinates ?? this.coordinates,
      currentPosition: currentPosition ?? this.currentPosition,
    );
  }
}

class TrackingNotifier extends Notifier<TrackingState> {
  StreamSubscription<Map<String, dynamic>?>? _serviceSubscription;
  StreamSubscription<Position>? _idlePositionSub;
  StreamSubscription<Position>? _gpsSubscription;
  StreamSubscription<StepCount>? _stepSubscription;

  @override
  TrackingState build() {
    ref.onDispose(() {
      _serviceSubscription?.cancel();
      _idlePositionSub?.cancel();
      _gpsSubscription?.cancel();
      _stepSubscription?.cancel();
    });
    return TrackingState();
  }

  LocationService get _locationService => ref.read(locationServiceProvider);

  Future<void> initLocationStream() async {
    // Xin quyền thông báo cho Android 13+ (đã có Activity nên không bị crash)
    await Permission.notification.request();

    final hasPermission = await _locationService.ensurePermission();
    if (!hasPermission) return;

    // Lấy vị trí ban đầu
    final pos = await _locationService.getCurrentPosition();
    state = state.copyWith(currentPosition: pos);

    // Lắng nghe GPS khi ở trạng thái idle (để pan camera)
    _startIdleLocationStream();

    // Kết nối tới Background Service
    _serviceSubscription?.cancel();
    _serviceSubscription = FlutterBackgroundService().on('update').listen((event) {
      if (event == null) return;
      
      final bool isRunning = event['isRunning'] ?? false;
      final bool isPaused = event['isPaused'] ?? false;
      
      RunState newState = RunState.stopped;
      if (isRunning) newState = RunState.running;
      if (isPaused) newState = RunState.paused;
      
      final rawCoords = event['coordinates'] as List<dynamic>? ?? [];
      final List<LatLng> newCoordinates = rawCoords.map((c) {
        return LatLng((c['lat'] as num).toDouble(), (c['lng'] as num).toDouble());
      }).toList();

      state = state.copyWith(
        runState: newState,
        elapsedSeconds: event['elapsedSeconds'] ?? 0,
        totalDistanceKm: (event['totalDistanceKm'] as num?)?.toDouble() ?? 0.0,
        stepCount: event['stepCount'] ?? 0,
        coordinates: newCoordinates,
        // Update currentPosition based on the last coordinate from background
        currentPosition: newCoordinates.isNotEmpty 
          ? Position(
              latitude: newCoordinates.last.latitude,
              longitude: newCoordinates.last.longitude,
              timestamp: DateTime.now(),
              accuracy: 0,
              altitude: 0,
              altitudeAccuracy: 0,
              heading: 0,
              headingAccuracy: 0,
              speed: 0,
              speedAccuracy: 0,
            )
          : state.currentPosition,
      );
    });

    // Request state in case service is already running
    FlutterBackgroundService().invoke('request_state');
  }

  void _startIdleLocationStream() {
    _idlePositionSub?.cancel();
    _idlePositionSub = _locationService.getPositionStream().listen((pos) {
      if (state.runState == RunState.stopped) {
        state = state.copyWith(currentPosition: pos);
      }
    });
  }

  Future<void> startRun() async {
    if (state.currentPosition == null) return;
    
    // Ngắt stream idle
    _idlePositionSub?.cancel();
    
    state = state.copyWith(
      runState: RunState.running,
      startTime: DateTime.now(),
      elapsedSeconds: 0,
      totalDistanceKm: 0.0,
      stepCount: 0,
      coordinates: [
        LatLng(state.currentPosition!.latitude, state.currentPosition!.longitude)
      ],
    );

    final service = FlutterBackgroundService();
    await service.startService();
    service.invoke('start', {
      'lat': state.currentPosition!.latitude,
      'lng': state.currentPosition!.longitude,
    });

    // Forward GPS updates to the background service
    _gpsSubscription?.cancel();
    _gpsSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      ),
    ).listen((pos) {
      FlutterBackgroundService().invoke('location', {
        'lat': pos.latitude,
        'lng': pos.longitude,
        'accuracy': pos.accuracy,
      });
    });

    // Forward pedometer updates to the background service
    _stepSubscription?.cancel();
    _stepSubscription = Pedometer.stepCountStream.listen((event) {
      FlutterBackgroundService().invoke('step', {
        'steps': event.steps,
      });
    });
  }

  Future<void> pauseRun() async {
    if (state.runState != RunState.running) return;
    
    _gpsSubscription?.cancel();
    _stepSubscription?.cancel();
    state = state.copyWith(runState: RunState.paused);
    FlutterBackgroundService().invoke('pause');
  }

  Future<void> resumeRun() async {
    if (state.runState != RunState.paused) return;
    
    state = state.copyWith(runState: RunState.running);
    FlutterBackgroundService().invoke('resume');

    // Re-subscribe GPS and pedometer
    _gpsSubscription?.cancel();
    _gpsSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      ),
    ).listen((pos) {
      FlutterBackgroundService().invoke('location', {
        'lat': pos.latitude,
        'lng': pos.longitude,
        'accuracy': pos.accuracy,
      });
    });

    _stepSubscription?.cancel();
    _stepSubscription = Pedometer.stepCountStream.listen((event) {
      FlutterBackgroundService().invoke('step', {
        'steps': event.steps,
      });
    });
  }

  Future<({RunSessionModel session, bool syncedSuccessfully})?> stopRun() async {
    _gpsSubscription?.cancel();
    _stepSubscription?.cancel();

    final endTime = DateTime.now();
    final currentState = state;

    FlutterBackgroundService().invoke('stop');
    
    // Mở lại idle stream
    _startIdleLocationStream();

    state = state.copyWith(runState: RunState.stopped);

    if (currentState.startTime == null) return null;

    final session = RunSessionModel.fromTrackingData(
      startTime: currentState.startTime!,
      endTime: endTime,
      distanceKm: currentState.totalDistanceKm,
      durationSeconds: currentState.elapsedSeconds,
      stepCount: currentState.stepCount,
      coordinates: currentState.coordinates,
    );

    bool synced = false;
    try {
      final service = RunSessionService();
      await service.createRunSession(session);
      synced = true;
    } catch (e) {
      // Lưu local nếu lỗi
      final db = LocalRunDatabase();
      await db.savePendingRun(session);
    }

    return (session: session, syncedSuccessfully: synced);
  }
}

final trackingProvider = NotifierProvider<TrackingNotifier, TrackingState>(() {
  return TrackingNotifier();
});

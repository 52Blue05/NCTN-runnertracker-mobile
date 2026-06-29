import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/utils/math_utils.dart';
import '../service/location_service.dart';

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
  final Position? currentPosition;

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
  StreamSubscription<Position>? _positionSubscription;
  StreamSubscription<StepCount>? _stepSubscription;
  Timer? _timer;
  
  int? _initialSteps;
  int _lastSteps = 0; // Để lưu số bước khi pause

  @override
  TrackingState build() {
    ref.onDispose(() {
      _timer?.cancel();
      _positionSubscription?.cancel();
      _stepSubscription?.cancel();
    });
    return TrackingState();
  }

  LocationService get _locationService => ref.read(locationServiceProvider);

  Future<void> initLocationStream() async {
    final hasPermission = await _locationService.ensurePermission();
    if (!hasPermission) return;

    final pos = await _locationService.getCurrentPosition();
    state = state.copyWith(currentPosition: pos);

    _positionSubscription?.cancel();
    _positionSubscription = _locationService.getPositionStream().listen((pos) {
      _handlePositionUpdate(pos);
    });
  }

  void _handlePositionUpdate(Position position) {
    if (state.runState != RunState.running) {
      // Chỉ cập nhật vị trí hiện tại nếu chưa chạy hoặc đang dừng/pause
      state = state.copyWith(currentPosition: position);
      return;
    }

    final newPoint = LatLng(position.latitude, position.longitude);
    
    // Lọc GPS xuyên tường
    if (!_shouldAcceptPoint(position, newPoint)) {
      state = state.copyWith(currentPosition: position);
      return;
    }

    double newDistance = state.totalDistanceKm;
    if (state.coordinates.isNotEmpty) {
      final last = state.coordinates.last;
      newDistance += MathUtils.haversineDistance(last, newPoint);
    }

    state = state.copyWith(
      currentPosition: position,
      totalDistanceKm: newDistance,
      coordinates: [...state.coordinates, newPoint],
    );
  }

  bool _shouldAcceptPoint(Position position, LatLng newPoint) {
    if (position.accuracy > 25) return false;

    if (state.coordinates.isNotEmpty) {
      final last = state.coordinates.last;
      final distanceKm = MathUtils.haversineDistance(last, newPoint);
      final distanceMeters = distanceKm * 1000;
      final maxDistancePerUpdate = (45 * 1000 / 3600) * 5; // max 45km/h trong 5s
      if (distanceMeters > maxDistancePerUpdate) return false;
    }
    return true;
  }

  Future<void> startRun() async {
    if (state.currentPosition == null) return;
    
    final startPoint = LatLng(
      state.currentPosition!.latitude,
      state.currentPosition!.longitude,
    );

    state = state.copyWith(
      runState: RunState.running,
      startTime: DateTime.now(),
      elapsedSeconds: 0,
      totalDistanceKm: 0.0,
      stepCount: 0,
      coordinates: [startPoint],
    );

    _initialSteps = null;
    _lastSteps = 0;

    await _startSensors();
  }

  Future<void> pauseRun() async {
    if (state.runState != RunState.running) return;

    _timer?.cancel();
    _stepSubscription?.cancel();
    _lastSteps = state.stepCount;

    state = state.copyWith(runState: RunState.paused);
  }

  Future<void> resumeRun() async {
    if (state.runState != RunState.paused) return;

    state = state.copyWith(runState: RunState.running);
    await _startSensors();
  }

  Future<void> stopRun() async {
    _timer?.cancel();
    _stepSubscription?.cancel();
    state = state.copyWith(runState: RunState.stopped);
  }

  Future<void> _startSensors() async {
    // 1. Khởi động Timer
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.runState == RunState.running) {
        state = state.copyWith(elapsedSeconds: state.elapsedSeconds + 1);
      }
    });

    // 2. Khởi động Pedometer
    if (await Permission.activityRecognition.request().isGranted) {
      _stepSubscription?.cancel();
      _stepSubscription = Pedometer.stepCountStream.listen((event) {
        if (state.runState != RunState.running) return;
        
        _initialSteps ??= event.steps;
        
        final currentRunSteps = event.steps - _initialSteps!;
        state = state.copyWith(stepCount: _lastSteps + currentRunSteps);
      });
    }
  }
}

final trackingProvider = NotifierProvider<TrackingNotifier, TrackingState>(() {
  return TrackingNotifier();
});

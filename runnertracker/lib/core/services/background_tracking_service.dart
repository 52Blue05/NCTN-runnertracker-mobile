import 'dart:async';
import 'dart:ui';
import 'package:flutter_background_service/flutter_background_service.dart';
import '../utils/math_utils.dart';

Future<void> initializeBackgroundService() async {
  final service = FlutterBackgroundService();
  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStart: false,
      isForegroundMode: true,
      notificationChannelId: 'running_tracker_channel',
      initialNotificationTitle: 'Runner Tracker',
      initialNotificationContent: 'Đang chuẩn bị...',
      foregroundServiceNotificationId: 888,
    ),
    iosConfiguration: IosConfiguration(
      autoStart: false,
      onForeground: onStart,
      onBackground: onIosBackground,
    ),
  );
}

@pragma('vm:entry-point')
bool onIosBackground(ServiceInstance service) {
  return true;
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();

  bool isRunning = false;
  bool isPaused = false;
  int elapsedSeconds = 0;
  double totalDistanceKm = 0.0;
  int stepCount = 0;
  List<Map<String, double>> coordinates = [];
  int? initialSteps;
  int lastSteps = 0;
  bool ignoreNextDistance = false;

  Timer? timer;

  // Broadcast state to UI
  void broadcastState() {
    service.invoke('update', {
      'isRunning': isRunning,
      'isPaused': isPaused,
      'elapsedSeconds': elapsedSeconds,
      'totalDistanceKm': totalDistanceKm,
      'stepCount': stepCount,
      'coordinates': coordinates,
    });
  }

  // Timer for elapsed seconds
  void startTimer() {
    timer?.cancel();
    timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (isRunning && !isPaused) {
        elapsedSeconds++;
        broadcastState();
      }
    });
  }

  // Handle commands from UI
  service.on('start').listen((event) {
    isRunning = true;
    isPaused = false;
    elapsedSeconds = 0;
    totalDistanceKm = 0.0;
    stepCount = 0;
    coordinates.clear();
    initialSteps = null;
    lastSteps = 0;
    ignoreNextDistance = false;
    // optional initial coordinate from UI
    if (event != null && event['lat'] != null && event['lng'] != null) {
      coordinates.add({'lat': event['lat'], 'lng': event['lng']});
    }
    startTimer();
    broadcastState();
  });

  service.on('pause').listen((event) {
    isPaused = true;
    timer?.cancel();
    lastSteps = stepCount;
    broadcastState();
  });

  service.on('resume').listen((event) {
    isPaused = false;
    ignoreNextDistance = true; // ignore first jump after resume
    startTimer();
    broadcastState();
  });

  service.on('stop').listen((event) {
    isRunning = false;
    isPaused = false;
    timer?.cancel();
    broadcastState();
    service.stopSelf();
  });

  service.on('request_state').listen((event) {
    broadcastState();
  });

  // Receive location updates from UI
  service.on('location').listen((event) {
    if (event == null || !isRunning || isPaused) return;
    final double lat = (event['lat'] as num).toDouble();
    final double lng = (event['lng'] as num).toDouble();
    final double accuracy = (event['accuracy'] as num).toDouble();
    if (accuracy > 25) return;

    if (coordinates.isNotEmpty && !ignoreNextDistance) {
      final last = coordinates.last;
      final distanceKm = MathUtils.haversineDistance(
        last['lat']!, last['lng']!,
        lat, lng,
      );
      final distanceMeters = distanceKm * 1000;
      final maxDist = (45 * 1000 / 3600) * 5; // max 45km/h in 5s
      if (distanceMeters > maxDist) return;
      totalDistanceKm += distanceKm;
    }
    ignoreNextDistance = false;
    coordinates.add({'lat': lat, 'lng': lng});
    broadcastState();
  });

  // Receive step count updates from UI
  service.on('step').listen((event) {
    if (event == null || !isRunning || isPaused) return;
    final int steps = (event['steps'] as num).toInt();
    initialSteps ??= steps;
    stepCount = lastSteps + (steps - initialSteps!);
    broadcastState();
  });
}

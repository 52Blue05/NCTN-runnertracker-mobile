import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Trạng thái kết nối mạng của thiết bị.
enum NetworkStatus { online, offline }

/// Provider theo dõi trạng thái kết nối mạng realtime.
/// Khi mạng thay đổi (WiFi/Mobile bật tắt), provider sẽ tự emit giá trị mới.
final connectivityProvider = StreamProvider<NetworkStatus>((ref) {
  final connectivity = Connectivity();

  // Tạo controller để merge initial check + stream
  final controller = StreamController<NetworkStatus>();

  // Check trạng thái ban đầu
  connectivity.checkConnectivity().then((results) {
    controller.add(_mapStatus(results));
  });

  // Lắng nghe thay đổi mạng
  final sub = connectivity.onConnectivityChanged.listen((results) {
    controller.add(_mapStatus(results));
  });

  ref.onDispose(() {
    sub.cancel();
    controller.close();
  });

  return controller.stream;
});

NetworkStatus _mapStatus(List<ConnectivityResult> results) {
  if (results.contains(ConnectivityResult.none) || results.isEmpty) {
    return NetworkStatus.offline;
  }
  return NetworkStatus.online;
}

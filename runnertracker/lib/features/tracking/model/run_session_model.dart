import 'dart:convert';
import 'package:maplibre_gl/maplibre_gl.dart';

class RunSessionModel {
  const RunSessionModel({
    this.id,
    required this.startTime,
    this.endTime,
    required this.distanceKm,
    required this.durationSeconds,
    this.stepCount,
    this.polylineData,
    this.avgPace,
    this.status,
    this.createdAt,
  });

  final int? id;
  final DateTime startTime;
  final DateTime? endTime;
  final double distanceKm;
  final int durationSeconds;
  final int? stepCount;
  final String? polylineData; // JSON string: [[lat,lng], ...]
  final double? avgPace;
  final String? status;
  final DateTime? createdAt;

  /// Tạo từ tracking state khi nhấn Stop
  factory RunSessionModel.fromTrackingData({
    required DateTime startTime,
    required DateTime endTime,
    required double distanceKm,
    required int durationSeconds,
    required int stepCount,
    required List<LatLng> coordinates,
  }) {
    // Serialize coordinates thành JSON array: [[lat, lng], ...]
    final coordList = coordinates.map((c) => [c.latitude, c.longitude]).toList();
    final polylineJson = jsonEncode(coordList);

    return RunSessionModel(
      startTime: startTime,
      endTime: endTime,
      distanceKm: distanceKm,
      durationSeconds: durationSeconds,
      stepCount: stepCount,
      polylineData: polylineJson,
      status: 'COMPLETED',
    );
  }

  /// Tạo từ JSON response của backend
  factory RunSessionModel.fromJson(Map<String, dynamic> json) {
    return RunSessionModel(
      id: json['id'] as int?,
      startTime: DateTime.parse(json['startTime'].toString()),
      endTime: json['endTime'] != null
          ? DateTime.tryParse(json['endTime'].toString())
          : null,
      distanceKm: (json['distanceKm'] as num?)?.toDouble() ?? 0,
      durationSeconds: (json['durationSeconds'] as num?)?.toInt() ?? 0,
      stepCount: (json['stepCount'] as num?)?.toInt(),
      polylineData: json['polylineData'] as String?,
      avgPace: (json['avgPace'] as num?)?.toDouble(),
      status: json['status'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }

  /// Serialize thành JSON để gửi lên backend
  Map<String, dynamic> toJson() {
    return {
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'distanceKm': distanceKm,
      'durationSeconds': durationSeconds,
      'stepCount': stepCount,
      'polylineData': polylineData,
      'status': status ?? 'COMPLETED',
    };
  }

  /// Parse polylineData JSON thành List of LatLng
  List<LatLng> get coordinatesList {
    if (polylineData == null || polylineData!.isEmpty) return [];
    try {
      final List<dynamic> decoded = jsonDecode(polylineData!);
      return decoded.map((c) {
        final coords = c as List<dynamic>;
        return LatLng(
          (coords[0] as num).toDouble(),
          (coords[1] as num).toDouble(),
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  /// Tính pace dạng chuỗi mm:ss
  String get paceFormatted {
    if (distanceKm <= 0.01) return '--:--';
    final totalMinutes = durationSeconds / 60.0;
    final paceDecimal = totalMinutes / distanceKm;
    if (paceDecimal > 60) return '>60:00';
    final paceMinutes = paceDecimal.floor();
    final paceSeconds = ((paceDecimal - paceMinutes) * 60).round();
    if (paceSeconds >= 60) {
      return '${(paceMinutes + 1).toString().padLeft(2, '0')}:00';
    }
    return '${paceMinutes.toString().padLeft(2, '0')}:${paceSeconds.toString().padLeft(2, '0')}';
  }

  /// Format thời gian chạy thành chuỗi
  String get durationFormatted {
    final d = Duration(seconds: durationSeconds);
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    final seconds = d.inSeconds.remainder(60);
    if (hours > 0) {
      return '${hours}h ${minutes.toString().padLeft(2, '0')}m ${seconds.toString().padLeft(2, '0')}s';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}

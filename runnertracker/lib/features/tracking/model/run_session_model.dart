class RunSessionModel {
  const RunSessionModel({
    required this.id,
    required this.distanceMeters,
    required this.duration,
    required this.startedAt,
    this.endedAt,
  });

  final String id;
  final double distanceMeters;
  final Duration duration;
  final DateTime startedAt;
  final DateTime? endedAt;

  factory RunSessionModel.fromJson(Map<String, dynamic> json) {
    return RunSessionModel(
      id: json['id']?.toString() ?? '',
      distanceMeters: (json['distanceMeters'] as num?)?.toDouble() ?? 0,
      duration: Duration(
        seconds: (json['durationSeconds'] as num?)?.toInt() ?? 0,
      ),
      startedAt:
          DateTime.tryParse(json['startedAt']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      endedAt: DateTime.tryParse(json['endedAt']?.toString() ?? ''),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'distanceMeters': distanceMeters,
      'durationSeconds': duration.inSeconds,
      'startedAt': startedAt.toIso8601String(),
      'endedAt': endedAt?.toIso8601String(),
    };
  }
}

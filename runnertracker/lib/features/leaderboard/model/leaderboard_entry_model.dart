class LeaderboardEntryModel {
  const LeaderboardEntryModel({
    required this.rank,
    required this.userId,
    required this.fullName,
    required this.totalDistanceKm,
    required this.runCount,
  });

  final int rank;
  final String userId;
  final String fullName;
  final double totalDistanceKm;
  final int runCount;

  factory LeaderboardEntryModel.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntryModel(
      rank: (json['rank'] as num?)?.toInt() ?? 0,
      userId: json['userId']?.toString() ?? '',
      fullName: json['fullName']?.toString() ?? 'Người dùng Ẩn danh',
      totalDistanceKm: (json['totalDistanceKm'] as num?)?.toDouble() ?? 0.0,
      runCount: (json['runCount'] as num?)?.toInt() ?? 0,
    );
  }
}

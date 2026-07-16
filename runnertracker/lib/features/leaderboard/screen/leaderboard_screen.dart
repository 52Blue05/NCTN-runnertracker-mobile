import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/provider/auth_provider.dart';
import '../../../shared/widgets/empty_state_widget.dart';
import '../../../shared/widgets/skeleton_list_widget.dart';
import '../model/leaderboard_entry_model.dart';
import '../provider/leaderboard_provider.dart';

class LeaderboardScreen extends ConsumerStatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  ConsumerState<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends ConsumerState<LeaderboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bảng xếp hạng'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Tuần này'),
            Tab(text: 'Tháng này'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _LeaderboardList(period: 'weekly'),
          _LeaderboardList(period: 'monthly'),
        ],
      ),
    );
  }
}

class _LeaderboardList extends ConsumerWidget {
  const _LeaderboardList({required this.period});

  final String period;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leaderboardAsync = ref.watch(leaderboardProvider(period));
    final currentUser = ref.watch(authProvider).currentUser;

    return leaderboardAsync.when(
      data: (entries) {
        if (entries.isEmpty) {
          return EmptyStateWidget(
            icon: Icons.emoji_events_outlined,
            title: 'Chưa có dữ liệu',
            message: 'Bảng xếp hạng đang trống.\nHãy là người đầu tiên ghi danh!',
            actionText: 'Làm mới',
            onAction: () => ref.refresh(leaderboardProvider(period).future),
          );
        }

        return RefreshIndicator(
          onRefresh: () async => ref.refresh(leaderboardProvider(period).future),
          child: ListView.builder(
            itemCount: entries.length,
            itemBuilder: (context, index) {
              final entry = entries[index];
              final isMe = currentUser != null && entry.userId == currentUser.id;

              return _LeaderboardTile(
                entry: entry,
                isMe: isMe,
              );
            },
          ),
        );
      },
      loading: () => const SkeletonListWidget(itemCount: 10, itemHeight: 70),
      error: (err, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text('Lỗi: $err', textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.refresh(leaderboardProvider(period).future),
              child: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }
}

class _LeaderboardTile extends StatelessWidget {
  const _LeaderboardTile({required this.entry, required this.isMe});

  final LeaderboardEntryModel entry;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    // Top 3 colors
    Color? rankColor;
    if (entry.rank == 1) rankColor = Colors.amber;
    if (entry.rank == 2) rankColor = Colors.blueGrey[300];
    if (entry.rank == 3) rankColor = Colors.brown[300];

    return Container(
      color: isMe ? Theme.of(context).primaryColor.withValues(alpha: 0.1) : null,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Rank
          SizedBox(
            width: 40,
            child: Text(
              '${entry.rank}',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: rankColor ?? Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 8),

          // Avatar (Initial letter)
          CircleAvatar(
            backgroundColor: isMe ? Theme.of(context).primaryColor : Colors.grey[300],
            foregroundColor: isMe ? Colors.white : Colors.black87,
            child: Text(
              entry.fullName.isNotEmpty ? entry.fullName.substring(0, 1).toUpperCase() : '?',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 16),

          // Name and Run Count
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.fullName,
                  style: TextStyle(
                    fontWeight: isMe ? FontWeight.bold : FontWeight.w500,
                    fontSize: 16,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${entry.runCount} buổi chạy',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),

          // Distance
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                entry.totalDistanceKm.toStringAsFixed(2),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Text(
                'km',
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/connectivity_provider.dart';
import '../../core/services/sync_service.dart';

/// Widget hiển thị banner trạng thái kết nối mạng ở đầu màn hình.
/// Bao bọc child widget bên trong, tự động ẩn/hiện banner.
class ConnectionStatusWrapper extends ConsumerStatefulWidget {
  const ConnectionStatusWrapper({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<ConnectionStatusWrapper> createState() =>
      _ConnectionStatusWrapperState();
}

class _ConnectionStatusWrapperState
    extends ConsumerState<ConnectionStatusWrapper> {
  @override
  Widget build(BuildContext context) {
    final connectivity = ref.watch(connectivityProvider);
    final syncState = ref.watch(syncProvider);

    // Lắng nghe sync message để show SnackBar
    ref.listen<SyncState>(syncProvider, (prev, next) {
      if (next.lastSyncMessage != null &&
          next.lastSyncMessage != prev?.lastSyncMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                if (next.isSyncing)
                  const Padding(
                    padding: EdgeInsets.only(right: 12),
                    child: SizedBox.square(
                      dimension: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    ),
                  ),
                Expanded(child: Text(next.lastSyncMessage!)),
              ],
            ),
            backgroundColor: next.isSyncing ? Colors.blue : Colors.green,
            duration: Duration(seconds: next.isSyncing ? 10 : 3),
            behavior: SnackBarBehavior.floating,
          ),
        );
        // Xoá message sau khi hiển thị
        if (!next.isSyncing) {
          Future.delayed(const Duration(seconds: 3), () {
            if (mounted) ref.read(syncProvider.notifier).clearMessage();
          });
        }
      }
    });

    final isOffline = connectivity.when(
      data: (s) => s == NetworkStatus.offline,
      loading: () => false,
      error: (_, __) => false,
    );

    return Column(
      children: [
        // Offline banner
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          height: isOffline ? null : 0,
          child: isOffline
              ? MaterialBanner(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  content: Row(
                    children: [
                      const Icon(Icons.wifi_off, color: Colors.white, size: 18),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Không có kết nối mạng. Dữ liệu sẽ được lưu offline.',
                          style: TextStyle(color: Colors.white, fontSize: 13),
                        ),
                      ),
                      if (syncState.pendingCount > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white24,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${syncState.pendingCount} chờ sync',
                            style: const TextStyle(
                                color: Colors.white, fontSize: 11),
                          ),
                        ),
                    ],
                  ),
                  backgroundColor: Colors.red[700]!,
                  actions: const [SizedBox.shrink()],
                )
              : const SizedBox.shrink(),
        ),

        // Pending sync indicator (when online but has pending)
        if (!isOffline && syncState.pendingCount > 0 && !syncState.isSyncing)
          Container(
            width: double.infinity,
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            color: Colors.orange[700],
            child: Row(
              children: [
                const Icon(Icons.sync, color: Colors.white, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${syncState.pendingCount} buổi chạy chưa đồng bộ',
                    style:
                        const TextStyle(color: Colors.white, fontSize: 13),
                  ),
                ),
                GestureDetector(
                  onTap: () =>
                      ref.read(syncProvider.notifier).syncPendingRuns(),
                  child: const Text(
                    'Sync ngay',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ),

        // Main content
        Expanded(child: widget.child),
      ],
    );
  }
}

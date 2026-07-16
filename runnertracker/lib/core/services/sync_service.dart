import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/provider/auth_provider.dart';
import '../../features/tracking/service/run_session_service.dart';
import '../network/connectivity_provider.dart';
import '../storage/local_run_database.dart';

/// Trạng thái đồng bộ
class SyncState {
  const SyncState({
    this.pendingCount = 0,
    this.isSyncing = false,
    this.lastSyncMessage,
  });

  final int pendingCount;
  final bool isSyncing;
  final String? lastSyncMessage;

  SyncState copyWith({
    int? pendingCount,
    bool? isSyncing,
    String? lastSyncMessage,
    bool clearMessage = false,
  }) {
    return SyncState(
      pendingCount: pendingCount ?? this.pendingCount,
      isSyncing: isSyncing ?? this.isSyncing,
      lastSyncMessage: clearMessage ? null : lastSyncMessage ?? this.lastSyncMessage,
    );
  }
}

class SyncNotifier extends Notifier<SyncState> {
  final _db = LocalRunDatabase();

  @override
  SyncState build() {
    // Lắng nghe thay đổi kết nối mạng
    ref.listen<AsyncValue<NetworkStatus>>(connectivityProvider, (prev, next) {
      final prevStatus = prev?.value;
      final nextStatus = next.value;

      // Nếu vừa chuyển từ offline → online, tự động sync
      if (prevStatus == NetworkStatus.offline &&
          nextStatus == NetworkStatus.online) {
        syncPendingRuns();
      }
    });

    // Check pending count khi khởi tạo
    _loadPendingCount();

    return const SyncState();
  }

  Future<void> _loadPendingCount() async {
    final count = await _db.getPendingCount();
    state = state.copyWith(pendingCount: count);
  }

  /// Đồng bộ tất cả buổi chạy chưa sync lên server.
  Future<void> syncPendingRuns() async {
    if (state.isSyncing) return; // Tránh chạy song song

    final pendingRuns = await _db.getPendingRunsWithId();
    if (pendingRuns.isEmpty) return;

    state = state.copyWith(
      isSyncing: true,
      lastSyncMessage: 'Đang đồng bộ ${pendingRuns.length} buổi chạy...',
    );

    final service = RunSessionService(
      apiClient: ref.read(apiClientProvider),
    );

    int syncedCount = 0;
    int failedCount = 0;

    for (final entry in pendingRuns) {
      try {
        await service.createRunSession(entry['model']);
        await _db.deletePendingRun(entry['localId'] as int);
        syncedCount++;
      } catch (e) {
        failedCount++;
        debugPrint('Sync failed for localId=${entry['localId']}: $e');
      }
    }

    final remaining = await _db.getPendingCount();

    String message;
    if (failedCount == 0) {
      message = 'Đã đồng bộ thành công $syncedCount buổi chạy!';
    } else {
      message = 'Đồng bộ: $syncedCount thành công, $failedCount thất bại';
    }

    state = SyncState(
      pendingCount: remaining,
      isSyncing: false,
      lastSyncMessage: message,
    );
  }

  /// Cập nhật số lượng pending (gọi sau khi lưu local mới)
  Future<void> refreshPendingCount() async {
    final count = await _db.getPendingCount();
    state = state.copyWith(pendingCount: count);
  }

  void clearMessage() {
    state = state.copyWith(clearMessage: true);
  }
}

final syncProvider = NotifierProvider<SyncNotifier, SyncState>(
  SyncNotifier.new,
);

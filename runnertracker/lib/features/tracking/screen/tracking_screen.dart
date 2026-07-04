import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/math_utils.dart';
import '../provider/tracking_provider.dart';
import 'run_summary_screen.dart';

class TrackingScreen extends ConsumerStatefulWidget {
  const TrackingScreen({super.key});

  @override
  ConsumerState<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends ConsumerState<TrackingScreen> {
  static const LatLng _defaultTarget = LatLng(21.0278, 105.8342);

  MapLibreMapController? _mapController;
  bool _styleLoaded = false;
  
  Line? _polyline;
  Circle? _startMarker;
  Circle? _currentMarker;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(trackingProvider.notifier).initLocationStream();
    });
  }
  
  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  LatLng get _cameraTarget {
    final state = ref.read(trackingProvider);
    if (state.currentPosition == null) return _defaultTarget;
    return LatLng(state.currentPosition!.latitude, state.currentPosition!.longitude);
  }

  void _onMapCreated(MapLibreMapController controller) {
    _mapController = controller;
    final pos = ref.read(trackingProvider).currentPosition;
    if (pos != null) {
      _animateToPosition(pos.latitude, pos.longitude);
    }
  }

  void _onStyleLoaded() {
    _styleLoaded = true;
  }

  Future<void> _animateToPosition(double lat, double lng) async {
    final controller = _mapController;
    if (controller == null) return;

    await controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(lat, lng),
          zoom: 17,
        ),
      ),
    );
  }

  // ── Sync UI with Provider ──────────────────────────────────
  Future<void> _syncMapAnnotations(TrackingState state) async {
    final controller = _mapController;
    if (controller == null || !_styleLoaded) return;

    // Vẽ Start Marker
    if (state.coordinates.isNotEmpty && _startMarker == null) {
      _startMarker = await controller.addCircle(
        CircleOptions(
          geometry: state.coordinates.first,
          circleRadius: 10,
          circleColor: '#22C55E',
          circleStrokeColor: '#FFFFFF',
          circleStrokeWidth: 3,
          circleOpacity: 1,
        ),
      );
    } else if (state.coordinates.isEmpty && _startMarker != null) {
      await controller.removeCircle(_startMarker!);
      _startMarker = null;
    }

    // Vẽ Current Marker
    if (state.coordinates.isNotEmpty && _currentMarker == null) {
      _currentMarker = await controller.addCircle(
        CircleOptions(
          geometry: state.coordinates.last,
          circleRadius: 8,
          circleColor: '#EF4444',
          circleStrokeColor: '#FFFFFF',
          circleStrokeWidth: 2,
          circleOpacity: 1,
        ),
      );
    } else if (state.coordinates.isEmpty && _currentMarker != null) {
      await controller.removeCircle(_currentMarker!);
      _currentMarker = null;
    } else if (_currentMarker != null && state.coordinates.isNotEmpty) {
      await controller.updateCircle(
        _currentMarker!,
        CircleOptions(geometry: state.coordinates.last),
      );
    }

    // Vẽ Polyline
    if (state.coordinates.isNotEmpty && _polyline == null) {
      _polyline = await controller.addLine(
        LineOptions(
          geometry: List<LatLng>.from(state.coordinates),
          lineColor: '#2F80ED',
          lineWidth: 5.0,
          lineOpacity: 0.85,
          lineJoin: 'round',
        ),
      );
    } else if (state.coordinates.isEmpty && _polyline != null) {
      await controller.removeLine(_polyline!);
      _polyline = null;
    } else if (_polyline != null && state.coordinates.length > 1) {
      await controller.updateLine(
        _polyline!,
        LineOptions(geometry: List<LatLng>.from(state.coordinates)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(trackingProvider);
    final notifier = ref.read(trackingProvider.notifier);

    // Lắng nghe thay đổi toạ độ để cập nhật bản đồ
    ref.listen<List<LatLng>>(
      trackingProvider.select((s) => s.coordinates),
      (prev, next) {
        _syncMapAnnotations(state);
      }
    );

    // Lắng nghe vị trí hiện tại để tự động pan camera
    ref.listen<TrackingState>(
      trackingProvider,
      (prev, next) {
        if (prev?.currentPosition != next.currentPosition && next.currentPosition != null) {
          _animateToPosition(next.currentPosition!.latitude, next.currentPosition!.longitude);
        }
      }
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Theo dõi GPS')),
      body: Stack(
        children: [
          MapLibreMap(
            initialCameraPosition: CameraPosition(
              target: _cameraTarget,
              zoom: state.currentPosition == null ? 13 : 17,
            ),
            styleString: ApiConstants.goongStyleUrl,
            myLocationEnabled: true,
            myLocationTrackingMode: MyLocationTrackingMode.tracking,
            myLocationRenderMode: MyLocationRenderMode.compass,
            onMapCreated: _onMapCreated,
            onStyleLoadedCallback: _onStyleLoaded,
            trackCameraPosition: true,
          ),

          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: _RunStatusPanel(
              state: state,
              onStart: notifier.startRun,
              onPause: notifier.pauseRun,
              onResume: notifier.resumeRun,
              onStop: () async {
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (_) => const Center(child: CircularProgressIndicator()),
                );
                
                final result = await notifier.stopRun();
                
                if (context.mounted) {
                  Navigator.of(context).pop(); // Đóng loading dialog
                  if (result != null) {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => RunSummaryScreen(
                          session: result.session,
                          syncedSuccessfully: result.syncedSuccessfully,
                        ),
                      ),
                    );
                  }
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// Panel hiển thị trạng thái + nút Start/Pause/Stop
// ══════════════════════════════════════════════════════════════
class _RunStatusPanel extends StatelessWidget {
  const _RunStatusPanel({
    required this.state,
    required this.onStart,
    required this.onPause,
    required this.onResume,
    required this.onStop,
  });

  final TrackingState state;
  final VoidCallback onStart;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onStop;

  String _formatDuration(int totalSeconds) {
    final d = Duration(seconds: totalSeconds);
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    final seconds = d.inSeconds.remainder(60);
    if (hours > 0) {
      return '${hours}h ${minutes.toString().padLeft(2, '0')}m ${seconds.toString().padLeft(2, '0')}s';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final isRunning = state.runState != RunState.stopped;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x29000000),
            blurRadius: 20,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (state.currentPosition == null)
              const Row(
                children: [
                  SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 12),
                  Expanded(child: Text('Đang lấy tọa độ GPS...')),
                ],
              )
            else ...[
              if (isRunning) ...[
                // Stats khi đang chạy hoặc pause
                _buildRunningStats(context),
              ] else ...[
                // Thông tin GPS khi chưa chạy
                _buildGpsInfo(),
              ],
              const SizedBox(height: 16),
              _buildActionButtons(context),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildGpsInfo() {
    final pos = state.currentPosition!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tọa độ GPS hiện tại',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(Icons.location_on, size: 16, color: AppColors.primary),
            const SizedBox(width: 4),
            Text(
              '${pos.latitude.toStringAsFixed(6)}, ${pos.longitude.toStringAsFixed(6)}',
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            const Icon(Icons.gps_fixed, size: 16, color: AppColors.primary),
            const SizedBox(width: 4),
            Text(
              'Accuracy: ${pos.accuracy.toStringAsFixed(1)} m',
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRunningStats(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatColumn(
            icon: Icons.straighten,
            label: 'Quãng đường',
            value: '${state.totalDistanceKm.toStringAsFixed(2)} km',
          ),
        ),
        Container(width: 1, height: 40, color: AppColors.textSecondary.withAlpha(51)),
        Expanded(
          child: _StatColumn(
            icon: Icons.timer_outlined,
            label: 'Thời gian',
            value: _formatDuration(state.elapsedSeconds),
          ),
        ),
        Container(width: 1, height: 40, color: AppColors.textSecondary.withAlpha(51)),
        Expanded(
          child: _StatColumn(
            icon: Icons.speed_outlined,
            label: 'Pace',
            value: MathUtils.formatPace(Duration(seconds: state.elapsedSeconds), state.totalDistanceKm),
          ),
        ),
        Container(width: 1, height: 40, color: AppColors.textSecondary.withAlpha(51)),
        Expanded(
          child: _StatColumn(
            icon: Icons.directions_walk,
            label: 'Bước',
            value: '${state.stepCount}',
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    if (state.runState == RunState.stopped) {
      return FilledButton.icon(
        onPressed: onStart,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        icon: const Icon(Icons.play_arrow_rounded),
        label: const Text('Bắt đầu chạy', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      );
    }

    return Row(
      children: [
        if (state.runState == RunState.running)
          Expanded(
            child: FilledButton.icon(
              onPressed: onPause,
              style: FilledButton.styleFrom(
                backgroundColor: Colors.orange,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.pause),
              label: const Text('Tạm dừng'),
            ),
          )
        else
          Expanded(
            child: FilledButton.icon(
              onPressed: onResume,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.play_arrow),
              label: const Text('Tiếp tục'),
            ),
          ),
        const SizedBox(width: 12),
        Expanded(
          child: FilledButton.icon(
            onPressed: onStop,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.danger,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.stop),
            label: const Text('Dừng lại'),
          ),
        ),
      ],
    );
  }
}

class _StatColumn extends StatelessWidget {
  const _StatColumn({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14, // Nhỏ hơn một chút để tránh rớt dòng vì 4 cột
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

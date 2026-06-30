import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/constants/app_colors.dart';
import '../model/run_session_model.dart';

class RunSummaryScreen extends StatelessWidget {
  const RunSummaryScreen({
    super.key,
    required this.session,
    this.syncedSuccessfully = true,
  });

  final RunSessionModel session;
  final bool syncedSuccessfully;

  String _formatDateTime(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final coordinates = session.coordinatesList;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kết quả chạy'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Sync status banner
            _buildSyncBanner(),

            // Map preview
            if (coordinates.isNotEmpty)
              SizedBox(
                height: 250,
                child: _RunMapPreview(coordinates: coordinates),
              ),

            // Stats cards
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildMainStats(),
                  const SizedBox(height: 16),
                  _buildDetailStats(),
                  const SizedBox(height: 16),
                  _buildTimeInfo(),
                  const SizedBox(height: 24),
                  // Button quay lại
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () => Navigator.of(context).pop(),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.check_circle_outline),
                      label: const Text(
                        'Hoàn tất',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSyncBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: syncedSuccessfully
          ? const Color(0xFFDCFCE7)
          : const Color(0xFFFEF3C7),
      child: Row(
        children: [
          Icon(
            syncedSuccessfully ? Icons.cloud_done : Icons.cloud_off,
            size: 20,
            color: syncedSuccessfully
                ? const Color(0xFF16A34A)
                : const Color(0xFFD97706),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              syncedSuccessfully
                  ? 'Đã đồng bộ lên server thành công!'
                  : 'Lưu tạm offline — sẽ đồng bộ khi có mạng.',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: syncedSuccessfully
                    ? const Color(0xFF16A34A)
                    : const Color(0xFFD97706),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainStats() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            session.distanceKm.toStringAsFixed(2),
            style: const TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
              height: 1.1,
            ),
          ),
          const Text(
            'km',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _SummaryStatItem(
                  icon: Icons.timer_outlined,
                  label: 'Thời gian',
                  value: session.durationFormatted,
                ),
              ),
              Container(width: 1, height: 44, color: AppColors.textSecondary.withAlpha(30)),
              Expanded(
                child: _SummaryStatItem(
                  icon: Icons.speed_outlined,
                  label: 'Pace',
                  value: '${session.paceFormatted}/km',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailStats() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _SummaryStatItem(
              icon: Icons.directions_walk,
              label: 'Số bước',
              value: '${session.stepCount ?? 0}',
            ),
          ),
          Container(width: 1, height: 44, color: AppColors.textSecondary.withAlpha(30)),
          Expanded(
            child: _SummaryStatItem(
              icon: Icons.route_outlined,
              label: 'Tọa độ',
              value: '${session.coordinatesList.length} điểm',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _InfoRow(
            icon: Icons.play_circle_outline,
            label: 'Bắt đầu',
            value: _formatDateTime(session.startTime),
          ),
          if (session.endTime != null) ...[
            const SizedBox(height: 8),
            _InfoRow(
              icon: Icons.stop_circle_outlined,
              label: 'Kết thúc',
              value: _formatDateTime(session.endTime!),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Map Preview Widget ──────────────────────────────────────────
class _RunMapPreview extends StatefulWidget {
  const _RunMapPreview({required this.coordinates});

  final List<LatLng> coordinates;

  @override
  State<_RunMapPreview> createState() => _RunMapPreviewState();
}

class _RunMapPreviewState extends State<_RunMapPreview> {
  MapLibreMapController? _controller;

  @override
  Widget build(BuildContext context) {
    // Tính bounds từ danh sách toạ độ
    double minLat = widget.coordinates.first.latitude;
    double maxLat = widget.coordinates.first.latitude;
    double minLng = widget.coordinates.first.longitude;
    double maxLng = widget.coordinates.first.longitude;
    for (final c in widget.coordinates) {
      if (c.latitude < minLat) minLat = c.latitude;
      if (c.latitude > maxLat) maxLat = c.latitude;
      if (c.longitude < minLng) minLng = c.longitude;
      if (c.longitude > maxLng) maxLng = c.longitude;
    }
    final center = LatLng((minLat + maxLat) / 2, (minLng + maxLng) / 2);

    return MapLibreMap(
      initialCameraPosition: CameraPosition(target: center, zoom: 15),
      styleString: ApiConstants.goongStyleUrl,
      myLocationEnabled: false,
      rotateGesturesEnabled: false,
      tiltGesturesEnabled: false,
      onStyleLoadedCallback: () async {
        if (_controller == null) return;
        // Vẽ polyline khi style load xong
        await _controller!.addLine(
          LineOptions(
            geometry: List<LatLng>.from(widget.coordinates),
            lineColor: '#2F80ED',
            lineWidth: 4.0,
            lineOpacity: 0.9,
            lineJoin: 'round',
          ),
        );
        // Vẽ start marker (xanh)
        await _controller!.addCircle(
          CircleOptions(
            geometry: widget.coordinates.first,
            circleRadius: 8,
            circleColor: '#22C55E',
            circleStrokeColor: '#FFFFFF',
            circleStrokeWidth: 2,
          ),
        );
        // Vẽ end marker (đỏ)
        await _controller!.addCircle(
          CircleOptions(
            geometry: widget.coordinates.last,
            circleRadius: 8,
            circleColor: '#EF4444',
            circleStrokeColor: '#FFFFFF',
            circleStrokeWidth: 2,
          ),
        );
      },
      onMapCreated: (controller) {
        _controller = controller;
        // Fit camera to bounds
        if (widget.coordinates.length > 1) {
          controller.moveCamera(
            CameraUpdate.newLatLngBounds(
              LatLngBounds(
                southwest: LatLng(minLat - 0.001, minLng - 0.001),
                northeast: LatLng(maxLat + 0.001, maxLng + 0.001),
              ),
              left: 40,
              top: 40,
              right: 40,
              bottom: 40,
            ),
          );
        }
      },
    );
  }
}

// ── Stat Item Widget ──────────────────────────────────────────
class _SummaryStatItem extends StatelessWidget {
  const _SummaryStatItem({
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
        Icon(icon, size: 22, color: AppColors.primary),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

// ── Info Row Widget ──────────────────────────────────────────
class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(
          '$label:',
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

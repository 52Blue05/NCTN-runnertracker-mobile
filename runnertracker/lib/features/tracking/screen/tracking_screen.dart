import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/constants/app_colors.dart';
import '../provider/tracking_provider.dart';

class TrackingScreen extends ConsumerStatefulWidget {
  const TrackingScreen({super.key});

  @override
  ConsumerState<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends ConsumerState<TrackingScreen> {
  static const LatLng _defaultTarget = LatLng(21.0278, 105.8342);

  MapLibreMapController? _mapController;
  StreamSubscription<Position>? _positionSubscription;
  Position? _currentPosition;
  bool _isLoadingLocation = true;
  bool _locationEnabled = false;
  String? _errorMessage;

  LatLng get _cameraTarget {
    final position = _currentPosition;
    if (position == null) {
      return _defaultTarget;
    }

    return LatLng(position.latitude, position.longitude);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startLocationStream());
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _startLocationStream() async {
    final locationService = ref.read(locationServiceProvider);

    setState(() {
      _isLoadingLocation = true;
      _errorMessage = null;
    });

    try {
      final hasPermission = await locationService.ensurePermission();
      if (!mounted) {
        return;
      }

      if (!hasPermission) {
        setState(() {
          _isLoadingLocation = false;
          _locationEnabled = false;
          _errorMessage = 'Chưa có quyền truy cập vị trí.';
        });
        return;
      }

      final currentPosition = await locationService.getCurrentPosition();
      if (!mounted) {
        return;
      }

      setState(() {
        _currentPosition = currentPosition;
        _locationEnabled = true;
        _isLoadingLocation = false;
      });

      await _animateToPosition(currentPosition);
      await _positionSubscription?.cancel();
      _positionSubscription = locationService.getPositionStream().listen(
        _handlePositionUpdate,
        onError: _handlePositionError,
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoadingLocation = false;
        _locationEnabled = false;
        _errorMessage = error.toString();
      });
    }
  }

  Future<void> _animateToPosition(Position position) async {
    final controller = _mapController;
    if (controller == null) {
      return;
    }

    await controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(position.latitude, position.longitude),
          zoom: 17,
        ),
      ),
    );
  }

  void _handlePositionUpdate(Position position) {
    if (!mounted) {
      return;
    }

    setState(() {
      _currentPosition = position;
      _locationEnabled = true;
      _errorMessage = null;
    });

    _animateToPosition(position);
  }

  void _handlePositionError(Object error) {
    if (!mounted) {
      return;
    }

    setState(() {
      _errorMessage = error.toString();
    });
  }

  void _onMapCreated(MapLibreMapController controller) {
    _mapController = controller;
    final position = _currentPosition;
    if (position != null) {
      _animateToPosition(position);
    }
  }

  void _onStyleLoaded() {
    // Bật hiển thị vị trí user (chấm xanh) khi style đã load
    _mapController?.updateMyLocationTrackingMode(
      MyLocationTrackingMode.tracking,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Theo dõi GPS')),
      body: Stack(
        children: [
          MapLibreMap(
            initialCameraPosition: CameraPosition(
              target: _cameraTarget,
              zoom: _currentPosition == null ? 13 : 17,
            ),
            styleString: ApiConstants.goongStyleUrl,
            myLocationEnabled: _locationEnabled,
            myLocationTrackingMode: _locationEnabled
                ? MyLocationTrackingMode.tracking
                : MyLocationTrackingMode.none,
            myLocationRenderMode: MyLocationRenderMode.compass,
            onMapCreated: _onMapCreated,
            onStyleLoadedCallback: _onStyleLoaded,
            trackCameraPosition: true,
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: _LocationStatusPanel(
              isLoading: _isLoadingLocation,
              position: _currentPosition,
              errorMessage: _errorMessage,
              onRetry: _startLocationStream,
            ),
          ),
        ],
      ),
    );
  }
}

class _LocationStatusPanel extends StatelessWidget {
  const _LocationStatusPanel({
    required this.isLoading,
    required this.position,
    required this.errorMessage,
    required this.onRetry,
  });

  final bool isLoading;
  final Position? position;
  final String? errorMessage;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final position = this.position;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1F000000),
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (isLoading)
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
            else if (errorMessage != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    errorMessage!,
                    style: const TextStyle(color: AppColors.danger),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.my_location),
                    label: const Text('Thử lại'),
                  ),
                ],
              )
            else if (position != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Tọa độ GPS hiện tại',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Text('Lat: ${position.latitude.toStringAsFixed(6)}'),
                  Text('Lng: ${position.longitude.toStringAsFixed(6)}'),
                  Text('Accuracy: ${position.accuracy.toStringAsFixed(1)} m'),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

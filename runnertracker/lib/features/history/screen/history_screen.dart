import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../shared/widgets/empty_state_widget.dart';
import '../../../shared/widgets/skeleton_list_widget.dart';
import '../provider/history_provider.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(historyProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch sử chạy'),
      ),
      body: historyAsync.when(
        data: (runs) {
          if (runs.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.directions_run,
              title: 'Chưa có dữ liệu',
              message: 'Bạn chưa có buổi chạy nào.\nHãy bắt đầu ngay hôm nay!',
              actionText: 'Làm mới',
              onAction: () => ref.refresh(historyProvider.future),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => ref.refresh(historyProvider.future),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: runs.length,
              itemBuilder: (context, index) {
                final run = runs[index];
                final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        // Icon thay thế cho Map mini để tối ưu hiệu suất
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.directions_run,
                            size: 32,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                        const SizedBox(width: 16),

                        // Thông tin buổi chạy
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                dateFormat.format(run.startTime),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  _StatItem(
                                    label: 'Quãng đường',
                                    value: '${run.distanceKm.toStringAsFixed(2)} km',
                                  ),
                                  _StatItem(
                                    label: 'Pace',
                                    value: run.paceFormatted,
                                  ),
                                  _StatItem(
                                    label: 'Thời gian',
                                    value: run.durationFormatted,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
        loading: () => const SkeletonListWidget(itemCount: 5, itemHeight: 92),
        error: (err, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('Lỗi: $err', textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.refresh(historyProvider.future),
                child: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}

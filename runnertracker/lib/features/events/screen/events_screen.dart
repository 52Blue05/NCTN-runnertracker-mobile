import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../shared/widgets/empty_state_widget.dart';
import '../../../shared/widgets/skeleton_list_widget.dart';
import '../provider/event_provider.dart';

class EventsScreen extends ConsumerWidget {
  const EventsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(eventsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sự kiện'),
      ),
      body: eventsAsync.when(
        data: (events) {
          if (events.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.event_available,
              title: 'Chưa có sự kiện',
              message: 'Hiện tại chưa có sự kiện nào sắp diễn ra.\nHãy quay lại sau nhé!',
              actionText: 'Làm mới',
              onAction: () => ref.refresh(eventsProvider.future),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => ref.refresh(eventsProvider.future),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: events.length,
              itemBuilder: (context, index) {
                final event = events[index];
                final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

                return Card(
                  clipBehavior: Clip.antiAlias,
                  elevation: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Event Cover Image
                      Container(
                        height: 150,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          image: event.imageUrl != null && event.imageUrl!.isNotEmpty
                              ? DecorationImage(
                                  image: NetworkImage(event.imageUrl!),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: event.imageUrl == null || event.imageUrl!.isEmpty
                            ? const Center(
                                child: Icon(Icons.event, size: 48, color: Colors.grey),
                              )
                            : null,
                      ),

                      // Event Details
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              event.title,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    dateFormat.format(event.eventDate),
                                    style: TextStyle(color: Colors.grey[700]),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    event.location ?? 'Chưa cập nhật địa điểm',
                                    style: TextStyle(color: Colors.grey[700]),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            if (event.description != null && event.description!.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Text(
                                event.description!,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: Colors.black87),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
        loading: () => const SkeletonListWidget(itemCount: 3, itemHeight: 250),
        error: (err, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('Lỗi: $err', textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.refresh(eventsProvider.future),
                child: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

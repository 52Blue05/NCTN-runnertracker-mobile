import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/provider/auth_provider.dart';
import '../model/order_model.dart';
import '../service/order_service.dart';

final orderServiceProvider = Provider<OrderService>((ref) {
  return OrderService(apiClient: ref.watch(apiClientProvider));
});

/// Provider lấy danh sách đơn hàng của user
final myOrdersProvider = FutureProvider<List<OrderModel>>((ref) async {
  final service = ref.watch(orderServiceProvider);
  return service.getMyOrders();
});

import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../model/order_model.dart';

class OrderService {
  OrderService({required this.apiClient});

  final ApiClient apiClient;

  /// POST /api/v1/orders — Tạo đơn hàng mới
  Future<OrderModel> createOrder({
    required String shippingAddress,
    String? note,
    required List<OrderItemModel> items,
  }) async {
    final response = await apiClient.post(
      ApiConstants.orders,
      data: {
        'shippingAddress': shippingAddress,
        'note': note,
        'items': items.map((e) => e.toJson()).toList(),
      },
    );

    final data = response.data;
    if (data is Map<String, dynamic> && data['data'] != null) {
      return OrderModel.fromJson(data['data'] as Map<String, dynamic>);
    }
    throw Exception('Unexpected response format');
  }

  /// GET /api/v1/orders — Lấy danh sách đơn hàng của user
  Future<List<OrderModel>> getMyOrders() async {
    final response = await apiClient.get(ApiConstants.orders);
    final data = response.data;
    if (data is Map<String, dynamic> && data['data'] != null) {
      final list = data['data'] as List<dynamic>;
      return list
          .map((e) => OrderModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }
}

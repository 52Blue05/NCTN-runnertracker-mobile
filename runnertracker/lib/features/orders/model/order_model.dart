class OrderModel {
  const OrderModel({
    required this.id,
    required this.userId,
    required this.totalAmount,
    required this.status,
    this.shippingAddress,
    this.note,
    this.createdAt,
    required this.items,
  });

  final int id;
  final String userId;
  final double totalAmount;
  final String status;
  final String? shippingAddress;
  final String? note;
  final DateTime? createdAt;
  final List<OrderItemModel> items;

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List<dynamic>? ?? [];
    return OrderModel(
      id: (json['id'] as num).toInt(),
      userId: json['userId']?.toString() ?? '',
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0.0,
      status: json['status']?.toString() ?? 'PENDING',
      shippingAddress: json['shippingAddress']?.toString(),
      note: json['note']?.toString(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      items: rawItems
          .map((e) => OrderItemModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  /// Trả về tên trạng thái tiếng Việt
  String get statusLabel {
    switch (status) {
      case 'PENDING':
        return 'Chờ xác nhận';
      case 'CONFIRMED':
        return 'Đã xác nhận';
      case 'SHIPPED':
        return 'Đang giao';
      case 'DELIVERED':
        return 'Đã giao';
      case 'CANCELED':
        return 'Đã huỷ';
      default:
        return status;
    }
  }
}

class OrderItemModel {
  const OrderItemModel({
    this.id,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
  });

  final int? id;
  final String productName;
  final int quantity;
  final double unitPrice;

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    return OrderItemModel(
      id: (json['id'] as num?)?.toInt(),
      productName: json['productName']?.toString() ?? '',
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
      unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productName': productName,
      'quantity': quantity,
      'unitPrice': unitPrice,
    };
  }
}

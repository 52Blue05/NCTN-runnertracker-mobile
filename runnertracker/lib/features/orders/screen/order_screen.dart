import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../shared/widgets/empty_state_widget.dart';
import '../../../shared/widgets/skeleton_list_widget.dart';
import '../model/order_model.dart';
import '../provider/order_provider.dart';

/// Danh mục sản phẩm cố định của CLB
class _Product {
  const _Product(this.name, this.price);
  final String name;
  final double price;
}

const List<_Product> _products = [
  _Product('Áo HRC Running', 250000),
  _Product('Áo HRC Polo', 300000),
  _Product('Quần HRC Short', 200000),
  _Product('Giày chạy bộ HRC', 850000),
  _Product('Mũ lưỡi trai HRC', 120000),
  _Product('Băng đô thể thao', 50000),
  _Product('Bình nước HRC', 80000),
];

const List<String> _sizes = ['S', 'M', 'L', 'XL', 'XXL'];

class OrderScreen extends ConsumerStatefulWidget {
  const OrderScreen({super.key});

  @override
  ConsumerState<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends ConsumerState<OrderScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Đặt hàng'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Đặt hàng'),
            Tab(text: 'Đơn của tôi'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _OrderFormTab(
            onOrderCreated: () {
              // Refresh danh sách đơn hàng và chuyển qua tab lịch sử
              ref.invalidate(myOrdersProvider);
              _tabController.animateTo(1);
            },
          ),
          const _OrderHistoryTab(),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────
// Tab 1: Form đặt hàng
// ─────────────────────────────────────────────────────
class _OrderFormTab extends ConsumerStatefulWidget {
  const _OrderFormTab({required this.onOrderCreated});

  final VoidCallback onOrderCreated;

  @override
  ConsumerState<_OrderFormTab> createState() => _OrderFormTabState();
}

class _OrderFormTabState extends ConsumerState<_OrderFormTab> {
  final _formKey = GlobalKey<FormState>();
  final _addressController = TextEditingController();
  final _noteController = TextEditingController();

  // Danh sách item đang chọn
  final List<_OrderItemEntry> _items = [_OrderItemEntry()];

  bool _isSubmitting = false;

  @override
  void dispose() {
    _addressController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _addItem() {
    setState(() {
      _items.add(_OrderItemEntry());
    });
  }

  void _removeItem(int index) {
    if (_items.length > 1) {
      setState(() {
        _items.removeAt(index);
      });
    }
  }

  double get _totalPrice {
    double total = 0;
    for (final item in _items) {
      if (item.selectedProduct != null) {
        total += item.selectedProduct!.price * item.quantity;
      }
    }
    return total;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    // Kiểm tra sản phẩm
    for (final item in _items) {
      if (item.selectedProduct == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vui lòng chọn sản phẩm cho tất cả mục')),
        );
        return;
      }
    }

    setState(() => _isSubmitting = true);

    try {
      final orderItems = _items.map((e) {
        final sizeSuffix = e.selectedSize != null ? ' - ${e.selectedSize}' : '';
        return OrderItemModel(
          productName: '${e.selectedProduct!.name}$sizeSuffix',
          quantity: e.quantity,
          unitPrice: e.selectedProduct!.price,
        );
      }).toList();

      await ref.read(orderServiceProvider).createOrder(
            shippingAddress: _addressController.text.trim(),
            note: _noteController.text.trim().isEmpty
                ? null
                : _noteController.text.trim(),
            items: orderItems,
          );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đặt hàng thành công!'),
          backgroundColor: Colors.green,
        ),
      );

      // Reset form
      _addressController.clear();
      _noteController.clear();
      setState(() {
        _items.clear();
        _items.add(_OrderItemEntry());
      });

      widget.onOrderCreated();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Sản phẩm',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            // Danh sách item
            ...List.generate(_items.length, (index) {
              final item = _items[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Text(
                            'Mục ${index + 1}',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const Spacer(),
                          if (_items.length > 1)
                            IconButton(
                              icon: const Icon(Icons.close, size: 20),
                              onPressed: () => _removeItem(index),
                              visualDensity: VisualDensity.compact,
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Dropdown sản phẩm
                      DropdownButtonFormField<_Product>(
                        initialValue: item.selectedProduct,
                        decoration: const InputDecoration(
                          labelText: 'Chọn sản phẩm',
                          border: OutlineInputBorder(),
                          contentPadding:
                              EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        ),
                        items: _products.map((p) {
                          return DropdownMenuItem(
                            value: p,
                            child: Text(
                              '${p.name} (${currencyFormat.format(p.price)})',
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setState(() => item.selectedProduct = val);
                        },
                      ),
                      const SizedBox(height: 12),

                      Row(
                        children: [
                          // Dropdown size
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: item.selectedSize,
                              decoration: const InputDecoration(
                                labelText: 'Size',
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 12),
                              ),
                              items: _sizes.map((s) {
                                return DropdownMenuItem(value: s, child: Text(s));
                              }).toList(),
                              onChanged: (val) {
                                setState(() => item.selectedSize = val);
                              },
                            ),
                          ),
                          const SizedBox(width: 12),

                          // Số lượng
                          Expanded(
                            child: TextFormField(
                              initialValue: '1',
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Số lượng',
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 12),
                              ),
                              validator: (val) {
                                if (val == null || val.isEmpty) {
                                  return 'Nhập số lượng';
                                }
                                final n = int.tryParse(val);
                                if (n == null || n < 1) return 'Tối thiểu 1';
                                return null;
                              },
                              onChanged: (val) {
                                setState(() {
                                  item.quantity = int.tryParse(val) ?? 1;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }),

            // Nút thêm sản phẩm
            OutlinedButton.icon(
              onPressed: _addItem,
              icon: const Icon(Icons.add),
              label: const Text('Thêm sản phẩm'),
            ),
            const SizedBox(height: 16),

            // Địa chỉ
            TextFormField(
              controller: _addressController,
              decoration: const InputDecoration(
                labelText: 'Địa chỉ giao hàng',
                prefixIcon: Icon(Icons.location_on_outlined),
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Vui lòng nhập địa chỉ';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),

            // Ghi chú
            TextFormField(
              controller: _noteController,
              decoration: const InputDecoration(
                labelText: 'Ghi chú (tuỳ chọn)',
                prefixIcon: Icon(Icons.notes),
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),

            // Tổng tiền
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Tổng tiền:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  Text(
                    currencyFormat.format(_totalPrice),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Submit
            FilledButton.icon(
              onPressed: _isSubmitting ? null : _submit,
              icon: _isSubmitting
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.shopping_cart_checkout),
              label: Text(_isSubmitting ? 'Đang xử lý...' : 'Đặt hàng'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Dữ liệu tạm cho mỗi item trong form
class _OrderItemEntry {
  _Product? selectedProduct;
  String? selectedSize;
  int quantity = 1;
}

// ─────────────────────────────────────────────────────
// Tab 2: Lịch sử đơn hàng
// ─────────────────────────────────────────────────────
class _OrderHistoryTab extends ConsumerWidget {
  const _OrderHistoryTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(myOrdersProvider);
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return ordersAsync.when(
      data: (orders) {
        if (orders.isEmpty) {
          return EmptyStateWidget(
            icon: Icons.receipt_long,
            title: 'Chưa có đơn hàng',
            message: 'Bạn chưa mua sản phẩm nào.\nHãy đặt hàng để nhận các trang bị xịn sò!',
            actionText: 'Làm mới',
            onAction: () => ref.refresh(myOrdersProvider.future),
          );
        }

        return RefreshIndicator(
          onRefresh: () async => ref.refresh(myOrdersProvider.future),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];

              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header: Mã đơn + Trạng thái
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Đơn #${order.id}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          _StatusChip(status: order.status, label: order.statusLabel),
                        ],
                      ),
                      const Divider(height: 20),

                      // Items
                      ...order.items.map((item) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  '${item.productName} x${item.quantity}',
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ),
                              Text(
                                currencyFormat.format(item.unitPrice * item.quantity),
                                style: const TextStyle(fontSize: 14),
                              ),
                            ],
                          ),
                        );
                      }),

                      const Divider(height: 16),

                      // Footer: Tổng tiền + Ngày đặt
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            order.createdAt != null
                                ? dateFormat.format(order.createdAt!)
                                : '',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 13,
                            ),
                          ),
                          Text(
                            currencyFormat.format(order.totalAmount),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
      loading: () => const SkeletonListWidget(itemCount: 4, itemHeight: 150),
      error: (err, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text('Lỗi: $err', textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.refresh(myOrdersProvider.future),
              child: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status, required this.label});

  final String status;
  final String label;

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status) {
      case 'PENDING':
        color = Colors.orange;
        break;
      case 'CONFIRMED':
        color = Colors.blue;
        break;
      case 'SHIPPED':
        color = Colors.purple;
        break;
      case 'DELIVERED':
        color = Colors.green;
        break;
      case 'CANCELED':
        color = Colors.red;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}

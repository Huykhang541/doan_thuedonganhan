


import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../resources/app_colors.dart';
import '../../Model/Order.dart';
import '../../Controller/order_controller.dart';
import '../../Controller/product_controller.dart';
import '../Widget/order_widgets.dart';

class AdminOrderDetailScreen extends StatefulWidget {
  final Order order;
  const AdminOrderDetailScreen({super.key, required this.order});

  @override
  State<AdminOrderDetailScreen> createState() => _AdminOrderDetailScreenState();
}

class _AdminOrderDetailScreenState extends State<AdminOrderDetailScreen> {
  final OrderController _orderController = OrderController();
  late Future<Order?> _orderFuture;
  List<dynamic> _allVariants = [];

  @override
  void initState() {
    super.initState();
    _orderFuture = _orderController.getOrderDetail(widget.order.id);
    _loadProducts();
  }

  void _loadProducts() async {
    try {
      final list = await ProductController.getAllProductVariants();
      if (mounted) setState(() => _allVariants = list);
    } catch (e) { print(e); }
  }

  String formatCurrency(int amount) => NumberFormat.currency(locale: 'vi_VN', symbol: 'đ').format(amount);
  
  String formatDate(String dateString) {
    try { 
      String validDate = dateString.endsWith('Z') ? dateString : '${dateString}Z';
      DateTime parsedDate = DateTime.parse(validDate).toLocal();
      return DateFormat('dd/MM/yyyy HH:mm').format(parsedDate); 
    } catch (e) { 
      return dateString; 
    }
  }

  Map<String, dynamic> getStatusConfig(String status) {
    switch (status.toLowerCase().trim()) {
      case 'completed': 
      case 'delivered': return {'text': "Đã giao / Hoàn thành", 'color': Colors.green};
      case 'cancelled': return {'text': "Đã hủy", 'color': Colors.red};
      case 'confirmed': 
      case 'shipping': return {'text': "Đang giao đồ", 'color': Colors.orange};
      case 'cho_duyet': 
      case 'pending': return {'text': "Chờ xử lý", 'color': Colors.blue};
      case 'processing': return {'text': "Đang chuẩn bị", 'color': Colors.deepPurple};
      default: return {'text': status, 'color': Colors.grey};
    }
  }

  Map<String, String?> _getProductInfo(int id, String defaultName) {
    String name = defaultName;
    String? img;
    if (_allVariants.isNotEmpty) {
      for (var variant in _allVariants) {
        if (variant.id.toString() == id.toString()) {
          name = variant.name ?? name;
          img = variant.imageUrl;
          break;
        }
      }
    }
    return {'name': name, 'img': img};
  }

  void _updateStatus(String status) async {
    try {
      await _orderController.updateOrderStatus(widget.order.id, status);
      if (!mounted) return;
      final statusText = getStatusConfig(status)['text'];
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Đã cập nhật: $statusText"), backgroundColor: Colors.green)
      );
      setState(() { _orderFuture = _orderController.getOrderDetail(widget.order.id); });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Lỗi cập nhật API: $e"), backgroundColor: Colors.red)
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Order?>(
      future: _orderFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(appBar: _buildAppBar(), body: const Center(child: CircularProgressIndicator()));
        }
        
        final order = snapshot.data ?? widget.order;
        final items = order.items ?? [];
        int total = items.fold(0, (sum, i) => sum + (i.price * i.quantity));
        if (total == 0) total = order.totalPrice - order.shippingFee;

        return Scaffold(
          backgroundColor: Colors.grey.shade100,
          appBar: _buildAppBar(),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                OrderCardSection(
                  children: [
                    OrderCustomerInfoRow(fullName: order.fullName ?? "Khách thuê", phoneNumber: order.phoneNumber ?? ""),
                    const Divider(height: 24),
                    OrderIconTextRow(icon: Icons.location_on_outlined, text: order.address ?? "Chưa có địa chỉ"),
                    const SizedBox(height: 8),
                    OrderIconTextRow(icon: Icons.access_time, text: formatDate(order.createdAt)),
                  ],
                ),
                const SizedBox(height: 16),
                OrderCardSection(
                  children: [
                    Text("Đồ đang thuê (${items.length})", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const Divider(height: 24),
                    if (items.isEmpty) const Center(child: Text("Không có sản phẩm")),
                    ...items.map((i) => _buildProductItem(i)),
                  ],
                ),
                const SizedBox(height: 16),
                OrderCardSection(
                  children: [
                    OrderInfoRow(label: "Tạm tính (Tiền thuê + Cọc)", value: formatCurrency(total)),
                    OrderInfoRow(label: "Phí vận chuyển", value: formatCurrency(order.shippingFee)),
                    const Divider(height: 24),
                    OrderInfoRow(label: "Tổng cộng", value: formatCurrency(order.totalPrice), isBold: true, valueColor: AppColors.primaryOrange),
                    const SizedBox(height: 16),
                    _buildStatusBadge(order.status),
                  ],
                ),
                const SizedBox(height: 80),
              ],
            ),
          ),
          bottomNavigationBar: _buildBottomBar(order.status),
        );
      },
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: Text("Đơn thuê #${widget.order.id}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
      backgroundColor: AppColors.primaryOrange,
      centerTitle: true,
      leading: IconButton(icon: const Icon(Icons.arrow_back_ios, color: Colors.white), onPressed: () => Navigator.pop(context, true)),
    );
  }

  Widget _buildProductItem(OrderItem item) {
    final info = _getProductInfo(item.productId, item.productName);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 70, height: 70,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade300)),
            clipBehavior: Clip.hardEdge,
            child: (info['img'] != null && info['img']!.isNotEmpty)
                ? Image.network(info['img']!, fit: BoxFit.cover)
                : const Icon(Icons.shopping_bag_outlined, color: Colors.grey),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(info['name']!, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15), maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text("Số lượng: ${item.quantity}", style: const TextStyle(color: Colors.grey, fontSize: 13)),
              ],
            ),
          ),
          Text(formatCurrency(item.price), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    final config = getStatusConfig(status);
    return Container(
      width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(color: config['color'].withOpacity(0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: config['color'].withOpacity(0.3))),
      alignment: Alignment.center,
      child: Text(config['text'].toUpperCase(), style: TextStyle(color: config['color'], fontWeight: FontWeight.bold)),
    );
  }

  Widget? _buildBottomBar(String rawStatus) {
    String status = rawStatus.toLowerCase().trim();
    if (['completed', 'delivered', 'cancelled'].contains(status)) return null;
    return Container(
      padding: const EdgeInsets.all(16), 
      decoration: const BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black, blurRadius: 10)]),
      child: Row(
        children: [
          Expanded(child: OutlinedButton(
            onPressed: () => _updateStatus('cancelled'), 
            style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.red), padding: const EdgeInsets.symmetric(vertical: 14)), 
            child: const Text("Hủy đơn", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)))),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                if (status == 'pending' || status == 'cho_duyet') { 
                  _updateStatus('confirmed'); // Đổi từ 'shipping' sang 'confirmed' để khớp DB
                } else if (status == 'confirmed' || status == 'shipping') {
                  _updateStatus('completed'); // Đổi từ 'delivered' sang 'completed' để khớp DB
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryOrange, padding: const EdgeInsets.symmetric(vertical: 14)),
              child: Text((status == 'pending' || status == 'cho_duyet') ? "Duyệt đơn & Giao" : "Đã giao đồ", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            )
          ),
        ]
      ),
    );
  }
  
}
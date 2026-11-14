import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../resources/app_colors.dart';
import '../../Controller/order_controller.dart';
import '../../Controller/product_controller.dart';
import '../../Model/Order.dart';
import '../../Config/baseUrl.dart';
import 'Widget/order_widgets.dart';

class OrderDetailScreen extends StatefulWidget {
  final int orderId;
  const OrderDetailScreen({super.key, required this.orderId});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  final OrderController _orderController = OrderController();
  late Future<Order?> _orderDetailFuture;
  List<dynamic> _allVariants = []; 

  @override
  void initState() {
    super.initState();
    _orderDetailFuture = _orderController.getOrderDetail(widget.orderId);
    _loadProductList();
  }

  void _loadProductList() async {
    try {
      final list = await ProductController.getAllProductVariants();
      if (mounted) setState(() => _allVariants = list);
    } catch (e) { print(e); }
  }

  // Chuẩn hóa link ảnh (xử lý cả trường hợp DB lưu localhost:3001 khi chạy qua ngrok/máy ảo)
  String _formatImageUrl(String? path) {
    if (path == null || path.isEmpty) return "";
    String rootUrl = baseUrl.endsWith('/api') ? baseUrl.replaceAll('/api', '') : baseUrl;
    String cleanBase = rootUrl.endsWith('/') ? rootUrl.substring(0, rootUrl.length - 1) : rootUrl;

    if (path.contains("localhost:3001")) {
      return path.replaceFirst(RegExp(r'http://localhost:3001'), cleanBase);
    }
    if (path.startsWith("http")) return path;
    String cleanPath = path.startsWith('/') ? path : '/$path';
    return "$cleanBase$cleanPath";
  }

  String formatCurrency(int amount) => NumberFormat.currency(locale: 'vi_VN', symbol: 'đ', decimalDigits: 0).format(amount);
  
  //MÀN HÌNH ADMIN
  String formatDate(String dateString) {
    if (dateString.isEmpty) return "Chưa cập nhật";
    try { 
       DateTime parsedDate = DateTime.parse(dateString);
       
       // Kiểm tra nếu chuỗi API trả về là UTC (có đuôi Z) thì ép cộng 7 tiếng của VN
       // Nếu không phải UTC thì đưa về Local bình thường
       if (parsedDate.isUtc) {
          parsedDate = parsedDate.add(const Duration(hours: 7));
       } else {
          parsedDate = parsedDate.toLocal();
       }

       return DateFormat('dd/MM/yyyy HH:mm').format(parsedDate); 
    } 
    catch (e) { return dateString; }
  }

  Map<String, dynamic> getStatusConfig(String status) {
    String st = status.toLowerCase().trim();
    switch (st) {
      case 'cho_duyet':
      case 'pending': return {'text': "Chờ xác nhận", 'color': Colors.blue};
      case 'confirmed':
      case 'processing': return {'text': "Chủ đồ đã duyệt", 'color': Colors.deepPurple};
      case 'shipping': return {'text': "Đang giao đến bạn", 'color': Colors.orange};
      case 'completed':
      case 'delivered': return {'text': "Đang thuê", 'color': Colors.green};
      case 'cancelled':
      case 'da_huy': return {'text': "Đã hủy", 'color': Colors.red};
      default: return {'text': status, 'color': Colors.grey};
    }
  }

  Map<String, String?> _getProductInfo(int targetVariantId, String defaultName) {
    String name = defaultName;
    String? img;
    if (_allVariants.isNotEmpty && targetVariantId > 0) {
      for (var variant in _allVariants) {
        try {
           if (variant.id.toString() == targetVariantId.toString()) {
              name = variant.name ?? name;
              img = variant.imageUrl;
              break;
           }
        } catch(e) {
           if (variant['id'].toString() == targetVariantId.toString()) {
              name = variant['name'] ?? name;
              img = variant['imageUrl'] ?? variant['image'];
              break;
           }
        }
      }
    }
    return {'name': name, 'img': img};
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text("Thông tin đơn thuê", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primaryOrange,
        centerTitle: true,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios, color: Colors.white), onPressed: () => Navigator.pop(context)),
      ),
      
      body: FutureBuilder<Order?>(
        future: _orderDetailFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (!snapshot.hasData || snapshot.data == null) return const Center(child: Text("Không tìm thấy đơn thuê"));

          final order = snapshot.data!;
          final items = order.items ?? [];
          int productTotal = items.fold(0, (sum, item) => sum + (item.price * item.quantity));
          if (productTotal == 0) productTotal = order.totalPrice - order.shippingFee;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildOrderInfoCard(order),
                const SizedBox(height: 16),
                _buildAddressCard(order),
                const SizedBox(height: 16),
                _buildProductListCard(items),
                const SizedBox(height: 16),
                _buildPaymentCard(order, productTotal),
                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildOrderInfoCard(Order order) {
    final statusConfig = getStatusConfig(order.status);
    return OrderCardSection(
      children: [
        OrderInfoRow(label: "Mã đơn thuê", value: "#${order.id}", isBold: true),
        const Divider(height: 24, thickness: 0.5),
        OrderInfoRow(label: "Trạng thái", value: statusConfig['text'], valueColor: statusConfig['color'], isBold: true),
        if (order.createdAt.isNotEmpty) OrderInfoRow(label: "Ngày đặt", value: formatDate(order.createdAt)),
      ],
    );
  }

  Widget _buildAddressCard(Order order) {
    if (order.fullName == null || order.fullName!.isEmpty) return const SizedBox.shrink();
    return OrderCardSection(
      children: [
        const Text("Địa chỉ nhận hàng", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        Text("${order.fullName} | ${order.phoneNumber ?? ''}", style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
        const SizedBox(height: 4),
        Text(order.address ?? "Không có địa chỉ", style: const TextStyle(color: Colors.grey)),
      ],
    );
  }

  Widget _buildProductListCard(List<OrderItem> items) {
    return OrderCardSection(
      children: [
        const Text("Đồ đang thuê", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const Divider(height: 24, thickness: 0.5),
        if (items.isEmpty) const Center(child: Text("Không có sản phẩm", style: TextStyle(color: Colors.grey))),
        ...items.map((item) => _buildProductItem(item)),
      ],
    );
  }

  Widget _buildProductItem(OrderItem item) {
    // [FIX]: Tra cứu theo variantId thay vì productId
    final info = _getProductInfo(item.variantId ?? 0, item.productName);
    
    // Ưu tiên lấy trực tiếp link ảnh biến thể từ API chi tiết đơn hàng
    String rawImg = (item.imageUrl != null && item.imageUrl!.isNotEmpty) 
        ? item.imageUrl! 
        : (info['img'] ?? '');
    String finalImgUrl = _formatImageUrl(rawImg);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 70, height: 70,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade300)),
            clipBehavior: Clip.hardEdge,
            child: finalImgUrl.isNotEmpty 
                ? Image.network(
                    finalImgUrl, 
                    headers: const {"ngrok-skip-browser-warning": "true"},
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported, color: Colors.grey),
                  ) 
                : const Icon(Icons.shopping_bag_outlined, color: Colors.grey),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, 
              children: [
                Text(info['name']!, style: const TextStyle(fontWeight: FontWeight.w600), maxLines: 2, overflow: TextOverflow.ellipsis),
                if (item.color != null && item.color!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text("Màu sắc: ${item.color}", style: TextStyle(color: Colors.orange.shade700, fontSize: 12, fontWeight: FontWeight.w500)),
                ],
                const SizedBox(height: 4),
                Text("Số lượng: ${item.quantity}", style: const TextStyle(color: Colors.grey)),
              ]
            )
          ),
          Text(formatCurrency(item.price), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        ]
      ),
    );
  }

  Widget _buildPaymentCard(Order order, int productTotal) {
    int rentalAmount = order.rentalFee > 0 ? order.rentalFee : productTotal;
    int subTotal = rentalAmount + order.depositFee;
    return OrderCardSection(
      children: [
        OrderInfoRow(label: "Tiền thuê đồ", value: formatCurrency(rentalAmount)),
        OrderInfoRow(label: "Tiền cọc (Hoàn khi trả đồ)", value: formatCurrency(order.depositFee)),
        OrderInfoRow(label: "Tạm tính (Thuê + Cọc)", value: formatCurrency(subTotal), isBold: true),
        OrderInfoRow(label: "Phí vận chuyển", value: formatCurrency(order.shippingFee)),
        const Divider(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("Tổng thanh toán", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Text(formatCurrency(order.totalPrice), style: const TextStyle(color: AppColors.primaryOrange, fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
      ],
    );
  }
}
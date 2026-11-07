import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../resources/app_colors.dart';
import '../../Controller/order_controller.dart';
import '../../Controller/product_controller.dart';
import '../../Model/Order.dart';
import 'admin_order_detail_screen.dart';
import '../login_screen.dart';
import '../Widget/order_widgets.dart';

class AdminOrderListScreen extends StatefulWidget {
  const AdminOrderListScreen({super.key});

  @override
  State<AdminOrderListScreen> createState() => _AdminOrderListScreenState();
}

class _AdminOrderListScreenState extends State<AdminOrderListScreen> {
  final OrderController _orderController = OrderController();
  
  // Future chứa danh sách đơn hàng
  late Future<List<Order>> _ordersFuture;
  
  // Danh sách biến thể sản phẩm dùng để tra cứu tên và ảnh
  List<dynamic> _allVariants = [];

  // Các tab bộ lọc trạng thái
  final List<String> _tabs = ["All", "Chờ xử lý", "Chờ lấy hàng", "Lịch sử"];
  int _selectedIndex = 0;

  String _sortType = 'newest';
  bool isLoadingButtonCancel = false;

  @override
  void initState() {
    super.initState();
    // Tải danh sách đơn hàng và sản phẩm ngay khi vào màn hình
    _loadOrders();
    _loadProducts();
  }

  // Hàm tải lại danh sách đơn hàng
  void _loadOrders() {
    setState(() {
      _ordersFuture = _orderController.getAllOrdersAdmin();
    });
  }

  // Hàm tải danh sách sản phẩm
  void _loadProducts() async {
    try {
      final list = await ProductController.getAllProductVariants();
      if (mounted) {
        setState(() {
          _allVariants = list;
        });
      }
    } catch (e) {
      print("Lỗi tải danh sách sản phẩm: $e");
    }
  }

  // --- 1. CÁC HÀM HỖ TRỢ ---

  // Định dạng số tiền sang VNĐ
  String _formatMoney(int amount) => NumberFormat.currency(locale: 'vi_VN', symbol: 'đ').format(amount);

  // Định dạng ngày tháng
  String _formatDate(String dateString) {
    try {
      return DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(dateString));
    } catch (e) { return dateString; }
  }

  // Lấy màu sắc và chữ hiển thị cho badge trạng thái
  Map<String, dynamic> _getStatusConfig(String status) {
    switch (status.toLowerCase()) {
      case 'pending': 
        return {'text': "Chờ xử lý", 'color': Colors.blue, 'bg': const Color(0xFFE3F2FD)};
      case 'processing': 
        return {'text': "Đang chuẩn bị", 'color': Colors.deepPurple, 'bg': const Color(0xFFEEE5FF)};
      case 'shipping': 
        return {'text': "Đang giao", 'color': Colors.orange, 'bg': const Color(0xFFFFF3E0)};
      case 'delivered': 
        return {'text': "Đã giao", 'color': Colors.green, 'bg': const Color(0xFFE8F5E9)};
      case 'cancelled': 
        return {'text': "Đã hủy", 'color': Colors.red, 'bg': const Color(0xFFFFEBEE)};
      default: 
        return {'text': status, 'color': Colors.black, 'bg': Colors.grey.shade200};
    }
  }

  // Tạo chuỗi tóm tắt sản phẩm
  String _generateProductSummary(List<OrderItem> items) {
    List<String> productNames = [];
    for (var item in items) {
      String name = item.productName; // Tên mặc định
      
      // Tìm tên thật trong danh sách đã tải
      if (_allVariants.isNotEmpty) {
        for (var v in _allVariants) {
          if ((v as dynamic).id.toString() == item.productId.toString()) {
            name = v.name ?? name;
            break;
          }
        }
      }
      productNames.add("- $name (x${item.quantity})");
    }
    
    // Chỉ lấy 3 dòng đầu tiên, còn lại hiển thị "..."
    String summary = productNames.take(3).join("\n");
    if (productNames.length > 3) {
      summary += "\n... và ${productNames.length - 3} sản phẩm khác";
    }
    return summary;
  }

  // --- 2. GIAO DIỆN ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text("Quản trị đơn hàng", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primaryOrange,
        centerTitle: true,
        automaticallyImplyLeading: false, // Ẩn nút back mặc định
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort, color: Colors.white),
            tooltip: "Sắp xếp đơn hàng",
            onSelected: (value) {
              setState(() {
                _sortType = value; // Cập nhật trạng thái sắp xếp
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'newest',
                child: Row(
                  children: [
                    Icon(Icons.arrow_downward, color: Colors.orange, size: 20),
                    SizedBox(width: 8),
                    Text("Mới nhất trước"),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'oldest',
                child: Row(
                  children: [
                    Icon(Icons.arrow_upward, color: Colors.grey, size: 20),
                    SizedBox(width: 8),
                    Text("Cũ nhất trước"),
                  ],
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.power_settings_new, color: Colors.white),
            onPressed: () => Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (route) => false),
          ),
        ],
      ),

      body: Column(
        children: [
        _buildFilterBar(),

          // Danh sách đơn hàng
          Expanded(
            child: FutureBuilder<List<Order>>(
              future: _ordersFuture,
              builder: (context, snapshot) {
                // Đang tải
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                // Không có dữ liệu
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text("Không có đơn hàng nào"));
                }

                // Lọc danh sách theo Tab đang chọn
                List<Order> allOrders = snapshot.data!;
                List<Order> filteredOrders = [];

                if (_selectedIndex == 0) { // All
                  filteredOrders = allOrders;
                } else if (_selectedIndex == 1) { // Chờ xử lý
                  filteredOrders = allOrders.where((o) => o.status == 'pending').toList();
                } else if (_selectedIndex == 2) { // Chờ lấy hàng
                  filteredOrders = allOrders.where((o) => ['processing', 'shipping'].contains(o.status)).toList();
                } else { // Lịch sử (Đã giao/Hủy)
                  filteredOrders = allOrders.where((o) => ['delivered', 'cancelled'].contains(o.status)).toList();
                }

                if (filteredOrders.isEmpty) {
                   return const Center(child: Text("Trống"));
                }

                filteredOrders.sort((a, b) {
                  // Parse chuỗi ngày tháng sang DateTime để so sánh
                  DateTime? dateA = DateTime.tryParse(a.createdAt);
                  DateTime? dateB = DateTime.tryParse(b.createdAt);

                  // Xử lý trường hợp ngày lỗi
                  dateA ??= DateTime(1970);
                  dateB ??= DateTime(1970);

                  if (_sortType == 'newest') {
                    return dateB.compareTo(dateA); // Giảm dần (Mới nhất lên đầu)
                  } else {
                    return dateA.compareTo(dateB); // Tăng dần (Cũ nhất lên đầu)
                  }
                });

                // Hiển thị danh sách (có tính năng kéo để refresh)
                return RefreshIndicator(
                  onRefresh: () async {
                    _loadOrders();
                    _loadProducts();
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredOrders.length,
                    itemBuilder: (context, index) {
                      return _buildOrderCard(filteredOrders[index]);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // --- 3. CÁC WIDGET CON ---

  // Widget thanh lọc trạng thái ngang
  Widget _buildFilterBar() {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16), 
        child: Row(
          children: List.generate(_tabs.length, (index) {
            bool isSelected = _selectedIndex == index;
            return GestureDetector(
              onTap: () => setState(() => _selectedIndex = index),
              child: Container(
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primaryOrange : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _tabs[index],
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.black87,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 13,
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  // Thẻ hiển thị tóm tắt 1 đơn hàng
  Widget _buildOrderCard(Order order) {
    final statusConfig = _getStatusConfig(order.status);

    return OrderListCard(
      onTap: () async {
        // Mở trang chi tiết
        final result = await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => AdminOrderDetailScreen(order: order)),
        );
        // Reload lại list nếu có thay đổi trong trang chi tiết
        if (result == true) _loadOrders(); 
      },
      child: Column(
        children: [
          // Dòng 1: ID đơn hàng và Badge trạng thái
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Đơn #${order.id}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(color: statusConfig['bg'], borderRadius: BorderRadius.circular(12)),
                child: Text(statusConfig['text'], style: TextStyle(color: statusConfig['color'], fontWeight: FontWeight.bold, fontSize: 12)),
              ),
            ],
          ),
          const Divider(height: 12),
          
          // Dòng 2: Tên khách hàng
          OrderInfoRow(
            label: "Khách hàng", 
            value: order.fullName ?? "Khách lẻ", 
            isBold: true
          ),
          
          const Divider(height: 12),
          
          // Dòng 3: Danh sách sản phẩm
          // Nếu đã có list sản phẩm -> Hiển thị luôn
          // Nếu chưa -> Gọi API chi tiết ngay tại đây (Lazy Loading)
          (order.items != null && order.items!.isNotEmpty)
            ? OrderInfoRow(
                label: "Sản phẩm", 
                value: _generateProductSummary(order.items!), 
                alignTop: true
              )
            : FutureBuilder<Order?>(
                future: _orderController.getOrderDetail(order.id),
                builder: (context, snapshot) {
                  if (snapshot.hasData && snapshot.data!.items != null) {
                    return OrderInfoRow(
                      label: "Sản phẩm", 
                      value: _generateProductSummary(snapshot.data!.items!), 
                      alignTop: true
                    );
                  }
                  return const OrderInfoRow(
                    label: "Sản phẩm", 
                    value: "Đang tải...", 
                    alignTop: true
                  );
                },
              ),

          const Divider(height: 12),
          
          // Dòng 4: Tổng tiền
          OrderInfoRow(
            label: "Tổng tiền", 
            value: _formatMoney(order.totalPrice), 
            valueColor: Colors.orange, 
            isBold: true
          ),
          
          const Divider(height: 12),
          
          // Dòng 5: Ngày đặt hàng
          OrderInfoRow(
            label: "Ngày đặt", 
            value: _formatDate(order.createdAt)
          ),
        ],
      ),
    );
  }
}
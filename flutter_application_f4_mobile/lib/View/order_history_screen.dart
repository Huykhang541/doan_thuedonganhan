// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
// import '../../resources/app_colors.dart';
// import '../../Controller/order_controller.dart';
// import '../../Controller/product_controller.dart';
// import '../../Model/Order.dart';
// import 'order_detail_screen.dart';
// import 'Widget/order_widgets.dart';

// class OrderHistoryScreen extends StatefulWidget {
//   const OrderHistoryScreen({super.key});

//   @override
//   State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
// }

// class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
//   final OrderController _orderController = OrderController();
//   late Future<List<Order>> _ordersFuture;
//   List<dynamic> _allVariants = [];

//   final List<String> _filters = ["Tất cả", "Chờ xác nhận", "Đang giao", "Đang thuê", "Đã hủy"];
//   String _selectedFilter = "Tất cả";
//   String _sortType = 'newest';
//   bool isLoadingButtonCancel = false;

//   @override
//   void initState() {
//     super.initState();
//     _ordersFuture = _orderController.getOrderHistory();
//     _loadProductList();
//   }

//   void _loadProductList() async {
//     try {
//       final list = await ProductController.getAllProductVariants();
//       if (mounted) setState(() => _allVariants = list);
//     } catch (e) { print(e); }
//   }

//   String formatCurrency(int amount) => NumberFormat.currency(locale: 'vi_VN', symbol: 'đ').format(amount);
//   String formatDate(String dateString) {
//     try { 
//       // 1. Chuẩn hóa chuỗi ngày tháng từ API (đổi khoảng trắng thành 'T' theo chuẩn ISO)
//       String normalizedDate = dateString.replaceAll(' ', 'T');
      
//       // 2. Ép Dart hiểu đây là giờ quốc tế UTC bằng cách thêm 'Z' ở cuối (nếu chưa có)
//       if (!normalizedDate.endsWith('Z')) {
//         normalizedDate += 'Z';
//       }
      
//       // 3. Parse sang DateTime và gọi .toLocal() để cộng bù lại 7 tiếng (Múi giờ VN)
//       DateTime parsedDate = DateTime.parse(normalizedDate).toLocal();
      
//       return DateFormat('dd/MM/yyyy HH:mm').format(parsedDate); 
//     } 
//     catch (e) { 
//       return dateString; 
//     }
//   }

//   // ĐÃ ĐỒNG BỘ MAP STATUS ĐỂ LỌC TAB KHÔNG BỊ TRỐNG
//   Map<String, dynamic> getStatusConfig(String status) {
//     String st = status.toLowerCase().trim();
//     switch (st) {
//       case 'cho_duyet':
//       case 'pending': return {'text': 'Chờ xác nhận', 'color': Colors.blue};
//       case 'processing':
//       case 'confirmed': return {'text': 'Chủ đồ đã duyệt', 'color': Colors.deepPurple};
//       case 'shipping': return {'text': 'Đang giao', 'color': Colors.orange};
//       case 'delivered':
//       case 'completed': return {'text': 'Đang thuê', 'color': Colors.green};
//       case 'cancelled':
//       case 'da_huy': return {'text': 'Đã hủy', 'color': Colors.red};
//       default: return {'text': status, 'color': Colors.grey};
//     }
//   }

//   Map<String, String?> _getProductInfo(int id, String defaultName) {
//     String name = defaultName;
//     String? img;
//     if (_allVariants.isNotEmpty) {
//       for (var variant in _allVariants) {
//         try {
//            if (variant.id.toString() == id.toString()) {
//               name = variant.name ?? name;
//               img = variant.imageUrl;
//               break;
//            }
//         } catch(e) {
//            if (variant['id'].toString() == id.toString()) {
//               name = variant['name'] ?? name;
//               img = variant['imageUrl'] ?? variant['image'];
//               break;
//            }
//         }
//       }
//     }
//     return {'name': name, 'img': img};
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFF5F5F5),
//       appBar: AppBar(
//         title: const Text("Lịch sử thuê đồ", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
//         backgroundColor: AppColors.primaryOrange,
//         centerTitle: true,
//         leading: IconButton(icon: const Icon(Icons.arrow_back_ios, color: Colors.white), onPressed: () => Navigator.pop(context)),
//       ),
      
//       body: Column(
//         children: [
//           _buildFilterBar(),
//           Expanded(
//             child: FutureBuilder<List<Order>>(
//               future: _ordersFuture,
//               builder: (context, snapshot) {
//                 if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
//                 if (!snapshot.hasData || snapshot.data!.isEmpty) return const Center(child: Text("Bạn chưa thuê món đồ nào"));

//                 final allOrders = snapshot.data!;
                
//                 // LỌC ĐƠN HÀNG SAU KHI ĐÃ ĐỒNG BỘ TEXT
//                 List<Order> displayedOrders;
//                 if (_selectedFilter == "Tất cả") {
//                   displayedOrders = allOrders;
//                 } else {
//                   displayedOrders = allOrders.where((order) {
//                     String statusText = getStatusConfig(order.status)['text'];
//                     if (_selectedFilter == "Chờ xác nhận") {
//                       return statusText == "Chờ xác nhận" || statusText == "Chủ đồ đã duyệt";
//                     }
//                     return statusText == _selectedFilter;
//                   }).toList();
//                 }

//                 displayedOrders.sort((a, b) {
//                   DateTime dateA = DateTime.tryParse(a.createdAt) ?? DateTime(1970);
//                   DateTime dateB = DateTime.tryParse(b.createdAt) ?? DateTime(1970);
//                   return _sortType == 'newest' ? dateB.compareTo(dateA) : dateA.compareTo(dateB);
//                 });

//                 if (displayedOrders.isEmpty) return Center(child: Text("Không có đơn ở mục '$_selectedFilter'"));

//                 return RefreshIndicator(
//                   onRefresh: () async {
//                     setState(() => _ordersFuture = _orderController.getOrderHistory());
//                     _loadProductList(); 
//                   },
//                   child: ListView.builder(
//                     padding: const EdgeInsets.all(12),
//                     itemCount: displayedOrders.length,
//                     itemBuilder: (context, index) => _buildOrderCard(displayedOrders[index]),
//                   ),
//                 );
//               },
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildFilterBar() {
//     return Container(
//       width: double.infinity, color: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12),
//       child: SingleChildScrollView(
//         scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 16),
//         child: Row(
//           children: _filters.map((filter) {
//             final isSelected = _selectedFilter == filter;
//             return GestureDetector(
//               onTap: () => setState(() => _selectedFilter = filter),
//               child: Container(
//                 margin: const EdgeInsets.only(right: 12), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//                 decoration: BoxDecoration(color: isSelected ? AppColors.primaryOrange : Colors.grey.shade200, borderRadius: BorderRadius.circular(20)),
//                 child: Text(filter, style: TextStyle(color: isSelected ? Colors.white : Colors.black, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, fontSize: 13)),
//               ),
//             );
//           }).toList(),
//         ),
//       ),
//     );
//   }

//   Widget _buildOrderCard(Order order) {
//     final statusConfig = getStatusConfig(order.status);
//     return OrderListCard(
//       onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => OrderDetailScreen(orderId: order.id))),
//       child: Column(
//         children: [
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               Padding(padding: const EdgeInsets.only(bottom: 12), child: Text("Ngày tạo: ${formatDate(order.createdAt)}")),
//               Padding(padding: const EdgeInsets.only(bottom: 12), child: Text(statusConfig['text'], style: TextStyle(color: statusConfig['color'], fontWeight: FontWeight.bold, fontSize: 13))),
//             ],
//           ),
//           const Divider(height: 1, thickness: 0.5),
//           Column(
//             children: [
//               if (order.items != null && order.items!.isNotEmpty)
//                 ...order.items!.map((item) => _buildProductItem(item)).toList()
//               else
//                 // SỬA LỖI BỊ KẸT CHỮ ĐANG TẢI ĐỒ Ở ĐÂY
//                 FutureBuilder<Order?>(
//                   future: _orderController.getOrderDetail(order.id),
//                   builder: (context, snapshot) {
//                     if (snapshot.connectionState == ConnectionState.waiting) {
//                       return const Padding(padding: EdgeInsets.all(16), child: Text("Đang tải đồ...", style: TextStyle(color: Colors.grey)));
//                     }
//                     if (snapshot.hasData && snapshot.data!.items != null && snapshot.data!.items!.isNotEmpty) {
//                       return Column(children: snapshot.data!.items!.map((item) => _buildProductItem(item)).toList());
//                     }
//                     return const Padding(padding: EdgeInsets.all(16), child: Text("Bấm để xem chi tiết đồ thuê", style: TextStyle(color: Colors.grey)));
//                   },
//                 ),
//             ],
//           ),
//           Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 12),
//             child: Column(
//               children: [
//                 const Divider(height: 1, thickness: 0.5),
//                 const SizedBox(height: 12),
//                 OrderInfoRow(label: "Tổng tiền (Thuê + Cọc):", value: formatCurrency(order.totalPrice), isBold: true, valueColor: AppColors.primaryOrange),
//                 const SizedBox(height: 12),
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.end,
//                   children: [
//                     if (['cho_duyet', 'pending'].contains(order.status.toLowerCase().trim()))
//                       OrderSmallButton(
//                         text: "Hủy đặt đồ", color: Colors.white, textColor: Colors.black, isOutlined: true,
//                         onPressed: isLoadingButtonCancel ? null : () {
//                           showDialog(
//                             context: context,
//                             builder: (ctx) => AlertDialog(
//                               title: const Text("Xác nhận hủy"),
//                               content: const Text("Bạn có chắc chắn muốn hủy đơn thuê này không?"),
//                               actions: [
//                                 TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text("Không")),
//                                 TextButton(
//                                   onPressed: () async {
//                                     Navigator.of(ctx).pop();
//                                     setState(() => isLoadingButtonCancel = true);
//                                     bool succeeded = await OrderController().cancelOrder(order.id);
//                                     if (!mounted) return;
//                                     if (succeeded) {
//                                       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Hủy thành công")));
//                                       setState(() { isLoadingButtonCancel = false; _ordersFuture = _orderController.getOrderHistory(); });
//                                     } else {
//                                       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Hủy thất bại"), backgroundColor: Colors.red));
//                                       setState(() => isLoadingButtonCancel = false);
//                                     }
//                                   },
//                                   child: const Text("Đồng ý", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
//                                 ),
//                               ],
//                             ),
//                           );
//                         },
//                       ),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildProductItem(OrderItem item) {
//     final info = _getProductInfo(item.productId, item.productName);
//     return Padding(
//       padding: const EdgeInsets.all(12),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Container(
//             width: 70, height: 70,
//             decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade200), borderRadius: BorderRadius.circular(4)),
//             clipBehavior: Clip.hardEdge,
//             child: (info['img'] != null && info['img']!.isNotEmpty)
//                 ? Image.network(info['img']!, fit: BoxFit.cover, errorBuilder: (c, e, s) => const Icon(Icons.shopping_bag_outlined, color: Colors.grey))
//                 : const Icon(Icons.shopping_bag_outlined, color: Colors.grey),
//           ),
//           const SizedBox(width: 12),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(info['name']!, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15)),
//                 const SizedBox(height: 4),
//                 Text("Số lượng: ${item.quantity}", style: const TextStyle(color: Colors.grey)),
//               ],
//             ),
//           ),
//           Text(formatCurrency(item.price), style: const TextStyle(fontWeight: FontWeight.w500)),
//         ],
//       ),
//     );
//   }
// }







import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../resources/app_colors.dart';
import '../../Controller/order_controller.dart';
import '../../Controller/product_controller.dart';
import '../../Model/Order.dart';
import '../../Config/baseUrl.dart';
import 'order_detail_screen.dart';
import 'Widget/order_widgets.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  final OrderController _orderController = OrderController();
  late Future<List<Order>> _ordersFuture;
  List<dynamic> _allVariants = [];

  final List<String> _filters = ["Tất cả", "Chờ xác nhận", "Đang giao", "Đang thuê", "Đã hủy"];
  String _selectedFilter = "Tất cả";
  String _sortType = 'newest';
  bool isLoadingButtonCancel = false;

  @override
  void initState() {
    super.initState();
    _ordersFuture = _orderController.getOrderHistory();
    _loadProductList();
  }

  void _loadProductList() async {
    try {
      final list = await ProductController.getAllProductVariants();
      if (mounted) setState(() => _allVariants = list);
    } catch (e) { print(e); }
  }

  // [FIX]: Đồng bộ hàm chuẩn hóa link ảnh giống order_detail_screen.dart
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
  
  String formatDate(String dateString) {
    try { 
      String normalizedDate = dateString.replaceAll(' ', 'T');
      if (!normalizedDate.endsWith('Z')) {
        normalizedDate += 'Z';
      }
      DateTime parsedDate = DateTime.parse(normalizedDate).toLocal();
      return DateFormat('dd/MM/yyyy HH:mm').format(parsedDate); 
    } 
    catch (e) { 
      return dateString; 
    }
  }

  Map<String, dynamic> getStatusConfig(String status) {
    String st = status.toLowerCase().trim();
    switch (st) {
      case 'cho_duyet':
      case 'pending': return {'text': 'Chờ xác nhận', 'color': Colors.blue};
      case 'processing':
      case 'confirmed': return {'text': 'Chủ đồ đã duyệt', 'color': Colors.deepPurple};
      case 'shipping': return {'text': 'Đang giao', 'color': Colors.orange};
      case 'delivered':
      case 'completed': return {'text': 'Đang thuê', 'color': Colors.green};
      case 'cancelled':
      case 'da_huy': return {'text': 'Đã hủy', 'color': Colors.red};
      default: return {'text': status, 'color': Colors.grey};
    }
  }

  // [FIX]: Tra cứu theo targetVariantId thay vì productId
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
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text("Lịch sử thuê đồ", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primaryOrange,
        centerTitle: true,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios, color: Colors.white), onPressed: () => Navigator.pop(context)),
      ),
      
      body: Column(
        children: [
          _buildFilterBar(),
          Expanded(
            child: FutureBuilder<List<Order>>(
              future: _ordersFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                if (!snapshot.hasData || snapshot.data!.isEmpty) return const Center(child: Text("Bạn chưa thuê món đồ nào"));

                final allOrders = snapshot.data!;
                
                List<Order> displayedOrders;
                if (_selectedFilter == "Tất cả") {
                  displayedOrders = allOrders;
                } else {
                  displayedOrders = allOrders.where((order) {
                    String statusText = getStatusConfig(order.status)['text'];
                    if (_selectedFilter == "Chờ xác nhận") {
                      return statusText == "Chờ xác nhận" || statusText == "Chủ đồ đã duyệt";
                    }
                    return statusText == _selectedFilter;
                  }).toList();
                }

                displayedOrders.sort((a, b) {
                  DateTime dateA = DateTime.tryParse(a.createdAt) ?? DateTime(1970);
                  DateTime dateB = DateTime.tryParse(b.createdAt) ?? DateTime(1970);
                  return _sortType == 'newest' ? dateB.compareTo(dateA) : dateA.compareTo(dateB);
                });

                if (displayedOrders.isEmpty) return Center(child: Text("Không có đơn ở mục '$_selectedFilter'"));

                return RefreshIndicator(
                  onRefresh: () async {
                    setState(() => _ordersFuture = _orderController.getOrderHistory());
                    _loadProductList(); 
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: displayedOrders.length,
                    itemBuilder: (context, index) => _buildOrderCard(displayedOrders[index]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      width: double.infinity, color: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: _filters.map((filter) {
            final isSelected = _selectedFilter == filter;
            return GestureDetector(
              onTap: () => setState(() => _selectedFilter = filter),
              child: Container(
                margin: const EdgeInsets.only(right: 12), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(color: isSelected ? AppColors.primaryOrange : Colors.grey.shade200, borderRadius: BorderRadius.circular(20)),
                child: Text(filter, style: TextStyle(color: isSelected ? Colors.white : Colors.black, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, fontSize: 13)),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildOrderCard(Order order) {
    final statusConfig = getStatusConfig(order.status);
    return OrderListCard(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => OrderDetailScreen(orderId: order.id))),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Padding(padding: const EdgeInsets.only(bottom: 12), child: Text("Ngày tạo: ${formatDate(order.createdAt)}")),
              Padding(padding: const EdgeInsets.only(bottom: 12), child: Text(statusConfig['text'], style: TextStyle(color: statusConfig['color'], fontWeight: FontWeight.bold, fontSize: 13))),
            ],
          ),
          const Divider(height: 1, thickness: 0.5),
          Column(
            children: [
              if (order.items != null && order.items!.isNotEmpty)
                ...order.items!.map((item) => _buildProductItem(item)).toList()
              else
                FutureBuilder<Order?>(
                  future: _orderController.getOrderDetail(order.id),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Padding(padding: EdgeInsets.all(16), child: Text("Đang tải đồ...", style: TextStyle(color: Colors.grey)));
                    }
                    if (snapshot.hasData && snapshot.data!.items != null && snapshot.data!.items!.isNotEmpty) {
                      return Column(children: snapshot.data!.items!.map((item) => _buildProductItem(item)).toList());
                    }
                    return const Padding(padding: EdgeInsets.all(16), child: Text("Bấm để xem chi tiết đồ thuê", style: TextStyle(color: Colors.grey)));
                  },
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              children: [
                const Divider(height: 1, thickness: 0.5),
                const SizedBox(height: 12),
                OrderInfoRow(label: "Tổng tiền (Thuê + Cọc):", value: formatCurrency(order.totalPrice), isBold: true, valueColor: AppColors.primaryOrange),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (['cho_duyet', 'pending'].contains(order.status.toLowerCase().trim()))
                      OrderSmallButton(
                        text: "Hủy đặt đồ", color: Colors.white, textColor: Colors.black, isOutlined: true,
                        onPressed: isLoadingButtonCancel ? null : () {
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text("Xác nhận hủy"),
                              content: const Text("Bạn có chắc chắn muốn hủy đơn thuê này không?"),
                              actions: [
                                TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text("Không")),
                                TextButton(
                                  onPressed: () async {
                                    Navigator.of(ctx).pop();
                                    setState(() => isLoadingButtonCancel = true);
                                    bool succeeded = await OrderController().cancelOrder(order.id);
                                    if (!mounted) return;
                                    if (succeeded) {
                                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Hủy thành công")));
                                      setState(() { isLoadingButtonCancel = false; _ordersFuture = _orderController.getOrderHistory(); });
                                    } else {
                                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Hủy thất bại"), backgroundColor: Colors.red));
                                      setState(() => isLoadingButtonCancel = false);
                                    }
                                  },
                                  child: const Text("Đồng ý", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductItem(OrderItem item) {
    // [FIX]: Đồng bộ hoàn toàn cách lấy ảnh và màu sắc với order_detail_screen.dart
    final info = _getProductInfo(item.variantId ?? 0, item.productName);
    
    String rawImg = (item.imageUrl != null && item.imageUrl!.isNotEmpty) 
        ? item.imageUrl! 
        : (info['img'] ?? '');
    String finalImgUrl = _formatImageUrl(rawImg);

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 70, height: 70,
            decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade200), borderRadius: BorderRadius.circular(4)),
            clipBehavior: Clip.hardEdge,
            child: finalImgUrl.isNotEmpty
                ? Image.network(
                    finalImgUrl, 
                    headers: const {"ngrok-skip-browser-warning": "true"},
                    fit: BoxFit.cover, 
                    errorBuilder: (c, e, s) => const Icon(Icons.shopping_bag_outlined, color: Colors.grey)
                  )
                : const Icon(Icons.shopping_bag_outlined, color: Colors.grey),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(info['name']!, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15)),
                if (item.color != null && item.color!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text("Màu sắc: ${item.color}", style: TextStyle(color: Colors.orange.shade700, fontSize: 12, fontWeight: FontWeight.w500)),
                ],
                const SizedBox(height: 4),
                Text("Số lượng: ${item.quantity}", style: const TextStyle(color: Colors.grey)),
              ],
            ),
          ),
          Text(formatCurrency(item.price), style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
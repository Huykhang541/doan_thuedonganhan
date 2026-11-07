// import 'package:flutter/material.dart';
// import 'package:flutter_application_f4_mobile/Model/cartModel.dart';
// import 'package:flutter_application_f4_mobile/Model/product_model.dart';
// import 'package:flutter_application_f4_mobile/View/checkout_screen.dart';
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
  
//   // Future chứa danh sách đơn hàng
//   late Future<List<Order>> _ordersFuture;
  
//   // Danh sách biến thể sản phẩm dùng để tra cứu tên và ảnh
//   List<dynamic> _allVariants = [];

//   // Các tab bộ lọc trạng thái
//   final List<String> _filters = ["Tất cả", "Chờ xác nhận", "Đang giao", "Đã giao thành công", "Đã hủy"];
//   String _selectedFilter = "Tất cả";

//   String _sortType = 'newest';
//   bool isLoadingButtonCancel = false;


//   @override
//   void initState() {
//     super.initState();
//     // Gọi API lấy danh sách đơn hàng ngay khi màn hình mở
//     _ordersFuture = _orderController.getOrderHistory();

//     // Tải danh sách sản phẩm chạy ngầm
//     _loadProductList();
//   }

//   // Hàm tải danh sách sản phẩm từ server
//   void _loadProductList() async {
//     try {
//       final list = await ProductController.getAllProductVariants();
//       if (mounted) {
//         setState(() {
//           _allVariants = list;
//         });
//       }
//     } catch (e) {
//       print("Lỗi tải danh sách sản phẩm: $e");
//     }
//   }

//   // --- 1. CÁC HÀM HỖ TRỢ ---

//     // Định dạng số tiền sang VNĐ
//   String formatCurrency(int amount) {
//     return NumberFormat.currency(locale: 'vi_VN', symbol: 'đ').format(amount);
//   }

//   // Định dạng ngày tháng
//   String formatDate(String dateString) {
//     try {
//       return DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(dateString));
//     } catch (e) {
//       return dateString;
//     }
//   }

//   // Cấu hình màu sắc và chữ hiển thị cho trạng thái đơn hàng
//   Map<String, dynamic> getStatusConfig(String status) {
//     switch (status.toLowerCase()) {
//       case 'pending':
//         return {'text': 'Chờ xác nhận', 'color': Colors.blue};
//       case 'processing':
//         return {'text': 'Đang chuẩn bị', 'color': Colors.deepPurple};
//       case 'shipping':
//         return {'text': 'Đang giao', 'color': Colors.orange};
//       case 'delivered':
//         return {'text': 'Đã giao thành công', 'color': Colors.green};
//       case 'cancelled':
//         return {'text': 'Đã hủy', 'color': Colors.red};
//       default:
//         return {'text': status, 'color': Colors.grey};
//     }
//   }

//   // Tìm tên và ảnh thật của sản phẩm dựa vào ID
//   Map<String, String?> _getProductInfo(int id, String defaultName) {
//     String name = defaultName;
//     String? img;
//     String? variantsInfo;

//     if (_allVariants.isNotEmpty) {
//       for (var v in _allVariants) {
//         final variant = v as dynamic; 
        
//         if (variant.id.toString() == id.toString()) {
//           name = variant.name ?? name;
//           img = variant.imageUrl;
//           List<String> details = [];
//           if (variant.color != null && variant.color!.isNotEmpty) {
//             details.add(variant.color!);
//           }
//           if (variant.storage != null && variant.storage!.isNotEmpty) {
//             details.add(variant.storage!);
//           }
          
//           if (details.isNotEmpty) {
//             variantsInfo = details.join(" - ");
//           }
//           break;
//         }
//       }
//     }
//     return {'name': name, 'img': img, 'variant': variantsInfo};
//   }

//   // --- 2. GIAO DIỆN ---
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFF5F5F5),
//       appBar: AppBar(
//         title: const Text(
//           "Lịch sử đơn hàng",
//           style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
//         ),
//         backgroundColor: AppColors.primaryOrange,
//         centerTitle: true,
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
//           onPressed: () => Navigator.pop(context),
//         ),
//         actions: [
//           PopupMenuButton<String>(
//             icon: const Icon(Icons.sort, color: Colors.white),
//             tooltip: "Sắp xếp đơn hàng",
//             onSelected: (value) {
//               setState(() {
//                 _sortType = value;
//               });
//             },
//             itemBuilder: (context) => [
//               const PopupMenuItem(
//                 value: 'newest',
//                 child: Row(
//                   children: [
//                     Icon(Icons.arrow_downward, color: Colors.orange, size: 20),
//                     SizedBox(width: 8),
//                     Text("Mới nhất trước"),
//                   ],
//                 ),
//               ),
//               const PopupMenuItem(
//                 value: 'oldest',
//                 child: Row(
//                   children: [
//                     Icon(Icons.arrow_upward, color: Colors.grey, size: 20),
//                     SizedBox(width: 8),
//                     Text("Cũ nhất trước"),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ],
//       ),
      
//       body: Column(
//         children: [
//           // Thanh lọc trạng thái (Tab bar)
//           _buildFilterBar(),
          
//           // Danh sách đơn hàng
//           Expanded(
//             child: FutureBuilder<List<Order>>(
//               future: _ordersFuture,
//               builder: (context, snapshot) {
//                 // Đang tải
//                 if (snapshot.connectionState == ConnectionState.waiting) {
//                   return const Center(child: CircularProgressIndicator());
//                 }
                
//                 // Không có dữ liệu
//                 if (!snapshot.hasData || snapshot.data!.isEmpty) {
//                   return const Center(child: Text("Bạn chưa có đơn hàng nào"));
//                 }

//                 final allOrders = snapshot.data!;
//                 List<Order> displayedOrders;

//                 // Lọc đơn hàng theo tab đang chọn
//                 if (_selectedFilter == "Tất cả") {
//                   displayedOrders = allOrders;
//                 } else {
//                   displayedOrders = allOrders.where((order) {
//                     final config = getStatusConfig(order.status);
//                     return config['text'] == _selectedFilter;
//                   }).toList();
//                 }

//                 displayedOrders.sort((a, b) {
//                   // Parse chuỗi ngày tháng sang DateTime để so sánh
//                   DateTime? dateA = DateTime.tryParse(a.createdAt);
//                   DateTime? dateB = DateTime.tryParse(b.createdAt);

//                   // Xử lý trường hợp ngày lỗi
//                   dateA ??= DateTime(1970);
//                   dateB ??= DateTime(1970);

//                   if (_sortType == 'newest') {
//                     return dateB.compareTo(dateA); // Giảm dần (Mới nhất lên đầu)
//                   } else {
//                     return dateA.compareTo(dateB); // Tăng dần (Cũ nhất lên đầu)
//                   }
//                 });

//                 // Nếu tab hiện tại không có đơn nào
//                 if (displayedOrders.isEmpty) {
//                   return Center(child: Text("Không có đơn hàng ở mục '$_selectedFilter'"));
//                 }

//                 // Hiển thị danh sách kết quả
//                 return RefreshIndicator(
//                   onRefresh: () async {
//                     setState(() {
//                       _ordersFuture = _orderController.getOrderHistory();
//                     });
//                     _loadProductList(); // Tải lại sản phẩm khi refresh
//                   },
//                   child: ListView.builder(
//                     padding: const EdgeInsets.all(12),
//                     itemCount: displayedOrders.length,
//                     itemBuilder: (context, index) {
//                       return _buildOrderCard(displayedOrders[index]);
//                     },
//                   ),
//                 );
//               },
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   // --- 3. CÁC WIDGET CON ---

//   // Widget thanh lọc trạng thái ngang
//   Widget _buildFilterBar() {
//     return Container(
//       width: double.infinity,
//       color: Colors.white,
//       padding: const EdgeInsets.symmetric(vertical: 12),
//       child: SingleChildScrollView(
//         scrollDirection: Axis.horizontal,
//         padding: const EdgeInsets.symmetric(horizontal: 16),
//         child: Row(
//           children: _filters.map((filter) {
//             final isSelected = _selectedFilter == filter;
//             return GestureDetector(
//               onTap: () {
//                 setState(() {
//                   _selectedFilter = filter;
//                 });
//               },
//               child: Container(
//                 margin: const EdgeInsets.only(right: 12),
//                 padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//                 decoration: BoxDecoration(
//                   color: isSelected ? AppColors.primaryOrange : Colors.grey.shade200,
//                   borderRadius: BorderRadius.circular(20),
//                 ),
//                 child: Text(
//                   filter,
//                   style: TextStyle(
//                     color: isSelected ? Colors.white : Colors.black,
//                     fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
//                     fontSize: 13,
//                   ),
//                 ),
//               ),
//             );
//           }).toList(),
//         ),
//       ),
//     );
//   }

//   // Widget hiển thị 1 thẻ đơn hàng
//   Widget _buildOrderCard(Order order) {
//     final statusConfig = getStatusConfig(order.status);

//     return OrderListCard(
//       onTap: () {
//         Navigator.push(
//           context,
//           MaterialPageRoute(builder: (_) => OrderDetailScreen(orderId: order.id)),
//         );
//       },
//       child: Column(
//         children: [
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               Padding(
//                 padding: const EdgeInsets.only(bottom: 12),
//                 child: Row(
//                   mainAxisAlignment: MainAxisAlignment.end,
//                   children: [
//                     Text("Ngày tạo đơn: ${formatDate(order.createdAt)}"),
//                   ],
//                 ),
//               ),
//               // Header: Trạng thái
//               Padding(
//                 padding: const EdgeInsets.only(bottom: 12),
//                 child: Row(
//                   mainAxisAlignment: MainAxisAlignment.end,
//                   children: [
//                     Text(
//                       statusConfig['text'],
//                       style: TextStyle(
//                         color: statusConfig['color'],
//                         fontWeight: FontWeight.bold,
//                         fontSize: 13,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//           const Divider(height: 1, thickness: 0.5),

//           // Body: Danh sách sản phẩm
//           Column(
//             children: [
//               // Logic hiển thị sản phẩm:
//               // Nếu đã có items -> Hiển thị ngay
//               if (order.items != null && order.items!.isNotEmpty)
//                 ...order.items!.map((item) => _buildProductItem(item)).toList()
//               else
//                 // Nếu chưa có items -> Gọi API chi tiết (Lazy Loading)
//                 FutureBuilder<Order?>(
//                   future: _orderController.getOrderDetail(order.id),
//                   builder: (context, snapshot) {
//                     if (snapshot.hasData && snapshot.data!.items != null) {
//                       return Column(
//                         children: snapshot.data!.items!.map((item) => _buildProductItem(item)).toList(),
//                       );
//                     }
//                     // Trạng thái chờ
//                     return const Padding(
//                       padding: EdgeInsets.all(20),
//                       child: Text("Đang tải thông tin sản phẩm...", style: TextStyle(color: Colors.grey)),
//                     );
//                   },
//                 ),
//             ],
//           ),

//           // Footer: Tổng tiền và nút bấm
//           Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 12),
//             child: Column(
//               children: [
//                 const Divider(height: 1, thickness: 0.5),
//                 const SizedBox(height: 12),
                
//                 // Tổng tiền
//                 OrderInfoRow(
//                   label: "Tổng số tiền:", 
//                   value: formatCurrency(order.totalPrice),
//                   isBold: true,
//                   valueColor: AppColors.primaryOrange,
//                 ),
                
//                 const SizedBox(height: 12),
                
//                 // Các nút hành động
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.end,
//                   children: [
//                     // Nút Hủy (Chỉ hiện khi chưa xử lý)
//                     if (order.status == 'pending')
//                       Padding(
//                         padding: const EdgeInsets.only(right: 8),
//                         child: OrderSmallButton(
//                         text: "Hủy",
//                         color: Colors.white,
//                         textColor: Colors.black,
//                         isOutlined: true,
//                         onPressed: isLoadingButtonCancel
//                             ? null
//                             : () {
//                             // Hiển thị Dialog xác nhận
//                             showDialog(
//                               context: context,
//                               builder: (ctx) => AlertDialog(
//                                 title: const Text("Xác nhận hủy đơn"),
//                                 content: const Text("Bạn có chắc chắn muốn hủy đơn hàng này không?\nHành động này không thể hoàn tác."),
//                                 actions: [
//                                   // Nút Đóng Dialog
//                                   TextButton(
//                                     onPressed: () => Navigator.of(ctx).pop(),
//                                     child: const Text("Không", style: TextStyle(color: Colors.black)),
//                                   ),
//                                   // Nút Đồng ý Hủy
//                                   TextButton(
//                                     onPressed: () async {
//                                       Navigator.of(ctx).pop();
//                                       setState(() {
//                                         isLoadingButtonCancel = true;
//                                       });

//                                       bool succeeded = await OrderController().cancelOrder(order.id);

//                                       if (!mounted) return;

//                                       if (succeeded) {
//                                         ScaffoldMessenger.of(context).showSnackBar(
//                                           const SnackBar(
//                                             content: Text("Hủy đơn hàng thành công"),
//                                             backgroundColor: Colors.greenAccent,
//                                           ),
//                                         );

//                                         // Load lại dữ liệu
//                                         setState(() {
//                                           isLoadingButtonCancel = false;
//                                           _ordersFuture = _orderController.getOrderHistory();
//                                         });
//                                         _loadProductList(); 
//                                       } else {
//                                         ScaffoldMessenger.of(context).showSnackBar(
//                                           const SnackBar(
//                                             content: Text("Hủy đơn thất bại"),
//                                             backgroundColor: Colors.redAccent,
//                                           ),
//                                         );
//                                         setState(() {
//                                           isLoadingButtonCancel = false;
//                                         });
//                                       }
//                                     },
//                                     child: const Text("Đồng ý hủy", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
//                                   ),
//                                 ],
//                               ),
//                             );
//                           },
//                       ),
//                     ),
                    
//                     // Nút Mua lại (Luôn hiện)
//                     OrderSmallButton(
//                       text: "Mua lại",
//                       color: AppColors.primaryOrange,
//                       textColor: Colors.white,
//                       isOutlined: false,
//                       onPressed: () async {
//                       // 1. Hiển thị Loading để người dùng biết đang xử lý
//                       showDialog(
//                         context: context,
//                         barrierDismissible: false,
//                         builder: (context) => const Center(child: CircularProgressIndicator()),
//                       );

//                       try {
//                         // 2. Gọi API lấy chi tiết đơn hàng để có danh sách items đầy đủ
//                         Order? fullOrder = await _orderController.getOrderDetail(order.id);
                        
//                         // Tắt Loading
//                         Navigator.of(context).pop();

//                         // 3. Kiểm tra dữ liệu
//                         if (fullOrder == null || fullOrder.items == null || fullOrder.items!.isEmpty) {
//                           ScaffoldMessenger.of(context).showSnackBar(
//                             const SnackBar(content: Text("Không lấy được thông tin sản phẩm của đơn hàng này")),
//                           );
//                           return;
//                         }

//                         List<CartItem> buyAgainList = [];

//                         // 4. Xử lý logic ghép dữ liệu
//                         for (var orderItem in fullOrder.items!) {
//                           ProductVariant? variant;
                          
//                           // Tìm variant trong danh sách đã load (nếu có)
//                           try {
//                             if (_allVariants.isNotEmpty) {
//                               final safeList = _allVariants.whereType<ProductVariant>().toList();
//                               variant = safeList.firstWhere(
//                                 (v) => v.id == orderItem.productId, 
//                                 orElse: () => ProductVariant(id: 0, price: 0)
//                               );
//                               if (variant.id == 0) variant = null;
//                             }
//                           } catch (_) {
//                             variant = null;
//                           }

//                           // Tạo CartItem
//                           buyAgainList.add(CartItem(
//                             productVariantId: orderItem.productId,
//                             productName: variant?.name ?? orderItem.productName,
//                             quantity: orderItem.quantity,
//                             price: (variant?.price ?? orderItem.price).toDouble(),
//                             imageUrl: variant?.imageUrl ?? "",
//                             color: variant?.color ?? "",
//                             ram: variant?.ram ?? "",
//                             storage: variant?.storage ?? "",
//                           ));
//                         }

//                         // 5. Tính tổng tiền và chuyển trang
//                         double totalMoney = buyAgainList.fold(0, (sum, item) => sum + ((item.price ?? 0) * (item.quantity ?? 0)));

//                         if (buyAgainList.isNotEmpty) {
//                           Navigator.push(
//                             context,
//                             MaterialPageRoute(
//                               builder: (context) => CheckoutScreen(
//                                 cartItems: buyAgainList,
//                                 totalMoney: totalMoney,
//                                 is_buy_now: true,
//                               ),
//                             ),
//                           );
//                         }

//                       } catch (e) {
//                         // Tắt Loading nếu có lỗi và báo lỗi
//                         Navigator.of(context).pop();
//                         print("Lỗi Mua lại: $e");
//                         ScaffoldMessenger.of(context).showSnackBar(
//                           SnackBar(content: Text("Có lỗi xảy ra: $e")),
//                         );
//                       }
//                     },
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   // Widget hiển thị thông tin 1 sản phẩm
//   Widget _buildProductItem(OrderItem item) {
//     final info = _getProductInfo(item.productId, item.productName);

//     return Padding(
//       padding: const EdgeInsets.all(12),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           // Ảnh sản phẩm
//           Container(
//             width: 70,
//             height: 70,
//             decoration: BoxDecoration(
//               border: Border.all(color: Colors.grey.shade200),
//               borderRadius: BorderRadius.circular(4),
//             ),
//             clipBehavior: Clip.hardEdge,
//             child: (info['img'] != null && info['img']!.isNotEmpty)
//                 ? Image.network(
//                     info['img']!,
//                     fit: BoxFit.cover,
//                     errorBuilder: (ctx, err, stack) => const Icon(Icons.broken_image, color: Colors.grey),
//                   )
//                 : const Icon(Icons.shopping_bag_outlined, color: Colors.grey),
//           ),
//           const SizedBox(width: 12),
          
//           // Tên sản phẩm
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   info['name']!,
//                   maxLines: 2,
//                   overflow: TextOverflow.ellipsis,
//                   style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
//                 ),

//                 // Màu sắc & Dung lượng
//                 if (info['variant'] != null)
//                   Padding(
//                     padding: const EdgeInsets.only(top: 4),
//                     child: Container(
//                       padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
//                       decoration: BoxDecoration(
//                         color: Colors.blue.shade50,
//                         borderRadius: BorderRadius.circular(4),
//                       ),
//                       child: Text(
//                         info['variant']!,
//                         style: TextStyle(color: Colors.blue.shade800, fontSize: 12, fontWeight: FontWeight.w500),
//                         maxLines: 1, 
//                         overflow: TextOverflow.ellipsis
//                       ),
//                     ),
//                   ),

//                   // Số lượng
//                   const SizedBox(height: 4),
//                   Text("  x${item.quantity}",maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.grey)),
//                 ],
//               ),
//             ),
          
//           // Giá tiền
//           Text(
//             formatCurrency(item.price),
//             style: const TextStyle(fontWeight: FontWeight.w500),
//           ),
//         ],
//       ),
//     );
//   }
// }


import 'package:flutter/material.dart';
import 'package:flutter_application_f4_mobile/Model/cartModel.dart';
import 'package:flutter_application_f4_mobile/Model/product_model.dart';
import 'package:flutter_application_f4_mobile/View/checkout_screen.dart';
import 'package:intl/intl.dart';
import '../../resources/app_colors.dart';
import '../../Controller/order_controller.dart';
import '../../Controller/product_controller.dart';
import '../../Model/Order.dart';
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

  final List<String> _filters = ["Tất cả", "Chờ xác nhận", "Đang giao", "Đã giao thành công", "Đã hủy"];
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
      if (mounted) {
        setState(() {
          _allVariants = list;
        });
      }
    } catch (e) {
      print("Lỗi tải danh sách sản phẩm: $e");
    }
  }

  String formatCurrency(int amount) {
    return NumberFormat.currency(locale: 'vi_VN', symbol: 'đ').format(amount);
  }

  String formatDate(String dateString) {
    try {
      return DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(dateString));
    } catch (e) {
      return dateString;
    }
  }

  Map<String, dynamic> getStatusConfig(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return {'text': 'Chờ xác nhận', 'color': Colors.blue};
      case 'processing':
        return {'text': 'Đang chuẩn bị', 'color': Colors.deepPurple};
      case 'shipping':
        return {'text': 'Đang giao', 'color': Colors.orange};
      case 'delivered':
        return {'text': 'Đã giao thành công', 'color': Colors.green};
      case 'cancelled':
        return {'text': 'Đã hủy', 'color': Colors.red};
      default:
        return {'text': status, 'color': Colors.grey};
    }
  }

  Map<String, String?> _getProductInfo(int id, String defaultName) {
    String name = defaultName;
    String? img;
    String? variantsInfo;

    if (_allVariants.isNotEmpty) {
      for (var v in _allVariants) {
        final variant = v as dynamic; 
        
        if (variant.id.toString() == id.toString()) {
          name = variant.name ?? name;
          img = variant.imageUrl;
          List<String> details = [];
          
          if (variant.color != null && variant.color!.isNotEmpty) {
            details.add(variant.color!);
          }
          
          if (details.isNotEmpty) {
            variantsInfo = details.join(" - ");
          }
          break;
        }
      }
    }
    return {'name': name, 'img': img, 'variant': variantsInfo};
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text("Lịch sử đơn hàng", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primaryOrange,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort, color: Colors.white),
            onSelected: (value) {
              setState(() { _sortType = value; });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'newest', child: Row(children: [Icon(Icons.arrow_downward, color: Colors.orange, size: 20), SizedBox(width: 8), Text("Mới nhất trước")])),
              const PopupMenuItem(value: 'oldest', child: Row(children: [Icon(Icons.arrow_upward, color: Colors.grey, size: 20), SizedBox(width: 8), Text("Cũ nhất trước")])),
            ],
          ),
        ],
      ),
      
      body: Column(
        children: [
          _buildFilterBar(),
          Expanded(
            child: FutureBuilder<List<Order>>(
              future: _ordersFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                if (!snapshot.hasData || snapshot.data!.isEmpty) return const Center(child: Text("Bạn chưa có đơn hàng nào"));

                final allOrders = snapshot.data!;
                List<Order> displayedOrders;

                if (_selectedFilter == "Tất cả") {
                  displayedOrders = allOrders;
                } else {
                  displayedOrders = allOrders.where((order) {
                    final config = getStatusConfig(order.status);
                    return config['text'] == _selectedFilter;
                  }).toList();
                }

                displayedOrders.sort((a, b) {
                  DateTime? dateA = DateTime.tryParse(a.createdAt);
                  DateTime? dateB = DateTime.tryParse(b.createdAt);
                  dateA ??= DateTime(1970);
                  dateB ??= DateTime(1970);
                  return _sortType == 'newest' ? dateB.compareTo(dateA) : dateA.compareTo(dateB);
                });

                if (displayedOrders.isEmpty) return Center(child: Text("Không có đơn hàng ở mục '$_selectedFilter'"));

                return RefreshIndicator(
                  onRefresh: () async {
                    setState(() { _ordersFuture = _orderController.getOrderHistory(); });
                    _loadProductList(); 
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: displayedOrders.length,
                    itemBuilder: (context, index) {
                      return _buildOrderCard(displayedOrders[index]);
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

  Widget _buildFilterBar() {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: _filters.map((filter) {
            final isSelected = _selectedFilter == filter;
            return GestureDetector(
              onTap: () { setState(() { _selectedFilter = filter; }); },
              child: Container(
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
      onTap: () { Navigator.push(context, MaterialPageRoute(builder: (_) => OrderDetailScreen(orderId: order.id))); },
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Padding(padding: const EdgeInsets.only(bottom: 12), child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [Text("Ngày tạo đơn: ${formatDate(order.createdAt)}")])),
              Padding(padding: const EdgeInsets.only(bottom: 12), child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [Text(statusConfig['text'], style: TextStyle(color: statusConfig['color'], fontWeight: FontWeight.bold, fontSize: 13))])),
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
                    if (snapshot.hasData && snapshot.data!.items != null) {
                      return Column(children: snapshot.data!.items!.map((item) => _buildProductItem(item)).toList());
                    }
                    return const Padding(padding: EdgeInsets.all(20), child: Text("Đang tải thông tin sản phẩm...", style: TextStyle(color: Colors.grey)));
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
                OrderInfoRow(label: "Tổng số tiền:", value: formatCurrency(order.totalPrice), isBold: true, valueColor: AppColors.primaryOrange),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (order.status == 'pending')
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: OrderSmallButton(
                        text: "Hủy", color: Colors.white, textColor: Colors.black, isOutlined: true,
                        onPressed: isLoadingButtonCancel
                            ? null
                            : () {
                            showDialog(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text("Xác nhận hủy đơn"),
                                content: const Text("Bạn có chắc chắn muốn hủy đơn hàng này không?\nHành động này không thể hoàn tác."),
                                actions: [
                                  TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text("Không", style: TextStyle(color: Colors.black))),
                                  TextButton(
                                    onPressed: () async {
                                      Navigator.of(ctx).pop();
                                      setState(() { isLoadingButtonCancel = true; });
                                      bool succeeded = await OrderController().cancelOrder(order.id);
                                      if (!mounted) return;
                                      if (succeeded) {
                                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Hủy đơn hàng thành công"), backgroundColor: Colors.greenAccent));
                                        setState(() { isLoadingButtonCancel = false; _ordersFuture = _orderController.getOrderHistory(); });
                                        _loadProductList(); 
                                      } else {
                                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Hủy đơn thất bại"), backgroundColor: Colors.redAccent));
                                        setState(() { isLoadingButtonCancel = false; });
                                      }
                                    },
                                    child: const Text("Đồng ý hủy", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ),
                            );
                          },
                      ),
                    ),
                    OrderSmallButton(
                      text: "Mua lại", color: AppColors.primaryOrange, textColor: Colors.white, isOutlined: false,
                      onPressed: () async {
                      showDialog(context: context, barrierDismissible: false, builder: (context) => const Center(child: CircularProgressIndicator()));
                      try {
                        Order? fullOrder = await _orderController.getOrderDetail(order.id);
                        Navigator.of(context).pop();
                        if (fullOrder == null || fullOrder.items == null || fullOrder.items!.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Không lấy được thông tin sản phẩm của đơn hàng này")));
                          return;
                        }
                        List<CartItem> buyAgainList = [];
                        // 4. Xử lý logic ghép dữ liệu
                        for (var orderItem in fullOrder.items!) {
                          ProductVariant? variant;
                          try {
                            if (_allVariants.isNotEmpty) {
                              final safeList = _allVariants.whereType<ProductVariant>().toList();
                              variant = safeList.firstWhere((v) => v.id == orderItem.productId, orElse: () => ProductVariant(id: 0, price: 0));
                              if (variant.id == 0) variant = null;
                            }
                          } catch (_) { variant = null; }
                          
                          buyAgainList.add(CartItem(
                            productVariantId: orderItem.productId,
                            productName: variant?.name ?? orderItem.productName,
                            productId: variant?.productId ?? 0, // Thêm dòng này để truyền đủ id sản phẩm gốc
                            quantity: orderItem.quantity,
                            price: (variant?.price ?? orderItem.price).toDouble(),
                            imageUrl: variant?.imageUrl ?? "",
                          ));
                        }
                        double totalMoney = buyAgainList.fold(0, (sum, item) => sum + ((item.price ?? 0) * (item.quantity ?? 0)));
                        if (buyAgainList.isNotEmpty) {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => CheckoutScreen(cartItems: buyAgainList, totalMoney: totalMoney, is_buy_now: true)));
                        }
                      } catch (e) {
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Có lỗi xảy ra: $e")));
                      }
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
    final info = _getProductInfo(item.productId, item.productName);

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 70, height: 70,
            decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade200), borderRadius: BorderRadius.circular(4)),
            clipBehavior: Clip.hardEdge,
            child: (info['img'] != null && info['img']!.isNotEmpty)
                ? Image.network(info['img']!, fit: BoxFit.cover, errorBuilder: (ctx, err, stack) => const Icon(Icons.broken_image, color: Colors.grey))
                : const Icon(Icons.shopping_bag_outlined, color: Colors.grey),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(info['name']!, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15)),
                if (info['variant'] != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(4)),
                      child: Text(info['variant']!, style: TextStyle(color: Colors.blue.shade800, fontSize: 12, fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text("  x${item.quantity}",maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.grey)),
                ],
              ),
            ),
          Text(formatCurrency(item.price), style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
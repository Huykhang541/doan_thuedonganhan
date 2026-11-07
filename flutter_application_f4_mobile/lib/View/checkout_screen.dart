import 'package:flutter/material.dart';
import 'package:flutter_application_f4_mobile/Controller/shippingController.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'Widget/custom_button.dart';
import 'thanhtoanok_screen.dart';
import '../Model/cartModel.dart';
import '../Controller/create_order_controller.dart';
import 'package:intl/intl.dart'; // Để format ngày tháng
import '../Model/couponModel.dart'; 
import '../Controller/couponController.dart';

class CheckoutScreen extends StatefulWidget {
  final List<CartItem> cartItems;
  final double totalMoney;
  final bool is_buy_now;

  const CheckoutScreen({
    super.key, 
    required this.cartItems, 
    required this.totalMoney,
    required this.is_buy_now
  });

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final CreateOrderController _orderController = CreateOrderController();
  final CouponController _couponController = CouponController();

  // Dữ liệu người dùng
  String receiverName = "Người dùng"; 
  String phoneNumber = "";
  String address = "Chưa nhập địa chỉ";
  String city = ""; // Mặc định
  String note = "";

  // Trạng thái thanh toán
  bool _isEWallet = false;
  bool _isCOD = false;
  bool _isLoading = false;

  // Logic Mã giảm giá
  String _couponCode = "";
  double _discountAmount = 0;

  double shippingFee = 0;

  // --- DANH SÁCH TỈNH THÀNH (Bạn có thể thêm đủ 63 tỉnh) ---
  final List<String> _provinces = [
    "Hà Nội", "TP.HCM", "Đà Nẵng", "Hải Phòng", "Cần Thơ",
    "An Giang", "Bà Rịa - Vũng Tàu", "Bắc Giang", "Bắc Kạn", "Bạc Liêu",
    "Bắc Ninh", "Bến Tre", "Bình Định", "Bình Dương", "Bình Phước",
    "Bình Thuận", "Cà Mau", "Cao Bằng", "Đắk Lắk", "Đắk Nông",
    "Điện Biên", "Đồng Nai", "Đồng Tháp", "Gia Lai", "Hà Giang",
    "Hà Nam", "Hà Tĩnh", "Hải Dương", "Hậu Giang", "Hòa Bình",
    "Hưng Yên", "Khánh Hòa", "Kiên Giang", "Kon Tum", "Lai Châu",
    "Lâm Đồng", "Lạng Sơn", "Lào Cai", "Long An", "Nam Định",
    "Nghệ An", "Ninh Bình", "Ninh Thuận", "Phú Thọ", "Quảng Bình",
    "Quảng Nam", "Quảng Ngãi", "Quảng Ninh", "Quảng Trị", "Sóc Trăng",
    "Sơn La", "Tây Ninh", "Thái Bình", "Thái Nguyên", "Thanh Hóa",
    "Thừa Thiên Huế", "Tiền Giang", "Trà Vinh", "Tuyên Quang", "Vĩnh Long",
    "Vĩnh Phúc", "Yên Bái"
  ];

  @override
  void initState() {
    super.initState();
    // Sort tên tỉnh theo bảng chữ cái cho dễ tìm
    _provinces.sort((a, b) => a.compareTo(b));
    _loadSavedInfo();
    _getShippingFee(city);
  }

  Future<void> _loadSavedInfo() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      if (prefs.containsKey('saved_name')) receiverName = prefs.getString('saved_name')!;
      if (prefs.containsKey('saved_phone')) phoneNumber = prefs.getString('saved_phone')!;
      if (prefs.containsKey('saved_address')) address = prefs.getString('saved_address')!;
      
      // Load thành phố, nếu không có trong danh sách thì lấy mặc định
      String savedCity = prefs.getString('saved_city') ?? "TP.HCM";
      if (_provinces.contains(savedCity)) {
        city = savedCity;
      }
    });
  }
  Future<void> _getShippingFee(String city)async{
    final prefs = await SharedPreferences.getInstance();
    final cityLocal = prefs.getString('saved_city');
    final String? shipping_fee;
    if(cityLocal != null){
      if(cityLocal != "TP.HCM" && cityLocal != "Hà Nội" && cityLocal != "Đà Nẵng"){
        shipping_fee = await Shippingcontroller.getShippingFee("Khác");
      }
      else{
        shipping_fee = await Shippingcontroller.getShippingFee(cityLocal);
      }
      final double fee = double.tryParse(shipping_fee ?? "0.0") ?? 0;
      if(fee != 0){
        setState(() {
          shippingFee = fee;
        });
      }
      else{
        _showNotify('$shipping_fee');
      }
    }
    else if(city.isNotEmpty){
      if(city != "TP.HCM" && city != "Hà Nội" && city != "Đà Nẵng"){
        shipping_fee = await Shippingcontroller.getShippingFee("Khác");
      }
      else{
        shipping_fee = await Shippingcontroller.getShippingFee(city);
      }
      final double fee = double.tryParse(shipping_fee ?? "0.0") ?? 0;
      if(fee != 0){
        setState(() {
          shippingFee = fee;
        });
      }
      else{
        _showNotify('$shipping_fee');
      }
    }
  }
  Future<void> _saveInfo(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }
  // Popup Mã giảm giá
  void _onApplyCoupon() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7, // Chiếm 70% màn hình
        decoration: const BoxDecoration(
          color: Color(0xFFF5F5F5), // Màu nền xám nhạt
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: const Center(child: Text("Mã giảm giá", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
            ),
            
            // Danh sách Coupon từ API
            Expanded(
              child: FutureBuilder<List<CouponModel>>(
                future: CouponController.getCoupons(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: Colors.orange));
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text("Lỗi tải dữ liệu: ${snapshot.error}"));
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text("Hiện không có mã giảm giá nào."));
                  }

                  List<CouponModel> coupons = snapshot.data!;
                  
                  return ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: coupons.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      CouponModel coupon = coupons[index];
                      // Tính xem mã này giảm được bao nhiêu cho đơn hiện tại
                      double tempDiscount = _couponController.calculateDiscount(coupon, widget.totalMoney);
                      bool canApply = tempDiscount > 0; 

                      return _buildCouponTicket(coupon, canApply, tempDiscount);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Popup Sửa thông tin chung
  void _showEditSheet({required String title, required List<Widget> fields, required VoidCallback onSave}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 15),
              ...fields,
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, padding: const EdgeInsets.all(16)),
                  onPressed: () { onSave(); Navigator.pop(context); }, 
                  child: const Text("Lưu thay đổi", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatPrice(num price) => "${price.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}đ";
  void _showNotify(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  @override
  Widget build(BuildContext context) {
    double finalPrice = widget.totalMoney - _discountAmount + shippingFee;
    if (finalPrice < 0) finalPrice = 0;

    return Scaffold(
      backgroundColor: const Color(0xFFFF8A00),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
              child: Row(
                children: [
                  IconButton(icon: const Icon(Icons.arrow_back, color: Colors.black), onPressed: () => Navigator.pop(context)),
                  const Expanded(child: Center(child: Text("Thanh toán", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)))),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionHeader("Thông tin nhận hàng"),
                      const SizedBox(height: 10),
                      
                      // 1. Tên & SĐT
                      _buildClickableRow(
                        icon: Icons.person_outline,
                        title: "$receiverName | $phoneNumber",
                        subTitle: "Bấm để sửa liên hệ",
                        onTap: () {
                          TextEditingController n = TextEditingController(text: receiverName);
                          TextEditingController p = TextEditingController(text: phoneNumber);
                          _showEditSheet(title: "Sửa liên hệ", fields: [
                            TextField(controller: n, decoration: const InputDecoration(labelText: "Họ tên", border: OutlineInputBorder(), prefixIcon: Icon(Icons.person))),
                            const SizedBox(height: 15),
                            TextField(controller: p, decoration: const InputDecoration(labelText: "Số điện thoại", border: OutlineInputBorder(), prefixIcon: Icon(Icons.phone)), keyboardType: TextInputType.phone),
                          ], onSave: () {
                            setState(() { receiverName = n.text; phoneNumber = p.text; });
                            _saveInfo('saved_name', n.text);
                            _saveInfo('saved_phone', p.text);
                          });
                        }
                      ),
                      const SizedBox(height: 10),

                      // 2. Địa chỉ & Chọn Thành phố (Dropdown)
                      _buildClickableRow(
                        icon: Icons.location_on_outlined,
                        title: "$address, $city",
                        subTitle: "Bấm để nhập địa chỉ",
                        isHighLight: address == "Chưa nhập địa chỉ",
                        onTap: () {
                          TextEditingController a = TextEditingController(text: address == "Chưa nhập địa chỉ" ? "" : address);
                          
                          // Biến tạm để lưu thành phố đang chọn trong popup
                          String tempSelectedCity = city; 

                          // Mở popup
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                            builder: (BuildContext context) {
                              return StatefulBuilder( // Dùng StatefulBuilder để update dropdown ngay trong popup
                                builder: (context, setStatePopup) {
                                  return Padding(
                                    padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
                                    child: Container(
                                      padding: const EdgeInsets.all(24),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Text("Địa chỉ giao hàng", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                                          const SizedBox(height: 20),
                                          
                                          // --- DROPDOWN CHỌN TỈNH THÀNH ---
                                          DropdownButtonFormField<String>(
                                            value: tempSelectedCity,
                                            decoration: const InputDecoration(
                                              labelText: "Tỉnh / Thành phố",
                                              border: OutlineInputBorder(),
                                              prefixIcon: Icon(Icons.location_city),
                                            ),
                                            isExpanded: true, // Để text dài không bị lỗi
                                            menuMaxHeight: 300, // Chiều cao danh sách xổ xuống
                                            items: _provinces.map((String value) {
                                              return DropdownMenuItem<String>(
                                                value: value,
                                                child: Text(value),
                                              );
                                            }).toList(),
                                            onChanged: (newValue) async {
                                              //_getShippingFee(city);
                                              setStatePopup(() { // Update giao diện trong popup
                                                tempSelectedCity = newValue!;
                                              });
                                            },
                                          ),
                                          // ---------------------------------
                                          
                                          const SizedBox(height: 15),
                                          TextField(
                                            controller: a, 
                                            decoration: const InputDecoration(labelText: "Số nhà, Đường, Phường...", border: OutlineInputBorder()), 
                                            maxLines: 2
                                          ),
                                          const SizedBox(height: 20),
                                          
                                          SizedBox(
                                            width: double.infinity,
                                            child: ElevatedButton(
                                              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, padding: const EdgeInsets.all(16)),
                                              onPressed: () { 
                                                // Lưu lại
                                                if(a.text.isNotEmpty) {
                                                  setState(() { 
                                                    address = a.text; 
                                                    city = tempSelectedCity; // Cập nhật city chính thức
                                                  });
                                                  _saveInfo('saved_address', a.text);
                                                  _saveInfo('saved_city', tempSelectedCity);
                                                }
                                                _getShippingFee(tempSelectedCity);
                                                Navigator.pop(context); 
                                              }, 
                                              child: const Text("Lưu thay đổi", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }
                              );
                            }
                          );
                        }
                      ),

                      const SizedBox(height: 25),

                      // 3. Sản phẩm
                      _buildSectionHeader("Sản phẩm"),
                      const SizedBox(height: 10),
                      ...widget.cartItems.map((item) => _buildProductCard(item)),

                      const SizedBox(height: 10),
                      TextField(
                        decoration: InputDecoration(
                          hintText: "Ghi chú...",
                          prefixIcon: const Icon(Icons.note_alt_outlined),
                          filled: true, fillColor: Colors.grey[100],
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none)
                        ),
                        onChanged: (val) => note = val,
                      ),

                      const SizedBox(height: 20),

                      // 4. Mã giảm giá
                      InkWell(
                        onTap: _onApplyCoupon,
                        child: Container(
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(border: Border.all(color: Colors.orange.shade200), borderRadius: BorderRadius.circular(10), color: Colors.orange.shade50),
                          child: Row(
                            children: [
                              const Icon(Icons.confirmation_number_outlined, color: Colors.orange),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _couponCode.isEmpty ? "Chọn mã giảm giá" : "Mã: $_couponCode (-${_formatPrice(_discountAmount)})",
                                  style: TextStyle(color: _couponCode.isEmpty ? Colors.black54 : Colors.red, fontWeight: FontWeight.bold),
                                ),
                              ),
                              const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 25),
                      
                      // 5. Thanh toán
                      _buildSectionHeader("Thanh toán"),
                      _buildPaymentOption("COD (Tiền mặt)", _isCOD, (val) => setState(() { _isCOD = val!; if(val) _isEWallet = false; })),
                      _buildPaymentOption("Ví điện tử / Chuyển khoản", _isEWallet, (val) => setState(() { _isEWallet = val!; if(val) _isCOD = false; })),

                      const SizedBox(height: 30),

                      // 6. Tổng tiền
                      Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text("Khuyến mãi", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              _buildDiscountMoney(_couponCode, _discountAmount),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text("Phí vận chuyển", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              Text(_formatPrice(shippingFee), style: TextStyle(color: Colors.deepOrangeAccent),)
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text("Tổng thanh toán", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              Text(_formatPrice(finalPrice), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.red)),
                            ],
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 20),
                      
                      CustomButton(
                        text: _isLoading ? "ĐANG XỬ LÝ..." : "ĐẶT HÀNG", 
                        onPressed: _isLoading ? () {} : () async {
                           if(phoneNumber.isEmpty){_showNotify("Vui lòng nhập số điện thoại!"); return; }
                           if (address == "Chưa nhập địa chỉ" || address.isEmpty) { _showNotify("Vui lòng nhập địa chỉ!"); return; }
                           if (!_isCOD && !_isEWallet) { _showNotify("Vui lòng chọn phương thức thanh toán!"); return; }
                           
                           setState(() => _isLoading = true);
                           
                           if(city != 'TP.HCM' && city != 'Hà Nội' && city != 'Đà Nẵng'){
                            city = 'Khác';
                           }

                          int success = await _orderController.createOrder(
                              fullName: receiverName, 
                              phone: phoneNumber, 
                              address: address, 
                              city: city, // Gửi thành phố đã chọn
                              couponCode: _couponCode,
                              note: note,
                              totalPrice: finalPrice, 
                              isBuyNow: widget.is_buy_now,
                              paymentMethod: _isCOD ? "COD" : "E_WALLET", 
                              cartItems: widget.cartItems
                           );
                           
                           setState(() => _isLoading = false);

                          if(!mounted) return;

                           if (success != 0) {
                             Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => ThanhToanOkScreen(orderID: success,)));
                           } else {
                             _showNotify("Lỗi đặt hàng. Vui lòng thử lại!");
                           }
                        }
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildDiscountMoney(String couponCode, double discount){
    if(couponCode.isNotEmpty){
      return Text(
        "- ${_formatPrice(discount)}",
        style: TextStyle(color: Colors.deepOrangeAccent),
      );
    }
    else{
      return Text(
        "- ${_formatPrice(0)}",
        style: TextStyle(color: Colors.deepOrangeAccent),
      );
    }
  }
  Widget _buildSectionHeader(String title) => Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold));

  Widget _buildClickableRow({required IconData icon, required String title, required String subTitle, required VoidCallback onTap, bool isHighLight = false}) {
    return InkWell(
      onTap: onTap, borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isHighLight ? Colors.orange.withOpacity(0.1) : Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isHighLight ? Colors.orange : Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Icon(icon, color: isHighLight ? Colors.orange : Colors.grey[600], size: 24),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: isHighLight ? Colors.orange[800] : Colors.black87)),
              Text(subTitle, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            ])),
            const Icon(Icons.edit, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentOption(String title, bool value, Function(bool?) onChanged) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(border: Border.all(color: value ? Colors.orange : Colors.grey.shade200), borderRadius: BorderRadius.circular(10), color: value ? Colors.orange.withOpacity(0.05) : null),
      child: CheckboxListTile(title: Text(title, style: TextStyle(fontSize: 14, fontWeight: value ? FontWeight.bold : FontWeight.normal)), value: value, activeColor: Colors.orange, contentPadding: const EdgeInsets.symmetric(horizontal: 8), onChanged: onChanged),
    );
  }

  Widget _buildProductCard(CartItem item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(children: [
        ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(item.imageUrl ?? "", width: 60, height: 60, fit: BoxFit.cover, errorBuilder: (_,__,___) => Container(width: 60, height: 60, color: Colors.grey[200]))),
        const SizedBox(width: 12),
        Expanded(child: 
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(item.productName ?? "", maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold)), 
          // Đã xóa dòng hiển thị item.color gây lỗi ở đây
          Text("${item.quantity} x ${_formatPrice(item.price ?? 0)}", style: const TextStyle(color: Colors.grey, fontSize: 13))])
        ),
        Text(_formatPrice((item.price ?? 0) * (item.quantity ?? 1)), style: const TextStyle(fontWeight: FontWeight.bold)),
      ]),
    );
  }

  Widget _buildCouponTicket(CouponModel coupon, bool canApply, double calculatedAmount) {
    double percentUsed = 0;
    if (coupon.usageLimit > 0) {
      percentUsed = (coupon.usedCount / coupon.usageLimit) * 100;
    } 
    return Container(
      height: 100, // Chiều cao cố định cho vé
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade200),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          // 1. Phần trái (Icon)
          Container(
            width: 80,
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(12), bottomLeft: Radius.circular(12)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.card_giftcard, color: Colors.orange[700], size: 30),
                const SizedBox(height: 4),
                Text("Voucher", style: TextStyle(color: Colors.orange[700], fontSize: 10, fontWeight: FontWeight.bold)),
              ],
            ),
          ),

          // 2. Đường kẻ đứt dọc ở giữa
          CustomPaint(
            size: const Size(1, double.infinity),
            painter: DashedLineVerticalPainter(),
          ),

          // 3. Phần phải (Thông tin & Nút)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Mã: ${coupon.code}", style: TextStyle(color: Colors.orange[800], fontWeight: FontWeight.bold, fontSize: 12)),
                      if (coupon.endDate != null)
                        Text("Hết hạn: ${DateFormat('dd/MM/yy').format(coupon.endDate!)}", style: const TextStyle(fontSize: 10, color: Colors.grey)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  
                  // Giá trị giảm (VD: Giảm 15% hoặc Giảm 50.000đ)
                  Text(
                    coupon.discountType == 'percent' 
                        ? "Giảm ${coupon.discountValue.toStringAsFixed(0)}%" 
                        : "Giảm ${_formatPrice(coupon.discountValue)}",
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),

                  const Spacer(),

                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Đơn tối thiểu ${_formatPrice(coupon.minOrderValue)} | Đã dùng ${percentUsed.toInt()}%", style: const TextStyle(fontSize: 11, color: Colors.grey)),
                      
                      SizedBox(
                        height: 30,
                        child: ElevatedButton(
                          onPressed: canApply ? () {
                            setState(() {
                              _couponCode = coupon.code;
                              _discountAmount = calculatedAmount;
                            });
                            Navigator.pop(context); // Đóng popup
                            _showNotify("Đã áp dụng mã ${coupon.code}");
                          } : null, // Disable nút nếu không đủ điều kiện
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            disabledBackgroundColor: Colors.grey[300],
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
                          ),
                          child: Text(canApply ? "Áp dụng" : "Chưa đủ ĐK", style: TextStyle(color: canApply ? Colors.white : Colors.grey[600], fontSize: 11, fontWeight: FontWeight.bold)),
                        ),
                      )
                    ],
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}

class DashedLineVerticalPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    double dashHeight = 5, dashSpace = 3, startY = 0;
    final paint = Paint()
      ..color = Colors.grey.shade300
      ..strokeWidth = 1;
    while (startY < size.height) {
      canvas.drawLine(Offset(0, startY), Offset(0, startY + dashHeight), paint);
      startY += dashHeight + dashSpace;
    }
  }
  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
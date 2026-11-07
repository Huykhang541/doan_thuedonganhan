import 'package:flutter/material.dart';
import 'package:flutter_application_f4_mobile/View/order_detail_screen.dart';
import '../../resources/app_colors.dart';
import 'Widget/custom_button.dart';

class ThanhToanOkScreen extends StatelessWidget {
  final int orderID;

  const ThanhToanOkScreen({super.key, required this.orderID});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundOrange,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Nút Back ở góc trái
            /*Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.black),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),*/

            // Nội dung bo góc trắng
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Biểu tượng tích xanh thành công
                    Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        color: const Color(0xFFD4F5E1),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Container(
                          width: 110,
                          height: 110,
                          decoration: const BoxDecoration(
                            color: Color(0xFF4CD964),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 70,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Tiêu đề Thành công
                    const Text(
                      "Thành công !!",
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Nội dung thông báo
                    const Text(
                      "Your order has been\ncompleted and is being\nattended to.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 60),

                    // Nút Xem lại đơn hàng
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (context) => OrderDetailScreen(orderId: orderID))
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF262626),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        child: const Text(
                          "Xem lại đơn hàng",
                          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Nút Tiếp tục mua hàng (Sử dụng CustomButton của bạn)
                    CustomButton(
                      text: "Tiếp tục mua hàng",
                      onPressed: () {
                        // Logic quay về trang chủ
                        Navigator.of(context).popUntil((route) => route.isFirst);
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
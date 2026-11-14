import orderModel from "../models/orderModel.js";
import { execute } from "../config/db.js";

export default class orderController {
    static async createOrder(req, res) {
        try {
            const userId = req.userid; 
            if (!userId) return res.status(401).json({ succeeded: false, message: "Chưa đăng nhập" });

            // [FIX 3]: Bao quát tên biến phòng ngừa việc Flutter gửi tên camelCase thay vì snake_case
            const { fullName, phone, address, city, note, couponCode, coupon_code, paymentMethod, payment_method, order_details, cartItems, isBuyNow, is_buy_now, ngayThue, NgayThue, ngayTra, NgayTra } = req.body;
            
            const finalCoupon = couponCode || coupon_code;
            const finalPayment = paymentMethod || payment_method;
            const finalItems = order_details || cartItems;
            const finalIsBuyNow = isBuyNow !== undefined ? isBuyNow : is_buy_now;
            const finalNgayThue = ngayThue || NgayThue;
            const finalNgayTra = ngayTra || NgayTra;

            if (!fullName || !phone || !address || !city || !finalPayment || !finalItems || finalIsBuyNow === undefined || !finalNgayThue || !finalNgayTra) {
                return res.status(400).json({ succeeded: false, message: "Thiếu thông tin giao hàng hoặc chưa chọn Ngày thuê/Ngày trả!" });
            }

            if (new Date(finalNgayTra) < new Date(finalNgayThue)) {
                return res.status(400).json({ succeeded: false, message: "Lỗi: Ngày trả đồ phải sau hoặc bằng ngày thuê!" });
            }

            const shippingData = { fullName, phone, address, city, note, NgayThue: finalNgayThue, NgayTra: finalNgayTra };
            const orderId = await orderModel.checkout(userId, shippingData, finalCoupon, finalPayment, finalItems, finalIsBuyNow);

            return res.status(201).json({
                succeeded: true,
                message: "Tạo đơn thuê thành công!",
                order_id: orderId
            });
        } catch (error) {
            return res.status(500).json({
                succeeded: false,
                message: error.message
            });
        }
    }

    static async getOrderDetail(req, res) {
        try {
            const userId = req.userid;
            const { orderID } = req.params;
            
            if (!userId) return res.status(401).json({ succeeded: false, message: "Bạn chưa đăng nhập" });
            if (!orderID) return res.status(400).json({ succeeded: false, message: 'Thiếu ID đơn hàng' });

            const rawOrderDetails = await orderModel.getOrderDetail(orderID);

            if (!rawOrderDetails || rawOrderDetails.length === 0) {
                 return res.status(404).json({ succeeded: false, message: "Không tìm thấy đơn hàng này!" });
            }

            const firstRow = rawOrderDetails[0];
            
            // [FIX]: Mở khóa cho Admin được phép xem chi tiết đơn (Dựa vào req.role set từ auth/admin middleware)
            if (userId !== firstRow.MaKhachThue && userId !== firstRow.MaChuSoHuu && req.role !== 'admin') {
                return res.status(403).json({ 
                    succeeded: false, 
                    message: "Bạn không có quyền xem chi tiết đơn hàng này!" 
                });
            }
            
            const rentalFee = parseFloat(firstRow.TongTienThue || 0);
            const depositFee = parseFloat(firstRow.TongTienCoc || 0);
            const shippingFee = parseFloat(firstRow.PhiGiaoHang || 0);

            const formattedOrder = {
                id: firstRow.MaDonThue,
                userId: firstRow.MaKhachThue,
                ownerId: firstRow.MaChuSoHuu,
                fullName: firstRow.HoTen, 
                phoneNumber: firstRow.SoDienThoai,
                address: firstRow.DiaChiGiaoHang,
                rentalFee: rentalFee,
                depositFee: depositFee,
                shippingFee: shippingFee,
                totalPrice: rentalFee + depositFee + shippingFee, 
                status: firstRow.status,
                createdAt: firstRow.NgayTao,
                items: rawOrderDetails.map(row => ({
                    productId: row.MaSanPham,
                    productName: row.TenSanPham,
                    variantId: row.MaBienThe,
                    imageUrl: row.imageUrl,
                    image: row.imageUrl, 
                    color: row.MauSac,
                    price: parseFloat(row.DonGiaThue || row.ThanhTien || 0), 
                    quantity: 1,
                    subTotal: parseFloat(row.ThanhTien || 0) 
                }))
            };

            return res.status(200).json({
                succeeded: true, 
                message: "Lấy chi tiết hóa đơn thành công",
                order: formattedOrder
            });
        } catch (error) {
            return res.status(500).json({ succeeded: false, message: "Lỗi lấy chi tiết hóa đơn: " + error.message });
        }
    }
    
    static async getOrders(req, res) {
        try {
            const user_id = req.userid;
            const orders = await orderModel.getListOrderByUserID(user_id);
            return res.status(200).json({ succeeded: true, message: "Lấy danh sách đơn hàng thành công", orders: orders });
        } catch (error) {
            return res.status(500).json({ succeeded: false, message: "Lỗi lấy lịch sử đơn hàng của người dùng: " + error.message });
        }
    }

    static async cancelOrder(req, res) {
        try {
            const userId = req.userid; 
            const { orderId } = req.params; 

            // [FIX]: Check trước xem đơn hàng có phải của user này không
            const [rows] = await execute("SELECT MaKhachThue FROM donthue WHERE MaDonThue = ?", [orderId]);

            if (rows.length === 0) {
                return res.status(404).json({ succeeded: false, message: "Không tìm thấy đơn hàng!" });
            }
            if (rows[0].MaKhachThue !== userId) {
                return res.status(403).json({ succeeded: false, message: "Bạn không có quyền hủy đơn của người khác!" });
            }

            // [FIX]: Gọi hàm từ orderModel thay vì execute chay để TẬN DỤNG CƠ CHẾ TRANSACTION & LOCK (FOR UPDATE)
            await orderModel.cancelOrder(orderId);

            return res.status(200).json({ succeeded: true, message: "Hủy đơn hàng thành công!" });
        } catch (error) {
            // Nhận lỗi ném ra từ Model nếu trạng thái không phải là 'cho_duyet'
            return res.status(400).json({ succeeded: false, message: error.message });
        }
    }

    static async getMyOrders(req, res) {
        try {
            const user_id = req.userid; 
            if (!user_id) {
                return res.status(401).json({ succeeded: false, message: "Yêu cầu đăng nhập!" });
            }

            const orders = await orderModel.getOrdersByCustomerId(user_id);
            
            // [FIX 3]: Tính sẵn totalPrice đầy đủ (Thuê + Cọc + Ship) để màn hình Lịch sử thuê đồ hiển thị đúng
            const formattedOrders = orders.map(o => ({
                ...o,
                totalPrice: parseFloat(o.TongTienThue || 0) + parseFloat(o.TongTienCoc || 0) + parseFloat(o.PhiGiaoHang || 0)
            }));

            return res.status(200).json({
                succeeded: true,
                message: "Lấy danh sách đơn đã đặt thành công!",
                orders: formattedOrders
            });
        } catch (error) {
            return res.status(500).json({ succeeded: false, message: error.message });
        }
    }

    static async getLessorRequests(req, res) {
        try {
            const lessor_id = req.userid;
            if (!lessor_id) {
                return res.status(401).json({ succeeded: false, message: "Yêu cầu đăng nhập!" });
            }

            const requests = await orderModel.getIncomingRequestsForLessor(lessor_id);
            return res.status(200).json({
                succeeded: true,
                message: "Lấy danh sách yêu cầu thuê nhận được thành công!",
                requests: requests
            });
        } catch (error) {
            return res.status(500).json({ succeeded: false, message: error.message });
        }
    }
    
    static async returnOrder(req, res) {
        try {
            const { orderId } = req.params;
            const { tien_phat_hu_hong, ghi_chu } = req.body; 

            const tienPhatThuCong = tien_phat_hu_hong ? parseFloat(tien_phat_hu_hong) : 0;

            const result = await orderModel.returnOrder(orderId, tienPhatThuCong, ghi_chu);
            
            if (result) {
                res.status(200).json({
                    succeeded: true,
                    message: "Xác nhận trả đồ thành công! Hệ thống đã tự động tính toán tiền phạt và tiền cọc hoàn trả."
                });
            } else {
                res.status(400).json({ succeeded: false, message: "Không thể cập nhật đơn hàng này." });
            }
        } catch (error) {
            res.status(500).json({ succeeded: false, message: error.message });
        }
    }

    static async lessorUpdateStatus(req, res) {
        try {
            const { orderId } = req.params;
            const { trang_thai_don, trang_thai_giao } = req.body;
            const lessorId = req.userid;

            if (!trang_thai_don) {
                return res.status(400).json({ succeeded: false, message: "Thiếu trạng thái đơn hàng để cập nhật!" });
            }

            // [FIX]: Loại bỏ JOIN thừa thãi (vì donthue có sẵn MaChuSoHuu), giảm tải Server DB
            const [checkOrder] = await execute(
                `SELECT MaDonThue FROM donthue WHERE MaDonThue = ? AND MaChuSoHuu = ? LIMIT 1`,
                [orderId, lessorId]
            );

            if (checkOrder.length === 0) {
                return res.status(403).json({ 
                    succeeded: false, 
                    message: "Không tìm thấy đơn hàng hoặc đơn hàng này không thuộc quyền sở hữu của bạn!" 
                });
            }

            const [result] = await execute(
                "UPDATE donthue SET TrangThaiDon = ?, TrangThaiGiaoHang = ? WHERE MaDonThue = ?",
                [trang_thai_don, trang_thai_giao || 'chưa giao', orderId]
            );

            if (result.affectedRows > 0) {
                return res.status(200).json({ succeeded: true, message: "Cập nhật trạng thái đơn hàng thành công!" });
            } else {
                return res.status(400).json({ succeeded: false, message: "Cập nhật trạng thái thất bại." });
            }
        } catch (error) {
            return res.status(500).json({ succeeded: false, message: error.message });
        }
    }

    static async getAllOrders(req, res) {
        try {
            // [FIX]: Đồng bộ gọi Model thay vì dùng raw execute
            const orders = await orderModel.getAllOrder();
            
            return res.status(200).json({
                succeeded: true,
                message: "Lấy danh sách tất cả đơn hàng thành công!",
                orders: orders
            });
        } catch (error) {
            return res.status(500).json({ succeeded: false, message: error.message });
        }
    }

    static async approveOrder(req, res) {
        try {
            const { orderId } = req.params;
            const status = req.body.status || 'confirmed'; 

            const [rows] = await execute("SELECT TrangThaiDon FROM donthue WHERE MaDonThue = ?", [orderId]);
            if (rows.length === 0) {
                return res.status(444).json({ succeeded: false, message: "Không tìm thấy đơn hàng này trong hệ thống!" });
            }

            const currentStatus = rows[0].TrangThaiDon;

            if (currentStatus === 'cancelled') {
                return res.status(409).json({ 
                    succeeded: false, 
                    message: "Lỗi: Đơn hàng này đã bị hủy từ trước, không thể thay đổi trạng thái nữa!" 
                });
            }

            // [FIX]: Mapping tự động Trạng thái giao hàng theo Trạng thái đơn (Dựa theo ENUM của DB)
            let deliveryStatus = '';
            if (status === 'confirmed') {
                deliveryStatus = 'dang_giao'; // Duyệt đơn -> Bắt đầu giao
            } else if (status === 'completed') {
                deliveryStatus = 'da_giao';   // Hoàn thành -> Đã giao tới
            }

            // Khởi tạo câu lệnh query động
            let query = "UPDATE donthue SET TrangThaiDon = ?";
            let queryParams = [status];

            if (deliveryStatus) {
                query += ", TrangThaiGiaoHang = ?";
                queryParams.push(deliveryStatus);
            }
            
            query += " WHERE MaDonThue = ?";
            queryParams.push(orderId);

            // [FIX]: Thực thi query cập nhật cả 2 cột
            const [result] = await execute(query, queryParams);

            if (result.affectedRows > 0) {
                const msg = status === 'cancelled' ? "Từ chối và hủy đơn hàng thành công!" : "Duyệt đơn & Cập nhật giao hàng thành công!";
                return res.status(200).json({ succeeded: true, message: msg });
            } else {
                return res.status(400).json({ succeeded: false, message: "Cập nhật thất bại." });
            }
        } catch (error) {
            return res.status(500).json({ succeeded: false, message: error.message });
        }
    }

    static async getAdminDashboard(req, res) {
        try {
            const stats = await orderModel.getDashboardStats();
            return res.status(200).json({
                succeeded: true,
                message: "Lấy dữ liệu thống kê Dashboard thành công!",
                data: stats
            });
        } catch (error) {
            return res.status(500).json({ succeeded: false, message: error.message });
        }
    }

    static async createComplaint(req, res) {
        try {
            const { orderId } = req.params;
            const { ly_do, loai_khieu_nai, hinh_anh } = req.body; 
            const userId = req.userid; 
            
            if (!userId) {
                return res.status(401).json({ succeeded: false, message: "Bạn chưa đăng nhập!" });
            }

            if (!ly_do) {
                return res.status(400).json({ succeeded: false, message: "Vui lòng nhập lý do khiếu nại!" });
            }

            const complaintId = await orderModel.insertComplaint(orderId, userId, loai_khieu_nai, ly_do, hinh_anh);
            
            return res.status(200).json({ 
                succeeded: true,
                message: "Đã gửi khiếu nại thành công! Hệ thống đã đóng băng giao dịch để Admin phân xử.",
                complaint_id: complaintId
            });
        } catch (error) {
            return res.status(500).json({ succeeded: false, message: error.message });
        }
    }

    static async adminResolveComplaint(req, res) {
        try {
            const { complaintId } = req.params; 
            const { hinh_thuc_id, so_tien, noi_dung, trang_thai_don_moi } = req.body;
            const adminId = req.userid; 

            if (!hinh_thuc_id) {
                return res.status(400).json({ succeeded: false, message: "Vui lòng chọn hình thức xử lý!" });
            }

            await orderModel.resolveComplaint(complaintId, adminId, hinh_thuc_id, so_tien, noi_dung, trang_thai_don_moi);

            return res.status(200).json({ 
                succeeded: true,
                message: "Đã phân xử khiếu nại thành công!"
            });
        } catch (error) {
            return res.status(500).json({ succeeded: false, message: error.message });
        }
    }

    static async getPendingComplaints(req, res) {
        try {
            const complaints = await orderModel.getPendingComplaints();
            return res.status(200).json({
                succeeded: true,
                data: complaints
            });
        } catch (error) {
            return res.status(500).json({ succeeded: false, message: error.message });
        }
    }

    static async payOrder(req, res) {
        try {
            const { orderId } = req.params;
            const { so_tien } = req.body; 
            const userId = req.userid; 

            if (!so_tien || isNaN(so_tien) || so_tien <= 0) {
                return res.status(400).json({ 
                    succeeded: false, 
                    message: "Vui lòng cung cấp số tiền hợp lệ cần thanh toán!" 
                });
            }

            await orderModel.processPaymentEscrow(orderId, userId, so_tien);

            return res.status(200).json({
                succeeded: true,
                message: "Thanh toán thành công! Tiền của bạn đã được hệ thống tạm giữ an toàn."
            });

        } catch (error) {
            return res.status(400).json({ succeeded: false, message: error.message });
        }
    }

    static async completeOrder(req, res) {
        try {
            const { orderId } = req.params;
            await orderModel.completeOrderAndPayout(orderId);

            return res.status(200).json({
                succeeded: true,
                message: "Đã hoàn tất đơn hàng và giải ngân tiền cho các bên thành công!"
            });
        } catch (error) {
            return res.status(400).json({ succeeded: false, message: error.message });
        }
    }
}
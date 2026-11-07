import orderModel from "../models/orderModel.js";
import { execute } from "../config/db.js";

export default class orderController{
    static async createOrder(req, res) {
        try {
            const userId = req.userid; 
            if (!userId) return res.status(401).json({ succeeded: false, message: "Chưa đăng nhập" });

            // 1. Nhận dữ liệu (Đã bổ sung thêm NgayThue và NgayTra để phù hợp với đồ án cho thuê)
            const { fullName, phone, address, city, note, coupon_code, payment_method, order_details, is_buy_now, NgayThue, NgayTra } = req.body;

            // Validate dữ liệu: Bắt buộc khách phải chọn Ngày thuê và Ngày trả
            if (!fullName || !phone || !address || !city || !payment_method || !order_details || is_buy_now === undefined || !NgayThue || !NgayTra) {
                return res.status(400).json({ succeeded: false, message: "Thiếu thông tin giao hàng hoặc chưa chọn Ngày thuê/Ngày trả!" });
            }

            // Kiểm tra logic cơ bản: Ngày trả không thể diễn ra trước ngày thuê
            if (new Date(NgayTra) < new Date(NgayThue)) {
                return res.status(400).json({ succeeded: false, message: "Lỗi: Ngày trả đồ phải sau hoặc bằng ngày thuê!" });
            }

            // Đóng gói dữ liệu kèm theo NgayThue và NgayTra để gửi xuống Database
            const shippingData = { fullName, phone, address, city, note, NgayThue, NgayTra };

            // 2. Đẩy toàn bộ trách nhiệm tính tiền xuống Model (An toàn tuyệt đối)
            const orderId = await orderModel.checkout(userId, shippingData, coupon_code, payment_method, order_details, is_buy_now);

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

    static async approveOrder(req,res){
        try{
            const userId = req.userid;
            if(!userId) return res.status(401).json({succeeded: false, message: "Chưa đăng nhập"});
            const orderID = req.params.id;
            if(!orderID) return res.status(400).json({succeeded: false, message: "Thiếu order_ID"});
            const {curStatus} = req.body;
            if(!curStatus) return res.status(400).json({succeeded: false, message: "Thiếu trạng thái đơn hàng"});
            const status = await orderModel.approveOrders(orderID,curStatus);
            if(status === 'cancelled') return res.status(409).json({succeeded: false, message: "Đơn hàng đã bị hủy trước đó"});
            if(!status) return res.status(500).json({succeeded: false, message: "Không thể thay đổi trạng thái đơn hàng do lỗi server"});

            return res.status(200).json({
                succeeded: true,
                message:"Thay đổi trạng thái đơn hàng thành công"
            });
        }
        catch(error){
            return res.status(500).json({
                succeeded: false,
                message: "Lỗi thay đổi trạng thái đơn hàng: "+error.message
            });
        }
    }

    static async getOrderDetail(req,res){
        try{
            const id = req.userid;
            const {orderID} = req.params;
            console.log("DEBUG(getOrderDetail-sever): " + orderID);
            if(!id) return res.status(400).json({succeeded: false, message:"Bạn chưa đăng nhập"});
            if(!orderID)return res.status(400).json({succeeded: false, message: 'Thiếu ID đơn hàng'});

            const order = await orderModel.getOrderDetail(orderID);

            return res.status(200).json({succeeded: true, message:"Lấy chi tiết hóa đơn thành công",
                order: order
            });

        }
        catch(error){
            return res.status(500).json({
                succeeded: false,
                message:"Lỗi lấy chi tiết hóa đơn: "+ error.message
            });
        }
    }
    
    static async getOrders(req,res){
        try{
            const user_id = req.userid;
            const orders = await orderModel.getListOrderByUserID(user_id);
            return res.status(200).json({succeeded: true, message: "Lấy danh sách đơn hàng thành công", orders: orders});
        }
        catch(error){
            return res.status(500).json({succeeded: false, message: "Lỗi lấy lịch sử đơn hàng của người dùng: " + error.message});
        }
    }

    static async getAllOrder(req,res){
        try{
            const orders = await orderModel.getAllOrder();

            return res.status(200).json({
                succeeded: true,
                orders: orders
            });
        }
        catch(error){
            return res.status(500).json({
                succeeded: false,
                message: error.message
            });
        }
    }
    
    static async cancelOrder(req,res){
        try{
            const {order_id} = req.params;

            if(!order_id) return res.status(400).json({succeeded: false ,message: "Thiếu id đơn hàng"});

            const result = await orderModel.cancelOrder(order_id);

            return res.status(200).json({
                succeeded: result,
                message: "Hủy đơn hàng thành công"
            });
        }
        catch(error){
            return res.status(500).json({
                succeeded: false,
                message: "Hủy đơn hàng không thành công: " + error.message
            });
        }
    }

    // =========================================================================
    // BỔ SUNG 1: CONTROLLER KHÁCH THUÊ XEM LỊCH SỬ ĐƠN ĐÃ GỬI
    // =========================================================================
    static async getMyOrders(req, res) {
        try {
            const user_id = req.userid; // Lấy từ middleware auth sau khi giải mã token
            if (!user_id) {
                return res.status(401).json({ succeeded: false, message: "Yêu cầu đăng nhập!" });
            }

            const orders = await orderModel.getOrdersByCustomerId(user_id);
            return res.status(200).json({
                succeeded: true,
                message: "Lấy danh sách đơn đã đặt thành công!",
                orders: orders
            });
        } catch (error) {
            return res.status(500).json({ succeeded: false, message: error.message });
        }
    }

    // =========================================================================
    // BỔ SUNG 2: CONTROLLER CHỦ ĐỒ XEM YÊU CẦU NHẬN ĐƯỢC
    // =========================================================================
    static async getLessorRequests(req, res) {
        try {
            const lessor_id = req.userid; // Lấy từ middleware auth
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
    
    /**
     * API Admin: Xác nhận trả đồ (Đã nâng cấp tự động hóa)
     */
    static async returnOrder(req, res) {
        try {
            const { orderId } = req.params;
            // Admin chỉ cần nhập tiền phạt hư hỏng (nếu có), không cần tự tính tiền trễ
            const { tien_phat_hu_hong, ghi_chu } = req.body; 

            const tienPhatThuCong = tien_phat_hu_hong ? parseFloat(tien_phat_hu_hong) : 0;

            // Gửi dữ liệu xuống Model để máy tính toán
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
    // =========================================================================
    // ⛺ CONTROLLER: CHỦ ĐỒ CẬP NHẬT TRẠNG THÁI ĐƠN HÀNG (Lessor Update Status)
    // =========================================================================
    static async lessorUpdateStatus(req, res) {
        try {
            const { orderId } = req.params;
            const { trang_thai_don, trang_thai_giao } = req.body;
            const lessorId = req.userid; // ID của chủ đồ lấy từ Token đăng nhập

            if (!trang_thai_don) {
                return res.status(400).json({ succeeded: false, message: "Thiếu trạng thái đơn hàng để cập nhật!" });
            }

            // 1. Kiểm tra đơn hàng hợp lệ và thuộc về sản phẩm của chủ đồ này
            // ĐÃ SỬA: Thay thế 'sp.MaKhachThue' sai lầm bằng 'dt.MaNguoiDung AS MaKhachThue'
            // Thay vì viết sai là sp.MaKhachThue, ta lấy Mã người dùng từ bảng đơn thuê (dt)
            // Thay vì viết sai là sp.MaKhachThue, ta lấy Mã người dùng từ bảng đơn thuê (dt)
            const [checkOrder] = await execute(
                `SELECT dt.MaDonThue, dt.TrangThaiDon, dt.MaKhachThue 
                FROM donthue dt
                JOIN chitietdonthue ctdt ON dt.MaDonThue = ctdt.MaDonThue
                JOIN sanpham sp ON ctdt.MaSanPham = sp.MaSanPham
                WHERE dt.MaDonThue = ? AND sp.MaChuSoHuu = ? LIMIT 1`,
                [orderId, lessorId]
            );

            if (checkOrder.length === 0) {
                return res.status(403).json({ 
                    succeeded: false, 
                    message: "Không tìm thấy đơn hàng hoặc đơn hàng này không chứa sản phẩm thuộc quyền sở hữu của bạn!" 
                });
            }

            // 2. Tiến hành cập nhật trạng thái đơn và trạng thái giao hàng vào bảng donthue
            // (Bạn lưu ý kiểm tra chính xác tên cột TrangThaiDon / TrangThaiGiao trong DB của bạn nhé)
            const [result] = await execute(
                "UPDATE donthue SET TrangThaiDon = ?, TrangThaiGiaoHang = ? WHERE MaDonThue = ?",
                [trang_thai_don, trang_thai_giao || 'chưa giao', orderId]
            );

            if (result.affectedRows > 0) {
                return res.status(200).json({ 
                    succeeded: true, 
                    message: "Chủ đồ cập nhật trạng thái đơn hàng thành công!" 
                });
            } else {
                return res.status(400).json({ succeeded: false, message: "Cập nhật trạng thái thất bại." });
            }
        } catch (error) {
            return res.status(500).json({ succeeded: false, message: error.message });
        }
    }

    // 1. Thêm hàm này để chạy đường link /admin/orders
    static async getAllOrders(req, res) {
        try {
            // Gọi đến hàm lấy tất cả đơn đã có sẵn trong bảng 'donthue' của bạn
            const [orders] = await execute("SELECT * FROM donthue ORDER BY MaDonThue DESC");
            
            return res.status(200).json({
                succeeded: true,
                message: "Lấy danh sách tất cả đơn hàng thành công!",
                orders: orders
            });
        } catch (error) {
            return res.status(500).json({ succeeded: false, message: error.message });
        }
    }

    // 2. Thêm hàm này để chạy đường link /admin/approve-order/{orderId}
    // Hàm cập nhật trạng thái đơn hàng (Duyệt hoặc Hủy/Từ chối đơn)
    static async approveOrder(req, res) {
        try {
            const { orderId } = req.params;
            // Admin sẽ truyền trạng thái mong muốn lên qua Body (ví dụ: { "status": "cancelled" })
            // Nếu admin không truyền gì lên, mặc định hệ thống hiểu là muốn Duyệt đơn ('confirmed')
            const status = req.body.status || 'confirmed'; 

            // 1. Kiểm tra xem đơn hàng có tồn tại không và trạng thái hiện tại là gì
            const [rows] = await execute("SELECT TrangThaiDon FROM donthue WHERE MaDonThue = ?", [orderId]);
            if (rows.length === 0) {
                return res.status(444).json({ succeeded: false, message: "Không tìm thấy đơn hàng này trong hệ thống!" });
            }

            const currentStatus = rows[0].TrangThaiDon;

            // 2. NGĂN CHẶN LOGIC SAI: Nếu đơn đã bị hủy trước đó rồi thì KHÔNG cho duyệt hay hủy lại nữa
            if (currentStatus === 'cancelled') {
                return res.status(409).json({ 
                    succeeded: false, 
                    message: "Lỗi: Đơn hàng này đã bị hủy từ trước, không thể thay đổi trạng thái nữa!" 
                });
            }

            // 3. Tiến hành cập nhật trạng thái mới (confirmed hoặc cancelled) vào Database
            const [result] = await execute(
                "UPDATE donthue SET TrangThaiDon = ? WHERE MaDonThue = ?", 
                [status, orderId]
            );

            if (result.affectedRows > 0) {
                const msg = status === 'cancelled' ? "Từ chối và hủy đơn hàng thành công!" : "Duyệt đơn hàng thành công!";
                return res.status(200).json({ succeeded: true, message: msg });
            } else {
                return res.status(400).json({ succeeded: false, message: "Cập nhật thất bại." });
            }
        } catch (error) {
            return res.status(500).json({ succeeded: false, message: error.message });
        }
    }

    // =========================================================
    // API: KHÁCH HÀNG TỰ HỦY ĐƠN
    // =========================================================
    static async cancelOrder(req, res) {
        try {
            const userId = req.userid; // Lấy ID của người đang đăng nhập từ token
            const { orderId } = req.params; // Lấy mã đơn hàng từ trên URL

            // 1. Kiểm tra xem đơn này có đúng là của user này không
            const [rows] = await execute(
                "SELECT TrangThaiDon FROM donthue WHERE MaDonThue = ? AND MaKhachThue = ?", 
                [orderId, userId]
            );

            if (rows.length === 0) {
                return res.status(404).json({ 
                    succeeded: false, 
                    message: "Không tìm thấy đơn hàng, hoặc bạn không có quyền hủy đơn của người khác!" 
                });
            }

            const currentStatus = rows[0].TrangThaiDon;

            // 2. Luật: Chỉ cho phép khách tự hủy khi đơn còn đang "pending" (Chờ duyệt)
            if (currentStatus !== 'pending') {
                return res.status(400).json({ 
                    succeeded: false, 
                    message: "Bạn không thể tự hủy vì đơn hàng đã được shop xử lý! Vui lòng liên hệ hotline." 
                });
            }

            // 3. Tiến hành hủy đơn
            const [result] = await execute(
                "UPDATE donthue SET TrangThaiDon = 'cancelled' WHERE MaDonThue = ?", 
                [orderId]
            );

            if (result.affectedRows > 0) {
                return res.status(200).json({ succeeded: true, message: "Hủy đơn hàng thành công!" });
            } else {
                return res.status(400).json({ succeeded: false, message: "Hủy đơn hàng thất bại." });
            }
        } catch (error) {
            return res.status(500).json({ succeeded: false, message: error.message });
        }
    }

    // =========================================================
    // CONTROLLER: TRẢ VỀ DỮ LIỆU DASHBOARD CHO ADMIN
    // =========================================================
    static async getAdminDashboard(req, res) {
        try {
            // Gọi sang Model để lấy bộ số liệu
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

    // =========================================================================
    // CONTROLLER: TIẾP NHẬN YÊU CẦU KHIẾU NẠI TỪ USER
    // =========================================================================
    static async createComplaint(req, res) {
        try {
            const { orderId } = req.params;
            const { ly_do, loai_khieu_nai, hinh_anh } = req.body; 
            
            // Lấy ID người dùng từ middleware auth[cite: 26]
            const userId = req.userid; 
            
            if (!userId) {
                return res.status(401).json({ succeeded: false, message: "Bạn chưa đăng nhập!" });
            }

            // Bắt buộc phải có lý do khiếu nại
            if (!ly_do) {
                return res.status(400).json({ succeeded: false, message: "Vui lòng nhập lý do khiếu nại!" });
            }

            // Gọi xuống Model để thực hiện lưu DB
            const complaintId = await orderModel.insertComplaint(
                orderId, 
                userId, 
                loai_khieu_nai, 
                ly_do, 
                hinh_anh
            );
            
            return res.status(200).json({ 
                succeeded: true,
                message: "Đã gửi khiếu nại thành công! Hệ thống đã đóng băng giao dịch để Admin phân xử.",
                complaint_id: complaintId
            });
        } catch (error) {
            return res.status(500).json({ 
                succeeded: false, 
                message: error.message 
            });
        }
    }

    // =========================================================================
    // CONTROLLER: ADMIN PHÂN XỬ KHIẾU NẠI
    // =========================================================================
    static async adminResolveComplaint(req, res) {
        try {
            const { complaintId } = req.params; // Lấy ID khiếu nại từ URL
            const { hinh_thuc_id, so_tien, noi_dung, trang_thai_don_moi } = req.body;
            
            const adminId = req.userid; // Bắt buộc dùng token của Admin

            if (!hinh_thuc_id) {
                return res.status(400).json({ succeeded: false, message: "Vui lòng chọn hình thức xử lý!" });
            }

            await orderModel.resolveComplaint(
                complaintId, 
                adminId, 
                hinh_thuc_id, 
                so_tien, 
                noi_dung, 
                trang_thai_don_moi
            );

            return res.status(200).json({ 
                succeeded: true,
                message: "Đã phân xử khiếu nại thành công!"
            });
        } catch (error) {
            return res.status(500).json({ succeeded: false, message: error.message });
        }
    }

    // =========================================================================
    // CONTROLLER: ADMIN LẤY DANH SÁCH KHIẾU NẠI CHỜ XỬ LÝ
    // =========================================================================
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

    // =========================================================================
    // CONTROLLER: KHÁCH HÀNG THANH TOÁN ĐƠN THUÊ
    // =========================================================================
    static async payOrder(req, res) {
        try {
            const { orderId } = req.params;
            const { so_tien } = req.body; 
            const userId = req.userid; // Lấy từ Token đăng nhập của khách

            if (!so_tien || isNaN(so_tien) || so_tien <= 0) {
                return res.status(400).json({ 
                    succeeded: false, 
                    message: "Vui lòng cung cấp số tiền hợp lệ cần thanh toán!" 
                });
            }

            // Gọi model xử lý 5 bước giao dịch
            await orderModel.processPaymentEscrow(orderId, userId, so_tien);

            return res.status(200).json({
                succeeded: true,
                message: "Thanh toán thành công! Tiền của bạn đã được hệ thống tạm giữ an toàn."
            });

        } catch (error) {
            return res.status(400).json({ 
                succeeded: false, 
                message: error.message 
            });
        }
    }

    // =========================================================================
    // CONTROLLER: THANH TOÁN VÀ GIẢI NGÂN
    // =========================================================================
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
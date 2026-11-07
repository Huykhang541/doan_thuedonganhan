import { Router } from "express";
import auth from "../middleware/auth.js";
import admin from "../middleware/admin.js";
import orderController from "../controllers/orderController.js";

const orderRoutes = Router();
const authOrderRoutes = Router();

authOrderRoutes.use(auth); // Tất cả API dưới đây đều yêu cầu đăng nhập

// =========================================================================
// 🛒 API DÀNH CHO: KHÁCH ĐI THUÊ ĐỒ (Renter)
// =========================================================================

/**
 * @swagger
 * /orders:
 *   post:
 *     summary: "[Khách thuê] Tạo đơn thuê đồ mới (Checkout)"
 *     tags:
 *       - "Orders - Khách thuê"
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               fullName:
 *                 type: string
 *                 example: "Nguyễn Văn Khách"
 *               phone:
 *                 type: string
 *                 example: "0901234567"
 *               address:
 *                 type: string
 *                 example: "123 Đường Cắm Trại"
 *               city:
 *                 type: string
 *                 example: "Hồ Chí Minh"
 *               payment_method:
 *                 type: string
 *                 example: "cod"
 *               is_buy_now:
 *                 type: boolean
 *                 example: false
 *               NgayThue:
 *                 type: string
 *                 example: "2026-07-01"
 *               NgayTra:
 *                 type: string
 *                 example: "2026-07-03"
 *               order_details:
 *                 type: array
 *                 items:
 *                   type: object
 *     responses:
 *       201:
 *         description: Đặt đơn thành công
 */
authOrderRoutes.post("/", orderController.createOrder);

/**
 * @swagger
 * /orders/cancel/{orderId}:
 *   put:
 *     summary: "[Khách thuê] Tự hủy đơn hàng (Chỉ khi đơn ở trạng thái pending)"
 *     tags:
 *       - "Orders - Khách thuê"
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: orderId
 *         required: true
 *         schema:
 *           type: integer
 *     responses:
 *       200:
 *         description: Hủy đơn thành công
 */
authOrderRoutes.put("/cancel/:orderId", orderController.cancelOrder);

/**
 * @swagger
 * /orders/{orderId}/complaint:
 *   post:
 *     summary: "Gửi khiếu nại và đóng băng đơn hàng (Dành cho Khách hoặc Chủ đồ)"
 *     tags:
 *       - "Orders - Khách thuê"
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: orderId
 *         required: true
 *         schema:
 *           type: integer
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               loai_khieu_nai:
 *                 type: string
 *                 example: "Hàng bị hư hỏng"
 *               ly_do:
 *                 type: string
 *                 example: "Tôi nhận được một cục gạch thay vì lều cắm trại!"
 *               hinh_anh:
 *                 type: string
 *                 example: "url_anh_cuc_gach.jpg"
 *     responses:
 *       200:
 *         description: Gửi khiếu nại thành công
 */
authOrderRoutes.post("/:orderId/complaint", orderController.createComplaint);


// =========================================================================
// BỔ SUNG 1: KHÁCH THUÊ XEM DANH SÁCH YÊU CẦU ĐÃ GỬI
// =========================================================================
/**
 * @swagger
 * /orders/my-orders:
 *   get:
 *     summary: "[Khách thuê] Xem danh sách yêu cầu thuê đã gửi (Lịch sử đặt)"
 *     tags:
 *       - "Orders - Khách thuê"
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Lấy lịch sử đặt thành công
 *       401:
 *         description: Chưa đăng nhập
 *       500:
 *         description: Lỗi hệ thống
 */
orderRoutes.get('/my-orders', auth, orderController.getMyOrders);

/**
 * @swagger
 * /orders/{orderId}/pay:
 *   post:
 *     summary: "Khách hàng thanh toán đơn thuê (Tạm giữ tiền qua Ví Hệ Thống)"
 *     tags:
 *       - "Orders - Khách thuê"
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: orderId
 *         required: true
 *         schema:
 *           type: integer
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               so_tien:
 *                 type: number
 *                 example: 500000
 *                 description: "Tổng tiền cần thanh toán cho đơn hàng"
 *     responses:
 *       200:
 *         description: Thanh toán thành công, tiền đã được đóng băng.
 */
authOrderRoutes.post("/:orderId/pay", orderController.payOrder);

// =========================================================================
// 🚀 API MỚI THÊM: HOÀN TẤT ĐƠN HÀNG VÀ GIẢI NGÂN
// =========================================================================
/**
 * @swagger
 * /orders/{orderId}/complete:
 *   put:
 *     summary: "Hoàn tất đơn hàng & Giải ngân tiền (Luồng suôn sẻ)"
 *     tags:
 *       - "Orders - Khách thuê / Chủ cho thuê"
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: orderId
 *         required: true
 *         schema:
 *           type: integer
 *     responses:
 *       200:
 *         description: Đã hoàn tất đơn hàng và giải ngân tiền cho các bên thành công!
 */
authOrderRoutes.put("/:orderId/complete", orderController.completeOrder);

// =========================================================================
// ⛺ API DÀNH CHO: CHỦ CÓ ĐỒ CHO THUÊ (Lessor)
// =========================================================================

/**
 * @swagger
 * /orders/lessor/status/{orderId}:
 *   put:
 *     summary: "[Chủ đồ] Duyệt đơn hàng hoặc Cập nhật tiến độ giao đồ"
 *     tags:
 *       - "Orders - Chủ cho thuê"
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: orderId
 *         required: true
 *         schema:
 *           type: integer
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               trang_thai_don:
 *                 type: string
 *                 example: "confirmed"
 *                 description: "confirmed (Chấp nhận), cancelled (Từ chối duyệt)"
 *               trang_thai_giao:
 *                 type: string
 *                 example: "đang giao"
 *                 description: "chưa giao, đang giao, đã giao"
 *     responses:
 *       200:
 *         description: Chủ đồ cập nhật thành công
 */
authOrderRoutes.put(
  "/lessor/status/:orderId",
  orderController.lessorUpdateStatus
);

// =========================================================================
// BỔ SUNG 2: CHỦ CHO THUÊ XEM DANH SÁCH YÊU CẦU NHẬN ĐƯỢC
// =========================================================================
/**
 * @swagger
 * /orders/lessor/requests:
 *   get:
 *     summary: "[Chủ đồ] Xem danh sách các yêu cầu thuê đồ nhận được từ khách"
 *     tags:
 *       - "Orders - Chủ cho thuê"
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Lấy danh sách yêu cầu thuê thành công
 *       401:
 *         description: Chưa đăng nhập
 *       500:
 *         description: Lỗi hệ thống
 */
orderRoutes.get('/lessor/requests', auth, orderController.getLessorRequests);

// =========================================================================
// 👑 API DÀNH CHO: ADMIN HỆ THỐNG
// =========================================================================

/**
 * @swagger
 * /orders/admin/dashboard:
 *   get:
 *     summary: "[Admin] Xem số liệu tổng quan toàn sàn (Doanh thu, tổng số đơn...)"
 *     tags:
 *       - "Orders - Admin Tổng"
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Lấy dữ liệu thành công
 */
orderRoutes.get("/admin/dashboard", admin, orderController.getAdminDashboard);

// =========================================================================
// API ADMIN: TRẢ ĐỒ, HOÀN CỌC VÀ PHẠT TỰ ĐỘNG
// =========================================================================
/**
 * @swagger
 * /orders/admin/return-order/{orderId}:
 *   put:
 *     summary: "[Admin] Xác nhận khách trả đồ (Tự động tính phạt trễ hạn & Hoàn cọc)"
 *     tags:
 *       - "Admin Orders"
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: orderId
 *         required: true
 *         schema:
 *           type: integer
 *     requestBody:
 *       required: false
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               tien_phat_hu_hong:
 *                 type: number
 *                 example: 0
 *                 description: "Tiền phạt thêm nếu làm hỏng đồ (Không bắt buộc, phạt trễ hạn máy đã tự tính)"
 *               ghi_chu:
 *                 type: string
 *                 example: "Khách trả đồ đầy đủ"
 *     responses:
 *       200:
 *         description: Xác nhận trả đồ và tính tiền thành công
 */
orderRoutes.put("/admin/return-order/:orderId", admin, orderController.returnOrder);


/**
 * @swagger
 * /orders/admin/complaint/{complaintId}/resolve:
 *   put:
 *     summary: "[Admin] Phân xử khiếu nại"
 *     tags:
 *       - "Orders - Admin Tổng"
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: complaintId
 *         required: true
 *         schema:
 *           type: integer
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               hinh_thuc_id:
 *                 type: integer
 *                 example: 1
 *                 description: "ID hình thức xử lý (1 đến 4)"
 *               so_tien:
 *                 type: number
 *                 example: 500000
 *                 description: "Số tiền bồi thường/hoàn lại (nếu có)"
 *               noi_dung:
 *                 type: string
 *                 example: "Admin xác nhận chủ đồ lừa đảo, hoàn 100% tiền."
 *               trang_thai_don_moi:
 *                 type: string
 *                 example: "resolved"
 *                 description: "Trạng thái mới của đơn hàng sau khi gỡ băng"
 *     responses:
 *       200:
 *         description: Xử lý thành công
 */
orderRoutes.put("/admin/complaint/:complaintId/resolve", admin, orderController.adminResolveComplaint);

/**
 * @swagger
 * /orders/admin/complaints/pending:
 *   get:
 *     summary: "[Admin] Lấy danh sách khiếu nại đang chờ xử lý"
 *     tags:
 *       - "Orders - Admin Tổng"
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Lấy danh sách thành công
 */
orderRoutes.get("/admin/complaints/pending", admin, orderController.getPendingComplaints);


// Kích hoạt toàn bộ định tuyến
orderRoutes.use("/", authOrderRoutes);

export default orderRoutes;
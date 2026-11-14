import { Router } from "express";
import auth from "../middleware/auth.js";
import admin from "../middleware/admin.js";
import orderController from "../controllers/orderController.js";

const orderRoutes = Router();

// =========================================================================
// 1. NHÓM KHÁCH THUÊ ĐỒ (RENTER) - YÊU CẦU ĐĂNG NHẬP (AUTH)
// =========================================================================

/**
 * @swagger
 * /orders:
 *   post: { summary: "[Khách thuê] Tạo đơn thuê đồ mới (Checkout)", tags: [1. Khách Thuê - Renter], security: [{ bearerAuth: [] }] }
 */
orderRoutes.post("/", auth, orderController.createOrder);

/**
 * @swagger
 * /orders/my-orders:
 *   get: { summary: "[Khách thuê] Xem danh sách yêu cầu thuê đã gửi (Lịch sử đặt)", tags: [1. Khách Thuê - Renter], security: [{ bearerAuth: [] }] }
 */
orderRoutes.get('/my-orders', auth, orderController.getMyOrders);

/**
 * @swagger
 * /orders/{orderId}/pay:
 *   post: { summary: "[Khách thuê] Thanh toán đơn thuê (Tạm giữ tiền qua Ví Hệ Thống)", tags: [1. Khách Thuê - Renter], security: [{ bearerAuth: [] }] }
 */
orderRoutes.post("/:orderId/pay", auth, orderController.payOrder);

/**
 * @swagger
 * /orders/cancel/{orderId}:
 *   put: { summary: "[Khách thuê] Tự hủy đơn hàng (Chỉ khi đơn ở trạng thái pending)", tags: [1. Khách Thuê - Renter], security: [{ bearerAuth: [] }] }
 */
orderRoutes.put("/cancel/:orderId", auth, orderController.cancelOrder);

/**
 * @swagger
 * /orders/{orderId}/complaint:
 *   post: { summary: "[Khách thuê/Chủ đồ] Gửi khiếu nại và đóng băng đơn hàng", tags: [1. Khách Thuê - Renter], security: [{ bearerAuth: [] }] }
 */
orderRoutes.post("/:orderId/complaint", auth, orderController.createComplaint);

/**
 * @swagger
 * /orders/{orderId}/complete:
 *   put: { summary: "[Khách thuê/Chủ đồ] Hoàn tất đơn hàng & Giải ngân tiền", tags: [1. Khách Thuê - Renter], security: [{ bearerAuth: [] }] }
 */
orderRoutes.put("/:orderId/complete", auth, orderController.completeOrder);

/**
 * @swagger
 * /orders/detail/{orderID}:
 *   get: { summary: "[Khách thuê] Xem chi tiết 1 đơn hàng", tags: [1. Khách Thuê - Renter], security: [{ bearerAuth: [] }] }
 */
// ĐÃ FIX PHÍA FLUTTER ĐỂ GỌI ĐÚNG ĐƯỜNG DẪN /detail/:orderID
orderRoutes.get('/detail/:orderID', auth, orderController.getOrderDetail);


// =========================================================================
// 2. NHÓM CHỦ CHO THUÊ (LESSOR) - YÊU CẦU ĐĂNG NHẬP (AUTH)
// =========================================================================

/**
 * @swagger
 * /orders/lessor/requests:
 *   get: { summary: "[Chủ đồ] Xem danh sách các yêu cầu thuê đồ nhận được từ khách", tags: [2. Chủ Cho Thuê - Lessor], security: [{ bearerAuth: [] }] }
 */
orderRoutes.get('/lessor/requests', auth, orderController.getLessorRequests);

/**
 * @swagger
 * /orders/lessor/status/{orderId}:
 *   put: { summary: "[Chủ đồ] Duyệt đơn hàng hoặc Cập nhật tiến độ giao đồ", tags: [2. Chủ Cho Thuê - Lessor], security: [{ bearerAuth: [] }] }
 */
orderRoutes.put("/lessor/status/:orderId", auth, orderController.lessorUpdateStatus);


// =========================================================================
// 3. NHÓM QUẢN TRỊ VIÊN (ADMIN) - YÊU CẦU ĐĂNG NHẬP (ADMIN)
// =========================================================================

/**
 * @swagger
 * /orders/admin/orders:
 *   get: { summary: "[Admin] Xem tất cả đơn hàng", tags: [3. Quản Trị Viên - Admin], security: [{ bearerAuth: [] }] }
 */
// ĐÃ BỔ SUNG ROUTE ADMIN GET ALL ORDERS 
orderRoutes.get("/admin/orders", admin, orderController.getAllOrders);

/**
 * @swagger
 * /orders/admin/dashboard:
 *   get: { summary: "[Admin] Xem số liệu tổng quan toàn sàn (Doanh thu, tổng số đơn...)", tags: [3. Quản Trị Viên - Admin], security: [{ bearerAuth: [] }] }
 */
orderRoutes.get("/admin/dashboard", admin, orderController.getAdminDashboard);

/**
 * @swagger
 * /orders/admin/approve-order/{orderId}:
 *   put: { summary: "[Admin] Duyệt / Hủy đơn hàng", tags: [3. Quản Trị Viên - Admin], security: [{ bearerAuth: [] }] }
 */
// ĐÃ BỔ SUNG ROUTE ADMIN PHÊ DUYỆT ĐƠN 
orderRoutes.put("/admin/approve-order/:orderId", admin, orderController.approveOrder);

/**
 * @swagger
 * /orders/admin/return-order/{orderId}:
 *   put: { summary: "[Admin] Xác nhận khách trả đồ (Tự động tính phạt trễ hạn & Hoàn cọc)", tags: [3. Quản Trị Viên - Admin], security: [{ bearerAuth: [] }] }
 */
orderRoutes.put("/admin/return-order/:orderId", admin, orderController.returnOrder);

/**
 * @swagger
 * /orders/admin/complaints/pending:
 *   get: { summary: "[Admin] Lấy danh sách khiếu nại đang chờ xử lý", tags: [3. Quản Trị Viên - Admin], security: [{ bearerAuth: [] }] }
 */
orderRoutes.get("/admin/complaints/pending", admin, orderController.getPendingComplaints);

/**
 * @swagger
 * /orders/admin/complaint/{complaintId}/resolve:
 *   put: { summary: "[Admin] Phân xử khiếu nại", tags: [3. Quản Trị Viên - Admin], security: [{ bearerAuth: [] }] }
 */
orderRoutes.put("/admin/complaint/:complaintId/resolve", admin, orderController.adminResolveComplaint);


export default orderRoutes;
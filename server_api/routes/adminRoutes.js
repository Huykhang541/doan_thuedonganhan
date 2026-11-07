import { Router } from "express";
const adminRoutes = Router();
import userController from "../controllers/userController.js";
import auth from "../middleware/auth.js";
import admin from "../middleware/admin.js";
import orderController from "../controllers/orderController.js";
// BỔ SUNG: Import productController để xử lý duyệt sản phẩm
import productController from "../controllers/productController.js";

/**
 * @swagger
 * tags:
 *   name: Admin
 *   description: API quản trị hệ thống
 */

const adminAuthRoutes = Router();
adminAuthRoutes.use(auth, admin);

/**
 * @swagger
 * /admin/login:
 *   post:
 *     summary: Đăng nhập tài khoản admin
 *     tags: [Admin]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - email
 *               - password
 *             properties:
 *               email:
 *                 type: string
 *                 example: admin@gmail.com
 *               password:
 *                 type: string
 *                 example: Admin@123
 *     responses:
 *       200:
 *         description: Đăng nhập thành công, trả về JWT
 */
adminRoutes.post('/login', userController.adminLogin);

/**
 * @swagger
 * /admin/logout:
 *   post:
 *     summary: Đăng xuất admin
 *     tags: [Admin]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Đăng xuất thành công
 */
adminAuthRoutes.post('/logout', userController.logout);

/**
 * @swagger
 * /admin/users:
 *   get:
 *     summary: Lấy danh sách tất cả người dùng
 *     tags: [Admin]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Lấy danh sách người dùng thành công
 */
adminAuthRoutes.get('/users', userController.getAllUsers);

/**
 * @swagger
 * /admin/orders:
 *   get:
 *     summary: Lấy danh sách tất cả hóa đơn (Admin)
 *     tags: [Admin Orders]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Lấy danh sách thành công
 */
adminAuthRoutes.get('/orders', orderController.getAllOrder);

/**
 * @swagger
 * /admin/approve-order/{orderId}:
 *   patch:
 *     summary: Admin thay đổi trạng thái đơn hàng
 *     tags: [Admin Orders]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: orderId
 *         required: true
 *         schema:
 *           type: string
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - status
 *             properties:
 *               status:
 *                 type: string
 *                 example: processing
 *     responses:
 *       200:
 *         description: Duyệt đơn hàng thành công
 */
adminAuthRoutes.patch('/approve-order/:orderId', orderController.approveOrder);

/**
 * @swagger
 * /admin/lock-user/{userId}:
 *   patch:
 *     summary: Admin khóa hoặc mở khóa tài khoản lừa đảo
 *     tags: [Admin]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: userId
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
 *               action:
 *                 type: string
 *                 example: lock
 *     responses:
 *       200:
 *         description: Thao tác thành công
 */
adminAuthRoutes.patch("/lock-user/:userId", userController.lockUserAccount);


// =========================================================================
// BỔ SUNG: API ADMIN KIỂM DUYỆT SẢN PHẨM ĐĂNG TẢI (Đúng yêu cầu file PDF)
// =========================================================================
/**
 * @swagger
 * /admin/approve-product/{productId}:
 *   patch:
 *     summary: Admin kiểm duyệt sản phẩm đăng tải
 *     tags: [Admin]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: productId
 *         required: true
 *         schema:
 *           type: integer
 *         description: ID của sản phẩm cần duyệt
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - status
 *             properties:
 *               status:
 *                 type: string
 *                 enum: ['SanSang', 'TuChoi']
 *                 example: SanSang
 *                 description: Nhập 'SanSang' để duyệt, 'TuChoi' để từ chối đăng bài
 *     responses:
 *       200:
 *         description: Thay đổi trạng thái sản phẩm thành công
 *       400:
 *         description: Trạng thái truyền lên không hợp lệ
 *       404:
 *         description: Không tìm thấy sản phẩm
 *       500:
 *         description: Lỗi hệ thống
 */
adminAuthRoutes.patch("/approve-product/:productId", productController.approveProduct);

// =========================================================================
// BỔ SUNG: API ADMIN XÓA SẢN PHẨM VI PHẠM
// =========================================================================
/**
 * @swagger
 * /admin/delete-product/{productId}:
 *   delete:
 *     summary: Admin xóa vĩnh viễn sản phẩm vi phạm
 *     tags: [Admin]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: productId
 *         required: true
 *         schema:
 *           type: integer
 *         description: ID của sản phẩm vi phạm cần xóa khỏi hệ thống
 *     responses:
 *       200:
 *         description: Xóa sản phẩm thành công
 *       404:
 *         description: Không tìm thấy sản phẩm
 *       500:
 *         description: Lỗi hệ thống
 */
adminAuthRoutes.delete("/delete-product/:productId", productController.adminDeleteProduct);


adminRoutes.use('/', adminAuthRoutes);
export default adminRoutes;
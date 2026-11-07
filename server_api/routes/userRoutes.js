import { Router } from "express";
const userRoutes = Router();
import userController from "../controllers/userController.js";
import auth from "../middleware/auth.js";
/**
 * @swagger
 * tags:
 *   name: Users
 *   description: API người dùng & xác thực
 */
const authRoutes = Router();
authRoutes.use(auth);

/**
 * @swagger
 * /register:
 *   post:
 *     summary: Đăng ký tài khoản mới
 *     tags:
 *       - Users
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - email
 *               - password
 *               - fullName
 *               - phoneNumber
 *               - address
 *             properties:
 *               email:
 *                 type: string
 *                 format: email
 *                 example: user@example.com
 *               password:
 *                 type: string
 *                 format: password
 *                 example: Pass@1234
 *               fullName:
 *                 type: string
 *                 example: Nguyễn Văn A
 *               phoneNumber:
 *                 type: string
 *                 example: "0987654321"
 *               address:
 *                 type: string
 *                 example: "123 Đường ABC, Quận 1, TP.HCM"
 *     responses:
 *       201:
 *         description: Đăng ký thành công
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 succeeded:
 *                   type: boolean
 *                   example: true
 *                 message:
 *                   type: string
 *                   example: Đăng ký thành công
 *                 user_id:
 *                   type: integer
 *                   example: 10
 *       400:
 *         description: Thiếu thông tin hoặc Email đã tồn tại
 */
userRoutes.post('/register',userController.register);
/**
 * @swagger
 * /login:
 *   post:
 *     summary: Đăng nhập (User)
 *     tags:
 *       - Users
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
 *                 example: user@example.com
 *               password:
 *                 type: string
 *                 example: Pass@1234
 *     responses:
 *       200:
 *         description: Đăng nhập thành công
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 succeeded:
 *                   type: boolean
 *                   example: true
 *                 token:
 *                   type: string
 *                   description: JWT Token dùng để xác thực các request sau
 *       401:
 *         description: Sai email hoặc mật khẩu
 */
userRoutes.post('/login',userController.login);
/**
 * @swagger
 * /logout:
 *   post:
 *     summary: Đăng xuất người dùng
 *     tags: [Users]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Đăng xuất thành công
 *       400:
 *         description: Token không hợp lệ
 */
authRoutes.post('/logout',userController.logout);
/**
 * @swagger
 * /profile:
 *   get:
 *     summary: Xem thông tin cá nhân
 *     tags:
 *       - Users
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Lấy thông tin thành công
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 succeeded:
 *                   type: boolean
 *                   example: true
 *                 user:
 *                   type: object
 *                   properties:
 *                     id:
 *                       type: integer
 *                     fullname:
 *                       type: string
 *                     email:
 *                       type: string
 *                     phone_number:
 *                       type: string
 *                     address:
 *                       type: string
 *       401:
 *         description: Chưa đăng nhập (Thiếu token)
 */
authRoutes.get('/profile',userController.profile);
/**
 * @swagger
 * /updateprofile:
 *   put:
 *     summary: Cập nhật thông tin cá nhân
 *     tags:
 *       - Users
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - fullName
 *               - phoneNumber
 *               - address
 *             properties:
 *               fullName:
 *                 type: string
 *                 example: "Nguyễn Văn B"
 *               phoneNumber:
 *                 type: string
 *                 example: "0123456789"
 *               address:
 *                 type: string
 *                 example: "Hà Nội"
 *     responses:
 *       200:
 *         description: Cập nhật thành công
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 succeeded:
 *                   type: boolean
 *                   example: true
 *                 message:
 *                   type: string
 *                   example: Đổi thông tin thành công
 *       400:
 *         description: Thiếu thông tin đầu vào
 */
authRoutes.put('/updateprofile',userController.updateUser);

/**
 * @swagger
 * /change-password:
 *   patch:
 *     summary: Đổi mật khẩu người dùng
 *     description: Người dùng phải đăng nhập mới được đổi mật khẩu
 *     tags:
 *       - Users
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - newPassword
 *               - currentPassword
 *             properties:
 *               newPassword:
 *                 type: string
 *                 format: password
 *                 description: Mật khẩu mới
 *                 example: NewPass@123
 *               currentPassword:
 *                 type: string
 *                 format: password
 *                 description: Mật khẩu hiện tại
 *                 example: CurrentPass@123
 *     responses:
 *       200:
 *         description: Đổi mật khẩu thành công
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 succeeded:
 *                   type: boolean
 *                   example: true
 *                 message:
 *                   type: string
 *                   example: Đổi mật khẩu thành công
 *       400:
 *         description: Thiếu thông tin mật khẩu mới
 *       401:
 *         description: Chưa đăng nhập (Token không hợp lệ)
 *       500:
 *         description: Lỗi server
 */
authRoutes.patch('/change-password',userController.changePassword);

userRoutes.use('/',authRoutes);
export default userRoutes;

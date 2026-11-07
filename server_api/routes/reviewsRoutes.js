import express from "express";
import reviewsController from "../controllers/reviewsController.js";
import auth from "../middleware/auth.js"; // Import đúng middleware auth của dự án

const router = express.Router();

/**
 * @swagger
 * /api/reviews/{product_id}:
 *   get:
 *     summary: Lấy danh sách đánh giá của 1 sản phẩm
 *     tags: [Reviews]
 *     parameters:
 *       - in: path
 *         name: product_id
 *         required: true
 *         schema:
 *           type: integer
 *     responses:
 *       200:
 *         description: Thành công
 */
router.get("/:product_id", reviewsController.getReviewProduct);

/**
 * @swagger
 * /api/reviews/add:
 *   post:
 *     summary: Thêm đánh giá mới cho sản phẩm (Cần đăng nhập)
 *     tags: [Reviews]
 *     security:
 *       - bearerAuth: [] 
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               product_id:
 *                 type: integer
 *               rating:
 *                 type: integer
 *               comment:
 *                 type: string
 *     responses:
 *       200:
 *         description: Thành công
 */
router.post("/add", auth, reviewsController.addReview); 

export default router;
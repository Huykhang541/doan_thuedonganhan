import { Router } from "express";
import favoriteController from "../controllers/favoriteController.js";
import auth from "../middleware/auth.js";

const favoriteRoute = Router();

favoriteRoute.use(auth);

/**
 * @swagger
 * /favorites:
 *   get:
 *     summary: Lấy danh sách sản phẩm yêu thích của tôi
 *     tags: [Favorites]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Thành công
 */
favoriteRoute.get("/", favoriteController.getListFavoriteByUserID);

/**
 * @swagger
 * /favorites/add/{product_id}:
 *   post:
 *     summary: Thêm sản phẩm vào danh sách yêu thích
 *     tags: [Favorites]
 *     security:
 *       - bearerAuth: []
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
favoriteRoute.post("/add/:product_id", favoriteController.addFavorite);

/**
 * @swagger
 * /favorites/remove/{product_id}:
 *   delete:
 *     summary: Xóa sản phẩm khỏi danh sách yêu thích
 *     tags: [Favorites]
 *     security:
 *       - bearerAuth: []
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
favoriteRoute.delete("/remove/:product_id", favoriteController.removeFavorite);

export default favoriteRoute;
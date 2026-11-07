import { Router } from "express";
import productController from "../controllers/productController.js";
import auth from "../middleware/auth.js"; // Middleware check token

const productRoute = Router();

// =========================================================================
// 1. NHÓM KHÁCH HÀNG (PUBLIC) - KHÔNG CẦN ĐĂNG NHẬP
// =========================================================================

/**
 * @swagger
 * /products:
 *   get: { summary: Lấy danh sách tất cả sản phẩm, tags: [1. Khách Hàng - Public] }
 */
productRoute.get("/", productController.products);

/**
 * @swagger
 * /products/search:
 *   get: { summary: Tìm kiếm sản phẩm theo tên và bộ lọc, tags: [1. Khách Hàng - Public] }
 */
productRoute.get("/search", productController.searchProduct);

/**
 * @swagger
 * /products/product-variants/get-all:
 *   get: { summary: Lấy tất cả các biến thể sản phẩm, tags: [1. Khách Hàng - Public] }
 */
productRoute.get("/product-variants/get-all", productController.getAllProductVariant);

/**
 * @swagger
 * /products/product-variants/{product_id}:
 *   get: { summary: Lấy biến thể của 1 sản phẩm cụ thể, tags: [1. Khách Hàng - Public] }
 */
productRoute.get("/product-variants/:product_id", productController.getProductVariantByProductId);


// =========================================================================
// 2. NHÓM CHỦ CHO THUÊ (LESSOR) - YÊU CẦU ĐĂNG NHẬP (AUTH)
// =========================================================================

/**
 * @swagger
 * /products/lessor/my-products:
 *   get: { summary: Lấy danh sách sản phẩm của chính tôi, tags: [2. Chủ Cho Thuê - Lessor], security: [{ bearerAuth: [] }] }
 */
productRoute.get("/lessor/my-products", auth, productController.getMyProducts);

/**
 * @swagger
 * /products/lessor/create:
 *   post: { summary: Thêm sản phẩm cho thuê mới, tags: [2. Chủ Cho Thuê - Lessor], security: [{ bearerAuth: [] }] }
 */
productRoute.post("/lessor/create", auth, productController.createProduct);

/**
 * @swagger
 * /products/lessor/update/{id}:
 *   put: { summary: Cập nhật thông tin sản phẩm của tôi, tags: [2. Chủ Cho Thuê - Lessor], security: [{ bearerAuth: [] }] }
 */
productRoute.put("/lessor/update/:id", auth, productController.updateProduct);

/**
 * @swagger
 * /products/lessor/delete/{id}:
 *   delete: { summary: Xóa sản phẩm của tôi, tags: [2. Chủ Cho Thuê - Lessor], security: [{ bearerAuth: [] }] }
 */
productRoute.delete("/lessor/delete/:id", auth, productController.deleteProduct);


// =========================================================================
// 3. NHÓM QUẢN TRỊ VIÊN (ADMIN) - YÊU CẦU ĐĂNG NHẬP (AUTH)
// =========================================================================

/**
 * @swagger
 * /products/admin/approve-product/{productId}:
 *   patch: { summary: Duyệt hoặc từ chối sản phẩm (SanSang / TuChoi), tags: [3. Quản Trị Viên - Admin], security: [{ bearerAuth: [] }] }
 */
productRoute.patch("/admin/approve-product/:productId", auth, productController.approveProduct);

/**
 * @swagger
 * /products/admin/delete-product/{productId}:
 *   delete: { summary: Xóa vĩnh viễn sản phẩm vi phạm, tags: [3. Quản Trị Viên - Admin], security: [{ bearerAuth: [] }] }
 */
productRoute.delete("/admin/delete-product/:productId", auth, productController.adminDeleteProduct);


// =========================================================================
// LƯU Ý: HÀM LẤY CHI TIẾT THEO ID PHẢI NẰM Ở DƯỚI CÙNG ĐỂ KHÔNG BỊ LỖI ROUTE
// =========================================================================
/**
 * @swagger
 * /products/{id}:
 *   get: { summary: Xem chi tiết 1 sản phẩm theo ID, tags: [1. Khách Hàng - Public] }
 */
productRoute.get("/:id", productController.detailProduct);

export default productRoute;
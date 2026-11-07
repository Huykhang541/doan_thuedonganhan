import productModel from '../models/productModel.js';

export default class productController {

    // =========================================================================
    // 1. NHÓM KHÁCH HÀNG (PUBLIC) - AI CŨNG XEM ĐƯỢC
    // =========================================================================
    
    // Lấy danh sách tất cả sản phẩm hiển thị ra trang chủ
    static async products(req, res) {
        try {
            const products = await productModel.allproduct();
            return res.status(200).json({ succeeded: true, products: products });
        } catch (error) { return res.status(500).json({ succeeded: false, message: error.message }); }
    }
    
    // Lọc và tìm kiếm sản phẩm theo tên, khoảng giá, danh mục...
    static async searchProduct(req, res) {
        try {
            const { name, min_price, max_price, category_id, min_rent_price, max_rent_price } = req.query;
            const products = await productModel.searchProduct({ name, min_price, max_price, category_id, min_rent_price, max_rent_price });
            return res.status(200).json({ succeeded: true, message: "Tìm kiếm thành công", products: products });
        } catch (error) { return res.status(500).json({ succeeded: false, message: error.message }); }
    }

    // Lấy tất cả biến thể sản phẩm (Màu sắc, kích cỡ,...)
    static async getAllProductVariant(req, res) {
        try {
            const product_variant = await productModel.getProductVariants();
            return res.status(200).json({ succeeded: true, product_variants: product_variant });
        } catch (error) { return res.status(500).json({ succeeded: false, message: error.message }); }
    }

    // Lấy biến thể của 1 sản phẩm cụ thể (Ví dụ: Các màu của Lều Cam)
    static async getProductVariantByProductId(req, res) {
        try {
            const { product_id } = req.params;
            if (!product_id) return res.status(400).json({ succeeded: false, message: "Thiếu id sản phẩm" });
            const products = await productModel.findProductVariantByProductID(product_id);
            return res.status(200).json({ succeeded: true, message: "Lấy biến thể thành công", product_variants: products });
        } catch (error) { return res.status(500).json({ succeeded: false, message: error.message }); }
    }

    // Xem chi tiết 1 sản phẩm (Khi click vào 1 ô sản phẩm)
    static async detailProduct(req, res) {
        try {
            const { id } = req.params;
            if (!id) return res.status(400).json({ succeeded: false, message: "ID sản phẩm không được để trống" });
            const product = await productModel.findProductById(id);
            if (!product) return res.status(404).json({ succeeded: false, message: "ID sản phẩm không tồn tại" });
            return res.status(200).json({ succeeded: true, message: "Lấy chi tiết thành công", product: product });
        } catch (error) { return res.status(500).json({ succeeded: false, message: error.message }); }
    }


    // =========================================================================
    // 2. NHÓM CHỦ CHO THUÊ (LESSOR) - CHỈ QUẢN LÝ ĐỒ CỦA MÌNH
    // =========================================================================

    // Lấy danh sách sản phẩm do chính tài khoản này đăng lên
    static async getMyProducts(req, res) {
        try {
            const userId = req.user.id || req.user.userId || req.user.MaNguoiDung; 
            const products = await productModel.getMyProducts(userId);
            return res.status(200).json({ succeeded: true, message: "Lấy sản phẩm của tôi thành công", products: products });
        } catch (error) { return res.status(500).json({ succeeded: false, message: error.message }); }
    }

    // Chủ đồ đăng sản phẩm mới (Mặc định trạng thái thường là 'ChoDuyet')
    static async createProduct(req, res) {
        try {
            const userId = req.user.id || req.user.userId || req.user.MaNguoiDung;
            const newProductId = await productModel.createProduct(userId, req.body);
            return res.status(201).json({ succeeded: true, message: "Thêm sản phẩm thành công", product_id: newProductId });
        } catch (error) { return res.status(500).json({ succeeded: false, message: error.message }); }
    }

    // Cập nhật thông tin sản phẩm (Chỉ cập nhật được đồ của chính mình)
    static async updateProduct(req, res) {
        try {
            const userId = req.user.id || req.user.userId || req.user.MaNguoiDung;
            const isUpdated = await productModel.updateProduct(req.params.id, userId, req.body);
            if (!isUpdated) return res.status(403).json({ succeeded: false, message: "Không thể cập nhật (Sản phẩm không tồn tại hoặc không phải của bạn)" });
            return res.status(200).json({ succeeded: true, message: "Cập nhật sản phẩm thành công" });
        } catch (error) { return res.status(500).json({ succeeded: false, message: error.message }); }
    }

    // Xóa sản phẩm của mình
    static async deleteProduct(req, res) {
        try {
            const userId = req.user.id || req.user.userId || req.user.MaNguoiDung;
            const isDeleted = await productModel.deleteProduct(req.params.id, userId);
            if (!isDeleted) return res.status(403).json({ succeeded: false, message: "Không thể xóa (Sản phẩm không tồn tại hoặc không phải của bạn)" });
            return res.status(200).json({ succeeded: true, message: "Xóa sản phẩm thành công" });
        } catch (error) { return res.status(500).json({ succeeded: false, message: error.message }); }
    }


    // =========================================================================
    // 3. NHÓM QUẢN TRỊ VIÊN (ADMIN) - KIỂM DUYỆT HỆ THỐNG
    // =========================================================================
    
    // Admin duyệt bài đăng (Đổi trạng thái sang 'SanSang' hoặc 'TuChoi')
    static async approveProduct(req, res) {
        try {
            const { status } = req.body; 
            if (!status || !['SanSang', 'TuChoi'].includes(status)) {
                return res.status(400).json({ succeeded: false, message: "Trạng thái không hợp lệ! Chỉ chấp nhận 'SanSang' hoặc 'TuChoi'." });
            }
            const isUpdated = await productModel.updateProductStatus(req.params.productId, status);
            if (!isUpdated) return res.status(404).json({ succeeded: false, message: "Không tìm thấy sản phẩm." });
            
            return res.status(200).json({ succeeded: true, message: status === 'SanSang' ? "Đã duyệt hiển thị!" : "Đã từ chối bài đăng!" });
        } catch (error) { return res.status(500).json({ succeeded: false, message: error.message }); }
    }

    // Admin xóa vĩnh viễn sản phẩm vi phạm khỏi DB
    static async adminDeleteProduct(req, res) {
        try {
            const isDeleted = await productModel.adminForceDeleteProduct(req.params.productId);
            if (!isDeleted) return res.status(404).json({ succeeded: false, message: "Không tìm thấy sản phẩm." });
            return res.status(200).json({ succeeded: true, message: "Đã xóa vĩnh viễn sản phẩm vi phạm!" });
        } catch (error) { return res.status(500).json({ succeeded: false, message: error.message }); }
    }
}
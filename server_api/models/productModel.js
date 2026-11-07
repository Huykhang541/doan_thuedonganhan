import { execute } from "../config/db.js";

export default class productModel {

    // =========================================================================
    // 1. PUBLIC - KHÁCH CHUNG
    // =========================================================================
    static async allproduct() {
        try {
            const query = `
                SELECT 
                sp.MaSanPham AS id,
                sp.TenSanPham AS name,
                sp.MoTa AS description,
                sp.GiaThueTheoNgay AS price,
                sp.TrangThai AS status,
                (SELECT DuongDanAnh FROM bienthesanpham WHERE MaSanPham = sp.MaSanPham LIMIT 1) AS imageUrl,
    
                COALESCE((
                    SELECT AVG(dg.SoSao)
                    FROM danhgia dg
                    JOIN chitietdonthue ct ON dg.MaChiTietDon = ct.MaChiTietDon
                    JOIN bienthesanpham bt ON ct.MaBienThe = bt.MaBienThe
                    WHERE bt.MaSanPham = sp.MaSanPham
                ), 0) AS averageRating,
    
                COALESCE((
                    SELECT COUNT(dg.MaDanhGia)
                    FROM danhgia dg
                    JOIN chitietdonthue ct ON dg.MaChiTietDon = ct.MaChiTietDon
                    JOIN bienthesanpham bt ON ct.MaBienThe = bt.MaBienThe
                    WHERE bt.MaSanPham = sp.MaSanPham
                ), 0) AS reviewCount
  
            FROM sanpham sp
            WHERE TRIM(sp.TrangThai) = 'SanSang'
            `;
            const [rows] = await execute(query);
            return rows; 
        } catch (error) { throw new Error("Lỗi lấy danh sách sản phẩm: " + error.message); }
    }

    static async getProductVariants() {
        try {
            const query = `
                SELECT 
                    bt.MaBienThe AS id, 
                    bt.MaSanPham AS product_id, 
                    sp.TenSanPham AS name, 
                    bt.MauSac AS color, 
                    bt.DuongDanAnh AS image, 
                    sp.GiaThueTheoNgay AS price,
                    sp.MaDanhMuc AS brandId 
                FROM bienthesanpham bt
                JOIN sanpham sp ON bt.MaSanPham = sp.MaSanPham
                ORDER BY bt.MaSanPham ASC
            `;
            const [rows] = await execute(query);
            return rows;
        } catch (error) { throw new Error("Lỗi lấy danh sách biến thể: " + error.message); }
    }

    static async findProductById(id){
        try{
            const queryProduct = `
                SELECT MaSanPham AS id, TenSanPham AS name, MoTa AS description, 'Đồ cắm trại' as brand_name 
                FROM sanpham WHERE MaSanPham = ?
            `;
            const [productRows] = await execute(queryProduct, [id]);
            if (productRows.length === 0) return null;
            const product = productRows[0];

            const queryVariants = `
                SELECT MaBienThe AS id, MaSanPham AS product_id, MauSac AS color, DuongDanAnh AS image 
                FROM bienthesanpham WHERE MaSanPham = ?
            `;
            const [variants] = await execute(queryVariants, [id]);
            product.variants = variants; 
            return product;
        }catch(error){ throw new Error("Lỗi lấy chi tiết sản phẩm: " + error.message); }
    }

    static async searchProduct(filters) {
        try {
            let sql = `
                SELECT 
                    sp.MaSanPham AS id, 
                    sp.TenSanPham AS name, 
                    sp.MoTa AS description, 
                    sp.GiaThueTheoNgay AS price, 
                    sp.MaDanhMuc AS brandId, 
                    sp.TienCoc as deposit,
                    sp.TrangThai AS status,
                    (SELECT DuongDanAnh FROM bienthesanpham WHERE MaSanPham = sp.MaSanPham LIMIT 1) AS image,
                    
                    COALESCE((
                        SELECT AVG(dg.SoSao)
                        FROM danhgia dg
                        JOIN chitietdonthue ct ON dg.MaChiTietDon = ct.MaChiTietDon
                        JOIN bienthesanpham bt ON ct.MaBienThe = bt.MaBienThe
                        WHERE bt.MaSanPham = sp.MaSanPham
                    ), 0) AS averageRating,
        
                    COALESCE((
                        SELECT COUNT(dg.MaDanhGia)
                        FROM danhgia dg
                        JOIN chitietdonthue ct ON dg.MaChiTietDon = ct.MaChiTietDon
                        JOIN bienthesanpham bt ON ct.MaBienThe = bt.MaBienThe
                        WHERE bt.MaSanPham = sp.MaSanPham
                    ), 0) AS reviewCount

                FROM sanpham sp 
                WHERE TRIM(sp.TrangThai) = 'SanSang'
            `;
            const values = [];

            if (filters.name) { sql += ` AND sp.TenSanPham LIKE ?`; values.push(`%${filters.name}%`); }
            if (filters.category_id) { sql += ` AND sp.MaDanhMuc = ?`; values.push(filters.category_id); }
            if (filters.min_price) { sql += ` AND sp.TienCoc >= ?`; values.push(filters.min_price); }
            if (filters.max_price) { sql += ` AND sp.TienCoc <= ?`; values.push(filters.max_price); }
            if (filters.min_rent_price) { sql += ` AND sp.GiaThueTheoNgay >= ?`; values.push(filters.min_rent_price); }
            if (filters.max_rent_price) { sql += ` AND sp.GiaThueTheoNgay <= ?`; values.push(filters.max_rent_price); }

            const [rows] = await execute(sql, values);
            return rows;
        } catch (error) { throw new Error('Lỗi tìm kiếm sản phẩm: ' + error.message); }
    }
    
    static async findProductById(id){
        try{
            const queryProduct = `
                SELECT 
                    sp.MaSanPham AS id, 
                    sp.TenSanPham AS name, 
                    sp.MoTa AS description, 
                    sp.GiaThueTheoNgay AS price,
                    sp.TienCoc AS deposit,
                    sp.TrangThai AS status,
                    'Đồ cắm trại' as brand_name,
                    
                    COALESCE((
                        SELECT AVG(dg.SoSao)
                        FROM danhgia dg
                        JOIN chitietdonthue ct ON dg.MaChiTietDon = ct.MaChiTietDon
                        JOIN bienthesanpham bt ON ct.MaBienThe = bt.MaBienThe
                        WHERE bt.MaSanPham = sp.MaSanPham
                    ), 0) AS averageRating,
        
                    COALESCE((
                        SELECT COUNT(dg.MaDanhGia)
                        FROM danhgia dg
                        JOIN chitietdonthue ct ON dg.MaChiTietDon = ct.MaChiTietDon
                        JOIN bienthesanpham bt ON ct.MaBienThe = bt.MaBienThe
                        WHERE bt.MaSanPham = sp.MaSanPham
                    ), 0) AS reviewCount

                FROM sanpham sp
                WHERE sp.MaSanPham = ?
            `;
            const [productRows] = await execute(queryProduct, [id]);
            if (productRows.length === 0) return null;
            const product = productRows[0];

            const queryVariants = `
                SELECT 
                    MaBienThe AS id, 
                    MaSanPham AS product_id, 
                    MauSac AS color, 
                    DuongDanAnh AS image
                FROM bienthesanpham 
                WHERE MaSanPham = ?
            `;
            const [variants] = await execute(queryVariants, [id]);
            product.variants = variants; 
            return product;
        }catch(error){ throw new Error("Lỗi lấy chi tiết sản phẩm: " + error.message); }
    }

    static async findProductVariantByProductID(product_id){
        try{
            const [rows] = await execute(`
                SELECT 
                    bt.MaBienThe AS id, 
                    sp.TenSanPham AS name, 
                    sp.MoTa AS description, 
                    bt.MaSanPham AS product_id, 
                    sp.GiaThueTheoNgay AS price,
                    sp.TienCoc AS deposit,
                    sp.TrangThai AS status, 
                    bt.DuongDanAnh AS image, 
                    bt.MauSac AS color 
                FROM bienthesanpham bt 
                JOIN sanpham sp ON bt.MaSanPham = sp.MaSanPham 
                WHERE bt.MaSanPham = ?
            `, [product_id]);
            if(rows.length === 0) throw new Error('Không tìm thấy product_id');
            return rows;
        }
        catch(error){ throw new Error('Lỗi lấy biến thể: ' + error.message); }
    }

    // =========================================================================
    // 2. LESSOR - CHỦ CHO THUÊ
    // =========================================================================
    static async getMyProducts(lessorId) {
        try {
            const query = `
                SELECT 
                    sp.MaSanPham AS id, sp.TenSanPham AS name, sp.MoTa AS description, sp.GiaThueTheoNgay AS price, sp.TrangThai AS status,
                    (SELECT DuongDanAnh FROM bienthesanpham WHERE MaSanPham = sp.MaSanPham LIMIT 1) AS image
                FROM sanpham sp WHERE sp.MaChuSoHuu = ? ORDER BY sp.MaSanPham DESC
            `;
            const [rows] = await execute(query, [lessorId]);
            return rows;
        } catch (error) { throw new Error("Lỗi lấy sản phẩm của tôi: " + error.message); }
    }

    static async createProduct(lessorId, productData) {
        try {
            const { name, price, deposit, description, category_id } = productData;
            const query = `INSERT INTO sanpham (TenSanPham, GiaThueTheoNgay, TienCoc, MoTa, MaDanhMuc, MaChuSoHuu, TrangThai) VALUES (?, ?, ?, ?, ?, ?, 'ChoDuyet')`;
            const [result] = await execute(query, [name, price, deposit, description, category_id, lessorId]);
            return result.insertId; 
        } catch (error) { throw new Error("Lỗi thêm sản phẩm: " + error.message); }
    }

    static async updateProduct(productId, lessorId, productData) {
        try {
            const { name, price, deposit, description, category_id } = productData;
            const query = `UPDATE sanpham SET TenSanPham = ?, GiaThueTheoNgay = ?, TienCoc = ?, MoTa = ?, MaDanhMuc = ? WHERE MaSanPham = ? AND MaChuSoHuu = ?`;
            const [result] = await execute(query, [name, price, deposit, description, category_id, productId, lessorId]);
            return result.affectedRows > 0;
        } catch (error) { throw new Error("Lỗi cập nhật sản phẩm: " + error.message); }
    }

    static async deleteProduct(productId, lessorId) {
        try {
            const query = `DELETE FROM sanpham WHERE MaSanPham = ? AND MaChuSoHuu = ?`;
            const [result] = await execute(query, [productId, lessorId]);
            return result.affectedRows > 0;
        } catch (error) { throw new Error("Lỗi xóa sản phẩm: " + error.message); }
    }

    // =========================================================================
    // 3. ADMIN
    // =========================================================================
    static async updateProductStatus(productId, status) {
        try {
            const query = `UPDATE sanpham SET TrangThai = ? WHERE MaSanPham = ?`;
            const [result] = await execute(query, [status, productId]);
            return result.affectedRows > 0;
        } catch (error) { throw new Error("Lỗi duyệt sản phẩm: " + error.message); }
    }

    static async adminForceDeleteProduct(productId) {
        try {
            const query = `DELETE FROM sanpham WHERE MaSanPham = ?`;
            const [result] = await execute(query, [productId]);
            return result.affectedRows > 0;
        } catch (error) { throw new Error("Lỗi xóa sản phẩm: " + error.message); }
    }
}
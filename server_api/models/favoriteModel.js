import { execute } from '../config/db.js';

export default class favoriteModel {
    static async getFavoriteByUserID(user_id) {
        try {
            // SỬA LẠI: JOIN trực tiếp với bảng sanpham theo MaSanPham
            const query = `
                SELECT 
                    f.MaYeuThich as id, 
                    f.MaSanPham as productID, 
                    p.TenSanPham as name, 
                    p.GiaThueTheoNgay as price, 
                    (SELECT DuongDanAnh FROM bienthesanpham WHERE MaSanPham = p.MaSanPham LIMIT 1) as image 
                FROM yeuthich f
                JOIN sanpham p ON f.MaSanPham = p.MaSanPham
                WHERE f.MaNguoiDung = ?
            `;
            const [favorites] = await execute(query, [user_id]);
            return favorites.length === 0 ? [] : favorites;
        } catch (error) {
            throw new Error('Lỗi lấy sản phẩm ưa thích: ' + error.message);
        }
    }

    static async addFavorite(user_id, product_id) {
        try {
            // SỬA LẠI: Kiểm tra bảng sanpham thay vì bienthesanpham
            const [product] = await execute('SELECT * FROM sanpham WHERE MaSanPham = ?', [product_id]);
            if (product.length === 0) {
                throw new Error('Không tìm thấy sản phẩm này');
            }

            // Kiểm tra xem đã thả tim chưa để tránh trùng lặp
            const [existing] = await execute('SELECT MaYeuThich FROM yeuthich WHERE MaNguoiDung = ? AND MaSanPham = ?', [user_id, product_id]);
            if (existing.length > 0) return existing[0].MaYeuThich; 

            const [result] = await execute(
                'INSERT INTO yeuthich (MaNguoiDung, MaSanPham, NgayThem) VALUES (?, ?, NOW())',
                [user_id, product_id]
            );
            return result.affectedRows > 0 ? result.insertId : null;
        } catch (error) {
            throw new Error('Lỗi thêm sản phẩm yêu thích: ' + error.message);
        }
    }

    static async removeFavorite(user_id, product_id) {
        try {
            // SỬA LẠI: Xóa theo MaSanPham
            const [result] = await execute(
                'DELETE FROM yeuthich WHERE MaNguoiDung = ? AND MaSanPham = ?', 
                [user_id, product_id]
            );
            if (result.affectedRows === 0) {
                throw new Error('Không tìm thấy sản phẩm ưa thích này để xóa');
            }
            return true;
        } catch (error) {
            throw new Error('Lỗi xóa sản phẩm ưa thích: ' + error.message);
        }
    }
}
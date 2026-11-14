import { execute } from "../config/db.js";

export default class reviewsModel {
    
    // 1. Lấy danh sách đánh giá của sản phẩm thông qua bảng chitietdonthue
    static async getReviewsByProductId(product_id) {
        try {
            const [rows] = await execute(`
                SELECT 
                    dg.SoSao AS rating, 
                    dg.BinhLuan AS comment, 
                    dg.NgayDanhGia AS created_at, 
                    nd.HoTen AS fullname 
                FROM danhgia dg
                JOIN nguoidung nd ON dg.MaNguoiDung = nd.MaNguoiDung 
                JOIN chitietdonthue ct ON dg.MaChiTietDon = ct.MaChiTietDon
                WHERE ct.MaSanPham = ?
                ORDER BY dg.NgayDanhGia DESC
            `, [product_id]);

            if (rows.length === 0) {
                return {
                    totalRating: 0,
                    avgRating: 0,
                    rows: []
                };
            }

            let totalRating = 0;
            rows.forEach((r) => {
                totalRating += r.rating;
            });
            const avgRating = parseFloat((totalRating / rows.length).toFixed(1));

            return {
                totalRating: rows.length,
                avgRating,
                rows
            };
        } catch (error) {
            throw new Error("Lỗi lấy đánh giá sản phẩm: " + error.message);
        }
    }

    // 2. Thêm đánh giá mới
    static async addReview(review, product_id, user_id) {
        try {
            // Lấy trực tiếp MaChiTietDon và MaChuSoHuu từ chitietdonthue mà không cần join bảng sanpham
            const queryCheck = `
                SELECT ct.MaChiTietDon, ct.MaChuSoHuu as NguoiBiDanhGia
                FROM donthue dt
                JOIN chitietdonthue ct ON dt.MaDonThue = ct.MaDonThue
                WHERE 
                    dt.MaKhachThue = ?                
                    AND ct.MaSanPham = ?      
                    AND dt.TrangThaiDon IN ('completed', 'resolved') 
                    AND NOT EXISTS (           
                        SELECT 1 FROM danhgia dg 
                        WHERE dg.MaNguoiDung = dt.MaKhachThue 
                        AND dg.MaChiTietDon = ct.MaChiTietDon
                    )
                ORDER BY dt.NgayTao DESC     
                LIMIT 1;
            `;

            const [checkRows] = await execute(queryCheck, [user_id, product_id]);

            if (checkRows.length > 0) {
                const { MaChiTietDon, NguoiBiDanhGia } = checkRows[0];

                const [result] = await execute(
                    'INSERT INTO `danhgia` (`MaChiTietDon`, `MaNguoiDung`, `NguoiBiDanhGia`, `SoSao`, `BinhLuan`, `TrangThai`, `NgayDanhGia`) VALUES (?, ?, ?, ?, ?, ?, NOW())',
                    [MaChiTietDon, user_id, NguoiBiDanhGia, review.rating, review.comment, 'HienThi']
                );

                return result.affectedRows > 0 ? result.insertId : null;
            } else {
                throw new Error('Bạn chỉ có thể đánh giá sau khi đơn thuê đã hoàn thành hoặc bạn đã đánh giá đơn này rồi!');
            }
        } catch (error) {
            throw new Error('Lỗi thêm đánh giá: ' + error.message);
        }
    }
}
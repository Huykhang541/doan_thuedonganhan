import { execute } from "../config/db.js";

export default class reviewsModel {
    
    // 1. Lấy danh sách đánh giá của sản phẩm
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
                WHERE dg.MaSanPham = ?
                ORDER BY dg.NgayDanhGia DESC
            `, [product_id]);

            if (rows.length === 0) {
                return {
                    totalRating: 0,
                    avgRating: 0,
                    rows: []
                };
            }

            // Tính toán tổng số sao và trung bình cộng sao
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

    // 2. Thêm đánh giá mới (Kiểm tra xem user đã thuê và hoàn thành đơn chưa)
    static async addReview(review, product_id, user_id) {
        try {
            // Kiểm tra xem khách đã thuê sản phẩm này và đơn đã hoàn tất ('completed' hoặc 'resolved')
            const queryCheck = `
                SELECT dt.MaDonThue as found_order_id
                FROM donthue dt
                JOIN chitietdonthue ct ON dt.MaDonThue = ct.MaDonThue
                WHERE 
                    dt.MaKhachThue = ?                
                    AND ct.MaSanPham = ?      
                    AND dt.TrangThaiDon IN ('completed', 'resolved') -- Đã sửa khớp với database thực tế
                    AND NOT EXISTS (           
                        SELECT 1 FROM danhgia dg 
                        WHERE dg.MaNguoiDung = dt.MaKhachThue 
                        AND dg.MaSanPham = ct.MaSanPham
                    )
                ORDER BY dt.NgayTao DESC     
                LIMIT 1;
            `;

            const [checkRows] = await execute(queryCheck, [user_id, product_id]);

            if (checkRows.length > 0) {
                const orderId = checkRows[0].found_order_id;

                const [result] = await execute(
                    'INSERT INTO `danhgia` (`MaNguoiDung`, `MaSanPham`, `MaDonThue`, `SoSao`, `BinhLuan`, `NgayDanhGia`) VALUES (?, ?, ?, ?, ?, NOW())',
                    [user_id, product_id, orderId, review.rating, review.comment]
                );

                return result.affectedRows > 0 ? result.insertId : null;
            } else {
                throw new Error('Bạn chỉ có thể đánh giá sau khi đơn thuê đã hoàn thành (completed)!');
            }
        } catch (error) {
            throw new Error('Lỗi thêm đánh giá: ' + error.message);
        }
    }
}
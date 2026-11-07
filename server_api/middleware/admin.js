import jwt from 'jsonwebtoken';

export default function admin(req, res, next) {
    try {
        // 1. Lấy mã Token từ trên Header mà bạn gửi (chỗ Bearer Token trong Thunder Client)
        const authHeader = req.header('Authorization') || req.header('authorization');
        const token = authHeader && authHeader.split(' ')[1];

        if (!token) {
            return res.status(403).json({ message: "Admin privileges required: Không tìm thấy Token" });
        }

        // 2. Giải mã Token ra xem ruột có gì
        const decoded = jwt.verify(token, process.env.JWT_SECRET);

        // 3. Kiểm tra xem quyền có phải là admin không (Khớp hoàn toàn với Token ta tạo lúc nãy)
        if (decoded.role === 'admin' || decoded.VaiTro === 'admin') {
            req.userid = decoded.id; // Nhớ lại mã ID người dùng cho các hàm phía sau dùng
            return next();           // Mở cửa! Chạy tiếp vào hàm của Controller
        } else {
            // Nếu Token giải mã ra chữ 'user', chặn lại
            return res.status(403).json({ message: "Admin privileges required: Bạn chỉ là User thường" });
        }
    } catch (error) {
        return res.status(403).json({ message: "Admin privileges required: Token lỗi hoặc hết hạn" });
    }
}
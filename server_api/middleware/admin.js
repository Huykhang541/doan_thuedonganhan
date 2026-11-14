import jwt from 'jsonwebtoken';
import userModel from "../models/userModel.js"; // [FIX]: Import model để check revoke

export default async function admin(req, res, next) { // [FIX]: Chuyển thành async function
    try {
        const authHeader = req.header('Authorization') || req.header('authorization');
        const token = authHeader && authHeader.split(' ')[1];

        if (!token) {
            return res.status(403).json({ message: "Admin privileges required: Không tìm thấy Token" });
        }

        // [FIX]: Thêm check token thu hồi (blacklist) bảo vệ tuyến admin
        if(await userModel.isTokenRevoked(token)){
            return res.status(401).json({message: 'Invalid or expired token'});
        }

        const decoded = jwt.verify(token, process.env.JWT_SECRET);

        if (decoded.role === 'admin' || decoded.VaiTro === 'admin') {
            req.userid = decoded.id; 
            req.role = decoded.role || decoded.VaiTro; // [FIX]: Gán req.role để Controller sau đó biết đây là Admin
            return next();           
        } else {
            return res.status(403).json({ message: "Admin privileges required: Bạn chỉ là User thường" });
        }
    } catch (error) {
        return res.status(403).json({ message: "Admin privileges required: Token lỗi hoặc hết hạn" });
    }
}
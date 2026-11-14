import userModel from "../models/userModel.js";
import jsonwebtoken from 'jsonwebtoken';
const { verify } = jsonwebtoken;
const JWT_SECRET = process.env.JWT_SECRET;

export default async function auth(req, res, next) {
    try {
        const authHeader = req.headers.authorization;

        if(!authHeader || !authHeader.startsWith('Bearer ')){
            return res.status(401).json({message: 'Authorization required'});
        }
        const token = authHeader.split(' ')[1];
        
        if(await userModel.isTokenRevoked(token)){
            return res.status(401).json({message: 'Invalid or expired token'});
        }
        
        const decoded = verify(token, JWT_SECRET);
        if(!decoded || !decoded.id) return res.status(401).json({message: 'Invalid or expired token'});
        
        const user = await userModel.findById(decoded.id);
        if(!user) return res.status(401).json({message: 'User not found'});

        req.userid = decoded.id;
        
        // ĐỒNG BỘ: Đổi username thành Email và is_admin thành VaiTro để khớp hoàn toàn với bảng NguoiDung
        req.email = user.Email; 
        req.role = user.VaiTro;
        
        req.token = token;
        req.user = user;
        req.user.id = decoded.id;
        next();
    } catch (error) {
        // [FIX]: Bắt lỗi giải mã token (VD: token hết hạn, token bịa đặt) để server không bị crash
        return res.status(401).json({message: 'Invalid or expired token'});
    }
};
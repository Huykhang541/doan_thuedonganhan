
import { compare, hash } from "bcrypt";
import { execute } from "../config/db.js";
const PASSWORD_HASH_ROUNDS = parseInt(process.env.PASSWORD_HASH_ROUNDS) || 10;

export default class userModel{
    // Lấy tất cả người dùng
    static async all(){
        try{
            const [rows] = await execute("SELECT * FROM NguoiDung");
            return rows;
        }
        catch (error){
            throw new Error("Database query failed: " + error.message);
        }
    }

    // Tìm người dùng theo ID (Đã sửa id thành MaNguoiDung)
    static async findById(id){
        try{
            const [rows] = await execute("SELECT * FROM NguoiDung WHERE MaNguoiDung = ? LIMIT 1",[id]);
            return rows[0]??null;
        }
        catch (error){
            throw new Error("Database query failed: " + error.message);
        }
    }

    // Tìm người dùng theo Email
    // Tìm người dùng theo Email (Đã sửa đổi để tương thích 100% với Controller)
    // Tìm người dùng theo Email (Bản chuẩn hóa sửa lỗi triệt để)
    /*static async findByUsername(email) {
        try {
            // Lấy toàn bộ cột gốc từ database (để giữ lại cột MatKhau, MaNguoiDung...)
            const [rows] = await execute(
                "SELECT * FROM NguoiDung WHERE Email = ?", 
                [email]
            );
            
            if (rows.length > 0) {
                const user = rows[0];
                // Tạo thêm các thuộc tính tiếng Anh để dù Controller gọi kiểu nào cũng chạy được
                user.id = user.MaNguoiDung;
                user.password = user.MatKhau;
                user.fullname = user.HoTen;
                user.phone_number = user.SoDienThoai;
                user.address = user.DiaChiNguoiDung;
                user.is_admin = user.VaiTro === 'Admin' ? 1 : 0;
                
                return user;
            }
            return null;
        } catch (error) {
            throw new Error("Database query failed: " + error.message);
        }
    }*/

    // Tìm người dùng theo Email (Bản chuẩn hóa sửa lỗi triệt để)
    static async findByUsername(email) {
        try {
            // Lấy toàn bộ cột gốc từ database (để giữ lại cột MatKhau, MaNguoiDung...)
            const [rows] = await execute(
                "SELECT * FROM NguoiDung WHERE Email = ?", 
                [email]
            );
            
            if (rows.length > 0) {
                return rows[0]; // Trả về đối tượng user gốc có chứa MaNguoiDung và MatKhau
            }
            return null;
        } catch (error) {
            throw new Error("Database query failed: " + error.message);
        }
    }

    // Tạo người dùng mới (Đã sửa cột thành Tiếng Việt)
    static async create(data) {
        try {
            const fullName = data.fullName || data.Fullname || data.fullname || '';
            const email = data.email || data.Email || '';
            const pass = data.password || data.hashedPassword || ''; 
            const phone = data.phoneNumber || data.PhoneNumber || data.phone_number || '';
            const address = data.address || data.Address || '';
            
            // ĐOẠN ĐƯỢC SỬA: Lấy data.VaiTro từ Controller gửi xuống, nếu không có mới dùng logic cũ
            const vaiTro = data.VaiTro || (data.is_admin ? 'Admin' : 'KhachHang');

            const [result] = await execute(
                'INSERT INTO `NguoiDung`(`HoTen`, `Email`, `MatKhau`, `SoDienThoai`, `DiaChiNguoiDung`, `VaiTro`, `TrangThaiTaiKhoan`, `NgayTao`) VALUES (?,?,?,?,?,?,?, NOW())',
                [fullName, email, pass, phone, address, vaiTro, 'HoatDong']
            );
            return result.affectedRows > 0 ? result.insertId : null;
        } catch (error) {
            throw new Error("Database query failed: " + error.message);
        }
    }

    // Xử lý token (Giữ nguyên vì có thể bạn có bảng revoked_tokens riêng)
   static async revokeToken(token, expiresAt){
        try{
            const [result] = await execute('INSERT INTO revoked_tokens (token, expires_at) VALUES(?,?)',[token,expiresAt]);
            return result.affectedRows > 0;
        }
        catch(error){
            throw new Error("Database query failed: " + error.message);
        }
    }

    static async isTokenRevoked(token){
        try{
            const [rows] = await execute('SELECT id FROM revoked_tokens WHERE token = ? LIMIT 1',[token]);
            return rows.length > 0;
        }catch(error){
            throw new Error("Database query failed: " + error.message);
        }
    }

    

    // Cập nhật thông tin (Đã sửa tên cột)
    static async updateUser(id,fullname,phone_number,address){
        try{
            // Đã đổi `DiaChi` thành `DiaChiNguoiDung`
            const [rows] = await execute('UPDATE NguoiDung SET HoTen = ?, SoDienThoai = ?, DiaChiNguoiDung = ? WHERE MaNguoiDung = ?',
                [fullname,phone_number,address,id]);
            return rows.affectedRows > 0;
        }
        catch(error){
            throw new Error("Lỗi update user: "+error.message);
        }
    }

    // Đổi mật khẩu (Đã sửa password thành MatKhau)
    // Đổi mật khẩu (Đã sửa đổi để tương thích với cả mật khẩu thô lẫn mật khẩu mã hóa)
    static async changePass(currentPassword, newPassword, user_id){
        try{
            const user = await this.findById(user_id);
            if(user){
                // --- ĐOẠN SỬA THÔNG MINH 1: KIỂM TRA MẬT KHẨU HIỆN TẠI ---
                let isCurrentMatch = false;
                if (user.MatKhau && (user.MatKhau.startsWith('$2b$') || user.MatKhau.startsWith('$2a$'))) {
                    isCurrentMatch = await compare(currentPassword, user.MatKhau);
                } else {
                    isCurrentMatch = (currentPassword === user.MatKhau);
                }

                if(!isCurrentMatch){
                    throw new Error('Mật khẩu hiện tại không đúng');
                }
                // --------------------------------------------------------

                // --- ĐOẠN SỬA THÔNG MINH 2: KIỂM TRA MẬT KHẨU MỚI CÓ TRÙNG CŨ KHÔNG ---
                let isNewMatch = false;
                if (user.MatKhau && (user.MatKhau.startsWith('$2b$') || user.MatKhau.startsWith('$2a$'))) {
                    isNewMatch = await compare(newPassword, user.MatKhau);
                } else {
                    isNewMatch = (newPassword === user.MatKhau);
                }

                if(isNewMatch){
                    throw new Error('Password mới trùng với password hiện tại');
                }
                // --------------------------------------------------------

                // Khi đổi thành công, hệ thống sẽ tự động băm mật khẩu mới thành dạng mã hóa chuẩn luôn
                const hashedPassword = await hash(newPassword, PASSWORD_HASH_ROUNDS)
                const [changePassword] = await execute('UPDATE NguoiDung SET MatKhau = ? WHERE MaNguoiDung = ?',[hashedPassword,user_id]);
                return changePassword.affectedRows > 0? true:false;
            }else{
                throw new Error('Không tìm thấy user_ID này');
            }
        }
        catch(error){
            throw new Error(error.message); // Giữ nguyên luồng bắt lỗi cũ của bạn
        }
    }


    // =========================================================
    // MODEL: CẬP NHẬT TRẠNG THÁI TÀI KHOẢN (KHÓA/MỞ KHÓA)
    // =========================================================
    static async updateAccountStatus(userId, status) {
        try {
            // LƯU Ý: Sửa chữ 'TrangThai' thành đúng tên cột trong DB của bạn
            const [result] = await execute(
                "UPDATE NguoiDung SET TrangThaiTaiKhoan = ? WHERE MaNguoiDung = ?",
                [status, userId]
            );
            return result.affectedRows > 0;
        } catch (error) {
            throw new Error("Lỗi cập nhật trạng thái tài khoản: " + error.message);
        }
    }
}
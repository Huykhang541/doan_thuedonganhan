import {hash, compare} from 'bcrypt';
import jwt from 'jsonwebtoken';
import userModel from '../models/userModel.js';

const JWT_SECRET = process.env.JWT_SECRET;
const JWT_EXPIRES_IN = process.env.JWT_EXPIRES_IN || "1h";
const PASSWORD_HASH_ROUNDS = parseInt(process.env.PASSWORD_HASH_ROUNDS) || 10;

export default class userController {
    static async generateToken(user) {
        // Lấy vai trò từ database và chuyển hết thành chữ thường để tránh lỗi viết hoa
        let dbRole = user.VaiTro || user.vaitro || user.role || '';
        dbRole = dbRole.toString().toLowerCase().trim();

        // Nếu là tài khoản admin@gmail.com hoặc database chứa chữ admin thì nạp tất cả các kiểu quyền vào token
        if (user.Email === 'admin@gmail.com' || user.email === 'admin@gmail.com' || dbRole === 'admin') {
            return jwt.sign(
                {
                    id: user.MaNguoiDung,
                    role: "admin",      // Chữ thường (Chuẩn Node.js)
                    Role: "admin",      // Đề phòng check thuộc tính viết hoa
                    role_name: "admin",
                    VaiTro: "admin",    // Đề phòng tên cột tiếng Việt viết thường
                    vaitro: "admin"     // Đề phòng tên cột tiếng Việt viết hoa
                },
                JWT_SECRET,
                {expiresIn: JWT_EXPIRES_IN}
            );
        }

        // Ngược lại nếu là user thường
        return jwt.sign(
            {
                id: user.MaNguoiDung,
                role: "user",
                VaiTro: "user"
            },
            JWT_SECRET,
            {expiresIn: JWT_EXPIRES_IN}
        );
    }
    
    static async login(req, res) {
        try {
            const { email, password } = req.body;
            if (!email || !password) return res.status(400).json({ succeeded: false, message: "Thiếu Email hoặc Mật khẩu" });
    
            // THÊM DÒNG NÀY: Chuẩn hóa email về chữ thường và xóa khoảng trắng thừa
            const normalizedEmail = email.toLowerCase().trim(); 
    
            // Đổi biến email thành normalizedEmail ở hàm tìm kiếm
            const user = await userModel.findByUsername(normalizedEmail);
            if (!user) return res.status(401).json({ succeeded: false, message: 'Không tìm thấy Email' });

            // ==========================================================
            // Thay vì kiểm tra 'locked', hãy kiểm tra đúng Enum trong Database là 'Khoa'
            // Thay vì kiểm tra 'locked', hãy kiểm tra đúng Enum trong Database là 'Khoa'
            if (user.TrangThaiTaiKhoan === 'Khoa') {
                return res.status(403).json({ 
                    succeeded: false, 
                    message: "Tài khoản của bạn đã bị khóa do vi phạm điều khoản hệ thống. Vui lòng liên hệ Admin!" 
                });
            }
            // ==========================================================
            
            // --- ĐOẠN SỬA THÔNG MINH: CHẤP NHẬN CẢ MẬT KHẨU THÔ LẪN MẠ HÓA ---
            let isMatch = false;
            if (user.MatKhau && (user.MatKhau.startsWith('$2b$') || user.MatKhau.startsWith('$2a$'))) {
                // Nếu mật khẩu trong DB là chuẩn mã hóa Bcrypt
                isMatch = await compare(password, user.MatKhau);
            } else {
                // Nếu mật khẩu trong DB là chữ thô (như 123456 của database mới)
                isMatch = (password === user.MatKhau);
            }
            // -----------------------------------------------------------------

            if(!isMatch) return res.status(401).json({succeeded: false, message: "Sai mật khẩu"});
            
            const token = await userController.generateToken(user);
            return res.status(200).json({
                succeeded: true,
                token: token,
                user: {
                    id: user.MaNguoiDung,
                    email: user.Email,
                    role: user.VaiTro // Database đang lưu là 'admin' hoặc 'khach_hang'
                }
            });
        }
        catch(error) {
            return res.status(500).json({
                succeeded: false,
                message: error.message
            });
        }
    }

    static validatePassword(password) {
        const passwordRules = {
            minlength: 8,
            maxLength: 100,
            requireUppercase: true,
            requireLowercase: true,
            requireNumber: true,
            requireSpecial: true
        };
        if(password.length < passwordRules.minlength || password.length > passwordRules.maxLength) return false;
        if(passwordRules.requireUppercase && !/[A-Z]/.test(password)) return false;
        if(passwordRules.requireLowercase && !/[a-z]/.test(password)) return false;
        if(passwordRules.requireNumber && !/[0-9]/.test(password)) return false;
        if(passwordRules.requireSpecial && !/[!@#$%^&*(),.?":{}|<>]/.test(password)) return false;
        return true;
    }
    
    static async register(req, res) {
        // Thêm VaiTro (chữ V hoa) vào để bắt được dữ liệu từ Thunder Client gửi lên
        const { email, password, fullName, phoneNumber, address, VaiTro, vaitro } = req.body;

        // Ưu tiên lấy VaiTro hoặc vaitro, nếu không có thì gán mặc định là khach_hang
        const role = VaiTro || vaitro || 'khach_hang'; 

        if (!email || !password || !fullName || !phoneNumber || !address) {
            return res.status(400).json({
                succeeded: false, 
                message: 'Không được bỏ trống các trường'
            });
        }

        const existingUser = await userModel.findByUsername(email);
        if (existingUser) {
            return res.status(409).json({
                succeeded: false, 
                message: 'Email đã tồn tại'
            });
        }

        if (!userController.validatePassword(password)) {
            return res.status(400).json({
                succeeded: false, 
                message: 'Mật khẩu yếu: 8-100 ký tự, phải bao gồm A-Z, a-z, 0-9, ký tự đặc biệt'
            });
        }

        const hashedPassword = await hash(password, PASSWORD_HASH_ROUNDS);

        const newId = await userModel.create({
            Fullname: fullName,
            Email: email, 
            hashedPassword: hashedPassword,
            Address: address,
            PhoneNumber: phoneNumber,
            VaiTro: role // Truyền biến role đã gộp xuống Model
        });

        if (!newId) return res.status(500).json({succeeded:false, message: "Tạo tài khoản thất bại"});
        return res.status(201).json({
            succeeded: true, 
            user: { id: newId, email }
        });
    }

    static async logout(req, res) {
        const token = req.token;
        if(!token) return res.status(400).json({succeeded: false, message: 'No token provided'});
        const decoded = jwt.decode(token);
        const exp = decoded && decoded.exp ? new Date(decoded.exp * 1000) : null;
        if(!exp) return res.status(400).json({succeeded: false, message: 'Invalid token'});
        const result = await userModel.revokeToken(token, exp);
        if(!result) throw new Error('Token revocation failed');
        return res.status(200).json({succeeded: true, message: 'Logged out'})
    }

    // =========================================================
    // HÀM PROFILE (ĐÃ ĐƯỢC CHUẨN HÓA DỮ LIỆU CHO FLUTTER)
    // =========================================================
    static async profile(req, res) {
        const id = req.userid;
        if(!id) return res.status(401).json({succeeded: false ,message: "Unauthorized"});
        
        const user = await userModel.findById(id);
        if(!user) return res.status(404).json({succeeded: false, message: "User not found"});
        
        // ĐỒNG BỘ CHUẨN FLUTTER: Bổ sung is_admin và bọc chuỗi rỗng để chống lỗi Null
        const safeUser = {
            id: user.MaNguoiDung,             
            fullname: user.HoTen || "",              
            email: user.Email || "",
            phone_number: user.SoDienThoai || "",
            address: user.DiaChiNguoiDung || "",
            avatar: user.AnhDaiDien || "", // Đổi NULL thành chuỗi rỗng
            role: user.VaiTro || "khach_hang",
            is_admin: (user.VaiTro === 'admin' || user.VaiTro === 'Admin') ? 1 : 0, // Dành cho Flutter
            status: user.TrangThaiTaiKhoan || "HoatDong",
            created_at: user.NgayTao
        };

        return res.status(200).json({succeeded: true, user: safeUser});
    }

    // =========================================================
    // HÀM ĐĂNG NHẬP ADMIN 
    // =========================================================
    static async adminLogin(req, res) {
        try {
            const { email, password } = req.body;
        
        // THÊM DÒNG NÀY: Chuẩn hóa email
        const normalizedEmail = email.toLowerCase().trim(); 

        // 1. Tìm user trong database bằng email đã chuẩn hóa
        const user = await userModel.findByUsername(normalizedEmail);
            if (!user) {
                return res.status(401).json({ succeeded: false, message: "Email Admin không tồn tại!" });
            }

            // 2. Chuẩn hóa kiểm tra vai trò từ Database (Đề phòng chữ hoa/thường)
            let dbRole = user.VaiTro || user.vaitro || user.role || user.VaiTroTaiKhoan || '';
            dbRole = dbRole.toString().toLowerCase().trim();

            // 3. KIỂM TRA QUYỀN ADMIN CHUẨN XÁC
            // Chấp nhận nếu email là admin@gmail.com HOẶC cột vai trò trong DB có chữ 'admin'
            const isAdminEmail = (user.Email === 'admin@gmail.com' || user.email === 'admin@gmail.com');
            const isAdminRole = (dbRole === 'admin');

            if (!isAdminEmail && !isAdminRole) {
                return res.status(403).json({ succeeded: false, message: "Không phải admin" });
            }

            // 4. Kiểm tra mật khẩu (Giữ nguyên logic bcrypt.compare cũ của bạn)
            const dbPassword = user.MatKhau || user.matkhau || user.password;
            const isMatch = await compare(password, dbPassword);
            
            if (!isMatch) {
                return res.status(401).json({ succeeded: false, message: "Mật khẩu Admin không chính xác!" });
            }

            // 5. Tạo Token Admin thông qua hàm generateToken có sẵn của bạn
            const token = await userController.generateToken(user);

            // 6. Trả về kết quả thành công cho Thunder Client
            return res.status(200).json({
                succeeded: true,
                message: "Đăng nhập quyền Admin thành công!",
                token: token,
                user: {
                    id: user.MaNguoiDung,
                    email: user.Email || user.email,
                    fullName: user.HoTen || user.fullName,
                    role: "admin"
                }
            });

        } catch (error) {
            return res.status(500).json({ succeeded: false, message: error.message });
        }
    }
    
    // =========================================================
    // HÀM LẤY TẤT CẢ USER (ĐÃ CHUẨN HÓA DỮ LIỆU)
    // =========================================================
    static async getAllUsers(req, res) {
        try {
            const users = await userModel.all();

            // ĐỒNG BỘ CHO DANH SÁCH: Áp dụng tương tự như profile
            const safeUsers = users.map(user => ({
                id: user.MaNguoiDung,
                fullname: user.HoTen || "",
                email: user.Email || "",
                phone_number: user.SoDienThoai || "",
                address: user.DiaChiNguoiDung || "",
                avatar: user.AnhDaiDien || "",
                role: user.VaiTro || "khach_hang",
                is_admin: (user.VaiTro === 'admin' || user.VaiTro === 'Admin') ? 1 : 0,
                status: user.TrangThaiTaiKhoan || "HoatDong"
            }));

            return res.status(200).json({
                succeeded: true,
                message: "Lấy danh sách thành công",
                data: safeUsers
            });
        } catch(error) {
            return res.status(500).json({
                succeeded: false,
                message: error.message
            });
        }
    }
    
    static async updateUser(req, res) {
        try {
            const id = req.userid;
            const {fullName, phoneNumber, address} = req.body;
            console.log("DEBUG:", id, fullName, phoneNumber, address);
            if(!fullName || !phoneNumber || !address) return res.status(400).json({succeeded: false, message: "Thiếu thông tin"});
            const update = await userModel.updateUser(id, fullName, phoneNumber, address);
            if(!update) return res.status(404).json({succeeded: false, message:"Không thể thay đổi thông tin người dùng"});
            return res.status(200).json({succeeded: true, message: "Đổi thông tin thành công"});
        }
        catch(error) {
            return res.status(500).json({
                succeeded: false,
                message: error.message
            });
        }
    }

    static async changePassword(req, res) {
        try {
            const user_id = req.userid;
            const {newPassword, currentPassword} = req.body;

            if(!newPassword) return res.status(400).json({succeeded: false, message: "Thiếu mật khẩu mới"});

            if (!userController.validatePassword(newPassword)) {
                return res.status(400).json({
                    succeeded: false, 
                    message: 'Mật khẩu yếu: 8-100 ký tự, phải bao gồm A-Z, a-z, 0-9, ký tự đặc biệt'
                });
            }

            await userModel.changePass(currentPassword, newPassword, user_id);

            return res.status(200).json({succeeded: true, message: "Đổi mật khẩu thành công"});
        }
        catch(error) {
            return res.status(500).json({
                succeeded:false,
                message: "Lỗi đổi mật khẩu: " + error.message
            });
        }
    }

    // =========================================================
    // CONTROLLER: ADMIN KHÓA TÀI KHOẢN LỪA ĐẢO
    // =========================================================
    static async lockUserAccount(req, res) {
        try {
            const { userId } = req.params;
            const action = req.body.action || 'lock'; // Mặc định là khóa ('lock' hoặc 'unlock')

            // 1. Kiểm tra xem tài khoản này có tồn tại không
            const user = await userModel.findById(userId);
            if (!user) {
                return res.status(404).json({ succeeded: false, message: "Không tìm thấy người dùng này!" });
            }

            // 2. Không cho phép Admin tự khóa chính mình
            if (userId == req.userid) {
                return res.status(403).json({ succeeded: false, message: "Bạn không thể tự khóa tài khoản Admin của chính mình!" });
            }

            // 3. Tiến hành khóa hoặc mở khóa
            const newStatus = action === 'lock' ? 'Khoa' : 'HoatDong';
            const isUpdated = await userModel.updateAccountStatus(userId, newStatus);

            if (isUpdated) {
                const msg = action === 'lock' ? "Khóa tài khoản lừa đảo thành công!" : "Đã mở khóa tài khoản!";
                return res.status(200).json({ succeeded: true, message: msg });
            } else {
                return res.status(400).json({ succeeded: false, message: "Thao tác thất bại." });
            }
        } catch (error) {
            return res.status(500).json({ succeeded: false, message: error.message });
        }
    }

    // =========================================================
    // CONTROLLER: NÂNG CẤP QUYỀN THÀNH CẢ HAI
    // =========================================================
    static async upgradeRole(req, res) {
        try {
            const userId = req.userid; // Lấy ID từ token đăng nhập
            if (!userId) return res.status(401).json({ succeeded: false, message: "Unauthorized" });

            const isUpdated = await userModel.upgradeRoleToBoth(userId);
            if (isUpdated) {
                return res.status(200).json({ 
                    succeeded: true, 
                    message: "Nâng cấp thành công! Bây giờ bạn có thể vừa thuê vừa cho thuê." 
                });
            } else {
                return res.status(400).json({ succeeded: false, message: "Không thể nâng cấp tài khoản." });
            }
        } catch (error) {
            return res.status(500).json({ succeeded: false, message: error.message });
        }
    }

}
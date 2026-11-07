import { beginTransaction, commitTransaction, rollbackTransaction, execute } from "../config/db.js";
 
export default class orderModel {
    static async getShippingFee(city) {
        if (!city) return 30000;
        const normalizedCity = city.toLowerCase();
        if (normalizedCity.includes("hồ chí minh") || normalizedCity.includes("hcm")) return 20000;
        if (normalizedCity.includes("hà nội")) return 35000;
        return 30000; 
    }

    static async checkout(userId, shippingData, couponCode, payment_method, orderItems, is_buy_now) {
        const { beginTransaction, commitTransaction, rollbackTransaction, execute } = await import("../config/db.js");
        const conn = await beginTransaction(); 

        try {
            if (!orderItems || orderItems.length === 0) throw new Error("Danh sách sản phẩm trống!");

            const dateThue = new Date(shippingData.NgayThue);
            const dateTra = new Date(shippingData.NgayTra);
            const rentalDays = Math.ceil(Math.abs(dateTra - dateThue) / (1000 * 60 * 60 * 24)) || 1; 

            let tongTienThueGoc = 0;
            let tongTienCocCoDinh = 0;
            let firstOwnerId = null; // Lấy chủ sở hữu của sản phẩm đầu tiên làm chủ đơn

            for (const item of orderItems) {
                const productId = item.product_id || item.product_variant_id;
                
                // Bỏ SoLuongTon vì DB không có
                const [prodRows] = await conn.execute(
                    "SELECT MaChuSoHuu, TenSanPham, GiaThueTheoNgay, TienCoc FROM sanpham WHERE MaSanPham = ? FOR UPDATE", 
                    [productId]
                );

                if (prodRows.length === 0) throw new Error(`Không tìm thấy sản phẩm có ID: ${productId}`);
                const product = prodRows[0];
                if (!firstOwnerId) firstOwnerId = product.MaChuSoHuu;

                // Do DB không có cột SoLuong trong chitietdonthue, ta tính gộp tiền dựa vào số lượng khách yêu cầu
                const quantity = item.quantity || 1;
                tongTienThueGoc += parseFloat(product.GiaThueTheoNgay) * quantity * rentalDays;
                tongTienCocCoDinh += parseFloat(product.TienCoc) * quantity;
            }

            let discountRate = 0; 
            if (rentalDays >= 3 && rentalDays <= 6) discountRate = 0.1;
            else if (rentalDays >= 7) discountRate = 0.2;
            const tienThueSauGiam = tongTienThueGoc * (1 - discountRate);

            let PhanTramHoaHong = (rentalDays < 3) ? 5 : (rentalDays <= 7 ? 10 : 15);
            let TienHoaHong = tienThueSauGiam * (PhanTramHoaHong / 100);
            const shippingFee = await this.getShippingFee(shippingData.city);
            const tongThanhToan = tienThueSauGiam + shippingFee;
            const DiaChiGiaoHang = `${shippingData.address}, ${shippingData.city}`;

            // SỬA: Bỏ NgayBatDau, NgayKetThuc khỏi donthue. Thêm MaChuSoHuu. Đổi 'pending' thành 'cho_duyet'
            const insertOrderSql = `
                INSERT INTO donthue (
                    MaKhachThue, MaChuSoHuu, PhuongThucGiaoNhan, 
                    DiaChiGiaoHang, GhiChu, NgayGui, TongTienThue, 
                    TongTienCoc, PhiGiaoHang, TrangThaiDon, TrangThaiGiaoHang, NgayTao, 
                    PhanTramHoaHong, TienHoaHong
                ) VALUES (?, ?, ?, ?, ?, NOW(), ?, ?, ?, 'cho_duyet', 'chua_giao', NOW(), ?, ?)
            `;
            
            const [orderResult] = await conn.execute(insertOrderSql, [
                userId, firstOwnerId, payment_method, DiaChiGiaoHang,
                shippingData.note || '', tongThanhToan, tongTienCocCoDinh, shippingFee, PhanTramHoaHong, TienHoaHong
            ]);

            const newOrderId = orderResult.insertId;

            // SỬA: Đưa NgayBatDau, NgayKetThuc vào chitietdonthue. Bỏ cột SoLuong vì DB không có.
            for (const item of orderItems) {
                const productId = item.product_id || item.product_variant_id;
                const quantity = item.quantity || 1;
                
                const [pRows] = await conn.execute("SELECT MaChuSoHuu, GiaThueTheoNgay, TienCoc FROM sanpham WHERE MaSanPham = ?", [productId]);
                const p = pRows[0];
                const itemThanhTien = parseFloat(p.GiaThueTheoNgay) * quantity * rentalDays;
                const itemCoc = parseFloat(p.TienCoc) * quantity;

                await conn.execute(
                    `INSERT INTO chitietdonthue (MaDonThue, MaChuSoHuu, MaSanPham, MaBienThe, NgayBatDau, NgayKetThuc, DonGiaThue, TienCocDong, ThanhTien) 
                     VALUES (?, ?, ?, NULL, ?, ?, ?, ?, ?)`,
                    [newOrderId, p.MaChuSoHuu, productId, shippingData.NgayThue, shippingData.NgayTra, p.GiaThueTheoNgay, itemCoc, itemThanhTien]
                );
            }

            if (!is_buy_now) await conn.execute("DELETE FROM giohang WHERE MaNguoiDung = ?", [userId]); 

            await commitTransaction(conn);
            return newOrderId;

        } catch (error) {
            await rollbackTransaction(conn);
            throw error; 
        }
    }

    static async cancelOrder(order_id){
        const conn = await beginTransaction();
        try {
            const [order] = await conn.query("SELECT TrangThaiDon AS status FROM donthue WHERE MaDonThue = ?", [order_id]);
            if (order.length === 0) throw new Error("Không tìm thấy đơn thuê");
            
            if (order[0].status !== 'cho_duyet') {
                throw new Error('Chỉ có thể hủy đơn khi đang chờ duyệt. Đơn của bạn đã được xử lý!');
            }
            // Mặc định hủy đơn (cần đảm bảo CSDL bạn có Enum cancelled hoặc tu_choi, ở đây mình dùng cancelled)
            await conn.query("UPDATE donthue SET TrangThaiDon = 'cancelled' WHERE MaDonThue = ?", [order_id]);
            await commitTransaction(conn);
            return true;
        } catch(error){
            await rollbackTransaction(conn);
            throw new Error('Lỗi hủy đơn thuê: ' + error.message);
        }
    }

    static async getOrderDetail(order_ID){
        try {
            // SỬA: Lấy NgayBatDau, NgayKetThuc từ chitietdonthue thay vì donthue
            const [orderDetail] = await execute(`
                SELECT 
                    d.MaDonThue, d.MaKhachThue, d.MaChuSoHuu, d.DiaChiGiaoHang, d.PhuongThucGiaoNhan, d.GhiChu, 
                    d.NgayTraThucTe, d.TongTienThue, d.TongTienCoc, d.PhiGiaoHang, 
                    d.PhanTramHoaHong, d.TienHoaHong, d.SoTienCocHoanTra, d.TienPhat,
                    d.TrangThaiDon as status, d.TrangThaiGiaoHang, d.NgayTao,
                    ct.MaChiTietDon, ct.MaSanPham, ct.NgayBatDau, ct.NgayKetThuc, ct.ThanhTien,
                    sp.TenSanPham, sp.GiaThueTheoNgay
                FROM donthue d
                JOIN chitietdonthue ct ON d.MaDonThue = ct.MaDonThue 
                JOIN sanpham sp ON ct.MaSanPham = sp.MaSanPham
                WHERE d.MaDonThue = ?
            `, [order_ID]);
            return orderDetail;
        } catch(error){
            throw new Error('Lỗi lấy chi tiết đơn: ' + error.message);
        }
    }

    static async getListOrderByUserID(user_id){
        try {
            const [listOrder] = await execute(`SELECT * FROM donthue WHERE MaKhachThue = ? ORDER BY NgayTao DESC`, [user_id]);
            return listOrder;
        } catch(error){
            throw new Error('Lỗi lấy danh sách đơn của khách: ' + error.message);
        }
    }

    static async getAllOrder(){
        try {
            const [orders] = await execute(`SELECT * FROM donthue ORDER BY NgayTao DESC`);
            return orders;
        } catch(error){
            throw new Error("Lỗi lấy tất cả đơn thuê: " + error.message);
        }
    }

    static async returnOrder(order_id, tien_phat_thu_cong, ghi_chu) {
        try {
            // SỬA: Phải Join để lấy NgayKetThuc từ chitietdonthue
            const [orders] = await execute(
                `SELECT d.TongTienCoc, d.TrangThaiDon, d.TongTienThue, ct.NgayKetThuc 
                 FROM donthue d
                 JOIN chitietdonthue ct ON d.MaDonThue = ct.MaDonThue 
                 WHERE d.MaDonThue = ? LIMIT 1`, 
                [order_id]
            );
            
            if (orders.length === 0) throw new Error("Không tìm thấy đơn thuê");
            const order = orders[0];
            
            if (order.TrangThaiDon === 'cancelled' || order.TrangThaiDon === 'completed') {
                 throw new Error("Đơn hàng này đã bị hủy hoặc đã hoàn tất trước đó!");
            }

            const ngayHenTra = new Date(order.NgayKetThuc);
            const ngayThucTra = new Date(); 
            let soNgayTre = 0;
            let tienPhatTre = 0;

            if (ngayThucTra > ngayHenTra) {
                const diffTime = Math.abs(ngayThucTra - ngayHenTra);
                soNgayTre = Math.floor(diffTime / (1000 * 60 * 60 * 24));
            }

            if (soNgayTre > 0) tienPhatTre = soNgayTre * (parseFloat(order.TongTienThue) * 0.1);
            const tongTienPhat = tienPhatTre + (parseFloat(tien_phat_thu_cong) || 0);

            let tienCocHoanTra = parseFloat(order.TongTienCoc) - tongTienPhat;
            if (tienCocHoanTra < 0) tienCocHoanTra = 0; 

            let finalNote = ghi_chu ? ` | Admin: ${ghi_chu}` : '';
            if (soNgayTre > 0) finalNote = `Khách trả trễ ${soNgayTre} ngày (Máy tự phạt: ${tienPhatTre}đ)${finalNote}`;

            const sql = `
                UPDATE donthue
                SET TrangThaiDon = 'completed',
                    TrangThaiGiaoHang = 'da_thu_hoi',
                    NgayTraThucTe = NOW(),
                    TienPhat = ?,
                    SoTienCocHoanTra = ?,
                    GhiChu = CONCAT(IFNULL(GhiChu, ''), ?)
                WHERE MaDonThue = ?
            `;
            const [result] = await execute(sql, [tongTienPhat, tienCocHoanTra, finalNote, order_id]);
            return result.affectedRows > 0;
        } catch (error) {
            throw new Error("Lỗi xử lý trả đồ: " + error.message);
        }
    }

    static async getDashboardStats() {
        try {
            const [totalOrdersRows] = await execute("SELECT COUNT(*) AS total FROM donthue");
            const [revenueRows] = await execute("SELECT SUM(TongTienThue) AS total FROM donthue WHERE TrangThaiDon = 'completed'");
            const [totalUsersRows] = await execute("SELECT COUNT(*) AS total FROM nguoidung WHERE VaiTro = 'user'");
            const [pendingOrdersRows] = await execute("SELECT COUNT(*) AS total FROM donthue WHERE TrangThaiDon = 'cho_duyet'");

            return {
                totalOrders: totalOrdersRows[0].total || 0,
                totalRevenue: revenueRows[0].total || 0,
                totalUsers: totalUsersRows[0].total || 0,
                pendingOrdersToday: pendingOrdersRows[0].total || 0
            };
        } catch (error) {
            throw new Error("Lỗi truy vấn dữ liệu thống kê: " + error.message);
        }
    }
    
    static async getOrdersByCustomerId(customerId) {
        try {
            const [orders] = await execute("SELECT * FROM donthue WHERE MaKhachThue = ? ORDER BY MaDonThue DESC", [customerId]);
            return orders;
        } catch (error) {
            throw new Error("Lỗi lấy danh sách đơn đã đặt: " + error.message);
        }
    }

    static async getIncomingRequestsForLessor(lessorId) {
        try {
            const query = `
                SELECT DISTINCT 
                    d.MaDonThue, d.MaKhachThue, d.TongTienThue, d.TrangThaiDon, d.NgayTao,
                    p.TenSanPham, p.MaSanPham
                FROM donthue d
                JOIN chitietdonthue ct ON d.MaDonThue = ct.MaDonThue
                JOIN sanpham p ON ct.MaSanPham = p.MaSanPham
                WHERE d.MaChuSoHuu = ?
                ORDER BY d.MaDonThue DESC
            `;
            const [requests] = await execute(query, [lessorId]);
            return requests;
        } catch (error) {
            throw new Error("Lỗi lấy yêu cầu thuê của chủ đồ: " + error.message);
        }
    }

    static async insertComplaint(orderId, userId, loaiKhieuNai, lyDo, hinhAnh) {
        const { beginTransaction, commitTransaction, rollbackTransaction } = await import("../config/db.js");
        const conn = await beginTransaction();
        try {
            const [orderCheck] = await conn.execute(
                `SELECT MaDonThue FROM donthue WHERE MaDonThue = ? AND (MaKhachThue = ? OR MaChuSoHuu = ?) LIMIT 1`,
                [orderId, userId, userId]
            );

            if (orderCheck.length === 0) throw new Error("Không tìm thấy đơn hàng, hoặc bạn không có quyền khiếu nại!");

            const insertSql = `
                INSERT INTO khieunai (MaDonThue, MaNguoiKhieuNai, LoaiKhieuNai, LyDo, HinhAnhBangChung, TrangThai, NgayKhieuNai)
                VALUES (?, ?, ?, ?, ?, 'Chờ xử lý', NOW())
            `;
            const [complaintResult] = await conn.execute(insertSql, [
                orderId, userId, loaiKhieuNai || 'LuaDao_TraoHang', lyDo, hinhAnh || null
            ]);

            await conn.execute("UPDATE donthue SET TrangThaiDon = 'resolved' WHERE MaDonThue = ?", [orderId]);
            await commitTransaction(conn);
            return complaintResult.insertId;
        } catch (error) {
            await rollbackTransaction(conn);
            throw new Error("Lỗi khi tạo khiếu nại: " + error.message);
        }
    }

    static async resolveComplaint(complaintId, adminId, hinhThucId, soTien, noiDung, trangThaiDonMoi) {
        const { beginTransaction, commitTransaction, rollbackTransaction } = await import("../config/db.js");
        const conn = await beginTransaction();

        try {
            const systemWalletId = 5;
            const [complaintRows] = await conn.execute(
                `SELECT kn.MaDonThue, dt.MaKhachThue, dt.TongTienThue, dt.TongTienCoc, dt.MaChuSoHuu AS MaChuDo
                 FROM khieunai kn
                 JOIN donthue dt ON kn.MaDonThue = dt.MaDonThue
                 WHERE kn.MaKhieuNai = ? LIMIT 1 FOR UPDATE`, 
                [complaintId]
            );

            if (complaintRows.length === 0) throw new Error("Không tìm thấy dữ liệu khiếu nại này!");

            const data = complaintRows[0];
            const orderId = data.MaDonThue;
            const totalAmountPaid = parseFloat(data.TongTienThue || 0) + parseFloat(data.TongTienCoc || 0);
            const amountToProcess = parseFloat(soTien || totalAmountPaid);

            const [tenantWallet] = await conn.execute("SELECT MaVi FROM vi WHERE MaNguoiDung = ?", [data.MaKhachThue]);
            const [hostWallet] = await conn.execute("SELECT MaVi FROM vi WHERE MaNguoiDung = ?", [data.MaChuDo]);
            const customerWalletId = tenantWallet[0]?.MaVi;
            const hostWalletId = hostWallet[0]?.MaVi;

            // SỬA: Khớp Enum bảng giaodichvi -> 'ThanhCong', 'HoanTien', 'GiaiNgan'
            if (hinhThucId == 1) {
                await conn.execute("UPDATE vi SET SoTienDongBang = SoTienDongBang - ?, NgayCapNhat = NOW() WHERE MaVi = ?", [amountToProcess, systemWalletId]);
                await conn.execute("UPDATE vi SET SoDuKhaDung = SoDuKhaDung + ?, NgayCapNhat = NOW() WHERE MaVi = ?", [amountToProcess, customerWalletId]);
                await conn.execute(
                    `INSERT INTO giaodichvi (MaVi, MaViDoiTac, MaDonThue, LoaiGiaoDich, SoTien, TrangThai, NgayGiaoDich) VALUES (?, ?, ?, 'HoanTien', ?, 'ThanhCong', NOW())`,
                    [customerWalletId, systemWalletId, orderId, amountToProcess]
                );
            } else if (hinhThucId == 2) {
                await conn.execute("UPDATE vi SET SoTienDongBang = SoTienDongBang - ?, NgayCapNhat = NOW() WHERE MaVi = ?", [amountToProcess, systemWalletId]);
                await conn.execute("UPDATE vi SET SoDuKhaDung = SoDuKhaDung + ?, NgayCapNhat = NOW() WHERE MaVi = ?", [amountToProcess, hostWalletId]);
                await conn.execute(
                    `INSERT INTO giaodichvi (MaVi, MaViDoiTac, MaDonThue, LoaiGiaoDich, SoTien, TrangThai, NgayGiaoDich) VALUES (?, ?, ?, 'HoanTien', ?, 'ThanhCong', NOW())`,
                    [hostWalletId, systemWalletId, orderId, amountToProcess]
                );
            } else if (hinhThucId == 3) {
                const halfAmount = amountToProcess / 2;
                await conn.execute("UPDATE vi SET SoTienDongBang = SoTienDongBang - ?, NgayCapNhat = NOW() WHERE MaVi = ?", [amountToProcess, systemWalletId]);
                await conn.execute("UPDATE vi SET SoDuKhaDung = SoDuKhaDung + ?, NgayCapNhat = NOW() WHERE MaVi = ?", [halfAmount, customerWalletId]);
                await conn.execute("UPDATE vi SET SoDuKhaDung = SoDuKhaDung + ?, NgayCapNhat = NOW() WHERE MaVi = ?", [halfAmount, hostWalletId]);
                await conn.execute(
                    `INSERT INTO giaodichvi (MaVi, MaViDoiTac, MaDonThue, LoaiGiaoDich, SoTien, TrangThai, NgayGiaoDich)
                     VALUES (?, ?, ?, 'HoanTien', ?, 'ThanhCong', NOW()), (?, ?, ?, 'GiaiNgan', ?, 'ThanhCong', NOW())`,
                    [customerWalletId, systemWalletId, orderId, halfAmount, hostWalletId, systemWalletId, orderId, halfAmount]
                );
            }

            await conn.execute(
                `UPDATE khieunai SET MaHinhThucXuLy = ?, NgayGiaiQuyet = NOW(), SoTienTuongUng = ?, NoiDungChiTiet = ?, MaAdmin = ?, TrangThai = 'Đã giải quyết' WHERE MaKhieuNai = ?`,
                [hinhThucId, amountToProcess, noiDung, adminId, complaintId]
            );
            await conn.execute("UPDATE donthue SET TrangThaiDon = ? WHERE MaDonThue = ?", [trangThaiDonMoi || 'resolved', orderId]);

            await commitTransaction(conn);
            return true;
        } catch (error) {
            await rollbackTransaction(conn);
            throw new Error("Lỗi khi xử lý khiếu nại: " + error.message);
        }
    }

    static async getPendingComplaints() {
        const { execute } = await import("../config/db.js");
        const [rows] = await execute(`SELECT kn.*, nd.HoTen AS TenNguoiKhieuNai FROM khieunai kn LEFT JOIN nguoidung nd ON kn.MaNguoiKhieuNai = nd.MaNguoiDung WHERE kn.TrangThai = 'Chờ xử lý' ORDER BY kn.NgayKhieuNai DESC`);
        return rows;
    }

    static async processPaymentEscrow(orderId, customerUserId, totalAmount) {
        const { beginTransaction, commitTransaction, rollbackTransaction } = await import("../config/db.js");
        const conn = await beginTransaction();

        try {
            const systemWalletId = 5; 
            const [customerWalletRows] = await conn.execute("SELECT MaVi, SoDuKhaDung FROM vi WHERE MaNguoiDung = ? FOR UPDATE", [customerUserId]);
            if (customerWalletRows.length === 0) throw new Error("Không tìm thấy ví của khách hàng.");
            
            const customerWallet = customerWalletRows[0];
            if (parseFloat(customerWallet.SoDuKhaDung) < parseFloat(totalAmount)) throw new Error("Số dư khả dụng không đủ.");

            await conn.execute("UPDATE vi SET SoDuKhaDung = SoDuKhaDung - ?, NgayCapNhat = NOW() WHERE MaVi = ?", [totalAmount, customerWallet.MaVi]);
            await conn.execute("UPDATE vi SET SoTienDongBang = SoTienDongBang + ?, NgayCapNhat = NOW() WHERE MaVi = ?", [totalAmount, systemWalletId]);

            // SỬA: Đổi 'Thành công' thành 'ThanhCong' để khớp Enum bảng giaodichvi
            await conn.execute(
                `INSERT INTO giaodichvi (MaVi, MaViDoiTac, MaDonThue, LoaiGiaoDich, SoTien, TrangThai, NgayGiaoDich) VALUES (?, ?, ?, 'ThanhToan', ?, 'ThanhCong', NOW())`,
                [customerWallet.MaVi, systemWalletId, orderId, totalAmount]
            );
            await conn.execute(
                `INSERT INTO giaodichvi (MaVi, MaViDoiTac, MaDonThue, LoaiGiaoDich, SoTien, TrangThai, NgayGiaoDich) VALUES (?, ?, ?, 'NhanTamGiu', ?, 'ThanhCong', NOW())`,
                [systemWalletId, customerWallet.MaVi, orderId, totalAmount]
            );
            await conn.execute("UPDATE donthue SET TrangThaiDon = 'confirmed' WHERE MaDonThue = ?", [orderId]);

            await commitTransaction(conn);
            return true;
        } catch (error) {
            await rollbackTransaction(conn);
            throw error;
        }
    }

    static async completeOrderAndPayout(orderId) {
        const { beginTransaction, commitTransaction, rollbackTransaction } = await import("../config/db.js");
        const conn = await beginTransaction();

        try {
            const systemWalletId = 5; 
            const [orderRows] = await conn.execute(
                `SELECT MaDonThue, MaKhachThue, TongTienThue, TongTienCoc, TrangThaiDon, MaChuSoHuu AS MaChuDo
                 FROM donthue WHERE MaDonThue = ? LIMIT 1 FOR UPDATE`,
                [orderId]
            );

            if (orderRows.length === 0) throw new Error("Không tìm thấy đơn thuê!");
            const order = orderRows[0];
            if (order.TrangThaiDon !== 'confirmed' && order.TrangThaiDon !== 'completed') {
                throw new Error("Đơn hàng chưa thanh toán hoặc đang tranh chấp!");
            }

            const rentalFee = parseFloat(order.TongTienThue || 0); 
            const depositFee = parseFloat(order.TongTienCoc || 0); 
            const totalAmount = rentalFee + depositFee;

            const [tenantWallet] = await conn.execute("SELECT MaVi FROM vi WHERE MaNguoiDung = ?", [order.MaKhachThue]);
            const [hostWallet] = await conn.execute("SELECT MaVi FROM vi WHERE MaNguoiDung = ?", [order.MaChuDo]);
            if (tenantWallet.length === 0 || hostWallet.length === 0) throw new Error("Không tìm thấy thông tin ví!");

            const customerWalletId = tenantWallet[0].MaVi;
            const hostWalletId = hostWallet[0].MaVi;

            await conn.execute("UPDATE vi SET SoTienDongBang = SoTienDongBang - ?, NgayCapNhat = NOW() WHERE MaVi = ?", [totalAmount, systemWalletId]);
            await conn.execute("UPDATE vi SET SoDuKhaDung = SoDuKhaDung + ?, NgayCapNhat = NOW() WHERE MaVi = ?", [rentalFee, hostWalletId]);
            await conn.execute(
                `INSERT INTO giaodichvi (MaVi, MaViDoiTac, MaDonThue, LoaiGiaoDich, SoTien, TrangThai, NgayGiaoDich) VALUES (?, ?, ?, 'GiaiNgan', ?, 'ThanhCong', NOW())`,
                [hostWalletId, systemWalletId, orderId, rentalFee]
            );

            if (depositFee > 0) {
                await conn.execute("UPDATE vi SET SoDuKhaDung = SoDuKhaDung + ?, NgayCapNhat = NOW() WHERE MaVi = ?", [depositFee, customerWalletId]);
                await conn.execute(
                    `INSERT INTO giaodichvi (MaVi, MaViDoiTac, MaDonThue, LoaiGiaoDich, SoTien, TrangThai, NgayGiaoDich) VALUES (?, ?, ?, 'HoanTien', ?, 'ThanhCong', NOW())`,
                    [customerWalletId, systemWalletId, orderId, depositFee]
                );
            }

            await conn.execute("UPDATE donthue SET TrangThaiDon = 'completed' WHERE MaDonThue = ?", [orderId]);
            await commitTransaction(conn);
            return true;
        } catch (error) {
            await rollbackTransaction(conn);
            throw error;
        }
    }
}
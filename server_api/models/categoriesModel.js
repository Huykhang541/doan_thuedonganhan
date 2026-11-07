import baseUrl from "../baseUrl.js";
import { execute } from "../config/db.js";

export default class categoriesModel {
    static async getAllCategories() {
        try {
            // Sửa tên bảng thành 'danhmuc' viết thường và map lại các cột tiếng Việt sang tiếng Anh
            const [categories] = await execute(
                'SELECT MaDanhMuc AS id, TenDanhMuc AS name, MoTa AS description, HinhAnh AS image_url FROM danhmuc'
            );
            
            if (categories.length === 0) return [];

            return categories;
        }
        catch (error) {
            throw new Error("Lỗi lấy danh mục: " + error.message);
        }
    }
}
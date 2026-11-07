import favoriteModel from '../models/favoriteModel.js';

export default class favoriteController{
    static async getListFavoriteByUserID(req,res){
        try{
            const user_id = req.userid;
            console.log("DEBUG: MaNguoiDung = ", user_id);
            if(!user_id) return res.status(200).json({
                succeeded: true,
                message: "Lấy danh sách sản phẩm ưa thích không có id người dùng",
                favorites: []
            }); 
            const favorites = await favoriteModel.getFavoriteByUserID(user_id);

            return res.status(200).json({
                succeeded: true,
                message: "Lấy danh sách sản phẩm ưa thích thành công",
                favorites: favorites
            });
        }
        catch(error){
            return res.status(500).json({
                succeeded: false,
                message: 'Lỗi lấy danh sách sản phẩm ưa thích ' + error.message
            });
        }
    }
    static async addFavorite(req,res){
        try{
            const user_id = req.userid;
            // SỬA LẠI: Lấy product_id từ URL
            const {product_id} = req.params;
            if(!user_id) return res.status(400).json({succeeded: false, message: "Chưa đăng nhập"});

            const result = await favoriteModel.addFavorite(user_id, product_id);

            return res.status(200).json({
                succeeded: true,
                message: "Thêm sản phẩm vào ưa thích thành công",
                id: result
            });
        }
        catch(error){
            return res.status(500).json({
                succeeded: false,
                message: "Lỗi thêm sản phẩm ưa thích: "+ error.message
            });
        }
    }
    static async removeFavorite(req,res){
        try{
            const user_id = req.userid;
            // SỬA LẠI: Lấy product_id từ URL
            const {product_id} = req.params;
            if(!user_id) return res.status(400).json({succeeded: false, message: "Chưa đăng nhập"});

            const result = await favoriteModel.removeFavorite(user_id, product_id);

            return res.status(200).json({
                succeeded: true,
                message: "Xóa sản phẩm khỏi danh sách ưa thích thành công",
            });
        }
        catch(error){
            return res.status(500).json({
                succeeded: false,
                message: "Lỗi xóa sản phẩm yêu thích: "+ error.message
            });
        }
    }
}
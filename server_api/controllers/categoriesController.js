import categoriesModel from "../models/categoriesModel.js";

export default class categoriesController{
    static async getAllCategories(req,res){
        try{
            const categories = await categoriesModel.getAllCategories();

            return res.status(200).json({
                succeeded: true,
                categories: categories
            });
        }
        catch(error){
            return res.status(500).json({
                succeeded: false,
                message: error.message
            });
        }
    }
}
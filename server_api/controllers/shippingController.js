/*import '../models/shippingModel.js';
import shippingModel from '../models/shippingModel.js';

export default class shippingController{
    static async getShippingFeeByCity(req,res){
        try{
            const {city} = req.query;
            console.log("DEBUG(shipping_fee): ",city);
            if(!city || city === '') return res.status(400).json({
                succeeded: false,
                message: "Thiếu tên thành phố"
            });

            const shippingfee = await shippingModel.getShippingFeeByCity(city);

            return res.status(200).json({
                succeeded: true,
                shipping_fee: shippingfee
            });
        }
        catch(error){
            return res.status(500).json({
                succeeded: false,
                message: error.message
            });
        }
    }
}*/
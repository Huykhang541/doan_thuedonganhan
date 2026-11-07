/*import { execute } from "../config/db.js";

export default class shippingModel{
    static async getShippingFeeByCity(city_name){
        try{
            const [shippingFee] = await execute('SELECT shipping_fee FROM shipping_rates WHERE province LIKE ?',[city_name]);
            console.log("DEBUG(shipping_fee|MODEL): ",shippingFee[0].shipping_fee)
            return shippingFee[0].shipping_fee;
        }
        catch(error){
            throw new Error("Lỗi lấy phí ship: " + error.message);
        }
    }
}*/
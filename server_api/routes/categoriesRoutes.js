import { Router } from "express";
import categoriesController from "../controllers/categoriesController.js";

const categoriesRoute = Router();

categoriesRoute.get('/',categoriesController.getAllCategories);

export default categoriesRoute;
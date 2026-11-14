import swaggerJSDoc from 'swagger-jsdoc';
import baseUrl from '../baseUrl.js';

const options = {
  definition: {
    openapi: '3.0.0', // Chuẩn OpenAPI
    info: {
      title: 'API Tài Liệu Thuê Đồ Ngắn Hạn',
      version: '1.0.0',
      description: 'Mô tả các API của dự án',
    },

    // tags: [
    //   {
    //     name: "Khách thuê",
    //     description: "API dành cho khách thuê đồ",
    //   },
    //   {
    //     name: "Chủ cho thuê",
    //     description: "API dành cho chủ cho thuê",
    //   },
    //   {
    //     name: "Admin",
    //     description: "API thống kê dành cho Admin",
    //   },
    // ],

    

    servers: [
      {
        url: baseUrl, // Đường dẫn server
        description: 'Server Local',
      },
    ],
    components: {
      securitySchemes: {
        bearerAuth: {
          type: 'http',
          scheme: 'bearer',
          bearerFormat: 'JWT',
        },
      },
    },
  },
  // Quan trọng: Chỉ định nơi chứa file code cần quét tài liệu
  apis: ['./routes/*.js'], 
};

const swaggerSpec = swaggerJSDoc(options);
//console.log(Object.keys(swaggerSpec.paths)); kiểm tra coi các link api có chưa
export default swaggerSpec;
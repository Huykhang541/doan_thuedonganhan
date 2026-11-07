import { createPool } from "mysql2/promise";
const pool = createPool({
    host: process.env.DB_HOST,
    user: process.env.DB_USER,
    password: process.env.DB_PASSWORD,
    database: process.env.DB_NAME,
    waitForConnections: true,
    connectionLimit: 10,
    queueLimit: 0
});
export async function execute(query, params) {
    return await pool.execute(query, params);
}

export async function beginTransaction() {
    const connection = await pool.getConnection();
    await connection.beginTransaction();
    return connection;
}
export async function commitTransaction(connection) {
    await connection.commit();
    connection.release();
}
export async function rollbackTransaction(connection) {
    await connection.rollback();
    connection.release();
}
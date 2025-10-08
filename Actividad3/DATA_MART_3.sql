-- ==============================================================
-- MODELO ESTRELLA PARA DATA MART JARDINERÍA
-- ==============================================================
-- 1. Crear la base de datos del data mart
DROP DATABASE IF EXISTS datamart_jardineria;
CREATE DATABASE datamart_jardineria CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE datamart_jardineria;

-- 2. Creo tablas de staging (estructura igual que origen)
CREATE TABLE staging_pedido LIKE jardineria.pedido;
CREATE TABLE staging_detalle_pedido LIKE jardineria.detalle_pedido;
CREATE TABLE staging_producto LIKE jardineria.producto;
CREATE TABLE staging_categoria LIKE jardineria.Categoria_producto;
CREATE TABLE staging_cliente LIKE jardineria.cliente;

-- 3. ingresamos daticos a tablas de staging con datos de la BD original
INSERT INTO staging_pedido SELECT * FROM jardineria.pedido;
INSERT INTO staging_detalle_pedido SELECT * FROM jardineria.detalle_pedido;
INSERT INTO staging_producto SELECT * FROM jardineria.producto;
INSERT INTO staging_categoria SELECT * FROM jardineria.Categoria_producto;
INSERT INTO staging_cliente SELECT * FROM jardineria.cliente;

-- 4. Crear dimensiones
DROP TABLE IF EXISTS dim_tiempo;
CREATE TABLE dim_tiempo (
  time_id INT PRIMARY KEY,
  fecha DATE,
  anio INT,
  mes INT,
  trimestre INT,
  dia_semana INT
);

DROP TABLE IF EXISTS dim_categoria_producto;
CREATE TABLE dim_categoria_producto (
  category_id INT PRIMARY KEY,
  descripcion_categoria VARCHAR(50)
);

DROP TABLE IF EXISTS dim_producto;
CREATE TABLE dim_producto (
  product_id INT PRIMARY KEY,
  codigo_producto VARCHAR(15),
  nombre_producto VARCHAR(70),
  category_id INT,
  descripcion TEXT,
  proveedor VARCHAR(50),
  precio_venta DECIMAL(15,2),
  FOREIGN KEY (category_id) REFERENCES dim_categoria_producto(category_id)
);

SELECT * FROM dim_producto;

DROP TABLE IF EXISTS dim_cliente;
CREATE TABLE dim_cliente (
  customer_id INT PRIMARY KEY,
  nombre_cliente VARCHAR(50),
  ciudad VARCHAR(50),
  region VARCHAR(50),
  pais VARCHAR(50)
);

DROP TABLE IF EXISTS dim_pedido;
CREATE TABLE dim_pedido (
  order_id INT PRIMARY KEY,
  fecha_pedido DATE,
  fecha_entrega DATE,
  estado_pedido VARCHAR(20),
  customer_id INT,
  FOREIGN KEY (customer_id) REFERENCES dim_cliente(customer_id)
);

-- 5. Poblar dimensiones

-- Tiempo (solo fechas únicas)
INSERT IGNORE INTO dim_tiempo (time_id, fecha, anio, mes, trimestre, dia_semana)
SELECT
  DATE_FORMAT(fecha_pedido, '%Y%m%d') AS time_id,
  fecha_pedido,
  YEAR(fecha_pedido) AS anio,
  MONTH(fecha_pedido) AS mes,
  QUARTER(fecha_pedido) AS trimestre,
  DAYOFWEEK(fecha_pedido) AS dia_semana
FROM (
  SELECT DISTINCT fecha_pedido FROM staging_pedido
) fechas_unicas;

-- Categoría
INSERT IGNORE INTO dim_categoria_producto (category_id, descripcion_categoria)
SELECT DISTINCT Id_Categoria, Desc_Categoria FROM staging_categoria;

-- Producto
INSERT IGNORE INTO dim_producto (product_id, codigo_producto, nombre_producto, category_id, descripcion, proveedor, precio_venta)
SELECT ID_producto, CodigoProducto, nombre, Categoria, descripcion, proveedor, precio_venta
FROM staging_producto;

-- Cliente
INSERT IGNORE INTO dim_cliente (customer_id, nombre_cliente, ciudad, region, pais)
SELECT ID_cliente, nombre_cliente, ciudad, region, pais FROM staging_cliente;

-- Pedido
INSERT IGNORE INTO dim_pedido (order_id, fecha_pedido, fecha_entrega, estado_pedido, customer_id)
SELECT ID_pedido, fecha_pedido, fecha_entrega, estado, ID_cliente FROM staging_pedido;

-- 6. Crear tabla de hechos
DROP TABLE IF EXISTS fact_ventas;
CREATE TABLE fact_ventas (
  sale_id INT PRIMARY KEY,
  time_id INT,
  product_id INT,
  category_id INT,
  order_id INT,
  customer_id INT,
  cantidad INT,
  precio_unitario DECIMAL(15,2),
  importe DECIMAL(19,2),
  FOREIGN KEY (time_id) REFERENCES dim_tiempo(time_id),
  FOREIGN KEY (product_id) REFERENCES dim_producto(product_id),
  FOREIGN KEY (category_id) REFERENCES dim_categoria_producto(category_id),
  FOREIGN KEY (order_id) REFERENCES dim_pedido(order_id),
  FOREIGN KEY (customer_id) REFERENCES dim_cliente(customer_id)
);

select * from fact_ventas;

-- 7. Poblar tabla de hechos
INSERT IGNORE INTO fact_ventas (
  sale_id, time_id, product_id, category_id, order_id, customer_id, cantidad, precio_unitario, importe
)
SELECT
  dp.ID_pedido * 10000 + dp.ID_producto,  -- surrogate key ejemplo
  DATE_FORMAT(p.fecha_pedido, '%Y%m%d'),
  dp.ID_producto,
  pr.Categoria,
  dp.ID_pedido,
  p.ID_cliente,
  dp.cantidad,
  dp.precio_unidad,
  (dp.cantidad * dp.precio_unidad)
FROM staging_detalle_pedido dp
JOIN staging_pedido p ON dp.ID_pedido = p.ID_pedido
JOIN staging_producto pr ON dp.ID_producto = pr.ID_producto;

-- 8. Consultas analíticas solicitadas

-- Producto más vendido
SELECT d.nombre_producto, SUM(f.cantidad) AS total_vendido
FROM fact_ventas f
JOIN dim_producto d ON f.product_id = d.product_id
GROUP BY d.product_id
ORDER BY total_vendido DESC
LIMIT 1;

-- Categoría con más productos
SELECT c.descripcion_categoria, COUNT(*) AS total_productos
FROM dim_producto p
JOIN dim_categoria_producto c ON p.category_id = c.category_id
GROUP BY c.category_id
ORDER BY total_productos DESC
LIMIT 1;

-- Año con más ventas
SELECT t.anio, SUM(f.importe) AS ventas_totales
FROM fact_ventas f
JOIN dim_tiempo t ON f.time_id = t.time_id
GROUP BY t.anio
ORDER BY ventas_totales DESC
LIMIT 1;


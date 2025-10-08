DROP DATABASE IF EXISTS jardineria_datamart;
CREATE DATABASE jardineria_datamart;
USE jardineria_datamart;

-- Borrar si existe cada tabla para evitar errores
DROP TABLE IF EXISTS fact_ventas;
DROP TABLE IF EXISTS dim_producto;
DROP TABLE IF EXISTS dim_categoria;
DROP TABLE IF EXISTS dim_fecha;

-- 1. Dimensión Producto
CREATE TABLE dim_producto (
  id_producto INT NOT NULL PRIMARY KEY,
  codigo_producto VARCHAR(15),
  nombre_producto VARCHAR(70),
  id_categoria INT NOT NULL
);

-- 2. Dimensión Categoría
CREATE TABLE dim_categoria (
  id_categoria INT NOT NULL PRIMARY KEY,
  nombre_categoria VARCHAR(50)
);

-- 3. Dimensión Fecha (NO "tiempo" con DATE como PK, mejor INT autoincrement o usar solo DATE y referenciar DATE)
CREATE TABLE dim_fecha (
  id_fecha INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  fecha DATE NOT NULL,
  año INT NOT NULL,
  mes INT NOT NULL,
  UNIQUE(fecha)
);

-- LLENADO de dimensiones
INSERT INTO dim_categoria (id_categoria, nombre_categoria)
SELECT DISTINCT Categoria, Desc_Categoria
FROM jardineria_staging_min.producto_staging
JOIN jardineria_staging_min.categoria_producto_staging ON Categoria = Id_Categoria;

INSERT INTO dim_producto (id_producto, codigo_producto, nombre_producto, id_categoria)
SELECT ID_producto, CodigoProducto, nombre, Categoria
FROM jardineria_staging_min.producto_staging;

INSERT INTO dim_fecha (fecha, año, mes)
SELECT DISTINCT fecha_pedido, YEAR(fecha_pedido), MONTH(fecha_pedido)
FROM jardineria_staging_min.pedido_staging;

-- 4. Tabla de hechos: Fact_Ventas (las FK ahora apuntan a los PK correctos)
CREATE TABLE fact_ventas (
  id_detalle_pedido INT PRIMARY KEY,
  id_producto INT NOT NULL,
  id_categoria INT NOT NULL,
  id_fecha INT NOT NULL,
  cantidad INT,
  importe DECIMAL(15,2),
  FOREIGN KEY (id_producto) REFERENCES dim_producto(id_producto),
  FOREIGN KEY (id_categoria) REFERENCES dim_categoria(id_categoria),
  FOREIGN KEY (id_fecha) REFERENCES dim_fecha(id_fecha)
);

-- LLENADO de la tabla de hechos
INSERT INTO fact_ventas (id_detalle_pedido, id_producto, id_categoria, id_fecha, cantidad, importe)
SELECT 
  dp.ID_detalle_pedido,
  dp.ID_producto,
  p.Categoria,
  df.id_fecha,
  dp.cantidad,
  dp.cantidad * dp.precio_unidad
FROM jardineria_staging_min.detalle_pedido_staging dp
JOIN jardineria_staging_min.producto_staging p ON dp.ID_producto = p.ID_producto
JOIN jardineria_staging_min.pedido_staging pe ON dp.ID_pedido = pe.ID_pedido
JOIN dim_fecha df ON pe.fecha_pedido = df.fecha;


-- PRODUCTO MAS VENDIDO
SELECT p.nombre_producto, SUM(f.cantidad) AS total_vendido
FROM fact_ventas f
JOIN dim_producto p ON f.id_producto = p.id_producto
GROUP BY p.id_producto, p.nombre_producto
ORDER BY total_vendido DESC
LIMIT 1;

-- CATEGORÍA CON MÁS PRODUCTOS
SELECT c.nombre_categoria, COUNT(p.id_producto) AS total_productos
FROM dim_producto p
JOIN dim_categoria c ON p.id_categoria = c.id_categoria
GROUP BY c.id_categoria, c.nombre_categoria
ORDER BY total_productos DESC
LIMIT 1;

-- AÑO CON MÁS VENTAS
SELECT df.año, SUM(f.importe) AS total_ventas
FROM fact_ventas f
JOIN dim_fecha df ON f.id_fecha = df.id_fecha
GROUP BY df.año
ORDER BY total_ventas DESC
LIMIT 1;

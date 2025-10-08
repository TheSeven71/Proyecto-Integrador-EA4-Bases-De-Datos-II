-- ==============================================================
-- PROCESO ETL COMPLETO: BD_JARDINERIA → STAGING → DATA MART
-- ==============================================================
-- Autor: Sistema ETL Jardinería
-- Fecha: 30 Septiembre 2025
-- Objetivo: Implementar proceso completo de transformación y carga
--           desde BD origen hasta Data Mart final
-- ==============================================================

-- ==============================================================
-- FASE 1: PREPARACIÓN Y CREACIÓN DE ESTRUCTURAS
-- ==============================================================

-- 1.1 Crear base de datos del Data Mart
DROP DATABASE IF EXISTS datamart_jardineria;
CREATE DATABASE datamart_jardineria CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE datamart_jardineria;

-- ==============================================================
-- FASE 2: EXTRACCIÓN - Creación de tablas STAGING
-- ==============================================================

-- 2.1 Crear tablas de staging con estructura idéntica a origen
CREATE TABLE staging_pedido LIKE jardineria.pedido;
CREATE TABLE staging_detalle_pedido LIKE jardineria.detalle_pedido;
CREATE TABLE staging_producto LIKE jardineria.producto;
CREATE TABLE staging_categoria LIKE jardineria.Categoria_producto;
CREATE TABLE staging_cliente LIKE jardineria.cliente;

-- 2.2 Extracción de datos desde BD origen a Staging
-- Carga completa de datos operacionales
INSERT INTO staging_pedido SELECT * FROM jardineria.pedido;
INSERT INTO staging_detalle_pedido SELECT * FROM jardineria.detalle_pedido;
INSERT INTO staging_producto SELECT * FROM jardineria.producto;
INSERT INTO staging_categoria SELECT * FROM jardineria.Categoria_producto;
INSERT INTO staging_cliente SELECT * FROM jardineria.cliente;

-- 2.3 Verificación de integridad de datos en Staging
SELECT 'Verificación de Staging' AS proceso;
SELECT 'staging_pedido' AS tabla, COUNT(*) AS registros FROM staging_pedido
UNION ALL
SELECT 'staging_detalle_pedido', COUNT(*) FROM staging_detalle_pedido
UNION ALL
SELECT 'staging_producto', COUNT(*) FROM staging_producto
UNION ALL
SELECT 'staging_categoria', COUNT(*) FROM staging_categoria
UNION ALL
SELECT 'staging_cliente', COUNT(*) FROM staging_cliente;

-- ==============================================================
-- FASE 3: TRANSFORMACIÓN - Creación de Dimensiones
-- ==============================================================

-- 3.1 DIMENSIÓN TIEMPO
-- Almacena información temporal para análisis cronológico
DROP TABLE IF EXISTS dim_tiempo;
CREATE TABLE dim_tiempo (
  time_id INT PRIMARY KEY,
  fecha DATE NOT NULL,
  anio INT NOT NULL,
  mes INT NOT NULL,
  trimestre INT NOT NULL,
  dia_semana INT NOT NULL,
  nombre_mes VARCHAR(20),
  nombre_dia VARCHAR(20),
  INDEX idx_fecha (fecha),
  INDEX idx_anio_mes (anio, mes)
);

-- 3.2 DIMENSIÓN CATEGORÍA PRODUCTO
-- Catálogo de categorías de productos
DROP TABLE IF EXISTS dim_categoria_producto;
CREATE TABLE dim_categoria_producto (
  category_id INT PRIMARY KEY,
  descripcion_categoria VARCHAR(50) NOT NULL,
  INDEX idx_desc (descripcion_categoria)
);

-- 3.3 DIMENSIÓN PRODUCTO
-- Catálogo completo de productos con sus atributos
DROP TABLE IF EXISTS dim_producto;
CREATE TABLE dim_producto (
  product_id INT PRIMARY KEY,
  codigo_producto VARCHAR(15) NOT NULL,
  nombre_producto VARCHAR(70) NOT NULL,
  category_id INT NOT NULL,
  descripcion TEXT,
  proveedor VARCHAR(50),
  precio_venta DECIMAL(15,2) NOT NULL,
  INDEX idx_codigo (codigo_producto),
  INDEX idx_categoria (category_id),
  FOREIGN KEY (category_id) REFERENCES dim_categoria_producto(category_id)
);

-- 3.4 DIMENSIÓN CLIENTE
-- Información demográfica y ubicación de clientes
DROP TABLE IF EXISTS dim_cliente;
CREATE TABLE dim_cliente (
  customer_id INT PRIMARY KEY,
  nombre_cliente VARCHAR(50) NOT NULL,
  ciudad VARCHAR(50) NOT NULL,
  region VARCHAR(50),
  pais VARCHAR(50),
  INDEX idx_ciudad (ciudad),
  INDEX idx_pais (pais)
);

-- 3.5 DIMENSIÓN PEDIDO
-- Información sobre pedidos y su estado
DROP TABLE IF EXISTS dim_pedido;
CREATE TABLE dim_pedido (
  order_id INT PRIMARY KEY,
  fecha_pedido DATE NOT NULL,
  fecha_entrega DATE,
  estado_pedido VARCHAR(20) NOT NULL,
  customer_id INT NOT NULL,
  dias_entrega INT,
  INDEX idx_estado (estado_pedido),
  INDEX idx_cliente (customer_id),
  FOREIGN KEY (customer_id) REFERENCES dim_cliente(customer_id)
);

-- ==============================================================
-- FASE 4: CARGA DE DIMENSIONES (Transformación + Inserción)
-- ==============================================================

-- 4.1 Poblar dim_tiempo con transformaciones
-- Extrae fechas únicas y calcula atributos temporales
INSERT INTO dim_tiempo (time_id, fecha, anio, mes, trimestre, dia_semana, nombre_mes, nombre_dia)
SELECT DISTINCT
  DATE_FORMAT(fecha_pedido, '%Y%m%d') AS time_id,
  fecha_pedido,
  YEAR(fecha_pedido) AS anio,
  MONTH(fecha_pedido) AS mes,
  QUARTER(fecha_pedido) AS trimestre,
  DAYOFWEEK(fecha_pedido) AS dia_semana,
  CASE MONTH(fecha_pedido)
    WHEN 1 THEN 'Enero'
    WHEN 2 THEN 'Febrero'
    WHEN 3 THEN 'Marzo'
    WHEN 4 THEN 'Abril'
    WHEN 5 THEN 'Mayo'
    WHEN 6 THEN 'Junio'
    WHEN 7 THEN 'Julio'
    WHEN 8 THEN 'Agosto'
    WHEN 9 THEN 'Septiembre'
    WHEN 10 THEN 'Octubre'
    WHEN 11 THEN 'Noviembre'
    WHEN 12 THEN 'Diciembre'
  END AS nombre_mes,
  CASE DAYOFWEEK(fecha_pedido)
    WHEN 1 THEN 'Domingo'
    WHEN 2 THEN 'Lunes'
    WHEN 3 THEN 'Martes'
    WHEN 4 THEN 'Miércoles'
    WHEN 5 THEN 'Jueves'
    WHEN 6 THEN 'Viernes'
    WHEN 7 THEN 'Sábado'
  END AS nombre_dia
FROM staging_pedido
ORDER BY fecha_pedido;

-- 4.2 Poblar dim_categoria_producto
-- Limpieza: eliminar espacios y normalizar texto
INSERT INTO dim_categoria_producto (category_id, descripcion_categoria)
SELECT 
  Id_Categoria,
  TRIM(Desc_Categoria) AS descripcion_categoria
FROM staging_categoria
ORDER BY Id_Categoria;

-- 4.3 Poblar dim_producto
-- Transformación: normalización de precios y validación
INSERT INTO dim_producto (product_id, codigo_producto, nombre_producto, category_id, descripcion, proveedor, precio_venta)
SELECT 
  ID_producto,
  UPPER(TRIM(CodigoProducto)) AS codigo_producto,
  TRIM(nombre) AS nombre_producto,
  Categoria,
  COALESCE(TRIM(descripcion), 'Sin descripción') AS descripcion,
  COALESCE(TRIM(proveedor), 'Proveedor no especificado') AS proveedor,
  ROUND(precio_venta, 2) AS precio_venta
FROM staging_producto
WHERE precio_venta > 0
ORDER BY ID_producto;

-- 4.4 Poblar dim_cliente
-- Transformación: normalización de ubicaciones
INSERT INTO dim_cliente (customer_id, nombre_cliente, ciudad, region, pais)
SELECT 
  ID_cliente,
  TRIM(nombre_cliente) AS nombre_cliente,
  TRIM(ciudad) AS ciudad,
  COALESCE(TRIM(region), 'No especificada') AS region,
  COALESCE(TRIM(pais), 'España') AS pais
FROM staging_cliente
ORDER BY ID_cliente;

-- 4.5 Poblar dim_pedido
-- Transformación: cálculo de días de entrega y normalización de estados
INSERT INTO dim_pedido (order_id, fecha_pedido, fecha_entrega, estado_pedido, customer_id, dias_entrega)
SELECT 
  ID_pedido,
  fecha_pedido,
  fecha_entrega,
  TRIM(estado) AS estado_pedido,
  ID_cliente,
  CASE 
    WHEN fecha_entrega IS NOT NULL 
    THEN DATEDIFF(fecha_entrega, fecha_pedido)
    ELSE NULL
  END AS dias_entrega
FROM staging_pedido
ORDER BY ID_pedido;

-- ==============================================================
-- FASE 5: CREACIÓN DE TABLA DE HECHOS
-- ==============================================================

-- 5.1 Crear fact_ventas (núcleo del modelo estrella)
DROP TABLE IF EXISTS fact_ventas;
CREATE TABLE fact_ventas (
  sale_id INT PRIMARY KEY,
  time_id INT NOT NULL,
  product_id INT NOT NULL,
  category_id INT NOT NULL,
  order_id INT NOT NULL,
  customer_id INT NOT NULL,
  cantidad INT NOT NULL,
  precio_unitario DECIMAL(15,2) NOT NULL,
  importe DECIMAL(19,2) NOT NULL,
  margen_bruto DECIMAL(19,2),
  INDEX idx_time (time_id),
  INDEX idx_product (product_id),
  INDEX idx_category (category_id),
  INDEX idx_order (order_id),
  INDEX idx_customer (customer_id),
  FOREIGN KEY (time_id) REFERENCES dim_tiempo(time_id),
  FOREIGN KEY (product_id) REFERENCES dim_producto(product_id),
  FOREIGN KEY (category_id) REFERENCES dim_categoria_producto(category_id),
  FOREIGN KEY (order_id) REFERENCES dim_pedido(order_id),
  FOREIGN KEY (customer_id) REFERENCES dim_cliente(customer_id)
);

-- ==============================================================
-- FASE 6: CARGA DE TABLA DE HECHOS
-- ==============================================================

-- 6.1 Poblar fact_ventas con métricas calculadas
-- Transformación: cálculo de importes y márgenes
INSERT INTO fact_ventas (
  sale_id, 
  time_id, 
  product_id, 
  category_id, 
  order_id, 
  customer_id, 
  cantidad, 
  precio_unitario, 
  importe,
  margen_bruto
)
SELECT
  -- Surrogate key compuesta
  dp.ID_pedido * 10000 + dp.ID_producto AS sale_id,
  
  -- FK a dimensión tiempo
  DATE_FORMAT(p.fecha_pedido, '%Y%m%d') AS time_id,
  
  -- FK a dimensión producto
  dp.ID_producto AS product_id,
  
  -- FK a dimensión categoría
  pr.Categoria AS category_id,
  
  -- FK a dimensión pedido
  dp.ID_pedido AS order_id,
  
  -- FK a dimensión cliente
  p.ID_cliente AS customer_id,
  
  -- Métricas
  dp.cantidad,
  ROUND(dp.precio_unidad, 2) AS precio_unitario,
  ROUND(dp.cantidad * dp.precio_unidad, 2) AS importe,
  
  -- Cálculo de margen bruto
  ROUND((dp.cantidad * dp.precio_unidad) - 
        (dp.cantidad * COALESCE(pr.precio_proveedor, 0)), 2) AS margen_bruto
        
FROM staging_detalle_pedido dp
INNER JOIN staging_pedido p ON dp.ID_pedido = p.ID_pedido
INNER JOIN staging_producto pr ON dp.ID_producto = pr.ID_producto
WHERE dp.cantidad > 0 
  AND dp.precio_unidad > 0
ORDER BY dp.ID_pedido, dp.ID_producto;

-- ==============================================================
-- FASE 7: VALIDACIÓN Y CONTROL DE CALIDAD
-- ==============================================================

-- 7.1 Verificar conteo de registros en dimensiones
SELECT 'VALIDACIÓN DE DIMENSIONES' AS reporte;

SELECT 'dim_tiempo' AS dimension, COUNT(*) AS registros FROM dim_tiempo
UNION ALL
SELECT 'dim_categoria_producto', COUNT(*) FROM dim_categoria_producto
UNION ALL
SELECT 'dim_producto', COUNT(*) FROM dim_producto
UNION ALL
SELECT 'dim_cliente', COUNT(*) FROM dim_cliente
UNION ALL
SELECT 'dim_pedido', COUNT(*) FROM dim_pedido
UNION ALL
SELECT 'fact_ventas', COUNT(*) FROM fact_ventas;

-- 7.2 Verificar integridad referencial
SELECT 'VALIDACIÓN DE INTEGRIDAD REFERENCIAL' AS reporte;

-- Verificar que todas las FK en fact_ventas existen en dimensiones
SELECT 
  'Registros huérfanos en fact_ventas' AS problema,
  COUNT(*) AS cantidad
FROM fact_ventas f
WHERE NOT EXISTS (SELECT 1 FROM dim_tiempo t WHERE t.time_id = f.time_id)
   OR NOT EXISTS (SELECT 1 FROM dim_producto p WHERE p.product_id = f.product_id)
   OR NOT EXISTS (SELECT 1 FROM dim_categoria_producto c WHERE c.category_id = f.category_id)
   OR NOT EXISTS (SELECT 1 FROM dim_pedido o WHERE o.order_id = f.order_id)
   OR NOT EXISTS (SELECT 1 FROM dim_cliente cl WHERE cl.customer_id = f.customer_id);

-- 7.3 Verificar consistencia de métricas
SELECT 'VALIDACIÓN DE MÉTRICAS' AS reporte;

SELECT 
  'Total registros en fact_ventas' AS metrica,
  COUNT(*) AS valor
FROM fact_ventas
UNION ALL
SELECT 
  'Importe total de ventas',
  CONCAT('€', FORMAT(SUM(importe), 2))
FROM fact_ventas
UNION ALL
SELECT 
  'Margen bruto total',
  CONCAT('€', FORMAT(SUM(margen_bruto), 2))
FROM fact_ventas
UNION ALL
SELECT 
  'Cantidad total productos vendidos',
  SUM(cantidad)
FROM fact_ventas;

-- ==============================================================
-- FASE 8: CONSULTAS ANALÍTICAS CLAVE
-- ==============================================================

-- 8.1 Producto más vendido
SELECT 'ANÁLISIS: PRODUCTO MÁS VENDIDO' AS analisis;

SELECT 
  d.codigo_producto,
  d.nombre_producto,
  c.descripcion_categoria,
  SUM(f.cantidad) AS unidades_vendidas,
  CONCAT('€', FORMAT(SUM(f.importe), 2)) AS ventas_totales,
  CONCAT('€', FORMAT(AVG(f.precio_unitario), 2)) AS precio_promedio
FROM fact_ventas f
JOIN dim_producto d ON f.product_id = d.product_id
JOIN dim_categoria_producto c ON f.category_id = c.category_id
GROUP BY d.product_id, d.codigo_producto, d.nombre_producto, c.descripcion_categoria
ORDER BY unidades_vendidas DESC
LIMIT 5;

-- 8.2 Categoría con más productos
SELECT 'ANÁLISIS: CATEGORÍA CON MÁS PRODUCTOS' AS analisis;

SELECT 
  c.descripcion_categoria,
  COUNT(DISTINCT p.product_id) AS total_productos,
  COUNT(DISTINCT f.sale_id) AS transacciones,
  CONCAT('€', FORMAT(SUM(f.importe), 2)) AS ventas_totales
FROM dim_producto p
JOIN dim_categoria_producto c ON p.category_id = c.category_id
LEFT JOIN fact_ventas f ON p.product_id = f.product_id
GROUP BY c.category_id, c.descripcion_categoria
ORDER BY total_productos DESC;

-- 8.3 Año con más ventas
SELECT 'ANÁLISIS: AÑO CON MÁS VENTAS' AS analisis;

SELECT 
  t.anio,
  COUNT(DISTINCT f.order_id) AS total_pedidos,
  SUM(f.cantidad) AS unidades_vendidas,
  CONCAT('€', FORMAT(SUM(f.importe), 2)) AS ventas_totales,
  CONCAT('€', FORMAT(AVG(f.importe), 2)) AS ticket_promedio
FROM fact_ventas f
JOIN dim_tiempo t ON f.time_id = t.time_id
GROUP BY t.anio
ORDER BY SUM(f.importe) DESC;

-- 8.4 Ventas por mes y trimestre
SELECT 'ANÁLISIS: VENTAS POR MES' AS analisis;

SELECT 
  t.anio,
  t.nombre_mes,
  t.trimestre,
  COUNT(DISTINCT f.order_id) AS pedidos,
  SUM(f.cantidad) AS unidades,
  CONCAT('€', FORMAT(SUM(f.importe), 2)) AS ventas
FROM fact_ventas f
JOIN dim_tiempo t ON f.time_id = t.time_id
GROUP BY t.anio, t.mes, t.nombre_mes, t.trimestre
ORDER BY t.anio, t.mes;

-- 8.5 Top 10 clientes por ventas
SELECT 'ANÁLISIS: TOP 10 CLIENTES' AS analisis;

SELECT 
  cl.nombre_cliente,
  cl.ciudad,
  cl.region,
  COUNT(DISTINCT f.order_id) AS total_pedidos,
  SUM(f.cantidad) AS unidades_compradas,
  CONCAT('€', FORMAT(SUM(f.importe), 2)) AS gasto_total,
  CONCAT('€', FORMAT(AVG(f.importe), 2)) AS ticket_promedio
FROM fact_ventas f
JOIN dim_cliente cl ON f.customer_id = cl.customer_id
GROUP BY cl.customer_id, cl.nombre_cliente, cl.ciudad, cl.region
ORDER BY SUM(f.importe) DESC
LIMIT 10;

-- 8.6 Análisis de rendimiento por categoría
SELECT 'ANÁLISIS: RENDIMIENTO POR CATEGORÍA' AS analisis;

SELECT 
  c.descripcion_categoria,
  COUNT(DISTINCT f.product_id) AS productos_distintos,
  SUM(f.cantidad) AS unidades_vendidas,
  CONCAT('€', FORMAT(SUM(f.importe), 2)) AS ventas_totales,
  CONCAT('€', FORMAT(SUM(f.margen_bruto), 2)) AS margen_bruto_total,
  CONCAT(FORMAT((SUM(f.margen_bruto) / NULLIF(SUM(f.importe), 0)) * 100, 2), '%') AS porcentaje_margen
FROM fact_ventas f
JOIN dim_categoria_producto c ON f.category_id = c.category_id
GROUP BY c.category_id, c.descripcion_categoria
ORDER BY SUM(f.importe) DESC;

-- 8.7 Análisis de estado de pedidos
SELECT 'ANÁLISIS: ESTADO DE PEDIDOS' AS analisis;

SELECT 
  o.estado_pedido,
  COUNT(DISTINCT o.order_id) AS total_pedidos,
  CONCAT('€', FORMAT(SUM(f.importe), 2)) AS ventas,
  AVG(o.dias_entrega) AS promedio_dias_entrega
FROM dim_pedido o
JOIN fact_ventas f ON o.order_id = f.order_id
GROUP BY o.estado_pedido
ORDER BY COUNT(DISTINCT o.order_id) DESC;

-- ==============================================================
-- FASE 9: LIMPIEZA DE STAGING (OPCIONAL)
-- ==============================================================

-- Comentado por si se necesita auditoría posterior
-- DROP TABLE IF EXISTS staging_pedido;
-- DROP TABLE IF EXISTS staging_detalle_pedido;
-- DROP TABLE IF EXISTS staging_producto;
-- DROP TABLE IF EXISTS staging_categoria;
-- DROP TABLE IF EXISTS staging_cliente;

-- ==============================================================
-- FIN DEL PROCESO ETL
-- ==============================================================

SELECT 'PROCESO ETL COMPLETADO EXITOSAMENTE' AS estado,
       NOW() AS fecha_finalizacion;
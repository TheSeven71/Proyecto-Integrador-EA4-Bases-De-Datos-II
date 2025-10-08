DROP DATABASE IF EXISTS jardineria_staging_min;
CREATE DATABASE jardineria_staging_min;
USE jardineria_staging_min;

-- En las siguientes tablas vamos a guardar solo los campos necesario. 
-- Tabla Producto 
CREATE TABLE producto_staging (
  ID_producto INT,
  CodigoProducto VARCHAR(15),
  nombre VARCHAR(70),
  Categoria INT,
  fecha_ingreso DATETIME
);


-- Tabla Categoría de producto 
CREATE TABLE categoria_producto_staging (
  Id_Categoria INT,
  Desc_Categoria VARCHAR(50),
  fecha_ingreso DATETIME
);

-- Tabla Detalle de pedido (solo lo necesario)
CREATE TABLE detalle_pedido_staging (
  ID_detalle_pedido INT,
  ID_pedido INT,
  ID_producto INT,
  cantidad INT,
  precio_unidad DECIMAL(15,2),
  fecha_ingreso DATETIME
);

-- Tabla Pedido 
CREATE TABLE pedido_staging (
  ID_pedido INT,
  fecha_pedido DATE,
  fecha_ingreso DATETIME
);



-- MIGRACIÓN DE DATOS DE BASE DE DATOS JARDINERÍA A TABLAS STAGING
INSERT INTO producto_staging (ID_producto, CodigoProducto, nombre, Categoria, fecha_ingreso)
SELECT ID_producto, CodigoProducto, nombre, Categoria, NOW() FROM jardineria.producto;

INSERT INTO categoria_producto_staging (Id_Categoria, Desc_Categoria, fecha_ingreso)
SELECT Id_Categoria, Desc_Categoria, NOW() FROM jardineria.Categoria_producto;

INSERT INTO detalle_pedido_staging (ID_detalle_pedido, ID_pedido, ID_producto, cantidad, precio_unidad, fecha_ingreso)
SELECT ID_detalle_pedido, ID_pedido, ID_producto, cantidad, precio_unidad, NOW() FROM jardineria.detalle_pedido;

INSERT INTO pedido_staging (ID_pedido, fecha_pedido, fecha_ingreso)
SELECT ID_pedido, fecha_pedido, NOW() FROM jardineria.pedido;

-- CONSULTAS DE MIGRACIÓN

-- VERIFICAR CANTIDAD DE REGISTROS MIGRADOS
SELECT COUNT(*) AS total_registros FROM producto_staging;
SELECT COUNT(*) AS total_registros FROM categoria_producto_staging;
SELECT COUNT(*) AS total_registros FROM detalle_pedido_staging;
SELECT COUNT(*) AS total_registros FROM pedido_staging;

-- VERIFICACION DE QUE NO HAYA CAMPOS NULOS
SELECT * FROM producto_staging WHERE nombre IS NULL OR Categoria IS NULL;
SELECT * FROM categoria_producto_staging WHERE Desc_Categoria IS NULL;
SELECT * FROM detalle_pedido_staging WHERE cantidad IS NULL OR precio_unidad IS NULL;
SELECT * FROM pedido_staging WHERE fecha_pedido IS NULL;

-- REVISAR CAMPOS OBLIGATORIOS
SELECT * FROM producto_staging WHERE nombre IS NULL OR Categoria IS NULL;


-- REGEX PARA VALIDAR FORMATOS
SELECT * FROM producto_staging WHERE precio_unidad NOT REGEXP '^[0-9]+(\.[0-9]{1,2})?$';
-- O, si quieres validar cantidad en stock:
SELECT * FROM producto_staging WHERE Categoria NOT REGEXP '^[0-9]+$';

-- DETECCIÓN DE DUPLICADOS
SELECT ID_producto, COUNT(*) AS repeticiones
FROM producto_staging
GROUP BY ID_producto
HAVING COUNT(*) > 1;

-- CONSULTAS PARA TABLAS DE STAGING 

SELECT * FROM pedido_staging WHERE ID_pedido = 1;
SELECT * FROM pedido_staging WHERE ID_pedido = 112;


-- Consulta de productos por ID
SELECT ID_producto FROM producto
WHERE ID_producto IN (1, 2, 3, 4, 5); 

-- Verificar existencia de producto
SELECT * FROM producto WHERE ID_producto = 1; 

-- Consulta de categoría de producto
SELECT Id_Categoria, Desc_Categoria FROM Categoria_producto;

-- No existe el campo 'Nombre_Categoria', usar 'Desc_Categoria'
SELECT Id_Categoria FROM Categoria_producto WHERE Desc_Categoria = 'Herramientas';

-- Insertar categorías 
INSERT INTO categoria_producto_staging (Id_Categoria, Desc_Categoria, fecha_ingreso) VALUES
(1, 'Herbaceas', NOW()),
(2, 'Herramientas', NOW()),
(3, 'Aromáticas', NOW()),
(4, 'Frutales', NOW()),
(5, 'Ornamentales', NOW());


-- Insertar detalle de pedido
INSERT INTO detalle_pedido (ID_pedido, ID_producto, cantidad, precio_unidad, numero_linea)
VALUES (1, 1, 10, 70.00, 1);

-- Verificar estado de las tablas 
SHOW TABLE STATUS WHERE Name IN ('producto', 'pedido', 'detalle_pedido', 'Categoria_producto');

-- Verificar existencia de pedido
SELECT * FROM pedido WHERE ID_pedido = 1;




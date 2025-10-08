-- ===================================================================
-- BASE DE DATOS: DataMart_Jardineria_EA1
-- TIPO: Data Mart Independiente (OLTP)
-- DESARROLLADO POR: Selénis Lorena Ramos, Lady Laura Olmos, Jorge Andrés Hernández Campos
-- PROPÓSITO: Análisis de ventas mediante modelo estrella
-- ===================================================================
DROP DATABASE IF EXISTS datamart_jardineria;
CREATE DATABASE datamart_jardineria CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE datamart_jardineria;


-- DIMENSIÓN TIEMPO
CREATE TABLE dim_tiempo (
  ID_tiempo INT PRIMARY KEY, -- Formato AAAAMMDD
  fecha DATE NOT NULL,
  año INT NOT NULL,
  mes INT NOT NULL,
  nombre_mes VARCHAR(10) NOT NULL,
  trimestre INT NOT NULL,
  dia_semana INT NOT NULL,
  nombre_dia VARCHAR(10) NOT NULL
) ENGINE=InnoDB;

-- DIMENSIÓN PRODUCTO
CREATE TABLE dim_producto (
  ID_producto INT PRIMARY KEY,
  CodigoProducto VARCHAR(15) NOT NULL,
  nombre VARCHAR(70) NOT NULL,
  proveedor VARCHAR(50),
  dimensiones VARCHAR(50),
  Categoria INT NOT NULL -- ← Añadido: es esencial para el modelo estrella
) ENGINE=InnoDB;

-- DIMENSIÓN CATEGORÍA
CREATE TABLE dim_categoria (
  ID_categoria INT PRIMARY KEY,
  Desc_Categoria VARCHAR(50) NOT NULL
) ENGINE=InnoDB;

-- DIMENSIÓN CLIENTE
CREATE TABLE dim_cliente (
  ID_cliente INT PRIMARY KEY,
  nombre_cliente VARCHAR(50) NOT NULL,
  ciudad VARCHAR(50) NOT NULL,
  region VARCHAR(50),
  pais VARCHAR(50),
  limite_credito DECIMAL(15,2)
) ENGINE=InnoDB;

-- DIMENSIÓN EMPLEADO
CREATE TABLE dim_empleado (
  ID_empleado INT PRIMARY KEY,
  nombre VARCHAR(50) NOT NULL,
  apellido1 VARCHAR(50) NOT NULL,
  apellido2 VARCHAR(50),
  puesto VARCHAR(50),
  ID_oficina INT,
  nombre_oficina VARCHAR(50),
  ciudad_oficina VARCHAR(30),
  pais_oficina VARCHAR(50)
) ENGINE=InnoDB;

-- TABLA DE HECHOS: VENTAS
CREATE TABLE hecho_venta (
  ID_hecho INT AUTO_INCREMENT PRIMARY KEY,
  ID_pedido INT NOT NULL,
  ID_producto INT NOT NULL,
  ID_cliente INT NOT NULL,
  ID_empleado INT NOT NULL,
  ID_categoria INT NOT NULL,
  ID_tiempo INT NOT NULL,
  cantidad INT NOT NULL,
  precio_unitario DECIMAL(15,2) NOT NULL,
  total_venta DECIMAL(15,2) AS (cantidad * precio_unitario) STORED,
  FOREIGN KEY (ID_producto) REFERENCES dim_producto (ID_producto),
  FOREIGN KEY (ID_categoria) REFERENCES dim_categoria (ID_categoria),
  FOREIGN KEY (ID_cliente) REFERENCES dim_cliente (ID_cliente),
  FOREIGN KEY (ID_empleado) REFERENCES dim_empleado (ID_empleado),
  FOREIGN KEY (ID_tiempo) REFERENCES dim_tiempo (ID_tiempo)
) ENGINE=InnoDB;

-- Índices
CREATE INDEX idx_hecho_producto ON hecho_venta (ID_producto);
CREATE INDEX idx_hecho_categoria ON hecho_venta (ID_categoria);
CREATE INDEX idx_hecho_cliente ON hecho_venta (ID_cliente);
CREATE INDEX idx_hecho_empleado ON hecho_venta (ID_empleado);
CREATE INDEX idx_hecho_tiempo ON hecho_venta (ID_tiempo);
CREATE FULLTEXT INDEX idx_producto_nombre ON dim_producto (nombre);
CREATE FULLTEXT INDEX idx_cliente_nombre ON dim_cliente (nombre_cliente);
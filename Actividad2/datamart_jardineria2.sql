-- ===========================================
-- CREACIÓN DE DATA MART JARDINERÍA (CORREGIDO)
-- ===========================================

CREATE DATABASE IF NOT EXISTS datamart_jardineria2
CHARACTER SET utf8mb4
COLLATE utf8mb4_unicode_ci;

USE datamart_jardineria2;

-- 1. Tablas de Dimensión
CREATE TABLE IF NOT EXISTS dim_producto (
    sk_producto INT AUTO_INCREMENT PRIMARY KEY,
    id_producto INT NOT NULL,
    codigo_producto VARCHAR(50),
    nombre_producto VARCHAR(200),
    gama VARCHAR(100),
    categoria VARCHAR(100),
    proveedor VARCHAR(100),
    precio_venta DECIMAL(10,2),
    precio_costo DECIMAL(10,2),
    margen_ganancia DECIMAL(10,2),
    estado_stock VARCHAR(50),
    cantidad_stock INT,
    fecha_inicio DATE,
    fecha_fin DATE,
    es_actual BOOLEAN DEFAULT TRUE,
    UNIQUE KEY uk_producto (id_producto, es_actual)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS dim_cliente (
    sk_cliente INT AUTO_INCREMENT PRIMARY KEY,
    id_cliente INT NOT NULL,
    codigo_cliente VARCHAR(50),
    nombre_cliente VARCHAR(100),
    nombre_completo_contacto VARCHAR(200),
    telefono VARCHAR(20),
    ciudad VARCHAR(100),
    region VARCHAR(100),
    pais VARCHAR(100),
    segmento_cliente VARCHAR(50),
    limite_credito DECIMAL(10,2),
    fecha_inicio DATE,
    fecha_fin DATE,
    es_actual BOOLEAN DEFAULT TRUE,
    UNIQUE KEY uk_cliente (id_cliente, es_actual)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS dim_tiempo (
    sk_tiempo INT AUTO_INCREMENT PRIMARY KEY,
    fecha DATE NOT NULL UNIQUE,
    anio INT,
    trimestre INT,
    mes INT,
    nombre_mes VARCHAR(20),
    semana INT,
    dia INT,
    dia_semana INT,
    nombre_dia VARCHAR(20),
    es_fin_semana BOOLEAN,
    es_festivo BOOLEAN DEFAULT FALSE,
    descripcion_festivo VARCHAR(100)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS dim_empleado (
    sk_empleado INT AUTO_INCREMENT PRIMARY KEY,
    id_empleado INT NOT NULL,
    codigo_empleado VARCHAR(50),
    nombre_completo VARCHAR(200),
    puesto VARCHAR(100),
    email VARCHAR(100),
    id_jefe INT,
    nombre_jefe VARCHAR(200),
    fecha_inicio DATE,
    fecha_fin DATE,
    es_actual BOOLEAN DEFAULT TRUE,
    UNIQUE KEY uk_empleado (id_empleado, es_actual)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS dim_oficina (
    sk_oficina INT AUTO_INCREMENT PRIMARY KEY,
    id_oficina INT NOT NULL,
    codigo_oficina VARCHAR(50),
    ciudad VARCHAR(100),
    pais VARCHAR(100),
    region VARCHAR(100),
    telefono VARCHAR(20),
    direccion_completa VARCHAR(400),
    fecha_inicio DATE,
    fecha_fin DATE,
    es_actual BOOLEAN DEFAULT TRUE,
    UNIQUE KEY uk_oficina (id_oficina, es_actual)
) ENGINE=InnoDB;

-- 2. Tabla de Hechos (después de las dimensiones)
CREATE TABLE IF NOT EXISTS hechos_ventas (
    sk_venta BIGINT AUTO_INCREMENT PRIMARY KEY,
    sk_producto INT NOT NULL,
    sk_cliente INT NOT NULL,
    sk_tiempo INT NOT NULL,
    sk_empleado INT NOT NULL,
    sk_oficina INT NOT NULL,
    id_pedido INT,
    numero_linea INT,
    cantidad_vendida INT,
    precio_unitario DECIMAL(10,2),
    precio_costo DECIMAL(10,2),
    monto_venta DECIMAL(12,2),
    costo_total DECIMAL(12,2),
    ganancia_bruta DECIMAL(12,2),
    margen_porcentaje DECIMAL(5,2),
    descuento DECIMAL(10,2) DEFAULT 0,
    dias_retraso INT,
    estado_entrega VARCHAR(50),
    fecha_carga TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_tiempo (sk_tiempo),
    INDEX idx_producto (sk_producto),
    INDEX idx_cliente (sk_cliente),
    INDEX idx_fecha_carga (fecha_carga),
    CONSTRAINT fk_hechos_producto FOREIGN KEY (sk_producto) REFERENCES dim_producto(sk_producto),
    CONSTRAINT fk_hechos_cliente FOREIGN KEY (sk_cliente) REFERENCES dim_cliente(sk_cliente),
    CONSTRAINT fk_hechos_tiempo FOREIGN KEY (sk_tiempo) REFERENCES dim_tiempo(sk_tiempo),
    CONSTRAINT fk_hechos_empleado FOREIGN KEY (sk_empleado) REFERENCES dim_empleado(sk_empleado),
    CONSTRAINT fk_hechos_oficina FOREIGN KEY (sk_oficina) REFERENCES dim_oficina(sk_oficina)
) ENGINE=InnoDB;

-- 6. TABLAS DE CONTROL Y AUDITORÍA
CREATE TABLE IF NOT EXISTS control_etl (
    id_ejecucion INT AUTO_INCREMENT PRIMARY KEY,
    nombre_proceso VARCHAR(100),
    fase VARCHAR(50),
    fecha_inicio TIMESTAMP,
    fecha_fin TIMESTAMP,
    estado VARCHAR(50),
    registros_procesados INT,
    registros_exitosos INT,
    registros_error INT,
    mensaje_error TEXT,
    duracion_segundos INT
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS errores_etl (
    id_error INT AUTO_INCREMENT PRIMARY KEY,
    id_ejecucion INT,
    fase VARCHAR(50),
    tabla_origen VARCHAR(100),
    tabla_destino VARCHAR(100),
    registro_id VARCHAR(100),
    tipo_error VARCHAR(100),
    descripcion_error TEXT,
    fecha_error TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (id_ejecucion) REFERENCES control_etl(id_ejecucion)
) ENGINE=InnoDB;

-- =====================================================
-- VERIFICACIÓN DE CREACIÓN
SELECT 'STAGING TABLES' AS verificacion;
SHOW TABLES FROM staging_jardineria2;

SELECT 'DATA MART TABLES' AS verificacion;
SHOW TABLES FROM datamart_jardineria2;

USE datamart_jardineria2;

CREATE TABLE IF NOT EXISTS control_etl (
    id_ejecucion INT AUTO_INCREMENT PRIMARY KEY,
    nombre_proceso VARCHAR(100),
    fase VARCHAR(50), -- 'EXTRACCION', 'TRANSFORMACION', 'CARGA'
    fecha_inicio TIMESTAMP,
    fecha_fin TIMESTAMP,
    estado VARCHAR(50), -- 'EXITOSO', 'FALLIDO', 'EN_PROCESO'
    registros_procesados INT,
    registros_exitosos INT,
    registros_error INT,
    mensaje_error TEXT,
    duracion_segundos INT
) ENGINE=InnoDB;

DELIMITER $$

DELIMITER $$



DROP PROCEDURE IF EXISTS sp_cargar_dim_producto;
DELIMITER $$

CREATE PROCEDURE sp_cargar_dim_producto()
BEGIN
    DECLARE v_id_ejecucion INT;
    DECLARE v_registros INT;
    DECLARE v_col_exists INT DEFAULT 0;

    INSERT INTO control_etl (nombre_proceso, fase, fecha_inicio, estado)
    VALUES ('CARGA_DIM_PRODUCTO', 'CARGA', NOW(), 'EN_PROCESO');
    SET v_id_ejecucion = LAST_INSERT_ID();

    -- Verificar si la columna categoria_precio existe en staging_jardineria.stg_producto
    SELECT COUNT(*) INTO v_col_exists
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'staging_jardineria'
      AND TABLE_NAME = 'stg_producto'
      AND COLUMN_NAME = 'categoria_precio';

    IF v_col_exists = 0 THEN
        SET @sql := 'ALTER TABLE staging_jardineria.stg_producto ADD COLUMN categoria_precio VARCHAR(50)';
        PREPARE stmt FROM @sql;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;
    END IF;

    SET SQL_SAFE_UPDATES = 0;

    -- Calcular y actualizar valores de categoria_precio antes de la carga
    UPDATE staging_jardineria.stg_producto
    SET categoria_precio = CASE 
        WHEN precio_venta < 10 THEN 'Económico'
        WHEN precio_venta >= 10 AND precio_venta < 50 THEN 'Medio'
        WHEN precio_venta >= 50 AND precio_venta < 100 THEN 'Premium'
        ELSE 'Lujo'
    END
    WHERE id_producto IS NOT NULL;

    -- Insertar productos nuevos o actualizar existentes
    INSERT INTO dim_producto (
        id_producto, codigo_producto, nombre_producto, gama, categoria,
        proveedor, precio_venta, precio_costo,
        cantidad_stock, fecha_inicio, es_actual
    )
    SELECT 
        p.id_producto,
        p.codigo_producto,
        p.nombre,
        p.gama,
        p.categoria_precio,
        p.proveedor,
        p.precio_venta,
        p.precio_proveedor,
        p.cantidad_stock,
        CURDATE(),
        TRUE
    FROM staging_jardineria.stg_producto p
    ON DUPLICATE KEY UPDATE
        nombre_producto = VALUES(nombre_producto),
        precio_venta = VALUES(precio_venta),
        precio_costo = VALUES(precio_costo),
        cantidad_stock = VALUES(cantidad_stock);

    SET v_registros = ROW_COUNT();

    UPDATE control_etl
    SET estado = 'EXITOSO', fecha_fin = NOW(),
        registros_procesados = v_registros,
        duracion_segundos = TIMESTAMPDIFF(SECOND, fecha_inicio, NOW())
    WHERE id_ejecucion = v_id_ejecucion;

    SELECT CONCAT('Dimensión Producto cargada: ', v_registros, ' registros') AS resultado;
END$$

DELIMITER ;


-- ==============================================================
-- CONSULTAS ANALÍTICAS AVANZADAS - DATA MART JARDINERÍA
-- ==============================================================
-- Autor: Sistema Analítico Jardinería
-- Fecha: 30 Septiembre 2025
-- Objetivo: Proporcionar insights profundos para toma de decisiones
-- ==============================================================

USE datamart_jardineria;

-- ==============================================================
-- SECCIÓN 1: ANÁLISIS DE PRODUCTOS
-- ==============================================================

-- 1.1 TOP 10 PRODUCTOS MÁS RENTABLES
-- Identifica productos con mejor margen de ganancia
SELECT 
    '1.1 TOP 10 PRODUCTOS MÁS RENTABLES' AS analisis;

SELECT 
    p.codigo_producto,
    p.nombre_producto,
    c.descripcion_categoria,
    SUM(f.cantidad) AS unidades_vendidas,
    CONCAT('€', FORMAT(SUM(f.importe), 2)) AS ingresos_totales,
    CONCAT('€', FORMAT(SUM(f.margen_bruto), 2)) AS ganancia_total,
    CONCAT(FORMAT((SUM(f.margen_bruto) / NULLIF(SUM(f.importe), 0)) * 100, 2), '%') AS porcentaje_margen,
    CONCAT('€', FORMAT(AVG(f.margen_bruto), 2)) AS margen_promedio_venta
FROM fact_ventas f
JOIN dim_producto p ON f.product_id = p.product_id
JOIN dim_categoria_producto c ON f.category_id = c.category_id
GROUP BY p.product_id, p.codigo_producto, p.nombre_producto, c.descripcion_categoria
ORDER BY SUM(f.margen_bruto) DESC
LIMIT 10;

-- 1.2 PRODUCTOS CON BAJO RENDIMIENTO
-- Productos que generan pocas ventas o bajo margen
SELECT 
    '1.2 PRODUCTOS CON BAJO RENDIMIENTO' AS analisis;

SELECT 
    p.codigo_producto,
    p.nombre_producto,
    c.descripcion_categoria,
    COALESCE(SUM(f.cantidad), 0) AS unidades_vendidas,
    CONCAT('€', FORMAT(COALESCE(SUM(f.importe), 0), 2)) AS ventas_totales,
    CONCAT('€', FORMAT(p.precio_venta, 2)) AS precio_actual,
    CASE 
        WHEN SUM(f.cantidad) IS NULL THEN 'Sin ventas'
        WHEN SUM(f.cantidad) < 5 THEN 'Ventas muy bajas'
        WHEN SUM(f.margen_bruto) < 20 THEN 'Margen bajo'
        ELSE 'Rendimiento aceptable'
    END AS estado
FROM dim_producto p
JOIN dim_categoria_producto c ON p.category_id = c.category_id
LEFT JOIN fact_ventas f ON p.product_id = f.product_id
GROUP BY p.product_id, p.codigo_producto, p.nombre_producto, 
         c.descripcion_categoria, p.precio_venta
HAVING COALESCE(SUM(f.cantidad), 0) < 8
ORDER BY unidades_vendidas ASC;

-- 1.3 ANÁLISIS DE PRECIO VS VOLUMEN
-- Relación entre precio de venta y cantidad vendida
SELECT 
    '1.3 ANÁLISIS PRECIO VS VOLUMEN' AS analisis;

SELECT 
    CASE 
        WHEN p.precio_venta < 10 THEN '€0-€10 (Bajo)'
        WHEN p.precio_venta BETWEEN 10 AND 30 THEN '€10-€30 (Medio)'
        WHEN p.precio_venta BETWEEN 30 AND 60 THEN '€30-€60 (Alto)'
        ELSE '€60+ (Premium)'
    END AS rango_precio,
    COUNT(DISTINCT p.product_id) AS productos_en_rango,
    SUM(f.cantidad) AS unidades_vendidas,
    CONCAT('€', FORMAT(AVG(f.precio_unitario), 2)) AS precio_promedio,
    CONCAT('€', FORMAT(SUM(f.importe), 2)) AS ventas_totales,
    ROUND(SUM(f.cantidad) / COUNT(DISTINCT p.product_id), 2) AS unidades_por_producto
FROM fact_ventas f
JOIN dim_producto p ON f.product_id = p.product_id
GROUP BY rango_precio
ORDER BY AVG(f.precio_unitario);

-- 1.4 ANÁLISIS ABC DE PRODUCTOS (Pareto)
-- Clasificación de productos por contribución a ventas
SELECT 
    '1.4 ANÁLISIS ABC DE PRODUCTOS' AS analisis;

WITH ventas_producto AS (
    SELECT 
        p.product_id,
        p.codigo_producto,
        p.nombre_producto,
        SUM(f.importe) AS ventas,
        SUM(SUM(f.importe)) OVER () AS ventas_totales
    FROM fact_ventas f
    JOIN dim_producto p ON f.product_id = p.product_id
    GROUP BY p.product_id, p.codigo_producto, p.nombre_producto
),
ventas_acumuladas AS (
    SELECT 
        *,
        SUM(ventas) OVER (ORDER BY ventas DESC) AS ventas_acum,
        (SUM(ventas) OVER (ORDER BY ventas DESC) / ventas_totales) * 100 AS porcentaje_acum
    FROM ventas_producto
)
SELECT 
    codigo_producto,
    nombre_producto,
    CONCAT('€', FORMAT(ventas, 2)) AS ventas,
    CONCAT(FORMAT(porcentaje_acum, 2), '%') AS porcentaje_acumulado,
    CASE 
        WHEN porcentaje_acum <= 80 THEN 'A (Alto valor)'
        WHEN porcentaje_acum <= 95 THEN 'B (Valor medio)'
        ELSE 'C (Bajo valor)'
    END AS clasificacion_abc
FROM ventas_acumuladas
ORDER BY ventas DESC;

-- ==============================================================
-- SECCIÓN 2: ANÁLISIS DE CLIENTES
-- ==============================================================

-- 2.1 SEGMENTACIÓN RFM (Recency, Frequency, Monetary)
-- Segmentación avanzada de clientes
SELECT 
    '2.1 SEGMENTACIÓN RFM DE CLIENTES' AS analisis;

WITH rfm_base AS (
    SELECT 
        cl.customer_id,
        cl.nombre_cliente,
        DATEDIFF(CURDATE(), MAX(t.fecha)) AS recency_dias,
        COUNT(DISTINCT f.order_id) AS frequency_pedidos,
        SUM(f.importe) AS monetary_total
    FROM fact_ventas f
    JOIN dim_cliente cl ON f.customer_id = cl.customer_id
    JOIN dim_tiempo t ON f.time_id = t.time_id
    GROUP BY cl.customer_id, cl.nombre_cliente
),
rfm_scores AS (
    SELECT 
        *,
        NTILE(5) OVER (ORDER BY recency_dias) AS r_score,
        NTILE(5) OVER (ORDER BY frequency_pedidos DESC) AS f_score,
        NTILE(5) OVER (ORDER BY monetary_total DESC) AS m_score
    FROM rfm_base
)
SELECT 
    nombre_cliente,
    recency_dias AS dias_ultima_compra,
    frequency_pedidos AS total_pedidos,
    CONCAT('€', FORMAT(monetary_total, 2)) AS gasto_total,
    CONCAT(r_score, f_score, m_score) AS rfm_score,
    CASE 
        WHEN r_score >= 4 AND f_score >= 4 AND m_score >= 4 THEN 'Champions'
        WHEN r_score >= 3 AND f_score >= 3 AND m_score >= 3 THEN 'Leales'
        WHEN r_score >= 4 AND f_score <= 2 THEN 'Nuevos Prometedores'
        WHEN r_score <= 2 AND f_score >= 3 AND m_score >= 3 THEN 'En Riesgo'
        WHEN r_score <= 2 AND f_score <= 2 THEN 'Perdidos'
        ELSE 'Requiere Atención'
    END AS segmento_cliente
FROM rfm_scores
ORDER BY monetary_total DESC;

-- 2.2 ANÁLISIS DE VALOR DE VIDA DEL CLIENTE (CLV)
-- Estimación del valor futuro de clientes
SELECT 
    '2.2 CUSTOMER LIFETIME VALUE (CLV)' AS analisis;

SELECT 
    cl.nombre_cliente,
    cl.ciudad,
    cl.pais,
    COUNT(DISTINCT f.order_id) AS total_pedidos,
    CONCAT('€', FORMAT(SUM(f.importe), 2)) AS ventas_historicas,
    CONCAT('€', FORMAT(AVG(f.importe), 2)) AS ticket_promedio,
    CONCAT('€', FORMAT(SUM(f.importe) / COUNT(DISTINCT f.order_id), 2)) AS valor_pedido_promedio,
    -- CLV simplificado: ventas_historicas * 1.5 (factor de proyección)
    CONCAT('€', FORMAT(SUM(f.importe) * 1.5, 2)) AS clv_estimado,
    CASE 
        WHEN SUM(f.importe) > 300 THEN 'VIP'
        WHEN SUM(f.importe) > 200 THEN 'Premium'
        WHEN SUM(f.importe) > 100 THEN 'Regular'
        ELSE 'Básico'
    END AS nivel_cliente
FROM fact_ventas f
JOIN dim_cliente cl ON f.customer_id = cl.customer_id
GROUP BY cl.customer_id, cl.nombre_cliente, cl.ciudad, cl.pais
ORDER BY SUM(f.importe) DESC;

-- 2.3 ANÁLISIS GEOGRÁFICO DE CLIENTES
-- Distribución y rendimiento por ubicación
SELECT 
    '2.3 ANÁLISIS GEOGRÁFICO' AS analisis;

SELECT 
    cl.region,
    cl.pais,
    COUNT(DISTINCT cl.customer_id) AS total_clientes,
    COUNT(DISTINCT f.order_id) AS total_pedidos,
    SUM(f.cantidad) AS unidades_vendidas,
    CONCAT('€', FORMAT(SUM(f.importe), 2)) AS ventas_totales,
    CONCAT('€', FORMAT(AVG(f.importe), 2)) AS ticket_promedio,
    CONCAT('€', FORMAT(SUM(f.importe) / COUNT(DISTINCT cl.customer_id), 2)) AS ventas_por_cliente,
    ROUND(COUNT(DISTINCT f.order_id) / COUNT(DISTINCT cl.customer_id), 2) AS pedidos_por_cliente
FROM fact_ventas f
JOIN dim_cliente cl ON f.customer_id = cl.customer_id
GROUP BY cl.region, cl.pais
ORDER BY SUM(f.importe) DESC;

-- 2.4 MATRIZ DE CLIENTES (Frecuencia vs Monetario)
-- Identificar tipos de compradores
SELECT 
    '2.4 MATRIZ FRECUENCIA VS VALOR' AS analisis;

SELECT 
    cl.nombre_cliente,
    COUNT(DISTINCT f.order_id) AS frecuencia_compra,
    CONCAT('€', FORMAT(SUM(f.importe), 2)) AS valor_total,
    CASE 
        WHEN COUNT(DISTINCT f.order_id) >= 2 AND SUM(f.importe) >= 250 
            THEN 'Alta Frecuencia - Alto Valor'
        WHEN COUNT(DISTINCT f.order_id) >= 2 AND SUM(f.importe) < 250 
            THEN 'Alta Frecuencia - Bajo Valor'
        WHEN COUNT(DISTINCT f.order_id) = 1 AND SUM(f.importe) >= 250 
            THEN 'Baja Frecuencia - Alto Valor'
        ELSE 'Baja Frecuencia - Bajo Valor'
    END AS tipo_cliente,
    CASE 
        WHEN COUNT(DISTINCT f.order_id) >= 2 AND SUM(f.importe) >= 250 
            THEN 'Mantener y premiar fidelidad'
        WHEN COUNT(DISTINCT f.order_id) >= 2 AND SUM(f.importe) < 250 
            THEN 'Incrementar ticket promedio'
        WHEN COUNT(DISTINCT f.order_id) = 1 AND SUM(f.importe) >= 250 
            THEN 'Incentivar recompra'
        ELSE 'Activar con promociones'
    END AS estrategia_recomendada
FROM fact_ventas f
JOIN dim_cliente cl ON f.customer_id = cl.customer_id
GROUP BY cl.customer_id, cl.nombre_cliente
ORDER BY SUM(f.importe) DESC;

-- ==============================================================
-- SECCIÓN 3: ANÁLISIS TEMPORAL Y TENDENCIAS
-- ==============================================================

-- 3.1 ANÁLISIS DE ESTACIONALIDAD POR DÍA DE SEMANA
-- Identificar días con mayor actividad
SELECT 
    '3.1 ESTACIONALIDAD POR DÍA DE SEMANA' AS analisis;

SELECT 
    t.nombre_dia,
    t.dia_semana,
    COUNT(DISTINCT f.order_id) AS total_pedidos,
    SUM(f.cantidad) AS unidades_vendidas,
    CONCAT('€', FORMAT(SUM(f.importe), 2)) AS ventas_totales,
    CONCAT('€', FORMAT(AVG(f.importe), 2)) AS ticket_promedio,
    CASE 
        WHEN t.dia_semana IN (1, 7) THEN 'Fin de Semana'
        ELSE 'Entre Semana'
    END AS tipo_dia
FROM fact_ventas f
JOIN dim_tiempo t ON f.time_id = t.time_id
GROUP BY t.nombre_dia, t.dia_semana
ORDER BY t.dia_semana;

-- 3.2 ANÁLISIS DE TENDENCIA MENSUAL
-- Evolución de ventas mes a mes
SELECT 
    '3.2 TENDENCIA MENSUAL DE VENTAS' AS analisis;

SELECT 
    t.anio,
    t.mes,
    t.nombre_mes,
    COUNT(DISTINCT f.order_id) AS pedidos,
    SUM(f.cantidad) AS unidades,
    CONCAT('€', FORMAT(SUM(f.importe), 2)) AS ventas,
    CONCAT('€', FORMAT(AVG(f.importe), 2)) AS ticket_promedio,
    -- Cálculo de variación (simplificado sin LAG para compatibilidad)
    CONCAT('€', FORMAT(SUM(f.importe) - 
        (SELECT AVG(ventas_mes) 
         FROM (SELECT SUM(f2.importe) AS ventas_mes 
               FROM fact_ventas f2 
               JOIN dim_tiempo t2 ON f2.time_id = t2.time_id 
               GROUP BY t2.mes) AS subq), 2)) AS variacion_vs_promedio
FROM fact_ventas f
JOIN dim_tiempo t ON f.time_id = t.time_id
GROUP BY t.anio, t.mes, t.nombre_mes
ORDER BY t.anio, t.mes;

-- 3.3 ANÁLISIS DE TRIMESTRE
-- Comparación de rendimiento trimestral
SELECT 
    '3.3 ANÁLISIS TRIMESTRAL' AS analisis;

SELECT 
    t.anio,
    CONCAT('Q', t.trimestre) AS trimestre,
    COUNT(DISTINCT f.order_id) AS total_pedidos,
    COUNT(DISTINCT f.customer_id) AS clientes_activos,
    SUM(f.cantidad) AS unidades_vendidas,
    CONCAT('€', FORMAT(SUM(f.importe), 2)) AS ventas_totales,
    CONCAT('€', FORMAT(SUM(f.margen_bruto), 2)) AS margen_total,
    CONCAT(FORMAT((SUM(f.margen_bruto) / NULLIF(SUM(f.importe), 0)) * 100, 2), '%') AS porcentaje_margen
FROM fact_ventas f
JOIN dim_tiempo t ON f.time_id = t.time_id
GROUP BY t.anio, t.trimestre
ORDER BY t.anio, t.trimestre;

-- 3.4 IDENTIFICACIÓN DE PICOS DE VENTA
-- Fechas con mayor actividad
SELECT 
    '3.4 PICOS DE VENTA' AS analisis;

SELECT 
    t.fecha,
    t.nombre_dia,
    t.nombre_mes,
    COUNT(DISTINCT f.order_id) AS pedidos_dia,
    SUM(f.cantidad) AS unidades_vendidas,
    CONCAT('€', FORMAT(SUM(f.importe), 2)) AS ventas_dia,
    CASE 
        WHEN SUM(f.importe) > (SELECT AVG(ventas_diarias) * 1.5
                               FROM (SELECT SUM(f2.importe) AS ventas_diarias
                                     FROM fact_ventas f2
                                     GROUP BY f2.time_id) AS subq)
            THEN 'Pico Alto'
        WHEN SUM(f.importe) > (SELECT AVG(ventas_diarias)
                               FROM (SELECT SUM(f2.importe) AS ventas_diarias
                                     FROM fact_ventas f2
                                     GROUP BY f2.time_id) AS subq)
            THEN 'Por encima del promedio'
        ELSE 'Normal'
    END AS tipo_actividad
FROM fact_ventas f
JOIN dim_tiempo t ON f.time_id = t.time_id
GROUP BY t.fecha, t.nombre_dia, t.nombre_mes, t.time_id
ORDER BY SUM(f.importe) DESC
LIMIT 10;

-- ==============================================================
-- SECCIÓN 4: ANÁLISIS DE CATEGORÍAS
-- ==============================================================

-- 4.1 MATRIZ DE CRECIMIENTO DE CATEGORÍAS
-- BCG Matrix adaptado (Estrellas, Vacas, Interrogantes, Perros)
SELECT 
    '4.1 MATRIZ BCG DE CATEGORÍAS' AS analisis;

WITH categoria_metricas AS (
    SELECT 
        c.category_id,
        c.descripcion_categoria,
        SUM(f.importe) AS ventas,
        SUM(f.margen_bruto) AS margen,
        SUM(f.cantidad) AS volumen,
        (SUM(f.margen_bruto) / NULLIF(SUM(f.importe), 0)) * 100 AS porcentaje_margen,
        COUNT(DISTINCT f.product_id) AS productos_activos
    FROM fact_ventas f
    JOIN dim_categoria_producto c ON f.category_id = c.category_id
    GROUP BY c.category_id, c.descripcion_categoria
),
promedios AS (
    SELECT 
        AVG(ventas) AS ventas_promedio,
        AVG(porcentaje_margen) AS margen_promedio
    FROM categoria_metricas
)
SELECT 
    cm.descripcion_categoria,
    CONCAT('€', FORMAT(cm.ventas, 2)) AS ventas_totales,
    CONCAT(FORMAT(cm.porcentaje_margen, 2), '%') AS margen_porcentaje,
    cm.productos_activos,
    CASE 
        WHEN cm.ventas > p.ventas_promedio AND cm.porcentaje_margen > p.margen_promedio 
            THEN 'Estrella (Invertir)'
        WHEN cm.ventas > p.ventas_promedio AND cm.porcentaje_margen <= p.margen_promedio 
            THEN 'Vaca (Mantener)'
        WHEN cm.ventas <= p.ventas_promedio AND cm.porcentaje_margen > p.margen_promedio 
            THEN 'Interrogante (Evaluar)'
        ELSE 'Perro (Descontinuar o renovar)'
    END AS clasificacion_bcg,
    CASE 
        WHEN cm.ventas > p.ventas_promedio AND cm.porcentaje_margen > p.margen_promedio 
            THEN 'Ampliar catálogo y marketing agresivo'
        WHEN cm.ventas > p.ventas_promedio AND cm.porcentaje_margen <= p.margen_promedio 
            THEN 'Optimizar márgenes manteniendo volumen'
        WHEN cm.ventas <= p.ventas_promedio AND cm.porcentaje_margen > p.margen_promedio 
            THEN 'Incrementar visibilidad y promoción'
        ELSE 'Revisar estrategia o eliminar'
    END AS recomendacion
FROM categoria_metricas cm
CROSS JOIN promedios p
ORDER BY cm.ventas DESC;

-- 4.2 ANÁLISIS DE CONCENTRACIÓN DE VENTAS POR CATEGORÍA
-- Índice de Herfindahl-Hirschman simplificado
SELECT 
    '4.2 CONCENTRACIÓN DE VENTAS' AS analisis;

WITH ventas_categoria AS (
    SELECT 
        c.descripcion_categoria,
        SUM(f.importe) AS ventas,
        (SUM(f.importe) / (SELECT SUM(importe) FROM fact_ventas)) * 100 AS participacion
    FROM fact_ventas f
    JOIN dim_categoria_producto c ON f.category_id = c.category_id
    GROUP BY c.category_id, c.descripcion_categoria
)
SELECT 
    descripcion_categoria,
    CONCAT('€', FORMAT(ventas, 2)) AS ventas,
    CONCAT(FORMAT(participacion, 2), '%') AS participacion_mercado,
    SUM(participacion) OVER (ORDER BY participacion DESC) AS participacion_acumulada,
    CASE 
        WHEN participacion >= 20 THEN 'Categoría Dominante'
        WHEN participacion >= 10 THEN 'Categoría Importante'
        WHEN participacion >= 5 THEN 'Categoría Secundaria'
        ELSE 'Categoría Marginal'
    END AS importancia
FROM ventas_categoria
ORDER BY participacion DESC;

-- 4.3 CROSS-SELLING: CATEGORÍAS COMPRADAS JUNTAS
-- Análisis de afinidad entre categorías
SELECT 
    '4.3 ANÁLISIS DE CROSS-SELLING' AS analisis;

SELECT 
    c1.descripcion_categoria AS categoria_principal,
    c2.descripcion_categoria AS categoria_complementaria,
    COUNT(DISTINCT f1.order_id) AS pedidos_combinados,
    CONCAT('€', FORMAT(SUM(f1.importe + f2.importe), 2)) AS valor_combinado,
    CONCAT(FORMAT(
        (COUNT(DISTINCT f1.order_id) * 100.0 / 
         (SELECT COUNT(DISTINCT order_id) FROM fact_ventas)), 2), '%'
    ) AS frecuencia_combinacion
FROM fact_ventas f1
JOIN fact_ventas f2 ON f1.order_id = f2.order_id AND f1.category_id < f2.category_id
JOIN dim_categoria_producto c1 ON f1.category_id = c1.category_id
JOIN dim_categoria_producto c2 ON f2.category_id = c2.category_id
GROUP BY c1.category_id, c1.descripcion_categoria, c2.category_id, c2.descripcion_categoria
HAVING COUNT(DISTINCT f1.order_id) >= 1
ORDER BY pedidos_combinados DESC
LIMIT 10;

-- ==============================================================
-- SECCIÓN 5: ANÁLISIS DE PEDIDOS Y LOGÍSTICA
-- ==============================================================

-- 5.1 ANÁLISIS DE EFICIENCIA DE ENTREGAS
-- KPIs de desempeño logístico
SELECT 
    '5.1 EFICIENCIA DE ENTREGAS' AS analisis;

SELECT 
    o.estado_pedido,
    COUNT(DISTINCT o.order_id) AS total_pedidos,
    COUNT(DISTINCT CASE WHEN o.fecha_entrega IS NOT NULL THEN o.order_id END) AS pedidos_entregados,
    CONCAT(FORMAT(
        (COUNT(DISTINCT CASE WHEN o.fecha_entrega IS NOT NULL THEN o.order_id END) * 100.0 / 
         COUNT(DISTINCT o.order_id)), 2), '%'
    ) AS tasa_entrega,
    ROUND(AVG(o.dias_entrega), 2) AS promedio_dias_entrega,
    MIN(o.dias_entrega) AS min_dias_entrega,
    MAX(o.dias_entrega) AS max_dias_entrega,
    CONCAT('€', FORMAT(SUM(f.importe), 2)) AS valor_pedidos,
    COUNT(DISTINCT CASE 
        WHEN o.dias_entrega > 5 THEN o.order_id 
    END) AS entregas_tardias
FROM dim_pedido o
JOIN fact_ventas f ON o.order_id = f.order_id
GROUP BY o.estado_pedido
ORDER BY COUNT(DISTINCT o.order_id) DESC;

-- 5.2 ANÁLISIS DE TAMAÑO DE PEDIDO
-- Distribución de pedidos por valor y volumen
SELECT 
    '5.2 DISTRIBUCIÓN DE TAMAÑO DE PEDIDO' AS analisis;

WITH pedido_metricas AS (
    SELECT 
        f.order_id,
        SUM(f.importe) AS valor_pedido,
        SUM(f.cantidad) AS unidades_pedido,
        COUNT(DISTINCT f.product_id) AS productos_diferentes
    FROM fact_ventas f
    GROUP BY f.order_id
)
SELECT 
    CASE 
        WHEN valor_pedido < 100 THEN '€0-€100 (Pequeño)'
        WHEN valor_pedido BETWEEN 100 AND 200 THEN '€100-€200 (Mediano)'
        WHEN valor_pedido BETWEEN 200 AND 300 THEN '€200-€300 (Grande)'
        ELSE '€300+ (Extra Grande)'
    END AS rango_valor,
    COUNT(*) AS cantidad_pedidos,
    CONCAT('€', FORMAT(AVG(valor_pedido), 2)) AS valor_promedio,
    ROUND(AVG(unidades_pedido), 2) AS unidades_promedio,
    ROUND(AVG(productos_diferentes), 2) AS productos_promedio,
    CONCAT('€', FORMAT(SUM(valor_pedido), 2)) AS valor_total_rango,
    CONCAT(FORMAT((SUM(valor_pedido) / 
        (SELECT SUM(valor_pedido) FROM pedido_metricas)) * 100, 2), '%') AS contribucion_ventas
FROM pedido_metricas
GROUP BY rango_valor
ORDER BY AVG(valor_pedido);

-- 5.3 ANÁLISIS DE PEDIDOS POR CLIENTE
-- Patrones de compra de clientes
SELECT 
    '5.3 PATRONES DE COMPRA POR CLIENTE' AS analisis;

SELECT 
    cl.nombre_cliente,
    cl.ciudad,
    COUNT(DISTINCT f.order_id) AS total_pedidos,
    ROUND(AVG(pedido_valor.valor), 2) AS valor_promedio_pedido,
    ROUND(AVG(pedido_valor.items), 2) AS items_promedio_pedido,
    CONCAT('€', FORMAT(SUM(f.importe), 2)) AS gasto_total,
    DATEDIFF(MAX(t.fecha), MIN(t.fecha)) AS dias_como_cliente,
    CASE 
        WHEN COUNT(DISTINCT f.order_id) >= 3 THEN 'Cliente Frecuente'
        WHEN COUNT(DISTINCT f.order_id) = 2 THEN 'Cliente Recurrente'
        ELSE 'Cliente Ocasional'
    END AS tipo_frecuencia
FROM fact_ventas f
JOIN dim_cliente cl ON f.customer_id = cl.customer_id
JOIN dim_tiempo t ON f.time_id = t.time_id
JOIN (
    SELECT 
        order_id,
        SUM(importe) AS valor,
        COUNT(*) AS items
    FROM fact_ventas
    GROUP BY order_id
) pedido_valor ON f.order_id = pedido_valor.order_id
GROUP BY cl.customer_id, cl.nombre_cliente, cl.ciudad
ORDER BY COUNT(DISTINCT f.order_id) DESC;

-- ==============================================================
-- SECCIÓN 6: ANÁLISIS DE RENTABILIDAD
-- ==============================================================

-- 6.1 ANÁLISIS DE MARGEN POR DIMENSIONES
-- Márgenes por producto, categoría y cliente
SELECT 
    '6.1 ANÁLISIS MULTIDIMENSIONAL DE MÁRGENES' AS analisis;

SELECT 
    'Por Producto' AS dimension,
    p.nombre_producto AS descripcion,
    CONCAT('€', FORMAT(SUM(f.importe), 2)) AS ventas,
    CONCAT('€', FORMAT(SUM(f.margen_bruto), 2)) AS margen,
    CONCAT(FORMAT((SUM(f.margen_bruto) / NULLIF(SUM(f.importe), 0)) * 100, 2), '%') AS porcentaje_margen
FROM fact_ventas f
JOIN dim_producto p ON f.product_id = p.product_id
GROUP BY p.product_id, p.nombre_producto
ORDER BY SUM(f.margen_bruto) DESC
LIMIT 5;

-- 6.2 PRODUCTOS CON MARGEN NEGATIVO O BAJO
-- Alertas de rentabilidad
SELECT 
    '6.2 ALERTAS DE RENTABILIDAD' AS analisis;

SELECT 
    p.codigo_producto,
    p.nombre_producto,
    c.descripcion_categoria,
    CONCAT('€', FORMAT(AVG(f.precio_unitario), 2)) AS precio_venta_promedio,
    CONCAT('€', FORMAT(SUM(f.importe), 2)) AS ventas_totales,
    CONCAT('€', FORMAT(SUM(f.margen_bruto), 2)) AS margen_total,
    CONCAT(FORMAT((SUM(f.margen_bruto) / NULLIF(SUM(f.importe), 0)) * 100, 2), '%') AS porcentaje_margen,
    CASE 
        WHEN (SUM(f.margen_bruto) / NULLIF(SUM(f.importe), 0)) * 100 < 0 THEN 'CRÍTICO: Margen Negativo'
        WHEN (SUM(f.margen_bruto) / NULLIF(SUM(f.importe), 0)) * 100 < 20 THEN 'ALERTA: Margen Bajo'
        WHEN (SUM(f.margen_bruto) / NULLIF(SUM(f.importe), 0)) * 100 < 40 THEN 'ACEPTABLE'
        ELSE 'ÓPTIMO'
    END AS estado_rentabilidad
FROM fact_ventas f
JOIN dim_producto p ON f.product_id = p.product_id
JOIN dim_categoria_producto c ON f.category_id = c.category_id
GROUP BY p.product_id, p.codigo_producto, p.nombre_producto, c.descripcion_categoria
HAVING (SUM(f.margen_bruto) / NULLIF(SUM(f.importe), 0)) * 100 < 40
ORDER BY porcentaje_margen ASC;

-- 6.3 ANÁLISIS DE PUNTO DE EQUILIBRIO POR CATEGORÍA
-- Estimación de ventas mínimas requeridas
SELECT 
    '6.3 ANÁLISIS DE EQUILIBRIO' AS analisis;

SELECT 
    c.descripcion_categoria,
    COUNT(DISTINCT p.product_id) AS total_productos,
    CONCAT('€', FORMAT(SUM(f.importe), 2)) AS ventas_actuales,
    CONCAT('€', FORMAT(SUM(f.margen_bruto), 2)) AS margen_actual,
    CONCAT(FORMAT((SUM(f.margen_bruto) / NULLIF(SUM(f.importe), 0)) * 100, 2), '%') AS margen_porcentaje,
    -- Estimación simple: costos fijos hipotéticos 30% de margen
    CONCAT('€', FORMAT(SUM(f.margen_bruto) * 0.3, 2)) AS costos_fijos_estimados,
    CONCAT('€', FORMAT(SUM(f.margen_bruto) * 0.7, 2)) AS beneficio_neto_estimado
FROM fact_ventas f
JOIN dim_categoria_producto c ON f.category_id = c.category_id
JOIN dim_producto p ON f.product_id = p.product_id
GROUP BY c.category_id, c.descripcion_categoria
ORDER BY SUM(f.margen_bruto) DESC;

-- ==============================================================
-- SECCIÓN 7: ANÁLISIS DE COMPORTAMIENTO DE COMPRA
-- ==============================================================

-- 7.1 ANÁLISIS DE CESTA DE COMPRA
-- Tamaño y composición promedio de pedidos
SELECT 
    '7.1 ANÁLISIS DE CESTA DE COMPRA' AS analisis;

WITH cesta_metricas AS (
    SELECT 
        f.order_id,
        COUNT(*) AS lineas_pedido,
        COUNT(DISTINCT f.product_id) AS productos_unicos,
        COUNT(DISTINCT f.category_id) AS categorias_diferentes,
        SUM(f.cantidad) AS unidades_totales,
        SUM(f.importe) AS valor_total
    FROM fact_ventas f
    GROUP BY f.order_id
)
SELECT 
    ROUND(AVG(lineas_pedido), 2) AS lineas_promedio_pedido,
    ROUND(AVG(productos_unicos), 2) AS productos_promedio,
    ROUND(AVG(categorias_diferentes), 2) AS categorias_promedio,
    ROUND(AVG(unidades_totales), 2) AS unidades_promedio,
    CONCAT('€', FORMAT(AVG(valor_total), 2)) AS valor_promedio_cesta,
    COUNT(*) AS total_pedidos_analizados,
    CONCAT('€', FORMAT(MIN(valor_total), 2)) AS cesta_minima,
    CONCAT('€', FORMAT(MAX(valor_total), 2)) AS cesta_maxima,
    CONCAT('€', FORMAT(STDDEV(valor_total), 2)) AS desviacion_estandar
FROM cesta_metricas;

-- 7.2 PRODUCTOS MÁS VENDIDOS POR CATEGORÍA
-- Top 3 productos en cada categoría
SELECT 
    '7.2 TOP PRODUCTOS POR CATEGORÍA' AS analisis;

WITH ranking_productos AS (
    SELECT 
        c.descripcion_categoria,
        p.nombre_producto,
        SUM(f.cantidad) AS unidades_vendidas,
        CONCAT('€', FORMAT(SUM(f.importe), 2)) AS ventas_totales,
        ROW_NUMBER() OVER (PARTITION BY c.category_id ORDER BY SUM(f.cantidad) DESC) AS ranking
    FROM fact_ventas f
    JOIN dim_producto p ON f.product_id = p.product_id
    JOIN dim_categoria_producto c ON f.category_id = c.category_id
    GROUP BY c.category_id, c.descripcion_categoria, p.product_id, p.nombre_producto
)
SELECT 
    descripcion_categoria,
    nombre_producto,
    unidades_vendidas,
    ventas_totales,
    ranking AS posicion
FROM ranking_productos
WHERE ranking <= 3
ORDER BY descripcion_categoria, ranking;

-- 7.3 ANÁLISIS DE PRIMERA COMPRA VS COMPRAS REPETIDAS
-- Comportamiento de clientes nuevos vs recurrentes
SELECT 
    '7.3 PRIMERA COMPRA VS RECURRENTES' AS analisis;

WITH primera_compra AS (
    SELECT 
        f.customer_id,
        MIN(t.fecha) AS fecha_primera_compra,
        MIN(f.order_id) AS primer_pedido
    FROM fact_ventas f
    JOIN dim_tiempo t ON f.time_id = t.time_id
    GROUP BY f.customer_id
),
clasificacion_compras AS (
    SELECT 
        f.order_id,
        f.customer_id,
        CASE 
            WHEN f.order_id = pc.primer_pedido THEN 'Primera Compra'
            ELSE 'Compra Repetida'
        END AS tipo_compra,
        SUM(f.importe) AS valor_pedido
    FROM fact_ventas f
    JOIN primera_compra pc ON f.customer_id = pc.customer_id
    GROUP BY f.order_id, f.customer_id, tipo_compra
)
SELECT 
    tipo_compra,
    COUNT(DISTINCT order_id) AS total_pedidos,
    COUNT(DISTINCT customer_id) AS total_clientes,
    CONCAT('€', FORMAT(AVG(valor_pedido), 2)) AS ticket_promedio,
    CONCAT('€', FORMAT(SUM(valor_pedido), 2)) AS ventas_totales,
    CONCAT(FORMAT((SUM(valor_pedido) / 
        (SELECT SUM(valor_pedido) FROM clasificacion_compras)) * 100, 2), '%') AS porcentaje_ventas
FROM clasificacion_compras
GROUP BY tipo_compra;

-- 7.4 ANÁLISIS DE VELOCIDAD DE RECOMPRA
-- Tiempo entre compras para clientes recurrentes
SELECT 
    '7.4 VELOCIDAD DE RECOMPRA' AS analisis;

WITH compras_ordenadas AS (
    SELECT 
        f.customer_id,
        cl.nombre_cliente,
        t.fecha,
        f.order_id,
        LAG(t.fecha) OVER (PARTITION BY f.customer_id ORDER BY t.fecha) AS fecha_compra_anterior
    FROM fact_ventas f
    JOIN dim_cliente cl ON f.customer_id = cl.customer_id
    JOIN dim_tiempo t ON f.time_id = t.time_id
    GROUP BY f.customer_id, cl.nombre_cliente, t.fecha, f.order_id
)
SELECT 
    nombre_cliente,
    COUNT(DISTINCT order_id) AS total_compras,
    ROUND(AVG(DATEDIFF(fecha, fecha_compra_anterior)), 2) AS dias_promedio_entre_compras,
    MIN(DATEDIFF(fecha, fecha_compra_anterior)) AS min_dias_recompra,
    MAX(DATEDIFF(fecha, fecha_compra_anterior)) AS max_dias_recompra,
    CASE 
        WHEN AVG(DATEDIFF(fecha, fecha_compra_anterior)) <= 30 THEN 'Muy Frecuente'
        WHEN AVG(DATEDIFF(fecha, fecha_compra_anterior)) <= 60 THEN 'Frecuente'
        WHEN AVG(DATEDIFF(fecha, fecha_compra_anterior)) <= 90 THEN 'Moderado'
        ELSE 'Ocasional'
    END AS frecuencia_recompra
FROM compras_ordenadas
WHERE fecha_compra_anterior IS NOT NULL
GROUP BY customer_id, nombre_cliente
HAVING COUNT(DISTINCT order_id) >= 2
ORDER BY dias_promedio_entre_compras;

-- ==============================================================
-- SECCIÓN 8: ANÁLISIS COMPARATIVO Y BENCHMARKING
-- ==============================================================

-- 8.1 COMPARACIÓN DE RENDIMIENTO ENTRE REGIONES
-- Benchmarking geográfico
SELECT 
    '8.1 BENCHMARKING POR REGIÓN' AS analisis;

WITH metricas_region AS (
    SELECT 
        cl.region,
        COUNT(DISTINCT cl.customer_id) AS clientes,
        COUNT(DISTINCT f.order_id) AS pedidos,
        SUM(f.importe) AS ventas,
        SUM(f.margen_bruto) AS margen
    FROM fact_ventas f
    JOIN dim_cliente cl ON f.customer_id = cl.customer_id
    GROUP BY cl.region
),
promedios_globales AS (
    SELECT 
        AVG(ventas / clientes) AS venta_promedio_por_cliente,
        AVG(margen / ventas) AS margen_promedio_global
    FROM metricas_region
)
SELECT 
    mr.region,
    mr.clientes,
    mr.pedidos,
    CONCAT('€', FORMAT(mr.ventas, 2)) AS ventas_totales,
    CONCAT('€', FORMAT(mr.ventas / mr.clientes, 2)) AS venta_por_cliente,
    CONCAT('€', FORMAT(mr.ventas / mr.pedidos, 2)) AS ticket_promedio,
    CONCAT(FORMAT((mr.margen / mr.ventas) * 100, 2), '%') AS margen_porcentaje,
    CASE 
        WHEN (mr.ventas / mr.clientes) > pg.venta_promedio_por_cliente * 1.2 THEN 'Sobre Promedio (+20%)'
        WHEN (mr.ventas / mr.clientes) > pg.venta_promedio_por_cliente THEN 'Por Encima del Promedio'
        WHEN (mr.ventas / mr.clientes) > pg.venta_promedio_por_cliente * 0.8 THEN 'Cerca del Promedio'
        ELSE 'Bajo Promedio (-20%)'
    END AS rendimiento_relativo
FROM metricas_region mr
CROSS JOIN promedios_globales pg
ORDER BY mr.ventas DESC;

-- 8.2 ANÁLISIS DE PARTICIPACIÓN DE MERCADO POR CATEGORÍA
-- Share of wallet por categoría
SELECT 
    '8.2 PARTICIPACIÓN POR CATEGORÍA' AS analisis;

WITH ventas_totales AS (
    SELECT SUM(importe) AS total FROM fact_ventas
)
SELECT 
    c.descripcion_categoria,
    COUNT(DISTINCT f.product_id) AS productos,
    CONCAT('€', FORMAT(SUM(f.importe), 2)) AS ventas,
    CONCAT(FORMAT((SUM(f.importe) / vt.total) * 100, 2), '%') AS share_ventas,
    CONCAT(FORMAT((COUNT(DISTINCT f.product_id) * 100.0 / 
        (SELECT COUNT(DISTINCT product_id) FROM dim_producto)), 2), '%') AS share_productos,
    CASE 
        WHEN (SUM(f.importe) / vt.total) * 100 > 10 THEN 'Líder'
        WHEN (SUM(f.importe) / vt.total) * 100 > 5 THEN 'Competidor Fuerte'
        ELSE 'Jugador Nicho'
    END AS posicion_mercado
FROM fact_ventas f
JOIN dim_categoria_producto c ON f.category_id = c.category_id
CROSS JOIN ventas_totales vt
GROUP BY c.category_id, c.descripcion_categoria, vt.total
ORDER BY SUM(f.importe) DESC;

-- 8.3 ÍNDICE DE CONCENTRACIÓN DE CLIENTES
-- Medida de dependencia de pocos clientes
SELECT 
    '8.3 ÍNDICE DE CONCENTRACIÓN DE CLIENTES' AS analisis;

WITH ventas_cliente AS (
    SELECT 
        cl.customer_id,
        cl.nombre_cliente,
        SUM(f.importe) AS ventas
    FROM fact_ventas f
    JOIN dim_cliente cl ON f.customer_id = cl.customer_id
    GROUP BY cl.customer_id, cl.nombre_cliente
),
ventas_acumuladas AS (
    SELECT 
        *,
        SUM(ventas) OVER (ORDER BY ventas DESC) AS ventas_acum,
        (SUM(ventas) OVER (ORDER BY ventas DESC) / 
         (SELECT SUM(ventas) FROM ventas_cliente)) * 100 AS porcentaje_acum,
        ROW_NUMBER() OVER (ORDER BY ventas DESC) AS ranking
    FROM ventas_cliente
)
SELECT 
    CONCAT('Top ', ranking) AS grupo_clientes,
    nombre_cliente,
    CONCAT('€', FORMAT(ventas, 2)) AS ventas_cliente,
    CONCAT(FORMAT(porcentaje_acum, 2), '%') AS participacion_acumulada,
    CASE 
        WHEN ranking <= 3 THEN 'Clientes Clave - Alta Dependencia'
        WHEN ranking <= 5 THEN 'Clientes Importantes'
        WHEN porcentaje_acum <= 80 THEN 'Contribuyentes 80/20'
        ELSE 'Long Tail'
    END AS clasificacion
FROM ventas_acumuladas
ORDER BY ranking;

-- ==============================================================
-- SECCIÓN 9: ANÁLISIS PREDICTIVO Y PROYECCIONES
-- ==============================================================

-- 9.1 PROYECCIÓN DE VENTAS BASADA EN TENDENCIA
-- Pronóstico simple basado en promedio histórico
SELECT 
    '9.1 PROYECCIÓN DE VENTAS' AS analisis;

WITH ventas_mensuales AS (
    SELECT 
        t.anio,
        t.mes,
        t.nombre_mes,
        SUM(f.importe) AS ventas_mes
    FROM fact_ventas f
    JOIN dim_tiempo t ON f.time_id = t.time_id
    GROUP BY t.anio, t.mes, t.nombre_mes
),
estadisticas AS (
    SELECT 
        AVG(ventas_mes) AS promedio_mensual,
        STDDEV(ventas_mes) AS desviacion,
        MAX(ventas_mes) AS mejor_mes,
        MIN(ventas_mes) AS peor_mes
    FROM ventas_mensuales
)
SELECT 
    'Promedio Mensual Histórico' AS metrica,
    CONCAT('€', FORMAT(promedio_mensual, 2)) AS valor
FROM estadisticas
UNION ALL
SELECT 
    'Proyección Mes Siguiente (Conservadora)',
    CONCAT('€', FORMAT(promedio_mensual * 0.95, 2))
FROM estadisticas
UNION ALL
SELECT 
    'Proyección Mes Siguiente (Optimista)',
    CONCAT('€', FORMAT(promedio_mensual * 1.1, 2))
FROM estadisticas
UNION ALL
SELECT 
    'Proyección Trimestral',
    CONCAT('€', FORMAT(promedio_mensual * 3, 2))
FROM estadisticas
UNION ALL
SELECT 
    'Proyección Anual',
    CONCAT('€', FORMAT(promedio_mensual * 12, 2))
FROM estadisticas;

-- 9.2 IDENTIFICACIÓN DE CLIENTES EN RIESGO DE ABANDONO
-- Clientes sin compras recientes
SELECT 
    '9.2 CLIENTES EN RIESGO DE ABANDONO' AS analisis;

WITH ultima_compra AS (
    SELECT 
        cl.customer_id,
        cl.nombre_cliente,
        cl.ciudad,
        MAX(t.fecha) AS fecha_ultima_compra,
        DATEDIFF(CURDATE(), MAX(t.fecha)) AS dias_sin_comprar,
        COUNT(DISTINCT f.order_id) AS total_compras_historicas,
        SUM(f.importe) AS valor_historico
    FROM fact_ventas f
    JOIN dim_cliente cl ON f.customer_id = cl.customer_id
    JOIN dim_tiempo t ON f.time_id = t.time_id
    GROUP BY cl.customer_id, cl.nombre_cliente, cl.ciudad
)
SELECT 
    nombre_cliente,
    ciudad,
    fecha_ultima_compra,
    dias_sin_comprar,
    total_compras_historicas,
    CONCAT('€', FORMAT(valor_historico, 2)) AS valor_lifetime,
    CASE 
        WHEN dias_sin_comprar > 90 AND total_compras_historicas >= 3 THEN 'CRÍTICO: Cliente Valioso Inactivo'
        WHEN dias_sin_comprar > 60 AND total_compras_historicas >= 2 THEN 'ALERTA: Riesgo Alto'
        WHEN dias_sin_comprar > 45 THEN 'PRECAUCIÓN: Monitorear'
        ELSE 'ACTIVO'
    END AS nivel_riesgo,
    CASE 
        WHEN dias_sin_comprar > 90 AND total_compras_historicas >= 3 THEN 'Contacto inmediato + oferta personalizada'
        WHEN dias_sin_comprar > 60 AND total_compras_historicas >= 2 THEN 'Email de reactivación + descuento'
        WHEN dias_sin_comprar > 45 THEN 'Newsletter con novedades'
        ELSE 'Mantener comunicación regular'
    END AS accion_recomendada
FROM ultima_compra
WHERE dias_sin_comprar > 30
ORDER BY valor_historico DESC, dias_sin_comprar DESC;

-- 9.3 PRODUCTOS CON POTENCIAL DE CRECIMIENTO
-- Productos con buena rotación pero baja penetración
SELECT 
    '9.3 PRODUCTOS CON POTENCIAL' AS analisis;

WITH metricas_producto AS (
    SELECT 
        p.product_id,
        p.codigo_producto,
        p.nombre_producto,
        c.descripcion_categoria,
        COUNT(DISTINCT f.customer_id) AS clientes_compradores,
        SUM(f.cantidad) AS unidades_vendidas,
        SUM(f.importe) AS ventas,
        (SUM(f.margen_bruto) / NULLIF(SUM(f.importe), 0)) * 100 AS margen_porcentaje,
        (COUNT(DISTINCT f.customer_id) * 100.0 / 
         (SELECT COUNT(DISTINCT customer_id) FROM fact_ventas)) AS penetracion_clientes
    FROM fact_ventas f
    JOIN dim_producto p ON f.product_id = p.product_id
    JOIN dim_categoria_producto c ON f.category_id = c.category_id
    GROUP BY p.product_id, p.codigo_producto, p.nombre_producto, c.descripcion_categoria
)
SELECT 
    codigo_producto,
    nombre_producto,
    descripcion_categoria,
    clientes_compradores,
    CONCAT(FORMAT(penetracion_clientes, 2), '%') AS penetracion,
    unidades_vendidas,
    CONCAT('€', FORMAT(ventas, 2)) AS ventas_actuales,
    CONCAT(FORMAT(margen_porcentaje, 2), '%') AS margen,
    CASE 
        WHEN margen_porcentaje > 40 AND penetracion_clientes < 30 THEN 'Alto Potencial - Buen Margen'
        WHEN unidades_vendidas > 10 AND penetracion_clientes < 40 THEN 'Alto Potencial - Buena Rotación'
        WHEN margen_porcentaje > 35 THEN 'Potencial Medio - Ampliar Base'
        ELSE 'Estable'
    END AS clasificacion_potencial,
    CASE 
        WHEN margen_porcentaje > 40 AND penetracion_clientes < 30 THEN 'Campaña de visibilidad agresiva'
        WHEN unidades_vendidas > 10 AND penetracion_clientes < 40 THEN 'Cross-selling y bundles'
        WHEN margen_porcentaje > 35 THEN 'Programa de referidos'
        ELSE 'Mantener estrategia actual'
    END AS estrategia_crecimiento
FROM metricas_producto
WHERE margen_porcentaje > 30 OR unidades_vendidas > 8
ORDER BY margen_porcentaje DESC, penetracion_clientes ASC;

-- ==============================================================
-- SECCIÓN 10: DASHBOARDS Y KPIs EJECUTIVOS
-- ==============================================================

-- 10.1 DASHBOARD EJECUTIVO - RESUMEN GENERAL
-- Vista consolidada de KPIs principales
SELECT 
    '10.1 DASHBOARD EJECUTIVO' AS reporte;

SELECT 
    'Total Ventas' AS kpi,
    CONCAT('€', FORMAT(SUM(importe), 2)) AS valor,
    'Ingresos totales del período' AS descripcion
FROM fact_ventas
UNION ALL
SELECT 
    'Margen Bruto Total',
    CONCAT('€', FORMAT(SUM(margen_bruto), 2)),
    'Ganancia antes de costos fijos'
FROM fact_ventas
UNION ALL
SELECT 
    'Margen Promedio',
    CONCAT(FORMAT((SUM(margen_bruto) / NULLIF(SUM(importe), 0)) * 100, 2), '%'),
    'Porcentaje de rentabilidad'
FROM fact_ventas
UNION ALL
SELECT 
    'Total Pedidos',
    COUNT(DISTINCT order_id),
    'Número de transacciones'
FROM fact_ventas
UNION ALL
SELECT 
    'Ticket Promedio',
    CONCAT('€', FORMAT(AVG(pedido_valor), 2)),
    'Valor promedio por pedido'
FROM (SELECT order_id, SUM(importe) AS pedido_valor FROM fact_ventas GROUP BY order_id) AS subq
UNION ALL
SELECT 
    'Clientes Activos',
    COUNT(DISTINCT customer_id),
    'Clientes con al menos una compra'
FROM fact_ventas
UNION ALL
SELECT 
    'Productos Vendidos',
    COUNT(DISTINCT product_id),
    'SKUs con movimiento'
FROM fact_ventas
UNION ALL
SELECT 
    'Unidades Totales',
    SUM(cantidad),
    'Cantidad total de productos vendidos'
FROM fact_ventas
UNION ALL
SELECT 
    'Categorías Activas',
    COUNT(DISTINCT category_id),
    'Categorías con ventas'
FROM fact_ventas;

-- 10.2 SCORECARD DE RENDIMIENTO POR CATEGORÍA
-- Tabla de scorecard consolidada
SELECT 
    '10.2 SCORECARD POR CATEGORÍA' AS reporte;

SELECT 
    c.descripcion_categoria AS categoria,
    COUNT(DISTINCT p.product_id) AS skus,
    COUNT(DISTINCT f.order_id) AS pedidos,
    SUM(f.cantidad) AS unidades,
    CONCAT('€', FORMAT(SUM(f.importe), 2)) AS ventas,
    CONCAT('€', FORMAT(SUM(f.margen_bruto), 2)) AS margen,
    CONCAT(FORMAT((SUM(f.margen_bruto) / NULLIF(SUM(f.importe), 0)) * 100, 1), '%') AS margen_pct,
    CONCAT('€', FORMAT(SUM(f.importe) / COUNT(DISTINCT f.order_id), 2)) AS ticket_medio,
    -- Scoring simple: 5 estrellas basado en ventas
    CASE 
        WHEN SUM(f.importe) >= (SELECT MAX(ventas) * 0.8 FROM 
            (SELECT SUM(importe) AS ventas FROM fact_ventas GROUP BY category_id) AS subq) 
            THEN '★★★★★'
        WHEN SUM(f.importe) >= (SELECT MAX(ventas) * 0.6 FROM 
            (SELECT SUM(importe) AS ventas FROM fact_ventas GROUP BY category_id) AS subq) 
            THEN '★★★★☆'
        WHEN SUM(f.importe) >= (SELECT MAX(ventas) * 0.4 FROM 
            (SELECT SUM(importe) AS ventas FROM fact_ventas GROUP BY category_id) AS subq) 
            THEN '★★★☆☆'
        WHEN SUM(f.importe) >= (SELECT MAX(ventas) * 0.2 FROM 
            (SELECT SUM(importe) AS ventas FROM fact_ventas GROUP BY category_id) AS subq) 
            THEN '★★☆☆☆'
        ELSE '★☆☆☆☆'
    END AS rating
FROM fact_ventas f
JOIN dim_categoria_producto c ON f.category_id = c.category_id
JOIN dim_producto p ON f.product_id = p.product_id
GROUP BY c.category_id, c.descripcion_categoria
ORDER BY SUM(f.importe) DESC;

-- 10.3 ALERTAS Y EXCEPCIONES
-- Monitoreo de situaciones que requieren atención
SELECT 
    '10.3 ALERTAS Y EXCEPCIONES' AS reporte;

SELECT 
    'Pedidos Pendientes' AS tipo_alerta,
    COUNT(DISTINCT o.order_id) AS cantidad,
    CONCAT('€', FORMAT(SUM(f.importe), 2)) AS valor_impacto,
    'OPERACIONAL' AS prioridad
FROM dim_pedido o
JOIN fact_ventas f ON o.order_id = f.order_id
WHERE o.estado_pedido = 'Pendiente'
UNION ALL
SELECT 
    'Entregas Tardías (>7 días)',
    COUNT(DISTINCT o.order_id),
    CONCAT('€', FORMAT(SUM(f.importe), 2)),
    'ALTA'
FROM dim_pedido o
JOIN fact_ventas f ON o.order_id = f.order_id
WHERE o.dias_entrega > 7
UNION ALL
SELECT 
    'Productos Sin Ventas',
    COUNT(DISTINCT p.product_id),
    'N/A',
    'MEDIA'
FROM dim_producto p
LEFT JOIN fact_ventas f ON p.product_id = f.product_id
WHERE f.product_id IS NULL
UNION ALL
SELECT 
    'Clientes Inactivos >60 días',
    COUNT(DISTINCT uc.customer_id),
    CONCAT('€', FORMAT(SUM(uc.valor_historico), 2)),
    'MEDIA'
FROM (
    SELECT 
        cl.customer_id,
        MAX(t.fecha) AS ultima_compra,
        SUM(f.importe) AS valor_historico
    FROM fact_ventas f
    JOIN dim_cliente cl ON f.customer_id = cl.customer_id
    JOIN dim_tiempo t ON f.time_id = t.time_id
    GROUP BY cl.customer_id
    HAVING DATEDIFF(CURDATE(), MAX(t.fecha)) > 60
) AS uc;

-- ==============================================================
-- FIN DE CONSULTAS ANALÍTICAS AVANZADAS
-- ==============================================================

SELECT 
    '=' AS separador,
    'PROCESO DE ANÁLISIS COMPLETADO' AS mensaje,
    NOW() AS fecha_ejecucion,
    'Total de 30+ consultas analíticas generadas' AS resultado;
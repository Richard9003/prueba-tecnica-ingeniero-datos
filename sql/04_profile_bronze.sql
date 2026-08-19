USE PruebaIngenieroDatos;
GO

/*
    Prueba técnica - Ingeniero de Datos

    Perfilado de las tablas Bronze.

    En esta capa se conserva la información recibida desde los archivos
    CSV. No se corrigen datos en Bronze. El objetivo es identificar
    problemas de calidad antes de construir Silver.
*/


/* 1. Conteo general de registros */

SELECT
    'ventas' AS tabla,
    COUNT(*) AS total_registros
FROM bronze.ventas

UNION ALL

SELECT
    'dim_cliente' AS tabla,
    COUNT(*) AS total_registros
FROM bronze.dim_cliente

UNION ALL

SELECT
    'dim_producto' AS tabla,
    COUNT(*) AS total_registros
FROM bronze.dim_producto;
GO


/* 2. Campos nulos o vacíos en ventas */

SELECT
    SUM(CASE
        WHEN venta_id IS NULL THEN 1
        ELSE 0
    END) AS venta_id_nulo,

    SUM(CASE
        WHEN fecha IS NULL OR LTRIM(RTRIM(fecha)) = '' THEN 1
        ELSE 0
    END) AS fecha_nula,

    SUM(CASE
        WHEN cliente_id IS NULL THEN 1
        ELSE 0
    END) AS cliente_id_nulo,

    SUM(CASE
        WHEN producto_id IS NULL THEN 1
        ELSE 0
    END) AS producto_id_nulo,

    SUM(CASE
        WHEN monto IS NULL OR LTRIM(RTRIM(monto)) = '' THEN 1
        ELSE 0
    END) AS monto_nulo,

    SUM(CASE
        WHEN cantidad IS NULL OR LTRIM(RTRIM(cantidad)) = '' THEN 1
        ELSE 0
    END) AS cantidad_nula
FROM bronze.ventas;
GO


/* 3. Validación de tipos numéricos */

SELECT
    SUM(CASE
        WHEN monto IS NOT NULL
         AND LTRIM(RTRIM(monto)) <> ''
         AND TRY_CONVERT(DECIMAL(18,2), monto) IS NULL
        THEN 1
        ELSE 0
    END) AS monto_no_numerico,

    SUM(CASE
        WHEN cantidad IS NOT NULL
         AND LTRIM(RTRIM(cantidad)) <> ''
         AND TRY_CONVERT(INT, cantidad) IS NULL
        THEN 1
        ELSE 0
    END) AS cantidad_no_numerica
FROM bronze.ventas;
GO


/* 4. Separación entre montos nulos y montos no numéricos */

SELECT
    SUM(CASE
        WHEN monto IS NULL OR LTRIM(RTRIM(monto)) = ''
        THEN 1
        ELSE 0
    END) AS monto_nulo,

    SUM(CASE
        WHEN monto IS NOT NULL
         AND LTRIM(RTRIM(monto)) <> ''
         AND TRY_CONVERT(DECIMAL(18,2), monto) IS NULL
        THEN 1
        ELSE 0
    END) AS monto_no_numerico
FROM bronze.ventas;
GO


/* 5. Separación entre cantidades nulas y cantidades no numéricas */

SELECT
    SUM(CASE
        WHEN cantidad IS NULL OR LTRIM(RTRIM(cantidad)) = ''
        THEN 1
        ELSE 0
    END) AS cantidad_nula,

    SUM(CASE
        WHEN cantidad IS NOT NULL
         AND LTRIM(RTRIM(cantidad)) <> ''
         AND TRY_CONVERT(INT, cantidad) IS NULL
        THEN 1
        ELSE 0
    END) AS cantidad_no_numerica
FROM bronze.ventas;
GO


/* 6. Validación de fechas */

SELECT
    COUNT(*) AS fechas_invalidas
FROM bronze.ventas
WHERE fecha IS NULL
   OR LTRIM(RTRIM(fecha)) = ''
   OR TRY_CONVERT(DATE, fecha, 103) IS NULL;
GO


/* 7. Duplicados de venta_id */

SELECT
    venta_id,
    COUNT(*) AS cantidad_registros
FROM bronze.ventas
GROUP BY venta_id
HAVING COUNT(*) > 1;
GO


/* 8. Duplicados de cliente_id */

SELECT
    cliente_id,
    COUNT(*) AS cantidad_registros
FROM bronze.dim_cliente
GROUP BY cliente_id
HAVING COUNT(*) > 1;
GO


/* 9. Duplicados de producto_id */

SELECT
    producto_id,
    COUNT(*) AS cantidad_registros
FROM bronze.dim_producto
GROUP BY producto_id
HAVING COUNT(*) > 1;
GO


/* 10. Clientes informados que no existen en la dimensión */

SELECT
    v.cliente_id,
    COUNT(*) AS cantidad_ventas
FROM bronze.ventas AS v
LEFT JOIN bronze.dim_cliente AS c
    ON v.cliente_id = c.cliente_id
WHERE v.cliente_id IS NOT NULL
  AND c.cliente_id IS NULL
GROUP BY v.cliente_id;
GO


/* 11. Productos informados que no existen en la dimensión */

SELECT
    v.producto_id,
    COUNT(*) AS cantidad_ventas
FROM bronze.ventas AS v
LEFT JOIN bronze.dim_producto AS p
    ON v.producto_id = p.producto_id
WHERE v.producto_id IS NOT NULL
  AND p.producto_id IS NULL
GROUP BY v.producto_id;
GO


/* 12. Valores encontrados en la dimensión de clientes */

SELECT DISTINCT
    segmento,
    region
FROM bronze.dim_cliente
ORDER BY segmento, region;
GO


/* 13. Valores encontrados en la dimensión de productos */

SELECT DISTINCT
    categoria,
    subcategoria
FROM bronze.dim_producto
ORDER BY categoria, subcategoria;
GO


/* 14. Detalle del cliente duplicado */

SELECT
    cliente_id,
    cliente_nombre,
    segmento,
    region
FROM bronze.dim_cliente
WHERE cliente_id IN (
    SELECT cliente_id
    FROM bronze.dim_cliente
    GROUP BY cliente_id
    HAVING COUNT(*) > 1
)
ORDER BY cliente_id;
GO


/* 15. Detalle del producto duplicado */

SELECT
    producto_id,
    producto_nombre,
    categoria,
    subcategoria,
    precio_lista
FROM bronze.dim_producto
WHERE producto_id IN (
    SELECT producto_id
    FROM bronze.dim_producto
    GROUP BY producto_id
    HAVING COUNT(*) > 1
)
ORDER BY producto_id;
GO


/* 16. Valores de monto encontrados */

SELECT
    monto,
    COUNT(*) AS cantidad_registros
FROM bronze.ventas
GROUP BY monto
ORDER BY monto;
GO


/* 17. Valores de cantidad encontrados */

SELECT
    cantidad,
    COUNT(*) AS cantidad_registros
FROM bronze.ventas
GROUP BY cantidad
ORDER BY cantidad;
GO
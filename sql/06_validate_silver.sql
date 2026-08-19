USE PruebaIngenieroDatos;
GO

/*
    Validación de resultados de la capa Silver.
*/

SELECT
    'silver.dim_cliente' AS tabla,
    COUNT(*) AS total_registros
FROM silver.dim_cliente

UNION ALL

SELECT
    'silver.dim_producto',
    COUNT(*)
FROM silver.dim_producto

UNION ALL

SELECT
    'silver.ventas',
    COUNT(*)
FROM silver.ventas

UNION ALL

SELECT
    'silver.rechazos',
    COUNT(*)
FROM silver.rechazos;
GO


/* Distribución de ventas válidas e inválidas */

SELECT
    venta_valida,
    COUNT(*) AS total_registros
FROM silver.ventas
GROUP BY venta_valida
ORDER BY venta_valida;
GO


/* Distribución de motivos de rechazo */

SELECT
    motivo,
    COUNT(*) AS total_registros
FROM silver.rechazos
GROUP BY motivo
ORDER BY motivo;
GO


/* Clientes Silver */

SELECT *
FROM silver.dim_cliente
ORDER BY cliente_id;
GO


/* Productos Silver */

SELECT *
FROM silver.dim_producto
ORDER BY producto_id;
GO
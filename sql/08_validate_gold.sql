USE PruebaIngenieroDatos;
GO

/*
    Validación del modelo dimensional Gold.
*/

SELECT
    'gold.dim_cliente' AS tabla,
    COUNT(*) AS total_registros
FROM gold.dim_cliente

UNION ALL

SELECT
    'gold.dim_producto',
    COUNT(*)
FROM gold.dim_producto

UNION ALL

SELECT
    'gold.dim_fecha',
    COUNT(*)
FROM gold.dim_fecha

UNION ALL

SELECT
    'gold.fact_ventas',
    COUNT(*)
FROM gold.fact_ventas;
GO


/* Validar claves duplicadas en la tabla de hechos */

SELECT
    venta_id,
    COUNT(*) AS cantidad
FROM gold.fact_ventas
GROUP BY venta_id
HAVING COUNT(*) > 1;
GO


/* Validar sumas y cantidades */

SELECT
    COUNT(*) AS total_ventas,
    SUM(cantidad) AS unidades_vendidas,
    SUM(monto) AS ventas_totales
FROM gold.fact_ventas;
GO
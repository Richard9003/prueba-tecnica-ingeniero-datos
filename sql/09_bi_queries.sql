USE PruebaIngenieroDatos;
GO

/*
    Consultas de ejemplo para consumo BI.
*/


/* 1. Ventas por mes */

SELECT
    f.anio,
    f.mes,
    f.nombre_mes,
    SUM(v.monto) AS ventas_totales,
    SUM(v.cantidad) AS unidades_vendidas,
    COUNT(*) AS numero_ventas
FROM gold.fact_ventas AS v
INNER JOIN gold.dim_fecha AS f
    ON f.fecha_sk = v.fecha_sk
GROUP BY
    f.anio,
    f.mes,
    f.nombre_mes
ORDER BY
    f.anio,
    f.mes;
GO


/* 2. Top clientes por ventas */

SELECT TOP (10)
    c.cliente_id,
    c.cliente_nombre,
    c.segmento,
    c.region,
    SUM(v.monto) AS ventas_totales,
    SUM(v.cantidad) AS unidades_vendidas,
    COUNT(*) AS numero_ventas
FROM gold.fact_ventas AS v
INNER JOIN gold.dim_cliente AS c
    ON c.cliente_sk = v.cliente_sk
GROUP BY
    c.cliente_id,
    c.cliente_nombre,
    c.segmento,
    c.region
ORDER BY
    ventas_totales DESC;
GO


/* 3. Ventas por categoría */

SELECT
    p.categoria,
    p.subcategoria,
    SUM(v.monto) AS ventas_totales,
    SUM(v.cantidad) AS unidades_vendidas,
    COUNT(*) AS numero_ventas
FROM gold.fact_ventas AS v
INNER JOIN gold.dim_producto AS p
    ON p.producto_sk = v.producto_sk
GROUP BY
    p.categoria,
    p.subcategoria
ORDER BY
    ventas_totales DESC;
GO
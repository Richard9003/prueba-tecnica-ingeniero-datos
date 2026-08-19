USE PruebaIngenieroDatos;
GO

/*
    Construcción de la capa Silver.

    Silver contiene datos tipificados, estandarizados y deduplicados.
    Los registros Bronze no se modifican.
*/


/* Crear esquema Silver */

IF NOT EXISTS (
    SELECT 1
    FROM sys.schemas
    WHERE name = 'silver'
)
BEGIN
    EXEC('CREATE SCHEMA silver');
END;
GO


/* Eliminar tablas para permitir ejecuciones repetibles */

IF OBJECT_ID('silver.ventas', 'U') IS NOT NULL
    DROP TABLE silver.ventas;

IF OBJECT_ID('silver.dim_cliente', 'U') IS NOT NULL
    DROP TABLE silver.dim_cliente;

IF OBJECT_ID('silver.dim_producto', 'U') IS NOT NULL
    DROP TABLE silver.dim_producto;

IF OBJECT_ID('silver.rechazos', 'U') IS NOT NULL
    DROP TABLE silver.rechazos;
GO


/* Clientes Silver */

WITH clientes_limpios AS (
    SELECT
        cliente_id,
        NULLIF(LTRIM(RTRIM(cliente_nombre)), '') AS cliente_nombre,

        CASE
            WHEN LOWER(LTRIM(RTRIM(segmento))) IN ('retail', 'retial')
                THEN 'Retail'
            WHEN LOWER(LTRIM(RTRIM(segmento))) = 'pyme'
                THEN 'PYME'
            WHEN LOWER(LTRIM(RTRIM(segmento))) = 'corporate'
                THEN 'Corporate'
            ELSE 'No informado'
        END AS segmento,

        CASE
            WHEN LOWER(LTRIM(RTRIM(region))) IN ('norte', 'noroeste')
                THEN 'Norte'
            WHEN LOWER(LTRIM(RTRIM(region))) = 'centro'
                THEN 'Centro'
            WHEN LOWER(LTRIM(RTRIM(region))) = 'sur'
                THEN 'Sur'
            ELSE 'No informado'
        END AS region,

        ROW_NUMBER() OVER (
            PARTITION BY cliente_id
            ORDER BY
                CASE
                    WHEN cliente_nombre IS NOT NULL
                     AND segmento IS NOT NULL
                     AND region IS NOT NULL
                    THEN 1
                    ELSE 2
                END
        ) AS fila
    FROM bronze.dim_cliente
    WHERE cliente_id IS NOT NULL
)
SELECT
    cliente_id,
    cliente_nombre,
    segmento,
    region
INTO silver.dim_cliente
FROM clientes_limpios
WHERE fila = 1;
GO


/* Productos Silver */

WITH productos_limpios AS (
    SELECT
        producto_id,
        NULLIF(LTRIM(RTRIM(producto_nombre)), '') AS producto_nombre,

        CASE
            WHEN UPPER(LTRIM(RTRIM(categoria))) IN ('AUTO', 'AUT0')
                THEN 'Auto'
            WHEN UPPER(LTRIM(RTRIM(categoria))) = 'HOGAR'
                THEN 'Hogar'
            WHEN UPPER(LTRIM(RTRIM(categoria))) = 'VIDA'
                THEN 'Vida'
            WHEN UPPER(LTRIM(RTRIM(categoria))) = 'SALUD'
                THEN 'Salud'
            ELSE 'No informado'
        END AS categoria,

        CASE
            WHEN UPPER(LTRIM(RTRIM(subcategoria))) = 'BÁSICO'
                THEN 'Básico'
            WHEN UPPER(LTRIM(RTRIM(subcategoria))) = 'PREMIUM'
                THEN 'Premium'
            WHEN UPPER(LTRIM(RTRIM(subcategoria))) = 'FULL'
                THEN 'Full'
            ELSE 'No informado'
        END AS subcategoria,

        TRY_CONVERT(DECIMAL(18,2), precio_lista) AS precio_lista,

        ROW_NUMBER() OVER (
            PARTITION BY producto_id
            ORDER BY
                CASE
                    WHEN producto_nombre IS NOT NULL
                     AND categoria IS NOT NULL
                     AND subcategoria IS NOT NULL
                     AND precio_lista IS NOT NULL
                    THEN 1
                    ELSE 2
                END
        ) AS fila
    FROM bronze.dim_producto
    WHERE producto_id IS NOT NULL
)
SELECT
    producto_id,
    producto_nombre,
    categoria,
    subcategoria,
    precio_lista
INTO silver.dim_producto
FROM productos_limpios
WHERE fila = 1;
GO


/* Ventas Silver */

SELECT
    TRY_CONVERT(INT, venta_id) AS venta_id,

    TRY_CONVERT(DATE, fecha, 103) AS fecha,

    TRY_CONVERT(INT, cliente_id) AS cliente_id,

    TRY_CONVERT(INT, producto_id) AS producto_id,

    TRY_CONVERT(DECIMAL(18,2), NULLIF(LTRIM(RTRIM(monto)), '')) AS monto,

    TRY_CONVERT(INT, NULLIF(LTRIM(RTRIM(cantidad)), '')) AS cantidad,

    CASE
        WHEN cliente_id IS NULL THEN 0
        ELSE 1
    END AS cliente_informado,

    CASE
        WHEN TRY_CONVERT(DECIMAL(18,2), NULLIF(LTRIM(RTRIM(monto)), '')) IS NOT NULL
         AND TRY_CONVERT(INT, NULLIF(LTRIM(RTRIM(cantidad)), '')) IS NOT NULL
         AND TRY_CONVERT(DATE, fecha, 103) IS NOT NULL
        THEN 1
        ELSE 0
    END AS venta_valida

INTO silver.ventas
FROM bronze.ventas;
GO


/* Tabla de rechazos y observaciones */

SELECT
    venta_id,
    fecha,
    cliente_id,
    producto_id,
    monto,
    cantidad,

    CASE
        WHEN fecha IS NULL OR TRY_CONVERT(DATE, fecha, 103) IS NULL
            THEN 'Fecha inválida'

        WHEN monto IS NULL OR LTRIM(RTRIM(monto)) = ''
            THEN 'Monto nulo'

        WHEN TRY_CONVERT(DECIMAL(18,2), monto) IS NULL
            THEN 'Monto no numérico'

        WHEN cantidad IS NULL OR LTRIM(RTRIM(cantidad)) = ''
            THEN 'Cantidad nula'

        WHEN TRY_CONVERT(INT, cantidad) IS NULL
            THEN 'Cantidad no numérica'

        WHEN cliente_id IS NULL
            THEN 'Cliente no informado'

        ELSE 'Observación'
    END AS motivo
INTO silver.rechazos
FROM bronze.ventas
WHERE
       fecha IS NULL
    OR TRY_CONVERT(DATE, fecha, 103) IS NULL
    OR monto IS NULL
    OR LTRIM(RTRIM(monto)) = ''
    OR TRY_CONVERT(DECIMAL(18,2), monto) IS NULL
    OR cantidad IS NULL
    OR LTRIM(RTRIM(cantidad)) = ''
    OR TRY_CONVERT(INT, cantidad) IS NULL
    OR cliente_id IS NULL;
GO
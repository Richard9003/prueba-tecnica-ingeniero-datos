USE PruebaIngenieroDatos;
GO

/*
    Construcción de la capa Silver.

    Silver conserva el detalle de las ventas, pero convierte los tipos
    de datos y estandariza los valores de las dimensiones.

    Los registros con datos inválidos no se eliminan de Silver.
    Se conservan para garantizar trazabilidad y se marcan mediante
    la columna venta_valida.
*/


/* Crear el esquema Silver si todavía no existe */

IF NOT EXISTS (
    SELECT 1
    FROM sys.schemas
    WHERE name = 'silver'
)
BEGIN
    EXEC('CREATE SCHEMA silver');
END;
GO


/*
    Eliminar las tablas Silver antes de reconstruirlas.

    Esto permite ejecutar el script varias veces sin duplicar datos.
*/

IF OBJECT_ID('silver.ventas', 'U') IS NOT NULL
    DROP TABLE silver.ventas;

IF OBJECT_ID('silver.dim_cliente', 'U') IS NOT NULL
    DROP TABLE silver.dim_cliente;

IF OBJECT_ID('silver.dim_producto', 'U') IS NOT NULL
    DROP TABLE silver.dim_producto;

IF OBJECT_ID('silver.rechazos', 'U') IS NOT NULL
    DROP TABLE silver.rechazos;
GO


/*
    Construcción de dim_cliente Silver.

    Se conserva un solo registro por cliente_id.
    En caso de duplicados, se prioriza el registro con mayor completitud.
*/

WITH clientes_preparados AS (
    SELECT
        cliente_id,

        NULLIF(
            LTRIM(RTRIM(cliente_nombre)),
            ''
        ) AS cliente_nombre,

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
FROM clientes_preparados
WHERE fila = 1;
GO


/*
    Construcción de dim_producto Silver.

    Se conserva un solo registro por producto_id.
    Se corrigen valores conocidos como AUT0 y se estandarizan
    las categorías y subcategorías.
*/

WITH productos_preparados AS (
    SELECT
        producto_id,

        NULLIF(
            LTRIM(RTRIM(producto_nombre)),
            ''
        ) AS producto_nombre,

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
            WHEN LOWER(LTRIM(RTRIM(subcategoria))) IN ('básico', 'basico')
                THEN 'Básico'

            WHEN LOWER(LTRIM(RTRIM(subcategoria))) = 'premium'
                THEN 'Premium'

            WHEN LOWER(LTRIM(RTRIM(subcategoria))) = 'full'
                THEN 'Full'

            ELSE 'No informado'
        END AS subcategoria,

        TRY_CONVERT(
            DECIMAL(18,2),
            NULLIF(LTRIM(RTRIM(precio_lista)), '')
        ) AS precio_lista,

        ROW_NUMBER() OVER (
            PARTITION BY producto_id
            ORDER BY
                CASE
                    WHEN producto_nombre IS NOT NULL
                     AND categoria IS NOT NULL
                     AND subcategoria IS NOT NULL
                     AND TRY_CONVERT(
                         DECIMAL(18,2),
                         NULLIF(LTRIM(RTRIM(precio_lista)), '')
                     ) IS NOT NULL
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
FROM productos_preparados
WHERE fila = 1;
GO


/*
    Construcción de ventas Silver.

    Se convierten los campos a sus tipos analíticos.
    TRY_CONVERT devuelve NULL cuando el valor original no se puede
    convertir, por ejemplo cuando monto contiene 'abc'.

    Los registros permanecen en Silver aunque tengan errores.
*/

SELECT
    TRY_CONVERT(INT, venta_id) AS venta_id,

    TRY_CONVERT(DATE, fecha, 103) AS fecha,

    TRY_CONVERT(INT, cliente_id) AS cliente_id,

    TRY_CONVERT(INT, producto_id) AS producto_id,

    TRY_CONVERT(
        DECIMAL(18,2),
        NULLIF(LTRIM(RTRIM(monto)), '')
    ) AS monto,

    TRY_CONVERT(
        INT,
        NULLIF(LTRIM(RTRIM(cantidad)), '')
    ) AS cantidad,

    CASE
        WHEN cliente_id IS NOT NULL
            THEN 1
        ELSE 0
    END AS cliente_informado,

    CASE
        WHEN TRY_CONVERT(DATE, fecha, 103) IS NOT NULL
         AND cliente_id IS NOT NULL
         AND producto_id IS NOT NULL
         AND TRY_CONVERT(
                 DECIMAL(18,2),
                 NULLIF(LTRIM(RTRIM(monto)), '')
             ) IS NOT NULL
         AND TRY_CONVERT(
                 INT,
                 NULLIF(LTRIM(RTRIM(cantidad)), '')
             ) IS NOT NULL
         AND TRY_CONVERT(
                 INT,
                 NULLIF(LTRIM(RTRIM(cantidad)), '')
             ) > 0
        THEN 1
        ELSE 0
    END AS venta_valida

INTO silver.ventas
FROM bronze.ventas;
GO


/*
    Registro de rechazos de ventas.

    Se registra una fila por cada venta que presenta al menos
    un problema de calidad.
*/

SELECT
    TRY_CONVERT(INT, venta_id) AS venta_id,

    TRY_CONVERT(DATE, fecha, 103) AS fecha,

    TRY_CONVERT(INT, cliente_id) AS cliente_id,

    TRY_CONVERT(INT, producto_id) AS producto_id,

    TRY_CONVERT(
        DECIMAL(18,2),
        NULLIF(LTRIM(RTRIM(monto)), '')
    ) AS monto,

    TRY_CONVERT(
        INT,
        NULLIF(LTRIM(RTRIM(cantidad)), '')
    ) AS cantidad,

    CASE
        WHEN fecha IS NULL
          OR LTRIM(RTRIM(fecha)) = ''
          OR TRY_CONVERT(DATE, fecha, 103) IS NULL
            THEN 'Fecha inválida'

        WHEN cliente_id IS NULL
            THEN 'Cliente no informado'

        WHEN producto_id IS NULL
            THEN 'Producto no informado'

        WHEN monto IS NULL
          OR LTRIM(RTRIM(monto)) = ''
            THEN 'Monto nulo'

        WHEN TRY_CONVERT(DECIMAL(18,2), monto) IS NULL
            THEN 'Monto no numérico'

        WHEN cantidad IS NULL
          OR LTRIM(RTRIM(cantidad)) = ''
            THEN 'Cantidad nula'

        WHEN TRY_CONVERT(INT, cantidad) IS NULL
            THEN 'Cantidad no numérica'

        WHEN TRY_CONVERT(INT, cantidad) <= 0
            THEN 'Cantidad no válida'

        ELSE 'Observación'
    END AS motivo

INTO silver.rechazos
FROM bronze.ventas
WHERE
       fecha IS NULL
    OR LTRIM(RTRIM(fecha)) = ''
    OR TRY_CONVERT(DATE, fecha, 103) IS NULL
    OR cliente_id IS NULL
    OR producto_id IS NULL
    OR monto IS NULL
    OR LTRIM(RTRIM(monto)) = ''
    OR TRY_CONVERT(DECIMAL(18,2), monto) IS NULL
    OR cantidad IS NULL
    OR LTRIM(RTRIM(cantidad)) = ''
    OR TRY_CONVERT(INT, cantidad) IS NULL
    OR TRY_CONVERT(INT, cantidad) <= 0;
GO
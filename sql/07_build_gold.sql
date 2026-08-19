USE PruebaIngenieroDatos;
GO

/*
    Construcción de la capa Gold.

    Gold contiene el modelo dimensional para consumo analítico.
    Se utiliza un esquema estrella con dimensiones y una tabla de hechos.
*/


/* Crear esquema Gold */

IF NOT EXISTS (
    SELECT 1
    FROM sys.schemas
    WHERE name = 'gold'
)
BEGIN
    EXEC('CREATE SCHEMA gold');
END;
GO


/* Eliminar tablas Gold para permitir ejecuciones repetibles */

IF OBJECT_ID('gold.fact_ventas', 'U') IS NOT NULL
    DROP TABLE gold.fact_ventas;

IF OBJECT_ID('gold.dim_fecha', 'U') IS NOT NULL
    DROP TABLE gold.dim_fecha;

IF OBJECT_ID('gold.dim_cliente', 'U') IS NOT NULL
    DROP TABLE gold.dim_cliente;

IF OBJECT_ID('gold.dim_producto', 'U') IS NOT NULL
    DROP TABLE gold.dim_producto;
GO


/*
    Dimensión de clientes.

    La clave sustituta se genera con IDENTITY.
    El valor 0 representa un cliente desconocido.
*/

CREATE TABLE gold.dim_cliente (
    cliente_sk INT IDENTITY(1,1) NOT NULL,
    cliente_id INT NOT NULL,
    cliente_nombre VARCHAR(200) NOT NULL,
    segmento VARCHAR(100) NOT NULL,
    region VARCHAR(100) NOT NULL,

    CONSTRAINT pk_gold_dim_cliente
        PRIMARY KEY (cliente_sk),

    CONSTRAINT uq_gold_dim_cliente
        UNIQUE (cliente_id)
);
GO

SET IDENTITY_INSERT gold.dim_cliente ON;

INSERT INTO gold.dim_cliente (
    cliente_sk,
    cliente_id,
    cliente_nombre,
    segmento,
    region
)
VALUES (
    0,
    -1,
    'Cliente desconocido',
    'No informado',
    'No informado'
);

SET IDENTITY_INSERT gold.dim_cliente OFF;
GO

INSERT INTO gold.dim_cliente (
    cliente_id,
    cliente_nombre,
    segmento,
    region
)
SELECT
    cliente_id,
    ISNULL(cliente_nombre, 'No informado'),
    ISNULL(segmento, 'No informado'),
    ISNULL(region, 'No informado')
FROM silver.dim_cliente;
GO


/*
    Dimensión de productos.

    La clave sustituta se genera con IDENTITY.
*/

CREATE TABLE gold.dim_producto (
    producto_sk INT IDENTITY(1,1) NOT NULL,
    producto_id INT NOT NULL,
    producto_nombre VARCHAR(200) NOT NULL,
    categoria VARCHAR(100) NOT NULL,
    subcategoria VARCHAR(100) NOT NULL,
    precio_lista DECIMAL(18,2) NULL,

    CONSTRAINT pk_gold_dim_producto
        PRIMARY KEY (producto_sk),

    CONSTRAINT uq_gold_dim_producto
        UNIQUE (producto_id)
);
GO

INSERT INTO gold.dim_producto (
    producto_id,
    producto_nombre,
    categoria,
    subcategoria,
    precio_lista
)
SELECT
    producto_id,
    ISNULL(producto_nombre, 'No informado'),
    ISNULL(categoria, 'No informado'),
    ISNULL(subcategoria, 'No informado'),
    precio_lista
FROM silver.dim_producto;
GO


/*
    Dimensión de fechas.

    Se genera desde la fecha mínima hasta la fecha máxima
    disponible en las ventas Silver.
*/

CREATE TABLE gold.dim_fecha (
    fecha_sk INT NOT NULL,
    fecha DATE NOT NULL,
    anio SMALLINT NOT NULL,
    trimestre TINYINT NOT NULL,
    mes TINYINT NOT NULL,
    nombre_mes VARCHAR(20) NOT NULL,
    dia TINYINT NOT NULL,

    CONSTRAINT pk_gold_dim_fecha
        PRIMARY KEY (fecha_sk),

    CONSTRAINT uq_gold_dim_fecha
        UNIQUE (fecha)
);
GO

DECLARE @fecha_inicio DATE;
DECLARE @fecha_fin DATE;
DECLARE @fecha_actual DATE;

SELECT
    @fecha_inicio = MIN(fecha),
    @fecha_fin = MAX(fecha)
FROM silver.ventas
WHERE fecha IS NOT NULL;

SET @fecha_actual = @fecha_inicio;

WHILE @fecha_actual <= @fecha_fin
BEGIN
    INSERT INTO gold.dim_fecha (
        fecha_sk,
        fecha,
        anio,
        trimestre,
        mes,
        nombre_mes,
        dia
    )
    VALUES (
        CONVERT(INT, CONVERT(CHAR(8), @fecha_actual, 112)),
        @fecha_actual,
        YEAR(@fecha_actual),
        DATEPART(QUARTER, @fecha_actual),
        MONTH(@fecha_actual),
        DATENAME(MONTH, @fecha_actual),
        DAY(@fecha_actual)
    );

    SET @fecha_actual = DATEADD(DAY, 1, @fecha_actual);
END;
GO


/*
    Tabla de hechos de ventas.

    Solo se incluyen ventas válidas.
    Las ventas sin cliente no se cargan al hecho principal.
*/

CREATE TABLE gold.fact_ventas (
    venta_sk INT IDENTITY(1,1) NOT NULL,
    venta_id INT NOT NULL,
    fecha_sk INT NOT NULL,
    cliente_sk INT NOT NULL,
    producto_sk INT NOT NULL,
    cantidad INT NOT NULL,
    monto DECIMAL(18,2) NOT NULL,

    CONSTRAINT pk_gold_fact_ventas
        PRIMARY KEY (venta_sk),

    CONSTRAINT uq_gold_fact_ventas
        UNIQUE (venta_id),

    CONSTRAINT fk_fact_fecha
        FOREIGN KEY (fecha_sk)
        REFERENCES gold.dim_fecha(fecha_sk),

    CONSTRAINT fk_fact_cliente
        FOREIGN KEY (cliente_sk)
        REFERENCES gold.dim_cliente(cliente_sk),

    CONSTRAINT fk_fact_producto
        FOREIGN KEY (producto_sk)
        REFERENCES gold.dim_producto(producto_sk)
);
GO

INSERT INTO gold.fact_ventas (
    venta_id,
    fecha_sk,
    cliente_sk,
    producto_sk,
    cantidad,
    monto
)
SELECT
    v.venta_id,
    CONVERT(INT, CONVERT(CHAR(8), v.fecha, 112)),
    c.cliente_sk,
    p.producto_sk,
    v.cantidad,
    v.monto
FROM silver.ventas AS v
INNER JOIN gold.dim_cliente AS c
    ON c.cliente_id = v.cliente_id
INNER JOIN gold.dim_producto AS p
    ON p.producto_id = v.producto_id
INNER JOIN gold.dim_fecha AS f
    ON f.fecha = v.fecha
WHERE v.venta_valida = 1
  AND v.venta_id IS NOT NULL
  AND v.fecha IS NOT NULL
  AND v.cantidad > 0
  AND v.monto IS NOT NULL;
GO
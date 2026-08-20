USE PruebaIngenieroDatos;
GO

CREATE SCHEMA bronze;
GO

CREATE TABLE bronze.ventas (
    venta_id    INT NULL,
    fecha       VARCHAR(20) NULL,
    cliente_id  INT NULL,
    producto_id INT NULL,
    monto       VARCHAR(50) NULL,
    cantidad    VARCHAR(50) NULL
);
GO

CREATE TABLE bronze.dim_cliente (
    cliente_id     INT NULL,
    cliente_nombre VARCHAR(200) NULL,
    segmento       VARCHAR(100) NULL,
    region         VARCHAR(100) NULL
);
GO

CREATE TABLE bronze.dim_producto (
    producto_id     INT NULL,
    producto_nombre VARCHAR(200) NULL,
    categoria       VARCHAR(100) NULL,
    subcategoria    VARCHAR(100) NULL,
    precio_lista    VARCHAR(50) NULL
);
GO
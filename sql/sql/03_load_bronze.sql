USE PruebaIngenieroDatos;
GO

BULK INSERT bronze.ventas
FROM 'C:\Proyectos\prueba-tecnica-ingeniero-datos\data\bronze\ventas_bronze.csv'
WITH (
    FORMAT = 'CSV',
    FIRSTROW = 2,
    FIELDQUOTE = '"',
    ROWTERMINATOR = '0x0a',
    TABLOCK
);
GO

BULK INSERT bronze.dim_cliente
FROM 'C:\Proyectos\prueba-tecnica-ingeniero-datos\data\bronze\dim_cliente_bronze.csv'
WITH (
    FORMAT = 'CSV',
    FIRSTROW = 2,
    FIELDQUOTE = '"',
    ROWTERMINATOR = '0x0a',
    TABLOCK
);
GO

BULK INSERT bronze.dim_producto
FROM 'C:\Proyectos\prueba-tecnica-ingeniero-datos\data\bronze\dim_producto_bronze.csv'
WITH (
    FORMAT = 'CSV',
    FIRSTROW = 2,
    FIELDQUOTE = '"',
    ROWTERMINATOR = '0x0a',
    TABLOCK
);
GO
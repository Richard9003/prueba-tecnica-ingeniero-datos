USE PruebaIngenieroDatos;
GO

SELECT COUNT(*) AS total_ventas
FROM bronze.ventas;
GO

SELECT COUNT(*) AS total_clientes
FROM bronze.dim_cliente;
GO

SELECT COUNT(*) AS total_productos
FROM bronze.dim_producto;
GO
# Modelo de datos

## Flujo de datos

```text
ventas_bronze.csv
dim_cliente_bronze.csv
dim_producto_bronze.csv
          │
          ▼
        Bronze
          │
          ▼
        Silver
          │
          ├── silver.ventas
          ├── silver.dim_cliente
          ├── silver.dim_producto
          └── silver.rechazos
          │
          ▼
         Gold
          │
          ├── gold.dim_fecha
          ├── gold.dim_cliente
          ├── gold.dim_producto
          └── gold.fact_ventas
```

## Modelo estrella

```text
              gold.dim_cliente
                      │
                      │ cliente_sk
                      │
gold.dim_fecha ── gold.fact_ventas ── gold.dim_producto
       │                  │                    │
    fecha_sk         cliente_sk           producto_sk
```

## Granularidad

La granularidad de `gold.fact_ventas` es:

> Una fila por venta identificada mediante `venta_id`.

## Claves

- Las dimensiones utilizan claves sustitutas.
- `venta_id` es la clave natural de la venta.
- `fecha_sk` utiliza el formato `YYYYMMDD`.
- Las relaciones entre hechos y dimensiones se validan mediante claves foráneas.
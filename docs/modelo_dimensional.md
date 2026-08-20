# Modelo dimensional Gold

```mermaid
erDiagram
    DIM_FECHA ||--o{ FACT_VENTAS : contiene
    DIM_CLIENTE ||--o{ FACT_VENTAS : realiza
    DIM_PRODUCTO ||--o{ FACT_VENTAS : corresponde

    DIM_FECHA {
        int fecha_sk PK
        date fecha
        smallint anio
        tinyint trimestre
        tinyint mes
        varchar nombre_mes
        tinyint dia
    }

    DIM_CLIENTE {
        int cliente_sk PK
        int cliente_id UK
        varchar cliente_nombre
        varchar segmento
        varchar region
    }

    DIM_PRODUCTO {
        int producto_sk PK
        int producto_id UK
        varchar producto_nombre
        varchar categoria
        varchar subcategoria
        decimal precio_lista
    }

    FACT_VENTAS {
        int venta_sk PK
        int venta_id UK
        int fecha_sk FK
        int cliente_sk FK
        int producto_sk FK
        int cantidad
        decimal monto
    }
```

## Granularidad

Una fila de `FACT_VENTAS` representa una venta válida identificada por `venta_id`.

## Relaciones

- `FACT_VENTAS.fecha_sk` → `DIM_FECHA.fecha_sk`.
- `FACT_VENTAS.cliente_sk` → `DIM_CLIENTE.cliente_sk`.
- `FACT_VENTAS.producto_sk` → `DIM_PRODUCTO.producto_sk`.
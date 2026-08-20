# Prueba técnica - Ingeniero de Datos

## Descripción

Implementación de un flujo de datos tipo Lakehouse/Data Warehouse
utilizando las capas Bronze, Silver y Gold.

El proyecto utiliza:

- SQL Server.
- SQL.
- PowerShell.
- Git y GitHub.
- VS Code.

## Arquitectura

```text
CSV de origen
     │
     ▼
  Bronze
     │
     ▼
  Silver
     │
     ▼
   Gold
     │
     ▼
 Consultas BI
```

## Estructura del proyecto

```text
data/
├── bronze/
├── silver/
└── gold/

sql/
├── 03_load_bronze.sql
├── 03_validate_bronze.sql
├── 04_profile_bronze.sql
├── 05_build_silver.sql
├── 06_validate_silver.sql
├── 07_build_gold.sql
├── 08_validate_gold.sql
└── 09_bi_queries.sql

docs/
└── decisiones_tecnicas.md

export_csv.ps1
```

## Capas

### Bronze

Contiene los archivos originales:

- `ventas_bronze.csv`
- `dim_cliente_bronze.csv`
- `dim_producto_bronze.csv`

Las tablas están almacenadas como:

```text
bronze.ventas
bronze.dim_cliente
bronze.dim_producto
```

### Silver

Contiene los datos tipificados y estandarizados:

```text
silver.ventas
silver.dim_cliente
silver.dim_producto
silver.rechazos
```

En Silver:

- Las fechas se convierten a `DATE`.
- Los montos se convierten a `DECIMAL(18,2)`.
- Las cantidades se convierten a `INT`.
- Los valores inválidos se convierten a `NULL`.
- Los registros se conservan para garantizar trazabilidad.
- Las ventas se marcan con `venta_valida`.
- Los registros problemáticos se registran en `silver.rechazos`.

### Gold

Contiene el modelo dimensional:

```text
gold.dim_cliente
gold.dim_producto
gold.dim_fecha
gold.fact_ventas
```

La tabla de hechos contiene únicamente ventas válidas.

## Reglas de validez

Una venta se considera válida cuando cumple:

- Fecha válida.
- Cliente informado.
- Producto informado.
- Monto numérico.
- Cantidad numérica mayor que cero.

Las ventas inválidas no se eliminan de Silver, pero no se cargan en `gold.fact_ventas`.

## Resultados de validación

- Ventas Bronze: 200.
- Clientes Bronze: 5.
- Productos Bronze: 5.
- Registros Silver de ventas: 200.
- Registros Gold de hechos: 84.
- Unidades vendidas en Gold: 216.
- Monto total de ventas Gold: 2.220.000,00.
- Ventas sin cliente en Gold: 0.
- Ventas sin producto en Gold: 0.
- Ventas sin fecha en Gold: 0.

## Exportación

Los archivos de salida se generan automáticamente mediante:

```text
export_csv.ps1
```

Archivos generados:

```text
data/silver/ventas_silver.csv
data/gold/dim_cliente_gold.csv
data/gold/dim_producto_gold.csv
data/gold/dim_fecha_gold.csv
data/gold/fact_ventas_gold.csv
```

La exportación utiliza `sqlcmd` y autenticación de Windows. No se utiliza `xp_cmdshell`.

## Ejecución

### 1. Crear Bronze

Ejecutar:

```text
sql/03_load_bronze.sql
```

### 2. Perfilar Bronze

Ejecutar:

```text
sql/04_profile_bronze.sql
```

### 3. Construir Silver

Ejecutar:

```text
sql/05_build_silver.sql
```

### 4. Validar Silver

Ejecutar:

```text
sql/06_validate_silver.sql
```

### 5. Construir Gold

Ejecutar:

```text
sql/07_build_gold.sql
```

### 6. Validar Gold

Ejecutar:

```text
sql/08_validate_gold.sql
```

### 7. Ejecutar consultas BI

Ejecutar:

```text
sql/09_bi_queries.sql
```

### 8. Exportar CSV

Desde PowerShell:

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
.\export_csv.ps1
```

## Consultas BI incluidas

- Ventas por mes.
- Top de clientes.
- Ventas por categoría y subcategoría.
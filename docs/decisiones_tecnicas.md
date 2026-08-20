# Prueba técnica de ingeniería de datos

## 1. Objetivo

Construir un flujo de datos con capas Bronze, Silver y Gold a partir de archivos CSV de ventas, clientes y productos.

## 2. Arquitectura

El flujo implementado es:

Bronze → Silver → Gold

Bronze conserva los datos originales. Silver aplica tipificación, estandarización y validaciones. Gold contiene un modelo dimensional para consumo analítico y BI.

## 3. Perfilado de Bronze

Se identificaron los siguientes hallazgos:

- 200 registros de ventas.
- 5 registros de clientes.
- 5 registros de productos.
- 44 ventas con cliente no informado.
- 33 ventas con monto nulo.
- Valores no numéricos en monto, principalmente `abc`.
- 37 ventas con cantidad nula.
- Fechas válidas en el formato `DD/MM/YYYY`.
- Duplicado para `cliente_id = 101`.
- Duplicado para `producto_id = 201`.
- Error de digitación `retial`, normalizado a `Retail`.
- Error de digitación `AUT0`, normalizado a `Auto`.
- No se encontraron claves huérfanas entre ventas y dimensiones.

## 4. Tratamiento Silver

Los datos se transformaron de la siguiente manera:

- Las fechas se convirtieron a tipo `DATE`.
- Los montos se convirtieron a `DECIMAL(18,2)`.
- Las cantidades se convirtieron a `INT`.
- Los valores no convertibles se conservaron como `NULL`.
- Los registros inválidos no se eliminaron de Silver.
- Se agregó la marca `venta_valida`.
- Se agregó la marca `cliente_informado`.
- Los registros con problemas se registraron en `silver.rechazos`.
- Los duplicados de clientes y productos se resolvieron conservando el registro más completo.

No se reemplazaron nulos por cero porque un valor no informado no representa necesariamente un valor cero.

## 5. Tratamiento Gold

Gold se diseñó como un modelo estrella compuesto por:

- `gold.dim_cliente`.
- `gold.dim_producto`.
- `gold.dim_fecha`.
- `gold.fact_ventas`.

Las dimensiones utilizan claves sustitutas generadas por SQL Server mediante `IDENTITY`.

La tabla de hechos contiene solamente ventas válidas, es decir, registros con:

- Fecha válida.
- Cliente informado.
- Producto informado.
- Monto numérico.
- Cantidad numérica mayor que cero.

## 6. Reglas de negocio

Una venta se considera válida cuando puede ser utilizada de forma segura en cálculos analíticos.

Los registros que no cumplen las reglas permanecen disponibles en Silver para trazabilidad, pero no se incluyen en la tabla de hechos Gold.

## 7. Consultas BI

Se incluyeron consultas de ejemplo para:

- Ventas por mes.
- Top de clientes.
- Ventas por categoría y subcategoría.

## 8. Reproducibilidad

Los scripts SQL se organizan por etapa y pueden ejecutarse nuevamente. Las tablas Silver y Gold se eliminan y reconstruyen para evitar duplicidad durante las ejecuciones.

## 9. Exportación de resultados

Los archivos Silver y Gold se exportan automáticamente mediante
el script `export_csv.ps1`, utilizando `sqlcmd` y autenticación
de Windows. La exportación no utiliza `xp_cmdshell`.

Los archivos generados son:

- `data/silver/ventas_silver.csv`
- `data/gold/dim_cliente_gold.csv`
- `data/gold/dim_producto_gold.csv`
- `data/gold/dim_fecha_gold.csv`
- `data/gold/fact_ventas_gold.csv`

Antes de la entrega se validó que los archivos no contengan filas
separadoras ni encabezados duplicados.
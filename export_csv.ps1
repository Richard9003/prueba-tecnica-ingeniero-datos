$ErrorActionPreference = "Stop"

$server = "localhost"
$database = "PruebaIngenieroDatos"
$project = "C:\Proyectos\prueba-tecnica-ingeniero-datos"

$silverPath = "$project\data\silver"
$goldPath = "$project\data\gold"

New-Item -ItemType Directory -Force -Path $silverPath | Out-Null
New-Item -ItemType Directory -Force -Path $goldPath | Out-Null

function Export-QueryToCsv {
    param (
        [string]$Query,
        [string]$OutputFile
    )

    sqlcmd `
        -S $server `
        -d $database `
        -E `
        -Q $Query `
        -s "," `
        -W `
        -h 1 `
        -o $OutputFile

    if ($LASTEXITCODE -ne 0) {
        throw "Error exportando: $OutputFile"
    }

    $content = Get-Content $OutputFile |
        Where-Object {
            $_ -and
            $_ -notmatch "^-+$" -and
            $_ -notmatch "^\(" -and
            $_ -notmatch "rows affected"
        }

    Set-Content -Path $OutputFile -Value $content -Encoding UTF8
}

Export-QueryToCsv `
    "SELECT venta_id, fecha, cliente_id, producto_id, monto, cantidad, cliente_informado, venta_valida FROM silver.ventas ORDER BY venta_id;" `
    "$silverPath\ventas_silver.csv"

Export-QueryToCsv `
    "SELECT cliente_sk, cliente_id, cliente_nombre, segmento, region FROM gold.dim_cliente ORDER BY cliente_sk;" `
    "$goldPath\dim_cliente_gold.csv"

Export-QueryToCsv `
    "SELECT producto_sk, producto_id, producto_nombre, categoria, subcategoria, precio_lista FROM gold.dim_producto ORDER BY producto_sk;" `
    "$goldPath\dim_producto_gold.csv"

Export-QueryToCsv `
    "SELECT fecha_sk, fecha, anio, trimestre, mes, nombre_mes, dia FROM gold.dim_fecha ORDER BY fecha;" `
    "$goldPath\dim_fecha_gold.csv"

Export-QueryToCsv `
    "SELECT venta_sk, venta_id, fecha_sk, cliente_sk, producto_sk, cantidad, monto FROM gold.fact_ventas ORDER BY venta_sk;" `
    "$goldPath\fact_ventas_gold.csv"

Write-Host "Exportacion completada correctamente."
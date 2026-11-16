#Requires -Version 5.1
<#
  tunnel.ps1 - Expone el stack local (Docker) por HTTPS publico con cloudflared.

  Para que sirve: la app iOS corre en un simulador en la nube, asi que
  http://localhost no existe para ella. Este script abre un quick tunnel de
  Cloudflare hacia http://localhost:80 (nginx -> gateway) y te da una URL
  https publica. No abre puertos en el router: la conexion es SALIENTE.

  Uso:
      docker compose up -d          # si aun no esta arriba
      .\tunnel.ps1                  # deja esta ventana abierta
      # URL: https://xxx.trycloudflare.com
      # app: BASE_URL = https://xxx.trycloudflare.com  ->  /api/...
      # Ctrl+C para cerrar el tunel

  La URL cambia cada vez que se reinicia (quick tunnel). Para una URL fija:
  named tunnel con tu dominio (cloudflared tunnel create + CNAME).
#>

param(
  [string]$Url  = "http://localhost:80",
  [string]$OutFile = ".tunnel-url"
)

$ErrorActionPreference = "Stop"

function Get-Cloudflared {
  $cmd = Get-Command cloudflared -ErrorAction SilentlyContinue
  if ($cmd) { return $cmd.Source }

  $tools = Join-Path $env:USERPROFILE "Tools"
  $exe   = Join-Path $tools "cloudflared.exe"
  if (Test-Path $exe) { return $exe }

  New-Item -ItemType Directory -Path $tools -Force | Out-Null
  Write-Host "cloudflared no esta instalado. Descargando a $exe ..." -ForegroundColor Yellow
  Invoke-WebRequest -UseBasicParsing `
    -Uri "https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-windows-amd64.exe" `
    -OutFile $exe
  return $exe
}

# 1. Verificar que el stack responde antes de abrir el tunel.
try {
  $code = (Invoke-WebRequest -UseBasicParsing $Url -TimeoutSec 5).StatusCode
  Write-Host "Stack local OK ($Url -> HTTP $code)" -ForegroundColor Green
} catch {
  Write-Host "AVISO: $Url no responde. Levanta el stack primero:" -ForegroundColor Yellow
  Write-Host "       docker compose up -d" -ForegroundColor Yellow
  Write-Host "El tunel se abre igual, pero la app vera errores 502 hasta que arranque." -ForegroundColor Yellow
}

$cloudflared = Get-Cloudflared
$outPath = Join-Path $PSScriptRoot $OutFile

Write-Host "Abriendo tunel HTTPS hacia $Url (Ctrl+C para cerrarlo)..." -ForegroundColor Cyan
Write-Host ""

& $cloudflared tunnel --url $Url --no-autoupdate 2>&1 | ForEach-Object {
  $line = "$_"
  Write-Host $line
  if ($line -match 'https://[a-z0-9-]+\.trycloudflare\.com') {
    $tunnel = $Matches[0]
    Set-Content -Path $outPath -Value $tunnel -NoNewline
    Write-Host ""
    Write-Host "  URL publica : $tunnel" -ForegroundColor Green
    Write-Host "  API para iOS: $tunnel/api" -ForegroundColor Green
    Write-Host "  Guardada en : $outPath" -ForegroundColor DarkGray
    Write-Host ""
  }
}

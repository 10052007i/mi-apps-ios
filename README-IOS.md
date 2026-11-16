# Velvet &amp; Gilt · iOS

App SwiftUI (iPhone, iOS 17+) que replica el sitio de Velvet &amp; Gilt: carta de cócteles, servicios, cotizador de 3 pasos, seguimiento público y panel de administración. Consume el API Gateway del proyecto `bar-events`.

## Probar en MobAI

El simulador corre en la nube, así que la app necesita una URL pública. Levanta el stack web y el túnel:

```powershell
cd C:\Users\AROM\Projects\bar-events
.\tunnel.ps1
```

Copia la URL `https://....trycloudflare.com` y pégala en la app en **Cuenta → Conexión al API** (o deja la que viene por defecto, que corresponde al último túnel).

Luego compila y comparte el simulador:

```powershell
cd C:\Proyectos\bar-events-ios
builder ios share --duration 30m
```

## Cuentas de prueba

- Admin: `admin@velvetgilt.com` / `admin123`

## Estructura

- `BarEvents/Core`: tema, modelos, cliente HTTP, sesión, cotizador (precios) y formato de moneda/fechas.
- `BarEvents/Views`: vistas públicas (inicio, carta, servicios, cotizador, seguimiento, cuenta).
- `BarEvents/Views/Admin`: dashboard, solicitudes, calendario, clientes, carta y configuración.
- `scripts/gen-project.ps1`: regenera `BarEvents.xcodeproj` listando los `.swift` de `BarEvents/`. Ejecútalo tras agregar archivos.

## Notas

- El túnel de Cloudflare es efímero: si cambia, actualiza la URL en la app.
- El PDF y las solicitudes usan los endpoints públicos `/api/public/...`; el panel usa JWT en Keychain.

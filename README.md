# Velvet & Gilt — Proyecto completo (iOS + Backend + Frontend)

Mixología para eventos. Este repositorio reúne las dos partes del proyecto:

| Carpeta | Contenido |
| --- | --- |
| `BarEvents/`, `BarEvents.xcodeproj/`, `scripts/` | App iOS SwiftUI (carta, cotizador, seguimiento, panel admin) |
| `auth-service/`, `core-service/`, `notification-service/`, `gateway-service/`, `eureka-server/` | Microservicios Spring Boot + Spring Cloud |
| `frontend/` | Angular 22 (sitio público + panel admin) |
| `db/bar-events.sql` | Dump de `auth_db`, `core_db`, `notif_db` |
| `uploads/` | Imágenes de los 16 cócteles |
| `docker/`, `Dockerfile`, `docker-compose.yml` | Despliegue con Docker Compose |
| `carta-cocteleria/` | Carta en PDF |

## App iOS

- Requiere iOS 17+, Xcode. Sin dependencias externas.
- El proyecto se regenera con `pwsh scripts/gen-project.ps1` (añadir archivos `.swift`).
- `builder.json` compila `BarEvents` con la scheme `BarEvents` en MobAI.
- API configurable en la app: `Cuenta → Conexión al API` (por defecto apunta al túnel de desarrollo).
- Detalles en [`README-IOS.md`](README-IOS.md).

## Backend + Frontend

```bash
cp .env.example .env   # completar secretos
docker compose up -d --build
```

Restaurar datos e imágenes:

```bash
docker exec -i bar-events-mysql mysql -uroot -proot < db/bar-events.sql
docker cp uploads/. bar-events-core:/data/uploads/
```

Frontend en <http://localhost>, API en `/api`. Instrucciones completas en [`README-COPIA.md`](README-COPIA.md).

> `.env` no se versiona. Credenciales demo: `admin@velvetgilt.com` / `admin123` (cambiar en producción).

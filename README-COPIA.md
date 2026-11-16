# Copia completa · Velvet & Gilt (backend + frontend + cócteles)

Copia de trabajo del proyecto web `bar-events` preparada para subir a un repositorio Git.
Incluye el stack completo, la base de datos con datos reales y las imágenes de los cócteles.

## Contenido

| Ruta | Descripción |
| --- | --- |
| `auth-service/`, `core-service/`, `gateway-service/`, `notification-service/`, `eureka-server/` | Microservicios Spring Boot (código fuente, sin `target/`) |
| `frontend/` | Angular (código fuente, sin `node_modules/` ni `dist/`) |
| `docker/` + `Dockerfile` + `docker-compose.yml` | Infraestructura del stack |
| `db/bar-events.sql` | Dump de `auth_db`, `core_db` y `notif_db` (16 cócteles, 84 solicitudes) |
| `uploads/` | 16 imágenes de cócteles usadas por el backend (`/data/uploads`) |
| `carta-cocteleria/` | Carta estática de referencia (HTML/CSS + mismas imágenes) |
| `.env` | Configuración local de desarrollo (NO se versiona; ver aviso) |
| `tunnel.ps1` | Túnel HTTPS con Cloudflare para probar desde el simulador iOS |

## Levantar el stack

```powershell
copy .env.example .env   # y completar los secretos
docker compose up -d --build
```

- Frontend: `http://localhost`
- Admin: `admin@velvetgilt.com` / `admin123`
- MySQL: `127.0.0.1:3306` (usuario `root`, password del `.env`)

## Restaurar la base de datos

El contenedor de MySQL debe estar arriba:

```powershell
docker compose up -d mysql
Get-Content .\db\bar-events.sql -Raw | docker exec -i bar-events-mysql mysql -uroot -proot
```

Si el password de root no es `root`, ajústalo en el comando.

## Restaurar las imágenes de los cócteles

```powershell
docker cp .\uploads\. bar-events-core:/data/uploads
```

## Secretos

`.env` contiene `JWT_SECRET`, `INTERNAL_TOKEN`, `MYSQL_ROOT_PASSWORD` y `ADMIN_PASSWORD`.
No debe subirse a un repositorio público. Para producción, genera valores nuevos con
`openssl rand -base64 48`.

`NOTAS-PROYECTO.txt` son notas internas de desarrollo; conviene excluirlo de un repo público.

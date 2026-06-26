# HeltClinica

Sistema de gestão clínica/hospitalar baseado em **ERPNext v15** com módulo **Healthcare**.

## Deploy no Railway (recomendado)

[![Deploy on Railway](https://railway.app/button.svg)](https://railway.app/new/template?template=https://github.com/lucbruna/HeltClinica)

### Passo a passo manual

1. Crie uma conta em [railway.app](https://railway.app)
2. Clique em **+ New Project** → **Deploy from GitHub repo**
3. Conecte o repositório `lucbruna/HeltClinica`
4. Adicione os serviços:

   | Serviço | Tipo | Observação |
   |---------|------|------------|
   | **MySQL** | Database | Railway gerencia automaticamente |
   | **Redis** | Database | Railway gerencia automaticamente |
   | **backend** | Dockerfile | Use `docker/Dockerfile.railway` |

5. Configure as variáveis de ambiente no serviço **backend**:

   ```
   ADMIN_PASSWORD=admin
   SITE_DB_PREFIX=heltclinica
   MYSQL_HOST=${{ mysql.RAILWAY_PRIVATE_DOMAIN }}
   MYSQL_PORT=${{ mysql.RAILWAY_TCP_PROXY_PORT }}
   MYSQL_USER=${{ mysql.MYSQL_USER }}
   MYSQL_PASSWORD=${{ mysql.MYSQL_PASSWORD }}
   REDIS_HOST=${{ redis.RAILWAY_PRIVATE_DOMAIN }}
   REDIS_PORT=${{ redis.RAILWAY_TCP_PROXY_PORT }}
   ```

6. Adicione um volume persistente ao serviço **backend**:
   - **Mount path:** `/home/frappe/frappe-bench/sites`
   - **Name:** `sites-data`

7. Pronto! O Railway vai buildar e iniciar automaticamente.

> **Acesso:** Após o deploy, Railway gera uma URL pública automaticamente.
> **Login:** `Administrator` / `admin`

---

## Instalação Local (Docker Desktop)

### Requisitos

- [Docker Desktop](https://www.docker.com/products/docker-desktop/)
- Git

### Setup

```powershell
.\setup.ps1
```

Isso vai:
1. Construir a imagem Docker personalizada com Healthcare
2. Iniciar todos os containers (MariaDB, Redis, backend, frontend, workers)
3. Criar o site com ERPNext e Healthcare instalados

### Acesso Local

- **URL:** http://localhost:8080
- **Usuário:** Administrator
- **Senha:** admin

### Comandos

| Comando | Descrição |
|---------|-----------|
| `.\iniciar.ps1` | Iniciar o sistema |
| `.\parar.ps1` | Parar o sistema |
| `.\status.ps1` | Ver status dos serviços |
| `docker compose logs -f backend` | Ver logs do backend |

### Serviços (Docker Compose)

| Container | Função |
|-----------|--------|
| heltclinica-db | MariaDB |
| heltclinica-redis-cache | Cache Redis |
| heltclinica-redis-fila | Fila de tarefas Redis |
| heltclinica-backend | Servidor Python (Gunicorn) |
| heltclinica-frontend | Nginx |
| heltclinica-websocket | Socket.IO |
| heltclinica-fila-padrao | Workers fila longa |
| heltclinica-fila-curta | Workers fila curta |
| heltclinica-agendador | Tarefas agendadas |

---

## Apps Instalados

- Frappe v15.113.0
- ERPNext v15.114.0
- Healthcare v15.1.20

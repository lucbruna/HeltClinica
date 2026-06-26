# HeltClinica

Sistema de gestão clínica/hospitalar baseado em **ERPNext v15** com módulo **Healthcare**.

## Requisitos

- [Docker Desktop](https://www.docker.com/products/docker-desktop/)
- Git

## Instalação Rápida

```powershell
.\setup.ps1
```

Isso vai:
1. Construir a imagem Docker personalizada com Healthcare
2. Iniciar todos os containers
3. Criar o site com ERPNext e Healthcare instalados

## Acesso

- **URL:** http://localhost:8080
- **Usuário:** Administrator
- **Senha:** admin

## Comandos

| Comando | Descrição |
|---------|-----------|
| `.\iniciar.ps1` | Iniciar o sistema |
| `.\parar.ps1` | Parar o sistema |
| `.\status.ps1` | Ver status dos serviços |
| `docker compose logs -f backend` | Ver logs do backend |

## Serviços

O sistema roda com os seguintes containers:

- **heltclinica-db** - MariaDB
- **heltclinica-redis-cache** - Cache Redis
- **heltclinica-redis-fila** - Fila de tarefas Redis
- **heltclinica-backend** - Servidor Python (Gunicorn)
- **heltclinica-frontend** - Nginx (requisições web)
- **heltclinica-websocket** - Socket.IO (tempo real)
- **heltclinica-fila-padrao** - Workers de fila longa
- **heltclinica-fila-curta** - Workers de fila curta
- **heltclinica-agendador** - Tarefas agendadas

## Apps Instalados

- Frappe v15.113.0
- ERPNext v15.114.0
- Healthcare v15.1.20

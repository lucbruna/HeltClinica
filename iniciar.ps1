Write-Host "Iniciando HeltClinica..." -ForegroundColor Cyan
docker compose up -d
Write-Host ""
Write-Host "HeltClinica disponivel em: http://localhost:8080" -ForegroundColor Green
Write-Host "Email: Administrator | Senha: admin" -ForegroundColor Gray

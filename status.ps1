Write-Host "HeltClinica - Status" -ForegroundColor Cyan
Write-Host "====================" -ForegroundColor Cyan
Write-Host ""

docker compose ps

Write-Host ""
Write-Host "Para ver logs:" -ForegroundColor Gray
Write-Host "  docker compose logs -f heltclinica-backend" -ForegroundColor Gray
Write-Host "  docker compose logs heltclinica-criar-site (se ainda estiver criando)" -ForegroundColor Gray

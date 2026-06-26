Write-Host "========================================" -ForegroundColor Cyan
Write-Host "   HeltClinica - ERP Saude v15" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "[1/4] Verificando Docker..." -ForegroundColor Yellow
try {
    $dockerVersion = docker --version
    Write-Host "  OK: $dockerVersion" -ForegroundColor Green
} catch {
    Write-Host "  ERRO: Docker nao encontrado. Instale Docker Desktop." -ForegroundColor Red
    exit 1
}

try {
    $composeVersion = docker compose version
    Write-Host "  OK: $composeVersion" -ForegroundColor Green
} catch {
    Write-Host "  ERRO: Docker Compose nao encontrado." -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "[2/4] Construindo imagem personalizada com Healthcare..." -ForegroundColor Yellow
docker build -t heltclinica:v15 .

Write-Host ""
Write-Host "[3/4] Iniciando containers..." -ForegroundColor Yellow
docker compose up -d

Write-Host ""
Write-Host "[4/4] Aguardando criacao do site..." -ForegroundColor Yellow
Write-Host "  Isso leva de 3 a 10 minutos..." -ForegroundColor DarkYellow

$timeout = 600
$decorrido = 0
while ($decorrido -lt $timeout) {
    $status = docker inspect heltclinica-criar-site --format '{{.State.Status}}' 2>$null
    if ($status -eq "exited") {
        $codigoSaida = docker inspect heltclinica-criar-site --format '{{.State.ExitCode}}' 2>$null
        if ($codigoSaida -eq "0") {
            Write-Host ""
            Write-Host "  Site criado com sucesso!" -ForegroundColor Green
            break
        } else {
            Write-Host ""
            Write-Host "  ERRO: Criacao do site falhou (codigo $codigoSaida)." -ForegroundColor Red
            Write-Host "  Verifique os logs: docker compose logs heltclinica-criar-site" -ForegroundColor Yellow
            break
        }
    }
    Start-Sleep -Seconds 10
    $decorrido += 10
    Write-Host "  Aguardando... ($decorrido segundos)" -ForegroundColor DarkGray
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  HeltClinica pronto!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Acesse em: http://localhost:8080" -ForegroundColor White
Write-Host "Email: Administrator" -ForegroundColor White
Write-Host "Senha: admin" -ForegroundColor White
Write-Host ""
Write-Host "Comandos faceis:" -ForegroundColor Gray
Write-Host "  .\start.ps1          - Iniciar" -ForegroundColor Gray
Write-Host "  .\stop.ps1           - Parar" -ForegroundColor Gray
Write-Host "  .\status.ps1         - Ver status" -ForegroundColor Gray
Write-Host "  docker compose logs -f backend  - Ver logs" -ForegroundColor Gray
Write-Host ""

Write-Host "=== Starting Cloudflare Tunnel ===" -ForegroundColor Cyan
Write-Host ""

$backendPort = 3000

Write-Host "Make sure your backend is running on port $backendPort" -ForegroundColor Yellow
Write-Host "If not, run: cd lib\backend; npm start" -ForegroundColor Yellow
Write-Host ""

$response = Read-Host "Press Enter to start Cloudflare tunnel (or Ctrl+C to cancel)"

Write-Host ""
Write-Host "Starting tunnel..." -ForegroundColor Green
Write-Host ""

cloudflared tunnel --url http://localhost:$backendPort


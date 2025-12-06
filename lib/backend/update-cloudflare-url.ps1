param(
    [Parameter(Mandatory=$true)]
    [string]$CloudflareUrl
)

Write-Host "Updating configuration with Cloudflare Tunnel URL: $CloudflareUrl" -ForegroundColor Green
Write-Host ""

$backendEnvPath = Join-Path $PSScriptRoot ".env"
$flutterEnvPath = Join-Path $PSScriptRoot ".." ".." ".env"

if (-not (Test-Path $backendEnvPath)) {
    Write-Host "Backend .env file not found at: $backendEnvPath" -ForegroundColor Red
    exit 1
}

$redirectUri = "$CloudflareUrl/api/oauth/callback"

Write-Host "Updating backend .env..." -ForegroundColor Cyan
$backendContent = Get-Content $backendEnvPath
$backendContent = $backendContent -replace 'GOOGLE_REDIRECT_URI=.*', "GOOGLE_REDIRECT_URI=$redirectUri"
$backendContent | Set-Content $backendEnvPath
Write-Host "  ✓ GOOGLE_REDIRECT_URI=$redirectUri" -ForegroundColor Green

if (Test-Path $flutterEnvPath) {
    Write-Host "Updating Flutter .env..." -ForegroundColor Cyan
    $flutterContent = Get-Content $flutterEnvPath
    
    if ($flutterContent -match 'API_BASE_URL=') {
        $flutterContent = $flutterContent -replace 'API_BASE_URL=.*', "API_BASE_URL=$CloudflareUrl"
    } else {
        $flutterContent += "`nAPI_BASE_URL=$CloudflareUrl"
    }
    
    $flutterContent | Set-Content $flutterEnvPath
    Write-Host "  ✓ API_BASE_URL=$CloudflareUrl" -ForegroundColor Green
} else {
    Write-Host "Flutter .env not found. Please create it manually." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Configuration updated!" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. Update Google Cloud Console:" -ForegroundColor White
Write-Host "   Add redirect URI: $redirectUri" -ForegroundColor White
Write-Host "2. Restart backend: npm start" -ForegroundColor White
Write-Host "3. Restart Flutter app" -ForegroundColor White


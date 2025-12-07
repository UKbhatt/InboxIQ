param(
    [Parameter(Mandatory=$true)]
    [string]$CloudflareUrl
)

$cloudflareUrl = $CloudflareUrl.Trim().TrimEnd('/')

Write-Host "=== Updating Cloudflare URL ===" -ForegroundColor Cyan
Write-Host ""

$rootEnv = ".\.env"
$backendEnv = ".\lib\backend\.env"

if (-not (Test-Path $rootEnv)) {
    Write-Host "ERROR: .env file not found at $rootEnv" -ForegroundColor Red
    exit 1
}

if (-not (Test-Path $backendEnv)) {
    Write-Host "ERROR: Backend .env file not found at $backendEnv" -ForegroundColor Red
    exit 1
}

Write-Host "Updating Flutter .env file..." -ForegroundColor Yellow
$rootContent = Get-Content $rootEnv
$newRootContent = @()
foreach ($line in $rootContent) {
    if ($line -match '^API_BASE_URL=') {
        $newRootContent += "API_BASE_URL=$cloudflareUrl"
    } else {
        $newRootContent += $line
    }
}
$newRootContent | Set-Content $rootEnv
Write-Host "✓ Updated API_BASE_URL=$cloudflareUrl" -ForegroundColor Green

Write-Host ""
Write-Host "Updating Backend .env file..." -ForegroundColor Yellow
$backendContent = Get-Content $backendEnv
$newBackendContent = @()
foreach ($line in $backendContent) {
    if ($line -match '^GOOGLE_REDIRECT_URI=') {
        $newBackendContent += "GOOGLE_REDIRECT_URI=$cloudflareUrl/api/oauth/callback"
    } else {
        $newBackendContent += $line
    }
}
$newBackendContent | Set-Content $backendEnv
Write-Host "✓ Updated GOOGLE_REDIRECT_URI=$cloudflareUrl/api/oauth/callback" -ForegroundColor Green

Write-Host ""
Write-Host "=== IMPORTANT ===" -ForegroundColor Yellow
Write-Host "1. Update Google Cloud Console redirect URI to: $cloudflareUrl/api/oauth/callback" -ForegroundColor Yellow
Write-Host "2. Restart your backend server (Ctrl+C then npm start)" -ForegroundColor Yellow
Write-Host "3. Restart your Flutter app" -ForegroundColor Yellow
Write-Host ""


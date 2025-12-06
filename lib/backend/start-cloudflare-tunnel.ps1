Write-Host "Starting Cloudflare Tunnel for InboxIQ Backend..." -ForegroundColor Green
Write-Host ""

$cloudflaredPath = Get-Command cloudflared -ErrorAction SilentlyContinue

if (-not $cloudflaredPath) {
    Write-Host "cloudflared not found in PATH." -ForegroundColor Yellow
    Write-Host "Please install cloudflared:" -ForegroundColor Yellow
    Write-Host "1. Download from: https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/install-and-setup/installation/" -ForegroundColor Yellow
    Write-Host "2. Or install via: choco install cloudflared" -ForegroundColor Yellow
    exit 1
}

Write-Host "Choose tunnel mode:" -ForegroundColor Cyan
Write-Host "1. Quick tunnel (temporary URL, no domain needed)" -ForegroundColor White
Write-Host "2. Named tunnel (persistent URL, requires domain setup)" -ForegroundColor White
Write-Host ""
$choice = Read-Host "Enter choice (1 or 2)"

if ($choice -eq "1") {
    Write-Host ""
    Write-Host "Starting quick tunnel..." -ForegroundColor Cyan
    Write-Host "This will create a temporary URL that changes each time." -ForegroundColor Yellow
    Write-Host "Copy the HTTPS URL shown and update your .env files." -ForegroundColor Yellow
    Write-Host ""
    cloudflared tunnel --url http://localhost:3000
} elseif ($choice -eq "2") {
    $tunnelName = Read-Host "Enter tunnel name (e.g., inboxiq-backend)"
    Write-Host ""
    Write-Host "Starting named tunnel: $tunnelName" -ForegroundColor Cyan
    Write-Host "Make sure you've configured the tunnel and DNS records." -ForegroundColor Yellow
    Write-Host ""
    cloudflared tunnel run $tunnelName
} else {
    Write-Host "Invalid choice. Exiting." -ForegroundColor Red
    exit 1
}


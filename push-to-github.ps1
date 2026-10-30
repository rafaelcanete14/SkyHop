param(
    [string]$RepoName = "SkyHop"
)

$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot

$remoteUrl = "https://github.com/rafaelcanete14/$RepoName.git"
Write-Host "==> Preparing local Git repository for $remoteUrl" -ForegroundColor Cyan

if (-not (Test-Path ".git")) {
    git init -b main
}

$existingName = git config user.name 2>$null
if (-not $existingName) {
    git config user.name "rafaelcanete14"
    git config user.email "rafaelcanete14@users.noreply.github.com"
}

git add -A
$status = git status --porcelain
if ($status) {
    git commit -m "Build Sky Hop iOS 18 game + GitHub Actions IPA pipeline"
}

$currentOrigin = git remote get-url origin 2>$null
if ($LASTEXITCODE -ne 0) {
    git remote add origin $remoteUrl
} elseif ($currentOrigin -ne $remoteUrl) {
    git remote set-url origin $remoteUrl
}

Write-Host "==> Pushing to $remoteUrl (sign in via the GitHub browser popup if prompted)..." -ForegroundColor Green
git branch -M main
git push -u origin main

Write-Host ""
Write-Host "Done! Open GitHub Actions to watch your IPA build:" -ForegroundColor Yellow
Write-Host "  https://github.com/rafaelcanete14/$RepoName/actions" -ForegroundColor Cyan
Write-Host "Once green (~2-3 mins), download SkyHop.ipa from:" -ForegroundColor Yellow
Write-Host "  https://github.com/rafaelcanete14/$RepoName/releases/latest" -ForegroundColor Cyan

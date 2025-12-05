# Script para restaurar el applicationId original

Write-Host "===================================================" -ForegroundColor Cyan
Write-Host "  RESTAURANDO APPLICATIONID ORIGINAL" -ForegroundColor Cyan
Write-Host "===================================================" -ForegroundColor Cyan
Write-Host ""

$gradlePath = "android\app\build.gradle.kts"
$backupPath = "$gradlePath.backup"

if (Test-Path $backupPath) {
    Copy-Item $backupPath $gradlePath -Force
    Remove-Item $backupPath -Force
    Write-Host "OK - applicationId restaurado a com.gaspar.echo_world" -ForegroundColor Green
    Write-Host ""
    Write-Host "Ahora ejecuta:" -ForegroundColor Yellow
    Write-Host "  flutter clean" -ForegroundColor White
    Write-Host "  flutter run --flavor development --target lib/main_development.dart" -ForegroundColor White
    Write-Host ""
} else {
    Write-Host "ERROR - No se encontro el backup. El applicationId ya esta restaurado." -ForegroundColor Red
}

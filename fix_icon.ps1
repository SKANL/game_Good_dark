# Script de Diagnostico y Solucion Agresiva para Icono de Android
# Este script cambia temporalmente el applicationId para forzar a Android a reconocer la app como nueva

Write-Host "===================================================" -ForegroundColor Cyan
Write-Host "  DIAGNOSTICO Y SOLUCION DE ICONO - PROYECTO CASANDRA" -ForegroundColor Cyan
Write-Host "===================================================" -ForegroundColor Cyan
Write-Host ""

# 1. Verificar que Icon_echo.png existe
Write-Host "[1/6] Verificando Icon_echo.png..." -ForegroundColor Yellow
if (Test-Path "assets\icon\Icon_echo.png") {
    $sourceSize = (Get-Item "assets\icon\Icon_echo.png").Length
    Write-Host "  OK - Icon_echo.png encontrado ($sourceSize bytes)" -ForegroundColor Green
} else {
    Write-Host "  ERROR - Icon_echo.png no encontrado" -ForegroundColor Red
    exit 1
}

# 2. Verificar iconos en mipmap
Write-Host "[2/6] Verificando iconos en carpetas mipmap..." -ForegroundColor Yellow
$densities = @("mdpi", "hdpi", "xhdpi", "xxhdpi", "xxxhdpi")
$allCorrect = $true

foreach ($density in $densities) {
    $path = "android\app\src\main\res\mipmap-$density\ic_launcher.png"
    if (Test-Path $path) {
        $size = (Get-Item $path).Length
        if ($size -eq $sourceSize) {
            Write-Host "  OK - mipmap-$density/ic_launcher.png correcto ($size bytes)" -ForegroundColor Green
        } else {
            Write-Host "  ERROR - mipmap-$density/ic_launcher.png incorrecto ($size bytes, esperado $sourceSize)" -ForegroundColor Red
            $allCorrect = $false
        }
    } else {
        Write-Host "  ERROR - mipmap-$density/ic_launcher.png NO EXISTE" -ForegroundColor Red
        $allCorrect = $false
    }
}

if (-not $allCorrect) {
    Write-Host ""
    Write-Host "  Copiando Icon_echo.png a todas las carpetas..." -ForegroundColor Yellow
    foreach ($density in $densities) {
        Copy-Item "assets\icon\Icon_echo.png" "android\app\src\main\res\mipmap-$density\ic_launcher.png" -Force
        Copy-Item "assets\icon\Icon_echo.png" "android\app\src\main\res\mipmap-$density\ic_launcher_round.png" -Force
    }
    Write-Host "  OK - Iconos copiados" -ForegroundColor Green
}

# 3. Cambiar temporalmente el applicationId
Write-Host "[3/6] Modificando applicationId temporalmente..." -ForegroundColor Yellow
$gradlePath = "android\app\build.gradle.kts"
$gradleContent = Get-Content $gradlePath -Raw

# Backup
Copy-Item $gradlePath "$gradlePath.backup" -Force

# Cambiar applicationId
$newContent = $gradleContent -replace 'applicationId = "com.gaspar.echo_world"', 'applicationId = "com.gaspar.echo_world_new"'
Set-Content $gradlePath $newContent -NoNewline

Write-Host "  OK - applicationId cambiado a com.gaspar.echo_world_new" -ForegroundColor Green
Write-Host "  INFO - Backup guardado en build.gradle.kts.backup" -ForegroundColor Cyan

# 4. Limpiar build
Write-Host "[4/6] Limpiando build..." -ForegroundColor Yellow
flutter clean | Out-Null
Write-Host "  OK - Build limpiado" -ForegroundColor Green

# 5. Instrucciones para el usuario
Write-Host ""
Write-Host "===================================================" -ForegroundColor Cyan
Write-Host "  PROXIMOS PASOS" -ForegroundColor Cyan
Write-Host "===================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "[5/6] Ejecuta ahora:" -ForegroundColor Yellow
Write-Host "  flutter run --flavor development --target lib/main_development.dart" -ForegroundColor White
Write-Host ""
Write-Host "  Esto instalara la app con un NUEVO applicationId," -ForegroundColor Cyan
Write-Host "  forzando a Android a tratarla como una app completamente nueva." -ForegroundColor Cyan
Write-Host ""
Write-Host "[6/6] Despues de verificar el icono:" -ForegroundColor Yellow
Write-Host "  1. Si el icono es correcto, ejecuta:" -ForegroundColor White
Write-Host "     .\restore_app_id.ps1" -ForegroundColor White
Write-Host ""
Write-Host "  2. Si el icono sigue mal, avisame para investigar mas." -ForegroundColor White
Write-Host ""
Write-Host "===================================================" -ForegroundColor Cyan

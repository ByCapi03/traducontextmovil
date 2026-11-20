# Ejecuta la app en el movil conectado por USB contra el backend local del PC.
# `adb reverse` hace que el 127.0.0.1:8000 del movil llegue al 127.0.0.1:8000 del PC: no hace
# falta la IP ni abrir el firewall, y la web en Edge sigue usando el mismo backend a la vez.
#
# Uso (desde traducontextmovil):  .\scripts\movil_usb.ps1
# Requisitos: backend arrancado en el puerto 8000 y depuracion USB activada en el movil.

$ErrorActionPreference = 'Stop'
$puerto = 8000

$adb = (Get-Command adb -ErrorAction SilentlyContinue).Source
if (-not $adb) {
    foreach ($candidato in @("$env:ANDROID_HOME\platform-tools\adb.exe", "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe", 'C:\AndroidSDK\platform-tools\adb.exe')) {
        if ($candidato -and (Test-Path $candidato)) { $adb = $candidato; break }
    }
}
if (-not $adb) { throw 'No se encontro adb. Instala Android SDK Platform-Tools o agrega adb al PATH.' }

$dispositivos = & $adb devices | Select-String -Pattern "`tdevice$"
if (-not $dispositivos) { throw 'No hay ningun movil conectado por USB (o falta autorizar la depuracion USB en el movil).' }
if (@($dispositivos).Count -gt 1) { Write-Warning 'Hay varios dispositivos: flutter preguntara en cual ejecutar.' }

& $adb reverse "tcp:$puerto" "tcp:$puerto" | Out-Null
Write-Host "adb reverse activo: el movil usa http://127.0.0.1:$puerto como el PC."

$raiz = Split-Path -Parent $PSScriptRoot
Push-Location $raiz
try {
    flutter run --dart-define-from-file=config/api_usb.json
} finally {
    Pop-Location
}

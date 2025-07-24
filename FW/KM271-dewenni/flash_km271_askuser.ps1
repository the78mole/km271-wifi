# Verfügbare COM-Ports ermitteln und anzeigen
$comPorts = [System.IO.Ports.SerialPort]::GetPortNames() | Sort-Object

if ($comPorts.Count -eq 0) {
    Write-Host "❌ Keine COM-Ports gefunden!" -ForegroundColor Red
    exit 1
}

Write-Host "🔌 Verfügbare COM-Ports:"
$comPorts | ForEach-Object { Write-Host $_ }


# COM-Port-Nummer abfragen
do {
    $comNum = Read-Host "Bitte geben Sie die COM-Port-Nummer ein (z.B. 6 für COM6)"
    if ($comNum -match '^\d+$') {
        $COMPORT = "COM$comNum"
        if ($comPorts -notcontains $COMPORT) {
            Write-Host "⚠️  COM$comNum wurde nicht in der Liste gefunden. Trotzdem versuchen? (j/n)"
            $answer = Read-Host
            if ($answer -ne 'j') {
                $COMPORT = $null
            }
        }
    } else {
        Write-Host "❌ Ungültige Eingabe. Bitte nur eine Zahl eingeben!" -ForegroundColor Red
    }
} until ($COMPORT)

$BAUDRATE = 921600
$FWFILE = "buderus_km271_esp32_flash_v5.3.1.bin"

Write-Host ""
Write-Host "COM Port: $COMPORT"
Write-Host "Baudrate: $BAUDRATE"
Write-Host "Firmware: $FWFILE"
Write-Host ""

while ($true) {
    $Host.UI.RawUI.FlushInputBuffer()

    Write-Host "#########################################################"
    Write-Host "Druecken Sie eine beliebige Taste zum Fortfahren oder 'x' zum Beenden..."
    $key = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

    if ($key.Character -eq "x") {
        Write-Host "Programm abgebrochen."
        break
    }

    Write-Host "#########################################################"
    Write-Host "Hier die Informationen zum Target:"
    python -m esptool --chip esp32 --port $COMPORT --baud $BAUDRATE flash_id

    Write-Host "#########################################################"
    python -m esptool --chip esp32 --port $COMPORT --baud $BAUDRATE write_flash -z 0x0 $FWFILE
}

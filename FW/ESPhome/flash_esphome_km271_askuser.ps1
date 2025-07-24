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

# $COMPORT = "COM8"
$BAUDRATE = 921600
$FWFILE = "km271-for-friends-esp32_0.1.4.factory.bin"
$esptool = "esptool.exe"

Write-Host ""
Write-Host "COM Port: $COMPORT"
Write-Host "Baudrate: $BAUDRATE"
Write-Host "Firmware: $FWFILE"
Write-Host "ESPTOOL :$esptool"


while($true) {
#  C:\Users\danie\.platformio\penv\Scripts\platformio.exe run --target upload
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
	#C:\Users\danie\Tools\esptool-v3.3.2-win64\esptool.exe --chip esp32 --port $COMPORT --baud $BAUDRATE flash_id
	esptool.exe --chip esp32 --port $COMPORT --baud $BAUDRATE flash_id

	Write-Host "#########################################################"
	
	#C:\Users\danie\Tools\esptool-v3.3.2-win64\esptool.exe --chip esp32 --port $COMPORT --baud $BAUDRATE write_flash -z 0x0 $FWFILE
	esptool.exe --chip esp32 --port $COMPORT --baud $BAUDRATE write_flash -z 0x0 $FWFILE
}
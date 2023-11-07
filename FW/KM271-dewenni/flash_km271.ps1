$COMPORT = "COM3"
$BAUDRATE = 921600
$FWFILE = "buderus_km271_esp32_flash_v3.2.4.bin"

Write-Host ""
Write-Host "COM Port: $COMPORT"
Write-Host "Baudrate: $BAUDRATE"
Write-Host "Firmware: $FWFILE"
Write-Host ""


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
	C:\Users\danie\Tools\esptool-v3.3.2-win64\esptool.exe --chip esp32 --port $COMPORT --baud $BAUDRATE flash_id

	Write-Host "#########################################################"
	
	C:\Users\danie\Tools\esptool-v3.3.2-win64\esptool.exe --chip esp32 --port $COMPORT --baud $BAUDRATE write_flash -z 0x0 $FWFILE
}
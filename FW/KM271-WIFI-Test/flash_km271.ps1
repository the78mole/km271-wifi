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
	C:\Users\danie\.platformio\penv\Scripts\platformio.exe run --target upload --environment esp32dev
	#C:\Users\danie\Tools\esptool-v3.3.2-win64\esptool.exe --chip esp32 --port COM8 --baud 921600 write_flash -z 0x0 km271-for-friends-factory.bin
}
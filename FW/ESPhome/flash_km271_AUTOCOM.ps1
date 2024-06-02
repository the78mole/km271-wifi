Write-Output ""
Write-Output ""

# Get all COM port instances using WMI
$comPorts = Get-WmiObject Win32_PnPEntity | Where-Object { $_.Name -like "*COM*" }

# Filter to find COM ports with either CP2102 or CH340 drivers
$filteredPorts = @($comPorts | Where-Object { $_.Caption -like "*CP2102*" -or $_.Caption -like "*CH340*" -or $_.Name -like "*CP2102*" -or $_.Name -like "*CH340*" })

foreach ($fport in $filteredPorts) {
	Write-Output "Port: '$($fport.Name)', '$($fport.Id)', '$($fport.Description)'"
	$portMembers = $fport | Get-Member -MemberType Properties
	foreach ($member in $portMembers) {
		$propName = $member.Name
		$propValue = $fport.$propName
		Write-Output "Member '$propName':'$propValue'"
	}
        
}

Write-Output ""
Write-Output ""

# Check if any matching COM ports are found
if ($filteredPorts -ne $null -and $filteredPorts.Count -gt 0) {
    Write-Output "Found the following COM Ports:"
    $i = 1
    foreach ($port in $filteredPorts) {
        Write-Output "$i. $($port.Name)"
        $i++
    }

    # Ask user to select a port if more than one is found
    if ($filteredPorts.Count -gt 1) {
        $selectedPortIndex = Read-Host "Please enter the number of the COM port you want to use (1-$($filteredPorts.Count))"
        $selectedPort = $filteredPorts[$selectedPortIndex - 1]
        Write-Output "You selected: $($selectedPort.Name)"
    } else {
		Write-Output ""
        Write-Output "Automatically selected the only found port: $($filteredPorts[0].Name)"
		$selectedPort = $filteredPorts[0].Name
    }
} else {
    Write-Output "No COM Ports with CP2102 or CH340 found."
	Write-Output "Here is the list of all found COM ports:"
	foreach ($port in $comPorts) {
        # Extract the COM port number from the Name property
        Write-Output "COM Port: $($port.Name)"
    }
}

# Regulären Ausdruck verwenden, um 'COM7' zu extrahieren
$matches = [regex]::Match($selectedPort, 'COM\d+')

# Überprüfen, ob ein Match gefunden wurde und den Wert ausgeben
if ($matches.Success) {
    Write-Output "Using COM port: $($matches.Value)"
} else {
    Write-Output "No COM port found in the string."
}

$COMPORT = "$($matches.Value)"
$BAUDRATE = 921600
$FWFILE = "km271-for-friends-factory.bin"

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
	C:\Users\danie\Tools\esptool-v3.3.2-win64\esptool.exe --chip esp32 --baud $BAUDRATE flash_id

	Write-Host "#########################################################"
	
	C:\Users\danie\Tools\esptool-v3.3.2-win64\esptool.exe --chip esp32 --baud $BAUDRATE write_flash -z 0x0 $FWFILE
}

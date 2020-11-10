$region = "East US"
$AutomationAccountRG = "Automation-AccountsRG"
$AutomationAccountName = "art-automation-account"
$classStartScheduleName = "class-start-schedule"
$classStopScheduleName = "class-stop-schedule"
$TimeZone = ([System.TimeZoneInfo]::Local).Id
$basePath = "C:\Users\asmith\Documents\code\Azure-Playground\RunbookStuff"

# Manual Step Create Runas Account, choose 'art-automation-account-->Account Settings-->Run as accounts' (note expiration date on calendar)
# renew the certificate https://docs.microsoft.com/en-us/azure/automation/manage-runas-account?WT.mc_id=Portal-Microsoft_Azure_Automation#cert-renewal

# Manual Step Import Modules, choose 'art-automation-account-->Modules-->Browse Gallery'
# Az.accounts
# Az.compute
# Az.Automation
# Az.Resources

Write-Output "------------------------ Create Automation Account ------------------------"
New-AzResourceGroup -Name $AutomationAccountRG -Location $region -Force
New-AzAutomationAccount -ResourceGroupName $AutomationAccountRG -Name $AutomationAccountName -Location $region

Write-Output "------------------------ Import Modules into Automation Account ------------------------"
$moduleName = "Az.Compute"
$moduleVersion = "1.7.3"
New-AzAutomationModule -AutomationAccountName  $AutomationAccountName -ResourceGroupName $AutomationAccountRG -Name $moduleName -ContentLinkUri "https://www.powershellgallery.com/api/v2/package/$moduleName/$moduleVersion"

Write-Output "------------------------ Create Automation Account Variables ------------------------"
if (Get-AzAutomationVariable -AutomationAccountName $AutomationAccountName -ResourceGroupName $AutomationAccountRG -Name 'Internal_AutomationAccountName' -ErrorAction Ignore) {
    Set-AzAutomationVariable -AutomationAccountName $AutomationAccountName -ResourceGroupName $AutomationAccountRG -Name 'Internal_AutomationAccountName' -Value $AutomationAccountName -Encrypted $false
}
else {
    New-AzAutomationVariable -AutomationAccountName $AutomationAccountName -ResourceGroupName $AutomationAccountRG -Name 'Internal_AutomationAccountName' -Value $AutomationAccountName -Encrypted $false
}
if (Get-AzAutomationVariable -AutomationAccountName $AutomationAccountName -ResourceGroupName $AutomationAccountRG -Name 'Internal_Automation-AccountsRG' -ErrorAction Ignore) {
    Set-AzAutomationVariable -AutomationAccountName $AutomationAccountName -ResourceGroupName $AutomationAccountRG -Name 'Internal_Automation-AccountsRG' -Value $AutomationAccountRG -Encrypted $false
}
else {
    New-AzAutomationVariable -AutomationAccountName $AutomationAccountName -ResourceGroupName $AutomationAccountRG -Name 'Internal_Automation-AccountsRG' -Value $AutomationAccountRG -Encrypted $false
}

Write-Output "------------------------ Create Schedules ------------------------"
$startTime = (Get-Date "9:50 AM").AddDays(1)
$startDescription = "triggers 10 minutes before classs start"
New-AzAutomationSchedule -AutomationAccountName $AutomationAccountName -Name $classStartScheduleName -StartTime $startTime -DayInterval 1 -ResourceGroupName $AutomationAccountRG -Description $startDescription -TimeZone $TimeZone

$stopTime = (Get-Date "4:00 PM").AddDays(1)
$stopDescription = "triggers 2 hours after classs is over (end of lab time)"
New-AzAutomationSchedule -AutomationAccountName $AutomationAccountName -Name $classStopScheduleName -StartTime $stopTime -DayInterval 1 -ResourceGroupName $AutomationAccountRG -Description $stopDescription -TimeZone $TimeZone

Write-Output "------------------------ Create Runbooks ------------------------"
function create-runbookFile ($path){
    $TempFile = "$env:Temp\tmp.ps1"
    $authHeader = get-content "C:\Users\asmith\Documents\code\Azure-Playground\RunbookStuff\Runbooks\AuthenticationHeader.ps1" -raw
    $script = (get-content $path) | Select -Skip 1 | Select -SkipLast 1
    $finalContent = $script.replace("# Insert Auth Here",$authHeader)
    Set-Content $TempFile $finalContent
    $TempFile
}
$class_StartAllVMsRbName = "class_StartAllVms"
$class_StopAllVMsRbName = "class_StopAllVms"
$class_StartAllVmsps1 = "$basePath\Runbooks\class_StartAllVms.ps1"
$class_StopAllVmsps1 = "$basePath\Runbooks\class_StopAllVms.ps1"
Import-AzAutomationRunbook -Path (create-runbookFile $class_StartAllVmsps1) -ResourceGroup $AutomationAccountRG -AutomationAccountName $AutomationAccountName -Type PowerShell -Name $class_StartAllVMsRbName -Published -Force
Import-AzAutomationRunbook -Path (create-runbookFile $class_StopAllVmsps1) -ResourceGroup $AutomationAccountRG -AutomationAccountName $AutomationAccountName -Type PowerShell -Name $class_StopAllVMsRbName -Published -Force
# Import-AzAutomationRunbook -Path (create-runbookFile "$basePath\Runbooks\Start-Stop-All-VMs-by-RG-Tag.ps1") -ResourceGroup $AutomationAccountRG -AutomationAccountName $AutomationAccountName -Type PowerShell -Name "Start-Stop-All-VMs-by-RG-Tag" -Published -Force
Import-AzAutomationRunbook -Path (create-runbookFile "$basePath\Runbooks\Start-Stop-Specific-VMs-by-VM-Tags-and-RG-Tag.ps1") -ResourceGroup $AutomationAccountRG -AutomationAccountName $AutomationAccountName -Type PowerShell -Name "Start-Stop-Specific-VMs-by-VM-Tags-and-RG-Tag" -Published -Force

Write-Output "------------------------ Link Schedules to Runbooks ------------------------"
Register-AzAutomationScheduledRunbook  -ResourceGroup $AutomationAccountRG -AutomationAccountName $AutomationAccountName -Name $class_StartAllVMsRbName -ScheduleName $classStartScheduleName
Register-AzAutomationScheduledRunbook  -ResourceGroup $AutomationAccountRG -AutomationAccountName $AutomationAccountName -Name $class_StopAllVMsRbName -ScheduleName $classStopScheduleName
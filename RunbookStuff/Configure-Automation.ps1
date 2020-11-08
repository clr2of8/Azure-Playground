$AutomationAccountName = "automation-account-2"
$classStartScheduleName = "class-start-schedule"
$classStopScheduleName = "class-stop-schedule"
$AutomationAccountRG = "Log-Analytics"
$TimeZone = ([System.TimeZoneInfo]::Local).Id
$basePath = "C:\Users\asmith\Documents\code\Azure-Playground\RunbookStuff"

$startTime = (Get-Date "9:50 AM").AddDays(1)
$startDescription = "triggers 10 minutes before classs start"
New-AzAutomationSchedule -AutomationAccountName $AutomationAccountName -Name $classStartScheduleName -StartTime $startTime -DayInterval 1 -ResourceGroupName $AutomationAccountRG -Description $startDescription -TimeZone $TimeZone

$stopTime = (Get-Date "4:00 PM").AddDays(1)
$stopDescription = "triggers 2 hours after classs is over (end of lab time)"
New-AzAutomationSchedule -AutomationAccountName $AutomationAccountName -Name $classStopScheduleName -StartTime $stopTime -DayInterval 1 -ResourceGroupName $AutomationAccountRG -Description $stopDescription -TimeZone $TimeZone

$class_StartAllVMsRbName = "class_StartAllVms"
$class_StopAllVMsRbName = "class_StopAllVms"
$class_StartAllVmsps1 = "$basePath\Runbooks\class_StartAllVms.ps1"
$class_StopAllVmsps1 = "$basePath\Runbooks\class_StopAllVms.ps1"
Import-AzAutomationRunbook -Path $class_StartAllVmsps1 -ResourceGroup $AutomationAccountRG -AutomationAccountName $AutomationAccountName -Type PowerShell -Name $class_StartAllVMsRbName -Published -Force
Import-AzAutomationRunbook -Path $class_StopAllVmsps1 -ResourceGroup $AutomationAccountRG -AutomationAccountName $AutomationAccountName -Type PowerShell -Name $class_StopAllVMsRbName -Published -Force
Import-AzAutomationRunbook -Path "$basePath\Runbooks\Start-Stop-All-VMs-by-RG-Tag.ps1" -ResourceGroup $AutomationAccountRG -AutomationAccountName $AutomationAccountName -Type PowerShell -Name "Start-Stop-All-VMs-by-RG-Tag" -Published -Force

Register-AzAutomationScheduledRunbook  -ResourceGroup $AutomationAccountRG -AutomationAccountName $AutomationAccountName -Name $class_StartAllVMsRbName -ScheduleName $classStartScheduleName
Register-AzAutomationScheduledRunbook  -ResourceGroup $AutomationAccountRG -AutomationAccountName $AutomationAccountName -Name $class_StopAllVMsRbName -ScheduleName $classStopScheduleName
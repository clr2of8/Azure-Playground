#first line

# Insert Auth Here

Write-Output ""
Write-Output "------------------------ Action ------------------------"
Write-Output "Stopping VMs ..."

#---------Read all the input variables---------------
$local = $false
try {
    $automationAccountName = Get-AutomationVariable -Name 'Internal_AutomationAccountName'
    $AutomationAccountRG = Get-AutomationVariable -Name 'Internal_Automation-AccountsRG'
}
catch {
    $local = $true
}

#Retry logic for Start-AzAutomationRunbook cmdlet
[string] $FailureMessage = "Failed to execute the Start-AzAutomationRunbook command"
[int] $RetryCount = 3 
[int] $TimeoutInSecs = 20
$RetryFlag = $true
$Attempt = 1
$VmTags = @{'type'='art';'type'='caldera'}
$params = @{"Action" = "stop"; "ResourceGroupTagName" = "type"; "ResourceGroupTagValue" = "class"; "VmTags" = $VmTags }
Write-Output $params

do {
    try {
        $rbName = 'Start-Stop-Specific-VMs-by-VM-Tags-and-RG-Tag'
        if ($local) {
            . "C:\Users\asmith\Documents\code\Azure-Playground\RunbookStuff\Runbooks\$rbName.ps1"
            Start-Stop-Specific-VMs-by-VM-Tags-and-RG-Tag @params
        }
        else {
            $runbook = Start-AzAutomationRunbook -AutomationAccountName $automationAccountName -Name $rbName -ResourceGroupName $AutomationAccountRG -Parameters $params
        }
        Write-Output "Triggered the child runbook: $rbName"

        $RetryFlag = $false
    }                    
    catch {
        Write-Output $ErrorMessage
                        
        if ($Attempt -gt $RetryCount) {
            Write-Output "$FailureMessage! Total retry attempts: $RetryCount"

            Write-Output "[Error Message] $($_.exception.message) `n"

            $RetryFlag = $false
        }
        else {
            Write-Output "[$Attempt/$RetryCount] $FailureMessage. Retrying in $TimeoutInSecs seconds..."

            Start-Sleep -Seconds $TimeoutInSecs

            $Attempt = $Attempt + 1
        }   
    }
}
while ($RetryFlag)
#last line
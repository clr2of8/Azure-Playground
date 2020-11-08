## Authentication
Write-Output ""
Write-Output "------------------------ Authentication ------------------------"
Write-Output "Logging into Azure ..."

#Retry logic for Start-AzAutomationRunbook cmdlet
[string] $FailureMessage = "Failed to execute the Start-AzAutomationRunbook command"
[int] $RetryCount = 3 
[int] $TimeoutInSecs = 20
$RetryFlag = $true
$Attempt = 1

do {
    try {
        # Ensures you do not inherit an AzContext in your runbook
        $null = Disable-AzContextAutosave -Scope Process

        $Conn = Get-AutomationConnection -Name AzureRunAsConnection
    
        $null = Connect-AzAccount `
            -ServicePrincipal `
            -Tenant $Conn.TenantID `
            -ApplicationId $Conn.ApplicationID `
            -CertificateThumbprint $Conn.CertificateThumbprint
        
        $RetryFlag = $false
        Write-Output "Successfully logged into Azure." 
    } 
    catch {
        if (!$Conn) {
            $ErrorMessage = "Service principal not found."
            throw $ErrorMessage
        } 
        else {
            Write-Error -Message $_.Exception
            throw $_.Exception
        }
    }
}
while ($RetryFlag)    
## End of authentication

## Authentication
Write-Output ""
Write-Output "------------------------ Action ------------------------"
Write-Output "Starting VMs ..."

#---------Read all the input variables---------------
$automationAccountName = Get-AutomationVariable -Name 'Internal_AutomationAccountName'
$aroResourceGroupName = Get-AutomationVariable -Name 'Internal_ResourceGroupName'



$params = @{"Action" = "start"; "TagName" = "type"; "TagValue" = "class" }

#Retry logic for Start-AzAutomationRunbook cmdlet
[string] $FailureMessage = "Failed to execute the Start-AzAutomationRunbook command"
[int] $RetryCount = 3 
[int] $TimeoutInSecs = 20
$RetryFlag = $true
$Attempt = 1

do {
    try {
        $rbName = 'Start-Stop-All-VMs-by-RG-Tag'
        $runbook = Start-AzAutomationRunbook -AutomationAccountName $automationAccountName -Name $rbName -ResourceGroupName $aroResourceGroupName –Parameters $params
                        
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
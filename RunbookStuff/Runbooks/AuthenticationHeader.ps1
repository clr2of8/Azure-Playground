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
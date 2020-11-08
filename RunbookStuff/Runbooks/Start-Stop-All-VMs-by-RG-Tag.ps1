param (

    [Parameter(Mandatory=$true)]  
    [String] $Action,

    [Parameter(Mandatory=$false)]  
    [String] $TagName,

    [Parameter(Mandatory=$false)]
    [String] $TagValue
) 

## Authentication
Write-Output ""
Write-Output "------------------------ Authentication ------------------------"
Write-Output "Logging into Azure ..."

try
{
    # Ensures you do not inherit an AzContext in your runbook
    $null = Disable-AzContextAutosave -Scope Process

    $Conn = Get-AutomationConnection -Name AzureRunAsConnection
    
    $null = Connect-AzAccount `
                    -ServicePrincipal `
                    -Tenant $Conn.TenantID `
                    -ApplicationId $Conn.ApplicationID `
                    -CertificateThumbprint $Conn.CertificateThumbprint

    Write-Output "Successfully logged into Azure." 
} 
catch
{
    if (!$Conn)
    {
        $ErrorMessage = "Service principal not found."
        throw $ErrorMessage
    } 
    else
    {
        Write-Error -Message $_.Exception
        throw $_.Exception
    }
}
## End of authentication

## Getting all virtual machines
Write-Output ""
Write-Output ""
Write-Output "---------------------------- Status ----------------------------"
Write-Output "Getting all virtual machines from all resource groups ..."


$rgs = Get-AzResourceGroup -Tag @{$TagName="$TagValue"}
foreach ($rg in $rgs) {
    $rgName = $rg.ResourceGroupName
    Write-Output "$Action`ing VMs in Resource Group: $rgName"
    $vms = Get-AzResource -ResourceGroupName $rgName -ResourceType Microsoft.Compute/virtualMachines
    if($Action -eq "start"){
        $null = $vms | Start-AzVM -NoWait
    }
    elseif($Action -eq "stop"){
        $null = $vms | Stop-AzVM -NoWait -Force
    }
    elseif($Action -eq "restart"){
        $null = $vms | Restart-AzVM -NoWait
    }
    
    Write-Output "Done $Action`ing VMs in Resource Group: $rgName"
}
#fist line
param (

    [Parameter(Mandatory=$true)]  
    [String] $Action,

    [Parameter(Mandatory=$false)]  
    [String] $TagName,

    [Parameter(Mandatory=$false)]
    [String] $TagValue
) 

## Authentication Header

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
#last line
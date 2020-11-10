function Start-Stop-Specific-VMs-by-VM-Tags-and-RG-Tag {
    param (

        [Parameter(Mandatory = $true)]  
        [String] $Action,

        [Parameter(Mandatory = $false)]  
        [String] $ResourceGroupTagName,

        [Parameter(Mandatory = $false)]
        [String] $ResourceGroupTagValue,

        [Parameter(Mandatory = $false)]  
        [Object] $VmTags,

        [Parameter(Mandatory = $false)]  
        [Object] $VmExclusionTags
    )

    # Insert Auth Here

    Write-Output ""
    Write-Output "---------------------------- Status ----------------------------"
    Write-Output "Getting all virtual machines from all resource groups ..."

    if ($VmTags) {
        $mynewhash = @{}
        $VmTags.psobject.properties | Foreach { $mynewhash[$_.Name] = $_.Value }
        $VmTags = $mynewhash
    } 
    if ($VmExclusionTags) {
        $mynewhash = @{}
        $VmExclusionTags.psobject.properties | Foreach { $mynewhash[$_.Name] = $_.Value }
        $VmExclusionTags = $mynewhash
    } 

    $rgs = Get-AzResourceGroup -Tag @{$ResourceGroupTagName = "$ResourceGroupTagValue" }
    foreach ($rg in $rgs) {
        $rgName = $rg.ResourceGroupName
        Write-Output "$Action`ing VMs in Resource Group: $rgName"
        $vms = Get-AzResource -ResourceGroupName $rgName -ResourceType Microsoft.Compute/virtualMachines
        if ($VmTags) {
            $vms = Get-AzResource -ResourceGroupName $rgName -ResourceType Microsoft.Compute/virtualMachines -Tag $VmTags
        }
        if ( $VmExclusionTags) {
            $vmsToExclude = Get-AzResource -ResourceGroupName $rgName -ResourceType Microsoft.Compute/virtualMachines -Tag $VmExclusionTags
            $vms = $vms | Where-Object { -not ($vmstoexclude.resourceID -contains $_.resourceID) }
        }
        foreach ($vm in $vms) {
            Write-Output "Called $Action on $($vm.Name)"
            if ($Action -eq "start") {
                $null = Start-AzVM -ResourceGroupName $rgName -Name $vm.Name -NoWait
            }
            elseif ($Action -eq "stop") {
                $null = Stop-AzVM -ResourceGroupName $rgName -Name $vm.Name -NoWait -Force
            }
            elseif ($Action -eq "restart") {
                $null = Restart-AzVM -ResourceGroupName $rgName -Name $vm.Name -NoWait
            }
        }
        Write-Output "Done $Action`ing VMs in Resource Group: $rgName"
    }
}
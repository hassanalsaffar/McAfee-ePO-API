#REQUIRES -version 2.0

<#
.SYNOPSIS
   PowerShell functions created to work with the McAfee Web API.

.DESCRIPTION
   ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
   Command naming convention/structure and some documentation formatting based on
   the ePOwerShell Module created by mischaboender

   Available at https://community.mcafee.com/thread/47989?tstart=0
   ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

   This module was created to containerize all McAfee Web API calls with PowerShell
   functions.  The Web API calls use XML output.

   As additional API calls are released from McAfee (for future products/product enhancements)
   this module will be updated.

   +++global (private data) variables (configured in the PSD1 module file)
    pd_EpoWebClient
    pd_EpoServer
    pd_EpoPort
    pd_EpoConnection

.NOTES
   Author:    _vidrine
   FileName:  epo-webapi.psm1
   Created:   2013.08.05
   Update:    2014.05.08
#>

$epoColorWarning = 'Yellow'
$epoColorError   = 'Red'

#region ePO Server Connection/Initialization
function Connect-EpoServer {

    param (

        [parameter(Mandatory=$false,Position=0)]
        [string]$EpoServer = $MyInvocation.MyCommand.Module.PrivateData['pd_EpoServer'],
        [parameter(Mandatory=$false,Position=1)]
        [string]$EpoPort = $MyInvocation.MyCommand.Module.PrivateData['pd_EpoPort'],
        [parameter(Mandatory=$false,Position=2,ValueFromPipeline=$True)]
        $Credential = (Get-Credential -Credential $null)
    )

    $EpoServer_old = $MyInvocation.MyCommand.Module.PrivateData['pd_EpoServer']
    $EpoPort_old   = $MyInvocation.MyCommand.Module.PrivateData['pd_EpoPort']

    # Set the module global parameters based on function parameters
    # This will only process if the loaded values are "" / blank from the PSD1 file.
    if ( $EpoServer -eq "" ) {

        $EpoServer  = Read-Host "Enter the ePO server URL (https://foo.com)"
        $MyInvocation.MyCommand.Module.PrivateData['pd_EpoServer'] = $EpoServer
    }
    elseIf ( $EpoServer_old -eq "" ) {

        $MyInvocation.MyCommand.Module.PrivateData['pd_EpoServer'] = $EpoServer
    }
    else {

        # Compare the pd_EpoServer value with the new entry
        # Prompt to replace if different

        if ($EpoServer_old -eq $EpoServer) {

            # Values are the same; no change
        }
        else {

            # Prompt to replace the PrivateData Value
            Write-Host "<WARNING> Value entered for the Epo Server does not match the Private Data stored value" -ForegroundColor $epoColorWarning
            Write-Host ''
            Write-Host "`tOld:`t$EpoServer_old"
            Write-Host "`tNew:`t$EpoServer"
            Write-Host ''

            do {

                $updatePdEpoServer = Read-Host  "Do you want to change/update the stored value? (y/N)"

                switch ($updatePdEpoServer) {

                    {$_.ToUpper() -in 'Y','YES'} {

                        $MyInvocation.MyCommand.Module.PrivateData['pd_EpoServer'] = $EpoServer
                        Write-Host "IN THE YES BLOCK" -ForegroundColor Magenta
                        $continue = $True
                    }

                    {$_.ToUpper() -in 'N','NO'} {

                        $EpoServer = $MyInvocation.MyCommand.Module.PrivateData['pd_EpoServer']
                        Write-Host "IN THE NO BLOCK" -ForegroundColor Magenta
                        $continue = $True
                    }

                    default {

                        $EpoServer = $MyInvocation.MyCommand.Module.PrivateData['pd_EpoServer']
                        Write-Host "IN THE DEFAULT BLOCK" -ForegroundColor Magenta
                        $continue = $True
                    }
                }
            } until ($continue)
        }
    }

    if ( $EpoPort -eq "" ) {

        $EpoPort    = Read-Host "Enter the port number for ePO server (8443, 8080, ...)"
        $MyInvocation.MyCommand.Module.PrivateData['pd_EpoPort'] = $EpoPort
    }
    elseIf ( $EpoPort_old -eq "" ) {

        $MyInvocation.MyCommand.Module.PrivateData['pd_EpoPort'] = $EpoPort
    }
    else {

        # Compare the pd_EpoPort value with the new entry
        # Prompt to replace if different

        if ($EpoPort_old -eq $EpoPort) {

            # Values are the same; no change
        }
        else {

            # Prompt to replace the PrivateData Value
            Write-Host "<WARNING> Value entered for the Epo Port does not match the Private Data stored value" -ForegroundColor $epoColorWarning
            Write-Host ''
            Write-Host "`tOld:`t$EpoPort_old"
            Write-Host "`tNew:`t$EpoPort"
            Write-Host ''

            do {

                $updatePdEpoPort = Read-Host  "Do you want to change the stored value? (y/N)"

                switch ($updatePdEpoPort) {

                    {$_.ToUpper() -in 'Y','YES'} {

                        $MyInvocation.MyCommand.Module.PrivateData['pd_EpoPort'] = $EpoPort
                        $continue = $True
                    }

                    {$_.ToUpper() -in 'N','NO'} {

                        $EpoPort = $MyInvocation.MyCommand.Module.PrivateData['pd_EpoPort']
                        $continue = $True
                    }

                    default {

                        $EpoPort = $MyInvocation.MyCommand.Module.PrivateData['pd_EpoPort']
                        $continue = $True
                    }
                }
            } until ($continue)
        }
    }

    # Join the two parameter values (loaded from CLI or PSD1 file) to create the connection string
    $MyInvocation.MyCommand.Module.PrivateData['pd_EpoConnection'] = ($EpoServer + ":" + $EpoPort)

    # Create the web client object + load user credentials into the PowerShell web client object
    $wc = New-Object System.Net.WebClient
    $wc.credentials = New-Object System.Net.NetworkCredential -ArgumentList ($Credential.GetNetworkCredential().username,$Credential.GetNetworkCredential().password)

    # Load the web client object into the global variable for use through other module functions
    $MyInvocation.MyCommand.Module.PrivateData['pd_EpoWebClient'] = $wc

    # Display the connection information for the current binding
    Get-EpoVersion

<#
.SYNOPSIS
   Connect-EpoServer

.DESCRIPTION
   Connect-EpoServer

.NOTES
   Author:    _vidrine
   Created:   2013.08.05
   Update:    2014.05.07
#>
}
#endregion ePO Server Connection/Initialization

#=================================================================

#region /remote/agentmgmt
function Get-EpoAgentHandler {

    # Configure the target API URL
	$urlBase      = $MyInvocation.MyCommand.Module.PrivateData['pd_EpoConnection']
	$urlExtension = "/remote/agentmgmt.listAgentHandlers?:output=xml"
	$URL          = $urlBase + $urlExtension

    # Make the connection to the MFE API URL
    # Place results in an XML variable
    $wc           = $MyInvocation.MyCommand.Module.PrivateData['pd_EpoWebClient']
	[xml]$result  = ($wc.downloadstring($URL)).replace("OK:`r`n","")

    # Return data results in an object
    $colResult    = @()

    forEach ( $item in $result.result.list.element.EPORegisteredApacheServer ) {

        $object = New-Object –TypeName PSObject

        $object | Add-Member –MemberType NoteProperty –Name autoId               -Value $item.'autoId'
        $object | Add-Member –MemberType NoteProperty –Name computerName         -Value $item.'computerName'
        $object | Add-Member –MemberType NoteProperty –Name dnsName              -Value $item.'dnsName'
        $object | Add-Member –MemberType NoteProperty –Name enabled              -Value $item.'enabled'
        $object | Add-Member –MemberType NoteProperty –Name key                  -Value $item.'key'
        $object | Add-Member –MemberType NoteProperty –Name lastKnownIp          -Value $item.'lastKnownIp'
        $object | Add-Member –MemberType NoteProperty –Name lastUpdate           -Value $item.'lastUpdate'
        $object | Add-Member –MemberType NoteProperty –Name masterHandler        -Value $item.'masterHandler'
        $object | Add-Member –MemberType NoteProperty –Name publishedDNSName     -Value $item.'publishedDNSName'
        $object | Add-Member –MemberType NoteProperty –Name publishedIP          -Value $item.'publishedIP'
        $object | Add-Member –MemberType NoteProperty –Name publishedNetBiosName -Value $item.'publishedNetBiosName'
        $object | Add-Member –MemberType NoteProperty –Name version              -Value $item.'version'
        $object | Add-Member –MemberType NoteProperty –Name versionMatch         -Value $item.'versionMatch'

        $colResult += $object
    }

    return $colResult

<#
.SYNOPSIS
   Get-EpoAgentHandler

.DESCRIPTION
   Get-EpoAgentHandler

.NOTES
   Author:    _vidrine
   Created:   2013.05.07
   Update:    2014.05.07
#>
}
#endregion /remote/agentmgmt

#region /remote/clienttask
#endregion /remote/agentmgmt

#region /remote/commonevent
#end region /remote/commonevent

#region /remote/core
#endregion /remote/core

#region /remote/detectedsystem
#endregion /remote/detectedsystem

#region /remote/eeadmin
function Get-EpoEncryptionKey {

    param (
        [parameter(Mandatory=$true,Position=0,ParameterSetName="MachineName")]
        [String]$machineName,
        [parameter(Mandatory=$true,Position=1,ParameterSetName="MachineId")]
        [String]$machineId
    )

    switch ($PsCmdlet.ParameterSetName) {

        "MachineName" {

            # Configure the target API URL
	        $urlBase      = $MyInvocation.MyCommand.Module.PrivateData['pd_EpoConnection']
	        $urlExtension = "/remote/eeadmin.exportMachineKey?machineName=$machineName"
	        $URL          = $urlBase + $urlExtension

            # Make the connection to the MFE API URL
            # Place results in an XML variable
            $wc           = $MyInvocation.MyCommand.Module.PrivateData['pd_EpoWebClient']
	        [xml]$result  = ($wc.downloadstring($URL)).replace("OK:`r`n","")

            # Return data results in an object
            $object = New-Object –TypeName PSObject
            $object | Add-Member –MemberType NoteProperty –Name key          –Value $result.mfeepeexportmachinekeys.current.key
            $object | Add-Member –MemberType NoteProperty –Name algorithm    –Value $result.mfeepeexportmachinekeys.current.algorithm
            $object | Add-Member –MemberType NoteProperty –Name algInfo      –Value $result.mfeepeexportmachinekeys.current.algInfo
            $object | Add-Member –MemberType NoteProperty –Name recoveryData –Value $result.mfeepeexportmachinekeys.current.recoveryData

            return $object
        }
        "MachineId" {

            # Configure the target API URL
	        $urlBase      = $MyInvocation.MyCommand.Module.PrivateData['pd_EpoConnection']
	        $urlExtension = "/remote/eeadmin.exportMachineKey?machineId=$machineId"
	        $URL          = $urlBase + $urlExtension

            # Make the connection to the MFE API URL
            # Place results in an XML variable
            $wc           = $MyInvocation.MyCommand.Module.PrivateData['pd_EpoWebClient']
	        [xml]$result  = ($wc.downloadstring($URL)).replace("OK:`r`n","")

            # Return data results in an object
            $object = New-Object –TypeName PSObject
            $object | Add-Member –MemberType NoteProperty –Name key          –Value $result.mfeepeexportmachinekeys.current.key
            $object | Add-Member –MemberType NoteProperty –Name algorithm    –Value $result.mfeepeexportmachinekeys.current.algorithm
            $object | Add-Member –MemberType NoteProperty –Name algInfo      –Value $result.mfeepeexportmachinekeys.current.algInfo
            $object | Add-Member –MemberType NoteProperty –Name recoveryData –Value $result.mfeepeexportmachinekeys.current.recoveryData

            return $object
        }
    }

<#
.SYNOPSIS
   Get-EpoEncryptionKey

.DESCRIPTION
   Get-EpoEncryptionKey

.NOTES
   Author:    _vidrine
   Created:   2014.05.08
   Update:    2014.05.08
#>
}
#endregion /remote/eeadmin

#region /remote/epo
function Get-EpoVersion {

    # Configure the target API URL
    $urlBase      = $MyInvocation.MyCommand.Module.PrivateData['pd_EpoConnection']
	$urlExtension = "/remote/epo.getVersion?:output=xml"
	$URL          = $urlBase + $urlExtension

    # Make the connection to the MFE API URL
    # Place results in an XML variable
	$wc           = $MyInvocation.MyCommand.Module.PrivateData['pd_EpoWebClient']
    $result       = ($wc.downloadstring($URL)).replace("OK:`r`n","")
    [xml]$xml     = $result

    # Return data results in an object
    $object = New-Object –TypeName PSObject
    $object | Add-Member –MemberType NoteProperty –Name EpoServer –Value $urlBase
    $object | Add-Member –MemberType NoteProperty –Name EpoVersion –Value $xml.result

    return $object

<#
.SYNOPSIS
   Get-EpoVersion

.DESCRIPTION
   Get-EpoVersion

.NOTES
   Author:    _vidrine
   Created:   2013.08.05
   Update:    2014.05.07
#>
}
#endregion /remote/epo

#region /remote/epogroup
#endregion /remote/epogroup

#region /remote/policy
function Get-EpoPolicy {

    param (
        [parameter(Mandatory=$false,Position=0,ParameterSetName="Filter")]
        [String]$Filter
    )

    # Configure the target API URL
	$urlBase      = $MyInvocation.MyCommand.Module.PrivateData['pd_EpoConnection']
	if ($Filter) {

        $urlExtension = "/remote/policy.find?searchText=" + $Filter + "&:output=xml"
    }
    else {

        $urlExtension = "/remote/policy.find?:output=xml"
    }
	$URL          = $urlBase + $urlExtension

    # Make the connection to the MFE API URL
    # Place results in an XML variable
    $wc           = $MyInvocation.MyCommand.Module.PrivateData['pd_EpoWebClient']
	[xml]$result  = ($wc.downloadstring($URL)).replace("OK:`r`n","")

    # Return data results in an object
    $colResult    = @()

    forEach ( $item in $result.result.list.element.ObjectPolicy ) {

        $object = New-Object –TypeName PSObject

        $object | Add-Member –MemberType NoteProperty –Name featureId   -Value $item.'featureId'
        $object | Add-Member –MemberType NoteProperty –Name featureName -Value $item.'featureName'
        $object | Add-Member –MemberType NoteProperty –Name objectId    -Value $item.'objectId'
        $object | Add-Member –MemberType NoteProperty –Name objectName  -Value $item.'objectName'
        $object | Add-Member –MemberType NoteProperty –Name objectNotes -Value $item.'objectNotes'
        $object | Add-Member –MemberType NoteProperty –Name productId   -Value $item.'productId'
        $object | Add-Member –MemberType NoteProperty –Name productName -Value $item.'productName'
        $object | Add-Member –MemberType NoteProperty –Name typeId      -Value $item.'typeId'
        $object | Add-Member –MemberType NoteProperty –Name typeName    -Value $item.'typeName'

        $colResult += $object
    }

    return $colResult

<#
.SYNOPSIS
   Get-EpoPolicy

.DESCRIPTION
   Get-EpoPolicy

.NOTES
   Author:    _vidrine
   Created:   2014.05.08
   Update:    2014.05.08
#>
}
function Export-EpoPolicy {

    param(
        [parameter(Mandatory=$true,Position=0)]
        [string]$productId,
        [parameter(Mandatory=$true,Position=1)]
        [string]$fileName
    )

    # Configure the target API URL
    $urlBase      = $MyInvocation.MyCommand.Module.PrivateData['pd_EpoConnection']
	$urlExtension = "/remote/policy.export?productId=$productId&fileName=$fileName&:output=xml"
	$URL          = $urlBase + $urlExtension

    # Make the connection to the MFE API URL
    # Place results in an XML variable
	$wc           = $MyInvocation.MyCommand.Module.PrivateData['pd_EpoWebClient']
    $result       = ($wc.downloadstring($URL)).replace("OK:`r`n","")
    [xml]$xml     = $result

    return $($xml.result)

<#
.SYNOPSIS
   Export-EpoPolicy

.DESCRIPTION
   Export-EpoPolicy

.NOTES
   Author:    _vidrine
   Created:   2014.05.08
   Update:    2014.05.08
#>
}
function Import-EpoPolicy {}
#endregion /remote/policy

#region /remote/repository
#endregion /remote/repository

#region /remote/rsd
#endregion /remote/rsd

#region /remote/scheduler
function Get-EpoServerTask {

    [CmdletBinding(DefaultParameterSetName="All")]

    param (
        [parameter(Position=0,ParameterSetName='TaskName')]
        [string]$TaskName = '',       # String filter for server task query
        [parameter(Position=1,ParameterSetName='TaskID')]
        [int]$TaskID = '',          # Integer value for server task id
        [parameter(Position=2,ParameterSetName='Running')]
        [switch]$Running = $false,  # List all RUNNING server tasks
        [ValidateSet("Enabled","Disabled")]
        [parameter(Position=3)]
        [string]$Status = ""        # List all ENABLED server tasks
    )

    # Nested function to return all server tasks - USED for sub-filtering
    function Get-EpoServerTaskALL {
        $urlBase      = $MyInvocation.MyCommand.Module.PrivateData['pd_EpoConnection']
	    $urlExtension = "/remote/scheduler.listAllServerTasks?:output=xml"
	    $URL          = $urlBase + $urlExtension

        $wc           = $MyInvocation.MyCommand.Module.PrivateData['pd_EpoWebClient']
        [xml]$result  = ($wc.DownloadString($url)).replace("OK:`r`n","")

        $comboBreaker = $result.result.list.serverTask
        foreach ($a in $comboBreaker) { if ($a.name -like $queryFilter){$a.id;$a.name} }

        # Return data results in an object
        $colResult    = @()

        forEach ( $item in $result.result.list.serverTask ) {

            $object = New-Object –TypeName PSObject

            $object | Add-Member –MemberType NoteProperty –Name TaskID          -Value $item.'id'
            $object | Add-Member –MemberType NoteProperty –Name TaskName        -Value $item.'name'
            $object | Add-Member –MemberType NoteProperty –Name TaskDescription -Value $item.'description'
            $object | Add-Member –MemberType NoteProperty –Name TaskStartDate   -Value $item.'startDate'
            $object | Add-Member –MemberType NoteProperty –Name TaskEndDate     -Value $item.'endDate'
            $object | Add-Member –MemberType NoteProperty –Name TaskNextRunTime -Value $item.'nextRunTime'
            $object | Add-Member –MemberType NoteProperty –Name TaskEnabled     -Value $item.'enabled'
            $object | Add-Member –MemberType NoteProperty –Name TaskValid       -Value $item.'valid'

            $colResult += $object
        }

    return $colResult
    }

    switch ($PsCmdlet.ParameterSetName)
    {

        "TaskName"  {

            $urlBase      = $MyInvocation.MyCommand.Module.PrivateData['pd_EpoConnection']
	        $urlExtension = "/remote/scheduler.getServerTask?taskName=$TaskName&:output=xml"
	        $URL          = $urlBase + $urlExtension

            $wc           = $MyInvocation.MyCommand.Module.PrivateData['pd_EpoWebClient']
            [xml]$result  = ($wc.DownloadString($url)).replace("OK:`r`n","")

            # Return data results in an object
            $colResult    = @()

            forEach ( $item in $result.result.serverTask ) {

                $object = New-Object –TypeName PSObject

                $object | Add-Member –MemberType NoteProperty –Name TaskID          -Value $item.'id'
                $object | Add-Member –MemberType NoteProperty –Name TaskName        -Value $item.'name'
                $object | Add-Member –MemberType NoteProperty –Name TaskDescription -Value $item.'description'
                $object | Add-Member –MemberType NoteProperty –Name TaskStartDate   -Value $item.'startDate'
                $object | Add-Member –MemberType NoteProperty –Name TaskEndDate     -Value $item.'endDate'
                $object | Add-Member –MemberType NoteProperty –Name TaskNextRunTime -Value $item.'nextRunTime'
                $object | Add-Member –MemberType NoteProperty –Name TaskEnabled     -Value $item.'enabled'
                $object | Add-Member –MemberType NoteProperty –Name TaskValid       -Value $item.'valid'

                $colResult += $object
            }

            if ( $Status ) {
                if ( $Status -eq "Enabled" ) {

                    $enabledTask = $colResult | where {$_.taskenabled -eq $true}

                    return $enabledTask
                }
                elseIf ( $Status -eq "Disabled" ) {

                    $disabledTask = $colResult | where {$_.taskenabled -eq $false}

                    return $disabledTask
                }
            }
            else {

                return $colResult
            }
        } # //End "Filter" switch block
        "TaskID"  {

            $urlBase      = $MyInvocation.MyCommand.Module.PrivateData['pd_EpoConnection']
	        $urlExtension = "/remote/scheduler.getServerTask?taskId=$TaskID&:output=xml"
	        $URL          = $urlBase + $urlExtension

            $wc           = $MyInvocation.MyCommand.Module.PrivateData['pd_EpoWebClient']
            [xml]$result  = ($wc.DownloadString($url)).replace("OK:`r`n","")

            # Return data results in an object
            $colResult    = @()

            forEach ( $item in $result.result.serverTask ) {

                $object = New-Object –TypeName PSObject

                $object | Add-Member –MemberType NoteProperty –Name TaskID          -Value $item.'id'
                $object | Add-Member –MemberType NoteProperty –Name TaskName        -Value $item.'name'
                $object | Add-Member –MemberType NoteProperty –Name TaskDescription -Value $item.'description'
                $object | Add-Member –MemberType NoteProperty –Name TaskStartDate   -Value $item.'startDate'
                $object | Add-Member –MemberType NoteProperty –Name TaskEndDate     -Value $item.'endDate'
                $object | Add-Member –MemberType NoteProperty –Name TaskNextRunTime -Value $item.'nextRunTime'
                $object | Add-Member –MemberType NoteProperty –Name TaskEnabled     -Value $item.'enabled'
                $object | Add-Member –MemberType NoteProperty –Name TaskValid       -Value $item.'valid'

                $colResult += $object
            }

            if ( $Status ) {
                if ( $Status -eq "Enabled" ) {

                    $enabledTask = $colResult | where {$_.taskenabled -eq $true}

                    return $enabledTask
                }
                elseIf ( $Status -eq "Disabled" ) {

                    $disabledTask = $colResult | where {$_.taskenabled -eq $false}

                    return $disabledTask
                }
            }
            else {

                return $colResult
            }
        } # //End "TaskID" switch block
        "Running" {

            $urlBase      = $MyInvocation.MyCommand.Module.PrivateData['pd_EpoConnection']
	        $urlExtension = "/remote/scheduler.listRunningServerTasks?:output=xml"
	        $URL          = $urlBase + $urlExtension

            $wc           = $MyInvocation.MyCommand.Module.PrivateData['pd_EpoWebClient']
            [xml]$result  = ($wc.DownloadString($url)).replace("OK:`r`n","")

            if ( $result.result.list.runningtask ) {

                $colResult = @()

                forEach ( $item in $result.result.list.runningtask ) {

                    $object = New-Object –TypeName PSObject

                    $object | Add-Member –MemberType NoteProperty –Name TaskLogID           -Value $item.'taskLogId'
                    $object | Add-Member –MemberType NoteProperty –Name TaskName            -Value $item.'taskName'
                    $object | Add-Member –MemberType NoteProperty –Name TaskStartDate       -Value $item.'startDate'
                    $object | Add-Member –MemberType NoteProperty –Name TaskPercentComplete -Value $item.'percentComplete'

                    $colResult += $object
                }

                return $colResult
            }
            else {

                return $null
            }
        } # //End "Running" switch block
        "All"  {

            # Return ALL server tasks / no filters
            $colResult = Get-EPOServerTaskALL

            if ( $Status -eq "Enabled" ) {

                $enabledTask = $colResult | where {$_.taskenabled -eq $true}

                return $enabledTask
            }
            elseIf ( $Status -eq "Disabled" ) {

                $disabledTask = $colResult | where {$_.taskenabled -eq $false}

                return $disabledTask
            }
            else {

                return $colResult
            }
        } # //End "Default" switch block
    } # //End switch block
<#
.SYNOPSIS
   Get-EpoServerTask

.DESCRIPTION
   Get-EpoServerTask

.NOTES
   Author:    _vidrine
   Created:   2013.08.05
   Update:    2014.05.07
#>
}
function Enable-EpoServerTask {

    param (
        [Parameter(Mandatory=$false,Position=0,ParameterSetName='TaskName')]
        [string]$TaskName = '',  # String value for the ePO Server Task Name
        [Parameter(Mandatory=$false,Position=1,ParameterSetName='TaskID')]
        [int]$TaskID = ''  # Int value for the ePO Server TaskID
    )

    switch ($PsCmdlet.ParameterSetName) {

        'TaskName' {

            $urlBase      = $MyInvocation.MyCommand.Module.PrivateData['pd_EpoConnection']
	        $urlExtension = "/remote/scheduler.updateServerTask?taskName=$TaskName&status=enabled&:output=xml"
	        $URL          = $urlBase + $urlExtension

            $wc           = $MyInvocation.MyCommand.Module.PrivateData['pd_EpoWebClient']
            [xml]$result  = ($wc.DownloadString($url)).replace("OK:`r`n","")

            # Display the server task information again - for validation
            Get-EpoServerTask -TaskName $TaskName
        }
        'TaskID' {

            $urlBase      = $MyInvocation.MyCommand.Module.PrivateData['pd_EpoConnection']
	        $urlExtension = "/remote/scheduler.updateServerTask?taskId=$TaskID&status=enabled&:output=xml"
	        $URL          = $urlBase + $urlExtension

            $wc           = $MyInvocation.MyCommand.Module.PrivateData['pd_EpoWebClient']
            [xml]$result  = ($wc.DownloadString($url)).replace("OK:`r`n","")

            # Display the server task information again - for validation
            Get-EpoServerTask -TaskID $TaskID
        }
    }
<#
.SYNOPSIS
   Enable-EpoServerTask

.DESCRIPTION
   Enable-EpoServerTask

.NOTES
   Author:    _vidrine
   Created:   2013.08.05
   Update:    2014.05.07
#>
}
function Disable-EpoServerTask {

    param (
        [Parameter(Mandatory=$false,Position=0,ParameterSetName='TaskName')]
        [string]$TaskName = '',  # String value for the ePO Server Task Name
        [Parameter(Mandatory=$false,Position=1,ParameterSetName='TaskID')]
        [int]$TaskID = ''  # Int value for the ePO Server TaskID
    )

    switch ($PsCmdlet.ParameterSetName) {

        'TaskName' {

            $urlBase      = $MyInvocation.MyCommand.Module.PrivateData['pd_EpoConnection']
	        $urlExtension = "/remote/scheduler.updateServerTask?taskName=$TaskName&status=disabled&:output=xml"
	        $URL          = $urlBase + $urlExtension

            $wc           = $MyInvocation.MyCommand.Module.PrivateData['pd_EpoWebClient']
            [xml]$result  = ($wc.DownloadString($url)).replace("OK:`r`n","")

            # Display the server task information again - for validation
            Get-EpoServerTask -TaskName $TaskName
        }
        'TaskID' {

            $urlBase      = $MyInvocation.MyCommand.Module.PrivateData['pd_EpoConnection']
	        $urlExtension = "/remote/scheduler.updateServerTask?taskId=$TaskID&status=disabled&:output=xml"
	        $URL          = $urlBase + $urlExtension

            $wc           = $MyInvocation.MyCommand.Module.PrivateData['pd_EpoWebClient']
            [xml]$result  = ($wc.DownloadString($url)).replace("OK:`r`n","")

            # Display the server task information again - for validation
            Get-EpoServerTask -TaskID $TaskID
        }
    }
<#
.SYNOPSIS
   Disable-EpoServerTask

.DESCRIPTION
   Disable-EpoServerTask

.NOTES
   Author:    _vidrine
   Created:   2013.08.05
   Update:    2014.05.07
#>
}
function Start-EpoServerTask {}
function Stop-EpoServerTask {}
#endregion /remote/scheduler

#region /remote/system
function Get-EpoSystem {

	param (

        [parameter(Mandatory=$true,Position=0,ParameterSetName="Filter")]
        [String]$Filter
    )

    # Configure the target API URL
	$urlBase      = $MyInvocation.MyCommand.Module.PrivateData['pd_EpoConnection']
	$urlExtension = "/remote/system.find?searchText=" + $Filter + "&:output=xml"
	$URL          = $urlBase + $urlExtension

    # Make the connection to the MFE API URL
    # Place results in an XML variable
    $wc           = $MyInvocation.MyCommand.Module.PrivateData['pd_EpoWebClient']
	[xml]$result  = ($wc.downloadstring($URL)).replace("OK:`r`n","")

    # Return data results in an object
    $colResult    = @()

    forEach ( $item in $result.result.list.row ) {

        $object = New-Object –TypeName PSObject

        $object | Add-Member –MemberType NoteProperty –Name AgentGUID           -Value $item.'EPOLeafNode.AgentGUID'
        $object | Add-Member –MemberType NoteProperty –Name AgentVersion        -Value $item.'EPOLeafNode.AgentVersion'
        $object | Add-Member –MemberType NoteProperty –Name ComputerName        -Value $item.'EPOComputerProperties.ComputerName'
        $object | Add-Member –MemberType NoteProperty –Name CPUSerialNum        -Value $item.'EPOComputerProperties.CPUSerialNum'
        $object | Add-Member –MemberType NoteProperty –Name CPUSpeed            -Value $item.'EPOComputerProperties.CPUSpeed'
        $object | Add-Member –MemberType NoteProperty –Name CPUType             -Value $item.'EPOComputerProperties.CPUType'
        $object | Add-Member –MemberType NoteProperty –Name DefaultLangID       -Value $item.'EPOComputerProperties.DefaultLangID'
        $object | Add-Member –MemberType NoteProperty –Name Description         -Value $item.'EPOComputerProperties.Description'
        $object | Add-Member –MemberType NoteProperty –Name DomainName          -Value $item.'EPOComputerProperties.DomainName'
        $object | Add-Member –MemberType NoteProperty –Name ExcludedTags        -Value $item.'EPOLeafNode.ExcludedTags'
        $object | Add-Member –MemberType NoteProperty –Name FreeDiskSpace       -Value $item.'EPOComputerProperties.FreeDiskSpace'
        $object | Add-Member –MemberType NoteProperty –Name FreeMemory          -Value $item.'EPOComputerProperties.FreeMemory'
        $object | Add-Member –MemberType NoteProperty –Name IPAddress           -Value $item.'EPOComputerProperties.IPAddress'
        $object | Add-Member –MemberType NoteProperty –Name IPHostName          -Value $item.'EPOComputerProperties.IPHostName'
        $object | Add-Member –MemberType NoteProperty –Name IPSubnet            -Value $item.'EPOComputerProperties.IPSubnet'
        $object | Add-Member –MemberType NoteProperty –Name IPSubnetMask        -Value $item.'EPOComputerProperties.IPSubnetMask'
        $object | Add-Member –MemberType NoteProperty –Name IPV4x               -Value $item.'EPOComputerProperties.IPV4x'
        $object | Add-Member –MemberType NoteProperty –Name IPV6                -Value $item.'EPOComputerProperties.IPV6'
        $object | Add-Member –MemberType NoteProperty –Name IPXAddress          -Value $item.'EPOComputerProperties.IPXAddress'
        $object | Add-Member –MemberType NoteProperty –Name IsPortable          -Value $item.'EPOComputerProperties.IsPortable'
        $object | Add-Member –MemberType NoteProperty –Name LastAgentHandler    -Value $item.'EPOComputerProperties.LastAgentHandler'
        $object | Add-Member –MemberType NoteProperty –Name LastUpdate          -Value $item.'EPOLeafNode.LastUpdate'
        $object | Add-Member –MemberType NoteProperty –Name ManagedState        -Value $item.'EPOLeafNode.ManagedState'
        $object | Add-Member –MemberType NoteProperty –Name NetAddress          -Value $item.'EPOComputerProperties.NetAddress'
        $object | Add-Member –MemberType NoteProperty –Name NumOfCPU            -Value $item.'EPOComputerProperties.NumOfCPU'
        $object | Add-Member –MemberType NoteProperty –Name OSBitMode           -Value $item.'EPOComputerProperties.OSBitMode'
        $object | Add-Member –MemberType NoteProperty –Name OSBuildNum          -Value $item.'EPOComputerProperties.OSBuildNum'
        $object | Add-Member –MemberType NoteProperty –Name OSOEMID             -Value $item.'EPOComputerProperties.OSOEMID'
        $object | Add-Member –MemberType NoteProperty –Name OSPlatform          -Value $item.'EPOComputerProperties.OSPlatform'
        $object | Add-Member –MemberType NoteProperty –Name OSServicePackVer    -Value $item.'EPOComputerProperties.OSServicePackVer'
        $object | Add-Member –MemberType NoteProperty –Name OSType              -Value $item.'EPOComputerProperties.OSType'
        $object | Add-Member –MemberType NoteProperty –Name OSVersion           -Value $item.'EPOComputerProperties.OSVersion'
        $object | Add-Member –MemberType NoteProperty –Name ParentID            -Value $item.'EPOComputerProperties.ParentID'
        $object | Add-Member –MemberType NoteProperty –Name SubnetAddress       -Value $item.'EPOComputerProperties.SubnetAddress'
        $object | Add-Member –MemberType NoteProperty –Name SubnetMask          -Value $item.'EPOComputerProperties.SubnetMask'
        $object | Add-Member –MemberType NoteProperty –Name SystemDescription   -Value $item.'EPOComputerProperties.SystemDescription'
        $object | Add-Member –MemberType NoteProperty –Name SysvolFreeSpace     -Value $item.'EPOComputerProperties.SysvolFreeSpace'
        $object | Add-Member –MemberType NoteProperty –Name SysvolTotalSpace    -Value $item.'EPOComputerProperties.SysvolTotalSpace'
        $object | Add-Member –MemberType NoteProperty –Name Tags                -Value $item.'EPOLeafNode.Tags'
        $object | Add-Member –MemberType NoteProperty –Name TimeZone            -Value $item.'EPOComputerProperties.TimeZone'
        $object | Add-Member –MemberType NoteProperty –Name TotalDiskSpace      -Value $item.'EPOComputerProperties.TotalDiskSpace'
        $object | Add-Member –MemberType NoteProperty –Name TotalPhysicalMemory -Value $item.'EPOComputerProperties.TotalPhysicalMemory'
        $object | Add-Member –MemberType NoteProperty –Name UserName            -Value $item.'EPOComputerProperties.UserName'
        $object | Add-Member –MemberType NoteProperty –Name UserProperty1       -Value $item.'EPOComputerProperties.UserProperty1'
        $object | Add-Member –MemberType NoteProperty –Name UserProperty2       -Value $item.'EPOComputerProperties.UserProperty2'
        $object | Add-Member –MemberType NoteProperty –Name UserProperty3       -Value $item.'EPOComputerProperties.UserProperty3'
        $object | Add-Member –MemberType NoteProperty –Name UserProperty4       -Value $item.'EPOComputerProperties.UserProperty4'

        $colResult += $object
    }

    return $colResult

<#
.SYNOPSIS
   Get-EpoSystem

.DESCRIPTION
   Get-EpoSystem

.NOTES
   Author:    _vidrine
   Created:   2013.08.05
   Update:    2014.05.07
#>
}
function Get-EpoTag {

	param (

        [parameter(Mandatory=$true,Position=0,ParameterSetName="Filter")]
        [String]$Filter
    )

    # Configure the target API URL
	$urlBase      = $MyInvocation.MyCommand.Module.PrivateData['pd_EpoConnection']
	$urlExtension = "/remote/system.findTag?searchText=" + $Filter + "&:output=xml"
	$URL          = $urlBase + $urlExtension

    # Make the connection to the MFE API URL
    # Place results in an XML variable
    $wc           = $MyInvocation.MyCommand.Module.PrivateData['pd_EpoWebClient']
	[xml]$result  = ($wc.downloadstring($URL)).replace("OK:`r`n","")

    # Return data results in an object
    $colResult    = @()

    forEach ( $item in $result.result.list.element.TagEPO ) {

        $object = New-Object –TypeName PSObject

        $object | Add-Member –MemberType NoteProperty –Name tagId    -Value $item.'tagId'
        $object | Add-Member –MemberType NoteProperty –Name tagName  -Value $item.'tagName'
        $object | Add-Member –MemberType NoteProperty –Name tagNotes -Value $item.'tagNotes'

        $colResult += $object
    }

    return $colResult
}
#endregion /remote/system

#region /remote/tasklog
#endregion /remote/tasklog

Export-ModuleMember -Function * -Alias *

#requires -Version 5.1
<#
.SYNOPSIS
  Endpoint health diagnostic for the Liquidware Stratusphere UX Connector ID (CID) Key agent.
  Personal project, not for production use. Provided as is, without warranty of any kind. Not affiliated with the author's employer, with Liquidware or with Microsoft.

.DESCRIPTION
  Checks whether the Stratusphere UX Connector ID Key directory exists, whether the agent service
  (tntgrd or LwL.ConnectorID) is installed and running, and optionally verifies TCP reachability to
  the Stratusphere Hub on port 443. Compatible with Windows PowerShell 5.1 and PowerShell 7+.
#>
[CmdletBinding()]
param(
  [string] $HubAddress = '',
  [ValidateRange(1, 65535)] [int] $HubPort = 443,
  [string[]] $ServiceName = @('tntgrd', 'LwL.ConnectorID'),
  [string[]] $InstallPaths = @(
    'C:\Program Files (x86)\Liquidware Labs\Connector ID',
    'C:\Program Files\Liquidware Labs\Connector ID'
  ),
  [switch] $SkipNetworkCheck,
  [AllowEmptyCollection()] [string[]] $MockExistingPaths = $null,
  [AllowEmptyCollection()] [object[]] $MockServices = $null,
  [nullable[bool]] $MockTcpConnected = $null,
  [switch] $Quiet
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Write-LwCheckLine {
  param(
    [string] $Level,
    [string] $CheckName,
    [string] $Message,
    [bool] $SuppressOutput
  )
  if ($SuppressOutput) { return }
  $color = 'Green'
  if ($Level -eq 'WARN') { $color = 'Yellow' }
  elseif ($Level -eq 'FAIL') { $color = 'Red' }
  Write-Host ("[{0}] {1}: {2}" -f $Level, $CheckName, $Message) -ForegroundColor $color
}

$checks = New-Object 'System.Collections.Generic.List[object]'

# 1. Install directory check
$matchedPaths = New-Object 'System.Collections.Generic.List[string]'
foreach ($candidatePath in $InstallPaths) {
  $exists = $false
  if ($null -ne $MockExistingPaths) {
    foreach ($mp in $MockExistingPaths) {
      if ($mp -ieq $candidatePath) {
        $exists = $true
        break
      }
    }
  } else {
    $exists = Test-Path -LiteralPath $candidatePath
  }
  if ($exists) {
    $matchedPaths.Add($candidatePath)
  }
}

if ($matchedPaths.Count -gt 0) {
  $msg = "Found CID Key directory at '$($matchedPaths[0])'."
  $checks.Add([pscustomobject]@{
      Name    = 'InstallDirectory'
      Status  = 'PASS'
      Message = $msg
    })
  Write-LwCheckLine -Level 'PASS' -CheckName 'InstallDirectory' -Message $msg -SuppressOutput $Quiet.IsPresent
} else {
  $msg = 'No Connector ID directory found in candidate InstallPaths.'
  $checks.Add([pscustomobject]@{
      Name    = 'InstallDirectory'
      Status  = 'WARN'
      Message = $msg
    })
  Write-LwCheckLine -Level 'WARN' -CheckName 'InstallDirectory' -Message $msg -SuppressOutput $Quiet.IsPresent
}

# 2. Service presence and status check
$discoveredServices = New-Object 'System.Collections.Generic.List[object]'
if ($null -ne $MockServices) {
  foreach ($ms in $MockServices) {
    foreach ($wanted in $ServiceName) {
      if ($ms.Name -ieq $wanted) {
        $discoveredServices.Add($ms)
      }
    }
  }
} else {
  $getServiceCmd = Get-Command -Name 'Get-Service' -ErrorAction SilentlyContinue
  if ($null -ne $getServiceCmd) {
    foreach ($wanted in $ServiceName) {
      $svc = Get-Service -Name $wanted -ErrorAction SilentlyContinue
      if ($null -ne $svc) {
        $discoveredServices.Add([pscustomobject]@{
            Name   = [string]$svc.Name
            Status = [string]$svc.Status
          })
      }
    }
  }
}

if ($discoveredServices.Count -eq 0) {
  $msg = "Neither $($ServiceName -join ' nor ') service is installed."
  $checks.Add([pscustomobject]@{
      Name    = 'AgentService'
      Status  = 'FAIL'
      Message = $msg
    })
  Write-LwCheckLine -Level 'FAIL' -CheckName 'AgentService' -Message $msg -SuppressOutput $Quiet.IsPresent
} else {
  $runningSvc = $null
  foreach ($ds in $discoveredServices) {
    if ([string]$ds.Status -ieq 'Running') {
      $runningSvc = $ds
      break
    }
  }
  if ($null -ne $runningSvc) {
    $msg = "Service '$($runningSvc.Name)' is Running."
    $checks.Add([pscustomobject]@{
        Name    = 'AgentService'
        Status  = 'PASS'
        Message = $msg
      })
    Write-LwCheckLine -Level 'PASS' -CheckName 'AgentService' -Message $msg -SuppressOutput $Quiet.IsPresent
  } else {
    $firstSvc = $discoveredServices[0]
    $msg = "Service '$($firstSvc.Name)' is installed but in state '$($firstSvc.Status)'."
    $checks.Add([pscustomobject]@{
        Name    = 'AgentService'
        Status  = 'FAIL'
        Message = $msg
      })
    Write-LwCheckLine -Level 'FAIL' -CheckName 'AgentService' -Message $msg -SuppressOutput $Quiet.IsPresent
  }
}

# 3. Hub TCP reachability check
if ($SkipNetworkCheck.IsPresent -or [string]::IsNullOrWhiteSpace($HubAddress)) {
  $msg = 'Skipped Hub network check (SkipNetworkCheck set or HubAddress not provided).'
  $checks.Add([pscustomobject]@{
      Name    = 'HubConnectivity'
      Status  = 'PASS'
      Message = $msg
    })
  Write-LwCheckLine -Level 'PASS' -CheckName 'HubConnectivity' -Message $msg -SuppressOutput $Quiet.IsPresent
} else {
  $cleanHub = $HubAddress.Trim() -replace '^https?://', '' -replace '/+$', ''
  $connected = $false
  if ($null -ne $MockTcpConnected) {
    $connected = [bool]$MockTcpConnected
  } else {
    $client = New-Object System.Net.Sockets.TcpClient
    try {
      $asyncResult = $client.BeginConnect($cleanHub, $HubPort, $null, $null)
      $waitOk = $asyncResult.AsyncWaitHandle.WaitOne(3000, $false)
      if ($waitOk -and $client.Connected) {
        $client.EndConnect($asyncResult)
        $connected = $true
      }
    } catch {
      $connected = $false
    } finally {
      $client.Close()
    }
  }

  if ($connected) {
    $msg = "TCP connection to Stratusphere Hub '$cleanHub`:$HubPort' succeeded."
    $checks.Add([pscustomobject]@{
        Name    = 'HubConnectivity'
        Status  = 'PASS'
        Message = $msg
      })
    Write-LwCheckLine -Level 'PASS' -CheckName 'HubConnectivity' -Message $msg -SuppressOutput $Quiet.IsPresent
  } else {
    $msg = "TCP connection to Stratusphere Hub '$cleanHub`:$HubPort' failed."
    $checks.Add([pscustomobject]@{
        Name    = 'HubConnectivity'
        Status  = 'FAIL'
        Message = $msg
      })
    Write-LwCheckLine -Level 'FAIL' -CheckName 'HubConnectivity' -Message $msg -SuppressOutput $Quiet.IsPresent
  }
}

$overallStatus = 'PASS'
foreach ($c in $checks) {
  if ($c.Status -eq 'FAIL') {
    $overallStatus = 'FAIL'
    break
  }
  if ($c.Status -eq 'WARN' -and $overallStatus -eq 'PASS') {
    $overallStatus = 'WARN'
  }
}

[pscustomobject]@{
  Status     = $overallStatus
  HubAddress = $HubAddress
  HubPort    = $HubPort
  CheckedAt  = [DateTime]::UtcNow.ToString('o')
  Checks     = $checks.ToArray()
}

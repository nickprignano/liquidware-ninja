#requires -Version 7.0
<#
.SYNOPSIS
  Pure cross-platform utility functions for Liquidware ProfileUnity, FlexApp and Stratusphere UX.
  Personal project, not for production use. Provided as is, without warranty of any kind. Not affiliated with the author's employer, with Liquidware or with Microsoft.
#>

Set-StrictMode -Version Latest

function Get-LwDefaultTemplateDirectory {
  [CmdletBinding()]
  param()
  Join-Path $PSScriptRoot '../../templates'
}

function Test-LwPortabilityOverlap {
  <#
  .SYNOPSIS
    Checks ProfileUnity Portability paths and active modules against FSLogix coexistence guardrails.
  #>
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)] [AllowEmptyCollection()] [string[]] $PortabilityPath,
    [AllowEmptyCollection()] [string[]] $EnabledModule = @(),
    [string] $GuardrailsPath = ''
  )
  if (-not $GuardrailsPath) {
    $GuardrailsPath = Join-Path (Get-LwDefaultTemplateDirectory) 'profileunity/fslogix-portability-guardrails.json'
  }
  $rules = Get-Content -LiteralPath $GuardrailsPath -Raw | ConvertFrom-Json
  $conflicts = [System.Collections.Generic.List[object]]::new()

  foreach ($mod in $EnabledModule) {
    foreach ($forbidden in $rules.forbiddenModulesWhenFslogixActive) {
      if ($mod -ieq $forbidden) {
        $conflicts.Add([pscustomobject]@{
            Kind           = 'ForbiddenModule'
            Candidate      = $mod
            ConflictingRule = $forbidden
            Reason         = "Module '$mod' conflicts with active FSLogix Profile Containers."
          })
      }
    }
  }

  foreach ($candidate in $PortabilityPath) {
    $normCandidate = $candidate.Trim().TrimEnd('\', '/').Replace('/', '\')
    foreach ($owned in $rules.fslogixOwnedPaths) {
      $normOwned = $owned.Trim().TrimEnd('\', '/').Replace('/', '\')
      if ($normCandidate -ieq $normOwned -or
        $normCandidate.StartsWith("$normOwned\", [System.StringComparison]::OrdinalIgnoreCase) -or
        $normOwned.StartsWith("$normCandidate\", [System.StringComparison]::OrdinalIgnoreCase)) {
        $conflicts.Add([pscustomobject]@{
            Kind            = 'PathOverlap'
            Candidate       = $candidate
            ConflictingRule = $owned
            Reason          = "Portability path '$candidate' overlaps FSLogix-managed path '$owned'."
          })
      }
    }
  }

  [pscustomobject]@{
    Passed    = ($conflicts.Count -eq 0)
    Conflicts = @($conflicts)
  }
}

function Get-LwSpotCheckThreshold {
  <#
  .SYNOPSIS
    Returns canonical Liquidware SpotCheck thresholds from templates/stratusphere/inspector-catalog.json.
  #>
  [CmdletBinding()]
  param(
    [string] $Metric = '',
    [string] $CatalogPath = ''
  )
  if (-not $CatalogPath) {
    $CatalogPath = Join-Path (Get-LwDefaultTemplateDirectory) 'stratusphere/inspector-catalog.json'
  }
  $catalog = Get-Content -LiteralPath $CatalogPath -Raw | ConvertFrom-Json
  $items = @($catalog.spotCheckThresholds)
  if ($Metric) {
    $items = @($items | Where-Object { $_.metric -ieq $Metric })
  }
  return $items
}

function ConvertTo-LwApiUrl {
  <#
  .SYNOPSIS
    Builds a Stratusphere UX /lwl/api?json=... URL from an inspector query specification.
  #>
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)] [string] $HubAddress,
    [Parameter(Mandatory)] [int] $Inspector,
    [Parameter(Mandatory)] [string] $Basis,
    [string[]] $Column = @(),
    [string] $StartDate = '',
    [string] $EndDate = '',
    [int] $StartTime = -1,
    [int] $EndTime = -1,
    [string] $Filter = '',
    [int] $Limit = 0
  )
  $cleanHub = $HubAddress.Trim() -replace '^https?://', '' -replace '/+$', ''
  if (-not $cleanHub) {
    throw 'HubAddress cannot be empty.'
  }

  $payload = [ordered]@{
    inspector = $Inspector
    basis     = $Basis
    limit     = $Limit
  }
  if ($Column.Count -gt 0) {
    $payload['columns'] = ($Column -join ',')
  }
  if ($StartDate -and $EndDate) {
    $payload['custom_start_date'] = $StartDate
    $payload['custom_end_date'] = $EndDate
  }
  if ($StartTime -ge 0 -and $EndTime -ge 0) {
    $payload['start_time'] = $StartTime
    $payload['end_time'] = $EndTime
  }
  if ($Filter) {
    $payload['filter'] = $Filter
  }

  $json = $payload | ConvertTo-Json -Compress
  $encoded = [System.Uri]::EscapeDataString($json)
  "https://$cleanHub/lwl/api?json=$encoded"
}

function Get-LwAssignmentConflict {
  <#
  .SYNOPSIS
    Finds applications assigned in more than one delivery plane (single assignment system rule).
  #>
  [CmdletBinding()]
  param(
    [AllowEmptyCollection()] [string[]] $AvdAppAttachApp = @(),
    [AllowEmptyCollection()] [string[]] $ProfileUnityFlexApp = @(),
    [AllowEmptyCollection()] [string[]] $NativeMsixApp = @()
  )
  $seen = @{}
  foreach ($source in @(
      @{ Name = 'AvdAppAttach'; Apps = $AvdAppAttachApp },
      @{ Name = 'ProfileUnityFlexApp'; Apps = $ProfileUnityFlexApp },
      @{ Name = 'NativeMsix'; Apps = $NativeMsixApp }
    )) {
    foreach ($app in $source.Apps) {
      if (-not $app) { continue }
      $key = $app.Trim().ToLowerInvariant()
      if (-not $seen.ContainsKey($key)) {
        $seen[$key] = [System.Collections.Generic.List[string]]::new()
      }
      if (-not $seen[$key].Contains($source.Name)) {
        $seen[$key].Add($source.Name)
      }
    }
  }

  $conflicts = [System.Collections.Generic.List[object]]::new()
  foreach ($k in ($seen.Keys | Sort-Object)) {
    if ($seen[$k].Count -gt 1) {
      $conflicts.Add([pscustomobject]@{
          Application = $k
          Planes      = @($seen[$k])
        })
    }
  }
  return @($conflicts)
}

Export-ModuleMember -Function @(
  'Test-LwPortabilityOverlap',
  'Get-LwSpotCheckThreshold',
  'ConvertTo-LwApiUrl',
  'Get-LwAssignmentConflict'
)

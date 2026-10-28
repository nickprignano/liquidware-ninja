#requires -Version 7.0
<#
.SYNOPSIS
  Pure cross-platform utility functions for Liquidware ProfileUnity, FlexApp, Stratusphere UX and CommandCTRL.
  Personal project, not for production use. Provided as is, without warranty of any kind. Not affiliated with the author's employer, with Liquidware or with Microsoft.
#>

Set-StrictMode -Version Latest

function Get-LwDefaultTemplateDirectory {
  [CmdletBinding()]
  param()
  Join-Path $PSScriptRoot '../../templates'
}

function ConvertTo-LwNormalizedPath {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)] [string] $PathText
  )
  $PathText.Trim().TrimEnd('\', '/').Replace('/', '\')
}

function Resolve-LwConfigInput {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)] [object] $InputObject
  )
  if ($InputObject -is [string]) {
    if (Test-Path -LiteralPath $InputObject) {
      return (Get-Content -LiteralPath $InputObject -Raw | ConvertFrom-Json)
    }
    return ($InputObject | ConvertFrom-Json)
  }
  if ($InputObject -is [System.Collections.IDictionary]) {
    return ([pscustomobject]$InputObject)
  }
  return $InputObject
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
            Kind            = 'ForbiddenModule'
            Candidate       = $mod
            ConflictingRule = $forbidden
            Reason          = "Module '$mod' conflicts with active FSLogix Profile Containers."
          })
      }
    }
  }

  foreach ($candidate in $PortabilityPath) {
    $normCandidate = ConvertTo-LwNormalizedPath -PathText $candidate
    foreach ($owned in $rules.fslogixOwnedPaths) {
      $normOwned = ConvertTo-LwNormalizedPath -PathText $owned
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

function Export-LwPortabilityRuleset {
  <#
  .SYNOPSIS
    Filters candidate Portability paths against FSLogix guardrails and outputs a clean ruleset object.
  #>
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)] [AllowEmptyCollection()] [string[]] $IncludePath,
    [string] $GuardrailsPath = ''
  )
  if (-not $GuardrailsPath) {
    $GuardrailsPath = Join-Path (Get-LwDefaultTemplateDirectory) 'profileunity/fslogix-portability-guardrails.json'
  }
  $rules = Get-Content -LiteralPath $GuardrailsPath -Raw | ConvertFrom-Json
  $included = [System.Collections.Generic.List[string]]::new()
  $removed = [System.Collections.Generic.List[string]]::new()

  foreach ($candidate in $IncludePath) {
    if (-not $candidate -or -not $candidate.Trim()) { continue }
    $normCandidate = ConvertTo-LwNormalizedPath -PathText $candidate
    $isOverlap = $false
    foreach ($owned in $rules.fslogixOwnedPaths) {
      $normOwned = ConvertTo-LwNormalizedPath -PathText $owned
      if ($normCandidate -ieq $normOwned -or
        $normCandidate.StartsWith("$normOwned\", [System.StringComparison]::OrdinalIgnoreCase) -or
        $normOwned.StartsWith("$normCandidate\", [System.StringComparison]::OrdinalIgnoreCase)) {
        $isOverlap = $true
        break
      }
    }
    if ($isOverlap) {
      if (-not $removed.Contains($candidate)) {
        $removed.Add($candidate)
      }
    } else {
      if (-not $included.Contains($candidate)) {
        $included.Add($candidate)
      }
    }
  }

  [pscustomobject]@{
    Schema               = 'liquidware-ninja-portability-ruleset/v1'
    IncludedPaths        = @($included)
    ExcludedFslogixPaths = @($rules.fslogixOwnedPaths)
    RemovedOverlaps      = @($removed)
  }
}

function Compare-LwProfileUnityConfig {
  <#
  .SYNOPSIS
    Diffs two ProfileUnity configuration exports (JSON paths, JSON strings, hashtables, or objects).
  #>
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)] [object] $ReferenceConfig,
    [Parameter(Mandatory)] [object] $DifferenceConfig
  )
  $ref = Resolve-LwConfigInput -InputObject $ReferenceConfig
  $diff = Resolve-LwConfigInput -InputObject $DifferenceConfig

  $refModules = @($ref.enabledModules | ForEach-Object { [string]$_ })
  $diffModules = @($diff.enabledModules | ForEach-Object { [string]$_ })
  $addedModules = @($diffModules | Where-Object { $m = $_; -not ($refModules | Where-Object { $_ -ieq $m }) })
  $removedModules = @($refModules | Where-Object { $m = $_; -not ($diffModules | Where-Object { $_ -ieq $m }) })

  $refPaths = @($ref.portabilityPaths | ForEach-Object { [string]$_ })
  $diffPaths = @($diff.portabilityPaths | ForEach-Object { [string]$_ })
  $addedPaths = @($diffPaths | Where-Object { $p = $_; -not ($refPaths | Where-Object { $_ -ieq $p }) })
  $removedPaths = @($refPaths | Where-Object { $p = $_; -not ($diffPaths | Where-Object { $_ -ieq $p }) })

  $refRestr = @($ref.applicationRestrictions | ForEach-Object { [string]$_ })
  $diffRestr = @($diff.applicationRestrictions | ForEach-Object { [string]$_ })
  $addedRestr = @($diffRestr | Where-Object { $r = $_; -not ($refRestr | Where-Object { $_ -ieq $r }) })
  $removedRestr = @($refRestr | Where-Object { $r = $_; -not ($diffRestr | Where-Object { $_ -ieq $r }) })

  $configNameChanged = ([string]$ref.configName -cne [string]$diff.configName)
  $iniHashChanged = ([string]$ref.iniSha256 -ine [string]$diff.iniSha256)

  $hasChanges = (
    $configNameChanged -or
    $iniHashChanged -or
    ($addedModules.Count -gt 0) -or
    ($removedModules.Count -gt 0) -or
    ($addedPaths.Count -gt 0) -or
    ($removedPaths.Count -gt 0) -or
    ($addedRestr.Count -gt 0) -or
    ($removedRestr.Count -gt 0)
  )

  [pscustomobject]@{
    ConfigNameChanged       = $configNameChanged
    IniHashChanged          = $iniHashChanged
    AddedModules            = $addedModules
    RemovedModules          = $removedModules
    AddedPortabilityPaths   = $addedPaths
    RemovedPortabilityPaths = $removedPaths
    AddedRestrictions       = $addedRestr
    RemovedRestrictions     = $removedRestr
    HasChanges              = $hasChanges
  }
}

function Test-LwFlexAppCandidate {
  <#
  .SYNOPSIS
    Scores an application for FlexApp packaging suitability based on Stratusphere UX discovery metrics.
  #>
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)] [string] $AppName,
    [Parameter(Mandatory)] [ValidateRange(0.0, 100.0)] [double] $UserShare,
    [bool] $HasKernelDriver = $false,
    [bool] $HasSystemService = $false,
    [bool] $HasShellExtension = $false,
    [int] $VersionCount = 1,
    [bool] $OfflineCapableRequired = $false
  )
  $reasons = [System.Collections.Generic.List[string]]::new()
  $recommended = 'FlexAppAppAttach'

  if ($HasKernelDriver -or $HasSystemService) {
    $recommended = 'NotRecommendedForLayering'
    if ($HasKernelDriver) {
      $reasons.Add('Application includes a kernel-mode driver; install in the base image or via native Win32/Intune installer.')
    }
    if ($HasSystemService) {
      $reasons.Add('Application registers a boot-start or persistent system service not suited for dynamic session layering.')
    }
  } elseif ($VersionCount -gt 3) {
    $recommended = 'VersionConsolidationFirst'
    $reasons.Add("Application has $VersionCount distinct versions in the field; consolidate versions before capturing a FlexApp package.")
  } elseif ($UserShare -gt 80.0) {
    $recommended = 'BaseImage'
    $reasons.Add("User share ($UserShare%) exceeds 80%; bake into the base image to avoid per-logon attach overhead.")
  } elseif ($OfflineCapableRequired) {
    $recommended = 'FlexAppOne'
    $reasons.Add('Offline capability is required; package as a self-contained FlexApp One executable.')
  } else {
    $recommended = 'FlexAppAppAttach'
    $reasons.Add("User share ($UserShare%) is in the layering band with no kernel drivers or system services.")
  }

  if ($HasShellExtension -and $recommended -in @('FlexAppAppAttach', 'FlexAppOne')) {
    $reasons.Add('Application includes Explorer shell extensions; validate shell registration on target multi-session build in QA ring.')
  }

  [pscustomobject]@{
    AppName             = $AppName
    RecommendedDelivery = $recommended
    Reasons             = @($reasons)
  }
}

function New-LwFlexAppManifest {
  <#
  .SYNOPSIS
    Builds and validates a liquidware-ninja-flexapp-package/v1 metadata manifest object.
  #>
  [CmdletBinding(SupportsShouldProcess)]
  param(
    [Parameter(Mandatory)] [string] $App,
    [Parameter(Mandatory)] [string] $DisplayName,
    [Parameter(Mandatory)] [string] $Version,
    [ValidateSet('VHDX', 'CimFS')] [string] $Format = 'VHDX',
    [ValidateSet('AvdAppAttach', 'ProfileUnityFlexApp', 'FlexAppOne')] [string] $DeliveryMode = 'AvdAppAttach',
    [ValidateSet('AvdControlPlane', 'ProfileUnityConsole', 'Intune')] [string] $AssignmentPlane = 'AvdControlPlane',
    [Parameter(Mandatory)] [string] $SharePath,
    [Parameter(Mandatory)] [string] $Sha256,
    [Parameter(Mandatory)] [int64] $SizeBytes,
    [Parameter(Mandatory)] [string] $OsBuildCapturedOn,
    [string] $FallbackInstallMethod = 'intune-win32',
    [ValidateSet('Canary', 'QA', 'Prod')] [string] $Ring = 'QA'
  )
  if ($Sha256 -notmatch '^[0-9a-fA-F]{64}$') {
    throw "Sha256 '$Sha256' must be a 64-character hexadecimal SHA-256 digest."
  }
  if ($SizeBytes -le 0) {
    throw 'SizeBytes must be greater than zero.'
  }
  if ($DeliveryMode -eq 'AvdAppAttach' -and $AssignmentPlane -ne 'AvdControlPlane') {
    throw "When DeliveryMode is 'AvdAppAttach', AssignmentPlane must be 'AvdControlPlane' (single assignment system rule)."
  }

  if ($PSCmdlet.ShouldProcess($App, 'Create FlexApp manifest')) {
    [pscustomobject]@{
      schema                = 'liquidware-ninja-flexapp-package/v1'
      app                   = $App.Trim().ToLowerInvariant()
      displayName           = $DisplayName.Trim()
      version               = $Version.Trim()
      format                = $Format
      deliveryMode          = $DeliveryMode
      assignmentPlane       = $AssignmentPlane
      sharePath             = $SharePath.Trim()
      sha256                = $Sha256.ToLowerInvariant()
      sizeBytes             = $SizeBytes
      osBuildCapturedOn     = $OsBuildCapturedOn.Trim()
      fallbackInstallMethod = $FallbackInstallMethod.Trim()
      ring                  = $Ring
    }
  }
}

function Test-LwCommandCtrlBaseline {
  <#
  .SYNOPSIS
    Validates a CommandCTRL host configuration against templates/commandctrl/multisession-baseline.json.
  #>
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)] [object] $Configuration,
    [string] $BaselinePath = ''
  )
  if (-not $BaselinePath) {
    $BaselinePath = Join-Path (Get-LwDefaultTemplateDirectory) 'commandctrl/multisession-baseline.json'
  }
  $baseline = Get-Content -LiteralPath $BaselinePath -Raw | ConvertFrom-Json
  $cfg = Resolve-LwConfigInput -InputObject $Configuration
  $violations = [System.Collections.Generic.List[string]]::new()

  if ([bool]$cfg.RemoteControlEnabled -ne [bool]$baseline.remoteControlDefaultEnabled) {
    $violations.Add('RemoteControlEnabled must be false by default on managed hosts.')
  }
  if ([bool]$cfg.RemoteShellEnabled -ne [bool]$baseline.remoteShellDefaultEnabled) {
    $violations.Add('RemoteShellEnabled must be false by default on managed hosts.')
  }
  if ([bool]$baseline.requireUserConsent -and (-not [bool]$cfg.RequireUserConsent)) {
    $violations.Add('RequireUserConsent must be true before interactive intervention.')
  }
  if ((-not [bool]$baseline.allowAgentOrAutomationAccess) -and [bool]$cfg.AgentAccessAllowed) {
    $violations.Add('AgentAccessAllowed must be false; automated agents must not hold CommandCTRL remote shell/control roles.')
  }
  if ([int]$cfg.SamplingIntervalSeconds -lt [int]$baseline.minSamplingIntervalSeconds) {
    $violations.Add("SamplingIntervalSeconds ($($cfg.SamplingIntervalSeconds)s) is below minimum baseline ($($baseline.minSamplingIntervalSeconds)s).")
  }
  if ([bool]$cfg.IsMultiSession) {
    if ((-not [bool]$baseline.captureCommandLinesOnMultiSession) -and [bool]$cfg.CaptureCommandLines) {
      $violations.Add('CaptureCommandLines must be disabled on multi-session hosts.')
    }
    if ((-not [bool]$baseline.captureWindowTitlesOnMultiSession) -and [bool]$cfg.CaptureWindowTitles) {
      $violations.Add('CaptureWindowTitles must be disabled on multi-session hosts.')
    }
    if ((-not [bool]$baseline.captureBrowserUrlsOnMultiSession) -and [bool]$cfg.CaptureBrowserUrls) {
      $violations.Add('CaptureBrowserUrls must be disabled on multi-session hosts.')
    }
  }
  if ([bool]$baseline.disableHistoryWhenStratusphereActive -and [bool]$cfg.StratusphereActive -and [bool]$cfg.HistoryEnabled) {
    $violations.Add('HistoryEnabled must be disabled when Stratusphere UX CID Key is active on the same endpoint.')
  }

  [pscustomobject]@{
    Passed     = ($violations.Count -eq 0)
    Violations = @($violations)
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
  'Export-LwPortabilityRuleset',
  'Compare-LwProfileUnityConfig',
  'Test-LwFlexAppCandidate',
  'New-LwFlexAppManifest',
  'Test-LwCommandCtrlBaseline',
  'Get-LwSpotCheckThreshold',
  'ConvertTo-LwApiUrl',
  'Get-LwAssignmentConflict'
)

#requires -Version 7.0
BeforeAll {
  $script:RepoRoot = Resolve-Path (Join-Path $PSScriptRoot '..')
  $script:ModulePath = Join-Path $script:RepoRoot 'scripts/tools/LiquidwareNinja.psm1'
  $script:CidScriptPath = Join-Path $script:RepoRoot 'scripts/tools/Test-LwCidKeyHealth.ps1'
  Import-Module $script:ModulePath -Force
}

Describe 'Test-LwPortabilityOverlap' {
  It 'passes when Portability paths do not overlap FSLogix-owned paths' {
    $res = Test-LwPortabilityOverlap -PortabilityPath @(
      '%APPDATA%\Notepad++',
      '%LOCALAPPDATA%\Contoso\LineOfBusinessApp'
    )
    $res.Passed | Should -BeTrue
    $res.Conflicts.Count | Should -Be 0
  }

  It 'flags direct and child path overlaps with FSLogix-owned paths' {
    $res = Test-LwPortabilityOverlap -PortabilityPath @(
      '%LOCALAPPDATA%\Microsoft\OneDrive\settings',
      '%APPDATA%\Microsoft\Teams'
    )
    $res.Passed | Should -BeFalse
    $res.Conflicts.Count | Should -Be 2
    $res.Conflicts[0].Kind | Should -Be 'PathOverlap'
  }

  It 'flags forbidden full profile disk modules when FSLogix is active' {
    $res = Test-LwPortabilityOverlap -PortabilityPath @() -EnabledModule @('Portability', 'ProfileDisk')
    $res.Passed | Should -BeFalse
    $res.Conflicts.Count | Should -Be 1
    $res.Conflicts[0].Kind | Should -Be 'ForbiddenModule'
  }
}

Describe 'Export-LwPortabilityRuleset' {
  It 'strips FSLogix-overlapping paths and preserves safe application paths' {
    $res = Export-LwPortabilityRuleset -IncludePath @(
      '%APPDATA%\Notepad++',
      '%APPDATA%\SAP\Common',
      '%LOCALAPPDATA%\Microsoft\Outlook\RoamCache',
      '%LOCALAPPDATA%\Temp\Scratch'
    )
    $res.Schema | Should -Be 'liquidware-ninja-portability-ruleset/v1'
    $res.IncludedPaths | Should -Contain '%APPDATA%\Notepad++'
    $res.IncludedPaths | Should -Contain '%APPDATA%\SAP\Common'
    $res.IncludedPaths.Count | Should -Be 2
    $res.RemovedOverlaps.Count | Should -Be 2
    $res.ExcludedFslogixPaths.Count | Should -BeGreaterOrEqual 9
  }
}

Describe 'Compare-LwProfileUnityConfig' {
  It 'reports HasChanges = false when comparing sample-config-export.json to itself' {
    $samplePath = Join-Path $script:RepoRoot 'templates/profileunity/sample-config-export.json'
    $diff = Compare-LwProfileUnityConfig -ReferenceConfig $samplePath -DifferenceConfig $samplePath
    $diff.HasChanges | Should -BeFalse
    $diff.ConfigNameChanged | Should -BeFalse
    $diff.IniHashChanged | Should -BeFalse
    $diff.AddedModules.Count | Should -Be 0
    $diff.RemovedModules.Count | Should -Be 0
  }

  It 'detects added/removed modules, Portability paths, restrictions, and INI hash changes' {
    $samplePath = Join-Path $script:RepoRoot 'templates/profileunity/sample-config-export.json'
    $candidate = @{
      configName              = 'AVD-Win11-MultiSession-Prod'
      iniSha256               = '1111111111111111111111111111111111111111111111111111111111111111'
      enabledModules          = @('Portability', 'ContextFilter', 'FlexApp')
      portabilityPaths        = @('%APPDATA%\Notepad++', '%APPDATA%\Contoso\NewApp')
      applicationRestrictions = @('%USERPROFILE%\Downloads\*.exe', '%APPDATA%\*.vbs')
    }
    $diff = Compare-LwProfileUnityConfig -ReferenceConfig $samplePath -DifferenceConfig $candidate
    $diff.HasChanges | Should -BeTrue
    $diff.IniHashChanged | Should -BeTrue
    $diff.AddedModules | Should -Contain 'FlexApp'
    $diff.RemovedModules | Should -Contain 'ApplicationRestrictions'
    $diff.RemovedModules | Should -Contain 'PrivilegeElevation'
    $diff.AddedPortabilityPaths | Should -Contain '%APPDATA%\Contoso\NewApp'
    $diff.RemovedPortabilityPaths | Should -Contain '%APPDATA%\SAP\Common'
    $diff.AddedRestrictions | Should -Contain '%APPDATA%\*.vbs'
  }
}

Describe 'Test-LwFlexAppCandidate' {
  It 'recommends BaseImage when user share exceeds 80%' {
    $res = Test-LwFlexAppCandidate -AppName 'Microsoft Edge' -UserShare 95.0
    $res.RecommendedDelivery | Should -Be 'BaseImage'
  }

  It 'recommends NotRecommendedForLayering when a kernel driver or system service is present' {
    $res = Test-LwFlexAppCandidate -AppName 'Contoso VPN Client' -UserShare 40.0 -HasKernelDriver $true
    $res.RecommendedDelivery | Should -Be 'NotRecommendedForLayering'
  }

  It 'recommends VersionConsolidationFirst when more than 3 versions exist in the estate' {
    $res = Test-LwFlexAppCandidate -AppName 'Java Runtime' -UserShare 35.0 -VersionCount 6
    $res.RecommendedDelivery | Should -Be 'VersionConsolidationFirst'
  }

  It 'recommends FlexAppOne when offline capability is required' {
    $res = Test-LwFlexAppCandidate -AppName 'Field Inspector Tool' -UserShare 25.0 -OfflineCapableRequired $true
    $res.RecommendedDelivery | Should -Be 'FlexAppOne'
  }

  It 'recommends FlexAppAppAttach for standard departmental apps and notes shell extensions' {
    $res = Test-LwFlexAppCandidate -AppName '7-Zip' -UserShare 45.0 -HasShellExtension $true
    $res.RecommendedDelivery | Should -Be 'FlexAppAppAttach'
    ($res.Reasons -join ' ') | Should -Match 'shell extensions'
  }
}

Describe 'New-LwFlexAppManifest' {
  It 'creates a valid liquidware-ninja-flexapp-package/v1 manifest matching the example schema' {
    $m = New-LwFlexAppManifest `
      -App 'Contoso-Reader' `
      -DisplayName 'Contoso Document Reader' `
      -Version '2.4.1' `
      -Format 'VHDX' `
      -DeliveryMode 'AvdAppAttach' `
      -AssignmentPlane 'AvdControlPlane' `
      -SharePath '\\stavdlzdevlwp001.file.core.windows.net\appattach\contoso-reader\2.4.1\contoso-reader.vhdx' `
      -Sha256 '0000000000000000000000000000000000000000000000000000000000000000' `
      -SizeBytes 536870912 `
      -OsBuildCapturedOn 'win11-24h2-ent' `
      -Ring 'QA'
    $m.schema | Should -Be 'liquidware-ninja-flexapp-package/v1'
    $m.app | Should -Be 'contoso-reader'
    $m.deliveryMode | Should -Be 'AvdAppAttach'
    $m.assignmentPlane | Should -Be 'AvdControlPlane'
  }

  It 'rejects an invalid SHA-256 digest or mismatched AvdAppAttach assignment plane' {
    {
      New-LwFlexAppManifest `
        -App 'bad-hash' `
        -DisplayName 'Bad Hash' `
        -Version '1.0.0' `
        -SharePath '\\server\share\bad.vhdx' `
        -Sha256 'not-a-sha256' `
        -SizeBytes 1024 `
        -OsBuildCapturedOn 'win11-24h2-ent'
    } | Should -Throw '*64-character*'

    {
      New-LwFlexAppManifest `
        -App 'dual-plane' `
        -DisplayName 'Dual Plane' `
        -Version '1.0.0' `
        -DeliveryMode 'AvdAppAttach' `
        -AssignmentPlane 'ProfileUnityConsole' `
        -SharePath '\\server\share\dual.vhdx' `
        -Sha256 '0000000000000000000000000000000000000000000000000000000000000000' `
        -SizeBytes 1024 `
        -OsBuildCapturedOn 'win11-24h2-ent'
    } | Should -Throw '*single assignment system rule*'
  }
}

Describe 'Test-LwCommandCtrlBaseline' {
  It 'passes when multi-session CommandCTRL settings comply with multisession-baseline.json' {
    $res = Test-LwCommandCtrlBaseline -Configuration @{
      RemoteControlEnabled    = $false
      RemoteShellEnabled      = $false
      RequireUserConsent      = $true
      AgentAccessAllowed      = $false
      SamplingIntervalSeconds = 60
      CaptureCommandLines     = $false
      CaptureWindowTitles     = $false
      CaptureBrowserUrls      = $false
      HistoryEnabled          = $false
      StratusphereActive      = $true
      IsMultiSession          = $true
    }
    $res.Passed | Should -BeTrue
    $res.Violations.Count | Should -Be 0
  }

  It 'flags privacy, consent, agent-access, and Stratusphere coexistence violations' {
    $res = Test-LwCommandCtrlBaseline -Configuration @{
      RemoteControlEnabled    = $true
      RemoteShellEnabled      = $true
      RequireUserConsent      = $false
      AgentAccessAllowed      = $true
      SamplingIntervalSeconds = 15
      CaptureCommandLines     = $true
      CaptureWindowTitles     = $true
      CaptureBrowserUrls      = $true
      HistoryEnabled          = $true
      StratusphereActive      = $true
      IsMultiSession          = $true
    }
    $res.Passed | Should -BeFalse
    $res.Violations.Count | Should -Be 9
  }
}

Describe 'Get-LwSpotCheckThreshold' {
  It 'returns all SpotCheck thresholds with their sources' {
    $all = @(Get-LwSpotCheckThreshold)
    $all.Count | Should -BeGreaterOrEqual 8
    ($all | Where-Object metric -eq 'cpu_used_pct').threshold | Should -Be 80.0
    ($all | Where-Object metric -eq 'login_duration_s').source | Should -Be 'Liquidware SpotCheck'
  }

  It 'filters to a single metric case-insensitively' {
    $m = @(Get-LwSpotCheckThreshold -Metric 'DISK_QUEUE_AVG')
    $m.Count | Should -Be 1
    $m[0].threshold | Should -Be 2.0
  }
}

Describe 'ConvertTo-LwApiUrl' {
  It 'builds a URL-encoded Stratusphere API URL with time window and columns' {
    $url = ConvertTo-LwApiUrl -HubAddress 'https://10.60.0.4/' -Inspector 4 -Basis 'machines' `
      -Column @('node_name', 'cpu_cores') -StartDate '2026-11-01' -EndDate '2026-11-14'
    $url | Should -Match '^https://10\.60\.0\.4/lwl/api\?json='
    $decoded = [System.Uri]::UnescapeDataString(($url -split '\?json=')[1]) | ConvertFrom-Json
    $decoded.inspector | Should -Be 4
    $decoded.basis | Should -Be 'machines'
    $decoded.columns | Should -Be 'node_name,cpu_cores'
    $decoded.custom_start_date | Should -Be '2026-11-01'
  }
}

Describe 'Get-LwAssignmentConflict' {
  It 'detects an application assigned in both AVD App Attach and ProfileUnity FlexApp' {
    $conflicts = @(Get-LwAssignmentConflict `
        -AvdAppAttachApp @('contoso-reader', '7zip') `
        -ProfileUnityFlexApp @('Contoso-Reader') `
        -NativeMsixApp @('vscode'))
    $conflicts.Count | Should -Be 1
    $conflicts[0].Application | Should -Be 'contoso-reader'
    $conflicts[0].Planes | Should -Contain 'AvdAppAttach'
    $conflicts[0].Planes | Should -Contain 'ProfileUnityFlexApp'
  }
}

Describe 'Test-LwCidKeyHealth.ps1' {
  It 'parses cleanly with zero AST errors and includes the personal-project header notice' {
    $tokens = $null
    $parseErrors = $null
    $ast = [System.Management.Automation.Language.Parser]::ParseFile(
      $script:CidScriptPath,
      [ref]$tokens,
      [ref]$parseErrors
    )
    $parseErrors.Count | Should -Be 0
    $raw = Get-Content -LiteralPath $script:CidScriptPath -Raw
    $raw | Should -Match '#requires -Version 5\.1'
    $raw | Should -Match 'Personal project, not for production use'
    # Ensure no PS7-only null-coalescing or ternary operators exist
    $ast.Extent.Text | Should -Not -Match '\?\?'
  }

  It 'returns PASS when install path exists, tntgrd is Running, and Hub port 443 is reachable' {
    $res = & $script:CidScriptPath `
      -HubAddress '10.60.0.4' `
      -MockExistingPaths @('C:\Program Files (x86)\Liquidware Labs\Connector ID') `
      -MockServices @([pscustomobject]@{ Name = 'tntgrd'; Status = 'Running' }) `
      -MockTcpConnected $true `
      -Quiet
    $res.Status | Should -Be 'PASS'
    $res.Checks.Count | Should -Be 3
  }

  It 'returns FAIL when neither tntgrd nor LwL.ConnectorID service is installed' {
    $res = & $script:CidScriptPath `
      -SkipNetworkCheck `
      -MockExistingPaths @() `
      -MockServices @() `
      -Quiet
    $res.Status | Should -Be 'FAIL'
    ($res.Checks | Where-Object Name -eq 'AgentService').Status | Should -Be 'FAIL'
  }

  It 'returns FAIL when Hub TCP connectivity fails' {
    $res = & $script:CidScriptPath `
      -HubAddress '10.60.0.4' `
      -MockExistingPaths @('C:\Program Files (x86)\Liquidware Labs\Connector ID') `
      -MockServices @([pscustomobject]@{ Name = 'LwL.ConnectorID'; Status = 'Running' }) `
      -MockTcpConnected $false `
      -Quiet
    $res.Status | Should -Be 'FAIL'
    ($res.Checks | Where-Object Name -eq 'HubConnectivity').Status | Should -Be 'FAIL'
  }
}

Describe 'Blog posts front matter and public-safe hygiene' {
  It 'validates front matter and zero leaks across all blog posts' {
    $blogDir = Join-Path $script:RepoRoot 'blog'
    $posts = @(Get-ChildItem -LiteralPath $blogDir -Filter '*.md' | Where-Object { $_.Name -ne 'README.md' })
    $posts.Count | Should -BeGreaterOrEqual 3

    foreach ($post in $posts) {
      $content = Get-Content -LiteralPath $post.FullName -Raw
      $fmMatch = [regex]::Match($content, '(?s)\A---\r?\n(.+?)\r?\n---\r?\n')
      $fmMatch.Success | Should -BeTrue
      $frontMatter = $fmMatch.Groups[1].Value
      $frontMatter | Should -Match '(?m)^title:\s+\S+'
      $frontMatter | Should -Match '(?m)^date:\s+\d{4}-\d{2}-\d{2}\s*$'
      $frontMatter | Should -Match '(?m)^summary:\s+\S+'
      $frontMatter | Should -Match '(?m)^tags:\s*$'
      $frontMatter | Should -Match '(?m)^status:\s+(published|draft)\s*$'

      # Check no non-placeholder emails
      $emails = [regex]::Matches($content, '\b[A-Za-z0-9._%+-]+@([A-Za-z0-9.-]+\.[A-Za-z]{2,})\b')
      foreach ($m in $emails) {
        $domain = $m.Groups[1].Value.ToLowerInvariant()
        $domain | Should -BeIn @('contoso.com', 'example.com', 'users.noreply.github.com')
      }
    }
  }
}

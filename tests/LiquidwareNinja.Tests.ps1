#requires -Version 7.0
BeforeAll {
  Import-Module (Join-Path $PSScriptRoot '../scripts/tools/LiquidwareNinja.psm1') -Force
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

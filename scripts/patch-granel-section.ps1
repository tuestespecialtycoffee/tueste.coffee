$root = Split-Path $PSScriptRoot -Parent
$esGrid = Get-Content "$PSScriptRoot\granel-grid-es.html" -Raw -Encoding UTF8
$enGrid = Get-Content "$PSScriptRoot\granel-grid-en.html" -Raw -Encoding UTF8

function Patch-File($path, $grid) {
  $content = Get-Content $path -Raw -Encoding UTF8
  $startMarker = '<div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(280px, 1fr)); gap: 1.25rem; margin-top: 2rem;">'
  $endMarker = '<p style="margin-top: 1.5rem; font-size: 0.875rem; color: var(--madera); text-align: center;">'
  $startIdx = $content.IndexOf($startMarker)
  $endIdx = $content.IndexOf($endMarker)
  if ($startIdx -lt 0 -or $endIdx -lt 0) { throw "Markers not found in $path" }
  $before = $content.Substring(0, $startIdx + $startMarker.Length)
  $after = $content.Substring($endIdx)
  $newContent = $before + "`n" + $grid + "`n          </div>`n          " + $after
  # Fix: we need closing div for grid - the endMarker is after </div>
  # Structure: <div grid> CARDS </div> <p footnote>
  # before includes opening div, after starts with footnote p - we lost </div>
}

# Simpler regex approach
function Patch-File2($path, $grid) {
  $content = Get-Content $path -Raw -Encoding UTF8
  $pattern = '(?s)(<div style="display: grid; grid-template-columns: repeat\(auto-fit, minmax\(280px, 1fr\)\); gap: 1\.25rem; margin-top: 2rem;">).*?(</div>\s*<p style="margin-top: 1\.5rem; font-size: 0\.875rem; color: var\(--madera\); text-align: center;">)'
  $replacement = "`${1}`n$grid`n          `${2}"
  $newContent = [regex]::Replace($content, $pattern, $replacement)
  if ($newContent -eq $content) { throw "No replacement in $path" }
  $utf8NoBom = New-Object System.Text.UTF8Encoding $false
  [System.IO.File]::WriteAllText($path, $newContent, $utf8NoBom)
  Write-Host "Patched $path"
}

Patch-File2 (Join-Path $root 'index.html') $esGrid
Patch-File2 (Join-Path $root 'index-en.html') $enGrid

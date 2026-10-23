$json = Get-Content "$PSScriptRoot\granel-coffees.json" -Raw -Encoding UTF8 | ConvertFrom-Json

function Render-Cards($coffees, $lang) {
  $sb = New-Object System.Text.StringBuilder
  foreach ($c in $coffees) {
    $name = if ($lang -eq 'en') { $c.nameEn } else { $c.nameEs }
    $process = if ($lang -eq 'en') { $c.processEn } else { $c.processEs }
    $notes = if ($lang -eq 'en') { $c.notesEn } else { $c.notesEs }
    $meta = if ($lang -eq 'en') { $c.metaEn } else { $c.metaEs }

    [void]$sb.AppendLine('            <div class="card coffee-card" style="background: #231813; border-color: rgba(235, 199, 163, 0.2);">')
    if ($c.sca) {
      [void]$sb.AppendLine("              <span class=""coffee-sca-badge"">SCA $($c.sca)</span>")
    }
    [void]$sb.AppendLine("              <h3 style=""font-family: 'STIX Two Text', serif; font-size: 1.25rem; color: #f7efe7; margin: 0 0 0.5rem 0;"">$name</h3>")
    [void]$sb.AppendLine("              <p style=""font-size: 0.875rem; color: #d7b99a; margin: 0 0 0.5rem 0; text-transform: uppercase; letter-spacing: 0.1em;"">$process</p>")
    if ($meta) {
      [void]$sb.AppendLine("              <p style=""font-size: 0.8125rem; color: #c9a882; margin: 0 0 0.75rem 0;"">$meta</p>")
    }
    [void]$sb.AppendLine("              <p style=""font-size: 0.9375rem; color: #e0b98f; margin: 0 0 1rem 0;"">$notes</p>")
    [void]$sb.AppendLine('              <div class="flavor-profile">')
    foreach ($f in $c.flavors) {
      $parts = $f -split ':'
      [void]$sb.AppendLine("                <span class=""flavor-segment $($parts[0])"" style=""width: $($parts[1])%;""></span>")
    }
    [void]$sb.AppendLine('              </div>')
    $consult = if ($lang -eq 'en') { "Ask us what's available and the price" } else { 'Consúltanos qué hay disponible y el precio' }
    [void]$sb.AppendLine("              <p style=""margin: 1rem 0 0; padding-top: 1rem; border-top: 0.0625rem solid rgba(235, 199, 163, 0.15); font-size: 0.9375rem; font-weight: 600; color: #f7efe7;"">$consult</p>")
    [void]$sb.AppendLine('            </div>')
  }
  return $sb.ToString().TrimEnd()
}

$utf8NoBom = New-Object System.Text.UTF8Encoding $false
[System.IO.File]::WriteAllText("$PSScriptRoot\granel-grid-es.html", (Render-Cards $json 'es'), $utf8NoBom)
[System.IO.File]::WriteAllText("$PSScriptRoot\granel-grid-en.html", (Render-Cards $json 'en'), $utf8NoBom)
Write-Host "Generated granel-grid-es.html and granel-grid-en.html"

# Optimiza imagenes para web: redimensiona (max 1000px) y guarda como JPEG calidad 70
# Requiere .NET / System.Drawing (Windows)
$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Drawing

$baseDir = "c:\Users\FX505\.cursor\projects"
$maxPixels = 1000
$jpegQuality = 70

# Codificador de calidad JPEG
$codec = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() | Where-Object { $_.MimeType -eq "image/jpeg" }
$encoder = [System.Drawing.Imaging.Encoder]::Quality
$encoderParams = New-Object System.Drawing.Imaging.EncoderParameters(1)
$encoderParams.Param[0] = New-Object System.Drawing.Imaging.EncoderParameter($encoder, $jpegQuality)

function Resize-Image {
    param([string]$Path, [string]$OutPath, [bool]$AsJpeg)
    $img = [System.Drawing.Image]::FromFile((Resolve-Path $Path))
    try {
        $w = $img.Width
        $h = $img.Height
        if ($w -le $maxPixels -and $h -le $maxPixels) {
            $nw = $w
            $nh = $h
        } else {
            if ($w -ge $h) {
                $nw = $maxPixels
                $nh = [int]($h * $maxPixels / $w)
            } else {
                $nh = $maxPixels
                $nw = [int]($w * $maxPixels / $h)
            }
        }
        $bmp = New-Object System.Drawing.Bitmap($nw, $nh)
        $g = [System.Drawing.Graphics]::FromImage($bmp)
        $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
        $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
        $g.DrawImage($img, 0, 0, $nw, $nh)
        $g.Dispose()
        if ($AsJpeg) {
            $bmp.Save($OutPath, $codec, $encoderParams)
        } else {
            $bmp.Save($OutPath, [System.Drawing.Imaging.ImageFormat]::Png)
        }
        $bmp.Dispose()
        $origKb = [math]::Round((Get-Item $Path).Length / 1KB, 1)
        $newKb = [math]::Round((Get-Item $OutPath).Length / 1KB, 1)
        Write-Host "  $([System.IO.Path]::GetFileName($Path)) -> $([System.IO.Path]::GetFileName($OutPath)) ${origKb}KB -> ${newKb}KB"
    } finally {
        $img.Dispose()
    }
}

# Marca: fotos a JPG (mantener logo PNG)
$marcaDir = Join-Path $baseDir "marca"
$marcaPhotos = @("imagen taza granos.png", "imagen cookie.png", "cuaderno cafe.png", "herramientas cafe.png")
foreach ($f in $marcaPhotos) {
    $p = Join-Path $marcaDir $f
    if (Test-Path $p) {
        $out = Join-Path $marcaDir ($f -replace "\.png$", ".jpg")
        Write-Host "Marca: $f"
        Resize-Image -Path $p -OutPath $out -AsJpeg $true
        Remove-Item $p -Force
    }
}
# Reoptimizar JPG existentes en marca con nueva calidad
Get-ChildItem -Path $marcaDir -Filter "*.jpg" | ForEach-Object {
    $temp = Join-Path $marcaDir "temp_$($_.Name)"
    Write-Host "Reoptimizando marca: $($_.Name)"
    Resize-Image -Path $_.FullName -OutPath $temp -AsJpeg $true
    Remove-Item $_.FullName -Force
    Rename-Item $temp $_.Name
}

# Logo: solo redimensionar si es muy grande, mantener PNG
$logoPath = Join-Path $marcaDir "TUESTE-1.png"
if (Test-Path $logoPath) {
    $img = $null
    try {
        $img = [System.Drawing.Image]::FromFile((Resolve-Path $logoPath))
        if ($img.Width -gt $maxPixels -or $img.Height -gt $maxPixels) {
            $temp = Join-Path $marcaDir "TUESTE-1_temp.png"
            Resize-Image -Path $logoPath -OutPath $temp -AsJpeg $false
            $img.Dispose(); $img = $null
            Remove-Item $logoPath -Force -ErrorAction SilentlyContinue
            if (Test-Path $temp) { Move-Item $temp $logoPath -Force }
        }
    } finally { if ($img) { $img.Dispose() } }
}

# Assets: todas las PNG a JPG optimizadas, y reoptimizar JPG existentes
$assetsDir = Join-Path $baseDir "assets"
Get-ChildItem -Path $assetsDir -Filter "*.png" | ForEach-Object {
    $out = $_.FullName -replace "\.png$", ".jpg"
    Write-Host "Assets: $($_.Name)"
    Resize-Image -Path $_.FullName -OutPath $out -AsJpeg $true
    Remove-Item $_.FullName -Force
}
# Reoptimizar JPG existentes con nueva calidad
Get-ChildItem -Path $assetsDir -Filter "*.jpg" | ForEach-Object {
    $temp = Join-Path $assetsDir "temp_$($_.Name)"
    Write-Host "Reoptimizando: $($_.Name)"
    Resize-Image -Path $_.FullName -OutPath $temp -AsJpeg $true
    Remove-Item $_.FullName -Force
    Rename-Item $temp $_.Name
}

Write-Host "Listo. Actualiza el HTML para usar .jpg en lugar de .png donde corresponda."

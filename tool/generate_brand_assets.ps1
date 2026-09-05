Add-Type -AssemblyName System.Drawing

$rawPath = "C:\Users\natan\.gemini\antigravity-ide\brain\fc52e779-8b0c-4590-808e-c6380b91d747\.user_uploaded\media_1788646207617.png"
$projectRoot = Split-Path -Parent $PSScriptRoot
$rawBitmap = [System.Drawing.Bitmap]::FromFile($rawPath)

# 1. Find tight bounding box
$minX = $rawBitmap.Width
$maxX = 0
$minY = $rawBitmap.Height
$maxY = 0

for ($y = 0; $y -lt $rawBitmap.Height; $y++) {
    for ($x = 0; $x -lt $rawBitmap.Width; $x++) {
        $p = $rawBitmap.GetPixel($x, $y)
        if ($p.A -gt 15) {
            if ($x -lt $minX) { $minX = $x }
            if ($x -gt $maxX) { $maxX = $x }
            if ($y -lt $minY) { $minY = $y }
            if ($y -gt $maxY) { $maxY = $y }
        }
    }
}

$cropW = $maxX - $minX + 1
$cropH = $maxY - $minY + 1
Write-Host "Tight Bounding Box: X=$minX, Y=$minY, W=$cropW, H=$cropH"

# 2. Create high-res centered transparent master (1024x1024)
# We want the logo to occupy ~82% of the height in the master transparent asset so in-app icons look bold and crisp.
$masterSize = 1024
$masterBmp = New-Object System.Drawing.Bitmap($masterSize, $masterSize, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$gMaster = [System.Drawing.Graphics]::FromImage($masterBmp)
$gMaster.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
$gMaster.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$gMaster.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
$gMaster.Clear([System.Drawing.Color]::Transparent)

$targetH = [int]($masterSize * 0.84)
$targetW = [int]($cropW * ($targetH / $cropH))
$destX = [int](($masterSize - $targetW) / 2)
$destY = [int](($masterSize - $targetH) / 2)

$srcRect = New-Object System.Drawing.Rectangle($minX, $minY, $cropW, $cropH)
$destRect = New-Object System.Drawing.Rectangle($destX, $destY, $targetW, $targetH)

$gMaster.DrawImage($rawBitmap, $destRect, $srcRect, [System.Drawing.GraphicsUnit]::Pixel)
$gMaster.Dispose()

# Save transparent in-app master asset
$assetLogoPath = Join-Path $projectRoot "assets\previewport-logo-transparent.png"
$masterBmp.Save($assetLogoPath, [System.Drawing.Imaging.ImageFormat]::Png)
Write-Host "Saved transparent in-app logo to: $assetLogoPath"

# 3. Helper function to generate icon on solid OLED dark background (#000000 / #030712)
function Generate-LauncherIcon {
    param(
        [int]$Size,
        [string]$OutputPath,
        [float]$ContentRatio = 0.72,
        [bool]$SolidDarkBg = $true
    )

    $iconBmp = New-Object System.Drawing.Bitmap($Size, $Size, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $g = [System.Drawing.Graphics]::FromImage($iconBmp)
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality

    if ($SolidDarkBg) {
        # Pure OLED Black / Deep Space Navy
        $g.Clear([System.Drawing.Color]::FromArgb(255, 0, 0, 0))
    } else {
        $g.Clear([System.Drawing.Color]::Transparent)
    }

    $iconTargetH = [int]($Size * $ContentRatio)
    $iconTargetW = [int]($cropW * ($iconTargetH / $cropH))
    $iDestX = [int](($Size - $iconTargetW) / 2)
    $iDestY = [int](($Size - $iconTargetH) / 2)

    $iDestRect = New-Object System.Drawing.Rectangle($iDestX, $iDestY, $iconTargetW, $iconTargetH)
    $g.DrawImage($rawBitmap, $iDestRect, $srcRect, [System.Drawing.GraphicsUnit]::Pixel)
    $g.Dispose()

    # Ensure parent dir exists
    $parent = Split-Path -Parent $OutputPath
    if (-not (Test-Path $parent)) {
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
    }

    if ($Size -eq 1024 -and $SolidDarkBg) {
        $rgbBmp = New-Object System.Drawing.Bitmap(1024, 1024, [System.Drawing.Imaging.PixelFormat]::Format24bppRgb)
        $rgbG = [System.Drawing.Graphics]::FromImage($rgbBmp)
        $rgbG.DrawImage($iconBmp, 0, 0, 1024, 1024)
        $rgbG.Dispose()
        $rgbBmp.Save($OutputPath, [System.Drawing.Imaging.ImageFormat]::Png)
        $rgbBmp.Dispose()
    } else {
        $iconBmp.Save($OutputPath, [System.Drawing.Imaging.ImageFormat]::Png)
    }
    $iconBmp.Dispose()
}

# 4. Generate all iOS AppIcon targets (Solid black, NO alpha channel for App Store compliance)
$iosIcons = @{
    'Icon-App-20x20@1x.png' = 20
    'Icon-App-20x20@2x.png' = 40
    'Icon-App-20x20@3x.png' = 60
    'Icon-App-29x29@1x.png' = 29
    'Icon-App-29x29@2x.png' = 58
    'Icon-App-29x29@3x.png' = 87
    'Icon-App-40x40@1x.png' = 40
    'Icon-App-40x40@2x.png' = 80
    'Icon-App-40x40@3x.png' = 120
    'Icon-App-60x60@2x.png' = 120
    'Icon-App-60x60@3x.png' = 180
    'Icon-App-76x76@1x.png' = 76
    'Icon-App-76x76@2x.png' = 152
    'Icon-App-83.5x83.5@2x.png' = 167
    'Icon-App-1024x1024@1x.png' = 1024
}

$iosAppIconDir = Join-Path $projectRoot "ios\Runner\Assets.xcassets\AppIcon.appiconset"
foreach ($entry in $iosIcons.GetEnumerator()) {
    $outPath = Join-Path $iosAppIconDir $entry.Key
    Generate-LauncherIcon -Size $entry.Value -OutputPath $outPath -ContentRatio 0.70 -SolidDarkBg $true
}
Write-Host "Generated $($iosIcons.Count) iOS AppIcon assets."

# 5. Generate iOS LaunchImage targets (Centered on pitch black)
$launchImgDir = Join-Path $projectRoot "ios\Runner\Assets.xcassets\LaunchImage.imageset"
Generate-LauncherIcon -Size 300 -OutputPath (Join-Path $launchImgDir "LaunchImage.png") -ContentRatio 0.50 -SolidDarkBg $true
Generate-LauncherIcon -Size 600 -OutputPath (Join-Path $launchImgDir "LaunchImage@2x.png") -ContentRatio 0.50 -SolidDarkBg $true
Generate-LauncherIcon -Size 900 -OutputPath (Join-Path $launchImgDir "LaunchImage@3x.png") -ContentRatio 0.50 -SolidDarkBg $true
Write-Host "Generated iOS LaunchImage assets."

# 6. Generate Android Launcher Icons
$androidMipmaps = @{
    'mipmap-mdpi\ic_launcher.png' = 48
    'mipmap-hdpi\ic_launcher.png' = 72
    'mipmap-xhdpi\ic_launcher.png' = 96
    'mipmap-xxhdpi\ic_launcher.png' = 144
    'mipmap-xxxhdpi\ic_launcher.png' = 192
}

$resDir = Join-Path $projectRoot "android\app\src\main\res"
foreach ($entry in $androidMipmaps.GetEnumerator()) {
    $outPath = Join-Path $resDir $entry.Key
    Generate-LauncherIcon -Size $entry.Value -OutputPath $outPath -ContentRatio 0.68 -SolidDarkBg $true
}
Write-Host "Generated Android launcher icons."

# 7. Generate Web icons & favicon
$webIcons = @{
    'web\favicon.png' = 64
    'web\icons\Icon-192.png' = 192
    'web\icons\Icon-512.png' = 512
    'web\icons\Icon-maskable-192.png' = 192
    'web\icons\Icon-maskable-512.png' = 512
}

foreach ($entry in $webIcons.GetEnumerator()) {
    $outPath = Join-Path $projectRoot $entry.Key
    Generate-LauncherIcon -Size $entry.Value -OutputPath $outPath -ContentRatio 0.70 -SolidDarkBg $true
}
Write-Host "Generated Web launcher icons."

# Also copy transparent version to artifacts for quick inspection
$artifactInspectPath = "C:\Users\natan\.gemini\antigravity-ide\brain\fc52e779-8b0c-4590-808e-c6380b91d747\new_logo_centered.png"
$masterBmp.Save($artifactInspectPath, [System.Drawing.Imaging.ImageFormat]::Png)

$rawBitmap.Dispose()
$masterBmp.Dispose()
Write-Host "All assets replaced successfully with the new logo!" -ForegroundColor Green

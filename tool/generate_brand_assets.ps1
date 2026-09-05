$ErrorActionPreference = 'Stop'

Add-Type -AssemblyName System.Drawing

$projectRoot = Split-Path -Parent $PSScriptRoot
$sourcePath = Join-Path $projectRoot 'assets\previewport-logo-transparent.png'
$sourceBitmap = New-Object System.Drawing.Bitmap($sourcePath)

function New-BrandIcon {
    param(
        [Parameter(Mandatory = $true)][int]$Size,
        [Parameter(Mandatory = $true)][string]$OutputPath
    )

    $bitmap = New-Object System.Drawing.Bitmap(
        $Size,
        $Size,
        [System.Drawing.Imaging.PixelFormat]::Format32bppArgb
    )
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
    $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
    $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $graphics.Clear([System.Drawing.Color]::FromArgb(255, 4, 8, 20))

    $logoSize = [Math]::Max(1, [int]($Size * 0.78))
    $offset = [int](($Size - $logoSize) / 2)
    $destination = New-Object System.Drawing.Rectangle($offset, $offset, $logoSize, $logoSize)
    $graphics.DrawImage(
        $sourceBitmap,
        $destination,
        0,
        0,
        $sourceBitmap.Width,
        $sourceBitmap.Height,
        [System.Drawing.GraphicsUnit]::Pixel
    )

    $graphics.Dispose()
    $bitmap.Save($OutputPath, [System.Drawing.Imaging.ImageFormat]::Png)
    $bitmap.Dispose()
}

$targets = @{
    'web\favicon.png' = 64
    'web\icons\Icon-192.png' = 192
    'web\icons\Icon-512.png' = 512
    'web\icons\Icon-maskable-192.png' = 192
    'web\icons\Icon-maskable-512.png' = 512
    'android\app\src\main\res\mipmap-mdpi\ic_launcher.png' = 48
    'android\app\src\main\res\mipmap-hdpi\ic_launcher.png' = 72
    'android\app\src\main\res\mipmap-xhdpi\ic_launcher.png' = 96
    'android\app\src\main\res\mipmap-xxhdpi\ic_launcher.png' = 144
    'android\app\src\main\res\mipmap-xxxhdpi\ic_launcher.png' = 192
    'ios\Runner\Assets.xcassets\AppIcon.appiconset\Icon-App-20x20@1x.png' = 20
    'ios\Runner\Assets.xcassets\AppIcon.appiconset\Icon-App-20x20@2x.png' = 40
    'ios\Runner\Assets.xcassets\AppIcon.appiconset\Icon-App-20x20@3x.png' = 60
    'ios\Runner\Assets.xcassets\AppIcon.appiconset\Icon-App-29x29@1x.png' = 29
    'ios\Runner\Assets.xcassets\AppIcon.appiconset\Icon-App-29x29@2x.png' = 58
    'ios\Runner\Assets.xcassets\AppIcon.appiconset\Icon-App-29x29@3x.png' = 87
    'ios\Runner\Assets.xcassets\AppIcon.appiconset\Icon-App-40x40@1x.png' = 40
    'ios\Runner\Assets.xcassets\AppIcon.appiconset\Icon-App-40x40@2x.png' = 80
    'ios\Runner\Assets.xcassets\AppIcon.appiconset\Icon-App-40x40@3x.png' = 120
    'ios\Runner\Assets.xcassets\AppIcon.appiconset\Icon-App-60x60@2x.png' = 120
    'ios\Runner\Assets.xcassets\AppIcon.appiconset\Icon-App-60x60@3x.png' = 180
    'ios\Runner\Assets.xcassets\AppIcon.appiconset\Icon-App-76x76@1x.png' = 76
    'ios\Runner\Assets.xcassets\AppIcon.appiconset\Icon-App-76x76@2x.png' = 152
    'ios\Runner\Assets.xcassets\AppIcon.appiconset\Icon-App-83.5x83.5@2x.png' = 167
    'ios\Runner\Assets.xcassets\AppIcon.appiconset\Icon-App-1024x1024@1x.png' = 1024
}

foreach ($target in $targets.GetEnumerator()) {
    $outputPath = Join-Path $projectRoot $target.Key
    New-BrandIcon -Size $target.Value -OutputPath $outputPath
}

$sourceBitmap.Dispose()
Write-Host "Generated $($targets.Count) PreviewPort launcher assets." -ForegroundColor Cyan

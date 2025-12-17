# PowerShell script to extract PNG icons from ICO file for macOS
# Note: This requires ImageMagick or manual conversion

Write-Host "macOS Icon Extraction Script" -ForegroundColor Green
Write-Host "=============================" -ForegroundColor Green
Write-Host ""
Write-Host "This script helps extract PNG files from the ICO file for macOS." -ForegroundColor Yellow
Write-Host ""
Write-Host "Requirements:" -ForegroundColor Cyan
Write-Host "  - ImageMagick installed (https://imagemagick.org/)"
Write-Host "  OR"
Write-Host "  - Use an online converter like https://cloudconvert.com/ico-to-png"
Write-Host ""

$icoPath = "windows\runner\resources\jungholm-logo.ico"
$outputDir = "macos\Runner\Assets.xcassets\AppIcon.appiconset\"

if (Test-Path $icoPath) {
    Write-Host "Found ICO file: $icoPath" -ForegroundColor Green
    
    # Check if ImageMagick is available
    $magickPath = Get-Command magick -ErrorAction SilentlyContinue
    $convertPath = Get-Command convert -ErrorAction SilentlyContinue
    
    if ($magickPath -or $convertPath) {
        Write-Host "ImageMagick found! Extracting PNG files..." -ForegroundColor Green
        
        $sizes = @(
            @{Size=16; File="app_icon_16.png"},
            @{Size=32; File="app_icon_32.png"},
            @{Size=64; File="app_icon_64.png"},
            @{Size=128; File="app_icon_128.png"},
            @{Size=256; File="app_icon_256.png"},
            @{Size=512; File="app_icon_512.png"},
            @{Size=1024; File="app_icon_1024.png"}
        )
        
        $cmd = if ($magickPath) { "magick" } else { "convert" }
        
        foreach ($item in $sizes) {
            $outputFile = Join-Path $outputDir $item.File
            Write-Host "Creating $($item.File) ($($item.Size)x$($item.Size))..." -ForegroundColor Cyan
            & $cmd convert $icoPath -resize "$($item.Size)x$($item.Size)" $outputFile
        }
        
        Write-Host ""
        Write-Host "Done! All PNG files have been created." -ForegroundColor Green
    } else {
        Write-Host "ImageMagick not found. Please use one of these options:" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Option 1: Install ImageMagick from https://imagemagick.org/" -ForegroundColor Cyan
        Write-Host "Option 2: Use online converter:" -ForegroundColor Cyan
        Write-Host "  1. Go to https://cloudconvert.com/ico-to-png" -ForegroundColor White
        Write-Host "  2. Upload: $icoPath" -ForegroundColor White
        Write-Host "  3. Extract/convert to PNG" -ForegroundColor White
        Write-Host "  4. Resize to required sizes and save to: $outputDir" -ForegroundColor White
        Write-Host ""
        Write-Host "Required PNG sizes:" -ForegroundColor Cyan
        Write-Host "  - 16x16 (app_icon_16.png)" -ForegroundColor White
        Write-Host "  - 32x32 (app_icon_32.png)" -ForegroundColor White
        Write-Host "  - 64x64 (app_icon_64.png)" -ForegroundColor White
        Write-Host "  - 128x128 (app_icon_128.png)" -ForegroundColor White
        Write-Host "  - 256x256 (app_icon_256.png)" -ForegroundColor White
        Write-Host "  - 512x512 (app_icon_512.png)" -ForegroundColor White
        Write-Host "  - 1024x1024 (app_icon_1024.png)" -ForegroundColor White
    }
} else {
    Write-Host "Error: ICO file not found at $icoPath" -ForegroundColor Red
}




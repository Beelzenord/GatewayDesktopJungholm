# App Icon Setup

## Windows ✅
The Windows icon has been configured to use `jungholm-logo.ico`.

## macOS
macOS requires PNG files in multiple sizes. To set up the macOS icon:

### Option 1: Using Online Converter
1. Go to https://cloudconvert.com/ico-to-png or similar converter
2. Upload `windows/runner/resources/jungholm-logo.ico`
3. Extract/convert to PNG format
4. Resize to the following sizes:
   - 16x16 (app_icon_16.png)
   - 32x32 (app_icon_32.png)
   - 64x64 (app_icon_64.png)
   - 128x128 (app_icon_128.png)
   - 256x256 (app_icon_256.png)
   - 512x512 (app_icon_512.png)
   - 1024x1024 (app_icon_1024.png)
5. Replace the files in `macos/Runner/Assets.xcassets/AppIcon.appiconset/`

### Option 2: Using ImageMagick (if installed)
```bash
# Extract PNG from ICO
magick convert windows/runner/resources/jungholm-logo.ico -resize 16x16 macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_16.png
magick convert windows/runner/resources/jungholm-logo.ico -resize 32x32 macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_32.png
magick convert windows/runner/resources/jungholm-logo.ico -resize 64x64 macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_64.png
magick convert windows/runner/resources/jungholm-logo.ico -resize 128x128 macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_128.png
magick convert windows/runner/resources/jungholm-logo.ico -resize 256x256 macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_256.png
magick convert windows/runner/resources/jungholm-logo.ico -resize 512x512 macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_512.png
magick convert windows/runner/resources/jungholm-logo.ico -resize 1024x1024 macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_1024.png
```

### Option 3: Using macOS Preview (if on Mac)
1. Open the ICO file in Preview
2. Export as PNG
3. Use Preview's resize feature to create all required sizes
4. Replace files in `macos/Runner/Assets.xcassets/AppIcon.appiconset/`


Add-Type -AssemblyName System.Drawing
$draft = $PSScriptRoot

function Save-SmallSprite {
    param([string]$InputName, [string]$OutputName, [System.Drawing.Rectangle]$Crop)
    $source = [System.Drawing.Bitmap]::new((Join-Path $draft $InputName))
    $sprite = [System.Drawing.Bitmap]::new(80, 200, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $graphics = [System.Drawing.Graphics]::FromImage($sprite)
    $graphics.Clear([System.Drawing.Color]::Transparent)
    $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
    $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::Half
    $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::None
    $graphics.DrawImage($source, [System.Drawing.Rectangle]::new(2, 5, 76, 190), $Crop, [System.Drawing.GraphicsUnit]::Pixel)
    $graphics.Dispose()
    $source.Dispose()
    for ($y = 0; $y -lt 200; $y++) {
        for ($x = 0; $x -lt 80; $x++) {
            $pixel = $sprite.GetPixel($x, $y)
            if ($pixel.A -lt 128) { $sprite.SetPixel($x, $y, [System.Drawing.Color]::Transparent) }
            else { $sprite.SetPixel($x, $y, [System.Drawing.Color]::FromArgb(255, $pixel.R, $pixel.G, $pixel.B)) }
        }
    }
    $sprite.Save((Join-Path $draft $OutputName), [System.Drawing.Imaging.ImageFormat]::Png)
    $sprite.Dispose()
}

Save-SmallSprite 'archie-reference-lowres-source.png' 'archie-reference-80x200-v3.png' ([System.Drawing.Rectangle]::new(218, 65, 557, 1474))
Save-SmallSprite 'james-reference-lowres-source.png' 'james-reference-80x200.png' ([System.Drawing.Rectangle]::new(174, 97, 592, 1586))

$plate = [System.Drawing.Bitmap]::new((Join-Path $draft 'plate-p1-v1.png'))
$archie = [System.Drawing.Bitmap]::new((Join-Path $draft 'archie-reference-80x200-v3.png'))
$james = [System.Drawing.Bitmap]::new((Join-Path $draft 'james-reference-80x200.png'))
$preview = [System.Drawing.Bitmap]::new(390, 544, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$graphics = [System.Drawing.Graphics]::FromImage($preview)
$graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
$graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::Half
$graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::None
$cropHeight = [int][Math]::Round($plate.Width * 544.0 / 390.0)
$graphics.DrawImage($plate, [System.Drawing.Rectangle]::new(0, 0, 390, 544), [System.Drawing.Rectangle]::new(0, [int](($plate.Height - $cropHeight) / 2), $plate.Width, $cropHeight), [System.Drawing.GraphicsUnit]::Pixel)
$graphics.DrawImage($archie, 0, 135, 144, 360)
$graphics.DrawImage($james, 85, 105, 160, 400)
$graphics.Dispose()
$preview.Save((Join-Path $draft 'scale-study-large-hip-390x544.png'), [System.Drawing.Imaging.ImageFormat]::Png)
$preview.Dispose()
$plate.Dispose()
$archie.Dispose()
$james.Dispose()
Write-Output 'Saved 80x200 sprites and 390x544 scale study.'

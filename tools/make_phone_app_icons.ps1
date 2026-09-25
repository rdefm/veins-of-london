param(
    [string]$ProjectRoot = (Split-Path -Parent $PSScriptRoot)
)

Add-Type -AssemblyName System.Drawing

$outputDirectory = Join-Path $ProjectRoot 'assets/phone/icons'
$sourceDirectory = Join-Path $ProjectRoot 'assets/phone/source'
$renderSize = 512
$finalSize = 128

function New-RoundedPath([float]$x, [float]$y, [float]$width, [float]$height, [float]$radius) {
    $path = [System.Drawing.Drawing2D.GraphicsPath]::new()
    $diameter = $radius * 2
    $path.AddArc($x, $y, $diameter, $diameter, 180, 90)
    $path.AddArc($x + $width - $diameter, $y, $diameter, $diameter, 270, 90)
    $path.AddArc($x + $width - $diameter, $y + $height - $diameter, $diameter, $diameter, 0, 90)
    $path.AddArc($x, $y + $height - $diameter, $diameter, $diameter, 90, 90)
    $path.CloseFigure()
    return $path
}

function New-Pen([string]$colour, [float]$width) {
    $pen = [System.Drawing.Pen]::new([System.Drawing.ColorTranslator]::FromHtml($colour), $width)
    $pen.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
    $pen.EndCap = [System.Drawing.Drawing2D.LineCap]::Round
    $pen.LineJoin = [System.Drawing.Drawing2D.LineJoin]::Round
    return $pen
}

function Save-Icon([System.Drawing.Bitmap]$bitmap, [string]$id) {
    $small = [System.Drawing.Bitmap]::new($finalSize, $finalSize, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $graphics = [System.Drawing.Graphics]::FromImage($small)
    $graphics.CompositingMode = [System.Drawing.Drawing2D.CompositingMode]::SourceCopy
    $graphics.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
    $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
    $graphics.DrawImage($bitmap, 0, 0, $finalSize, $finalSize)
    $graphics.Dispose()
    $small.Save((Join-Path $outputDirectory "$id.png"), [System.Drawing.Imaging.ImageFormat]::Png)
    $small.Dispose()
}

function Convert-SourceIcon([string]$sourceName, [string]$id, [bool]$cropSquare = $false) {
    $source = [System.Drawing.Image]::FromFile((Join-Path $sourceDirectory $sourceName))
    $bitmap = [System.Drawing.Bitmap]::new($renderSize, $renderSize, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
    $graphics.Clear([System.Drawing.Color]::Transparent)
    $graphics.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
    $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
    if ($cropSquare) {
        $side = [Math]::Min($source.Width, $source.Height)
        $sourceRect = [System.Drawing.Rectangle]::new([int](($source.Width - $side) / 2), [int](($source.Height - $side) / 2), $side, $side)
        $graphics.DrawImage($source, [System.Drawing.Rectangle]::new(0, 0, $renderSize, $renderSize), $sourceRect, [System.Drawing.GraphicsUnit]::Pixel)
    } else {
        $graphics.DrawImage($source, 0, 0, $renderSize, $renderSize)
    }
    $graphics.Dispose()
    $source.Dispose()
    Save-Icon $bitmap $id
    $bitmap.Dispose()
}

function New-GeneratedIcon([string]$id, [string]$top, [string]$bottom) {
    $bitmap = [System.Drawing.Bitmap]::new($renderSize, $renderSize, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
    $graphics.Clear([System.Drawing.Color]::Transparent)
    $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $graphics.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
    $path = New-RoundedPath 4 4 504 504 112
    $gradient = [System.Drawing.Drawing2D.LinearGradientBrush]::new(
        [System.Drawing.Rectangle]::new(0, 0, $renderSize, $renderSize),
        [System.Drawing.ColorTranslator]::FromHtml($top),
        [System.Drawing.ColorTranslator]::FromHtml($bottom),
        90
    )
    $graphics.FillPath($gradient, $path)
    $gradient.Dispose()
    $path.Dispose()

    $light = '#f5f6f7'
    $dark = '#202936'
    switch ($id) {
        'alarms' {
            $pen = New-Pen $dark 28
            $graphics.DrawEllipse($pen, 126, 126, 260, 260)
            $graphics.DrawLine($pen, 256, 256, 256, 178)
            $graphics.DrawLine($pen, 256, 256, 316, 304)
            $graphics.DrawArc($pen, 100, 74, 140, 110, 202, 126)
            $graphics.DrawArc($pen, 272, 74, 140, 110, 212, 126)
            $graphics.DrawLine($pen, 174, 386, 142, 424)
            $graphics.DrawLine($pen, 338, 386, 370, 424)
            $pen.Dispose()
        }
        'ticker' {
            $brush = [System.Drawing.SolidBrush]::new([System.Drawing.ColorTranslator]::FromHtml($light))
            $graphics.FillRectangle($brush, 118, 306, 42, 94)
            $graphics.FillRectangle($brush, 190, 258, 42, 142)
            $graphics.FillRectangle($brush, 262, 210, 42, 190)
            $graphics.FillRectangle($brush, 334, 154, 42, 246)
            $brush.Dispose()
            $pen = New-Pen $light 26
            $graphics.DrawLines($pen, [System.Drawing.Point[]]@(
                [System.Drawing.Point]::new(118, 272),
                [System.Drawing.Point]::new(210, 222),
                [System.Drawing.Point]::new(284, 242),
                [System.Drawing.Point]::new(390, 126)
            ))
            $graphics.DrawLine($pen, 390, 126, 384, 198)
            $graphics.DrawLine($pen, 390, 126, 318, 132)
            $pen.Dispose()
        }
        'factions' {
            $brush = [System.Drawing.SolidBrush]::new([System.Drawing.ColorTranslator]::FromHtml($light))
            $graphics.FillEllipse($brush, 198, 126, 116, 116)
            $graphics.FillEllipse($brush, 88, 172, 88, 88)
            $graphics.FillEllipse($brush, 336, 172, 88, 88)
            $graphics.FillPie($brush, 154, 228, 204, 214, 180, 180)
            $graphics.FillPie($brush, 44, 258, 176, 168, 180, 180)
            $graphics.FillPie($brush, 292, 258, 176, 168, 180, 180)
            $brush.Dispose()
        }
        'profile' {
            $brush = [System.Drawing.SolidBrush]::new([System.Drawing.ColorTranslator]::FromHtml($light))
            $graphics.FillEllipse($brush, 190, 126, 132, 132)
            $graphics.FillPie($brush, 126, 244, 260, 220, 180, 180)
            $brush.Dispose()
            $pen = New-Pen '#aeb7c4' 18
            $graphics.DrawRectangle($pen, 88, 82, 336, 348)
            $pen.Dispose()
        }
        'vfl' {
            $brush = [System.Drawing.SolidBrush]::new([System.Drawing.ColorTranslator]::FromHtml($dark))
            $graphics.FillRectangle($brush, 130, 128, 252, 224)
            $graphics.FillEllipse($brush, 130, 300, 252, 128)
            $lightBrush = [System.Drawing.SolidBrush]::new([System.Drawing.ColorTranslator]::FromHtml($light))
            $graphics.FillRectangle($lightBrush, 164, 164, 184, 92)
            $graphics.FillEllipse($lightBrush, 176, 304, 42, 42)
            $graphics.FillEllipse($lightBrush, 294, 304, 42, 42)
            $brush.Dispose()
            $lightBrush.Dispose()
            $pen = New-Pen $dark 24
            $graphics.DrawLine($pen, 202, 416, 164, 458)
            $graphics.DrawLine($pen, 310, 416, 348, 458)
            $graphics.DrawLine($pen, 170, 444, 342, 444)
            $pen.Dispose()
        }
        'notifications' {
            $brush = [System.Drawing.SolidBrush]::new([System.Drawing.ColorTranslator]::FromHtml($light))
            $graphics.FillPie($brush, 130, 118, 252, 304, 180, 180)
            $graphics.FillRectangle($brush, 130, 266, 252, 84)
            $graphics.FillEllipse($brush, 226, 382, 60, 60)
            $graphics.FillEllipse($brush, 232, 78, 48, 70)
            $brush.Dispose()
        }
        'debug' {
            $pen = New-Pen $light 30
            $graphics.DrawRectangle($pen, 126, 120, 260, 272)
            $graphics.DrawLine($pen, 190, 204, 150, 244)
            $graphics.DrawLine($pen, 150, 244, 190, 284)
            $graphics.DrawLine($pen, 322, 204, 362, 244)
            $graphics.DrawLine($pen, 362, 244, 322, 284)
            $graphics.DrawLine($pen, 222, 326, 290, 326)
            $pen.Dispose()
        }
    }

    $graphics.Dispose()
    Save-Icon $bitmap $id
    $bitmap.Dispose()
}

New-Item -ItemType Directory -Force -Path $outputDirectory | Out-Null

# Supplied artwork remains the source for the six matching launcher apps.
Convert-SourceIcon 'logo-todo.png' 'todo'
Convert-SourceIcon 'logo-bizbrief.png' 'bizbrief'
Convert-SourceIcon 'logo-reynards.png' 'bank'
Convert-SourceIcon 'logo-harrows.png' 'property'
Convert-SourceIcon 'logo-contacts.png' 'contacts'
Convert-SourceIcon 'logo-save.jpg' 'saveload' $true

New-GeneratedIcon 'alarms' '#f4f6f8' '#c9d1db'
New-GeneratedIcon 'ticker' '#168b57' '#075238'
New-GeneratedIcon 'factions' '#66549b' '#332854'
New-GeneratedIcon 'profile' '#3f4d62' '#202837'
New-GeneratedIcon 'vfl' '#f4f6f8' '#cbd3dc'
New-GeneratedIcon 'notifications' '#4b596d' '#273143'
New-GeneratedIcon 'debug' '#b84d3f' '#66261f'

Write-Host 'Generated 13 phone launcher icons at 128x128.'

# Converts a PNG of any size to a Windows .ico file holding one 256x256 PNG image (supported since Windows Vista).
# Used by bottlenoselabs.Sdk.GameApp on Windows build machines, which have System.Drawing.
param(
    [Parameter(Mandatory = $true)][string] $Source,
    [Parameter(Mandatory = $true)][string] $Destination
)
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

$size = 256
$image = [System.Drawing.Image]::FromFile($Source)
try {
    $bitmap = New-Object System.Drawing.Bitmap($size, $size)
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
    $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
    $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $graphics.DrawImage($image, 0, 0, $size, $size)
    $graphics.Dispose()

    $png = New-Object System.IO.MemoryStream
    $bitmap.Save($png, [System.Drawing.Imaging.ImageFormat]::Png)
    $bitmap.Dispose()
    $pngBytes = $png.ToArray()
}
finally {
    $image.Dispose()
}

$directory = [System.IO.Path]::GetDirectoryName($Destination)
if ($directory) { [System.IO.Directory]::CreateDirectory($directory) | Out-Null }
$stream = [System.IO.File]::Create($Destination)
$writer = New-Object System.IO.BinaryWriter($stream)
try {
    # ICONDIR: reserved, type 1 (icon), 1 image
    $writer.Write([UInt16]0); $writer.Write([UInt16]1); $writer.Write([UInt16]1)
    # ICONDIRENTRY: width and height 0 mean 256, no palette, reserved, 1 plane, 32 bits per pixel, size, offset (6 + 16)
    $writer.Write([Byte]0); $writer.Write([Byte]0); $writer.Write([Byte]0); $writer.Write([Byte]0)
    $writer.Write([UInt16]1); $writer.Write([UInt16]32)
    $writer.Write([UInt32]$pngBytes.Length); $writer.Write([UInt32]22)
    $writer.Write($pngBytes)
}
finally {
    $writer.Dispose()
}

#--------------------------------------------------------------------------------------------------------
# Get the vtex and game directory... then cd there.
#--------------------------------------------------------------------------------------------------------
[string]$gameDir = Read-Host "enter path to gameinfo.txt directory. This should be similar to C:\Program Files (x86)\Steam\steamapps\common\Half-Life 2\hl2"
cd $gameDir
cd ..\bin
$vtexDir = Get-Location
$pfmFolder = Read-Host "Enter PFM Folder Directory. MUST BE placed in <anyfolder>\materialsrc\skybox sub folder."
cd $pfmFolder

#--------------------------------------------------------------------------------------------------------
# Make text files for all pfm files in folder directory.
#--------------------------------------------------------------------------------------------------------
Get-ChildItem $pfmFolder -Filter "*.pfm" | Foreach-Object {
    $fileName = [System.IO.Path]::GetFileNameWithoutExtension($_.Name)
    New-Item -Force -Path . -Name "$fileName.txt" -value @"
    pfm 1 // Flag as HDR texture
    pfmscale 1 // brightness multiplier
    nonice 1 // prevent seams appearing at low texture detail
    clamps 1
    clampt 1
"@
}

#--------------------------------------------------------------------------------------------------------
# Make the vtf and vmt files
# MUST USE $hdrcompressedtexture for the created skybox in the VMT.
# TODO: Add a toggle for basetexturetransform
#--------------------------------------------------------------------------------------------------------

Get-ChildItem $pfmFolder -Filter "*.pfm" | Foreach-Object {
    $pfmfile = $_.Name
    $skyNameNoExt = [System.IO.Path]::GetFileNameWithoutExtension($_.Name)
    $ldrskyname = $skyNameNoExt.replace('_hdr','')
    $pfmfile

    if($ldrskyname.contains('dn') -or $ldrskyname.contains('up')){
    & $vtexDir/vtex.exe -game $gameDir -nopause -shader UnlitGeneric -vmtparam "`$baseTexture" "skybox/$ldrskyname" -vmtparam  "`$ignorez" "1" -vmtparam  "`$hdrcompressedtexture" "skybox/$skyNameNoExt" $pfmfile
    }
    else{
    #& $vtexDir/vtex.exe -game $gameDir -nopause -shader UnlitGeneric -vmtparam "`$baseTexture" "skybox/$ldrskyname" -vmtparam "`$basetexturetransform" "center 0 0 scale 1 2 rotate 0 translate 0 0" -vmtparam  "`$ignorez" "1" -vmtparam  "`$hdrcompressedtexture" "skybox/$skyNameNoExt" $pfmfile
    & $vtexDir/vtex.exe -game $gameDir -nopause -shader UnlitGeneric -vmtparam "`$baseTexture" "skybox/$ldrskyname" -vmtparam  "`$ignorez" "1" -vmtparam  "`$hdrcompressedtexture" "skybox/$skyNameNoExt" $pfmfile
    }
}

cd $gamedir/materials/skybox/
$sourceTextures = Get-Location

#--------------------------------------------------------------------------------------------------------
# Edit the vmt to remove duplicate basetexture in line 3.
#--------------------------------------------------------------------------------------------------------
Get-ChildItem $sourceTextures -Filter "*.vmt" | Foreach-Object {
    $vmtfile = $_.Name
    $skyNameNoExt = [System.IO.Path]::GetFileNameWithoutExtension($_.Name)
(Get-Content "$skyNameNoExt.vmt") | Where-Object ReadCount -ne 3 | Set-Content "$skyNameNoExt.vmt" -force
}


#--------------------------------------------------------------------------------------------------------
# Create LDR fallbacks.
#--------------------------------------------------------------------------------------------------------
cd $pfmFolder

Get-ChildItem $pfmFolder -Filter "*.tga" | Foreach-Object {
    $tgafile = $_.Name
    $skyNameNoExt = [System.IO.Path]::GetFileNameWithoutExtension($_.Name)
    New-Item -Force -Path . -Name "$skyNameNoExt.txt" -value @"
    nonice 1 // prevent seams appearing at low texture detail
    clamps 1
    clampt 1
"@
& $vtexDir/vtex.exe -game $gameDir -nopause $tgafile
}

#--------------------------------------------------------------------------------------------------------
# Exit
#--------------------------------------------------------------------------------------------------------
Write-Host @"

"@
Write-Host "Closing in 10 seconds." -BackgroundColor Magenta
ii $gameDir/materials/skybox
Start-Sleep -Seconds 10
Exit
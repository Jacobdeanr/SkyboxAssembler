#--------------------------------------------------------------------------------------------------------
# Get the vtex and game directory... then cd there.
#--------------------------------------------------------------------------------------------------------
[string]$gameDir = Read-Host "enter path to gameinfo.txt directory. This should be similar to C:\Program Files (x86)\Steam\steamapps\common\Half-Life 2\hl2"
cd $gameDir
cd ..\bin
$vtexDir = Get-Location
$pfmFolder = Read-Host "Enter PFM Folder Directory. MUST BE placed in <anyfolder>\materialsrc\skybox sub folder"


#--------------------------------------------------------------------------------------------------------
# Make text files for all pfm files in folder directory.
#--------------------------------------------------------------------------------------------------------
cd $pfmFolder

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
# TODO: Add a toggle for basetexturetransform for half sized files.
#--------------------------------------------------------------------------------------------------------
cd $pfmFolder

Get-ChildItem $pfmFolder -Filter "*.pfm" | Foreach-Object {
    $pfmfile = $_.Name
    $skyNameNoExt = [System.IO.Path]::GetFileNameWithoutExtension($_.Name)
    $ldrskyname = $skyNameNoExt.replace('_hdr','')

    if($ldrskyname.contains('dn') -or $ldrskyname.contains('up')){
    & $vtexDir/vtex.exe -game $gameDir -nopause -shader UnlitGeneric -vmtparam "`$baseTexture" "skybox/$ldrskyname" -vmtparam "`$nofog" "1" -vmtparam  "`$ignorez" "1" -vmtparam  "`$hdrcompressedtexture" "skybox/$skyNameNoExt" $pfmfile
    }
    else{
    # Switch these aroudn for 2:1 skyboxes. i.e. 1024x512
    & $vtexDir/vtex.exe -game $gameDir -nopause -shader UnlitGeneric -vmtparam "`$BaseTexture" "skybox/$ldrskyname" -vmtparam "`$nofog" "1" -vmtparam  "`$ignorez" "1" -vmtparam  "`$hdrcompressedtexture" "skybox/$skyNameNoExt" $pfmfile #Square Sides
    # & $vtexDir/vtex.exe -game $gameDir -nopause -shader UnlitGeneric -vmtparam "`$BaseTexture" "skybox/$ldrskyname" -vmtparam "`$basetexturetransform" "center 0 0 scale 1 2 rotate 0 translate 0 0" -vmtparam "`$nofog" "1" -vmtparam  "`$ignorez" "1" -vmtparam  "`$hdrcompressedtexture" "skybox/$skyNameNoExt" $pfmfile #2:1 Sides.
    }
}

#--------------------------------------------------------------------------------------------------------
# Edit the vmt to remove duplicate basetexture in line 3.
#--------------------------------------------------------------------------------------------------------
#cd $gamedir/materials/skybox/
#$sourceTextures = Get-Location
#
#Get-ChildItem $sourceTextures -Filter "*.vmt" | Foreach-Object {
#    $vmtfile = $_.Name
#    $skyNameNoExt = [System.IO.Path]::GetFileNameWithoutExtension($_.Name)
#    (Get-Content "$skyNameNoExt.vmt") | Where-Object ReadCount -ne 3 | Set-Content "$skyNameNoExt.vmt" -force
#}
#Disabled right now until I can think of a safer way to modify the VMT Files.


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
& $vtexDir/vtex.exe -game $gameDir -nopause -shader UnlitGeneric -vmtparam "`$ignorez" "1" -vmtparam "`$nofog" "1" $tgafile
}


#--------------------------------------------------------------------------------------------------------
# Exit
#--------------------------------------------------------------------------------------------------------
Write-Host @"

"@
Write-Host "Remember to modify your $BaseTexture parameter for HDR VMT Files!" -ForegroundColor Red
Read-Host -Prompt "Completed. Press Enter to close"
ii $gameDir/materials/skybox
Exit

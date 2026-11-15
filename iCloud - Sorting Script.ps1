# ==============================
# WINDOW TITLE
# ==============================

$Host.UI.RawUI.WindowTitle = "iPhone Auto Library Sorter"
[Console]::Title = "iPhone Auto Library Sorter"

#=========================
# MAIN CODE
#=========================

$base = Get-Location

$rawFolder = Join-Path $base "Raw Files"
$root = Join-Path $base "Organized"

New-Item $root -ItemType Directory -Force | Out-Null


# ==============================
# SAFE COPY FUNCTION
# ==============================

function Copy-Safe {
    param(
        [string]$Source,
        [string]$Destination
    )

    $fileName = Split-Path $Source -Leaf
    $target = Join-Path $Destination $fileName

    if (!(Test-Path $target)) {

        Copy-Item $Source $Destination

    }
    else {

        $base = [System.IO.Path]::GetFileNameWithoutExtension($fileName)
        $ext  = [System.IO.Path]::GetExtension($fileName)

        $i = 1

        do {
            $newName = "$base`_$i$ext"
            $target = Join-Path $Destination $newName
            $i++
        }
        while (Test-Path $target)

        Copy-Item $Source $target
    }
}



# ==============================
# FIND EXPORT CHUNKS
# ==============================

$archives = Get-ChildItem $rawFolder -Directory | Where-Object {
    $_.Name -like "iCloud Photos*"
}


# ==============================
# ORIGINAL INVENTORY
# ==============================

$originalFiles = $archives | ForEach-Object {
    Get-ChildItem $_.FullName -Recurse -File
}


Write-Host ""
Write-Host "===== ORIGINAL EXPORT FILES =====" -ForegroundColor Cyan


$originalFiles |
Group-Object Extension |
Sort-Object Count -Descending |
Select Count, Name |
Format-Table -AutoSize


[PSCustomObject]@{
    TOTAL = $originalFiles.Count
} |
Format-Table -AutoSize

# ==============================
# EMPTY CHECK
# ==============================

if (@($originalFiles).Count -eq 0) {

    Write-Host ""
    Write-Host "No files found." -ForegroundColor Yellow
    Write-Host "Please add iCloud media items first into the ""Raw Files"" folder." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Press any key to exit app..."

    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit
}


Write-Host ""
Write-Host "===== ORIGINAL EXPORT FILES =====" -ForegroundColor Cyan


$originalFiles |
Group-Object Extension |
Sort-Object Count -Descending |
Select Count, Name |
Format-Table -AutoSize


[PSCustomObject]@{
    TOTAL = $originalFiles.Count
} |
Format-Table -AutoSize


# ==============================
# OUTPUT FOLDERS
# ==============================

$liveFolder  = Join-Path $root "LivePhotos"
$photoFolder = Join-Path $root "Photos"
$videoFolder = Join-Path $root "Videos"
$otherFolder = Join-Path $root "Other"


New-Item $liveFolder -ItemType Directory -Force | Out-Null
New-Item $photoFolder -ItemType Directory -Force | Out-Null
New-Item $videoFolder -ItemType Directory -Force | Out-Null
New-Item $otherFolder -ItemType Directory -Force | Out-Null

# ==============================
# LIVE PHOTO OPTION
# ==============================

$includeLiveMov = Read-Host "Include Live Photo MOV files? (Y/N)"

$includeLiveMov = $includeLiveMov -match '^(y|yes)$'


# ==============================
# LIVE PHOTO DETECTION
# ==============================

$liveFiles = @()


Write-Host ""
Write-Host "===== DETECTING LIVE PHOTOS =====" -ForegroundColor Cyan


$totalMov = (
    $archives |
    ForEach-Object {
        Get-ChildItem $_.FullName -Recurse -File -Filter *.mov
    }
).Count


$currentMov = 0


foreach ($archive in $archives) {

    $files = Get-ChildItem $archive.FullName -Recurse -File


    foreach ($mov in ($files | Where-Object { $_.Extension -ieq ".mov" })) {


        $currentMov++

        $percent = [math]::Floor(($currentMov / $totalMov) * 100)

        $barLength = 30
        $filled = [math]::Floor($barLength * $percent / 100)

        $bar = ("█" * $filled) + ("░" * ($barLength - $filled))


        #Write-Host -NoNewline "`r$(' ' * 100)"
        #Write-Host -NoNewline "`rDetecting Live Photos [$bar] $percent%"
        $line = "Detecting Live Photos [$bar] $percent%"
        Write-Host -NoNewline "`r$($line.PadRight(100))"


        $image = $files | Where-Object {

            $_.DirectoryName -eq $mov.DirectoryName -and
            $_.BaseName -eq $mov.BaseName -and
            $_.Extension -match '(?i)\.(heic|jpg|jpeg)'
        }


if ($image) {

    foreach ($img in $image) {

        Copy-Safe $img.FullName $liveFolder
        $liveFiles += $img.FullName

    }


    if ($includeLiveMov) {

        Copy-Safe $mov.FullName $liveFolder

    }

    $liveFiles += $mov.FullName
}
    }
}


Write-Host ""
Write-Host "Live Photo detection complete."



# ==============================
# SORT REMAINING FILES
# ==============================


Write-Host ""
Write-Host "===== SORTING FILES =====" -ForegroundColor Cyan


$totalFiles = $originalFiles.Count
$processed = 0


foreach ($file in $originalFiles) {


    $processed++

    $percent = [math]::Floor(($processed / $totalFiles) * 100)

    $barLength = 30
    $filled = [math]::Floor($barLength * $percent / 100)

    $bar = ("█" * $filled) + ("░" * ($barLength - $filled))


#   Write-Host -NoNewline "`r$(' ' * 100)"
#   Write-Host -NoNewline "`rSorting [$bar] $percent%  $($file.Name)"
    $line = "Sorting [$bar] $percent%"
    Write-Host -NoNewline "`r$($line.PadRight(100))"
   

    if ($file.FullName -in $liveFiles) {
        continue
    }



    switch -Regex ($file.Extension.ToLower()) {


        '\.(heic|jpg|jpeg|png|gif)' {

            Copy-Safe $file.FullName $photoFolder
            break
        }


        '\.(mov|mp4|m4v)' {

            Copy-Safe $file.FullName $videoFolder
            break
        }


        default {

            Copy-Safe $file.FullName $otherFolder
            break
        }
    }
}


Write-Host ""
Write-Host "Sorting complete."



# ==============================
# FINAL REPORT
# ==============================


Write-Host ""
Write-Host "===== LIVEPHOTOS =====" -ForegroundColor Green

$liveGroups = Get-ChildItem $liveFolder -File |
Group-Object Extension |
Sort-Object Name

$liveGroups |
Select Count, Name |
Format-Table -AutoSize


$livePhotoTotal = (
    $liveGroups |
    Where-Object { $_.Name -notmatch '(?i)\.mov' } |
    Measure-Object Count -Sum
).Sum


$liveMovTotal = (
    $liveGroups |
    Where-Object { $_.Name -match '(?i)\.mov' } |
    Measure-Object Count -Sum
).Sum


[PSCustomObject]@{
    TOTAL_Photos = $livePhotoTotal
    TOTAL_MOV    = $liveMovTotal
} |
Format-Table -AutoSize




Write-Host "===== PHOTOS =====" -ForegroundColor Green

$photoGroups = Get-ChildItem $photoFolder -File |
Group-Object Extension |
Sort-Object Name

$photoGroups |
Select Count, Name |
Format-Table -AutoSize


$photoTotal = (
    $photoGroups |
    Measure-Object Count -Sum
).Sum


[PSCustomObject]@{
    TOTAL = $photoTotal
} |
Format-Table -AutoSize





Write-Host "===== VIDEOS =====" -ForegroundColor Green

$videoGroups = Get-ChildItem $videoFolder -File |
Group-Object Extension |
Sort-Object Name

$videoGroups |
Select Count, Name |
Format-Table -AutoSize


$videoTotal = (
    $videoGroups |
    Measure-Object Count -Sum
).Sum


[PSCustomObject]@{
    TOTAL = $videoTotal
} |
Format-Table -AutoSize





Write-Host "===== OTHER =====" -ForegroundColor Green

$otherGroups = Get-ChildItem $otherFolder -File |
Group-Object Extension |
Sort-Object Name


$otherGroups |
Select Count, Name |
Format-Table -AutoSize


$otherTotal = (
    $otherGroups |
    Measure-Object Count -Sum
).Sum


[PSCustomObject]@{
    TOTAL = $otherTotal
} |
Format-Table -AutoSize





# ==============================
# LIBRARY ITEM COUNT
# ==============================


$libraryItems =
    $livePhotoTotal +
    $photoTotal +
    $videoTotal +
    $otherTotal


Write-Host "===== IPHONE LIBRARY CHECK =====" -ForegroundColor Yellow


[PSCustomObject]@{
    LivePhotos = $livePhotoTotal
    Photos     = $photoTotal
    Videos     = $videoTotal
    Other      = $otherTotal
    TOTAL      = $libraryItems
} |
Format-Table -AutoSize





# ==============================
# TOTAL CHECK
# ==============================


Write-Host "===== TOTAL FILE CHECK =====" -ForegroundColor Yellow


$sortedCount = (
    Get-ChildItem $liveFolder,$photoFolder,$videoFolder,$otherFolder -Recurse -File
).Count


$ignoredFiles = 0

if (!$includeLiveMov) {
    $ignoredFiles = (
        $liveFiles |
        Where-Object { $_ -match '(?i)\.mov$' }
    ).Count
}


[PSCustomObject]@{
    Original_Files = $originalFiles.Count
    Sorted_Files   = $sortedCount
    Ignored_MOV    = $ignoredFiles
    Missing        = $originalFiles.Count - $sortedCount - $ignoredFiles
} |
Format-Table -AutoSize
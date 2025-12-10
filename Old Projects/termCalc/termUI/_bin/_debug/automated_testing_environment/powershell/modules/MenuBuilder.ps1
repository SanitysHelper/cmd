function Build-MenuTree {
    param([string]$RootPath)
    if (-not (Test-Path $RootPath)) {
        throw "Menu root not found: $RootPath"
    }
    $rootName = Split-Path $RootPath -Leaf
    return (Get-MenuNode -Folder $RootPath -Relative $rootName)
}

function Get-MenuNode {
    param(
        [string]$Folder,
        [string]$Relative
    )
    $children = @()
    $dirs = Get-ChildItem -Path $Folder -Directory -ErrorAction SilentlyContinue
    foreach ($dir in $dirs) {
        $childRel = if ($Relative) { "$Relative/$($dir.Name)" } else { $dir.Name }
        $node = Get-MenuNode -Folder $dir.FullName -Relative $childRel
        $node.Type = "submenu"
        $children += $node
    }
    $opts = Get-ChildItem -Path $Folder -File -Filter "*.opt" -ErrorAction SilentlyContinue
    foreach ($opt in $opts) {
        $childRel = if ($Relative) { "$Relative/$($opt.BaseName)" } else { $opt.BaseName }
        $children += @{ 
            Name = $opt.BaseName
            Type = "option"
            Path = $childRel
            Children = @()
        }
    }
    return @{
        Name = (Split-Path $Folder -Leaf)
        Type = "submenu"
        Path = if ($Relative) { $Relative } else { (Split-Path $Folder -Leaf) }
        Children = $children
    }
}

function Get-MenuItemsAtPath {
    param(
        [hashtable]$Tree,
        [string]$Path
    )
    # If path matches tree root name, return root's children
    if ($Path -eq $Tree.Name) {
        return $Tree.Children
    }
    
    $parts = $Path -split "/"
    $node = $Tree
    foreach ($p in $parts) {
        if ($p -eq $Tree.Name) { continue }  # Skip root name
        $next = $node.Children | Where-Object { $_.Name -eq $p }
        if (-not $next) { return @() }
        $node = $next
    }
    return $node.Children
}

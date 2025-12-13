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
        $desc = ""
        try { $desc = (Get-Content -Path $opt.FullName -Raw -ErrorAction SilentlyContinue).Trim() } catch {}
        # Strip numeric prefix pattern like "0 - ", "1 - " from display name
        $displayName = $opt.BaseName -replace '^\d+\s*-\s*', ''
        $children += @{ 
            Name = $displayName
            Type = "option"
            Path = $childRel
            Children = @()
            Description = $desc
        }
    }
    # Handle .input files for free-form text input buttons
    $inputs = Get-ChildItem -Path $Folder -File -Filter "*.input" -ErrorAction SilentlyContinue
    foreach ($input in $inputs) {
        $childRel = if ($Relative) { "$Relative/$($input.BaseName)" } else { $input.BaseName }
        $desc = ""
        $prompt = "Enter value"
        try { 
            $content = (Get-Content -Path $input.FullName -Raw -ErrorAction SilentlyContinue).Trim()
            # First line is the prompt, rest is description
            $lines = $content -split "`n"
            if ($lines.Count -gt 0 -and $lines[0]) { $prompt = $lines[0] }
            if ($lines.Count -gt 1) { $desc = ($lines[1..($lines.Count-1)] -join "`n").Trim() }
        } catch {}
        $children += @{ 
            Name = $input.BaseName
            Type = "input"
            Path = $childRel
            Children = @()
            Description = $desc
            Prompt = $prompt
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
        return ,@($Tree.Children)
    }
    
    $parts = $Path -split "/"
    $node = $Tree
    foreach ($p in $parts) {
        if ($p -eq $Tree.Name) { continue }  # Skip root name
        $next = $node.Children | Where-Object { $_.Name -eq $p }
        if (-not $next) { return @() }
        $node = $next
    }
    return ,@($node.Children)
}

function Force-MenuRefresh {
    <#
    .SYNOPSIS
    Forces a complete rebuild of the menu tree from the filesystem.
    Used by termUI programs to trigger dynamic menu updates without restarting termUI.
    
    .PARAMETER RootPath
    The root path of the buttons directory to rebuild from
    
    .PARAMETER ClearCache
    If true, clears any cached menu structure before rebuilding
    
    .EXAMPLE
    Force-MenuRefresh -RootPath "c:/path/to/termUI/buttons" -ClearCache $true
    
    .NOTES
    This function is called by Refresh-TermUIMenu in TermUIFunctionLibrary.ps1
    It forces MenuBuilder to re-scan the filesystem and return the latest menu structure.
    #>
    param(
        [string]$RootPath = (Join-Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) "buttons"),
        [bool]$ClearCache = $true
    )
    
    try {
        if (-not (Test-Path $RootPath)) {
            Write-Error "Menu root not found: $RootPath"
            return $null
        }
        
        # Force garbage collection to clear any cached directory listings
        if ($ClearCache) {
            [System.GC]::Collect()
            [System.GC]::WaitForPendingFinalizers()
        }
        
        # Rebuild menu tree from filesystem
        $newTree = Build-MenuTree -RootPath $RootPath
        
        return $newTree
    }
    catch {
        Write-Error "Failed to refresh menu: $_"
        return $null
    }
}


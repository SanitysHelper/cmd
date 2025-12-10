#!/usr/bin/env python3
"""
termUI Standalone - Single executable distribution
Fully self-contained - no external files needed
Downloads termUI from GitHub and runs it locally
"""

import os
import sys
import json
import shutil
import tempfile
from pathlib import Path
from urllib.request import urlopen, Request
from subprocess import run, DEVNULL

# Configuration
GITHUB_REPO = "SanitysHelper/cmd"
GITHUB_BRANCH = "main"
GITHUB_RAW = f"https://raw.githubusercontent.com/{GITHUB_REPO}/{GITHUB_BRANCH}/termUI"
LOCAL_CACHE = Path.home() / "AppData" / "Roaming" / "termUI" if sys.platform == "win32" else Path.home() / ".termui"

def ensure_cache():
    """Create cache directory if it doesn't exist"""
    LOCAL_CACHE.mkdir(parents=True, exist_ok=True)

def download_file(remote_path: str, local_path: Path) -> bool:
    """Download a file from GitHub"""
    try:
        url = f"{GITHUB_RAW}/{remote_path}"
        local_path.parent.mkdir(parents=True, exist_ok=True)
        
        print(f"[INFO] Downloading: {remote_path}")
        req = Request(url, headers={'User-Agent': 'termUI-Standalone'})
        with urlopen(req, timeout=30) as response:
            with open(local_path, 'wb') as f:
                f.write(response.read())
        return True
    except Exception as e:
        print(f"[ERROR] Failed to download {remote_path}: {e}")
        return False

def compare_versions(v1: str, v2: str) -> int:
    """Compare two semantic versions. Returns: 1 if v1 > v2, -1 if v1 < v2, 0 if equal"""
    try:
        v1_parts = [int(x) for x in v1.split('.')]
        v2_parts = [int(x) for x in v2.split('.')]
        
        # Pad with zeros
        while len(v1_parts) < len(v2_parts):
            v1_parts.append(0)
        while len(v2_parts) < len(v1_parts):
            v2_parts.append(0)
        
        if v1_parts > v2_parts:
            return 1
        elif v1_parts < v2_parts:
            return -1
        return 0
    except:
        return 0

def should_download() -> bool:
    """Check if files need to be downloaded from GitHub"""
    ensure_cache()
    
    # Check if VERSION.json exists locally
    version_file = LOCAL_CACHE / "VERSION.json"
    
    # If no files cached, download everything
    if not version_file.exists():
        return True
    
    # If VERSION.json exists, check if remote version is greater
    try:
        with open(version_file) as f:
            local_data = json.load(f)
            local_ver = local_data.get('version', 'unknown')
    except:
        return True
    
    # Get remote version
    try:
        remote_ver = get_version(local=False)
        
        # If versions differ and remote is greater, download
        if remote_ver and remote_ver != 'unknown':
            if compare_versions(remote_ver, local_ver) > 0:
                print(f"[INFO] Newer version available: {local_ver} -> {remote_ver}")
                return True
    except:
        # If we can't reach GitHub, use cached files
        pass
    
    return False

def sync_files() -> bool:
    """Sync required files from GitHub"""
    ensure_cache()
    
    required_files = [
        'VERSION.json',
        'settings.ini',
        'powershell/termUI.ps1',
        'powershell/InputHandler.ps1',
        'powershell/modules/Logging.ps1',
        'powershell/modules/Settings.ps1',
        'powershell/modules/MenuBuilder.ps1',
        'powershell/modules/InputBridge.ps1',
        'powershell/modules/VersionManager.ps1',
        'powershell/modules/Update-Manager.ps1',
        'powershell/modules/TermUIButtonLibrary.ps1',
        'powershell/modules/TermUIFunctionLibrary.ps1',
    ]
    
    # Check if download is needed
    if not should_download():
        return True
    
    print()
    print("Syncing termUI files from GitHub...")
    print()
    
    downloaded = 0
    for file in required_files:
        local_path = LOCAL_CACHE / file
        if download_file(file, local_path):
            downloaded += 1
    
    if downloaded > 0:
        print()
        print(f"[SUCCESS] Downloaded {downloaded} files")
    else:
        print("[ERROR] No files downloaded")
        return False
    
    return True

def get_version(local: bool = True) -> str:
    """Get version number"""
    try:
        version_file = LOCAL_CACHE / "VERSION.json"
        if local and version_file.exists():
            with open(version_file) as f:
                data = json.load(f)
                return data.get('version', 'unknown')
        elif not local:
            req = Request(f"{GITHUB_RAW}/VERSION.json", headers={'User-Agent': 'termUI-Standalone'})
            with urlopen(req, timeout=10) as response:
                data = json.loads(response.read())
                return data.get('version', 'unknown')
    except:
        pass
    return "unknown"

def show_version():
    """Display version information"""
    local_ver = get_version(local=True)
    print()
    print("="*40)
    print(f"termUI v{local_ver} (Standalone)")
    print(f"GitHub: https://github.com/{GITHUB_REPO}")
    print(f"Branch: {GITHUB_BRANCH}")
    print("="*40)
    print()

def start_termui():
    """Start termUI application"""
    # Check and download only if needed
    if should_download():
        if not sync_files():
            return 1
    
    term_ui_script = LOCAL_CACHE / "powershell" / "termUI.ps1"
    if not term_ui_script.exists():
        print("[ERROR] Failed to load termUI script")
        return 1
    
    print()
    print("Starting termUI...")
    print()
    
    # Run PowerShell script
    try:
        result = run([
            'powershell',
            '-NoProfile',
            '-ExecutionPolicy', 'Bypass',
            '-File', str(term_ui_script)
        ] + sys.argv[1:])
        return result.returncode
    except Exception as e:
        print(f"[ERROR] Failed to start termUI: {e}")
        return 1

def main():
    """Main entry point"""
    if len(sys.argv) > 1:
        arg = sys.argv[1].lower()
        
        if arg in ['--version', '-v']:
            show_version()
            return 0
        elif arg in ['--check-update']:
            sync_files()
            local_ver = get_version(local=True)
            remote_ver = get_version(local=False)
            
            print()
            if remote_ver and local_ver != remote_ver:
                print(f"Update available: {local_ver} -> {remote_ver}")
            else:
                print("[INFO] No update available")
            print()
            return 0
        elif arg in ['--update']:
            sync_files()
            local_ver = get_version(local=True)
            remote_ver = get_version(local=False)
            
            if remote_ver and local_ver != remote_ver:
                print(f"Updating: {local_ver} -> {remote_ver}")
                shutil.rmtree(LOCAL_CACHE, ignore_errors=True)
                sync_files()
                print("[SUCCESS] Update complete!")
            else:
                print("[INFO] No update available")
            return 0
    
    return start_termui()

if __name__ == '__main__':
    sys.exit(main())

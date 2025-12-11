# tagScanner - Audio Tag Editor

A termUI-based application for batch reading and editing audio file tags (FLAC and MP3).

## Features

- **Read Mode**: Recursively scans directories and displays all tags for FLAC and MP3 files
- **Write Mode**: Batch edits tags across multiple files
- **Directory History**: Remembers previously used directories
- **Dynamic Menu**: Buttons are created programmatically on startup

## Dependencies

### Required Tools
- **metaflac** - For FLAC file tag operations
- **id3v2** - For MP3 file tag operations

### Installation (Windows)
```powershell
# Install via Chocolatey
choco install flac
choco install id3lib
```

## Usage

1. Run `termUI.exe` to launch the program
2. Select **Read Mode** to view tags without modification
3. Select **Write Mode** to batch edit tags

### Read Mode Workflow
1. Select directory (0 for new path, numbered options for history)
2. View all tags for all audio files in the directory tree

### Write Mode Workflow
1. Select directory
2. Choose file type (FLAC or MP3)
3. Select tag to edit
4. Enter new value (leave empty to remove tag)
5. Confirm to apply changes to all files

## Supported Tags

### FLAC (Vorbis Comments)
TITLE, ARTIST, ALBUM, ALBUMARTIST, DATE, GENRE, TRACKNUMBER, DISCNUMBER, COMMENT, COMPOSER, PERFORMER, COPYRIGHT, LICENSE, and more

### MP3 (ID3v2 Frames)
TIT2 (Title), TPE1 (Artist), TALB (Album), TPE2 (Album Artist), TDRC (Year), TCON (Genre), TRCK (Track), TPOS (Disc), COMM (Comment), and more

## Technical Details

- Uses `TermUIButtonLibrary` for dynamic menu creation
- Buttons initialized via `InitializeButtons.ps1` on startup
- Tag operations handled by `modules/TagScanner.ps1`
- Directory history stored in `directory_history.txt`

## Note

The termUI library in this folder is local and should be updated separately from the main termUI repository for testing purposes.

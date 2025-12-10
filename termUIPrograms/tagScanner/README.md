# tagScanner - Audio Tag Editor

A unified tag editing tool for MP3 and FLAC audio files using termUI framework.

## Features

- **Dual Format Support**: Works with both MP3 and FLAC files
- **Batch Operations**: Edit tags across entire music directories
- **TagLib# Integration**: Uses TagLib# library for MP3 support
- **metaflac Integration**: Uses metaflac.exe for FLAC support
- **Multiple Tags**: Edit Artist, Title, Album, Comment, Genre, Track, Year
- **Read/Write Modes**: View existing tags or bulk update them
- **Debug Mode**: Toggle detailed per-file output
- **Directory Memory**: Remembers previously used directories

## Setup

### Prerequisites

1. **taglib-sharp.dll** - Already included in this folder
2. **metaflac.exe** - Required for FLAC support
   - Add the directory containing metaflac.exe to `tagEditorDirs.txt`
   - One path per line

### Configuration

**tagEditorDirs.txt**
- Add directories containing metaflac.exe (one per line)
- Example: `C:\Program Files\FLAC\bin`

**settings.txt**
- `debug=false` - Normal mode (only shows changes)
- `debug=true` - Verbose mode (shows all file operations)

**enteredDirectories.txt**
- Automatically populated with music directories you've used
- Can be manually edited to add frequently used paths

## Usage

1. Run `run.bat` to start the program
2. Select or enter a music directory
3. Choose a tag to edit (Artist, Title, Album, etc.)
4. Select action:
   - **Read [0]**: View current tag values
   - **Write [1]**: Update tag values
5. Follow prompts to complete operation

## Supported Tags

- **Artist** - Track artist/performer
- **Title** - Song title
- **Album** - Album name
- **Comment** - User comments
- **Genre** - Music genre
- **Track** - Track number
- **Year** - Release year

## File Formats

- **MP3** - Uses TagLib# for ID3 tag editing
- **FLAC** - Uses metaflac.exe for Vorbis comment editing

## Debug Mode

Toggle debug mode in `settings.txt`:
- **debug=false**: Only shows files that are changed
- **debug=true**: Shows detailed output for every file processed

## Notes

- Empty tag values in write mode will delete the tag
- Both MP3 and FLAC files in the same directory are processed together
- Previous tag values are displayed before changes are made
- Summary statistics are shown after batch operations

## Directory Structure

```
tagScanner/
├── Read-Comments.ps1       - Main PowerShell script
├── run.bat                 - Launcher
├── taglib-sharp.dll        - MP3 tag library
├── settings.txt            - Configuration (debug mode)
├── enteredDirectories.txt  - Music directory history
├── tagEditorDirs.txt       - Tool directories (metaflac)
└── status.txt             - Status/state file
```

## Example Workflow

1. First run: Add metaflac.exe location to `tagEditorDirs.txt`
2. Run `run.bat`
3. Enter music directory path (saved for future use)
4. Select tag (e.g., "Artist")
5. Choose "Read" to view current values
6. Run again, choose "Write" to update values
7. Enter new value or leave blank to delete
8. Review summary of changes

## Troubleshooting

**"metaflac.exe not found"**
- Add the directory containing metaflac.exe to `tagEditorDirs.txt`

**"taglib-sharp.dll not found"**
- Ensure taglib-sharp.dll is in the same folder as Read-Comments.ps1

**No files found**
- Verify the music directory path is correct
- Check that directory contains .mp3 or .flac files

## Integration with termUI

This tool is part of the termUIPrograms collection and can be integrated into the termUI menu system for easy access through the terminal interface.

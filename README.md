# quackalias-cli - DuckDuckGo Email Alias Manager

A professional command-line tool to generate and manage DuckDuckGo email aliases with full history tracking.

## Features

- Generate DuckDuckGo email aliases from the command line
- Automatic clipboard copying
- Add notes to track what each alias is used for
- Search and filter alias history
- Secure API key storage in config files
- Cross-platform support (Linux, macOS, Windows)
- Color-coded output for better readability
- Command shortcuts for faster workflows

## Installation

### Linux / macOS (Bash)

1. **Download the script:**
   ```bash
   curl -O https://raw.githubusercontent.com/mouadlotfi/quackalias-cli/main/ddg.sh
   ```

2. **Make it executable:**
   ```bash
   chmod +x ddg.sh
   ```

3. **Move to a directory in your PATH:**
   ```bash
   sudo mv ddg.sh /usr/local/bin/quackalias
   ```

4. **Configure your API key:**
   ```bash
   quackalias config
   ```

### Windows (PowerShell)

1. **Download the script:**
   ```powershell
   Invoke-WebRequest -Uri "https://raw.githubusercontent.com/mouadlotfi/quackalias-cli/main/ddg.ps1" -OutFile "quackalias.ps1"
   ```

2. **Set execution policy (if needed):**
   ```powershell
   Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned
   ```

3. **Create a permanent alias (optional):**
   Add to your PowerShell profile (`$PROFILE`):
   ```powershell
   function quackalias { & "C:\Path\To\quackalias.ps1" $args }
   ```

4. **Configure your API key:**
   ```powershell
   .\quackalias.ps1 config
   ```

## Getting Your API Key

1. Install the [DuckDuckGo web browser extension](https://duckduckgo.com/email/)
2. Set up [Email Protection](https://duckduckgo.com/email/)
3. Open the email autofill page
4. Right-click and select "Inspect" to open Developer Tools
5. Click the "Network" tab
6. Click "Generate Private Duck Address" on the page
7. In the Network tab, click on the "addresses" request
8. Scroll down to find the "authorization: Bearer" header
9. Copy the long string after "Bearer " (without "Bearer" itself)
10. Run `quackalias config` and paste your key

> Note: You can uninstall the extension after obtaining the API key.

## Usage

### Commands

```bash
quackalias [COMMAND] [OPTIONS]
```

| Command | Shortcut | Description |
|---------|----------|-------------|
| `generate [note]` | `g` | Generate a new email alias with optional note |
| `history` | `h` | Show all generated aliases in a table |
| `search <query>` | `s` | Search aliases by keyword (note, email, or date) |
| `count` | `c` | Show total number of generated aliases |
| `config` | - | Configure or update API key |
| `help` | `-h`, `--help` | Show help message |

### Examples

**Generate a new alias:**
```bash
quackalias generate
# or use shortcut
quackalias g
```

**Generate with a note:**
```bash
quackalias generate "Amazon shopping account"
quackalias g "Newsletter signup"
```

**View all aliases:**
```bash
quackalias history
quackalias h
```

**Search for specific aliases:**
```bash
quackalias search amazon
quackalias s shopping
```

**Count total aliases:**
```bash
quackalias count
quackalias c
```

**Update API key:**
```bash
quackalias config
```

### Sample Output

```
$ quackalias generate "GitHub signup"
ℹ Generating new email alias...
✓ Email alias generated: abc123xyz@duck.com
ℹ Copied to clipboard

$ quackalias history
Alias History
=============

DATE                 EMAIL ALIAS                              NOTE
----                 -----------                              ----
2025-12-26 10:30:15  abc123xyz@duck.com                       GitHub signup
2025-12-26 09:15:42  def456uvw@duck.com                       Shopping newsletter
2025-12-25 14:22:01  ghi789rst@duck.com                       Random site signup
```

## Configuration Files

### Linux / macOS
- **Config:** `~/.config/quackalias/config`
- **History:** `~/.local/share/quackalias/aliases.txt`

### Windows
- **Config:** `C:\Users\mouadlotfi\.config\quackalias\config.json`
- **History:** `C:\Users\mouadlotfi\.local\share\quackalias\aliases.txt`

## Features in Detail

### Automatic Clipboard Copy
Generated aliases are automatically copied to your clipboard (when available):
- Linux: Uses `xclip` or `clip.exe` (WSL)
- macOS: Uses `pbcopy`
- Windows: Uses `Set-Clipboard`

### History Format
Each entry in the history file includes:
- Timestamp (YYYY-MM-DD HH:MM:SS)
- Full email alias
- Optional note/description

### Secure Storage
- API keys are stored in local config files
- Config files have restricted permissions (600 on Unix systems)
- No data is sent anywhere except DuckDuckGo's API

## Troubleshooting

### "API key not configured" error
Run `quackalias config` to set up your API key.

### "Failed to generate alias" error
- Check that your API key is valid
- Ensure you have internet connectivity
- Verify the DuckDuckGo API is accessible

### Clipboard not working (Linux)
Install `xclip`:
```bash
# Debian/Ubuntu
sudo apt install xclip

# Fedora
sudo dnf install xclip

# Arch
sudo pacman -S xclip
```

### PowerShell execution policy error
Run PowerShell as Administrator and execute:
```powershell
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned
```

## License

This project is licensed under the GPL-3.0 License. See the [LICENSE](LICENSE) file for details.

## Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

For major changes, please open an issue first to discuss what you would like to change.

## Privacy

- Your API key is stored locally and never transmitted anywhere except DuckDuckGo's official API
- Alias history is stored locally on your machine
- No telemetry or analytics are collected
- No third-party services are used

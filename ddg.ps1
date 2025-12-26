# quackalias - DuckDuckGo Email Alias Manager
# Version: 1.0.0

param (
    [Parameter(Position = 0)]
    [string]$Command,

    [Parameter(Position = 1, ValueFromRemainingArguments = $true)]
    [string[]]$Arguments
)

# Configuration paths
$configDir = "$env:USERPROFILE\.config\quackalias"
$configFile = "$configDir\config.json"
$historyDir = "$env:USERPROFILE\.local\share\quackalias"
$historyFile = "$historyDir\aliases.txt"

# Ensure directories exist
if (-not (Test-Path -Path $configDir)) {
    New-Item -ItemType Directory -Path $configDir -Force | Out-Null
}

if (-not (Test-Path -Path $historyDir)) {
    New-Item -ItemType Directory -Path $historyDir -Force | Out-Null
}

# Color functions
function Write-Success {
    param([string]$Message)
    Write-Host "✓ $Message" -ForegroundColor Green
}

function Write-Info {
    param([string]$Message)
    Write-Host "ℹ $Message" -ForegroundColor Cyan
}

function Write-Warning {
    param([string]$Message)
    Write-Host "⚠ $Message" -ForegroundColor Yellow
}

function Write-Error {
    param([string]$Message)
    Write-Host "Error: $Message" -ForegroundColor Red
}

# Get API key from config
function Get-ApiKey {
    if (Test-Path $configFile) {
        try {
            $config = Get-Content $configFile | ConvertFrom-Json
            if ($config.ApiKey) {
                return $config.ApiKey
            }
        }
        catch {
            return $null
        }
    }
    return $null
}

# Configure API key
function Set-ApiKey {
    Write-Host "DuckDuckGo API Key Configuration" -ForegroundColor Cyan
    Write-Host "=================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Info "To obtain your API key, follow these steps:"
    Write-Host "1. Visit https://duckduckgo.com/email/"
    Write-Host "2. Open browser developer tools (F12)"
    Write-Host "3. Go to Network tab"
    Write-Host "4. Click 'Generate Private Duck Address'"
    Write-Host "5. Find the 'addresses' request"
    Write-Host "6. Copy the Bearer token from Authorization header"
    Write-Host ""

    $apiKey = Read-Host "Enter your DuckDuckGo API key"

    if ([string]::IsNullOrWhiteSpace($apiKey)) {
        Write-Error "API key cannot be empty"
        exit 1
    }

    $config = @{
        ApiKey = $apiKey
    }

    $config | ConvertTo-Json | Set-Content $configFile
    Write-Success "API key saved securely to $configFile"
}

# Generate new alias
function New-Alias {
    param([string]$Note)

    $apiKey = Get-ApiKey
    if (-not $apiKey) {
        Write-Error "API key not configured. Run: quackalias config"
        exit 1
    }

    Write-Info "Generating new email alias..."

    $url = "https://quack.duckduckgo.com/api/email/addresses"
    $headers = @{
        'Authorization' = "Bearer $apiKey"
        'Content-Type'  = 'application/json'
    }

    try {
        $response = Invoke-RestMethod -Uri $url -Method Post -Headers $headers -Body "{}"

        if ($response -and $response.address) {
            $alias = "$($response.address)@duck.com"
            $timestamp = Get-Date -Format "yyyy-MM-dd HH:MM:ss"

            if ($Note) {
                $entry = "$timestamp | $alias | $Note"
            }
            else {
                $entry = "$timestamp | $alias |"
            }

            Add-Content -Path $historyFile -Value $entry
            Write-Success "Email alias generated: $alias"

            # Copy to clipboard
            try {
                Set-Clipboard -Value $alias
                Write-Info "Copied to clipboard"
            }
            catch {
                # Clipboard not available, ignore
            }
        }
        else {
            Write-Error "Failed to generate alias"
            Write-Host "Response: $($response | ConvertTo-Json)"
            exit 1
        }
    }
    catch {
        Write-Error "Failed to generate alias: $_"
        exit 1
    }
}

# Show alias history
function Show-History {
    if (-not (Test-Path $historyFile) -or (Get-Item $historyFile).Length -eq 0) {
        Write-Warning "No aliases history found"
        return
    }

    Write-Host "Alias History" -ForegroundColor Cyan
    Write-Host "=============" -ForegroundColor Cyan
    Write-Host ""

    # Format output with columns
    Write-Host ("{0,-20} {1,-40} {2}" -f "DATE", "EMAIL ALIAS", "NOTE")
    Write-Host ("{0,-20} {1,-40} {2}" -f "----", "-----------", "----")

    Get-Content $historyFile | ForEach-Object {
        $parts = $_ -split '\|'
        if ($parts.Length -ge 2) {
            $timestamp = $parts[0].Trim()
            $alias = $parts[1].Trim()
            $note = if ($parts.Length -ge 3) { $parts[2].Trim() } else { "" }

            Write-Host ("{0,-20} {1,-40} {2}" -f $timestamp, $alias, $note)
        }
    }
}

# Search alias history
function Search-History {
    param([string]$Query)

    if ([string]::IsNullOrWhiteSpace($Query)) {
        Write-Error "Search query cannot be empty"
        exit 1
    }

    if (-not (Test-Path $historyFile)) {
        Write-Warning "No aliases history found"
        return
    }

    Write-Host "Search Results for: $Query" -ForegroundColor Cyan
    Write-Host "==========================" -ForegroundColor Cyan
    Write-Host ""

    $results = Get-Content $historyFile | Select-String -Pattern $Query -SimpleMatch

    if ($results.Count -eq 0) {
        Write-Warning "No matches found"
    }
    else {
        Write-Host ("{0,-20} {1,-40} {2}" -f "DATE", "EMAIL ALIAS", "NOTE")
        Write-Host ("{0,-20} {1,-40} {2}" -f "----", "-----------", "----")

        $results | ForEach-Object {
            $parts = $_.Line -split '\|'
            if ($parts.Length -ge 2) {
                $timestamp = $parts[0].Trim()
                $alias = $parts[1].Trim()
                $note = if ($parts.Length -ge 3) { $parts[2].Trim() } else { "" }

                Write-Host ("{0,-20} {1,-40} {2}" -f $timestamp, $alias, $note)
            }
        }
    }
}

# Count aliases
function Get-AliasCount {
    if (-not (Test-Path $historyFile)) {
        Write-Host "0 aliases generated"
    }
    else {
        $count = (Get-Content $historyFile | Measure-Object -Line).Lines
        Write-Host "$count aliases generated"
    }
}

# Show help
function Show-Help {
    Write-Host @"
quackalias - DuckDuckGo Email Alias Manager

USAGE:
    quackalias [COMMAND] [OPTIONS]

COMMANDS:
    generate [note]     Generate a new email alias with optional note
    history            Show all generated aliases
    search <query>     Search aliases history by keyword
    count              Show total number of generated aliases
    config             Configure API key
    help               Show this help message

EXAMPLES:
    quackalias generate                    # Generate a new alias
    quackalias generate "Shopping site"    # Generate alias with note
    quackalias history                     # View all aliases
    quackalias search amazon               # Search for aliases
    quackalias config                      # Set up API key

For more information, visit: https://github.com/yourusername/quackalias-cli
"@
}

# Main script logic
switch ($Command) {
    { $_ -in "generate", "g" } {
        $note = $Arguments -join " "
        New-Alias -Note $note
    }
    { $_ -in "history", "h" } {
        Show-History
    }
    { $_ -in "search", "s" } {
        $query = $Arguments -join " "
        Search-History -Query $query
    }
    { $_ -in "count", "c" } {
        Get-AliasCount
    }
    "config" {
        Set-ApiKey
    }
    { $_ -in "help", "--help", "-h" } {
        Show-Help
    }
    default {
        if ([string]::IsNullOrWhiteSpace($Command)) {
            Show-Help
        }
        else {
            Write-Error "Unknown command: $Command"
            Write-Host ""
            Show-Help
            exit 1
        }
    }
}

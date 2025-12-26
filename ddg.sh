#!/bin/bash

# quackalias - DuckDuckGo Email Alias Manager
# Version: 1.0.0

set -e

# Configuration paths
CONFIG_DIR="$HOME/.config/quackalias"
CONFIG_FILE="$CONFIG_DIR/config"
HISTORY_DIR="$HOME/.local/share/quackalias"
HISTORY_FILE="$HISTORY_DIR/aliases.txt"

# Colors for better output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Ensure directories exist
mkdir -p "$CONFIG_DIR" "$HISTORY_DIR"

# Functions
print_error() {
    echo -e "${RED}Error:${NC} $1" >&2
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

get_api_key() {
    if [ -f "$CONFIG_FILE" ]; then
        source "$CONFIG_FILE"
        if [ -n "$API_KEY" ]; then
            echo "$API_KEY"
            return 0
        fi
    fi
    return 1
}

config_setup() {
    echo "DuckDuckGo API Key Configuration"
    echo "================================="
    echo
    print_info "To obtain your API key, follow these steps:"
    echo "1. Visit https://duckduckgo.com/email/"
    echo "2. Open browser developer tools (F12)"
    echo "3. Go to Network tab"
    echo "4. Click 'Generate Private Duck Address'"
    echo "5. Find the 'addresses' request"
    echo "6. Copy the Bearer token from Authorization header"
    echo
    read -p "Enter your DuckDuckGo API key: " api_key

    if [ -z "$api_key" ]; then
        print_error "API key cannot be empty"
        exit 1
    fi

    echo "API_KEY=\"$api_key\"" > "$CONFIG_FILE"
    chmod 600 "$CONFIG_FILE"
    print_success "API key saved securely to $CONFIG_FILE"
}

generate_alias() {
    local note="$1"

    API_KEY=$(get_api_key) || {
        print_error "API key not configured. Run: quackalias config"
        exit 1
    }

    print_info "Generating new email alias..."

    RESPONSE=$(curl -s -X POST \
        -H "Authorization: Bearer $API_KEY" \
        -H "Content-Type: application/json" \
        -d '{}' \
        https://quack.duckduckgo.com/api/email/addresses)

    ALIAS=$(echo "$RESPONSE" | grep -oP '(?<="address":")[^"]*')

    if [ -n "$ALIAS" ]; then
        FULL_ALIAS="$ALIAS@duck.com"
        TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")

        if [ -n "$note" ]; then
            echo "$TIMESTAMP | $FULL_ALIAS | $note" >> "$HISTORY_FILE"
        else
            echo "$TIMESTAMP | $FULL_ALIAS |" >> "$HISTORY_FILE"
        fi

        print_success "Email alias generated: $FULL_ALIAS"

        # Copy to clipboard if available
        if command -v xclip &> /dev/null; then
            echo -n "$FULL_ALIAS" | xclip -selection clipboard
            print_info "Copied to clipboard"
        elif command -v pbcopy &> /dev/null; then
            echo -n "$FULL_ALIAS" | pbcopy
            print_info "Copied to clipboard"
        elif command -v clip.exe &> /dev/null; then
            echo -n "$FULL_ALIAS" | clip.exe
            print_info "Copied to clipboard"
        fi
    else
        print_error "Failed to generate alias"
        echo "Response: $RESPONSE"
        exit 1
    fi
}

show_history() {
    if [ ! -f "$HISTORY_FILE" ] || [ ! -s "$HISTORY_FILE" ]; then
        print_warning "No aliases history found"
        exit 0
    fi

    echo "Alias History"
    echo "============="
    echo

    # Format output with columns
    printf "%-20s %-40s %s\n" "DATE" "EMAIL ALIAS" "NOTE"
    printf "%-20s %-40s %s\n" "----" "-----------" "----"

    while IFS='|' read -r timestamp alias note; do
        # Trim whitespace
        timestamp=$(echo "$timestamp" | xargs)
        alias=$(echo "$alias" | xargs)
        note=$(echo "$note" | xargs)

        printf "%-20s %-40s %s\n" "$timestamp" "$alias" "$note"
    done < "$HISTORY_FILE"
}

search_history() {
    local query="$1"

    if [ -z "$query" ]; then
        print_error "Search query cannot be empty"
        exit 1
    fi

    if [ ! -f "$HISTORY_FILE" ]; then
        print_warning "No aliases history found"
        exit 0
    fi

    echo "Search Results for: $query"
    echo "=========================="
    echo

    results=$(grep -i "$query" "$HISTORY_FILE" || true)

    if [ -z "$results" ]; then
        print_warning "No matches found"
    else
        printf "%-20s %-40s %s\n" "DATE" "EMAIL ALIAS" "NOTE"
        printf "%-20s %-40s %s\n" "----" "-----------" "----"

        echo "$results" | while IFS='|' read -r timestamp alias note; do
            timestamp=$(echo "$timestamp" | xargs)
            alias=$(echo "$alias" | xargs)
            note=$(echo "$note" | xargs)

            printf "%-20s %-40s %s\n" "$timestamp" "$alias" "$note"
        done
    fi
}

count_aliases() {
    if [ ! -f "$HISTORY_FILE" ]; then
        echo "0 aliases generated"
    else
        count=$(wc -l < "$HISTORY_FILE")
        echo "$count aliases generated"
    fi
}

show_help() {
    cat << EOF
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
EOF
}

# Main script logic
case "${1:-}" in
    generate|g)
        shift
        generate_alias "$*"
        ;;
    history|h)
        show_history
        ;;
    search|s)
        shift
        search_history "$*"
        ;;
    count|c)
        count_aliases
        ;;
    config)
        config_setup
        ;;
    help|--help|-h)
        show_help
        ;;
    "")
        show_help
        ;;
    *)
        print_error "Unknown command: $1"
        echo
        show_help
        exit 1
        ;;
esac

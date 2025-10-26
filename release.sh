#!/bin/bash

# Release script for vincevarga.dev

# Stop execution on any failure
set -eo pipefail

# Parse command line arguments
DEBUG_MODE=false
for arg in "$@"; do
    case $arg in
        --debug)
            DEBUG_MODE=true
            shift
            ;;
        --help|-h)
            echo "Usage: $0 [--debug] [--help]"
            echo ""
            echo "Options:"
            echo "  --debug    Enable debug mode with additional health checks"
            echo "  --help     Show this help message"
            echo ""
            exit 0
            ;;
        *)
            echo "Unknown option: $arg"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# SSH configuration
SSH_KEY="~/.ssh/id_ed25519_scaleway"
SSH_HOST="root@51.15.107.139"
SSH_PATH="ssh -i $SSH_KEY $SSH_HOST"

# Server paths
SERVER_WEB_ROOT="/var/www/vincevarga.dev"
CADDY_CONFIG_PATH="/etc/caddy/Caddyfile"

# Generate timestamp for backup
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_PATH="${SERVER_WEB_ROOT}.${TIMESTAMP}.bak"

# Start timing the release process
START_TIME=$(date +%s)

echo "Starting release process..."

# Build Hugo site locally
echo "🟡 Building Hugo site..."
hugo build
echo "🟢 Hugo site built."

# Debug mode health checks
if [ "$DEBUG_MODE" = true ]; then
    # Verify Caddy is installed on server
    echo "🟡 Verifying Caddy installation on server..."
    $SSH_PATH "caddy --version"
    echo "🟢 Caddy installation verified."

    # Check current Caddy status
    echo "🟡 Checking current Caddy status..."
    $SSH_PATH "sudo systemctl status caddy --no-pager"
    echo "🟢 Current Caddy status checked."
fi

# Backup existing deployment
echo "🟡 Backing up existing deployment..."
$SSH_PATH "if [ -d '$SERVER_WEB_ROOT' ]; then sudo mv '$SERVER_WEB_ROOT' '$BACKUP_PATH' && echo 'Backup created at $BACKUP_PATH'; else echo 'No existing deployment to backup'; fi"
echo "🟢 Existing deployment backed up."

# Copy Caddyfile to server
echo "🟡 Copying Caddyfile to server..."
if [ "$DEBUG_MODE" = true ]; then
    scp -i $SSH_KEY Caddyfile $SSH_HOST:$CADDY_CONFIG_PATH
else
    scp -q -i $SSH_KEY Caddyfile $SSH_HOST:$CADDY_CONFIG_PATH
fi
echo "🟢 Caddyfile copied to server."

# Validate Caddyfile on server (debug mode only)
if [ "$DEBUG_MODE" = true ]; then
    echo "🟡 Validating Caddyfile on server..."
    $SSH_PATH "caddy validate --config $CADDY_CONFIG_PATH"
    echo "🟢 Caddyfile validation passed."
fi

# Copy public folder to server
echo "🟡 Copying public folder to server..."
$SSH_PATH "sudo mkdir -p $SERVER_WEB_ROOT"
if [ "$DEBUG_MODE" = true ]; then
    scp -i $SSH_KEY -r public/* $SSH_HOST:$SERVER_WEB_ROOT/
else
    scp -q -i $SSH_KEY -r public/* $SSH_HOST:$SERVER_WEB_ROOT/
fi
echo "🟢 Public folder copied to server."

# Reload Caddy service
# Note: This is only actually needed if the Caddyfile is changed,
# but it's fast, so we do it anyway to keep the script simple and predictable.
echo "🟡 Reloading Caddy service..."
$SSH_PATH "sudo systemctl reload caddy"
echo "🟢 Caddy service reloaded."

# Check Caddy status after reload (debug mode only)
if [ "$DEBUG_MODE" = true ]; then
    echo "🟡 Checking Caddy status after reload..."
    $SSH_PATH "sudo systemctl status caddy --no-pager"
    echo "🟢 Caddy status checked after reload."
fi

# Clean up old backups (keep only latest 5)
echo "🟡 Cleaning up old backups..."
$SSH_PATH "
cd /var/www && 
if ls -1d vincevarga.dev.*.bak 2>/dev/null | wc -l | grep -q '^[6-9]' || ls -1d vincevarga.dev.*.bak 2>/dev/null | wc -l | grep -q '^[0-9][0-9]'; then
    echo 'Found more than 5 backups, cleaning up...'
    OLD_BACKUPS=\$(ls -1d vincevarga.dev.*.bak | sort -r | tail -n +6)
    if [ -n \"\$OLD_BACKUPS\" ]; then
        echo 'Removing the following old backups:'
        echo \"\$OLD_BACKUPS\"
        echo \"\$OLD_BACKUPS\" | xargs -r sudo rm -rf
        echo 'Old backups removed, kept latest 5'
    fi
else
    echo 'No cleanup needed (5 or fewer backups found)'
fi
"
echo "🟢 Old backups cleaned up."

# Calculate and display total execution time
END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))
MINUTES=$((DURATION / 60))
SECONDS=$((DURATION % 60))

echo ""
echo "🎉 Release completed successfully!"
echo ""
if [ $MINUTES -gt 0 ]; then
    echo "⏱️  Total release time: ${MINUTES}m ${SECONDS}s"
else
    echo "⏱️  Total release time: ${SECONDS}s"
fi
echo ""
echo "Your site is now live at https://vincevarga.dev"
echo ""
echo "To open the live website in your browser, run:"
echo "🔗 open https://vincevarga.dev"
echo ""

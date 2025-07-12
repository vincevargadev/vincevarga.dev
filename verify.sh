#!/bin/bash

# Stop execution on any failure
set -e

echo "Starting verification process..."

# Check if Go is installed
echo "🟡 Checking Go installation..."
if ! command -v go &> /dev/null; then
    echo "🔴 Go not found."
    echo "Fix: Install Go with 'brew install go' on Mac"
    exit 1
fi
echo "🟢 Go $(go version | cut -d' ' -f3) found."

# Check if Hugo is installed
echo "🟡 Checking Hugo installation..."
if ! command -v hugo &> /dev/null; then
    echo "🔴 Hugo not found."
    echo "Fix: Install Hugo with 'brew install hugo' on Mac"
    exit 1
fi
echo "🟢 Hugo $(hugo version | cut -d' ' -f2) found."

# Get Hugo module dependencies
echo "🟡 Getting Hugo module dependencies..."
if ! hugo mod get &> /dev/null; then
    echo "🔴 Hugo module dependencies failed."
    echo "Fix: Check your internet connection and ensure go.mod is valid"
    echo "Try running 'hugo mod get' manually to see the specific error"
    exit 1
fi
echo "🟢 Hugo module dependencies updated."

# Build the project
echo "🟡 Building the project..."
if ! hugo build &> /dev/null; then
    echo "🔴 Build failed."
    echo "Fix: Check your Hugo configuration and content files"
    echo "Try running 'hugo build' manually to see the specific error"
    exit 1
fi
echo "🟢 Build completed successfully."

echo ""
echo "🎉 Verification completed successfully!"
echo ""
echo "Your vincevarga.dev setup is ready for development."
echo ""
echo "To start the development server, run:"
echo "🚀 hugo serve"
echo ""

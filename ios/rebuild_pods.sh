#!/bin/bash

# Script to rebuild iOS project with clean pod installation
echo "Starting iOS project rebuild process..."

# Navigate to iOS directory
cd "$(dirname "$0")"

# Clean up
echo "Cleaning up previous Pods installation..."
rm -rf Pods Podfile.lock
rm -rf .symlinks/

# Re-run Flutter pub get to update native configuration
echo "Running Flutter pub get..."
cd ..
flutter pub get

# Go back to iOS directory and install pods
echo "Installing Pods with fixed versions..."
cd ios
pod install
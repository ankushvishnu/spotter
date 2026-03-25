#!/bin/bash
set -e

echo "Downloading Flutter SDK..."
git clone https://github.com/flutter/flutter.git -b stable --depth 1

echo "Adding Flutter to PATH..."
export PATH="$PATH:`pwd`/flutter/bin"

echo "Pre-caching Flutter dependencies..."
flutter precache

echo "Fetching project dependencies..."
flutter pub get

echo "Building Flutter Web application..."
flutter build web --release

echo "Build complete."

#!/bin/bash

# Clean flutter build
echo "Cleaning flutter build..."
cd ..
flutter clean

# Build flutter for iOS
echo "Building Flutter iOS..."
flutter build ios --release --no-codesign

# Go to iOS directory
cd ios

# Create an archive
echo "Creating archive..."
xcodebuild -workspace Runner.xcworkspace -scheme Runner -configuration Release -sdk iphoneos -arch arm64 archive -archivePath Runner.xcarchive

# Export IPA using our options
echo "Exporting IPA..."
xcodebuild -exportArchive -archivePath Runner.xcarchive -exportOptionsPlist exportOptions.plist -exportPath ./build

echo "Done! IPA should be in the ios/build directory" 
#!/bin/bash

# Setup script for SwiftUI iOS Project
# This script initializes the project directory structure

echo "🚀 Setting up SwiftUI iOS Project..."

# Create main directories
echo "📁 Creating project directories..."
mkdir -p Sources/
mkdir -p Assets/xcassets/

# Create .gitkeep file in xcassets to preserve directory in Git
echo "📝 Adding .gitkeep to Assets/xcassets/..."
echo "# This file ensures the xcassets directory is tracked by Git" > Assets/xcassets/.gitkeep
echo "# Xcode will manage the actual .xcassets bundle content" >> Assets/xcassets/.gitkeep
echo "# Add your app icons, images, and color assets through Xcode's Asset Catalog" >> Assets/xcassets/.gitkeep

# Print directory structure
echo ""
echo "✅ Project structure created:"
echo "📁 Sources/          - Swift source files"
echo "📁 Assets/xcassets/  - Xcode Asset Catalog (with .gitkeep)"
echo ""

# Check if Swift files exist in Sources
if [ "$(ls -A Sources/)" ]; then
    echo "📄 Swift files found in Sources/:"
    ls -la Sources/ | grep "\.swift$" | awk '{print "   " $9}'
else
    echo "📄 Sources/ directory is ready for Swift files"
fi

echo ""
echo "🎉 Setup complete! Your SwiftUI iOS project is ready."
echo "💡 Next steps:"
echo "   - Add your Swift files to Sources/"
echo "   - Open in Xcode to configure .xcassets"
echo "   - Start building your SwiftUI app!"
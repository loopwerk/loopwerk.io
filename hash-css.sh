#!/bin/bash
set -e

# Build directory where CSS and HTML files are located
BUILD_DIR="deploy"
CSS_FILE="$BUILD_DIR/static/output.css"

# Check if CSS file exists
if [ ! -f "$CSS_FILE" ]; then
    echo "Error: CSS file not found at $CSS_FILE"
    exit 1
fi

# Generate MD5 hash of the CSS file
CSS_HASH=$(md5sum "$CSS_FILE" | cut -d' ' -f1 | cut -c1-8)

# Create new filename with hash
CSS_NEW_NAME="output-${CSS_HASH}.css"
CSS_NEW_PATH="$BUILD_DIR/static/$CSS_NEW_NAME"

# Rename the CSS file
mv "$CSS_FILE" "$CSS_NEW_PATH"
echo "Renamed CSS file to: $CSS_NEW_NAME"

# Update all HTML files to reference the new CSS filename
find "$BUILD_DIR" -name "*.html" -type f | while read -r html_file; do
    # Replace references to output.css with the hashed version
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        sed -i '' "s|/static/output\.css|/static/${CSS_NEW_NAME}|g" "$html_file"
    else
        # Linux/Debian
        sed -i "s|/static/output\.css|/static/${CSS_NEW_NAME}|g" "$html_file"
    fi
done

echo "Updated all HTML files to reference: $CSS_NEW_NAME"
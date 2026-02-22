#!/bin/bash
set -e

# Build directory where CSS and HTML files are located
BUILD_DIR="deploy"
CSS_FILES=("output.css" "prism.css")

for CSS_NAME in "${CSS_FILES[@]}"; do
    CSS_FILE="$BUILD_DIR/static/$CSS_NAME"

    # Check if CSS file exists
    if [ ! -f "$CSS_FILE" ]; then
        echo "Error: CSS file not found at $CSS_FILE"
        exit 1
    fi

    # Generate MD5 hash of the CSS file
    CSS_HASH=$(md5sum "$CSS_FILE" | cut -d' ' -f1 | cut -c1-8)

    # Create new filename with hash
    CSS_BASE="${CSS_NAME%.css}"
    CSS_NEW_NAME="${CSS_BASE}-${CSS_HASH}.css"

    # Rename the CSS file
    mv "$CSS_FILE" "$BUILD_DIR/static/$CSS_NEW_NAME"
    echo "Renamed $CSS_NAME to: $CSS_NEW_NAME"

    # Update all HTML files to reference the new CSS filename
    find "$BUILD_DIR" -name "*.html" -type f | while read -r html_file; do
        if [[ "$OSTYPE" == "darwin"* ]]; then
            # macOS
            sed -i '' "s|/static/${CSS_NAME}|/static/${CSS_NEW_NAME}|g" "$html_file"
        else
            # Linux/Debian
            sed -i "s|/static/${CSS_NAME}|/static/${CSS_NEW_NAME}|g" "$html_file"
        fi
    done

    echo "Updated all HTML files to reference: $CSS_NEW_NAME"
done
#!/bin/bash

# export_screenshots.sh
# Script to export UI test screenshots to an organized directory
# Created by Jin on 5/7/26

set -e

# Configuration
PROJECT_NAME="TeslaCare"
SCREENSHOTS_DIR="./Screenshots"
DATE_STAMP=$(date +"%Y-%m-%d_%H-%M-%S")
EXPORT_DIR="${SCREENSHOTS_DIR}/${DATE_STAMP}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Print header
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  TeslaCare Screenshot Export Tool${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Find DerivedData directory
echo -e "${YELLOW}🔍 Locating test results...${NC}"
DERIVED_DATA_PATH=$(xcodebuild -showBuildSettings 2>/dev/null | grep -m 1 "BUILD_DIR" | sed 's/[ ]*BUILD_DIR = //' | sed 's|/Build/Products||')

if [ -z "$DERIVED_DATA_PATH" ]; then
    DERIVED_DATA_PATH="$HOME/Library/Developer/Xcode/DerivedData"
fi

echo -e "   DerivedData path: ${DERIVED_DATA_PATH}"

# Find the TeslaCare project's DerivedData folder
PROJECT_DERIVED_DATA=$(find "$DERIVED_DATA_PATH" -maxdepth 1 -type d -name "${PROJECT_NAME}*" | head -n 1)

if [ -z "$PROJECT_DERIVED_DATA" ]; then
    echo -e "${RED}❌ Error: Could not find ${PROJECT_NAME} DerivedData${NC}"
    echo -e "   Expected location: ${DERIVED_DATA_PATH}/${PROJECT_NAME}-*"
    echo ""
    echo -e "${YELLOW}💡 Try running tests first:${NC}"
    echo -e "   xcodebuild test -scheme ${PROJECT_NAME} -destination 'platform=iOS Simulator,name=iPhone 15 Pro'"
    exit 1
fi

echo -e "${GREEN}✓ Found project DerivedData${NC}"

# Find attachments directory
ATTACHMENTS_PATH="${PROJECT_DERIVED_DATA}/Logs/Test/Attachments"

if [ ! -d "$ATTACHMENTS_PATH" ]; then
    echo -e "${RED}❌ Error: No test attachments found${NC}"
    echo -e "   Expected location: ${ATTACHMENTS_PATH}"
    echo -e "${YELLOW}💡 Run UI tests to generate screenshots${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Found test attachments${NC}"

# Count available screenshots
SCREENSHOT_COUNT=$(find "$ATTACHMENTS_PATH" -name "*.png" -o -name "*.jpg" | wc -l | tr -d ' ')

if [ "$SCREENSHOT_COUNT" -eq 0 ]; then
    echo -e "${RED}❌ Error: No screenshot files found${NC}"
    echo -e "${YELLOW}💡 Ensure tests are configured to keep screenshots (attachment.lifetime = .keepAlways)${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Found ${SCREENSHOT_COUNT} screenshot(s)${NC}"
echo ""

# Create export directory
echo -e "${YELLOW}📁 Creating export directory...${NC}"
mkdir -p "$EXPORT_DIR"
echo -e "${GREEN}✓ Created: ${EXPORT_DIR}${NC}"
echo ""

# Export screenshots with organized naming
echo -e "${YELLOW}📸 Exporting screenshots...${NC}"

# Find all screenshot files and organize them
COUNTER=0

while IFS= read -r screenshot; do
    # Get the directory name which contains test info
    PARENT_DIR=$(dirname "$screenshot")
    PARENT_NAME=$(basename "$PARENT_DIR")
    
    # Get original filename
    FILENAME=$(basename "$screenshot")
    
    # Extract test name from parent directory if possible
    # Format is typically: ScreenShot_yyyy-MM-dd-HHmmss_XXXX.png
    if [[ $FILENAME =~ Screenshot_([0-9-]+)_([0-9]+) ]]; then
        DATE_PART="${BASH_REMATCH[1]}"
        UNIQUE_ID="${BASH_REMATCH[2]}"
    fi
    
    # Try to find a more descriptive name from plist if available
    PLIST_FILE="${PARENT_DIR}/Attachment_*.plist"
    if [ -f $PLIST_FILE ]; then
        # Extract name from plist using PlistBuddy
        NAME=$(/usr/libexec/PlistBuddy -c "Print :Name" "$PLIST_FILE" 2>/dev/null || echo "")
        if [ ! -z "$NAME" ]; then
            # Use the descriptive name
            NEW_FILENAME="${NAME}.png"
        else
            NEW_FILENAME="${FILENAME}"
        fi
    else
        NEW_FILENAME="${FILENAME}"
    fi
    
    # Copy file with organized name
    cp "$screenshot" "${EXPORT_DIR}/${NEW_FILENAME}"
    COUNTER=$((COUNTER + 1))
    
    echo -e "   ✓ ${NEW_FILENAME}"
    
done < <(find "$ATTACHMENTS_PATH" -name "*.png" -o -name "*.jpg")

echo ""
echo -e "${GREEN}✓ Exported ${COUNTER} screenshot(s)${NC}"
echo ""

# Generate index HTML file
echo -e "${YELLOW}📄 Generating index.html...${NC}"

cat > "${EXPORT_DIR}/index.html" << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>TeslaCare UI Test Screenshots</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, sans-serif;
            background: #f5f5f7;
            padding: 20px;
            color: #1d1d1f;
        }
        
        .container {
            max-width: 1400px;
            margin: 0 auto;
        }
        
        header {
            background: white;
            padding: 40px;
            border-radius: 12px;
            margin-bottom: 30px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        }
        
        h1 {
            font-size: 48px;
            font-weight: 700;
            margin-bottom: 10px;
        }
        
        .subtitle {
            font-size: 18px;
            color: #6e6e73;
        }
        
        .stats {
            display: flex;
            gap: 20px;
            margin-top: 20px;
        }
        
        .stat {
            background: #f5f5f7;
            padding: 15px 25px;
            border-radius: 8px;
        }
        
        .stat-value {
            font-size: 32px;
            font-weight: 700;
            color: #0071e3;
        }
        
        .stat-label {
            font-size: 14px;
            color: #6e6e73;
            margin-top: 5px;
        }
        
        .gallery {
            display: grid;
            grid-template-columns: repeat(auto-fill, minmax(350px, 1fr));
            gap: 30px;
        }
        
        .screenshot-card {
            background: white;
            border-radius: 12px;
            overflow: hidden;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
            transition: transform 0.2s, box-shadow 0.2s;
        }
        
        .screenshot-card:hover {
            transform: translateY(-5px);
            box-shadow: 0 10px 30px rgba(0,0,0,0.15);
        }
        
        .screenshot-card img {
            width: 100%;
            height: auto;
            display: block;
        }
        
        .screenshot-info {
            padding: 20px;
        }
        
        .screenshot-name {
            font-size: 16px;
            font-weight: 600;
            margin-bottom: 8px;
            word-wrap: break-word;
        }
        
        .screenshot-meta {
            font-size: 14px;
            color: #6e6e73;
        }
        
        .filter-bar {
            background: white;
            padding: 20px;
            border-radius: 12px;
            margin-bottom: 30px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        }
        
        .filter-buttons {
            display: flex;
            gap: 10px;
            flex-wrap: wrap;
        }
        
        .filter-btn {
            padding: 10px 20px;
            border: 2px solid #d2d2d7;
            background: white;
            border-radius: 20px;
            cursor: pointer;
            font-size: 14px;
            transition: all 0.2s;
        }
        
        .filter-btn:hover {
            border-color: #0071e3;
            color: #0071e3;
        }
        
        .filter-btn.active {
            background: #0071e3;
            border-color: #0071e3;
            color: white;
        }
        
        @media (max-width: 768px) {
            .gallery {
                grid-template-columns: 1fr;
            }
            
            h1 {
                font-size: 32px;
            }
            
            .stats {
                flex-direction: column;
            }
        }
    </style>
</head>
<body>
    <div class="container">
        <header>
            <h1>🚗 TeslaCare UI Tests</h1>
            <p class="subtitle">CarDetailView Screenshot Gallery</p>
            <div class="stats">
                <div class="stat">
                    <div class="stat-value" id="total-count">0</div>
                    <div class="stat-label">Total Screenshots</div>
                </div>
                <div class="stat">
                    <div class="stat-value" id="test-date">Today</div>
                    <div class="stat-label">Test Date</div>
                </div>
            </div>
        </header>
        
        <div class="filter-bar">
            <div class="filter-buttons">
                <button class="filter-btn active" data-filter="all">All</button>
                <button class="filter-btn" data-filter="Component">Components</button>
                <button class="filter-btn" data-filter="Sheet">Sheets</button>
                <button class="filter-btn" data-filter="DarkMode">Dark Mode</button>
                <button class="filter-btn" data-filter="Device">Devices</button>
                <button class="filter-btn" data-filter="Accessibility">Accessibility</button>
            </div>
        </div>
        
        <div class="gallery" id="gallery">
            <!-- Screenshots will be inserted here by JavaScript -->
        </div>
    </div>
    
    <script>
        // Get all PNG files in the directory
        const screenshots = [
EOF

# Add screenshot filenames to HTML
for screenshot in "${EXPORT_DIR}"/*.png; do
    if [ -f "$screenshot" ]; then
        BASENAME=$(basename "$screenshot")
        echo "            '${BASENAME}'," >> "${EXPORT_DIR}/index.html"
    fi
done

cat >> "${EXPORT_DIR}/index.html" << 'EOF'
        ];
        
        const gallery = document.getElementById('gallery');
        const totalCount = document.getElementById('total-count');
        const testDate = document.getElementById('test-date');
        
        // Set total count
        totalCount.textContent = screenshots.length;
        
        // Set test date
        const today = new Date().toLocaleDateString('en-US', { 
            month: 'long', 
            day: 'numeric', 
            year: 'numeric' 
        });
        testDate.textContent = today;
        
        // Function to create screenshot cards
        function displayScreenshots(filter = 'all') {
            gallery.innerHTML = '';
            
            screenshots.forEach(filename => {
                // Apply filter
                if (filter !== 'all' && !filename.includes(filter)) {
                    return;
                }
                
                const card = document.createElement('div');
                card.className = 'screenshot-card';
                
                const displayName = filename
                    .replace('.png', '')
                    .replace(/_/g, ' ')
                    .replace(/(\d+)/, '$1 - ');
                
                card.innerHTML = `
                    <img src="${filename}" alt="${displayName}" loading="lazy">
                    <div class="screenshot-info">
                        <div class="screenshot-name">${displayName}</div>
                        <div class="screenshot-meta">${filename}</div>
                    </div>
                `;
                
                gallery.appendChild(card);
            });
        }
        
        // Initial display
        displayScreenshots();
        
        // Filter button handlers
        document.querySelectorAll('.filter-btn').forEach(btn => {
            btn.addEventListener('click', () => {
                // Update active state
                document.querySelectorAll('.filter-btn').forEach(b => b.classList.remove('active'));
                btn.classList.add('active');
                
                // Filter screenshots
                const filter = btn.dataset.filter;
                displayScreenshots(filter);
            });
        });
    </script>
</body>
</html>
EOF

echo -e "${GREEN}✓ Generated index.html${NC}"
echo ""

# Create README in export directory
cat > "${EXPORT_DIR}/README.txt" << EOF
TeslaCare UI Test Screenshots
Generated: ${DATE_STAMP}

This directory contains screenshots captured during UI testing of the CarDetailView.

Files:
- index.html: Interactive gallery to view all screenshots
- *.png: Individual screenshot files

To view:
1. Open index.html in a web browser
2. Use the filter buttons to browse by category
3. Click screenshots to view full size

Screenshot Categories:
- Full Views: Complete view states (numbered)
- Components: Individual UI components
- Sheets: Modal presentations
- Dark Mode: Dark appearance variants
- Devices: Different device sizes
- Accessibility: Accessibility variations

Test Information:
- Project: TeslaCare
- Component: CarDetailView
- Framework: XCTest + Swift Testing
- Total Screenshots: ${COUNTER}

For more information, see the UI_TESTING_README.md in the project repository.
EOF

echo -e "${BLUE}========================================${NC}"
echo -e "${GREEN}✅ Export Complete!${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo -e "${YELLOW}📂 Location:${NC}"
echo -e "   ${EXPORT_DIR}"
echo ""
echo -e "${YELLOW}🌐 To view in browser:${NC}"
echo -e "   open ${EXPORT_DIR}/index.html"
echo ""
echo -e "${YELLOW}📁 To open in Finder:${NC}"
echo -e "   open ${EXPORT_DIR}"
echo ""

# Offer to open
read -p "$(echo -e ${YELLOW}Would you like to open the gallery in your browser now? [y/N]: ${NC})" -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    open "${EXPORT_DIR}/index.html"
    echo -e "${GREEN}✓ Opened in default browser${NC}"
fi

echo ""
echo -e "${GREEN}Done! 🎉${NC}"

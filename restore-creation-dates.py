#!/usr/bin/env python3
"""
Restore file creation dates based on first git commit timestamp.
This script should be run during Docker build process.
"""

import os
import subprocess
import sys
from datetime import datetime
from pathlib import Path

def get_first_commit_date(file_path):
    """Get the first commit date for a file using git log."""
    try:
        result = subprocess.run([
            'git', 'log', '--follow', '--format=%aI', '--reverse', file_path
        ], capture_output=True, text=True, check=True)
        
        lines = result.stdout.strip().split('\n')
        if lines and lines[0]:
            return lines[0].strip()
    except subprocess.CalledProcessError as e:
        print(f"Git error for {file_path}: {e}")
    except Exception as e:
        print(f"Error processing {file_path}: {e}")
    
    return None

def set_file_timestamps(file_path, iso_timestamp):
    """Set file creation and modification time to the given ISO timestamp."""
    try:
        # Parse ISO timestamp to datetime
        dt = datetime.fromisoformat(iso_timestamp.replace('Z', '+00:00'))
        timestamp = dt.timestamp()
        
        # Set both access and modification time
        os.utime(file_path, (timestamp, timestamp))
        return True
    except Exception as e:
        print(f"Error setting timestamp for {file_path}: {e}")
        return False

def main():
    """Process all markdown files in content/articles directory."""
    content_dir = Path('content/articles')
    
    if not content_dir.exists():
        print(f"Directory {content_dir} not found")
        sys.exit(1)
    
    print("Restoring creation dates from git history...")
    
    processed = 0
    updated = 0
    
    # Find all markdown files
    for md_file in content_dir.glob('*.md'):
        processed += 1
        
        # Get first commit date
        first_commit = get_first_commit_date(str(md_file))
        
        if first_commit:
            # Set file timestamp
            if set_file_timestamps(str(md_file), first_commit):
                print(f"✓ {md_file.name}: {first_commit}")
                updated += 1
            else:
                print(f"✗ {md_file.name}: Failed to set timestamp")
        else:
            print(f"? {md_file.name}: No git history found")
    
    print(f"\nProcessed {processed} files, updated {updated} timestamps")

if __name__ == '__main__':
    main()
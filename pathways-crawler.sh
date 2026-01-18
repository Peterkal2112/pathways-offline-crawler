#!/bin/bash

# --- LEGAL WARNING ---
printf "\033[1;31m"
printf "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n"
printf "WARNING: This script downloads content from Shout Out UK.\n"
printf "Usage of this tool may violate their Terms of Service (ToS).\n"
printf "This project is for educational purposes only. USE AT YOUR OWN RISK.\n"
printf "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n"
printf "\033[0m\n"

# 1. Path Setup
DEFAULT_PATH="/opt/Pathways"
printf "Enter installation directory [%s]: " "$DEFAULT_PATH"
read -r USER_INPUT < /dev/tty
TARGET_DIR="${USER_INPUT:-$DEFAULT_PATH}"

# 2. Check Permissions
if [ "$(id -u)" -ne 0 ]; then
  printf "\033[1;31mError: Please run as root (use sudo).\033[0m\n"
  exit 1
fi

# 3. Dependencies
printf "\n\033[0;32m[1/5] Checking system dependencies...\033[0m\n"
if ! command -v docker >/dev/null 2>&1; then
    printf "Installing Docker and required tools...\n"
    apt-get update
    apt-get install -y -o Dpkg::Options::="--force-overwrite" docker.io curl python3
fi
systemctl start docker >/dev/null 2>&1

# 4. Preparation
printf "\033[0;32m[2/5] Preparing directory: %s\033[0m\n" "$TARGET_DIR"
mkdir -p "$TARGET_DIR"
cd "$TARGET_DIR" || exit

# 5. Bootstrap Discovery Files (FIXED: Explicitly placing them in subfolders)
printf "\033[0;32m[3/5] Downloading entry files into proper subdirectories...\033[0m\n"
BASE="https://www.shoutoutuk.org/gamepw/"

# Create the folder structure first
mkdir -p html5/data/js html5/lib/scripts html5/lib/stylesheets story_content mobile

# Download core files to the CORRECT subdirectories
curl -sL "${BASE}story.html" -o "story.html"
curl -sL "${BASE}html5/data/js/data.js" -o "html5/data/js/data.js"
curl -sL "${BASE}html5/data/js/paths.js" -o "html5/data/js/paths.js"
curl -sL "https://www.shoutoutuk.org/wp-content/uploads/2024/06/pathways-teachers-guide-extremism-youth-radicalisation.pdf" -o "Teaching_Guide.pdf"

# Clean up any misplaced files from previous runs
rm -f data.js paths.js

# 6. The Crawling Bit (IMPROVED: Strict Path Preservation)
printf "\033[0;32m[4/5] Starting Recursive Asset Discovery...\033[0m\n"



docker run -i --rm --user 0:0 -v "$TARGET_DIR:/app" python:3.9-slim bash -c "
pip install requests > /dev/null 2>&1;
python3 -c \"
import requests, os, re

base_url = 'https://www.shoutoutuk.org/gamepw/'
target_root = '/app'

# Articulate Storyline directory structure map
prefixes = ['', 'html5/data/js/', 'html5/data/css/', 'html5/lib/scripts/', 'html5/lib/stylesheets/', 'mobile/', 'story_content/']
regex = r'[a-zA-Z0-9_/.-]+\.(?:png|gif|jpg|jpeg|mp3|mp4|wav|swf|json|js|css|woff|html|xml|ico|cur|svg)'

scanned_files = set()
total_new = 0

def deep_scan():
    global total_new
    discovered_links = set()
    files_to_check = []

    # 1. Identify all crawlable files (html, js, css, etc.)
    for root, _, files in os.walk(target_root):
        for file in files:
            fpath = os.path.join(root, file)
            if fpath not in scanned_files and file.endswith(('.js', '.html', '.css', '.json', '.xml')):
                files_to_check.append(fpath)

    if not files_to_check: return False

    # 2. Extract links from those files
    for fpath in files_to_check:
        try:
            with open(fpath, 'r', errors='ignore') as f:
                content = f.read()
                discovered_links.update(re.findall(regex, content))
            scanned_files.add(fpath)
        except: continue

    # 3. Download Logic
    new_downloads = 0
    for link in sorted(discovered_links):
        clean_name = link.split('?')[0].lstrip('/')
        if len(clean_name) < 5 or clean_name.startswith('http'): continue

        found_locally = False
        # Check if file exists in ANY of the correct subdirectories
        for p in prefixes:
            # Handle cases where the link already contains the prefix
            rel_path = clean_name if p and clean_name.startswith(p) else p + clean_name
            if os.path.exists(os.path.join(target_root, rel_path)):
                found_locally = True
                break
        
        if not found_locally:
            # Try to fetch from the server by testing all possible paths
            for p in prefixes:
                rel_path = clean_name if p and clean_name.startswith(p) else p + clean_name
                try:
                    r = requests.get(base_url + rel_path, timeout=5)
                    if r.status_code == 200:
                        dest = os.path.join(target_root, rel_path)
                        os.makedirs(os.path.dirname(dest), exist_ok=True)
                        with open(dest, 'wb') as f: f.write(r.content)
                        print(f'  [+] Saved to: {rel_path}')
                        new_downloads += 1
                        total_new += 1
                        break
                except: continue
    return new_downloads > 0

round = 1
while deep_scan():
    print(f'[*] Round {round} complete. Scanning newly found files...')
    round += 1

print(f'[*] Final Sync Complete: {total_new} files added to directory structure.')
\" "

# 7. Final Step: Webserver
FILE_COUNT=$(find "$TARGET_DIR" -type f | wc -l)
printf "\n\033[0;32m[5/5] Integrity Check: %s files found.\033[0m\n" "$FILE_COUNT"
printf "Do you want to host the game locally now? (y/n): "
read -r START_SRV < /dev/tty

if [[ "$START_SRV" =~ ^[Yy]$ ]]; then
    IP_ADDR=$(hostname -I | awk '{print $1}')
    printf "\n\033[1;34mGame: http://%s:8080/story.html\033[0m\n" "$IP_ADDR"
    printf "\033[1;33mPress CTRL+C to stop the server.\033[0m\n"
    python3 -m http.server 8080
fi

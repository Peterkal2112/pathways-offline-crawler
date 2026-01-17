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

# 5. Bootstrap Discovery Files
printf "\033[0;32m[3/5] Downloading entry files...\033[0m\n"
# We download these to the root temporarily to kickstart the scan
curl -sL "https://www.shoutoutuk.org/gamepw/story.html" -o "story.html"
curl -sL "https://www.shoutoutuk.org/wp-content/uploads/2024/06/pathways-teachers-guide-extremism-youth-radicalisation.pdf" -o "Teaching_Guide.pdf"

# 6. Verbose Multi-Round Crawler
printf "\033[0;32m[4/5] Starting Asset Crawler (Deep Scan)...\033[0m\n"

docker run -i --rm --user 0:0 -v "$TARGET_DIR:/app" python:3.9-slim bash -c "
pip install requests > /dev/null 2>&1;
python3 -c \"
import requests, os, re

base_url = 'https://www.shoutoutuk.org/gamepw/'
target_root = '/app'
# Every possible directory Articulate uses
prefixes = ['', 'html5/lib/scripts/', 'html5/lib/stylesheets/', 'html5/data/css/', 'html5/data/js/', 'mobile/', 'story_content/']
exts = 'png|gif|jpg|jpeg|mp3|mp4|wav|swf|json|js|css|woff|html|xml|ico|cur|svg'
regex = r'[a-zA-Z0-9_/.-]+\.(?:' + exts + ')'

scanned_files = set()
total_downloaded = 0

def scan_and_sync():
    global total_downloaded
    found_links = set()
    
    # Verbose Debug: Identify files to scan
    files_to_scan = []
    for root, _, files in os.walk(target_root):
        for file in files:
            fpath = os.path.join(root, file)
            if fpath not in scanned_files and file.endswith(('.js', '.html', '.css', '.xml', '.json')):
                files_to_scan.append(fpath)
    
    if not files_to_scan:
        return 0

    # Part A: Extraction
    for fpath in files_to_scan:
        try:
            with open(fpath, 'r', errors='ignore') as f:
                found_links.update(re.findall(regex, f.read()))
            scanned_files.add(fpath)
        except: continue

    # Part B: Download Logic
    new_in_round = 0
    to_check = {l.split('?')[0].lstrip('/') for l in found_links if len(l) > 4 and not l.startswith('http')}
    
    for asset in sorted(to_check):
        success = False
        # Try all prefixes to find the file
        for p in prefixes:
            rel = p + asset if p and not asset.startswith(p) else asset
            dest = os.path.join(target_root, rel)
            
            if os.path.exists(dest):
                success = True
                break
            
            try:
                r = requests.get(base_url + rel, timeout=5)
                if r.status_code == 200:
                    os.makedirs(os.path.dirname(dest), exist_ok=True)
                    with open(dest, 'wb') as f: f.write(r.content)
                    print(f'  [+] {rel}')
                    new_in_round += 1
                    total_downloaded += 1
                    success = True
                    break
            except: continue
    return new_in_round

# Multi-round execution with verbosity
round_num = 1
while True:
    print(f'[*] Round {round_num}: Scanning for new assets...')
    added = scan_and_sync()
    if added == 0:
        print('[*] No new assets found in this round.')
        break
    print(f'--- Round {round_num} complete. Added {added} files. ---')
    round_num += 1

print(f'\nFinal Sync Complete. Total new assets: {total_downloaded}')
\" "

# 7. Webserver Prompt
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

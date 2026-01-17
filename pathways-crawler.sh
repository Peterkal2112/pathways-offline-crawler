#!/bin/bash

# --- LEGAL WARNING ---
printf "\033[1;31m"
printf "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n"
printf "WARNING: Educational & Research use only. Usage is at own risk.\n"
printf "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n"
printf "\033[0m\n"

TARGET_DIR="/opt/Pathways"

# 1. Root Check
if [ "$(id -u)" -ne 0 ]; then
  printf "\033[1;31mError: Please run as root (use sudo).\033[0m\n"
  exit 1
fi

# 2. Dependency Check & Repair (The "Normal" Safety Net)
printf "\n\033[0;32m[1/5] Checking system dependencies...\033[0m\n"
if ! command -v docker >/dev/null 2>&1; then
    printf "Installing Docker and required tools...\n"
    apt-get update
    apt-get install -y -o Dpkg::Options::="--force-overwrite" docker.io curl python3
fi
systemctl start docker >/dev/null 2>&1

# 3. Preparation
printf "\033[0;32m[2/5] Preparing directory: %s\033[0m\n" "$TARGET_DIR"
mkdir -p "$TARGET_DIR"
cd "$TARGET_DIR" || exit

# 4. Bootstrap Discovery Files
printf "\033[0;32m[3/5] Downloading entry files for mapping...\033[0m\n"
curl -sL "https://www.shoutoutuk.org/gamepw/story.html" -o "story.html"
curl -sL "https://www.shoutoutuk.org/gamepw/html5/data/js/data.js" -o "data.js"
curl -sL "https://www.shoutoutuk.org/gamepw/html5/data/js/paths.js" -o "paths.js"
curl -sL "https://www.shoutoutuk.org/wp-content/uploads/2024/06/pathways-teachers-guide-extremism-youth-radicalisation.pdf" -o "Teaching_Guide.pdf"

# 5. Manifest-Based Crawler (The Core Logic)
printf "\033[0;32m[4/5] Building Manifest and Syncing Assets...\033[0m\n"



docker run -i --rm --user 0:0 -v "$TARGET_DIR:/app" python:3.9-slim bash -c "
pip install requests > /dev/null 2>&1;
python3 -c \"
import requests, os, re

base_url = 'https://www.shoutoutuk.org/gamepw/'
target_root = '/app'
# Extended prefixes to prevent 404s
prefixes = ['', 'html5/lib/scripts/', 'html5/lib/stylesheets/', 'html5/data/css/', 'html5/data/js/', 'mobile/', 'story_content/']
regex = r'[a-zA-Z0-9_/.-]+\.(?:png|gif|jpg|jpeg|mp3|mp4|wav|swf|json|js|css|woff|html|xml|ico|cur|svg)'

def get_links_from_file(fpath):
    try:
        with open(fpath, 'r', errors='ignore') as f:
            return re.findall(regex, f.read())
    except: return []

scanned_files = set()
manifest = set()
downloaded_count = 0

# Iterative discovery loop
while True:
    new_discovery = False
    # Find all files we haven't scanned yet
    for root, _, files in os.walk(target_root):
        for file in files:
            fpath = os.path.join(root, file)
            if fpath not in scanned_files and file.endswith(('.js', '.html', '.css', '.xml', '.json')):
                # Extract potential links
                links = get_links_from_file(fpath)
                for l in links:
                    clean = l.split('?')[0].lstrip('/')
                    if len(clean) > 4 and not clean.startswith('http'):
                        manifest.add(clean)
                scanned_files.add(fpath)
                new_discovery = True

    if not new_discovery: break # No new files found to scan

    # Check manifest against disk and download missing
    for asset in sorted(manifest):
        already_exists = False
        for p in prefixes:
            rel = p + asset if p and not asset.startswith(p) else asset
            if os.path.exists(os.path.join(target_root, rel)):
                already_exists = True; break
        
        if not already_exists:
            for p in prefixes:
                rel = p + asset if p and not asset.startswith(p) else asset
                try:
                    r = requests.get(base_url + rel, timeout=5)
                    if r.status_code == 200:
                        dest = os.path.join(target_root, rel)
                        os.makedirs(os.path.dirname(dest), exist_ok=True)
                        with open(dest, 'wb') as f: f.write(r.content)
                        print(f'  [+] {rel}')
                        downloaded_count += 1
                        break # Successfully found this asset
                except: continue

print(f'\n--- Sync Complete ---')
print(f'Total Assets in Manifest: {len(manifest)}')
print(f'New Files Downloaded: {downloaded_count}')
\" "

# 6. Integrity Count Verification
FILE_COUNT=$(find "$TARGET_DIR" -type f | wc -l)
printf "\033[1;32m[*] Integrity Check: %s files found in %s\033[0m\n" "$FILE_COUNT" "$TARGET_DIR"

# 7. Webserver Prompt
printf "\n[5/5] Do you want to host the game locally now? (y/n): "
read -r START_SRV < /dev/tty

if [[ "$START_SRV" =~ ^[Yy]$ ]]; then
    IP_ADDR=$(hostname -I | awk '{print $1}')
    printf "\n\033[1;34mGame: http://%s:8080/story.html\033[0m\n" "$IP_ADDR"
    printf "\033[1;33mPress CTRL+C to stop the server.\033[0m\n"
    python3 -m http.server 8080
fi

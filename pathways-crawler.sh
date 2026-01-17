#!/bin/bash

# --- LEGAL WARNING ---
printf "\033[1;31m"
printf "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n"
printf "WARNING: Educational & Research use only. Usage is at own risk.\n"
printf "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n"
printf "\033[0m\n"

TARGET_DIR="/opt/Pathways"

if [ "$(id -u)" -ne 0 ]; then
  printf "\033[1;31mError: Please run as root (use sudo).\033[0m\n"
  exit 1
fi

# 1. Dependencies
if ! command -v docker >/dev/null 2>&1; then
    apt-get update && apt-get install -y docker.io curl python3
fi
systemctl start docker >/dev/null 2>&1

mkdir -p "$TARGET_DIR"
cd "$TARGET_DIR" || exit

# 2. Bootstrap Mapping
printf "\n\033[0;32m[*] Phase 1: Mapping remote assets...\033[0m\n"
curl -sL "https://www.shoutoutuk.org/gamepw/story.html" -o "story.html"
curl -sL "https://www.shoutoutuk.org/gamepw/html5/data/js/data.js" -o "data.js_temp"
curl -sL "https://www.shoutoutuk.org/gamepw/html5/data/js/paths.js" -o "paths.js_temp"
curl -sL "https://www.shoutoutuk.org/wp-content/uploads/2024/06/pathways-teachers-guide-extremism-youth-radicalisation.pdf" -o "Teaching_Guide.pdf"

# 3. Location-Aware Crawler
printf "\033[0;32m[*] Phase 2: Verifying integrity & Downloading missing files...\033[0m\n"

docker run -i --rm --user 0:0 -v "$TARGET_DIR:/app" python:3.9-slim bash -c "
pip install requests > /dev/null 2>&1;
python3 -c \"
import requests, os, re

base_url = 'https://www.shoutoutuk.org/gamepw/'
target_root = '/app'
prefixes = ['', 'html5/lib/scripts/', 'html5/lib/stylesheets/', 'html5/data/css/', 'html5/data/js/', 'mobile/', 'story_content/']

def get_master_list():
    assets = set()
    regex = r'[a-zA-Z0-9_/.-]+\.(?:png|gif|jpg|jpeg|mp3|mp4|wav|swf|json|js|css|woff|html|xml|ico|cur|svg)'
    for fname in ['story.html', 'data.js_temp', 'paths.js_temp']:
        p = os.path.join(target_root, fname)
        if os.path.exists(p):
            with open(p, 'r', errors='ignore') as f:
                assets.update(re.findall(regex, f.read()))
    return {a.split('?')[0].lstrip('/') for a in assets if len(a) > 4 and not a.startswith('http')}

master_assets = get_master_list()
downloaded = 0

for asset in sorted(master_assets):
    success = False
    
    # Try every prefix to find where the file actually lives on the server
    for p in prefixes:
        # Determine the correct relative path
        if p and not asset.startswith(p):
            rel_path = p + asset
        else:
            rel_path = asset
            
        full_local_path = os.path.join(target_root, rel_path)
        
        # If the file exists in this specific location, skip to next asset
        if os.path.exists(full_local_path):
            success = True
            break
            
        # If not on disk, try to download it from this specific prefix
        try:
            url = base_url + rel_path
            r = requests.get(url, timeout=3)
            if r.status_code == 200:
                os.makedirs(os.path.dirname(full_local_path), exist_ok=True)
                with open(full_local_path, 'wb') as f:
                    f.write(r.content)
                print(f'  [NEW] {rel_path}')
                downloaded += 1
                success = True
                break
        except:
            continue

print(f'\n--- Sync Complete. New files: {downloaded} ---')
\" "

# Clean up
rm -f *_temp

# 4. Webserver
printf "\n\033[0;32m[*] All assets verified.\033[0m\n"
printf "Do you want to host the game locally now? (y/n): "
read START_SRV < /dev/tty

if [[ "$START_SRV" =~ ^[Yy]$ ]]; then
    IP_ADDR=$(hostname -I | awk '{print $1}')
    printf "\n\033[1;34mGame URL: http://%s:8080/story.html\033[0m\n" "$IP_ADDR"
    python3 -m http.server 8080
fi

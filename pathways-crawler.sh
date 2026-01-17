#!/bin/bash

# --- LEGAL WARNING ---
printf "\033[1;31m"
printf "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n"
printf "WARNING: Educational & Research use only. Usage is at own risk.\n"
printf "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n"
printf "\033[0m\n"

# 1. Path Setup
DEFAULT_PATH="/opt/Pathways"
printf "Enter installation directory [%s]: " "$DEFAULT_PATH"
read -r USER_INPUT < /dev/tty
TARGET_DIR="${USER_INPUT:-$DEFAULT_PATH}"

# 2. Check Permissions
if [ "$(id -u)" -ne 0 ]; then
  printf "\033[1;31mPlease run as root (use sudo).\033[0m\n"
  exit 1
fi

# 3. Dependencies & Repair
printf "\n\033[0;32m[1/5] Checking system dependencies...\033[0m\n"
if ! command -v docker >/dev/null 2>&1; then
    printf "Repairing and installing docker...\n"
    apt-get update
    apt-get install -y -o Dpkg::Options::="--force-overwrite" docker.io curl python3
fi
systemctl start docker >/dev/null 2>&1

# 4. Prepare Directory
mkdir -p "$TARGET_DIR"
cd "$TARGET_DIR" || exit

# 5. Bootstrap
printf "\n\033[0;32m[2/5] Downloading entry files...\033[0m\n"
curl -sL "https://www.shoutoutuk.org/gamepw/story.html" -o "story.html"
curl -sL "https://www.shoutoutuk.org/wp-content/uploads/2024/06/pathways-teachers-guide-extremism-youth-radicalisation.pdf" -o "Teaching_Guide.pdf"

# 6. Deep Crawler Logic
printf "\n\033[0;32m[3/5] Starting Deep Asset Crawler (Deep Scan)...\033[0m\n"
docker run -i --rm --user 0:0 -v "$TARGET_DIR:/app" python:3.9-slim bash -c "
pip install requests > /dev/null 2>&1;
python3 -c \"
import requests, os, re

base_url = 'https://www.shoutoutuk.org/gamepw/'
target_root = '/app'
prefixes = ['', 'html5/lib/scripts/', 'html5/lib/stylesheets/', 'html5/data/css/', 'html5/data/js/', 'mobile/', 'story_content/']
regex = r'[a-zA-Z0-9_/.-]+\.(?:png|gif|jpg|jpeg|mp3|mp4|wav|swf|json|js|css|woff|html|xml|ico|cur|svg)'

def get_local_links():
    links = set()
    for root, _, files in os.walk(target_root):
        for file in files:
            if file.endswith(('.js', '.html', '.css', '.xml', '.json')):
                try:
                    with open(os.path.join(root, file), 'r', errors='ignore') as f:
                        links.update(re.findall(regex, f.read()))
                except: continue
    return {l.split('?')[0].lstrip('/') for l in links if len(l) > 4 and not l.startswith('http')}

total_new = 0
while True:
    master_list = get_local_links()
    added_this_round = 0
    
    for asset in sorted(master_list):
        found = False
        # Check if already exists in correct location
        for p in prefixes:
            rel = p + asset if p and not asset.startswith(p) else asset
            if os.path.exists(os.path.join(target_root, rel)):
                found = True
                break
        
        if found: continue

        # Try downloading
        for p in prefixes:
            rel = p + asset if p and not asset.startswith(p) else asset
            try:
                r = requests.get(base_url + rel, timeout=5)
                if r.status_code == 200:
                    dest = os.path.join(target_root, rel)
                    os.makedirs(os.path.dirname(dest), exist_ok=True)
                    with open(dest, 'wb') as f: f.write(r.content)
                    print(f'  [+] {rel}')
                    added_this_round += 1
                    break
            except: continue
            
    total_new += added_this_round
    if added_this_round == 0: break
    print(f'--- Round complete. Added {added_this_round} files. Re-scanning for sub-assets... ---')

print(f'Final Sync Complete. Total new assets: {total_new}')
\" "

# 7. Final Step: Webserver
printf "\n\033[0;32m[4/5] Download complete.\033[0m\n"
printf "Do you want to host the game locally now? (y/n): "
read -r START_SRV < /dev/tty

if [[ "$START_SRV" =~ ^[Yy]$ ]]; then
    IP_ADDR=$(hostname -I | awk '{print $1}')
    printf "\n\033[1;34mGame: http://%s:8080/story.html\033[0m\n" "$IP_ADDR"
    python3 -m http.server 8080
fi

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

# 2. Dependency Check & Install
printf "\n\033[0;32m[1/4] Checking system dependencies...\033[0m\n"
if ! command -v docker >/dev/null 2>&1; then
    printf "Installing Docker and required tools...\n"
    apt-get update
    apt-get install -y -o Dpkg::Options::="--force-overwrite" docker.io curl python3
fi
systemctl start docker >/dev/null 2>&1

# 3. Preparation
printf "\033[0;32m[2/4] Preparing directory: %s\033[0m\n" "$TARGET_DIR"
mkdir -p "$TARGET_DIR"
cd "$TARGET_DIR" || exit

# 4. Download Core Files
printf "\033[0;32m[3/4] Downloading entry files...\033[0m\n"
curl -sL "https://www.shoutoutuk.org/wp-content/uploads/2024/06/pathways-teachers-guide-extremism-youth-radicalisation.pdf" -o "Teaching_Guide.pdf"
curl -sL "https://www.shoutoutuk.org/gamepw/story.html" -o "story.html"

# 5. Optimized Crawler (Docker)
printf "\033[0;32m[4/4] Syncing assets (Checking local disk first)...\033[0m\n"
docker run -i --rm --user 0:0 -v "$TARGET_DIR:/app" python:3.9-slim bash -c "
pip install requests > /dev/null 2>&1;
python3 -c \"
import requests, os, re
base_url = 'https://www.shoutoutuk.org/gamepw/'
target_root = '/app'
regex = r'[a-zA-Z0-9_/.-]+\.(?:png|gif|jpg|jpeg|mp3|mp4|wav|swf|json|js|css|woff|html|xml|ico|cur|svg)'
prefixes = ['', 'html5/lib/scripts/', 'html5/data/css/', 'html5/data/js/', 'mobile/', 'story_content/']

def sync():
    found_links = set()
    for root, _, files in os.walk(target_root):
        for file in files:
            if file.endswith(('.js', '.html', '.css', '.xml')):
                try:
                    with open(os.path.join(root, file), 'r', errors='ignore') as f:
                        found_links.update(re.findall(regex, f.read()))
                except: continue
    
    to_check = {f.split('?')[0].lstrip('/') for f in found_links if not f.startswith(('http', 'data:'))}
    new_count = 0
    
    for path in sorted(to_check):
        if len(path) < 4: continue
        
        # Fast local check
        exists = False
        for p in prefixes:
            loc = p + os.path.basename(path) if p and '/' in path else path
            if p and not path.startswith(p): loc = p + path
            else: loc = path
            if os.path.exists(os.path.join(target_root, loc)):
                exists = True
                break
        
        if exists: continue

        # Network download only if missing
        for p in prefixes:
            loc = p + os.path.basename(path) if p and '/' in path else path
            if p and not path.startswith(p): loc = p + path
            else: loc = path
            dest = os.path.join(target_root, loc)
            try:
                r = requests.get(base_url + loc, timeout=5)
                if r.status_code == 200:
                    os.makedirs(os.path.dirname(dest), exist_ok=True)
                    with open(dest, 'wb') as f: f.write(r.content)
                    print(f'  [OK] Downloaded: {loc}')
                    new_count += 1
                    break
            except: continue
    return new_count

# Run sync loop
total = 0
while True:
    added = sync()
    total += added
    if added == 0: break
\" "

# 6. Webserver Prompt
printf "\n\033[0;32m[*] Sync complete. Total new assets: $total\033[0m\n"
printf "Do you want to host the game locally now? (y/n): "
read START_SRV < /dev/tty

if [[ "$START_SRV" =~ ^[Yy]$ ]]; then
    IP_ADDR=$(hostname -I | awk '{print $1}')
    printf "\n\033[1;34mLink: http://%s:8080/story.html\033[0m\n" "$IP_ADDR"
    printf "\033[1;33mPress CTRL+C to stop the server.\033[0m\n"
    python3 -m http.server 8080
fi

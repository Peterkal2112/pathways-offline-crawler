#!/bin/bash

# --- LEGAL WARNING ---
printf "\033[1;31m"
printf "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n"
printf "WARNING: ToS Violation Risk. Educational & Research use only.\n"
printf "Usage of this tool is at your own risk.\n"
printf "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n"
printf "\033[0m\n"

# 1. Path Setup
DEFAULT_PATH="/root/Pathways"
printf "Target directory [%s]: " "$DEFAULT_PATH"
read USER_INPUT
USER_PATH="${USER_INPUT:-$DEFAULT_PATH}"
TARGET_DIR="$USER_PATH/gamepw_offline"

# 2. Preparation
mkdir -p "$TARGET_DIR"
cd "$TARGET_DIR" || exit

# 3. Download Teacher's Guide
printf "\n\033[0;32m[*] Fetching Teacher's Guide PDF...\033[0m\n"
curl -sL "https://www.shoutoutuk.org/wp-content/uploads/2024/06/pathways-teachers-guide-extremism-youth-radicalisation.pdf" -o "Teaching_Guide.pdf"

# 4. Recursive Docker Crawler
printf "\n\033[0;32m[*] Launching Recursive Crawler (Docker)...\033[0m\n"
docker run -i --rm -v "$TARGET_DIR:/app" python:3.9-slim bash -c "
pip install requests > /dev/null 2>&1;
python3 -c \"
import requests, os, re
base_url = 'https://www.shoutoutuk.org/gamepw/'
target_root = '/app'
regex = r'[a-zA-Z0-9_/.-]+\.(?:png|gif|jpg|jpeg|mp3|mp4|wav|swf|json|js|css|woff|html|xml|ico)'

def crawl():
    found_files = {'story.html', 'analytics-frame.html'}
    for root, _, files in os.walk(target_root):
        for file in files:
            if file.endswith(('.js', '.html', '.css', '.xml')):
                with open(os.path.join(root, file), 'r', errors='ignore') as f:
                    found_files.update(re.findall(regex, f.read()))
    to_download = {f.split('?')[0].lstrip('/') for f in found_files if not f.startswith(('http', 'data:'))}
    new_count = 0
    for path in sorted(to_download):
        for loc in [path, 'mobile/'+os.path.basename(path), 'story_content/'+os.path.basename(path)]:
            dest = os.path.join(target_root, loc)
            if os.path.exists(dest): break
            try:
                r = requests.get(base_url + loc, headers={'User-Agent': 'Mozilla/5.0'}, timeout=5)
                if r.status_code == 200:
                    os.makedirs(os.path.dirname(dest), exist_ok=True)
                    with open(dest, 'wb') as f: f.write(r.content)
                    print(f'  [OK] {loc}')
                    new_count += 1
                    break
            except: continue
    return new_count

while True:
    added = crawl()
    if added == 0: break
    print(f'Done phase. Added {added} assets. Checking for new links...')
\" "

# 5. Webserver Option
printf "\n\033[0;32m[*] Process finished. Files saved in %s\033[0m\n" "$TARGET_DIR"
printf "Do you want to start the webserver? (y/n): "
read START_SRV

if [ "$START_SRV" = "y" ] || [ "$START_SRV" = "Y" ]; then
    IP_ADDR=$(hostname -I | awk '{print $1}')
    printf "\n\033[1;32mURL: http://%s:8080/story.html\033[0m\n" "$IP_ADDR"
    python3 -m http.server 8080
fi

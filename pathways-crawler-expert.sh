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

# 4. Docker Crawler
printf "\n\033[0;32m[*] Launching Asset Crawler (Docker)...\033[0m\n"
docker run -i --rm -v "$TARGET_DIR:/app" python:3.9-slim bash -c "
pip install requests > /dev/null 2>&1;
python3 -c \"
import requests, os, re
base_url = 'https://www.shoutoutuk.org/gamepw/'
target_root = '/app'
# Extended asset regex
regex = r'[a-zA-Z0-9_/.-]+\.(?:png|gif|jpg|jpeg|mp3|mp4|wav|swf|json|js|css|woff|html|xml|ico)'

found_files = {'story.html', 'analytics-frame.html'}

print('Scanning local files for remote asset links...')
for root, _, files in os.walk(target_root):
    for file in files:
        if file.endswith(('.js', '.html', '.css', '.xml')):
            with open(os.path.join(root, file), 'r', errors='ignore') as f:
                found_files.update(re.findall(regex, f.read()))

# Clean and filter links
to_download = {f.split('?')[0].lstrip('/') for f in found_files if not f.startswith(('http', 'data:'))}

print(f'Attempting to sync {len(to_download)} unique assets...')
for path in sorted(to_download):
    # Try multiple common Articulate Storyline paths
    for loc in [path, 'mobile/'+os.path.basename(path), 'story_content/'+os.path.basename(path)]:
        dest = os.path.join(target_root, loc)
        if os.path.exists(dest): break
        try:
            r = requests.get(base_url + loc, headers={'User-Agent': 'Mozilla/5.0'}, timeout=5)
            if r.status_code == 200:
                os.makedirs(os.path.dirname(dest), exist_ok=True)
                with open(dest, 'wb') as f: f.write(r.content)
                print(f'  [OK] {loc}')
                break
        except: continue
\" "

# 5. Webserver Option
printf "\n\033[0;32m[*] Process finished.\033[0m\n"
printf "Do you want to start the webserver? (y/n): "
read START_SRV

if [ "$START_SRV" = "y" ] || [ "$START_SRV" = "Y" ]; then
    IP_ADDR=$(hostname -I | awk '{print $1}')
    printf "\n\033[1;34m----------------------------------------------\033[0m\n"
    printf "\033[1;32mGAME URL:  http://%s:8080/story.html\033[0m\n" "$IP_ADDR"
    printf "\033[1;32mGUIDE PDF: http://%s:8080/Teaching_Guide.pdf\033[0m\n" "$IP_ADDR"
    printf "\033[1;34m----------------------------------------------\033[0m\n"
    python3 -m http.server 8080
fi
